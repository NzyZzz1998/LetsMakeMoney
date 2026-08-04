from __future__ import annotations

import copy
import sys

from verify_v105_m4 import BASELINE_HEAD, EXPECTED_BUSINESS_STATES, EXPECTED_RISK_STATES, validate_evidence


def sample() -> dict:
    return {
        "schema_version": 1,
        "milestone": "V105-M4",
        "candidate": {
            "kind": "dirty-controlled-m4-candidate",
            "source_head": BASELINE_HEAD,
            "source_tree_dirty": True,
            "candidate_id": "V105-M4-20260801-120000",
            "staged_exe_sha256": "A" * 64,
            "native_dll_sha256": "B" * 64,
            "identity_path": ".artifacts/candidates/v1.0.5/V105-M4-20260801-120000/candidate-identity.json",
        },
        "automation": {
            "architecture": "pass",
            "typescript": "pass",
            "web_build": "pass",
            "cargo_test": "pass",
            "clippy": "pass",
            "calendar_matrix_assertions": 49,
            "themes": ["light", "dark"],
            "dpi_contracts": [100, 125, 150],
        },
        "coverage": {
            "official_primary_surface": "hidden",
            "risk_states_visible": sorted(EXPECTED_RISK_STATES),
            "retry_contract": "pass",
        },
        "calendar_cells": {
            "today_scheme": "A-corner-badge",
            "today_cue": "今",
            "business_states": sorted(EXPECTED_BUSINESS_STATES),
            "business_layer": "pass",
            "selected_layer": "pass",
            "today_layer": "pass",
            "interaction_layer": "pass",
            "non_color_cues": "pass",
            "aria_contract": "pass",
            "keyboard_contract": "pass",
        },
        "desktop": {
            "official_quiet": "pass",
            "estimated_visible": "pass",
            "today_selected_business_composite": "pass",
            "light_theme": "pass",
            "dark_theme": "pass",
            "long_content": "pass",
            "dpi_100": "pass",
            "dpi_125": "automated-contract",
            "dpi_150": "automated-contract",
        },
        "baseline_integrity": {
            "configuration_restored": True,
            "debug_log_restored": True,
            "registry_changed": False,
            "remaining_processes": 0,
            "income_formula_changed": False,
            "calendar_data_changed": False,
            "configuration_schema_changed": False,
        },
        "raw_evidence": {
            "storage": "local-ignored",
            "index": ".artifacts/acceptance/v1.0.5/V105-M4-test/index.json",
            "repository_contains_raw_screenshots_or_logs": False,
        },
        "conclusion": {
            "milestone": "passed",
            "completed_tasks": 8,
            "release_created": False,
            "next_milestone": "V105-M5",
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
        print("PASS accepts valid M4 fixture")
        cases = [
            ("official source block visible", lambda value: value["coverage"].update(official_primary_surface="visible")),
            ("missing risk state", lambda value: value["coverage"]["risk_states_visible"].pop()),
            ("unapproved today scheme", lambda value: value["calendar_cells"].update(today_scheme="B-ring")),
            ("missing business state", lambda value: value["calendar_cells"]["business_states"].pop()),
            ("color-only cues", lambda value: value["calendar_cells"].update(non_color_cues="fail")),
            ("missing keyboard contract", lambda value: value["calendar_cells"].update(keyboard_contract="fail")),
            ("theme missing", lambda value: value["automation"].update(themes=["light"])),
            ("DPI missing", lambda value: value["automation"].update(dpi_contracts=[100, 125])),
            ("desktop composite failed", lambda value: value["desktop"].update(today_selected_business_composite="fail")),
            ("calendar data changed", lambda value: value["baseline_integrity"].update(calendar_data_changed=True)),
            ("absolute evidence path", lambda value: value["raw_evidence"].update(index="E:/codex/private/index.json")),
            ("release created", lambda value: value["conclusion"].update(release_created=True)),
        ]
        for name, mutate in cases:
            expect_rejected(name, mutate)
    except (AssertionError, KeyError, TypeError) as error:
        print(f"FAIL {error}", file=sys.stderr)
        return 1
    print(f"PASS v1.0.5 M4 negative contracts ({len(cases) + 1}/13)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
