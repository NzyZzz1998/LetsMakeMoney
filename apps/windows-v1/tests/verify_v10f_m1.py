from __future__ import annotations

import hashlib
import json
import re
import struct
import sys
from pathlib import Path


APP_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = APP_ROOT.parents[1]
EXPECTED_VERSION = "1.0.8"
EXPECTED_ICO_SIZES = [16, 20, 24, 32, 40, 48, 64, 128, 256]


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def load_json(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        value = json.load(handle)
    require(isinstance(value, dict), f"{path.name} must contain an object")
    return value


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def parse_ico_sizes(path: Path) -> list[int]:
    data = path.read_bytes()
    require(len(data) >= 6, "ICO header is truncated")
    reserved, icon_type, count = struct.unpack_from("<HHH", data, 0)
    require((reserved, icon_type) == (0, 1), "ICO header identity is invalid")
    require(len(data) >= 6 + count * 16, "ICO directory is truncated")
    result: list[int] = []
    for index in range(count):
        width, height = struct.unpack_from("BB", data, 6 + index * 16)
        require(width == height, "ICO entry is not square")
        result.append(256 if width == 0 else width)
    return result


def verify_versions() -> None:
    package = load_json(APP_ROOT / "package.json")
    lock = load_json(APP_ROOT / "package-lock.json")
    tauri = load_json(APP_ROOT / "src-tauri" / "tauri.conf.json")
    manifest = load_json(REPO_ROOT / "scripts" / "current-manifest.json")
    require(package.get("version") == EXPECTED_VERSION, "package version drift")
    require(lock.get("version") == EXPECTED_VERSION, "package-lock root version drift")
    require(lock.get("packages", {}).get("", {}).get("version") == EXPECTED_VERSION, "package-lock app version drift")
    require(tauri.get("version") == EXPECTED_VERSION, "Tauri version drift")
    require(manifest.get("version") == EXPECTED_VERSION, "current manifest version drift")
    require(manifest.get("artifacts", {}).get("zip_name") == "LetsMakeMoney-v1.0.8-windows-x86_64.zip", "candidate filename drift")

    cargo = (APP_ROOT / "src-tauri" / "Cargo.toml").read_text(encoding="utf-8")
    cargo_lock = (APP_ROOT / "src-tauri" / "Cargo.lock").read_text(encoding="utf-8")
    require(re.search(r'^version = "1\.0\.8"$', cargo, re.MULTILINE) is not None, "Cargo version drift")
    package_entry = re.search(r'name = "letsmakemoney_windows_v1"\nversion = "([^"]+)"', cargo_lock)
    require(package_entry is not None and package_entry.group(1) == EXPECTED_VERSION, "Cargo.lock app version drift")


def verify_brand() -> None:
    brand = APP_ROOT / "brand"
    svg = brand / "app-icon-l2.svg"
    png = APP_ROOT / "src-tauri" / "icons" / "icon.png"
    ico = APP_ROOT / "src-tauri" / "icons" / "icon.ico"
    app_mark = (APP_ROOT / "src" / "components" / "AppMark.tsx").read_text(encoding="utf-8")
    source = svg.read_text(encoding="utf-8")
    for token in ("#EEE9DF", "#30302B", "#778B7B", "#D89B26"):
        require(token in source, f"SVG is missing brand token {token}")
        require(token in app_mark, f"React mark is missing brand token {token}")
    require(png.read_bytes()[:8] == b"\x89PNG\r\n\x1a\n", "brand PNG signature is invalid")
    width, height = struct.unpack(">II", png.read_bytes()[16:24])
    require((width, height) == (512, 512), "brand PNG must be 512x512")
    require(parse_ico_sizes(ico) == EXPECTED_ICO_SIZES, "ICO size directory drift")

    identity = load_json(brand / "brand-assets.json")
    require(identity.get("brand") == "L2-oat-graphite", "brand identity drift")
    require(identity.get("source") == "apps/windows-v1/brand/app-icon-l2.svg", "brand source path drift")
    assets = identity.get("assets", {})
    require(assets.get("icon.png", {}).get("sha256") == sha256(png), "brand PNG hash drift")
    require(assets.get("icon.ico", {}).get("sha256") == sha256(ico), "brand ICO hash drift")
    require(assets.get("icon.ico", {}).get("sizes") == EXPECTED_ICO_SIZES, "brand ICO size contract drift")


def verify_current_boundary() -> None:
    current = (REPO_ROOT / "doc" / "current.md").read_text(encoding="utf-8")
    require("当前公开版本 | Windows v1.0.7 Stable" in current, "published v1.0.7 fact was overwritten")
    require("当前开发版本 | v1.0.F（公开版本固定为 v1.0.8）" in current, "v1.0.8 development identity is missing")
    require("不可发布" in current, "development status must not claim release readiness")


def main() -> int:
    verify_versions()
    verify_brand()
    verify_current_boundary()
    print("PASS v1.0.F M1 version, candidate and brand contracts (3 groups)")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (AssertionError, OSError, ValueError, json.JSONDecodeError) as error:
        print(f"FAIL v1.0.F M1: {error}", file=sys.stderr)
        raise SystemExit(1)
