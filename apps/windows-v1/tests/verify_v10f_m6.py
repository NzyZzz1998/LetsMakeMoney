from __future__ import annotations

import json
import sys
from pathlib import Path


APP_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = APP_ROOT.parents[1]
EVIDENCE_PATH = REPO_ROOT / "doc" / "releases" / "v1.0.F" / "evidence" / "m6-cold-start-performance.json"
SPIKE_PATH = REPO_ROOT / "doc" / "releases" / "v1.0.F" / "cold-start-spike.md"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def verify_evidence() -> None:
    evidence = json.loads(EVIDENCE_PATH.read_text(encoding="utf-8"))
    require(evidence["milestone"] == "V10F-M6", "wrong milestone")
    require(evidence["sample_count"] == {"cold": 10, "warm": 10}, "M6 requires 10 cold and 10 warm runs")
    require(evidence["thresholds"]["cold_start_p95_ms"] == 2000, "cold-start threshold drifted")
    require(evidence["thresholds"]["mini_first_frame_p95_ms"] == 1200, "Mini threshold drifted")
    require(evidence["thresholds"]["workbench_first_frame_p95_ms"] == 1500, "Workbench threshold drifted")
    require(evidence["thresholds"]["js_gzip_bytes"] == 184320, "bundle threshold drifted")
    require(evidence["thresholds"]["long_task_ms"] == 100, "long-task threshold drifted")
    require(evidence["thresholds"]["minimum_optimization_gain_percent"] == 15, "retention threshold drifted")
    require(evidence["executable"]["sha256"], "candidate EXE identity is missing")
    require(evidence["source_head"], "source HEAD is missing")
    require(evidence["source_tree_dirty"] is True, "development evidence must disclose the dirty tree")

    assessment = evidence["threshold_assessment"]
    review_required = any(assessment.values())
    require(evidence["optimization_review_required"] is review_required, "threshold decision is inconsistent")

    optimization = evidence["optimization"]
    if optimization["attempted"]:
        require(optimization["target"], "attempted optimization is missing a target")
        require(optimization["gain_percent"] is not None, "attempted optimization is missing measured gain")
        expected_retention = optimization["gain_percent"] >= 15
        require(optimization["retained"] is expected_retention, "optimization retention violates the 15% rule")
    else:
        require(optimization["retained"] is False, "an unattempted optimization cannot be retained")


def verify_spike_document() -> None:
    text = SPIKE_PATH.read_text(encoding="utf-8")
    for marker in (
        "V10F-M6",
        "冷启动",
        "Mini",
        "Workbench",
        "JS gzip",
        "长任务",
        "15%",
        "停止结论",
    ):
        require(marker in text, f"cold-start-spike.md is missing marker: {marker}")


def verify_gate_registration() -> None:
    manifest = json.loads((REPO_ROOT / "scripts" / "current-manifest.json").read_text(encoding="utf-8"))
    gates = {item["id"]: item for item in manifest["gates"]}
    require(gates.get("v10f-m6", {}).get("path") == "scripts/verify_v10f_m6.ps1", "M6 gate is not current")


def verify_targeted_optimization() -> None:
    platform = (APP_ROOT / "src-tauri" / "src" / "platform.rs").read_text(encoding="utf-8")
    start = platform.index("pub fn webview2_runtime_available() -> bool")
    implementation = platform[start : start + 700]
    require('Command::new("reg.exe")' not in implementation, "startup still launches reg.exe probes")
    require("startup WebView has been created" in implementation, "optimization rationale is missing")


def main() -> int:
    require(EVIDENCE_PATH.is_file(), "M6 evidence is missing")
    require(SPIKE_PATH.is_file(), "M6 spike document is missing")
    verify_evidence()
    verify_spike_document()
    verify_gate_registration()
    verify_targeted_optimization()
    print("PASS v1.0.F M6 cold-start evidence and stop rules (4 groups)")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (AssertionError, OSError, ValueError, json.JSONDecodeError) as error:
        print(f"FAIL v1.0.F M6: {error}", file=sys.stderr)
        raise SystemExit(1)
