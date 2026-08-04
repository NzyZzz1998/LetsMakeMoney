from __future__ import annotations

import json
import re
from pathlib import Path


APP_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = APP_ROOT.parents[1]
FIXTURE_PATH = APP_ROOT / "tests" / "fixtures" / "v104-mini-edge-geometry.json"
RUST_PATH = APP_ROOT / "src-tauri" / "src" / "lib.rs"
CONTROLLER_PATH = APP_ROOT / "src" / "features" / "mini" / "miniEdgeAutoHide.ts"
HOOK_PATH = APP_ROOT / "src" / "features" / "mini" / "useMiniEdgeAutoHide.ts"
MINI_PATH = APP_ROOT / "src" / "features" / "mini" / "MiniWindow.tsx"
WINDOW_SERVICE_PATH = APP_ROOT / "src" / "services" / "windowService.ts"
APP_PATH = APP_ROOT / "src" / "App.tsx"
STYLES_PATH = APP_ROOT / "src" / "styles.css"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def read(path: Path) -> str:
    require(path.is_file(), f"missing M6 contract file: {path.relative_to(REPO_ROOT)}")
    return path.read_text(encoding="utf-8")


def function_scope(source: str, start: str, end: str) -> str:
    start_index = source.find(start)
    require(start_index >= 0, f"missing source marker: {start}")
    end_index = source.find(end, start_index + len(start))
    require(end_index >= 0, f"missing source marker: {end}")
    return source[start_index:end_index]


def verify_geometry_contract() -> None:
    fixture = json.loads(read(FIXTURE_PATH))
    contract = fixture["contract"]
    require(contract["dock_threshold_logical_px"] == 16, "dock threshold drift")
    require(contract["privacy_tab_logical_px"] == 10, "privacy tab width drift")
    require(contract["undock_threshold_logical_px"] == 24, "undock threshold drift")
    ids = {case["id"] for case in fixture["dock_cases"]}
    require("left-edge-error-height-100" in ids, "error-height docking case is missing")
    scales = {case["scale_factor"] for case in fixture["dock_cases"]}
    require({1.0, 1.25, 1.5} <= scales, "100/125/150 percent DPI matrix is incomplete")


def verify_frontend_state_machine() -> None:
    controller = read(CONTROLLER_PATH)
    for token in [
        "MINI_EDGE_RETRACT_DELAY_MS = 600",
        "MINI_EDGE_TRANSITION_MS = 180",
        '"dragging"',
        '"focus_inside"',
        '"menu_open"',
        '"modal_open"',
        '"retract_pending"',
    ]:
        require(token in controller, f"missing Mini state-machine contract: {token}")
    require(
        controller.count("scheduler.set(") == 1,
        "Mini auto-hide must maintain one retract timer registration point",
    )


def verify_reduced_motion_and_privacy_surface() -> None:
    hook = read(HOOK_PATH)
    mini = read(MINI_PATH)
    styles = read(STYLES_PATH)
    require("prefers-reduced-motion: reduce" in styles, "reduced-motion CSS is missing")
    require("prefers-reduced-motion: reduce" in hook, "native motion preference is missing")
    require(
        "configurationService" in hook
        and ".listenUpdated(handleConfigurationUpdated)" in hook,
        "Mini does not refresh after a cross-window Settings save",
    )
    require(
        '"lmm:configuration-updated"' in hook and "current.refresh()" in hook,
        "Mini configuration refresh fallback is missing",
    )
    require("mini-window--privacy-tab" in mini, "privacy-only Mini surface is missing")
    privacy_branch = function_scope(
        mini,
        'if (edge.snapshot.phase === "retracted")',
        'if (snapshot.state === "loading")',
    )
    for private_content in ["today_earned", "formatted_amount", "status_label", "current_date"]:
        require(
            private_content not in privacy_branch,
            f"retracted privacy surface leaks content token: {private_content}",
        )


def verify_native_lifecycle_boundary() -> None:
    rust = read(RUST_PATH)
    retract_scope = function_scope(
        rust,
        "fn set_mini_edge_retracted_internal(",
        "fn complete_mini_drag_internal(",
    )
    for forbidden in [
        "lmm:window-hidden",
        "hide_window_internal(",
        "suspend_webview_internal(",
    ]:
        require(
            forbidden not in retract_scope,
            f"edge retraction must not enter native hidden lifecycle: {forbidden}",
        )
    persistence_scope = function_scope(
        rust,
        "fn mini_edge_position_persistence_suppressed(",
        "fn update_runtime_mini_edge_config(",
    )
    require(
        "MiniEdgeVisibility::Retracted" in persistence_scope,
        "physical retracted coordinates may overwrite the expanded position",
    )
    size_scope = function_scope(
        rust,
        "fn set_mini_window_state(",
        "fn append_log(",
    )
    require(
        'visibility == "retracted"' in size_scope
        and 'set_mini_edge_retracted_internal(&app, true, "size_changed", true)' in size_scope,
        "loading/error height changes do not recompute the retracted edge position",
    )


def verify_native_logs_are_semantic_and_redacted() -> None:
    rust = read(RUST_PATH)
    for event in [
        "mini.edge_dock.detected",
        "mini.edge_dock.retracted",
        "mini.edge_dock.revealed",
        "mini.edge_dock.canceled",
        "mini.edge_dock.restore_fallback",
        "mini.edge_dock.failed",
    ]:
        require(event in rust, f"missing semantic Mini log event: {event}")
    edge_log_calls = [
        match.group(0)
        for match in re.finditer(r"append_log\([\s\S]*?\);", rust)
        if "mini.edge_dock." in match.group(0)
    ]
    require(len(edge_log_calls) >= 6, "Mini edge log coverage is incomplete")
    serialized = "\n".join(edge_log_calls).lower()
    for forbidden in ["salary", "amount", "window_x", "window_y", "x=", "y=", "position="]:
        require(forbidden not in serialized, f"Mini edge logs expose forbidden detail: {forbidden}")


def verify_typed_api_and_settings_contract() -> None:
    service = read(WINDOW_SERVICE_PATH)
    app = read(APP_PATH)
    require("interface MiniEdgeStatus" in service, "typed Mini edge status is missing")
    require("completeMiniDrag" in service, "typed Mini drag completion API is missing")
    require("setMiniEdgeRetracted" in service, "typed Mini retraction API is missing")
    require("reducedMotion" in service, "native API does not carry reduced-motion preference")
    require("贴边自动隐藏" in app, "Settings toggle label is missing")
    require(
        "靠近屏幕左右边缘后收起，悬停时展开" in app,
        "Settings toggle description drift",
    )


def main() -> int:
    checks = [
        verify_geometry_contract,
        verify_frontend_state_machine,
        verify_reduced_motion_and_privacy_surface,
        verify_native_lifecycle_boundary,
        verify_native_logs_are_semantic_and_redacted,
        verify_typed_api_and_settings_contract,
    ]
    try:
        for check in checks:
            check()
            print(f"PASS {check.__name__}")
    except (AssertionError, KeyError, TypeError, json.JSONDecodeError) as error:
        print(f"FAIL {error}")
        return 1
    print(f"PASS v1.0.4 M6 contracts ({len(checks)} checks)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
