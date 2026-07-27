from __future__ import annotations

import re
import sys
from pathlib import Path


APP = Path(__file__).resolve().parents[1]
ROOT = APP.parents[1]
FAILURES: list[str] = []

ZIP_SHA256 = "A5C33B9DB8787536145AE4B9A1AC00213E692C99A2201CC91EB811A0A0F3BBE6"
EXE_SHA256 = "BD25B13F084A0F101DD77239F215019C0BB9E246847BBD15B2D0BEE98B381C44"
LOADER_SHA256 = "8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C"

DOCUMENTS = [
    ROOT / "README.md",
    ROOT / "README.en.md",
    ROOT / "doc" / "current.md",
    *sorted((ROOT / "doc" / "releases" / "v1.0").glob("*.md")),
]


def fail(message: str) -> None:
    FAILURES.append(message)


def read_utf8(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError) as error:
        fail(f"无法按 UTF-8 读取：{path.relative_to(ROOT)} ({error})")
        return ""


def check_local_links(path: Path, text: str) -> None:
    for target in re.findall(r"!?\[[^\]]*]\(([^)]+)\)", text):
        target = target.strip().strip("<>")
        if (
            not target
            or target.startswith(("#", "http://", "https://", "mailto:"))
            or "://" in target
        ):
            continue
        relative = target.split("#", 1)[0].replace("%20", " ")
        if not relative:
            continue
        resolved = (path.parent / relative).resolve()
        if not resolved.exists():
            fail(
                f"本地链接失效：{path.relative_to(ROOT)} -> {target}"
            )


def check_candidate_identity() -> None:
    identity_docs = [
        ROOT / "doc" / "current.md",
        ROOT / "doc" / "releases" / "v1.0" / "release-notes.md",
        ROOT / "doc" / "releases" / "v1.0" / "verification.md",
    ]
    for path in identity_docs:
        text = read_utf8(path)
        for label, expected in (
            ("Zip", ZIP_SHA256),
            ("EXE", EXE_SHA256),
            ("WebView2Loader", LOADER_SHA256),
        ):
            if expected not in text:
                fail(f"{path.relative_to(ROOT)} 缺少当前 {label} SHA256")


def main() -> int:
    required = {
        ROOT / "doc" / "current.md",
        ROOT / "doc" / "releases" / "v1.0" / "prd.md",
        ROOT / "doc" / "releases" / "v1.0" / "progress_v1.0.md",
        ROOT / "doc" / "releases" / "v1.0" / "verification.md",
        ROOT / "doc" / "releases" / "v1.0" / "manual-verification.md",
        ROOT / "doc" / "releases" / "v1.0" / "release-checklist.md",
        ROOT / "doc" / "releases" / "v1.0" / "release-notes.md",
    }
    for path in required:
        if not path.exists():
            fail(f"缺少 v1.0 事实文档：{path.relative_to(ROOT)}")

    for path in DOCUMENTS:
        text = read_utf8(path)
        if "\ufffd" in text or "锟斤拷" in text:
            fail(f"检测到乱码：{path.relative_to(ROOT)}")
        check_local_links(path, text)

    check_candidate_identity()

    current = read_utf8(ROOT / "doc" / "current.md")
    if "Windows v1.0 Stable 候选" not in current:
        fail("doc/current.md 未声明当前开发版本为 v1.0 Stable 候选")
    if "v0.9-beta" not in current:
        fail("doc/current.md 缺少 v0.9 回退基线")
    if "验收通过" not in current or "干净提交候选已生成" not in current:
        fail("doc/current.md 未声明当前验收通过状态")
    if "多显示器安全回落因当前设备仅有一台显示器，标记为待补证" not in current:
        fail("doc/current.md 未保留多显示器待补证边界")

    if FAILURES:
        print(f"v1.0 文档检查失败：{len(FAILURES)} 项")
        for item in FAILURES:
            print(f"- {item}")
        return 1

    print("v1.0 文档检查通过")
    print(f"- UTF-8 与乱码：{len(DOCUMENTS)} 份文档")
    print("- v1.0 必需事实源与本地链接完整")
    print("- current、release notes、verification 候选哈希一致")
    return 0


if __name__ == "__main__":
    sys.exit(main())
