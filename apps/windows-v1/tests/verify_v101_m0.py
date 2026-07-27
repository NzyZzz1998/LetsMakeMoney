from __future__ import annotations

import hashlib
import json
import re
import sys
from pathlib import Path


APP_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = APP_ROOT.parents[1]
CONTRACTS = APP_ROOT / "contracts"
CALENDAR_DATA = APP_ROOT / "calendar-data"
FIXTURES = APP_ROOT / "tests" / "fixtures"


def load_json(path: Path) -> object:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def verify_required_files() -> None:
    required = [
        CONTRACTS / "config-v101.schema.json",
        CONTRACTS / "config-v101-defaults.json",
        CONTRACTS / "calendar-data.schema.json",
        CONTRACTS / "calendar-manifest.schema.json",
        CONTRACTS / "migration-v101-contract.json",
        CONTRACTS / "salary-v101-contract.json",
        CONTRACTS / "log-v101-contract.json",
        CALENDAR_DATA / "manifest.json",
        CALENDAR_DATA / "cn-2025.json",
        CALENDAR_DATA / "cn-2026.json",
        FIXTURES / "v101-calendar-fixtures.json",
        FIXTURES / "v101-override-migration-fixtures.json",
        FIXTURES / "v101-salary-fixtures.json",
        FIXTURES / "v101-sync-fixtures.json",
        REPO_ROOT / "doc" / "releases" / "v1.0.1" / "verification.md",
        REPO_ROOT / "doc" / "releases" / "v1.0.1" / "manual-verification.md",
    ]
    missing = [path.relative_to(REPO_ROOT).as_posix() for path in required if not path.is_file()]
    require(not missing, f"Missing v1.0.1 M0 files: {missing}")


def verify_config_contract() -> None:
    schema = load_json(CONTRACTS / "config-v101.schema.json")
    defaults = load_json(CONTRACTS / "config-v101-defaults.json")
    require(defaults["config_version"] == 7, "v1.0.1 config version must be 7")
    require(set(schema["required"]) == set(defaults), "v1.0.1 defaults and required keys differ")
    override_kind = schema["properties"]["date_overrides"]["items"]["properties"]["kind"]
    require(
        override_kind["enum"] == ["workday", "paid_rest", "unpaid_rest"],
        "Date override kinds must be workday/paid_rest/unpaid_rest",
    )
    require("rest_day" not in json.dumps(schema), "Legacy rest_day must not be a v7 write value")


def verify_calendar_manifest() -> None:
    manifest = load_json(CALENDAR_DATA / "manifest.json")
    require(manifest["schema_version"] == 1, "Calendar manifest schema version drift")
    require(manifest["supported_years"] == [2025, 2026], "Supported calendar years must be 2025 and 2026")
    require(len(manifest["datasets"]) == 2, "Calendar manifest must contain exactly two annual datasets")
    for item in manifest["datasets"]:
        path = CALENDAR_DATA / item["file"]
        require(path.is_file(), f"Calendar dataset is missing: {item['file']}")
        require(sha256(path) == item["sha256"], f"Calendar hash mismatch: {item['file']}")
        data = load_json(path)
        require(data["year"] == item["year"], f"Calendar year mismatch: {item['file']}")
        require(data["source"]["publisher"] == "国务院办公厅", f"Untrusted publisher: {item['file']}")
        require(data["holidays"], f"Calendar holidays are empty: {item['file']}")


def verify_behavior_fixtures() -> None:
    calendar = load_json(FIXTURES / "v101-calendar-fixtures.json")
    migration = load_json(FIXTURES / "v101-override-migration-fixtures.json")
    salary = load_json(FIXTURES / "v101-salary-fixtures.json")
    sync = load_json(FIXTURES / "v101-sync-fixtures.json")

    calendar_ids = {case["id"] for case in calendar["cases"]}
    require(
        {
            "official-holiday",
            "official-adjusted-workday",
            "unsupported-year",
            "hash-mismatch",
            "late-request-ignored",
            "stale-keeps-last-valid-month",
        }
        <= calendar_ids,
        "Calendar fixture matrix is incomplete",
    )
    migration_ids = {case["id"] for case in migration["cases"]}
    require(
        {
            "legacy-workday-kept",
            "legacy-rest-on-auto-workday-becomes-paid",
            "legacy-rest-on-auto-rest-removed",
            "unknown-kind-backed-up-and-rejected",
        }
        <= migration_ids,
        "Override migration fixture matrix is incomplete",
    )
    salary_ids = {case["id"] for case in salary["cases"]}
    require(
        {
            "overnight-owner-before-end",
            "overnight-owner-after-end",
            "paid-rest-keeps-slot-amount",
            "unpaid-rest-keeps-slot-but-zeroes-contribution",
            "manual-workday-adds-slot",
            "month-cent-conservation",
            "zero-slot-error",
        }
        <= salary_ids,
        "Salary fixture matrix is incomplete",
    )
    sync_ids = {case["id"] for case in sync["cases"]}
    require(
        {
            "working-local-tick",
            "lunch-freeze",
            "thirty-second-authoritative-sync",
            "resume-immediate-sync",
            "one-cent-tolerance",
            "late-authoritative-snapshot-ignored",
        }
        <= sync_ids,
        "Sync fixture matrix is incomplete",
    )


def verify_contract_formulas_and_logs() -> None:
    migration = load_json(CONTRACTS / "migration-v101-contract.json")
    salary = load_json(CONTRACTS / "salary-v101-contract.json")
    logs = load_json(CONTRACTS / "log-v101-contract.json")
    require(migration["source_config_version"] == 6, "Migration source must be config v6")
    require(migration["target_config_version"] == 7, "Migration target must be config v7")
    require(
        migration["legacy_rest_day"]["automatic_workday"] == "paid_rest",
        "Legacy rest_day on an automatic workday must migrate to paid_rest",
    )
    require(
        migration["legacy_rest_day"]["automatic_rest"] == "remove_after_backup",
        "Redundant legacy rest_day must be removed after backup",
    )
    require(migration["unknown_kind"] == "backup_and_reject_override", "Unknown kinds must fail closed")
    require(salary["minor_unit"] == "cent", "Salary calculations must use integer cents")
    require(salary["cumulative_formula"] == "round(S*k/N)", "Cumulative salary formula drift")
    require(salary["slot_formula"] == "C(k)-C(k-1)", "Salary slot formula drift")
    events = set(logs["events"])
    required_events = {
        "calendar.dataset.loaded",
        "calendar.dataset.failed",
        "calendar.request.ignored",
        "date_override.saved",
        "date_override.unchanged",
        "date_override.failed",
        "date_override.removed",
        "date_override.migrated",
        "earnings.authoritative_sync.drift_corrected",
        "earnings.authoritative_sync.failed",
    }
    require(required_events <= events, f"Missing v1.0.1 log events: {sorted(required_events - events)}")
    serialized = json.dumps(logs, ensure_ascii=False)
    require("monthly_salary" in serialized, "Salary must remain redacted")
    require(not re.search(r"[A-Za-z]:\\\\Users\\\\", serialized), "Log contract contains an absolute user path")


def main() -> int:
    checks = [
        verify_required_files,
        verify_config_contract,
        verify_calendar_manifest,
        verify_behavior_fixtures,
        verify_contract_formulas_and_logs,
    ]
    try:
        for check in checks:
            check()
            print(f"PASS {check.__name__}")
    except (AssertionError, KeyError, TypeError, json.JSONDecodeError) as error:
        print(f"FAIL {error}", file=sys.stderr)
        return 1
    print(f"PASS v1.0.1 M0 contracts ({len(checks)} checks)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
