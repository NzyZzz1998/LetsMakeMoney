from __future__ import annotations

import copy
import sys

from verify_v105_m5 import (
    BASELINE_HEAD,
    M5_EXE_SHA256,
    NATIVE_DLL_SHA256,
    OFFICIAL_EXE_SHA256,
    OFFICIAL_SOURCE_HEAD,
    OFFICIAL_ZIP_SHA256,
    EXPECTED_WINDOWS,
    validate_document_routing,
    validate_evidence,
)


def sample() -> dict:
    windows = {
        "workbench": {"width": 922, "height": 642, "light": "pass", "dark": "pass", "drag": "pass", "close": "pass", "focus_restore": "pass"},
        "settings": {"width": 762, "height": 562, "light": "pass", "dark": "pass", "drag": "pass", "close_modal": "pass", "save": "pass"},
        "wizard": {"width": 782, "height": 582, "light": "pass", "dark": "automated-contract", "drag": "pass", "close_modal": "pass"},
    }
    return {
        "schema_version": 1,
        "milestone": "V105-M5",
        "baseline": {
            "release": "v1.0.4",
            "source_head": OFFICIAL_SOURCE_HEAD,
            "zip_sha256": OFFICIAL_ZIP_SHA256,
            "exe_sha256": OFFICIAL_EXE_SHA256,
            "windows": copy.deepcopy(EXPECTED_WINDOWS),
            "surface_ownership": {"web_surface": ["background", "border", "radius", "shadow"], "native_surface": ["transparent-window", "shadow"]},
        },
        "candidate": {
            "kind": "dirty-controlled-m5-candidate",
            "candidate_id": "V105-M5-test",
            "source_head": BASELINE_HEAD,
            "source_tree_dirty": True,
            "staged_exe_sha256": M5_EXE_SHA256,
            "native_dll_sha256": NATIVE_DLL_SHA256,
            "identity_path": ".artifacts/candidates/v1.0.5/V105-M5-test/candidate-identity.json",
            "publication_allowed": False,
            "retained": True,
        },
        "surface_contract": {
            "transparent_root": "pass",
            "web_owner": ["background", "border", "radius"],
            "native_owner": ["transparent-window", "shadow"],
            "css_shadow_removed_from_window_frame": True,
            "mini_surface_unchanged": True,
            "dimensions_unchanged": True,
        },
        "automation": {
            "window_surface_assertions": 16,
            "architecture": "pass",
            "typescript": "pass",
            "web_build": "pass",
            "cargo_test": "pass",
            "rust_tests": 54,
            "fmt": "pass",
            "clippy": "pass",
            "release_build": "pass",
        },
        "desktop": {
            "os": {"windows_11": "pass", "windows_10": "pending-environment", "windows_11_build": "26200"},
            **windows,
            "mini": {"surface_unchanged": "pass", "privacy_tab": "pass", "reveal": "pass"},
            "dpi_100": "pass",
            "dpi_125": "pass",
            "dpi_150": "pass",
        },
        "baseline_integrity": {
            "system_scale_restored": True,
            "applied_dpi": 96,
            "per_monitor_dpi_values": [0, 0],
            "configuration_restored": True,
            "previous_configuration_restored": True,
            "debug_log_restored": True,
            "configuration_sha256": "A" * 64,
            "previous_configuration_sha256": "B" * 64,
            "debug_log_sha256": "C" * 64,
            "remaining_processes": 0,
            "income_formula_changed": False,
            "calendar_data_changed": False,
            "configuration_schema_changed": False,
        },
        "raw_evidence": {
            "storage": "local-ignored",
            "index": ".artifacts/acceptance/v1.0.5/V105-M5-test/index.json",
            "repository_contains_raw_screenshots_or_logs": False,
        },
        "conclusion": {
            "milestone": "passed_with_pending_environment",
            "completed_tasks": 8,
            "candidate_decision": "retain",
            "windows_10": "pending-environment",
            "release_created": False,
            "next_milestone": "V105-M6",
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


def valid_document_fixture() -> tuple[str, str, str, str, str]:
    progress = """
| V105-M5 | 三窗单一表面真实壳 Spike | 已完成（Windows 10 待环境补证） | 8/8 | FR-008、009 |
- [x] `V105-M5-001`
- [x] `V105-M5-002`
- [x] `V105-M5-003`
- [x] `V105-M5-004`
- [x] `V105-M5-005`
- [x] `V105-M5-006`
- [x] `V105-M5-007`
- [x] `V105-M5-008`
"""
    verification = "M5 结论：通过；Windows 10 待环境补证。"
    current = "V105-M0 至 M5 已完成 52/52；下一步执行 V105-M6。"
    traceability = "M5 已通过"
    spike = "保留单一表面候选；Windows 10 待补证。"
    return progress, verification, current, traceability, spike


def verify_document_routing_contract() -> None:
    fixture = valid_document_fixture()
    validate_document_routing(*fixture)
    print("PASS accepts M5 completion after routing to M6")

    post_acc = list(fixture)
    post_acc[2] = (
        "V105-M0 至 M6 已完成；V105-BUG-001 最小代码修复已通过，"
        "等待新 clean 候选真实复验，当前不可发布。"
    )
    validate_document_routing(*post_acc)
    print("PASS accepts blocked post-ACC candidate rebuild status")

    accepted = list(fixture)
    accepted[2] = (
        "V105-M0 至 M6 已完成；修复后独立 ACC 已通过，"
        "当前无发布阻塞，可进入发布收口。"
    )
    validate_document_routing(*accepted)
    print("PASS accepts completed post-ACC release closure status")

    for name, index, replacement in [
        ("incomplete M5 row", 0, fixture[0].replace("8/8", "7/8")),
        ("unchecked M5 task", 0, fixture[0].replace("- [x] `V105-M5-008`", "- [ ] `V105-M5-008`")),
        ("missing M5 current fact", 2, "V105-M6 正在执行"),
        (
            "post-ACC route missing publication block",
            2,
            "V105-M0 至 M6 已完成；V105-BUG-001 等待新 clean 候选。",
        ),
        (
            "post-ACC pass missing release closure",
            2,
            "V105-M0 至 M6 已完成；修复后独立 ACC 已通过。",
        ),
    ]:
        values = list(fixture)
        values[index] = replacement
        try:
            validate_document_routing(*values)
        except AssertionError:
            print(f"PASS rejects {name}")
            continue
        raise AssertionError(f"document routing validator accepted invalid fixture: {name}")


def main() -> int:
    try:
        validate_evidence(sample())
        print("PASS accepts valid M5 fixture")
        verify_document_routing_contract()
        cases = [
            ("official hash drift", lambda value: value["baseline"].update(zip_sha256="0" * 64)),
            ("window dimensions drift", lambda value: value["baseline"]["windows"]["settings"].update(width=700)),
            ("publishable dirty candidate", lambda value: value["candidate"].update(publication_allowed=True)),
            ("discarded approved candidate", lambda value: value["candidate"].update(retained=False)),
            ("dual candidate shadow", lambda value: value["surface_contract"]["web_owner"].append("shadow")),
            ("Mini surface changed", lambda value: value["surface_contract"].update(mini_surface_unchanged=False)),
            ("window dimensions changed", lambda value: value["surface_contract"].update(dimensions_unchanged=False)),
            ("missing surface assertions", lambda value: value["automation"].update(window_surface_assertions=15)),
            ("missing 125 DPI evidence", lambda value: value["desktop"].update(dpi_125="automated-contract")),
            ("Workbench drag failed", lambda value: value["desktop"]["workbench"].update(drag="fail")),
            ("invalid Windows 10 state", lambda value: value["desktop"]["os"].update(windows_10="pass-by-inference")),
            ("system DPI not restored", lambda value: value["baseline_integrity"].update(applied_dpi=144)),
            ("config not restored", lambda value: value["baseline_integrity"].update(configuration_restored=False)),
            ("business formula changed", lambda value: value["baseline_integrity"].update(income_formula_changed=True)),
            ("absolute evidence path", lambda value: value["raw_evidence"].update(index="E:/codex/private/index.json")),
            ("release created", lambda value: value["conclusion"].update(release_created=True)),
        ]
        for name, mutate in cases:
            expect_rejected(name, mutate)
    except (AssertionError, KeyError, TypeError) as error:
        print(f"FAIL {error}", file=sys.stderr)
        return 1
    print(f"PASS v1.0.5 M5 negative contracts ({len(cases) + 1}/17)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
