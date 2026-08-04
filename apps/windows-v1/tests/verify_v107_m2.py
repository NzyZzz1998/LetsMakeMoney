from __future__ import annotations

import json
import re
import sys
from pathlib import Path


APP_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = APP_ROOT.parents[1]
RUST = APP_ROOT / "src-tauri" / "src"
TESTS = APP_ROOT / "tests"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def source(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def verify_startup_and_topmost_contract() -> None:
    tauri = json.loads(source(APP_ROOT / "src-tauri" / "tauri.conf.json"))
    mini = next(window for window in tauri["app"]["windows"] if window["label"] == "mini")
    require(mini["visible"] is False, "Mini must be created hidden before configuration hydration")

    rust = source(RUST / "lib.rs")
    for token in (
        '"startup"',
        "window.policy.requested",
        "window.policy.applied",
        "window.policy.failed",
        "apply_mini_topmost_policy",
        "schedule_window_operation_failure",
    ):
        require(token in rust, f"Missing startup/topmost contract: {token}")
    require(
        re.search(
            r'if configuration_initialized \{\s*show_window_with_options\(\s*app\.handle\(\),\s*"mini",\s*"startup",\s*false,\s*true,\s*true',
            rust,
            re.DOTALL,
        )
        is not None,
        "Configured startup must apply policy before showing Mini without stealing focus",
    )


def verify_visibility_lease_and_compensation() -> None:
    policy = source(RUST / "window_policy.rs")
    rust = source(RUST / "lib.rs")
    for token in (
        "VisibilityLeaseMachine",
        "transaction_id",
        "PrivacyRetracted",
        "HiddenByUser",
        "NotPresent",
        "ShowExpanded",
        "ShowPrivacyRetracted",
        "KeepHidden",
        "every_mini_pre_visibility_has_an_explicit_restore_action",
    ):
        require(token in policy, f"Missing visibility lease contract: {token}")
    for token in (
        "open_workbench_transaction",
        "confirm_workbench_ready_internal",
        "close_workbench_transaction",
        "compensate_workbench_loss",
        "schedule_workbench_open_watchdog",
        "workbench_initialization_timeout",
        "workbench_destroyed",
        "workbench_close_compensation",
    ):
        require(token in rust, f"Missing Workbench compensation path: {token}")


def verify_desktop_errors_do_not_use_browser_fallback() -> None:
    app = source(APP_ROOT / "src" / "App.tsx")
    service = source(APP_ROOT / "src" / "services" / "windowService.ts")
    require("WindowOperationError" in service, "Desktop window operations need a typed error")
    require("lmm:window-operation-failed" in service, "Desktop failures need visible feedback")
    require("if (runtime.isDesktop) reportWindowOperationFailure(detail)" in service, "Desktop errors must be reported")
    require("if (!windowService.isDesktop) window.location.search" in app, "Only browser preview may use query fallback")
    require("WindowOperationNotice" in app, "Desktop window failures need non-blocking feedback")


def verify_auto_hide_state_machine() -> None:
    controller = source(APP_ROOT / "src" / "features" / "mini" / "miniEdgeAutoHide.ts")
    characterization = source(TESTS / "mini-edge-auto-hide.m2-characterization.behavior.ts")
    randomized = source(TESTS / "mini-edge-auto-hide.m2-randomized.behavior.ts")
    require("pointerInside: false" in controller, "Dock completion must clear stale pointer intent")
    require("if (timer === scheduledTimer) timer = null" in controller, "Late timers must not orphan a newer timer")
    require("SEQUENCE_COUNT = 10_000" in randomized, "M2 must run 10,000 deterministic sequences")
    require("BASE_SEED" in randomized and "seed=${seed}" in randomized, "Random failures must retain a reproduction seed")
    require("no-pointerleave retraction works" in characterization, "Characterization must describe the fixed contract")
    require("failure is reproducible" not in characterization, "Historical failed expectation must not remain current")


def verify_move_finalize_recover_contract() -> None:
    rust = source(RUST / "lib.rs")
    move_section = rust[rust.index("fn move_app_window"): rust.index("fn finalize_window_drag")]
    finalize_section = rust[rust.index("fn finalize_window_drag"): rust.index("fn recover_app_window")]
    recover_section = rust[rust.index("fn recover_app_window"): rust.index("fn window_drag_origin")]
    require("safe_window_position" not in move_section, "Pointer move must not clamp the window")
    require("safe_window_position" in finalize_section, "Pointer up must finalize against a safe grab region")
    require("safe_window_position" in recover_section, "Explicit recovery must restore a safe grab region")

    policy = source(RUST / "window_policy.rs")
    for token in (
        "MINI_SAFE_GRAB_WIDTH_LOGICAL_PX: i32 = 28",
        "MINI_SAFE_GRAB_HEIGHT_LOGICAL_PX: i32 = 48",
        "STANDARD_SAFE_GRAB_LOGICAL_PX: i32 = 48",
        "safe_grab_thresholds_scale_at_100_125_and_150_percent",
        "the 28px privacy tab is a valid reachable Mini position",
    ):
        require(token in policy, f"Missing safe-grab contract: {token}")


def verify_frontend_lifecycle_contract() -> None:
    drag = source(APP_ROOT / "src" / "hooks" / "useWindowDrag.ts")
    mini = source(APP_ROOT / "src" / "features" / "mini" / "useMiniEdgeAutoHide.ts")
    app = source(APP_ROOT / "src" / "App.tsx")
    require('kind !== "mini"' in drag and "finalizeDrag(kind)" in drag, "Non-Mini drag must finalize once")
    require("onDragEnd?.()" in drag, "Mini drag must preserve its native finalizer")
    require("workbench_restore_privacy" in mini and "current.refresh()" in mini, "Privacy restoration must not reveal Mini")
    require("workbenchReady()" in app, "Workbench must acknowledge successful initialization")


def main() -> int:
    checks = [
        verify_startup_and_topmost_contract,
        verify_visibility_lease_and_compensation,
        verify_desktop_errors_do_not_use_browser_fallback,
        verify_auto_hide_state_machine,
        verify_move_finalize_recover_contract,
        verify_frontend_lifecycle_contract,
    ]
    try:
        for check in checks:
            check()
            print(f"PASS {check.__name__}")
    except (AssertionError, KeyError, TypeError, ValueError, OSError, json.JSONDecodeError) as error:
        print(f"FAIL {error}", file=sys.stderr)
        return 1
    print(f"PASS v1.0.7 M2 static contracts ({len(checks)} groups)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
