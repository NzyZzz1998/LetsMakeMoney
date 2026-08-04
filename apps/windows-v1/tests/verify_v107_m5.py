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
    require('"data-shadow-owner": "native-window"' in contract, "Native shadow ownership must be explicit")
    require('"data-surface-owner": "web-content"' in contract, "Web surface ownership must be explicit")
    require(re.search(r"\.window-frame\s*\{\s*box-shadow:\s*none;", css) is not None, "WindowFrame must not draw a second shadow")
    require(re.search(r"\.mini-window\s*\{\s*box-shadow:\s*none;", css) is not None, "Mini must not draw a second shadow")
    require('"shadow": true' in tauri and ".shadow(true)" in rust, "Native windows must retain the accepted shadow owner")
    require("web-shadow" in contract and "opaque-outer" in contract, "Rejected surface samples must remain documented and testable")


def verify_behavior_assets() -> None:
    for name in ("combobox.behavior.ts", "window-surface.behavior.ts"):
        require((APP_ROOT / "tests" / name).is_file(), f"Missing M5 behavior suite: {name}")


def main() -> int:
    checks = [verify_targeted_combobox, verify_single_surface_owner, verify_behavior_assets]
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
