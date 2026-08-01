from __future__ import annotations

import copy
import sys

from verify_v105_m3 import BASELINE_HEAD, EXPECTED_PRIVACY_STATES, validate_evidence


def sample() -> dict:
    return {
        "schema_version": 1,
        "milestone": "V105-M3",
        "candidate": {
            "kind": "dirty-controlled-m3-candidate",
            "source_head": BASELINE_HEAD,
            "source_tree_dirty": True,
            "candidate_id": "V105-M3-test",
            "staged_exe_sha256": "A" * 64,
            "native_dll_sha256": "B" * 64,
            "identity_path": ".artifacts/candidates/v1.0.5/V105-M3-test/candidate-identity.json",
        },
        "automation": {
            "architecture": "pass",
            "typescript": "pass",
            "web_build": "pass",
            "cargo_test": "pass",
            "clippy": "pass",
            "privacy_scan": "pass",
            "mini_state_machine_assertions": 37,
            "privacy_selector_cases": 10,
            "cargo_tests_passed": 54,
        },
        "privacy": {
            "tab_logical_px": 28,
            "covered_states": sorted(EXPECTED_PRIVACY_STATES),
            "forbidden_tokens_found": [],
            "dom_scan": "pass",
            "aria_scan": "pass",
            "log_scan": "pass",
            "light_theme": "pass",
            "dark_theme": "pass",
        },
        "desktop": {
            "left_edge_first_retract": "pass",
            "right_edge_first_retract": "pass",
            "hover_reveal": "pass",
            "pointer_leave_retract": "pass",
            "click_reveal": "pass",
            "keyboard_reveal": "pass",
            "ordinary_focus_does_not_reveal": "pass",
            "explicit_restore_reveals": "pass",
            "workbench_close_regression": "pass",
            "fallback_keeps_window_recoverable": "pass",
        },
        "fr003": {
            "status": "fixed-and-verified",
            "first_retract_requires_extra_interaction": False,
            "late_native_result_protected": True,
        },
        "fr004": {
            "status": "fixed-and-verified",
            "ordinary_focus_reveals": False,
            "explicit_shown_reveals": True,
            "tray_restore_reveals": True,
        },
        "baseline_integrity": {
            "configuration_restored": True,
            "debug_log_restored": True,
            "registry_changed": False,
            "remaining_processes": 0,
            "income_formula_changed": False,
            "calendar_contract_changed": False,
            "configuration_schema_changed": False,
        },
        "raw_evidence": {
            "storage": "local-ignored",
            "index": ".artifacts/acceptance/v1.0.5/V105-M3-test/index.json",
            "repository_contains_raw_screenshots_or_logs": False,
        },
        "conclusion": {
            "milestone": "passed",
            "completed_tasks": 10,
            "release_created": False,
            "next_milestone": "V105-M4",
        },
    }


def expect_rejected(name: str, mutate) -> None:
    value = copy.deepcopy(sample())
    mutate(value)
    try:
        validate_evidence(value)
    except (AssertionError, KeyError, TypeError):
        print(f"PASS rejects {name}")
        return
    raise AssertionError(f"validator accepted invalid fixture: {name}")


def main() -> int:
    try:
        validate_evidence(sample())
        print("PASS accepts valid M3 fixture")
        cases = [
            ("wrong privacy width", lambda value: value["privacy"].update(tab_logical_px=27)),
            ("income leak", lambda value: value["privacy"]["forbidden_tokens_found"].append("今日已赚")),
            ("missing privacy state", lambda value: value["privacy"]["covered_states"].pop()),
            ("ordinary focus reveal", lambda value: value["fr004"].update(ordinary_focus_reveals=True)),
            ("tray restore failure", lambda value: value["fr004"].update(tray_restore_reveals=False)),
            ("late result unprotected", lambda value: value["fr003"].update(late_native_result_protected=False)),
            ("desktop failure", lambda value: value["desktop"].update(right_edge_first_retract="fail")),
            ("unrestored config", lambda value: value["baseline_integrity"].update(configuration_restored=False)),
            ("absolute path", lambda value: value["raw_evidence"].update(index="E:/codex/private/evidence.json")),
            ("release created", lambda value: value["conclusion"].update(release_created=True)),
        ]
        for name, mutate in cases:
            expect_rejected(name, mutate)
    except (AssertionError, KeyError, TypeError) as error:
        print(f"FAIL {error}", file=sys.stderr)
        return 1
    print(f"PASS v1.0.5 M3 negative contracts ({len(cases) + 1}/11)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
