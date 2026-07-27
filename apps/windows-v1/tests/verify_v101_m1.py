from __future__ import annotations

import hashlib
import json
import sys
from datetime import date
from pathlib import Path


APP_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = APP_ROOT.parents[1]
CALENDAR_DATA = APP_ROOT / "calendar-data"


def load_json(path: Path) -> object:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def verify_manifest_and_datasets() -> None:
    manifest = load_json(CALENDAR_DATA / "manifest.json")
    require(manifest["supported_years"] == [2025, 2026], "Supported calendar years drifted")
    for entry in manifest["datasets"]:
        dataset_path = CALENDAR_DATA / entry["file"]
        raw = dataset_path.read_bytes()
        dataset = json.loads(raw)
        require(
            hashlib.sha256(raw).hexdigest().upper() == entry["sha256"],
            f"Calendar hash mismatch: {entry['file']}",
        )
        require(dataset["year"] == entry["year"], f"Calendar year mismatch: {entry['file']}")
        require(
            dataset["source"]["url"].startswith("https://www.gov.cn/"),
            f"Calendar source is not official: {entry['file']}",
        )
        holidays = set(dataset["holiday_dates"])
        adjusted = set(dataset["adjusted_workdays"])
        require(holidays, f"Calendar holidays are empty: {entry['file']}")
        require(not holidays & adjusted, f"Calendar dates overlap: {entry['file']}")
        for value in holidays | adjusted:
            parsed = date.fromisoformat(value)
            require(parsed.year == entry["year"], f"Calendar date is outside its year: {value}")


def verify_known_official_dates() -> None:
    data_2025 = load_json(CALENDAR_DATA / "cn-2025.json")
    data_2026 = load_json(CALENDAR_DATA / "cn-2026.json")
    require("2025-01-01" in data_2025["holiday_dates"], "2025 New Year holiday missing")
    require("2025-02-08" in data_2025["adjusted_workdays"], "2025 Spring Festival workday missing")
    require("2026-02-18" in data_2026["holiday_dates"], "2026 Spring Festival holiday missing")
    require("2026-02-28" in data_2026["adjusted_workdays"], "2026 Spring Festival workday missing")


def verify_native_loader() -> None:
    source = read(APP_ROOT / "src-tauri" / "src" / "calendar_data.rs")
    lib = read(APP_ROOT / "src-tauri" / "src" / "lib.rs")
    required_loader_tokens = [
        "include_str!",
        "Sha256::digest",
        "calendar_year_unsupported",
        "calendar_hash_mismatch",
        "calendar_dataset_invalid",
        "https://www.gov.cn/",
    ]
    for token in required_loader_tokens:
        require(token in source, f"Native calendar loader is missing: {token}")
    require("fn load_calendar_year(" in lib, "Tauri calendar command is missing")
    require("calendar.dataset.loaded" in lib, "Calendar success log is missing")
    require("calendar.dataset.failed" in lib, "Calendar failure log is missing")
    require("load_calendar_year," in lib, "Calendar command is not registered")


def verify_frontend_state_machine() -> None:
    state = read(APP_ROOT / "src" / "calendarState.ts")
    model = read(APP_ROOT / "src" / "model.ts")
    app = read(APP_ROOT / "src" / "App.tsx")
    for status in ["loading", "ready", "empty", "stale", "error", "unsupported"]:
        require(f'"{status}"' in state, f"Calendar state is missing: {status}")
    for token in ["requestId", "action.requestId !== state.requestId", 'state.data ? "stale"']:
        require(token in state, f"Calendar request ordering contract is missing: {token}")
    for token in [
        "calendar.request.ignored",
        "calendar.dataset.stale",
        "loadCalendarForYear",
        "calendarDatasetCache",
    ]:
        require(token in model, f"Calendar runtime integration is missing: {token}")
    for copy in [
        "正在读取",
        "没有可用日期数据",
        "重试",
        "当前仅支持 2025—2026 年日历",
        "上次有效数据",
    ]:
        require(copy in app, f"Calendar user feedback is missing: {copy}")


def verify_no_secret_or_absolute_path() -> None:
    files = [
        CALENDAR_DATA / "manifest.json",
        CALENDAR_DATA / "cn-2025.json",
        CALENDAR_DATA / "cn-2026.json",
        APP_ROOT / "src-tauri" / "src" / "calendar_data.rs",
        APP_ROOT / "src" / "calendarState.ts",
    ]
    content = "\n".join(read(path) for path in files)
    require("C:\\Users\\" not in content, "Calendar implementation contains a Windows user path")
    require("E:\\codex\\" not in content, "Calendar implementation contains a workspace path")


def main() -> int:
    checks = [
        verify_manifest_and_datasets,
        verify_known_official_dates,
        verify_native_loader,
        verify_frontend_state_machine,
        verify_no_secret_or_absolute_path,
    ]
    try:
        for check in checks:
            check()
            print(f"PASS {check.__name__}")
    except (AssertionError, KeyError, TypeError, ValueError, json.JSONDecodeError) as error:
        print(f"FAIL {error}", file=sys.stderr)
        return 1
    print(f"PASS v1.0.1 M1 calendar integration ({len(checks)} checks)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
