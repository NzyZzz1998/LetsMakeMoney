from __future__ import annotations

import argparse
import json
import re
import sys
import zipfile
from pathlib import Path


APP = Path(__file__).resolve().parents[1]
ROOT = APP.parents[1]
FAILURES: list[str] = []


def check(condition: bool, message: str) -> None:
    if not condition:
        FAILURES.append(message)


def production_rust(text: str) -> str:
    return text.split("#[cfg(test)]", 1)[0]


def check_source_tree() -> None:
    retired_paths = [
        "src",
        "native",
        "assets/pets",
        "icons",
        "project.godot",
        "export_presets.cfg",
        "installer",
        "third_party",
        "licenses",
    ]
    for relative in retired_paths:
        check(not (ROOT / relative).exists(), f"旧主线仍存在：{relative}")

    scripts = sorted(path.name for path in (ROOT / "scripts").glob("*") if path.is_file())
    check(bool(scripts), "根目录没有 v1.0 验证脚本")
    unexpected_scripts = [
        name
        for name in scripts
        if not (
            name.startswith("verify_v10")
            or name in {"package_v10.ps1", "package_v101.ps1", "v10_tools.ps1"}
        )
    ]
    check(
        not unexpected_scripts,
        f"根目录仍有旧版本脚本：{unexpected_scripts}",
    )

    production_files = list((APP / "src").rglob("*"))
    production_files += list((APP / "src-tauri" / "src").glob("*.rs"))
    forbidden = re.compile(
        r"(?i)(\bpet(?:_|-|\b)|pure_pet|click_through|desktop\s+pet|桌宠|宠物)"
    )
    for path in production_files:
        if not path.is_file() or path.suffix not in {".ts", ".tsx", ".css", ".rs", ".json"}:
            continue
        text = path.read_text(encoding="utf-8")
        if path.suffix == ".rs":
            text = production_rust(text)
        match = forbidden.search(text)
        check(match is None, f"v1.0 生产代码出现宠物能力：{path.relative_to(ROOT)}")

    config_text = (APP / "src-tauri" / "src" / "config.rs").read_text(encoding="utf-8")
    fixture = json.loads(
        (APP / "tests" / "fixtures" / "migration-fixtures.json").read_text(encoding="utf-8")
    )
    retired_keys = {
        "pet_id",
        "pet_package_id",
        "pet_package_version",
        "pure_pet_mode",
        "pet_scale",
        "click_through",
    }
    removed = set(fixture["cases"][0]["expected_removed"])
    check(retired_keys <= removed, "迁移 fixture 未覆盖全部退役宠物字段")
    for key in retired_keys:
        check(key in config_text, f"Rust 迁移测试未明确覆盖退役字段：{key}")

    readme = (ROOT / "README.md").read_text(encoding="utf-8")
    check("Rust" in readme and "Tauri" in readme and "React" in readme, "README 未声明 v1 技术主线")
    check("v0.9-beta" in readme and "无宠物" in readme, "README 未声明无宠物边界或历史恢复入口")
    check(
        (ROOT / "doc" / "releases" / "v1.0" / "v0.9-rollback.md").exists(),
        "缺少 v0.9 回退说明",
    )
    icon = APP / "src-tauri" / "icons" / "icon.ico"
    check(icon.exists() and icon.stat().st_size > 1000, "v1.0 无宠物图标缺失或为空")


def check_package(path: Path) -> None:
    check(path.exists(), f"候选 Zip 不存在：{path}")
    if not path.exists():
        return
    forbidden_fragments = (
        "assets/pets",
        "pet-package",
        "spritesheet",
        "extra-actions",
        ".pck",
        ".gd",
        ".tscn",
        "project.godot",
        "letsmakemoney_native",
    )
    with zipfile.ZipFile(path) as archive:
        names = [name.replace("\\", "/").lower() for name in archive.namelist()]
    for name in names:
        check(
            not any(fragment in name for fragment in forbidden_fragments),
            f"候选 Zip 含旧宠物或 Godot 载荷：{name}",
        )
    check(any(name.endswith("letsmakemoney.exe") for name in names), "候选 Zip 缺少 EXE")
    check(any(name.endswith("readme.md") for name in names), "候选 Zip 缺少 README")
    check(any(name.endswith("license") or name.endswith("license.md") for name in names), "候选 Zip 缺少 LICENSE")


def main() -> int:
    parser = argparse.ArgumentParser(description="LetsMakeMoney v1.0 M6 zero-pet verifier")
    parser.add_argument("--package", type=Path)
    args = parser.parse_args()
    check_source_tree()
    if args.package:
        check_package(args.package.resolve())
    if FAILURES:
        print(f"M6 验证失败：{len(FAILURES)} 项")
        for failure in FAILURES:
            print(f"- {failure}")
        return 1
    print("M6 验证通过")
    print("- v1.0 活跃源码、运行时与旧构建链已隔离")
    print("- 旧宠物字段迁移覆盖完整")
    print("- README、图标与 v0.9 回退入口完整")
    if args.package:
        print("- 候选 Zip 宠物与 Godot 载荷数量为 0")
    return 0


if __name__ == "__main__":
    sys.exit(main())
