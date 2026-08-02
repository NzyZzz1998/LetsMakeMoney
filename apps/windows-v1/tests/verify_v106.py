from __future__ import annotations

import json
import re
import sys
from pathlib import Path


APP = Path(__file__).resolve().parents[1]
ROOT = APP.parents[1]
FAILURES: list[str] = []


def read(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError) as error:
        FAILURES.append(f"无法按 UTF-8 读取 {path.relative_to(ROOT)}：{error}")
        return ""


def require(path: Path, *markers: str) -> str:
    text = read(path)
    for marker in markers:
        if marker not in text:
            FAILURES.append(f"{path.relative_to(ROOT)} 缺少合同：{marker}")
    return text


def check_versions() -> None:
    package = json.loads(read(APP / "package.json"))
    lock = json.loads(read(APP / "package-lock.json"))
    tauri = json.loads(read(APP / "src-tauri" / "tauri.conf.json"))
    versions = {
        "package.json": package.get("version"),
        "package-lock.json": lock.get("version"),
        "package-lock root": lock.get("packages", {}).get("", {}).get("version"),
        "tauri.conf.json": tauri.get("version"),
    }
    cargo = read(APP / "src-tauri" / "Cargo.toml")
    match = re.search(r'(?m)^version\s*=\s*"([^"]+)"', cargo)
    versions["Cargo.toml"] = match.group(1) if match else None
    for source, version in versions.items():
        if version != "1.0.6":
            FAILURES.append(f"{source} 版本应为 1.0.6，实际为 {version!r}")


def check_theme_contract() -> None:
    index = require(
        APP / "index.html",
        'data-theme-ready="true"',
        'dataset.theme = "light"',
        'dataset.themeReady = "false"',
    )
    if "localStorage" in index:
        FAILURES.append("index.html 首帧不得从 localStorage 读取主题")

    main = require(
        APP / "src" / "main.tsx",
        "await bootstrapTheme()",
        "listenForThemeChanges()",
        'synchronizeTheme("window_shown")',
    )
    if "3000" in main:
        FAILURES.append("main.tsx 不得恢复 3000ms 延迟监听")

    theme = require(
        APP / "src" / "theme.ts",
        'const LEGACY_THEME_STORAGE_KEY = "lmm.theme"',
        "removeItem?.(LEGACY_THEME_STORAGE_KEY)",
        'runtime.invoke<ThemeSessionSnapshot>("read_theme_session"',
        'runtime.invoke<ThemeSessionSnapshot>("update_theme_session"',
        "request: {",
        'await synchronize("listener_registered")',
        "snapshot.revision < appliedRevision",
        '"theme.window_applied"',
    )
    for forbidden in (
        "getItem(LEGACY_THEME_STORAGE_KEY)",
        "setItem(LEGACY_THEME_STORAGE_KEY",
    ):
        if forbidden in theme:
            FAILURES.append(f"旧主题缓存不得成为读写事实源：{forbidden}")

    require(
        APP / "src" / "configurationTransaction.ts",
        'themeReason: "hydration_incomplete"',
        "if (!hydrated)",
    )
    require(
        APP / "src" / "App.tsx",
        "if (config.loading)",
        "if (config.hydrationError)",
        "config.reload(false)",
    )

    rust = require(
        APP / "src-tauri" / "src" / "lib.rs",
        "struct ThemeSessionState",
        "struct ThemeSessionUpdateRequest",
        "fn read_theme_session(",
        "fn update_theme_session(",
        'const THEME_SESSION_EVENT: &str = "lmm://theme-preview"',
        "app.emit(THEME_SESSION_EVENT",
        '"theme.loaded"',
        '"theme.preview_applied"',
        '"theme.saved"',
        '"theme.preview_reverted"',
        "read_theme_session,",
        "update_theme_session,",
    )
    if "ThemeSession::new(config.theme_mode.clone())" not in rust:
        FAILURES.append("ThemeSession 必须从 Rust 权威配置初始化")


def check_release_entrypoints() -> None:
    require(ROOT / "scripts" / "package_v106.ps1", 'Version = "1.0.6"')
    require(ROOT / "scripts" / "verify_v106.ps1", "verify_v106.py")
    require(
        ROOT / "scripts" / "verify_v106_package.ps1",
        'ExpectedVersion = "1.0.6"',
    )


def main() -> int:
    check_versions()
    check_theme_contract()
    check_release_entrypoints()
    if FAILURES:
        print(f"v1.0.6 定向合同检查失败：{len(FAILURES)} 项")
        for failure in FAILURES:
            print(f"- {failure}")
        return 1
    print("PASS v1.0.6 主题首帧、ThemeSession、hydration 与发布入口合同")
    return 0


if __name__ == "__main__":
    sys.exit(main())
