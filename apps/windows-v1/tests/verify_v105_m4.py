from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Any

from verify_v105_m3 import load_json, require, validate_evidence as validate_m3_evidence


APP_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = APP_ROOT.parents[1]
RELEASE_ROOT = REPO_ROOT / "doc" / "releases" / "v1.0.5"
EVIDENCE_ROOT = RELEASE_ROOT / "evidence"
EVIDENCE_PATH = EVIDENCE_ROOT / "m4-calendar-presentation-summary.json"
M3_EVIDENCE_PATH = EVIDENCE_ROOT / "m3-mini-privacy-summary.json"
BASELINE_HEAD = "8a63da7836fb24c3b7f8ff12f896ac40571adeb7"

EXPECTED_BUSINESS_STATES = {
    "workday",
    "rest_day",
    "adjusted_workday",
    "manual_workday",
    "paid_rest",
    "unpaid_rest",
}
EXPECTED_RISK_STATES = {"estimated", "stale", "loading", "integrity_error"}


def contains_sensitive_value(value: Any) -> bool:
    serialized = json.dumps(value, ensure_ascii=False)
    if re.search(r"(?i)[A-Z]:[\\/](?:Users|Work|codex)[\\/]", serialized):
        return True
    if isinstance(value, dict):
        for key, child in value.items():
            normalized = re.sub(r"[^a-z0-9]", "", str(key).lower())
            if normalized in {"token", "password", "privatekey", "secret"}:
                if child not in (None, "", "redacted", "[redacted]"):
                    return True
            if contains_sensitive_value(child):
                return True
    elif isinstance(value, list):
        return any(contains_sensitive_value(child) for child in value)
    return False


def validate_evidence(value: dict[str, Any]) -> None:
    require(value.get("schema_version") == 1, "M4 schema version drift")
    require(value.get("milestone") == "V105-M4", "M4 milestone drift")

    candidate = value["candidate"]
    require(candidate["kind"] == "dirty-controlled-m4-candidate", "M4 candidate kind drift")
    require(candidate["source_head"] == BASELINE_HEAD, "M4 source baseline drift")
    require(candidate["source_tree_dirty"] is True, "M4 candidate must disclose its dirty source tree")
    require(bool(re.fullmatch(r"V105-M4-[0-9]{8}-[0-9]{6}", candidate["candidate_id"])), "M4 candidate id drift")
    for field in ("staged_exe_sha256", "native_dll_sha256"):
        require(bool(re.fullmatch(r"[A-F0-9]{64}", candidate[field])), f"invalid candidate hash: {field}")
    require(candidate["identity_path"].startswith(".artifacts/candidates/v1.0.5/"), "M4 identity path drift")

    automation = value["automation"]
    for field in ("architecture", "typescript", "web_build", "cargo_test", "clippy"):
        require(automation[field] == "pass", f"M4 automation did not pass: {field}")
    require(automation["calendar_matrix_assertions"] >= 49, "M4 calendar matrix coverage drift")
    require(set(automation["themes"]) == {"light", "dark"}, "M4 theme coverage drift")
    require(set(automation["dpi_contracts"]) == {100, 125, 150}, "M4 DPI contract coverage drift")

    coverage = value["coverage"]
    require(coverage["official_primary_surface"] == "hidden", "normal official source block must be hidden")
    require(set(coverage["risk_states_visible"]) == EXPECTED_RISK_STATES, "risk-state visibility coverage drift")
    require(coverage["retry_contract"] == "pass", "calendar retry contract did not pass")

    cells = value["calendar_cells"]
    require(cells["today_scheme"] == "A-corner-badge", "unapproved today scheme")
    require(cells["today_cue"] == "今", "today cue drift")
    require(set(cells["business_states"]) == EXPECTED_BUSINESS_STATES, "business-state coverage drift")
    for field in (
        "business_layer",
        "selected_layer",
        "today_layer",
        "interaction_layer",
        "non_color_cues",
        "aria_contract",
        "keyboard_contract",
    ):
        require(cells[field] == "pass", f"calendar cell contract did not pass: {field}")

    desktop = value["desktop"]
    for field in (
        "official_quiet",
        "estimated_visible",
        "today_selected_business_composite",
        "light_theme",
        "dark_theme",
        "long_content",
    ):
        require(desktop[field] == "pass", f"M4 desktop verification did not pass: {field}")
    require(desktop["dpi_100"] == "pass", "100% DPI desktop check did not pass")
    require(desktop["dpi_125"] in {"pass", "automated-contract"}, "125% DPI evidence missing")
    require(desktop["dpi_150"] in {"pass", "automated-contract"}, "150% DPI evidence missing")

    integrity = value["baseline_integrity"]
    require(integrity["configuration_restored"] is True, "M4 configuration was not restored")
    require(integrity["debug_log_restored"] is True, "M4 debug log was not restored")
    require(integrity["registry_changed"] is False, "M4 changed registry state")
    require(integrity["remaining_processes"] == 0, "M4 left a process running")
    require(integrity["income_formula_changed"] is False, "M4 changed income formula")
    require(integrity["calendar_data_changed"] is False, "M4 changed calendar data")
    require(integrity["configuration_schema_changed"] is False, "M4 changed configuration schema")

    raw = value["raw_evidence"]
    require(raw["storage"] == "local-ignored", "M4 raw evidence storage drift")
    require(raw["index"].startswith(".artifacts/acceptance/v1.0.5/"), "M4 raw evidence index drift")
    require(raw["repository_contains_raw_screenshots_or_logs"] is False, "raw evidence must remain untracked")

    conclusion = value["conclusion"]
    require(conclusion["milestone"] == "passed", "M4 conclusion drift")
    require(conclusion["completed_tasks"] == 8, "M4 task count drift")
    require(conclusion["release_created"] is False, "M4 must not create a Release")
    require(conclusion["next_milestone"] == "V105-M5", "M4 next milestone drift")
    require(not contains_sensitive_value(value), "M4 evidence contains an absolute path or secret-like value")


def verify_required_files() -> None:
    required = [
        EVIDENCE_PATH,
        APP_ROOT / "src" / "presentation.ts",
        APP_ROOT / "src" / "App.tsx",
        APP_ROOT / "src" / "styles.css",
        APP_ROOT / "tests" / "calendar-v105-presentation.behavior.ts",
        APP_ROOT / "tests" / "verify_v105_m4.py",
        APP_ROOT / "tests" / "verify_v105_m4_tests.py",
        REPO_ROOT / "doc" / "prototypes" / "v1.0" / "app.js",
        REPO_ROOT / "doc" / "prototypes" / "v1.0" / "styles.css",
    ]
    missing = [path.relative_to(REPO_ROOT).as_posix() for path in required if not path.is_file()]
    require(not missing, f"missing M4 files: {missing}")


def verify_coverage_contract() -> None:
    presentation = (APP_ROOT / "src" / "presentation.ts").read_text(encoding="utf-8")
    app = (APP_ROOT / "src" / "App.tsx").read_text(encoding="utf-8")
    for mode in ("official", "estimated", "stale", "integrity_error"):
        require(f'"{mode}"' in presentation, f"coverage mode missing: {mode}")
    require("isVisible: false" in presentation and "tone: null" in presentation, "official quiet contract missing")
    require("不代表法定放假安排" in presentation, "estimated disclosure missing")
    require("上次有效数据" in presentation, "stale retained-data disclosure missing")
    require("未使用估算结果替代" in presentation, "integrity-error safeguard missing")
    require("calendarCoveragePresentation(coverage)" in app, "coverage selector not consumed")
    require("if (!content.isVisible || content.tone === null) return null" in app, "official source block still occupies UI")


def verify_calendar_layers() -> None:
    presentation = (APP_ROOT / "src" / "presentation.ts").read_text(encoding="utf-8")
    app = (APP_ROOT / "src" / "App.tsx").read_text(encoding="utf-8")
    styles = (APP_ROOT / "src" / "styles.css").read_text(encoding="utf-8")
    behavior = (APP_ROOT / "tests" / "calendar-v105-presentation.behavior.ts").read_text(encoding="utf-8")

    for state in EXPECTED_BUSINESS_STATES:
        require(f'"{state}"' in behavior, f"calendar matrix missing business state: {state}")
    require("calendar-day--${input.businessState}" in presentation, "calendar business-state class mapping missing")
    for state in EXPECTED_BUSINESS_STATES - {"workday"}:
        require(f"calendar-day--{state}" in styles, f"calendar CSS missing non-default business state: {state}")
    for layer in ("is-today", "is-selected", "is-stale", "is-disabled"):
        require(layer in presentation and layer in styles, f"calendar layer missing: {layer}")
    require('todayCue: input.isToday ? "今" : null' in presentation, "approved today cue missing")
    require('className="calendar-day__today"' in app, "today cue element missing")
    require('className="legend-today"' in app, "today legend missing")
    require("legend-ring" not in app, "legacy circular today legend remains")
    require(".calendar-day__today" in styles and "top: 4px" in styles and "left: 4px" in styles, "corner badge geometry drift")
    require("button.is-today .calendar-day__number { font-weight: 700; }" in styles, "today number emphasis missing")
    require("button.is-selected { border-color:" in styles, "selected-date border missing")
    require("button:focus-visible" in styles and "outline" in styles, "keyboard focus indicator missing")
    require("button.is-stale::after" in styles and "dashed" in styles, "stale non-color cue missing")
    require("49/49 passed" in behavior, "calendar matrix assertion count drift")


def verify_prototype_contract() -> None:
    script = (REPO_ROOT / "doc" / "prototypes" / "v1.0" / "app.js").read_text(encoding="utf-8")
    styles = (REPO_ROOT / "doc" / "prototypes" / "v1.0" / "styles.css").read_text(encoding="utf-8")
    require('node.hidden = mode === "official"' in script, "prototype official quiet state missing")
    require('state.todayVariant === "label" ? "今天" : "今"' in script, "prototype comparison history missing")
    require("calendar-today-cue" in styles, "prototype today cue styling missing")
    require('[data-today-variant="corner"]' in styles, "prototype approved scheme A styling missing")


def verify_document_routing() -> None:
    progress = (RELEASE_ROOT / "progress_v1.0.5.md").read_text(encoding="utf-8")
    verification = (RELEASE_ROOT / "verification.md").read_text(encoding="utf-8")
    current = (REPO_ROOT / "doc" / "current.md").read_text(encoding="utf-8")
    require("V105-M4 已完成" in progress and "44/74" in progress, "M4 progress state drift")
    require("V105-M4-008" in progress and "- [x]" in progress, "M4 checklist did not close")
    require("V105-M4" in verification and "49/49" in verification, "M4 verification evidence missing")
    require("V105-M4 已完成" in current, "current status did not route to M5")


def main() -> int:
    checks = [
        verify_required_files,
        lambda: validate_m3_evidence(load_json(M3_EVIDENCE_PATH)),
        lambda: validate_evidence(load_json(EVIDENCE_PATH)),
        verify_coverage_contract,
        verify_calendar_layers,
        verify_prototype_contract,
        verify_document_routing,
    ]
    try:
        for check in checks:
            check()
            print(f"PASS {getattr(check, '__name__', 'validate_evidence')}")
    except (AssertionError, KeyError, TypeError, OSError, UnicodeDecodeError, json.JSONDecodeError) as error:
        print(f"FAIL {error}", file=sys.stderr)
        return 1
    print(f"PASS v1.0.5 M4 contracts ({len(checks)} checks)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
