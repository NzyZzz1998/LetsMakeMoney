import os
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RUST = (ROOT / "src-tauri" / "src" / "lib.rs").read_text(encoding="utf-8")
PLATFORM = (ROOT / "src-tauri" / "src" / "platform.rs").read_text(encoding="utf-8")
APP = (ROOT / "src" / "App.tsx").read_text(encoding="utf-8")
CARGO = (ROOT / "src-tauri" / "Cargo.toml").read_text(encoding="utf-8")

cargo_home = Path(
    os.environ.get(
        "CARGO_HOME",
        str(Path.home() / ".cargo"),
    )
)
tray_provider_candidates = list(
    cargo_home.glob(
        "registry/src/*/tray-icon-0.24.1/src/platform_impl/windows/mod.rs"
    )
)
if len(tray_provider_candidates) != 1:
    raise SystemExit(
        "Expected exactly one tray-icon 0.24.1 source under CARGO_HOME; "
        f"found {len(tray_provider_candidates)}"
    )
TRAY_PROVIDER = tray_provider_candidates[0].read_text(encoding="utf-8")

checks = {
    "native-tray-menu": all(
        token in RUST
        for token in (
            "TrayIconBuilder::with_id",
            "显示 / 隐藏迷你收入",
            "打开今日工作台",
            "偏好设置",
            "重新配置",
            "退出 LetsMakeMoney",
        )
    ),
    "left-click-toggle": all(
        token in RUST
        for token in (
            "MouseButton::Left",
            "MouseButtonState::Up",
            "toggle_mini_window",
            "tray.left_click",
        )
    ),
    "window-policy-reapplied": all(
        token in RUST
        for token in (
            "apply_window_policy",
            "set_skip_taskbar",
            "set_always_on_top",
            "window.policy_applied",
        )
    ),
    "window-reuse": "get_webview_window(label)" in RUST and "ensure_window" in RUST,
    "close-hides-explicit-exit": all(
        token in RUST
        for token in ("CloseRequested", "prevent_close", "ExitState", "app.exit(0)")
    ),
    "monitor-safe-fallback": all(
        token in RUST + PLATFORM
        for token in (
            "available_monitors",
            "primary_monitor",
            "clamp_window_to_monitor",
            "supports_monitors_left_of_primary_display",
        )
    ),
    "explorer-recovery-provider": all(
        token in TRAY_PROVIDER for token in ("TaskbarCreated", "re-register")
    )
    and 'tray-icon-0.24.1' in RUST,
    "support-actions": all(
        token in APP + RUST
        for token in (
            "open_data_directory",
            "diagnostic_summary",
            "navigator.clipboard.writeText",
            "support.diagnostic_copied",
            "evaluate_update_response",
            "update.check_failed",
        )
    ),
    "degraded-update": "当前版本可继续正常使用" in APP,
    "semantic-logs": all(
        token in RUST
        for token in (
            "tray.registered",
            "tray.command",
            "window.show_requested",
            "window.shown",
            "window.hidden",
            "window.activation_failed",
            "window.close_hidden",
        )
    ),
    "tray-feature-locked": 'features = ["tray-icon"]' in CARGO,
    "no-pet-menu": not any(
        token in (RUST + APP).lower()
        for token in ("pure_pet", "pet mode", "桌宠模式", "宠物市场")
    ),
}

for name, passed in checks.items():
    print(f"{'PASS' if passed else 'FAIL'} {name}")

failed = [name for name, passed in checks.items() if not passed]
if failed:
    raise SystemExit(f"M5 checks failed: {', '.join(failed)}")
print(f"V10-M5 static PASS {len(checks)}/{len(checks)}")
