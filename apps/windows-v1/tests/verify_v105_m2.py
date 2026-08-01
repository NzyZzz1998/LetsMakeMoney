from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Any


APP_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = APP_ROOT.parents[1]
RELEASE_ROOT = REPO_ROOT / "doc" / "releases" / "v1.0.5"
EVIDENCE_PATH = RELEASE_ROOT / "evidence" / "m2-characterization-summary.json"
FIXTURE_PATH = APP_ROOT / "tests" / "fixtures" / "v105-mini-interaction-fixtures.json"
CHARACTERIZATION_PATH = APP_ROOT / "tests" / "mini-edge-auto-hide.m2-characterization.behavior.ts"
TARGET_PATH = APP_ROOT / "tests" / "mini-edge-auto-hide.m2-target.behavior.ts"

OFFICIAL_V104_SHA256 = "C4F28892831891A4266C4D9B12D432CD5C970BB3C9B36A6B8DB21FA2566DE50E"
EXPECTED_CONFIG_SHA256 = "62A5B2A846D990E98F0556CF5BE657D4E9D943E7426AC9BC6ACFC594858909CC"
TARGET_MARKER = "M2_RED_NO_POINTERLEAVE_RETRACT"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        value = json.load(handle)
    require(isinstance(value, dict), f"{path.name} must contain a JSON object")
    return value


def git(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", *args],
        cwd=REPO_ROOT,
        text=True,
        encoding="utf-8",
        capture_output=True,
        check=True,
    )


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
    require(value.get("schema_version") == 1, "M2 schema version drift")
    require(value.get("milestone") == "V105-M2", "M2 milestone drift")

    candidate = value["candidate"]
    require(candidate["kind"] == "published-v1.0.4-baseline", "M2 candidate kind drift")
    require(candidate["source_tree_dirty"] is False, "M2 GUI baseline must be published and clean")
    require(candidate["zip_sha256"] == OFFICIAL_V104_SHA256, "M2 candidate hash drift")

    fr003 = value["fr003_characterization"]
    require(fr003["fixture_count"] == 8, "FR-003 fixture count drift")
    require(set(fr003["edges"]) == {"left", "right"}, "FR-003 edge coverage drift")
    require(fr003["current_behavior_test"] == "pass", "current characterization must pass")
    require(fr003["target_behavior_test"] == "expected-red", "M3 target must remain red in M2")
    require(fr003["target_failure_marker"] == TARGET_MARKER, "M2 target marker drift")
    require(fr003["route"] == "V105-M3", "FR-003 route drift")
    require("pointerInside=true" in fr003["confirmed_root_cause"], "FR-003 root cause drift")

    fr004 = value["fr004_reproduction"]
    require(fr004["calibration_runs_excluded"] == 1, "calibration exclusion drift")
    require(fr004["valid_runs"] == 20, "FR-004 requires exactly 20 valid runs")
    require(fr004["reproduced_runs"] == 20, "FR-004 reproduction result drift")
    require(fr004["pre_close_state"] == "retracted", "FR-004 precondition drift")
    require(fr004["post_close_state"] == "expanded", "FR-004 observed state drift")
    require(fr004["observed_surface"] == "mini_expanded", "FR-004 surface identity drift")
    require(fr004["native_mini_shown_events"] == 0, "native Mini shown event would change root cause")
    require(fr004["correlated_ordinary_focus_runs"] == 20, "ordinary focus correlation drift")
    require(fr004["mini_reveal_events_with_window_shown_source"] == 20, "reveal source count drift")
    require(fr004["route"] == "V105-M3", "FR-004 must enter M3 after 20/20 reproduction")

    runs = value["runs"]
    require(len(runs) == 20, "M2 run table must contain 20 entries")
    require([entry["run"] for entry in runs] == list(range(1, 21)), "M2 run numbering drift")
    for entry in runs:
        require(entry["mini_before"] == "retracted", "every run must start retracted")
        require(entry["observed_surface"] == "mini_expanded", "every run must identify Mini")
        require(entry["mini_after"] == "expanded", "every run must end expanded")
        require(entry["result"] == "unexpected", "every reproduced run must be unexpected")

    integrity = value["baseline_integrity"]
    require(integrity["configuration_sha256_before"] == EXPECTED_CONFIG_SHA256, "config baseline hash drift")
    require(integrity["configuration_sha256_after"] == EXPECTED_CONFIG_SHA256, "restored config hash drift")
    require(integrity["configuration_restored"] is True, "configuration was not restored")
    require(integrity["debug_log_restored"] is True, "debug log was not restored")
    require(integrity["registry_changed"] is False, "M2 must not change registry state")
    require(integrity["remaining_processes"] == 0, "M2 left a process running")
    require(integrity["tray_restore_baseline_changed"] is False, "tray baseline changed")
    require(integrity["position_persistence_baseline_changed"] is False, "position baseline changed")
    require(integrity["configuration_transaction_baseline_changed"] is False, "configuration baseline changed")
    require(integrity["business_code_modified"] is False, "M2 business code boundary drift")

    raw = value["raw_evidence"]
    require(raw["storage"] == "local-ignored", "raw evidence storage drift")
    require(raw["index"].startswith(".artifacts/acceptance/v1.0.5/"), "raw evidence index drift")
    require(raw["repository_contains_raw_screenshots_or_logs"] is False, "raw evidence must not be tracked")

    conclusion = value["conclusion"]
    require(conclusion["milestone"] == "passed-characterization-only", "M2 conclusion drift")
    require(conclusion["fr003"] == "confirmed-not-fixed", "FR-003 must remain unfixed in M2")
    require(conclusion["fr004"] == "confirmed-not-fixed", "FR-004 must remain unfixed in M2")
    require(conclusion["candidate_or_release_created"] is False, "M2 must not create a candidate")
    require(not contains_sensitive_value(value), "M2 evidence contains an absolute path or secret-like value")


def verify_required_files() -> None:
    required = [
        EVIDENCE_PATH,
        FIXTURE_PATH,
        CHARACTERIZATION_PATH,
        TARGET_PATH,
        REPO_ROOT / "doc" / "logs" / "v1.0.5-bugfix-log.md",
        APP_ROOT / "tests" / "verify_v105_m2.py",
        APP_ROOT / "tests" / "verify_v105_m2_tests.py",
    ]
    missing = [path.relative_to(REPO_ROOT).as_posix() for path in required if not path.is_file()]
    require(not missing, f"missing M2 files: {missing}")


def verify_fixture_contract() -> None:
    value = load_json(FIXTURE_PATH)
    require(value.get("schema_version") == 1, "fixture schema drift")
    require(value.get("milestone") == "V105-M2", "fixture milestone drift")
    states = value.get("states")
    require(isinstance(states, list) and len(states) == 8, "fixture matrix must contain eight states")
    ids = {entry["id"] for entry in states}
    require(ids == {
        "docked-expanded-idle",
        "drag-release-at-edge-without-pointerleave",
        "drag-back-to-floating",
        "menu-open",
        "modal-open",
        "focus-inside",
        "ordinary-window-focus",
        "explicit-native-shown",
    }, "fixture state inventory drift")


def verify_behavior_sources() -> None:
    characterization = CHARACTERIZATION_PATH.read_text(encoding="utf-8")
    target = TARGET_PATH.read_text(encoding="utf-8")
    for marker in ('["left", "right"]', "pointerInside", "menu_open", "modal_open", "focus_inside", "dragging inward clears the dock"):
        require(marker in characterization, f"characterization missing {marker}")
    require(TARGET_MARKER in target, "target behavior missing red marker")
    require("scheduler.pendingCount() === 1" in target, "target behavior no longer expresses first retract")


def verify_document_routing() -> None:
    progress = (RELEASE_ROOT / "progress_v1.0.5.md").read_text(encoding="utf-8")
    verification = (RELEASE_ROOT / "verification.md").read_text(encoding="utf-8")
    issue_pool = (RELEASE_ROOT / "issue-pool.md").read_text(encoding="utf-8")
    bugfix = (REPO_ROOT / "doc" / "logs" / "v1.0.5-bugfix-log.md").read_text(encoding="utf-8")
    require("V105-M2 已完成" in progress, "progress M2 state missing")
    require("20/20" in progress and "26/74" in progress, "progress counts drift")
    require("FR-004" in verification and "进入 V105-M3" in verification, "verification route missing")
    require("已确认，待 M3 修复" in issue_pool, "issue routing not updated")
    require("20/20" in bugfix and "未修复" in bugfix, "bugfix evidence/status missing")


def verify_business_code_unchanged() -> None:
    status = git(
        "status",
        "--porcelain",
        "--untracked-files=all",
        "--",
        "apps/windows-v1/src",
        "apps/windows-v1/src-tauri/src",
    ).stdout.strip()
    require(not status, f"M2 business code changed unexpectedly: {status}")


def main() -> int:
    checks = [
        verify_required_files,
        lambda: validate_evidence(load_json(EVIDENCE_PATH)),
        verify_fixture_contract,
        verify_behavior_sources,
        verify_document_routing,
        verify_business_code_unchanged,
    ]
    try:
        for check in checks:
            check()
            print(f"PASS {getattr(check, '__name__', 'validate_evidence')}")
    except (AssertionError, KeyError, TypeError, OSError, UnicodeDecodeError, json.JSONDecodeError, subprocess.CalledProcessError) as error:
        print(f"FAIL {error}", file=sys.stderr)
        return 1
    print(f"PASS v1.0.5 M2 evidence contracts ({len(checks)} checks)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
