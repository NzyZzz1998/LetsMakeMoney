from __future__ import annotations

import re
import sys
from pathlib import Path


APP = Path(__file__).resolve().parents[1]
ROOT = APP.parents[1]
FAILURES: list[str] = []

V10_ZIP_SHA256 = "A5C33B9DB8787536145AE4B9A1AC00213E692C99A2201CC91EB811A0A0F3BBE6"
V10_EXE_SHA256 = "BD25B13F084A0F101DD77239F215019C0BB9E246847BBD15B2D0BEE98B381C44"
V101_ZIP_SHA256 = "DB45332F908669445B34FF40C490936B0EEAC0B41DC2FCDC2F5806924E5D1AC2"
V101_EXE_SHA256 = "C71B378E55B455BB71FA356837039DC7BBC2DA2695371AE027BA21D715FE7694"
V102_ZIP_SHA256 = "EEBA1788A8C1D6AEB071728B78C71C3634062B3F5BD6E61BDB46DD171C97FEA2"
V102_EXE_SHA256 = "4057E2F9F94B801A1A0A6C3D6F7B7AFE14DED2049478BF37AE6BBF17E33AD3BA"
V102_SOURCE_COMMIT = "fe074439521bda77c57e2e96f8065dad329a8686"
V103_ZIP_SHA256 = "259CAE23D785FC7712CAC0EFD42991C8EE210C0BCEA1EB5C07FC171DFB993B28"
V103_EXE_SHA256 = "41BB11FCBC95C3789AD283D0F85E67DB0E17D4BC769B133B317FDB1804607237"
V103_SOURCE_COMMIT = "87f6766a33fd6ff284f0fb3a42dc18c5a7292bf4"
LOADER_SHA256 = "8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C"

DOCUMENTS = [
    ROOT / "README.md",
    ROOT / "README.en.md",
    ROOT / "doc" / "current.md",
    *sorted((ROOT / "doc" / "releases" / "v1.0").glob("*.md")),
    *sorted((ROOT / "doc" / "releases" / "v1.0.1").glob("*.md")),
    *sorted((ROOT / "doc" / "releases" / "v1.0.2").glob("*.md")),
    *sorted((ROOT / "doc" / "releases" / "v1.0.3").glob("*.md")),
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


def check_release_identity() -> None:
    v10_identity_docs = [
        ROOT / "doc" / "releases" / "v1.0" / "release-notes.md",
        ROOT / "doc" / "releases" / "v1.0" / "verification.md",
    ]
    for path in v10_identity_docs:
        text = read_utf8(path)
        for label, expected in (
            ("Zip", V10_ZIP_SHA256),
            ("EXE", V10_EXE_SHA256),
            ("WebView2Loader", LOADER_SHA256),
        ):
            if expected not in text:
                fail(f"{path.relative_to(ROOT)} 缺少 v1.0 {label} SHA256")

    v101_identity_docs = [
        ROOT / "doc" / "current.md",
        ROOT / "doc" / "releases" / "v1.0.1" / "release-notes.md",
        ROOT / "doc" / "releases" / "v1.0.1" / "verification.md",
    ]
    for path in v101_identity_docs:
        text = read_utf8(path)
        for label, expected in (
            ("Zip", V101_ZIP_SHA256),
            ("EXE", V101_EXE_SHA256),
            ("WebView2Loader", LOADER_SHA256),
        ):
            if expected not in text:
                fail(f"{path.relative_to(ROOT)} 缺少 v1.0.1 {label} SHA256")

    v102_identity_docs = [
        ROOT / "doc" / "current.md",
        ROOT / "doc" / "releases" / "v1.0.2" / "release-notes.md",
        ROOT / "doc" / "releases" / "v1.0.2" / "verification.md",
    ]
    for path in v102_identity_docs:
        text = read_utf8(path)
        for label, expected in (
            ("Zip", V102_ZIP_SHA256),
            ("EXE", V102_EXE_SHA256),
            ("WebView2Loader", LOADER_SHA256),
            ("发布源码提交", V102_SOURCE_COMMIT),
        ):
            if expected not in text:
                fail(f"{path.relative_to(ROOT)} 缺少 v1.0.2 {label}")

    v103_identity_docs = [
        ROOT / "doc" / "current.md",
        ROOT / "doc" / "releases" / "v1.0.3" / "release-notes.md",
        ROOT / "doc" / "releases" / "v1.0.3" / "verification.md",
    ]
    for path in v103_identity_docs:
        text = read_utf8(path)
        for label, expected in (
            ("Zip", V103_ZIP_SHA256),
            ("EXE", V103_EXE_SHA256),
            ("WebView2Loader", LOADER_SHA256),
            ("发布源码提交", V103_SOURCE_COMMIT),
        ):
            if expected not in text:
                fail(f"{path.relative_to(ROOT)} 缺少 v1.0.3 {label}")


def main() -> int:
    required = {
        ROOT / "doc" / "current.md",
        ROOT / "doc" / "releases" / "v1.0" / "prd.md",
        ROOT / "doc" / "releases" / "v1.0" / "progress_v1.0.md",
        ROOT / "doc" / "releases" / "v1.0" / "verification.md",
        ROOT / "doc" / "releases" / "v1.0" / "manual-verification.md",
        ROOT / "doc" / "releases" / "v1.0" / "release-checklist.md",
        ROOT / "doc" / "releases" / "v1.0" / "release-notes.md",
        ROOT / "doc" / "releases" / "v1.0.1" / "prd.md",
        ROOT / "doc" / "releases" / "v1.0.1" / "progress_v1.0.1.md",
        ROOT / "doc" / "releases" / "v1.0.1" / "verification.md",
        ROOT / "doc" / "releases" / "v1.0.1" / "manual-verification.md",
        ROOT / "doc" / "releases" / "v1.0.1" / "release-checklist.md",
        ROOT / "doc" / "releases" / "v1.0.1" / "release-notes.md",
        ROOT / "doc" / "releases" / "v1.0.2" / "README.md",
        ROOT / "doc" / "releases" / "v1.0.2" / "prd.md",
        ROOT / "doc" / "releases" / "v1.0.2" / "dev_plan_v1.0.2.md",
        ROOT / "doc" / "releases" / "v1.0.2" / "progress_v1.0.2.md",
        ROOT / "doc" / "releases" / "v1.0.2" / "verification.md",
        ROOT / "doc" / "releases" / "v1.0.2" / "manual-verification.md",
        ROOT / "doc" / "releases" / "v1.0.2" / "release-checklist.md",
        ROOT / "doc" / "releases" / "v1.0.2" / "release-notes.md",
        ROOT / "doc" / "releases" / "v1.0.3" / "prd.md",
        ROOT / "doc" / "releases" / "v1.0.3" / "dev_plan_v1.0.3.md",
        ROOT / "doc" / "releases" / "v1.0.3" / "progress_v1.0.3.md",
        ROOT / "doc" / "releases" / "v1.0.3" / "verification.md",
        ROOT / "doc" / "releases" / "v1.0.3" / "manual-verification.md",
        ROOT / "doc" / "releases" / "v1.0.3" / "release-checklist.md",
        ROOT / "doc" / "releases" / "v1.0.3" / "release-notes.md",
    }
    for path in required:
        if not path.exists():
            fail(f"缺少正式版本事实文档：{path.relative_to(ROOT)}")

    for path in DOCUMENTS:
        text = read_utf8(path)
        if "\ufffd" in text or "锟斤拷" in text:
            fail(f"检测到乱码：{path.relative_to(ROOT)}")
        check_local_links(path, text)

    check_release_identity()

    current = read_utf8(ROOT / "doc" / "current.md")
    if "当前公开版本 | Windows v1.0.3 Stable" not in current:
        fail("doc/current.md 未声明当前公开版本为 v1.0.3 Stable")
    if "当前公开 tag | `v1.0.3`" not in current:
        fail("doc/current.md 未声明当前公开 tag 为 v1.0.3")
    if "v0.9-beta" not in current:
        fail("doc/current.md 缺少 v0.9 回退基线")
    if "已通过并发布" not in current or "v1.0` tag 指向发布提交" not in current:
        fail("doc/current.md 未声明 v1.0 已通过并发布")
    if "`main`、`v1.0.1` tag 与 GitHub Release 已完成" not in current:
        fail("doc/current.md 未声明 v1.0.1 已完成发布")
    if "`v1.0.2` annotated tag 与 GitHub Stable Release 已发布" not in current:
        fail("doc/current.md 未声明 v1.0.2 已完成发布")
    if "`v1.0.3` annotated tag 指向上述发布源提交" not in current:
        fail("doc/current.md 未声明 v1.0.3 已完成发布")
    if "多显示器安全回落因当前设备仅有一台显示器，标记为待补证" not in current:
        fail("doc/current.md 未保留多显示器待补证边界")

    if FAILURES:
        print(f"v1.0 文档检查失败：{len(FAILURES)} 项")
        for item in FAILURES:
            print(f"- {item}")
        return 1

    print("v1.0/v1.0.1/v1.0.2/v1.0.3 文档检查通过")
    print(f"- UTF-8 与乱码：{len(DOCUMENTS)} 份文档")
    print("- v1.0、v1.0.1、v1.0.2 与 v1.0.3 必需事实源及本地链接完整")
    print("- current、release notes、verification 的历史与当前发布哈希一致")
    return 0


if __name__ == "__main__":
    sys.exit(main())
