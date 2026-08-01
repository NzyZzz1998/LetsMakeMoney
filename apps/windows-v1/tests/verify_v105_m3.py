from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Any

from verify_v105_m0 import validate_evidence as validate_m0_evidence
from verify_v105_m1 import validate_contract as validate_m1_contract
from verify_v105_m2 import validate_evidence as validate_m2_evidence


APP_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = APP_ROOT.parents[1]
RELEASE_ROOT = REPO_ROOT / "doc" / "releases" / "v1.0.5"
EVIDENCE_ROOT = RELEASE_ROOT / "evidence"
EVIDENCE_PATH = EVIDENCE_ROOT / "m3-mini-privacy-summary.json"
GEOMETRY_FIXTURE_PATH = APP_ROOT / "tests" / "fixtures" / "v105-mini-edge-geometry.json"
BASELINE_HEAD = "8a63da7836fb24c3b7f8ff12f896ac40571adeb7"

FORBIDDEN_PRIVACY_COPY = {
    "月薪",
    "今日已赚",
    "日薪",
    "时薪",
    "预计收入",
    "收入进度",
    "带薪",
    "不带薪",
    "¥",
    "￥",
    "$",
}
EXPECTED_PRIVACY_STATES = {
    "loading",
    "error",
    "before_work",
    "working_before_rest",
    "rest",
    "working_after_rest",
    "after_work",
    "rest_day",
    "paid_rest",
    "unpaid_rest",
}


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        value = json.load(handle)
    require(isinstance(value, dict), f"{path.name} must contain a JSON object")
    return value


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
    require(value.get("schema_version") == 1, "M3 schema version drift")
    require(value.get("milestone") == "V105-M3", "M3 milestone drift")

    candidate = value["candidate"]
    require(candidate["kind"] == "dirty-controlled-m3-candidate", "M3 candidate kind drift")
    require(candidate["source_head"] == BASELINE_HEAD, "M3 source baseline drift")
    require(candidate["source_tree_dirty"] is True, "M3 candidate must disclose its dirty source tree")
    for field in ("candidate_id", "staged_exe_sha256", "native_dll_sha256"):
        require(bool(re.fullmatch(r"[A-Za-z0-9._-]+", candidate[field])), f"invalid candidate field: {field}")
    require(len(candidate["staged_exe_sha256"]) == 64, "M3 EXE hash length drift")
    require(len(candidate["native_dll_sha256"]) == 64, "M3 DLL hash length drift")
    require(candidate["identity_path"].startswith(".artifacts/candidates/v1.0.5/"), "M3 identity path drift")

    automation = value["automation"]
    for field in ("architecture", "typescript", "web_build", "cargo_test", "clippy", "privacy_scan"):
        require(automation[field] == "pass", f"M3 automation did not pass: {field}")
    require(automation["mini_state_machine_assertions"] >= 37, "M3 state-machine coverage drift")
    require(automation["privacy_selector_cases"] == 10, "M3 privacy selector coverage drift")
    require(automation["cargo_tests_passed"] >= 54, "M3 Rust test count drift")

    privacy = value["privacy"]
    require(privacy["tab_logical_px"] == 28, "privacy tab width drift")
    require(set(privacy["covered_states"]) == EXPECTED_PRIVACY_STATES, "privacy state coverage drift")
    require(privacy["forbidden_tokens_found"] == [], "privacy surface leaked forbidden copy")
    require(privacy["dom_scan"] == "pass", "privacy DOM scan did not pass")
    require(privacy["aria_scan"] == "pass", "privacy ARIA scan did not pass")
    require(privacy["log_scan"] == "pass", "privacy log scan did not pass")
    require(privacy["light_theme"] == "pass" and privacy["dark_theme"] == "pass", "theme coverage drift")

    desktop = value["desktop"]
    required_desktop = {
        "left_edge_first_retract",
        "right_edge_first_retract",
        "hover_reveal",
        "pointer_leave_retract",
        "click_reveal",
        "keyboard_reveal",
        "ordinary_focus_does_not_reveal",
        "explicit_restore_reveals",
        "workbench_close_regression",
        "fallback_keeps_window_recoverable",
    }
    for field in required_desktop:
        require(desktop[field] == "pass", f"M3 desktop verification did not pass: {field}")

    fr003 = value["fr003"]
    require(fr003["status"] == "fixed-and-verified", "FR-003 status drift")
    require(fr003["first_retract_requires_extra_interaction"] is False, "FR-003 regression")
    require(fr003["late_native_result_protected"] is True, "FR-003 generation protection missing")

    fr004 = value["fr004"]
    require(fr004["status"] == "fixed-and-verified", "FR-004 status drift")
    require(fr004["ordinary_focus_reveals"] is False, "ordinary focus still reveals Mini")
    require(fr004["explicit_shown_reveals"] is True, "explicit shown no longer reveals Mini")
    require(fr004["tray_restore_reveals"] is True, "tray restore regression")

    integrity = value["baseline_integrity"]
    require(integrity["configuration_restored"] is True, "M3 configuration was not restored")
    require(integrity["debug_log_restored"] is True, "M3 debug log was not restored")
    require(integrity["registry_changed"] is False, "M3 changed registry state")
    require(integrity["remaining_processes"] == 0, "M3 left a process running")
    require(integrity["income_formula_changed"] is False, "M3 changed income formula")
    require(integrity["calendar_contract_changed"] is False, "M3 changed calendar contract")
    require(integrity["configuration_schema_changed"] is False, "M3 changed configuration schema")

    raw = value["raw_evidence"]
    require(raw["storage"] == "local-ignored", "M3 raw evidence storage drift")
    require(raw["index"].startswith(".artifacts/acceptance/v1.0.5/"), "M3 raw evidence index drift")
    require(raw["repository_contains_raw_screenshots_or_logs"] is False, "raw evidence must remain untracked")

    conclusion = value["conclusion"]
    require(conclusion["milestone"] == "passed", "M3 conclusion drift")
    require(conclusion["completed_tasks"] == 10, "M3 task count drift")
    require(conclusion["release_created"] is False, "M3 must not create a Release")
    require(conclusion["next_milestone"] == "V105-M4", "M3 next milestone drift")
    require(not contains_sensitive_value(value), "M3 evidence contains an absolute path or secret-like value")


def verify_historical_evidence() -> None:
    validate_m0_evidence(load_json(EVIDENCE_ROOT / "m0-baseline.json"))
    validate_m1_contract(load_json(EVIDENCE_ROOT / "m1-contract.json"))
    validate_m2_evidence(load_json(EVIDENCE_ROOT / "m2-characterization-summary.json"))


def verify_required_files() -> None:
    required = [
        EVIDENCE_PATH,
        GEOMETRY_FIXTURE_PATH,
        APP_ROOT / "src" / "features" / "mini" / "miniEdgeAutoHide.ts",
        APP_ROOT / "src" / "features" / "mini" / "privacyTabPresentation.ts",
        APP_ROOT / "src" / "features" / "mini" / "useMiniEdgeAutoHide.ts",
        APP_ROOT / "src" / "features" / "mini" / "MiniWindow.tsx",
        APP_ROOT / "tests" / "mini-edge-auto-hide.behavior.ts",
        APP_ROOT / "tests" / "privacy-tab-presentation.behavior.ts",
        APP_ROOT / "tests" / "verify_v105_m3.py",
        APP_ROOT / "tests" / "verify_v105_m3_tests.py",
    ]
    missing = [path.relative_to(REPO_ROOT).as_posix() for path in required if not path.is_file()]
    require(not missing, f"missing M3 files: {missing}")


def verify_geometry_contract() -> None:
    fixture = load_json(GEOMETRY_FIXTURE_PATH)
    require(fixture["fixture_version"] == 1, "M3 geometry fixture version drift")
    require(fixture["contract"]["privacy_tab_logical_px"] == 28, "M3 fixture width drift")
    cases = fixture["dock_cases"]
    require(len(cases) >= 3, "M3 geometry fixture coverage drift")
    require({case["expected_side"] for case in cases} == {"left", "right"}, "M3 geometry must cover both sides")
    require({case["scale_factor"] for case in cases} >= {1.0, 1.25, 1.5}, "M3 geometry DPI coverage drift")
    platform = (APP_ROOT / "src-tauri" / "src" / "platform.rs").read_text(encoding="utf-8")
    require("MINI_EDGE_PRIVACY_TAB_LOGICAL_PX: i32 = 28" in platform, "native privacy width drift")
    require(
        "pub fn edge_dock_positions" in platform
        and "expanded:" in platform
        and "retracted:" in platform,
        "native geometry separation missing",
    )


def verify_frontend_contract() -> None:
    controller = (APP_ROOT / "src" / "features" / "mini" / "miniEdgeAutoHide.ts").read_text(encoding="utf-8")
    hook = (APP_ROOT / "src" / "features" / "mini" / "useMiniEdgeAutoHide.ts").read_text(encoding="utf-8")
    mini = (APP_ROOT / "src" / "features" / "mini" / "MiniWindow.tsx").read_text(encoding="utf-8")
    privacy = (APP_ROOT / "src" / "features" / "mini" / "privacyTabPresentation.ts").read_text(encoding="utf-8")
    styles = (APP_ROOT / "src" / "styles.css").read_text(encoding="utf-8")

    for marker in ("generation", "pointerEntryArmed", 'scheduleRetract("drag_complete")', "transitionGeneration"):
        require(marker in controller, f"Mini controller missing {marker}")
    require('setLock("focus_inside", true)' in hook, "ordinary focus lock mapping missing")
    require('reveal("window_shown")' in hook, "explicit shown reveal mapping missing")
    require("data-privacy-surface" in mini and "data-privacy-copy" in mini, "privacy DOM markers missing")
    require("privacy.ariaLabel" in mini and "privacy.visibleText" in mini, "privacy copy/ARIA binding missing")
    require('data-mini-primary-action="true"' in mini, "post-reveal focus target missing")
    retracted = mini.split('if (edge.snapshot.phase === "retracted")', 1)[1].split('if (snapshot.state === "loading")', 1)[0]
    for marker in ("formatMoney", "todayIncome", "dailySalary", "hourlySalary", "progress"):
        require(marker not in retracted, f"privacy DOM includes sensitive binding: {marker}")
    privacy_copy_source = re.sub(r"\$\{[^}]+\}", "", privacy)
    for token in FORBIDDEN_PRIVACY_COPY:
        haystack = privacy_copy_source if token == "$" else privacy
        require(token not in haystack, f"privacy selector contains forbidden token: {token}")
    require("width: 28px" in styles, "privacy CSS width drift")
    require("writing-mode: vertical-rl" in styles, "privacy vertical copy missing")
    require("mini-window--dock-left" in styles and "mini-window--dock-right" in styles, "privacy side styles missing")
    require("prefers-reduced-motion: reduce" in styles, "reduced-motion contract missing")


def verify_native_event_contract() -> None:
    native = (APP_ROOT / "src-tauri" / "src" / "lib.rs").read_text(encoding="utf-8")
    for source in ("drag_complete", "lock_released", "privacy_activate", "window_shown"):
        require(source in native, f"native semantic source missing: {source}")
    shown_dispatch = "window.dispatchEvent(new CustomEvent('lmm:window-shown'))"
    require(native.count(shown_dispatch) >= 2, "explicit window-shown dispatch coverage missing")
    require('set_mini_edge_retracted_internal(app, false, "tray_restore", true)' in native, "tray explicit restore source missing")


def verify_document_routing() -> None:
    progress = (RELEASE_ROOT / "progress_v1.0.5.md").read_text(encoding="utf-8")
    verification = (RELEASE_ROOT / "verification.md").read_text(encoding="utf-8")
    issue_pool = (RELEASE_ROOT / "issue-pool.md").read_text(encoding="utf-8")
    bugfix = (REPO_ROOT / "doc" / "logs" / "v1.0.5-bugfix-log.md").read_text(encoding="utf-8")
    require("V105-M3 已完成" in progress and "36/74" in progress, "M3 progress state drift")
    require("M3" in verification and "28" in verification, "M3 verification evidence missing")
    require("FR-003" in issue_pool and "已修复" in issue_pool, "FR-003 issue status missing")
    require("FR-004" in bugfix and "已修复" in bugfix, "FR-004 bugfix status missing")


def main() -> int:
    checks = [
        verify_required_files,
        verify_historical_evidence,
        lambda: validate_evidence(load_json(EVIDENCE_PATH)),
        verify_geometry_contract,
        verify_frontend_contract,
        verify_native_event_contract,
        verify_document_routing,
    ]
    try:
        for check in checks:
            check()
            print(f"PASS {getattr(check, '__name__', 'validate_evidence')}")
    except (AssertionError, KeyError, TypeError, OSError, UnicodeDecodeError, json.JSONDecodeError) as error:
        print(f"FAIL {error}", file=sys.stderr)
        return 1
    print(f"PASS v1.0.5 M3 contracts ({len(checks)} checks)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
