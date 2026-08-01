from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Any

from verify_v105_m4 import validate_evidence as validate_m4_evidence


APP_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = APP_ROOT.parents[1]
RELEASE_ROOT = REPO_ROOT / "doc" / "releases" / "v1.0.5"
EVIDENCE_ROOT = RELEASE_ROOT / "evidence"
EVIDENCE_PATH = EVIDENCE_ROOT / "m5-window-surface-summary.json"
M4_EVIDENCE_PATH = EVIDENCE_ROOT / "m4-calendar-presentation-summary.json"
BASELINE_HEAD = "8a63da7836fb24c3b7f8ff12f896ac40571adeb7"
OFFICIAL_SOURCE_HEAD = "4d06dc73dbc5c27d7a97462d8262a553dd97d5b6"
OFFICIAL_ZIP_SHA256 = "C4F28892831891A4266C4D9B12D432CD5C970BB3C9B36A6B8DB21FA2566DE50E"
OFFICIAL_EXE_SHA256 = "E0C9C603703FC2632619AFBC84F63B1B1D403273CD01D29AA0A308A95243E107"
M5_EXE_SHA256 = "DF18CC5A3A99975CE1A8CEE965D0A83F2DB0FB5B4628F079FDA96D4262546A3B"
NATIVE_DLL_SHA256 = "8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C"
EXPECTED_WINDOWS = {
    "workbench": {"width": 922, "height": 642},
    "settings": {"width": 762, "height": 562},
    "wizard": {"width": 782, "height": 582},
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
    require(value.get("schema_version") == 1, "M5 schema version drift")
    require(value.get("milestone") == "V105-M5", "M5 milestone drift")

    baseline = value["baseline"]
    require(baseline["release"] == "v1.0.4", "M5 baseline release drift")
    require(baseline["source_head"] == OFFICIAL_SOURCE_HEAD, "official source HEAD drift")
    require(baseline["zip_sha256"] == OFFICIAL_ZIP_SHA256, "official Zip hash drift")
    require(baseline["exe_sha256"] == OFFICIAL_EXE_SHA256, "official EXE hash drift")
    require(baseline["windows"] == EXPECTED_WINDOWS, "v1.0.4 window dimensions drift")
    baseline_owner = baseline["surface_ownership"]
    require(set(baseline_owner["web_surface"]) == {"background", "border", "radius", "shadow"}, "baseline Web ownership drift")
    require(set(baseline_owner["native_surface"]) == {"transparent-window", "shadow"}, "baseline native ownership drift")

    candidate = value["candidate"]
    require(candidate["kind"] == "dirty-controlled-m5-candidate", "M5 candidate kind drift")
    require(candidate["source_head"] == BASELINE_HEAD, "M5 source baseline drift")
    require(candidate["source_tree_dirty"] is True, "M5 must disclose dirty source tree")
    require(candidate["staged_exe_sha256"] == M5_EXE_SHA256, "M5 EXE hash drift")
    require(candidate["native_dll_sha256"] == NATIVE_DLL_SHA256, "M5 native DLL hash drift")
    require(candidate["identity_path"].startswith(".artifacts/candidates/v1.0.5/"), "M5 identity path drift")
    require(candidate["publication_allowed"] is False, "M5 candidate must not be publishable")
    require(candidate["retained"] is True, "approved M5 candidate was not retained")

    surface = value["surface_contract"]
    require(surface["transparent_root"] == "pass", "transparent root contract failed")
    require(set(surface["web_owner"]) == {"background", "border", "radius"}, "candidate Web ownership drift")
    require("shadow" not in surface["web_owner"], "candidate retains dual shadow ownership")
    require(set(surface["native_owner"]) == {"transparent-window", "shadow"}, "candidate native ownership drift")
    require(surface["css_shadow_removed_from_window_frame"] is True, "WindowFrame CSS shadow remains")
    require(surface["mini_surface_unchanged"] is True, "Mini surface was changed by M5")
    require(surface["dimensions_unchanged"] is True, "M5 changed window dimensions")

    automation = value["automation"]
    require(automation["window_surface_assertions"] == 16, "window surface assertion count drift")
    for field in ("architecture", "typescript", "web_build", "cargo_test", "fmt", "clippy", "release_build"):
        require(automation[field] == "pass", f"M5 automation failed: {field}")
    require(automation["rust_tests"] == 54, "Rust regression count drift")

    desktop = value["desktop"]
    os_state = desktop["os"]
    require(os_state["windows_11"] == "pass", "Windows 11 desktop evidence missing")
    require(os_state["windows_10"] in {"pass", "pending-environment"}, "invalid Windows 10 evidence state")
    require(bool(os_state["windows_11_build"]), "Windows 11 build missing")
    for name, dimensions in EXPECTED_WINDOWS.items():
        window = desktop[name]
        require(window["width"] == dimensions["width"] and window["height"] == dimensions["height"], f"{name} desktop dimensions drift")
        require(window["light"] == "pass", f"{name} light theme evidence missing")
        require(window["dark"] in {"pass", "automated-contract"}, f"{name} dark theme evidence missing")
        require(window["drag"] == "pass", f"{name} drag evidence missing")
    require(desktop["workbench"]["close"] == "pass" and desktop["workbench"]["focus_restore"] == "pass", "Workbench shell regression")
    require(desktop["settings"]["close_modal"] == "pass" and desktop["settings"]["save"] == "pass", "Settings shell regression")
    require(desktop["wizard"]["close_modal"] == "pass", "Wizard close modal regression")
    require(all(desktop["mini"][field] == "pass" for field in ("surface_unchanged", "privacy_tab", "reveal")), "Mini regression")
    for field in ("dpi_100", "dpi_125", "dpi_150"):
        require(desktop[field] == "pass", f"real Windows DPI evidence missing: {field}")

    integrity = value["baseline_integrity"]
    require(integrity["system_scale_restored"] is True, "system scale was not restored")
    require(integrity["applied_dpi"] == 96, "system DPI did not return to 100%")
    require(integrity["per_monitor_dpi_values"] == [0, 0], "per-monitor DPI values were not restored")
    for field in ("configuration_restored", "previous_configuration_restored", "debug_log_restored"):
        require(integrity[field] is True, f"user environment was not restored: {field}")
    for field in ("configuration_sha256", "previous_configuration_sha256", "debug_log_sha256"):
        require(bool(re.fullmatch(r"[A-F0-9]{64}", integrity[field])), f"invalid restored hash: {field}")
    require(integrity["remaining_processes"] == 0, "M5 left a process running")
    for field in ("income_formula_changed", "calendar_data_changed", "configuration_schema_changed"):
        require(integrity[field] is False, f"M5 crossed business boundary: {field}")

    raw = value["raw_evidence"]
    require(raw["storage"] == "local-ignored", "M5 raw evidence storage drift")
    require(raw["index"].startswith(".artifacts/acceptance/v1.0.5/"), "M5 raw evidence index drift")
    require(raw["repository_contains_raw_screenshots_or_logs"] is False, "raw evidence must remain untracked")

    conclusion = value["conclusion"]
    require(conclusion["milestone"] == "passed_with_pending_environment", "M5 conclusion drift")
    require(conclusion["completed_tasks"] == 8, "M5 task count drift")
    require(conclusion["candidate_decision"] == "retain", "M5 candidate decision drift")
    require(conclusion["windows_10"] == os_state["windows_10"], "Windows 10 conclusion mismatch")
    require(conclusion["release_created"] is False, "M5 must not create a Release")
    require(conclusion["next_milestone"] == "V105-M6", "M5 next milestone drift")
    require(not contains_sensitive_value(value), "M5 evidence contains an absolute path or secret-like value")


def verify_source_contract() -> None:
    frame = (APP_ROOT / "src" / "components" / "WindowFrame.tsx").read_text(encoding="utf-8")
    styles = (APP_ROOT / "src" / "styles.css").read_text(encoding="utf-8")
    app = (APP_ROOT / "src" / "App.tsx").read_text(encoding="utf-8")
    native = (APP_ROOT / "src-tauri" / "src" / "lib.rs").read_text(encoding="utf-8")
    behavior = (APP_ROOT / "tests" / "window-surface-v105.behavior.ts").read_text(encoding="utf-8")

    require('data-surface-owner="window-frame"' in frame, "WindowFrame surface owner marker missing")
    require('data-shadow-owner="native-window"' in frame, "WindowFrame shadow owner marker missing")
    require(re.search(r"\.window-frame\s*\{\s*box-shadow:\s*none;\s*\}", styles) is not None, "WindowFrame CSS shadow not removed")
    require(re.search(r"\.mini-window\s*\{\s*box-shadow:\s*var\(--shadow-window\);\s*\}", styles) is not None, "Mini shadow contract changed")
    require(app.count("<WindowFrame ") == 3, "WindowFrame consumer count drift")
    require("MiniWindow" in app and '<WindowFrame kind="mini"' not in app, "Mini was incorrectly moved into WindowFrame")
    require(".transparent(true)" in native and ".shadow(true)" in native, "native transparent/shadow contract drift")
    require("window surface contract ${assertions}/16 passed" in behavior, "window surface behavior assertion count drift")


def validate_document_routing(progress: str, verification: str, current: str, traceability: str, spike: str) -> None:
    require(
        re.search(r"\|\s*V105-M5\s*\|[^\n]*已完成[^\n]*\|\s*8/8\s*\|", progress) is not None,
        "M5 progress state drift",
    )
    require(
        all(f"- [x] `V105-M5-{index:03d}`" in progress for index in range(1, 9)),
        "M5 checklist did not close",
    )
    require("M5 结论" in verification and "Windows 10" in verification, "M5 verification evidence missing")
    m5_completion_recorded = (
        re.search(r"V105-M0\s*至\s*M5\s*已完成\s*52/52", current) is not None
        or re.search(r"V105-M0\s*至\s*M6\s*已完成", current) is not None
    )
    routed_to_m6 = "V105-M6" in current
    routed_to_post_acc_candidate = all(
        token in current
        for token in ("V105-BUG-001", "新 clean 候选", "不可发布")
    )
    routed_to_release_closure = all(
        token in current
        for token in ("修复后独立 ACC 已通过", "当前无发布阻塞", "可进入发布收口")
    )
    require(
        m5_completion_recorded
        and (routed_to_m6 or routed_to_post_acc_candidate or routed_to_release_closure),
        "current status did not route to M6, a blocked post-ACC rebuild, or release closure",
    )
    require("M5 已通过" in traceability, "FR-008 traceability did not close M5")
    require("保留单一表面候选" in spike and "Windows 10" in spike, "M5 Spike decision missing")


def verify_document_routing() -> None:
    progress = (RELEASE_ROOT / "progress_v1.0.5.md").read_text(encoding="utf-8")
    verification = (RELEASE_ROOT / "verification.md").read_text(encoding="utf-8")
    current = (REPO_ROOT / "doc" / "current.md").read_text(encoding="utf-8")
    traceability = (RELEASE_ROOT / "traceability.md").read_text(encoding="utf-8")
    spike = (RELEASE_ROOT / "window-surface-spike.md").read_text(encoding="utf-8")
    validate_document_routing(progress, verification, current, traceability, spike)


def main() -> int:
    checks = [
        lambda: validate_m4_evidence(load_json(M4_EVIDENCE_PATH)),
        lambda: validate_evidence(load_json(EVIDENCE_PATH)),
        verify_source_contract,
        verify_document_routing,
    ]
    try:
        for check in checks:
            check()
            print(f"PASS {getattr(check, '__name__', 'validate_evidence')}")
    except (AssertionError, KeyError, TypeError, OSError, UnicodeDecodeError, json.JSONDecodeError) as error:
        print(f"FAIL {error}", file=sys.stderr)
        return 1
    print(f"PASS v1.0.5 M5 contracts ({len(checks)} checks)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
