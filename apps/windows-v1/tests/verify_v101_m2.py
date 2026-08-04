from __future__ import annotations

import json
import re
import sys
from pathlib import Path


APP_ROOT = Path(__file__).resolve().parents[1]


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def verify_config_contract() -> None:
    defaults = json.loads(read(APP_ROOT / "contracts" / "config-v101-defaults.json"))
    model = read(APP_ROOT / "src" / "configModel.ts")
    domain = read(APP_ROOT / "src" / "domain" / "configuration.ts")
    require(defaults["config_version"] == 7, "Default config is not v7")
    versions = {
        int(value)
        for value in re.findall(r"(?:config_version:\s*|CURRENT_CONFIG_VERSION\s*=\s*)(\d+)", domain)
    }
    require(versions and min(versions) >= 7, "TypeScript config regressed below v7")
    for kind in ["workday", "paid_rest", "unpaid_rest"]:
        require(kind in domain, f"TypeScript override kind is missing: {kind}")
    require(
        'from "./domain/configuration"' in model,
        "React config model does not consume the shared configuration domain",
    )


def verify_native_transaction() -> None:
    config = read(APP_ROOT / "src-tauri" / "src" / "config.rs")
    domain = read(APP_ROOT / "src-tauri" / "src" / "domain.rs")
    lib = read(APP_ROOT / "src-tauri" / "src" / "lib.rs")
    for token in [
        "migrate_v6",
        "config.v1.0-compatible-backup",
        "config.override_kind_unknown",
        "save_date_override_transactional",
    ]:
        require(token in config, f"Native date override transaction is missing: {token}")
    require(
        "date_override_leave_requires_workday" in domain,
        "Automatic rest-day restriction is missing",
    )
    for event in [
        "date_override.saved",
        "date_override.unchanged",
        "date_override.failed",
        "date_override.removed",
        "date_override.migrated",
    ]:
        require(event in lib, f"Native semantic event is missing: {event}")
    require("save_date_override," in lib, "Date override command is not registered")


def verify_frontend_flow() -> None:
    app = read(APP_ROOT / "src" / "App.tsx")
    model = read(APP_ROOT / "src" / "model.ts")
    reducer = read(APP_ROOT / "src" / "dateOverrideState.ts")
    for copy in ["自动判断", "工作日", "带薪休息", "不带薪休息", "正在应用", "取消"]:
        require(copy in app, f"Date override UI is missing: {copy}")
    for event in [
        "calendar.override.opened",
        "calendar.override.cancelled",
        "calendar.override.applied",
        "calendar.override.failed",
    ]:
        require(event in app, f"Date override UI event is missing: {event}")
    for token in [
        'className="modal-backdrop"',
        'aria-modal="true"',
        'event.key === "Escape"',
        "setOverrideFeedback(message)",
        "setSelectedDate(null)",
        "onApplied(result.message)",
    ]:
        require(token in app, f"Date override modal behavior is missing: {token}")
    event_logic = app[
        app.index("dispatch({ type: result.status"):
        app.index("onApplied(result.message)")
    ]
    require(
        event_logic.index('result.status === "unchanged"')
        < event_logic.index('state.draft === "automatic"'),
        "Unchanged automatic overrides must log unchanged instead of removed",
    )
    for token in [
        "saveDateOverride",
        "lmm:configuration-updated",
        "draft: state.persisted",
        "failure must preserve",
    ]:
        source = "\n".join([
            model,
            reducer,
            read(APP_ROOT / "src" / "services" / "dashboardService.ts"),
            read(APP_ROOT / "tests" / "date-override-state.behavior.ts"),
        ])
        require(token in source, f"Date override behavior contract is missing: {token}")


def verify_calendar_settings_contract() -> None:
    app = read(APP_ROOT / "src" / "App.tsx")
    require("允许手动调整" not in app, "Calendar settings still expose the obsolete switch")
    for copy in [
        "离线节假日数据",
        "中国大陆 2025-2026",
        "手动调整 &gt; 官方日历 &gt; 休息模式",
        "单日调整请前往收入日历",
    ]:
        require(copy in app, f"Calendar settings contract is missing: {copy}")


def verify_no_absolute_paths() -> None:
    files = [
        APP_ROOT / "src" / "dateOverrideState.ts",
        APP_ROOT / "tests" / "date-override-state.behavior.ts",
        APP_ROOT / "src-tauri" / "src" / "config.rs",
    ]
    content = "\n".join(read(path) for path in files)
    require("C:\\Users\\" not in content, "M2 implementation contains a Windows user path")
    require("E:\\codex\\" not in content, "M2 implementation contains a workspace path")


def main() -> int:
    checks = [
        verify_config_contract,
        verify_native_transaction,
        verify_frontend_flow,
        verify_calendar_settings_contract,
        verify_no_absolute_paths,
    ]
    try:
        for check in checks:
            check()
            print(f"PASS {check.__name__}")
    except (AssertionError, KeyError, TypeError, ValueError, json.JSONDecodeError) as error:
        print(f"FAIL {error}", file=sys.stderr)
        return 1
    print(f"PASS v1.0.1 M2 date override transaction ({len(checks)} checks)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
