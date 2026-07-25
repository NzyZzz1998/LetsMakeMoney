from __future__ import annotations

import json
import sys
from pathlib import Path


APP_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = APP_ROOT.parents[1]
CONTRACTS = APP_ROOT / "contracts"
FIXTURES = APP_ROOT / "tests" / "fixtures"


def load_json(path: Path) -> object:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def verify_config_contract() -> None:
    schema = load_json(CONTRACTS / "config-v1.schema.json")
    defaults = load_json(CONTRACTS / "config-defaults.json")
    properties = schema["properties"]

    require(set(schema["required"]) == set(defaults), "Defaults and required config keys differ")
    require(defaults["config_version"] == 6, "config_version must be 6")
    require(defaults["work_hours_per_day"] == 8, "Default work duration must be 8 hours")
    require(defaults["alternating_anchor_week_type"] is None, "Alternating week type must not default")
    require(properties["alternating_anchor_week_type"]["default"] is None, "Schema must not choose big/small")

    forbidden = ("pet", "pure_pet", "click_through")
    for key in defaults:
        require(not any(marker in key for marker in forbidden), f"Pet field leaked into v1 defaults: {key}")


def verify_salary_fixtures() -> None:
    document = load_json(FIXTURES / "salary-schedule-fixtures.json")
    cases = document["cases"]
    ids = {case["id"] for case in cases}
    require(len(ids) == len(cases), "Salary fixture ids must be unique")

    required = {
        "double-weekend-2026-02",
        "single-weekend-2026-02",
        "alternating-big-anchor-2026-02",
        "alternating-small-anchor-2026-02",
        "alternating-week-type-required",
        "default-eight-hours-before-lunch",
        "lunch-freezes-income",
        "night-shift-owned-by-start-date",
        "calendar-priority-manual-over-holiday",
        "calendar-priority-adjusted-over-rest-mode",
    }
    require(required <= ids, f"Missing salary fixtures: {sorted(required - ids)}")

    by_id = {case["id"]: case for case in cases}
    require(by_id["double-weekend-2026-02"]["expected_workdays"] == 20, "Double weekend baseline drift")
    require(by_id["single-weekend-2026-02"]["expected_workdays"] == 24, "Single weekend baseline drift")
    require(by_id["alternating-big-anchor-2026-02"]["expected_workdays"] == 22, "Alternating big drift")
    require(by_id["alternating-small-anchor-2026-02"]["expected_workdays"] == 22, "Alternating small drift")
    require(
        by_id["alternating-week-type-required"]["expected_error"] == "alternating_week_type_required",
        "Alternating validation baseline drift",
    )
    require(by_id["lunch-freezes-income"]["expected_state"] == "lunch", "Lunch must freeze income")
    require(
        by_id["night-shift-owned-by-start-date"]["expected_effective_work_seconds"] == 28800,
        "Night shift must preserve eight effective hours",
    )


def verify_platform_contracts() -> None:
    windows = load_json(CONTRACTS / "window-contract.json")
    logs = load_json(CONTRACTS / "log-contract.json")
    visual = load_json(CONTRACTS / "visual-contract.json")

    by_id = {window["id"]: window for window in windows["windows"]}
    require(by_id["mini"]["default_size"] == [344, 120], "Mini window dimensions drift")
    require(by_id["workbench"]["default_size"] == [920, 640], "Workbench dimensions drift")
    require(by_id["settings"]["default_size"] == [760, 560], "Settings dimensions drift")
    require(by_id["wizard"]["default_size"] == [780, 580], "Wizard dimensions drift")
    require(windows["tray"]["left_click"] == "toggle_mini_visibility", "Tray left click contract drift")
    require(windows["single_instance"]["duplicate_windows"] is False, "Duplicate windows must be forbidden")

    events = set(logs["events"])
    for event in (
        "config.save.saved",
        "config.save.unchanged",
        "config.save.failed",
        "tray.command",
        "window.applied",
        "diagnostics.summary_copied",
    ):
        require(event in events, f"Missing semantic event: {event}")
    require("monthly_salary" in logs["redaction"]["forbidden_values"], "Salary must be redacted")
    require(visual["dpi_percent"] == [100, 125, 150], "DPI contract drift")


def verify_formal_project_boundary() -> None:
    package = load_json(APP_ROOT / "package.json")
    package_lock = load_json(APP_ROOT / "package-lock.json")
    tauri = load_json(APP_ROOT / "src-tauri" / "tauri.conf.json")
    cargo = (APP_ROOT / "src-tauri" / "Cargo.toml").read_text(encoding="utf-8")
    cargo_lock = (APP_ROOT / "src-tauri" / "Cargo.lock").read_text(encoding="utf-8")

    require(package["dependencies"]["react"] == "19.1.1", "React version must match approved spike")
    require(package["dependencies"]["@tauri-apps/api"] == "2.11.1", "Tauri API version drift")
    require(package_lock["name"] == package["name"], "npm lock identity differs from package")
    require(package_lock["version"] == package["version"], "npm lock version differs from package")
    require('tauri = { version = "=2.11.5"' in cargo, "Rust Tauri version drift")
    require('name = "letsmakemoney_windows_v1"' in cargo_lock, "Cargo lock identity differs from package")
    require(tauri["app"]["windows"][0]["label"] == "mini", "Formal shell must start with mini window")

    forbidden_fragments = ("petmanager", "pet_id", "pure_pet_mode", "click_through")
    text_extensions = {".css", ".html", ".js", ".json", ".md", ".ps1", ".rs", ".toml", ".ts", ".tsx"}
    generated_directories = {"dist", "node_modules", "target"}
    for path in APP_ROOT.rglob("*"):
        relative_path = path.relative_to(APP_ROOT)
        if (
            not path.is_file()
            or path.suffix.lower() not in text_extensions
            or any(part in generated_directories for part in relative_path.parts)
        ):
            continue
        text = path.read_text(encoding="utf-8")
        relative = relative_path.as_posix()
        if relative.startswith(("contracts/", "tests/")):
            continue
        if path.suffix.lower() == ".rs":
            text = text.split("#[cfg(test)]", 1)[0]
        for fragment in forbidden_fragments:
            require(fragment not in text.lower(), f"Forbidden v0.9 pet capability in formal app: {relative}")


def verify_docs_exist() -> None:
    required = [
        REPO_ROOT / "doc/releases/v1.0/implementation-baseline.md",
        REPO_ROOT / "doc/releases/v1.0/verification.md",
        REPO_ROOT / "doc/releases/v1.0/manual-verification.md",
        REPO_ROOT / "doc/releases/v1.0/release-checklist.md",
    ]
    missing = [path.relative_to(REPO_ROOT).as_posix() for path in required if not path.is_file()]
    require(not missing, f"Missing M0 documents: {missing}")


def verify_ci_utf8_environment() -> None:
    workflow = (REPO_ROOT / ".github/workflows/windows-v1-verify.yml").read_text(encoding="utf-8")
    require('PYTHONUTF8: "1"' in workflow, "Windows CI must force Python UTF-8 mode")
    require('PYTHONIOENCODING: "utf-8"' in workflow, "Windows CI must use UTF-8 standard streams")
    require("cargo fetch --locked" in workflow, "Windows CI must fetch locked Rust dependencies before offline checks")


def main() -> int:
    checks = [
        verify_config_contract,
        verify_salary_fixtures,
        verify_platform_contracts,
        verify_formal_project_boundary,
        verify_docs_exist,
        verify_ci_utf8_environment,
    ]
    try:
        for check in checks:
            check()
            print(f"PASS {check.__name__}")
    except (AssertionError, KeyError, TypeError, json.JSONDecodeError) as error:
        print(f"FAIL {error}", file=sys.stderr)
        return 1

    print(f"PASS v1.0 M0 contracts ({len(checks)} checks)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
