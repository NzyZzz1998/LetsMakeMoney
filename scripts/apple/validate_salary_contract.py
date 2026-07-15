#!/usr/bin/env python3
"""Standard-library validator and reference calculator for salary-schema v1."""

from __future__ import annotations

import argparse
import calendar
import hashlib
import json
import re
import sys
from dataclasses import dataclass
from datetime import date, datetime, timedelta
from pathlib import Path
from typing import Any
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError


ROOT = Path(__file__).resolve().parents[2]
CONTRACT_ROOT = ROOT / "shared" / "salary-schema" / "v1"
HOLIDAY_ROOT = CONTRACT_ROOT / "holidays"
TIME_PATTERN = re.compile(r"^(?:[01][0-9]|2[0-3]):[0-5][0-9]$")
DATE_PATTERN = re.compile(r"^\d{4}-\d{2}-\d{2}$")
ALLOWED_CONFIG_KEYS = {
    "schemaVersion", "monthlySalaryMinor", "currencyCode", "restMode", "alternatingAnchor",
    "workStart", "workEnd", "lunchStart", "lunchEnd", "standardWorkSeconds",
    "dateOverrides", "holidayDatasetVersion", "notificationPreference", "watchMetric",
}
REQUIRED_CONFIG_KEYS = ALLOWED_CONFIG_KEYS - {"alternatingAnchor"}
ALLOWED_OVERRIDE_KEYS = {"date", "isWorkday", "isPaid", "effectiveWorkSeconds"}


class ContractError(ValueError):
    def __init__(self, code: str, message: str):
        super().__init__(message)
        self.code = code


def load_json(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def parse_date(value: str, field: str) -> date:
    if not isinstance(value, str) or not DATE_PATTERN.fullmatch(value):
        raise ContractError("invalidConfiguration", f"{field} 必须为 YYYY-MM-DD")
    try:
        return date.fromisoformat(value)
    except ValueError as exc:
        raise ContractError("invalidConfiguration", f"{field} 不是有效日期") from exc


def minute_of_day(value: str, field: str) -> int:
    if not isinstance(value, str) or not TIME_PATTERN.fullmatch(value):
        raise ContractError("invalidTimeRange", f"{field} 必须为 HH:mm")
    hour, minute = (int(part) for part in value.split(":"))
    return hour * 60 + minute


def validate_config(config: Any) -> None:
    if not isinstance(config, dict):
        raise ContractError("invalidConfiguration", "配置根节点必须是对象")
    unknown = set(config) - ALLOWED_CONFIG_KEYS
    missing = REQUIRED_CONFIG_KEYS - set(config)
    if unknown:
        raise ContractError("invalidConfiguration", f"存在未知字段: {sorted(unknown)}")
    if missing:
        raise ContractError("invalidConfiguration", f"缺少字段: {sorted(missing)}")
    if config["schemaVersion"] != 1:
        raise ContractError("unsupportedSchemaVersion", "仅支持 schemaVersion=1")
    salary = config["monthlySalaryMinor"]
    if type(salary) is not int or not 0 <= salary <= 9_000_000_000_000:
        raise ContractError("invalidConfiguration", "monthlySalaryMinor 必须是安全范围内的非负整数")
    if not isinstance(config["currencyCode"], str) or not re.fullmatch(r"[A-Z]{3}", config["currencyCode"]):
        raise ContractError("invalidConfiguration", "currencyCode 必须是三位大写代码")
    if config["restMode"] not in {"doubleWeekend", "singleWeekend", "alternatingWeekend"}:
        raise ContractError("invalidConfiguration", "restMode 不受支持")
    anchor_value = config.get("alternatingAnchor")
    if config["restMode"] == "alternatingWeekend":
        if anchor_value is None:
            raise ContractError("missingAlternatingAnchor", "大小周必须提供双休周周六锚点")
        anchor = parse_date(anchor_value, "alternatingAnchor")
        if anchor.weekday() != 5:
            raise ContractError("missingAlternatingAnchor", "大小周锚点必须是周六")
    elif anchor_value is not None:
        parse_date(anchor_value, "alternatingAnchor")

    work_start = minute_of_day(config["workStart"], "workStart")
    work_end = minute_of_day(config["workEnd"], "workEnd")
    lunch_start = minute_of_day(config["lunchStart"], "lunchStart")
    lunch_end = minute_of_day(config["lunchEnd"], "lunchEnd")
    if not work_start < lunch_start < lunch_end <= work_end:
        raise ContractError("invalidTimeRange", "必须满足 workStart < lunchStart < lunchEnd <= workEnd")
    schedule_seconds = ((lunch_start - work_start) + (work_end - lunch_end)) * 60
    standard_seconds = config["standardWorkSeconds"]
    if type(standard_seconds) is not int or not 1 <= standard_seconds <= 86400:
        raise ContractError("invalidConfiguration", "standardWorkSeconds 超出范围")
    if schedule_seconds != standard_seconds:
        raise ContractError("invalidTimeRange", "standardWorkSeconds 必须等于排除午休后的有效工时")

    overrides = config["dateOverrides"]
    if not isinstance(overrides, list):
        raise ContractError("invalidConfiguration", "dateOverrides 必须是数组")
    seen: set[str] = set()
    for index, override in enumerate(overrides):
        if not isinstance(override, dict):
            raise ContractError("invalidConfiguration", f"dateOverrides[{index}] 必须是对象")
        if set(override) - ALLOWED_OVERRIDE_KEYS or not {"date", "isWorkday", "isPaid"} <= set(override):
            raise ContractError("invalidConfiguration", f"dateOverrides[{index}] 字段不合法")
        parsed = parse_date(override["date"], f"dateOverrides[{index}].date")
        if parsed.isoformat() in seen:
            raise ContractError("duplicateDateOverride", f"日期覆盖重复: {parsed.isoformat()}")
        seen.add(parsed.isoformat())
        if type(override["isWorkday"]) is not bool or type(override["isPaid"]) is not bool:
            raise ContractError("invalidConfiguration", "isWorkday/isPaid 必须是布尔值")
        effective = override.get("effectiveWorkSeconds")
        if effective is not None and (type(effective) is not int or not 1 <= effective <= 86400):
            raise ContractError("invalidConfiguration", "effectiveWorkSeconds 超出范围")

    if not isinstance(config["holidayDatasetVersion"], str) or not config["holidayDatasetVersion"]:
        raise ContractError("invalidConfiguration", "holidayDatasetVersion 不能为空")
    if config["notificationPreference"] not in {"notRequested", "allowed", "denied"}:
        raise ContractError("invalidConfiguration", "notificationPreference 不受支持")
    if config["watchMetric"] not in {"remainingTime", "todayIncome", "progress"}:
        raise ContractError("invalidConfiguration", "watchMetric 不受支持")


@dataclass(frozen=True)
class DayRule:
    is_workday: bool
    is_paid: bool
    effective_work_seconds: int


class ReferenceCalculator:
    def __init__(self, config: dict[str, Any]):
        validate_config(config)
        self.config = config
        manifest = load_json(HOLIDAY_ROOT / "manifest.json")
        if config["holidayDatasetVersion"] != manifest["datasetVersion"]:
            raise ContractError("holidayDatasetMismatch", "节假日数据版本不匹配")
        self.covered_years = set(manifest["coveredYears"])
        self.holidays: dict[int, set[date]] = {}
        self.adjusted: dict[int, set[date]] = {}
        for item in manifest["files"]:
            if item["status"] != "official":
                continue
            payload = load_json(HOLIDAY_ROOT / item["path"])
            year = payload["year"]
            self.holidays[year] = {date.fromisoformat(value) for value in payload["holidays"]}
            self.adjusted[year] = {date.fromisoformat(value) for value in payload["adjustedWorkdays"]}
        self.overrides = {date.fromisoformat(item["date"]): item for item in config["dateOverrides"]}

    def weekly_workday(self, day: date) -> bool:
        weekday = day.weekday()
        mode = self.config["restMode"]
        if mode == "doubleWeekend":
            return weekday < 5
        if mode == "singleWeekend":
            return weekday < 6
        if weekday < 5:
            return True
        if weekday == 6:
            return False
        anchor = date.fromisoformat(self.config["alternatingAnchor"])
        week_delta = (day - anchor).days // 7
        return week_delta % 2 != 0

    def rule_for(self, day: date) -> DayRule:
        override = self.overrides.get(day)
        if override is not None:
            return DayRule(
                override["isWorkday"],
                override["isPaid"],
                override.get("effectiveWorkSeconds") or self.config["standardWorkSeconds"],
            )
        if day.year in self.covered_years:
            if day in self.holidays.get(day.year, set()):
                return DayRule(False, False, self.config["standardWorkSeconds"])
            if day in self.adjusted.get(day.year, set()):
                return DayRule(True, True, self.config["standardWorkSeconds"])
        workday = self.weekly_workday(day)
        return DayRule(workday, workday, self.config["standardWorkSeconds"])

    @staticmethod
    def rounded_ratio(numerator: int, denominator: int) -> int:
        return (numerator + denominator // 2) // denominator

    def completed_seconds(self, now: datetime) -> tuple[int, str]:
        current_minutes = now.hour * 60 + now.minute
        start = minute_of_day(self.config["workStart"], "workStart")
        end = minute_of_day(self.config["workEnd"], "workEnd")
        lunch_start = minute_of_day(self.config["lunchStart"], "lunchStart")
        lunch_end = minute_of_day(self.config["lunchEnd"], "lunchEnd")
        current_seconds = current_minutes * 60 + now.second
        start_seconds = start * 60
        end_seconds = end * 60
        lunch_start_seconds = lunch_start * 60
        lunch_end_seconds = lunch_end * 60
        morning_seconds = lunch_start_seconds - start_seconds
        if current_seconds < start_seconds:
            return 0, "beforeWork"
        if current_seconds < lunch_start_seconds:
            return current_seconds - start_seconds, "working"
        if current_seconds < lunch_end_seconds:
            return morning_seconds, "lunchBreak"
        if current_seconds < end_seconds:
            return morning_seconds + current_seconds - lunch_end_seconds, "working"
        return self.config["standardWorkSeconds"], "finished"

    def calculate(self, now: datetime) -> dict[str, Any]:
        year, month = now.year, now.month
        days_in_month = calendar.monthrange(year, month)[1]
        days = [date(year, month, number) for number in range(1, days_in_month + 1)]
        paid_days = [day for day in days if (rule := self.rule_for(day)).is_workday and rule.is_paid]
        if not paid_days:
            raise ContractError("noPaidWorkdays", "当前月份没有计薪工作日")
        daily = self.rounded_ratio(self.config["monthlySalaryMinor"], len(paid_days))
        hourly = self.rounded_ratio(daily * 3600, self.config["standardWorkSeconds"])

        today = now.date()
        today_rule = self.rule_for(today)
        if not today_rule.is_workday:
            completed, status = 0, "restDay"
        else:
            completed, status = self.completed_seconds(now)
        full_today = 0
        if today_rule.is_workday and today_rule.is_paid:
            full_today = self.rounded_ratio(
                daily * today_rule.effective_work_seconds,
                self.config["standardWorkSeconds"],
            )
        today_earned = self.rounded_ratio(full_today * completed, self.config["standardWorkSeconds"])

        month_earned = 0
        for day in paid_days:
            if day >= today:
                continue
            rule = self.rule_for(day)
            month_earned += self.rounded_ratio(
                daily * rule.effective_work_seconds,
                self.config["standardWorkSeconds"],
            )
        month_earned += today_earned
        warnings = [] if year in self.covered_years else ["holidayDatasetOutOfRange"]
        return {
            "monthPaidWorkdays": len(paid_days),
            "dailySalaryMinor": daily,
            "standardHourlySalaryMinor": hourly,
            "todayEarnedMinor": today_earned,
            "monthEarnedMinor": month_earned,
            "completedEffectiveSeconds": completed,
            "progressBasisPoints": min(10000, self.rounded_ratio(completed * 10000, self.config["standardWorkSeconds"])),
            "status": status,
            "warnings": warnings,
        }


def resolve_vector_configs(payload: dict[str, Any]) -> list[tuple[dict[str, Any], dict[str, Any]]]:
    resolved: dict[str, dict[str, Any]] = {}
    output = []
    for case in payload["cases"]:
        if "config" in case:
            config = case["config"]
        else:
            config = resolved.get(case.get("configRef"))
            if config is None:
                raise ContractError("invalidConfiguration", f"未知 configRef: {case.get('configRef')}")
        resolved[case["id"]] = config
        output.append((case, config))
    return output


def validate_vectors(path: Path) -> None:
    payload = load_json(path)
    if payload.get("contractVersion") != 1 or not payload.get("vectorSetId"):
        raise ContractError("invalidConfiguration", "向量身份字段缺失")
    ids = [case.get("id") for case in payload.get("cases", [])]
    if not ids or len(ids) != len(set(ids)):
        raise ContractError("invalidConfiguration", "向量 ID 为空或重复")
    for case, config in resolve_vector_configs(payload):
        try:
            ZoneInfo(case["timeZone"])
        except (KeyError, ZoneInfoNotFoundError) as exc:
            raise ContractError("invalidConfiguration", f"{case['id']} 时区无效") from exc
        now = datetime.fromisoformat(case["now"])
        actual = ReferenceCalculator(config).calculate(now)
        if actual != case["expected"]:
            raise ContractError(
                "vectorMismatch",
                f"{case['id']} 不匹配\nexpected={case['expected']}\nactual={actual}",
            )


def validate_holidays(path: Path) -> None:
    manifest = load_json(path)
    if manifest.get("datasetVersion") != "cn-mainland-2025-2026-v1":
        raise ContractError("holidayDatasetMismatch", "数据集版本不正确")
    seen_years: set[int] = set()
    for item in manifest.get("files", []):
        target = path.parent / item["path"]
        if not target.is_file():
            raise ContractError("holidayDatasetMismatch", f"缺少 {item['path']}")
        digest = hashlib.sha256(target.read_bytes()).hexdigest().upper()
        if digest != item["sha256"]:
            raise ContractError("holidayDatasetMismatch", f"{item['path']} SHA256 不匹配")
        payload = load_json(target)
        if payload.get("year") != item["year"] or payload.get("status") != item["status"]:
            raise ContractError("holidayDatasetMismatch", f"{item['path']} 元数据不匹配")
        if item["year"] in seen_years:
            raise ContractError("holidayDatasetMismatch", f"年份重复: {item['year']}")
        seen_years.add(item["year"])
        if item["status"] == "official":
            holidays = {parse_date(value, "holidays") for value in payload["holidays"]}
            adjusted = {parse_date(value, "adjustedWorkdays") for value in payload["adjustedWorkdays"]}
            if holidays & adjusted:
                raise ContractError("holidayDatasetMismatch", f"{item['year']} 休息日与调休日重叠")
            if any(value.year != item["year"] for value in holidays | adjusted):
                raise ContractError("holidayDatasetMismatch", f"{item['year']} 包含跨年日期")
            if not payload.get("sourceUrl", "").startswith("https://www.gov.cn/"):
                raise ContractError("holidayDatasetMismatch", f"{item['year']} 缺少政府来源")
    if set(manifest.get("coveredYears", [])) != {2025, 2026} or set(manifest.get("unavailableYears", [])) != {2027}:
        raise ContractError("holidayDatasetMismatch", "覆盖范围必须明确为 2025-2026，2027 不可用")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("mode", choices=("config", "vectors", "holidays"))
    parser.add_argument("path", type=Path)
    args = parser.parse_args()
    try:
        if args.mode == "config":
            validate_config(load_json(args.path))
        elif args.mode == "vectors":
            validate_vectors(args.path)
        else:
            validate_holidays(args.path)
    except (ContractError, OSError, json.JSONDecodeError, KeyError, TypeError, ValueError) as exc:
        code = exc.code if isinstance(exc, ContractError) else "invalidConfiguration"
        print(f"FAIL [{code}] {exc}", file=sys.stderr)
        return 1
    print(f"PASS {args.mode}: {args.path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
