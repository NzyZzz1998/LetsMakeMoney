from __future__ import annotations

import re
import sys
from pathlib import Path


APP_ROOT = Path(__file__).resolve().parents[1]
SRC = APP_ROOT / "src"
RUST_ROOT = APP_ROOT / "src-tauri"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def source(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def verify_targeted_combobox() -> None:
    app = source(SRC / "App.tsx")
    component = source(SRC / "components" / "AccessibleCombobox.tsx")
    css = source(SRC / "styles.css")
    require(app.count("<AccessibleCombobox") == 2, "Only the two approved Settings controls may use the custom Combobox")
    require("<select" not in app, "The two production native select controls must be fully replaced")
    for token in (
        'role="combobox"',
        'role="listbox"',
        'role="option"',
        "aria-expanded",
        "aria-selected",
        "aria-invalid",
        'document.addEventListener("pointerdown"',
        'window.addEventListener("resize"',
        "shouldComboboxOpenUp",
    ):
        require(token in component, f"Combobox accessibility contract is missing {token}")
    for key in ("ArrowDown", "ArrowUp", "Home", "End", "Enter", "Escape", "Tab"):
        require(key in source(SRC / "components" / "comboboxModel.ts"), f"Combobox key contract is missing {key}")
    for selector in (".accessible-combobox__trigger", ".accessible-combobox__listbox", ".accessible-combobox.opens-up"):
        require(selector in css, f"Combobox visual contract is missing {selector}")


def verify_single_surface_owner() -> None:
    frame = source(SRC / "components" / "WindowFrame.tsx")
    mini = source(SRC / "features" / "mini" / "MiniWindow.tsx")
    contract = source(SRC / "components" / "windowSurfaceContract.ts")
    css = source(SRC / "styles.css")
    tauri = source(RUST_ROOT / "tauri.conf.json")
    rust = source(RUST_ROOT / "src" / "lib.rs")
    require("WINDOW_SURFACE_ATTRIBUTES" in frame and "WINDOW_SURFACE_ATTRIBUTES" in mini, "All four app windows must use one surface contract")
    require('"data-shadow-owner": "none"' in contract, "Disabled external shadow ownership must be explicit")
    require('"data-surface-owner": "web-content"' in contract, "Web surface ownership must be explicit")
    require(re.search(r"\.window-frame\s*\{\s*box-shadow:\s*none;", css) is not None, "WindowFrame must not draw a second shadow")
    require(re.search(r"\.mini-window\s*\{\s*box-shadow:\s*none;", css) is not None, "Mini must not draw a second shadow")
    require('"shadow": false' in tauri and ".shadow(false)" in rust, "Native shadows must not draw a second outer arc")
    require("native-shadow" in contract and "opaque-outer" in contract, "Rejected surface samples must remain documented and testable")


def verify_behavior_assets() -> None:
    for name in ("combobox.behavior.ts", "window-surface.behavior.ts"):
        require((APP_ROOT / "tests" / name).is_file(), f"Missing M5 behavior suite: {name}")


def verify_time_fields() -> None:
    app = source(SRC / "App.tsx")
    component = source(SRC / "components" / "TimeField.tsx")
    css = source(SRC / "styles.css")
    require('type="time"' not in app, "Native square time controls must not remain in production UI")
    require(app.count("<TimeField") == 7, "Every approved Wizard and Settings time field must use TimeField")
    for token in ('role="dialog"', 'role="listbox"', 'role="option"', "aria-selected", "Escape", "scrollIntoView"):
        require(token in component, f"TimeField accessibility contract is missing {token}")
    require('className="time-field__control"' in component, "TimeField popup must anchor to the control rather than the labelled field")
    for selector in (".time-field__control", ".time-field__trigger", ".time-field__popover", ".time-field.opens-up"):
        require(selector in css, f"TimeField visual contract is missing {selector}")
    require("top: calc(100% - 1px)" in css and "bottom: calc(100% - 1px)" in css, "TimeField popup must visually connect to its trigger")


def verify_privacy_tab_readability() -> None:
    css = source(SRC / "styles.css")
    platform = source(RUST_ROOT / "src" / "platform.rs")
    fixture = source(APP_ROOT / "tests" / "fixtures" / "v107-mini-edge-geometry.json")
    require("width: 40px" in css, "Privacy tab web surface must expose the readable width")
    require("MINI_EDGE_PRIVACY_TAB_LOGICAL_PX: i32 = 40" in platform, "Native privacy width must match the web surface")
    require('"privacy_tab_logical_px": 40' in fixture, "DPI fixture must lock the readable privacy width")
    require("white-space: nowrap" in css and "word-break: keep-all" in css, "Privacy tab copy must stay in one vertical line")


def verify_window_mark_candidate() -> None:
    frame = source(SRC / "components" / "WindowFrame.tsx")
    mark = source(SRC / "components" / "AppMark.tsx")
    css = source(SRC / "styles.css")
    brand = source(APP_ROOT / "brand" / "app-icon-l2.svg")
    require("<AppMark />" in frame, "Every branded WindowFrame must use the shared app mark")
    require('data-app-mark="l2-oat-graphite"' in mark, "Approved L2 app mark identity is missing")
    for color in ("#EEE9DF", "#30302B", "#D89B26", "#778B7B"):
        require(color in mark and color in brand, f"Approved L2 palette drifted: {color}")
    require("BadgeJapaneseYen" not in mark, "Legacy yen placeholder must not return")
    require(".app-mark" in css and ".coin-mark" not in css, "Legacy text coin mark must be replaced")


def verify_brand_icon_assets() -> None:
    ico = RUST_ROOT / "icons" / "icon.ico"
    png = RUST_ROOT / "icons" / "icon.png"
    generator = source(APP_ROOT / "scripts" / "generate_brand_icon.ps1")
    ico_bytes = ico.read_bytes()
    png_bytes = png.read_bytes()
    require(ico_bytes[:4] == b"\x00\x00\x01\x00", "Windows brand asset must be a valid ICO container")
    require(int.from_bytes(ico_bytes[4:6], "little") == 9, "Windows ICO must contain the nine approved sizes")
    require(png_bytes[:8] == b"\x89PNG\r\n\x1a\n", "Brand PNG must have a valid PNG signature")
    require(len(ico_bytes) > 8_000 and len(png_bytes) > 4_000, "Brand assets must not be blank placeholders")
    require("16, 20, 24, 32, 40, 48, 64, 128, 256" in generator, "Generator must retain the approved ICO size set")
    require("generate_brand_icon.ps1" in source(APP_ROOT / "scripts" / "generate_placeholder_icon.ps1"), "Legacy generator entry must delegate to the approved brand generator")


def main() -> int:
    checks = [verify_targeted_combobox, verify_single_surface_owner, verify_behavior_assets, verify_time_fields, verify_privacy_tab_readability, verify_window_mark_candidate, verify_brand_icon_assets]
    try:
        for check in checks:
            check()
            print(f"PASS {check.__name__}")
    except (AssertionError, OSError, TypeError, ValueError) as error:
        print(f"FAIL {error}", file=sys.stderr)
        return 1
    print(f"PASS v1.0.7 M5 static contracts ({len(checks)} groups)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
