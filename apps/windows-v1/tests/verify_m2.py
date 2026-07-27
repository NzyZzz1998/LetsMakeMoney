from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TAURI = ROOT / "src-tauri" / "src"

checks = {
    "domain-service": all((TAURI / name).exists() for name in ("domain.rs", "config.rs", "support.rs")),
    "salary-modes": all(
        token in (TAURI / "domain.rs").read_text(encoding="utf-8")
        for token in ("RestMode::Single", "RestMode::Double", "RestMode::Alternating")
    ),
    "alternating-explicit": "alternating_week_type_required" in (TAURI / "domain.rs").read_text(encoding="utf-8"),
    "schedule-lunch-night": all(
        token in (TAURI / "domain.rs").read_text(encoding="utf-8")
        for token in ("lunch", "overnight", "schedule_owner_date")
    ),
    "calendar-priority": all(
        token in (TAURI / "domain.rs").read_text(encoding="utf-8")
        for token in ("manual_workday", "adjusted_workday", "statutory_holiday")
    ),
    "migration-no-pet": all(
        token in (TAURI / "config.rs").read_text(encoding="utf-8")
        for token in ("migrate_v5", "config_version", "migration_drops_pet_fields")
    ),
    "transactional-save": all(
        token in (TAURI / "config.rs").read_text(encoding="utf-8")
        for token in ("json.tmp", "json.previous", "SideEffectDenied", "draft_preserved")
    ),
    "support-services": all(
        token in (TAURI / "support.rs").read_text(encoding="utf-8")
        for token in ("RotatingLogger", "DiagnosticSummary", "UpdateStatus")
    ),
    "tauri-commands": all(
        token in (TAURI / "lib.rs").read_text(encoding="utf-8")
        for token in (
            "calculate_month_salary",
            "calculate_today_income",
            "resolve_calendar_month",
            "resolve_next_workday",
            "save_configuration",
            "diagnostic_summary",
        )
    ),
    "calendar-shared-rules": all(
        token in (TAURI / "domain.rs").read_text(encoding="utf-8")
        for token in ("resolve_month_days", "next_workday", "CalendarDay")
    ),
    "fixtures-present": all(
        (ROOT / "tests" / "fixtures" / name).exists()
        for name in ("salary-schedule-fixtures.json", "migration-fixtures.json")
    ),
}

for name, passed in checks.items():
    print(f"{'PASS' if passed else 'FAIL'} {name}")

failed = [name for name, passed in checks.items() if not passed]
if failed:
    raise SystemExit(f"M2 checks failed: {', '.join(failed)}")
print(f"V10-M2 static PASS {len(checks)}/{len(checks)}")
