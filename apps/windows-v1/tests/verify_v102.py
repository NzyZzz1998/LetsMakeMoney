from __future__ import annotations

import json
import re
import sys
from pathlib import Path


APP = Path(__file__).resolve().parents[1]
ROOT = APP.parents[1]


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def version_tuple(value: str) -> tuple[int, int, int]:
    parts = value.split(".")
    require(len(parts) == 3 and all(part.isdigit() for part in parts), f"invalid version: {value}")
    return tuple(int(part) for part in parts)


def main() -> int:
    package = json.loads(read(APP / "package.json"))
    package_lock = json.loads(read(APP / "package-lock.json"))
    cargo = read(APP / "src-tauri" / "Cargo.toml")
    tauri = json.loads(read(APP / "src-tauri" / "tauri.conf.json"))
    capabilities = json.loads(read(APP / "src-tauri" / "capabilities" / "mini-window.json"))
    app_source = read(APP / "src" / "App.tsx")
    main_source = read(APP / "src" / "main.tsx")
    presentation = read(APP / "src" / "presentation.ts")
    theme = read(APP / "src" / "theme.ts")
    styles = read(APP / "src" / "styles.css")
    config_source = read(APP / "src-tauri" / "src" / "config.rs")
    native_source = read(APP / "src-tauri" / "src" / "lib.rs")
    setup_source = native_source.split(".setup(|app| {", 1)[1].split(".on_window_event", 1)[0]
    model = read(APP / "src" / "model.ts")
    sync = read(APP / "src" / "authoritativeSync.ts")
    behavior = read(APP / "tests" / "authoritative-sync.behavior.ts")
    presentation_behavior = read(APP / "tests" / "presentation.behavior.ts")
    log_contract = json.loads(read(APP / "contracts" / "log-v102-contract.json"))
    notices = read(ROOT / "THIRD_PARTY_NOTICES.md")

    current_version = package["version"]
    cargo_version = re.search(r'^version = "([^"]+)"$', cargo, re.MULTILINE)
    require(version_tuple(current_version) >= (1, 0, 2), "current version must retain the v1.0.2 contract")
    require(package_lock["version"] == current_version, "package-lock root version must match package.json")
    require(
        package_lock["packages"][""]["version"] == current_version,
        "package-lock workspace version must match package.json",
    )
    require(cargo_version is not None and cargo_version.group(1) == current_version, "Cargo.toml version must match package.json")
    require(tauri["version"] == current_version, "tauri.conf.json version must match package.json")
    require(
        app_source.count(f'currentVersion: "{current_version}"') == 2,
        "update checks must use the current package version",
    )
    require(f"<dd>{current_version}</dd>" in app_source, "About must display the current package version")
    require(package["dependencies"]["lucide-react"] == "1.27.0", "lucide-react must be exactly pinned")
    require(
        package_lock["packages"]["node_modules/lucide-react"]["version"] == "1.27.0",
        "package-lock must resolve lucide-react 1.27.0",
    )
    for token in ("Lucide React", "1.27.0", "ISC"):
        require(token in notices, f"THIRD_PARTY_NOTICES is missing {token}")

    require("shouldRetryInitialSync" in sync, "startup retry policy is missing")
    require('errorCode === "calculation_unavailable"' in sync, "retry must be limited to transient calculation failures")
    require("consecutiveFailures <= maxAttempts" in sync, "startup retry must be bounded")
    require("shouldRetryInitialSync(" in model, "dashboard does not apply startup retry policy")
    require("startup_retry" in model, "startup retry reason is missing")
    require("earnings.authoritative_sync.retry_scheduled" in model, "startup retry semantic log is missing")
    require("initialRetryTimer" in model and "clearTimeout" in model, "startup retry cleanup is missing")

    require("25/25 passed" in behavior, "authoritative sync behavior count is stale")
    require("invalid_work_hours" in behavior, "real configuration errors must remain visible")
    require(
        "earnings.authoritative_sync.retry_scheduled" in log_contract["events"],
        "v1.0.2 log contract is missing startup retry",
    )

    require("nextBoundarySeconds" in presentation, "stage copy must consume authoritative boundaries")
    require("timelineRows" in presentation, "timeline presentation selector is missing")
    require("11/11 passed" in presentation_behavior, "presentation behavior count is stale")
    require('type ThemeMode = "light" | "dark"' in theme, "theme mode contract is missing")
    require("lmm://theme-preview" in theme, "cross-window theme event is missing")
    require(
        "core:event:default" in capabilities["permissions"],
        "all product windows must be allowed to listen for and emit cross-window theme events",
    )
    require(
        "THEME_LISTENER_COLD_START_DELAY_MS = 3000" in main_source
        and "setTimeout" in main_source
        and "listenForThemeChanges().catch" in main_source,
        "cross-window theme listener registration must wait until WebView setup completes and handle failure",
    )
    require("[data-theme=\"dark\"]" in styles, "dark theme token layer is missing")
    require("config.config_version != 8" in config_source, "configuration version must be 8")
    require("theme_mode" in config_source, "persisted theme field is missing")
    require("stored_theme_requires_fallback" in config_source, "invalid theme fallback is missing")
    require("set_mini_window_state" in native_source, "mini state size command is missing")
    require(
        "for spec in WINDOW_SPECS" not in setup_source
        and "Secondary" in setup_source
        and 'show_window_internal(app.handle(), "wizard")?' in setup_source,
        "startup must create only Mini and lazily create secondary WebViews",
    )
    require(
        "async fn show_app_window" in native_source
        and "tauri::async_runtime::spawn_blocking" in native_source,
        "secondary WebViews must be created outside the synchronous WebView IPC callback",
    )
    require(
        app_source.count(
            "onConfirm={() => {\n"
            "            setConfirmClose(false);\n"
            "            config.cancel();"
        )
        == 2,
        "Settings and Wizard must clear the close confirmation before hiding a reused window",
    )
    require(
        "const firstRunRequest = useRef(0);" in app_source
        and "const refreshFirstRun = useCallback(async () => {" in app_source
        and "const request = ++firstRunRequest.current;" in app_source
        and app_source.count("request === firstRunRequest.current") >= 2,
        "Wizard must guard configuration_initialized responses against stale async writeback",
    )
    require(
        app_source.count("void refreshFirstRun();") >= 2
        and 'window.addEventListener("lmm:window-shown", resetWizard);' in app_source,
        "Wizard must refresh first-run state on mount and every reused-window show",
    )
    save_success = app_source.split("else if (await config.save()) {", 1)[1].split(
        "await hideCurrentWindow();",
        1,
    )[0]
    require(
        "firstRunRequest.current += 1;" in save_success
        and "setFirstRun(false);" in save_success,
        "Wizard save success must invalidate stale first-run requests and enter configured mode",
    )
    for event in (
        "window.ensure_completed",
        "window.policy_applied",
        "window.visible",
        "window.focused",
        "window.show_failed",
    ):
        require(event in native_source, f"native window show chain is missing {event}")
        require(
            event in log_contract["events"],
            f"v1.0.2 log contract is missing {event}",
        )
    require(
        "stage=" in native_source and "reason=" in native_source,
        "window show failure logging must identify the failed stage and reason",
    )
    require("date_override.migrated" in native_source, "v1.0.1 migration event compatibility is missing")
    for event in (
        "theme.preview_applied",
        "theme.saved",
        "theme.reverted",
        "theme.invalid_fallback",
        "mini.window.size_applied",
    ):
        require(event in log_contract["events"], f"log contract is missing {event}")

    print("PASS v1.0.2 presentation, theme, startup and distribution contracts")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as error:
        print(f"FAIL v1.0.2 verification: {error}", file=sys.stderr)
        raise SystemExit(1)
