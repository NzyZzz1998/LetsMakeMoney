from __future__ import annotations

import json
import sys
from pathlib import Path


APP_ROOT = Path(__file__).resolve().parents[1]


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def verify_sync_fixtures() -> None:
    fixtures = json.loads(
        read(APP_ROOT / "tests" / "fixtures" / "v101-sync-fixtures.json")
    )
    case_ids = {case["id"] for case in fixtures["cases"]}
    required = {
        "working-local-tick",
        "lunch-freeze",
        "thirty-second-authoritative-sync",
        "resume-immediate-sync",
        "one-cent-tolerance",
        "late-authoritative-snapshot-ignored",
    }
    require(required <= case_ids, f"Sync fixtures are missing: {sorted(required - case_ids)}")


def verify_local_tick_contract() -> None:
    source = read(APP_ROOT / "src" / "authoritativeSync.ts")
    behavior = read(APP_ROOT / "tests" / "authoritative-sync.behavior.ts")
    for token in [
        "calculateLocalTick",
        'authority.phase !== "working"',
        "nextBoundarySeconds",
        "shouldRunAuthoritativeSync",
        "shouldApplyAuthoritativeSnapshot",
        "needsAuthoritativeCorrection",
        "syncFailureDisposition",
        "wallClockJumped",
        "BigInt",
    ]:
        require(token in source, f"Local authoritative helper is missing: {token}")
    for message in [
        "lunch must freeze local income",
        "local tick must not interpolate past a boundary",
        "a late authority response must not replace",
        "consecutive failures across a boundary",
        "a wall-clock jump must force",
    ]:
        require(message in behavior, f"Sync behavior assertion is missing: {message}")


def verify_runtime_scheduler_and_logs() -> None:
    model = read(APP_ROOT / "src" / "model.ts")
    contract = json.loads(read(APP_ROOT / "contracts" / "log-v101-contract.json"))
    required_events = {
        "schedule.owner_date.resolved",
        "schedule.wall_clock_changed",
        "earnings.authoritative_sync.requested",
        "earnings.authoritative_sync.completed",
        "earnings.authoritative_sync.failed",
        "earnings.authoritative_sync.drift_corrected",
        "earnings.authoritative_sync.ignored",
        "earnings.boundary.recalculated",
        "earnings.local_tick.paused",
    }
    require(required_events <= set(contract["events"]), "Log contract is incomplete")
    for event in required_events:
        require(event in model, f"Runtime semantic event is missing: {event}")
    for token in [
        "30_000",
        "document.visibilityState",
        'window.addEventListener("focus"',
        'document.addEventListener("visibilitychange"',
        '"configuration_updated"',
        '"business_boundary"',
        '"wall_clock_changed"',
    ]:
        require(token in model, f"Authority scheduler is missing: {token}")
    require(
        'window.setInterval(() => {' in model and "}, 1000);" in model,
        "One-second local display timer is missing",
    )


def verify_feedback_states() -> None:
    app = read(APP_ROOT / "src" / "App.tsx")
    styles = read(APP_ROOT / "src" / "styles.css")
    for copy in [
        "正在重新同步，当前显示最近一次可信结果。",
        "正在同步最新结果",
        "时间边界后的结果尚未同步成功",
    ]:
        source = app + read(APP_ROOT / "src" / "model.ts")
        require(copy in source, f"Sync feedback is missing: {copy}")
    require("sync-notice" in styles, "Sync notice style is missing")
    require("mini-window__sync" in styles, "Mini sync feedback style is missing")


def verify_no_sensitive_paths() -> None:
    files = [
        APP_ROOT / "src" / "authoritativeSync.ts",
        APP_ROOT / "tests" / "authoritative-sync.behavior.ts",
        APP_ROOT / "src" / "model.ts",
    ]
    content = "\n".join(read(path) for path in files)
    require("C:\\Users\\" not in content, "M4 contains a Windows user path")
    require("E:\\codex\\" not in content, "M4 contains a workspace path")


def main() -> int:
    checks = [
        verify_sync_fixtures,
        verify_local_tick_contract,
        verify_runtime_scheduler_and_logs,
        verify_feedback_states,
        verify_no_sensitive_paths,
    ]
    try:
        for check in checks:
            check()
            print(f"PASS {check.__name__}")
    except (AssertionError, KeyError, TypeError, ValueError, json.JSONDecodeError) as error:
        print(f"FAIL {error}", file=sys.stderr)
        return 1
    print(f"PASS v1.0.1 M4 authoritative sync ({len(checks)} checks)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
