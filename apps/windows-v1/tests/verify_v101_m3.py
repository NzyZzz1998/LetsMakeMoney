from __future__ import annotations

import json
import sys
from pathlib import Path


APP_ROOT = Path(__file__).resolve().parents[1]


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def load_json(path: Path) -> object:
    return json.loads(read(path))


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def cumulative(monthly_minor: int, slots: int, completed: int) -> int:
    require(slots > 0, "Fixture salary slot count must be positive")
    return (monthly_minor * completed + slots // 2) // slots


def verify_salary_contract_and_fixtures() -> None:
    contract = load_json(APP_ROOT / "contracts" / "salary-v101-contract.json")
    require(contract["minor_unit"] == "cent", "Salary contract must use integer cents")
    require(contract["cumulative_formula"] == "round(S*k/N)", "Cumulative formula drifted")
    require(contract["slot_formula"] == "C(k)-C(k-1)", "Slot formula drifted")
    require(
        contract["today_formula"]
        == "round(S*((k-1)*E+e)/(N*E))-round(S*(k-1)/N)",
        "Today cumulative formula drifted",
    )
    fixtures = load_json(APP_ROOT / "tests" / "fixtures" / "v101-salary-fixtures.json")
    case_ids = {case["id"] for case in fixtures["cases"]}
    required = {
        "overnight-owner-before-end",
        "overnight-owner-after-end",
        "paid-rest-keeps-slot-amount",
        "unpaid-rest-keeps-slot-but-zeroes-contribution",
        "manual-workday-adds-slot",
        "month-cent-conservation",
        "zero-slot-error",
    }
    require(required <= case_ids, f"Salary fixtures are missing: {sorted(required - case_ids)}")
    conservation = next(
        case for case in fixtures["cases"] if case["id"] == "month-cent-conservation"
    )
    total = sum(
        cumulative(
            conservation["monthly_salary_minor"],
            conservation["slots"],
            index,
        )
        - cumulative(
            conservation["monthly_salary_minor"],
            conservation["slots"],
            index - 1,
        )
        for index in range(1, conservation["slots"] + 1)
    )
    require(total == conservation["expected_sum"], "Fixture cents do not conserve")


def verify_native_behavior() -> None:
    domain = read(APP_ROOT / "src-tauri" / "src" / "domain.rs")
    lib = read(APP_ROOT / "src-tauri" / "src" / "lib.rs")
    for token in [
        "pub enum SalarySlotKind",
        "pub struct SalarySlot",
        "pub fn salary_cumulative",
        "pub fn salary_slot_target",
        "pub fn resolve_schedule_owner_date",
        "today_earned_for_work_slot",
        "salary.zero_slots",
        "schedule.owner_date_mismatch",
        "salary-v101-cumulative-v1",
    ]:
        require(token in domain, f"Native salary implementation is missing: {token}")
    for test in [
        "overnight_owner_date_changes_at_shift_end",
        "adjacent_cumulative_slots_conserve_every_cent",
        "paid_and_unpaid_rest_keep_slot_but_change_workdays_and_payable_amount",
        "manual_workday_on_automatic_rest_adds_a_salary_slot",
        "paid_and_unpaid_today_states_use_the_salary_slot_contract",
        "month_without_salary_slots_has_a_readable_error",
    ]:
        require(test in domain, f"Native behavior test is missing: {test}")
    require("month_salary: domain::MonthSalary" in lib, "Today command lacks month salary input")
    require(
        "resolve_schedule_owner_date," in lib,
        "Owner-date command is not registered",
    )


def verify_frontend_consumes_authority() -> None:
    model = read(APP_ROOT / "src" / "model.ts")
    app = read(APP_ROOT / "src" / "App.tsx")
    for token in [
        'invoke<string>("resolve_schedule_owner_date"',
        'invoke<MonthSalaryResult>("calculate_month_salary"',
        "month_earned_minor",
        "payable_salary_minor",
        "salary_slot_count",
        "daily_target_minor",
    ]:
        require(token in model, f"Frontend authority flow is missing: {token}")
    for copy in [
        "今日带薪金额",
        "今天不计算收入",
        "本月预计应发",
        "今天不计算有效工时",
    ]:
        require(copy in app, f"Paid/unpaid rest UI is missing: {copy}")


def verify_no_sensitive_paths() -> None:
    files = [
        APP_ROOT / "src-tauri" / "src" / "domain.rs",
        APP_ROOT / "src" / "model.ts",
        APP_ROOT / "tests" / "fixtures" / "v101-salary-fixtures.json",
    ]
    content = "\n".join(read(path) for path in files)
    require("C:\\Users\\" not in content, "M3 contains a Windows user path")
    require("E:\\codex\\" not in content, "M3 contains a workspace path")


def main() -> int:
    checks = [
        verify_salary_contract_and_fixtures,
        verify_native_behavior,
        verify_frontend_consumes_authority,
        verify_no_sensitive_paths,
    ]
    try:
        for check in checks:
            check()
            print(f"PASS {check.__name__}")
    except (AssertionError, KeyError, TypeError, ValueError, json.JSONDecodeError) as error:
        print(f"FAIL {error}", file=sys.stderr)
        return 1
    print(f"PASS v1.0.1 M3 owner date and cent conservation ({len(checks)} checks)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
