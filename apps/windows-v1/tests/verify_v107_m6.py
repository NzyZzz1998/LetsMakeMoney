from __future__ import annotations

import importlib.util
import json
import re
import sys
from pathlib import Path


APP_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = APP_ROOT.parents[1]
SCRIPTS = REPO_ROOT / "scripts"
RELEASE = REPO_ROOT / "doc" / "releases" / "v1.0.7"
EVIDENCE = RELEASE / "evidence"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def load_json(path: Path) -> object:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def read_utf8(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def load_python_module(path: Path, name: str):
    spec = importlib.util.spec_from_file_location(name, path)
    require(spec is not None and spec.loader is not None, f"Cannot load module: {path.name}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


def verify_script_lifecycle_and_historical_protection() -> None:
    manifest_validator = load_python_module(SCRIPTS / "verify_current_manifest.py", "v107_manifest_validator")
    manifest_validator.validate_repository(REPO_ROOT, SCRIPTS / "current-manifest.json")

    m1 = load_python_module(APP_ROOT / "tests" / "verify_v107_m1.py", "v107_m1_for_m6")
    m1.verify_current_manifest_and_negative_cases()

    lifecycle = load_json(SCRIPTS / "script-lifecycle.json")
    manifest = load_json(SCRIPTS / "current-manifest.json")
    require(isinstance(lifecycle, dict) and isinstance(manifest, dict), "Lifecycle documents must be objects")
    require("scripts/verify_v107_m6.ps1" in lifecycle["statuses"]["current"], "M6 gate is not current")
    require("scripts/collect_v107_performance.ps1" in lifecycle["statuses"]["manual"], "Performance collector must be manual")
    require("scripts/spike_v107_csp.ps1" in lifecycle["statuses"]["manual"], "CSP spike must be manual")
    gates = {gate["path"] for gate in manifest["gates"]}
    require("scripts/verify_v107_m6.ps1" in gates, "Current manifest does not include M6")


def verify_current_and_support_documents() -> None:
    current_path = REPO_ROOT / "doc" / "current.md"
    current = read_utf8(current_path)
    require(len(current.splitlines()) <= 100, "doc/current.md must remain a concise current entry")
    for phrase in (
        "Windows v1.0.6 Stable",
        "Windows v1.0.7 Stable",
        "V107-M6",
        "releases/v1.0.7/progress_v1.0.7.md",
        "v0.9-beta",
    ):
        require(phrase in current, f"doc/current.md is missing: {phrase}")

    support = read_utf8(RELEASE / "support-matrix.md")
    require("Windows 11 x86_64、单显示器、100% DPI" in support, "Windows 11 verified baseline is missing")
    require("Windows 10 x86_64 | 未验证" in support, "Windows 10 must be explicitly unverified")
    require("Windows 11 多显示器 | 暂不验证" in support, "Multi-display exclusion is missing")
    require("125% DPI | 已验证" in support, "125% DPI verified support is missing")
    require("150% DPI | 已验证" in support, "150% DPI verified support is missing")

    dpi_evidence = load_json(EVIDENCE / "acceptance-dpi-summary.json")
    require(isinstance(dpi_evidence, dict), "DPI evidence must be an object")
    require(dpi_evidence["milestone"] == "V107-ACC-DPI", "DPI evidence identity drift")
    require(dpi_evidence["candidate"]["publication_allowed"] is False, "Dirty DPI candidate cannot be publishable")
    require(dpi_evidence["environment"]["scales_verified"] == [100, 125, 150], "DPI evidence matrix is incomplete")
    require(dpi_evidence["conclusion"] == "passed", "DPI evidence has not passed")

    for path in (RELEASE / "script-lifecycle.md", RELEASE / "security-performance-gates.md"):
        require(path.is_file(), f"Missing M6 document: {path.name}")
        text = read_utf8(path)
        require("\ufffd" not in text and "锟斤拷" not in text, f"Garbled text in {path.name}")


def verify_redacted_evidence() -> None:
    evidence = load_json(EVIDENCE / "m6-governance-security-performance.json")
    require(isinstance(evidence, dict), "M6 evidence must be an object")
    require(evidence["schema_version"] == 1 and evidence["milestone"] == "V107-M6", "M6 evidence identity drift")
    require(evidence["source_tree_dirty"] is True, "M6 evidence must retain dirty-tree identity")
    require(evidence["release_eligible"] is False, "Dirty M6 artifact cannot be release eligible")
    require(evidence["environment_restore"]["candidate_processes_remaining"] == 0, "M6 left a candidate process")

    files = [
        EVIDENCE / "m6-governance-security-performance.json",
        EVIDENCE / "acceptance-dpi-summary.json",
        EVIDENCE / "external-evidence-index.md",
        RELEASE / "support-matrix.md",
        RELEASE / "security-performance-gates.md",
    ]
    absolute_path_pattern = re.compile(r"(?:[A-Za-z]:[\\/]|/Users/|/home/|\\Users\\)")
    secret_patterns = (
        re.compile(r"github_pat_[A-Za-z0-9_]+"),
        re.compile(r"ghp_[A-Za-z0-9]+"),
        re.compile(r"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----"),
        re.compile(r"AKIA[0-9A-Z]{16}"),
    )
    for path in files:
        text = read_utf8(path)
        require(not absolute_path_pattern.search(text), f"Absolute path leaked into {path.name}")
        for pattern in secret_patterns:
            require(not pattern.search(text), f"Sensitive token leaked into {path.name}")


def verify_csp_decision() -> None:
    tauri = load_json(APP_ROOT / "src-tauri" / "tauri.conf.json")
    candidate = load_json(APP_ROOT / "tests" / "fixtures" / "v107-csp-candidate.json")
    evidence = load_json(EVIDENCE / "m6-governance-security-performance.json")
    require(tauri["app"]["security"]["csp"] is None, "Formal CSP must remain disabled after the failed spike")
    candidate_csp = candidate["app"]["security"]["csp"]
    require("unsafe-eval" not in candidate_csp, "CSP candidate must not allow unsafe-eval")
    require("https://api.github.com" in candidate_csp, "CSP candidate must cover update metadata")
    require(evidence["csp"]["decision"] == "withdrawn", "CSP failure must result in withdrawal")
    require(evidence["csp"]["failure_code"] == "mini_bootstrap_unavailable", "CSP failure code drift")
    require(evidence["csp"]["ipc_and_update_ready"] is False, "CSP IPC failure must not be reported as passed")


def verify_performance_stop_gate() -> None:
    evidence = load_json(EVIDENCE / "m6-governance-security-performance.json")
    perf = evidence["performance"]
    require(perf["sample_count"] == {"cold": 10, "warm": 10}, "Performance baseline must be 10 cold + 10 warm")
    require(perf["metrics"]["cold_mini_ready_p95_ms"] > perf["thresholds"]["cold_start_p95_ms"], "Cold Mini debt disappeared without new evidence")
    require(perf["metrics"]["warm_mini_ready_p95_ms"] <= perf["thresholds"]["mini_first_frame_p95_ms"], "Warm Mini threshold result drift")
    require(perf["metrics"]["warm_workbench_ready_p95_ms"] <= perf["thresholds"]["workbench_first_frame_p95_ms"], "Warm Workbench threshold result drift")
    require(perf["metrics"]["js_gzip_bytes"] <= perf["thresholds"]["js_gzip_bytes"], "Bundle threshold result drift")
    require(perf["metrics"]["max_long_task_ms"] <= perf["thresholds"]["long_task_ms"], "Long-task threshold result drift")
    require(perf["targeted_experiment_gain_at_least_15_percent"] is False, "Unproven performance optimization must not be retained")
    require(perf["decision"] == "stop_without_retaining_optimization", "Performance stop decision drift")


def verify_governance_boundary_and_ipc() -> None:
    package = load_json(APP_ROOT / "package.json")
    dependencies = set(package.get("dependencies", {})) | set(package.get("devDependencies", {}))
    forbidden_state_libraries = {"redux", "@reduxjs/toolkit", "zustand", "recoil", "mobx", "xstate"}
    require(not dependencies.intersection(forbidden_state_libraries), "M6 introduced a global state library")

    fixture = load_json(APP_ROOT / "tests" / "fixtures" / "v107-ipc-contracts.json")
    commands = {scenario["command"] for scenario in fixture["scenarios"] if scenario["implementation_status"] == "active"}
    rust = "\n".join(path.read_text(encoding="utf-8") for path in (APP_ROOT / "src-tauri" / "src").rglob("*.rs"))
    for command in commands:
        require(command in rust, f"Active IPC command was renamed or removed: {command}")

    expected_local_boundaries = (
        APP_ROOT / "src-tauri" / "src" / "window_policy.rs",
        APP_ROOT / "src-tauri" / "src" / "services" / "overtime_service.rs",
        APP_ROOT / "src" / "features" / "calendar" / "monthlySummary.ts",
    )
    for path in expected_local_boundaries:
        require(path.is_file(), f"Expected local boundary is missing: {path.name}")


def main() -> int:
    checks = [
        verify_script_lifecycle_and_historical_protection,
        verify_current_and_support_documents,
        verify_redacted_evidence,
        verify_csp_decision,
        verify_performance_stop_gate,
        verify_governance_boundary_and_ipc,
    ]
    try:
        for check in checks:
            check()
            print(f"PASS {check.__name__}")
    except (AssertionError, KeyError, TypeError, json.JSONDecodeError, OSError, ValueError) as error:
        print(f"FAIL {error}", file=sys.stderr)
        return 1
    print(f"PASS v1.0.7 M6 governance, security, performance ({len(checks)} groups)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
