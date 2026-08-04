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
V104_ZIP_SHA256 = "C4F28892831891A4266C4D9B12D432CD5C970BB3C9B36A6B8DB21FA2566DE50E"
V104_EXE_SHA256 = "E0C9C603703FC2632619AFBC84F63B1B1D403273CD01D29AA0A308A95243E107"
V104_SOURCE_COMMIT = "4d06dc73dbc5c27d7a97462d8262a553dd97d5b6"
V105_ZIP_SHA256 = "019B706E18E7D57D0B7E6DBFB6300762422B5723A11EB6ACCB601DA438215889"
V105_EXE_SHA256 = "68FA8FC443B12A2BA8BD757F532EC6B90E09E3DA7E1027255267150C4DAEC37A"
V105_SOURCE_COMMIT = "ffc431af3fbf7c3b54bca8aaff44946cc8d6aeaf"
V106_ZIP_SHA256 = "AEE4BC4A41D3839E421138D0B152EA5A8B0FBDC60C5B189EA11790DE4ED8B66A"
V106_EXE_SHA256 = "21EAC751534F4D0787DEC07545F315326E9C5D773F39D65D9F46AA1879518659"
V106_SOURCE_COMMIT = "51e4c08da5260af9b9f4808c4f6d29591319e655"
V107_ZIP_SHA256 = "D656B96973F64632896715ADCBB9CAFEAED4D06D44BA1C098824335AC673E3F2"
V107_EXE_SHA256 = "58F7F64060584FCAF6BABE0720DC3EF61067669D088DC0CCFBF25DA703E45C3C"
V107_SOURCE_COMMIT = "f500ed4e7de28ec68b2a848da6fa2340420b91b2"
LOADER_SHA256 = "8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C"

DOCUMENTS = [
    ROOT / "README.md",
    ROOT / "README.en.md",
    ROOT / "apps" / "windows-v1" / "README.md",
    ROOT / "doc" / "current.md",
    *sorted((ROOT / "doc" / "releases" / "v1.0").glob("*.md")),
    *sorted((ROOT / "doc" / "releases" / "v1.0.1").glob("*.md")),
    *sorted((ROOT / "doc" / "releases" / "v1.0.2").glob("*.md")),
    *sorted((ROOT / "doc" / "releases" / "v1.0.3").glob("*.md")),
    *sorted((ROOT / "doc" / "releases" / "v1.0.4").glob("*.md")),
    *sorted((ROOT / "doc" / "releases" / "v1.0.5").glob("*.md")),
    *sorted((ROOT / "doc" / "releases" / "v1.0.6").glob("*.md")),
    *sorted((ROOT / "doc" / "releases" / "v1.0.7").glob("*.md")),
    ROOT / "doc" / "logs" / "v1.0.6-bugfix-log.md",
    ROOT / "doc" / "logs" / "v1.0.7-bugfix-log.md",
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

    v104_identity_docs = [
        ROOT / "doc" / "releases" / "v1.0.4" / "release-notes.md",
        ROOT / "doc" / "releases" / "v1.0.4" / "verification.md",
    ]
    for path in v104_identity_docs:
        text = read_utf8(path)
        for label, expected in (
            ("Zip", V104_ZIP_SHA256),
            ("EXE", V104_EXE_SHA256),
            ("WebView2Loader", LOADER_SHA256),
            ("发布源码提交", V104_SOURCE_COMMIT),
        ):
            if expected not in text:
                fail(f"{path.relative_to(ROOT)} 缺少 v1.0.4 {label}")

    v105_identity_docs = [
        ROOT / "doc" / "releases" / "v1.0.5" / "release-notes.md",
        ROOT / "doc" / "releases" / "v1.0.5" / "verification.md",
    ]
    for path in v105_identity_docs:
        text = read_utf8(path)
        for label, expected in (
            ("Zip", V105_ZIP_SHA256),
            ("EXE", V105_EXE_SHA256),
            ("WebView2Loader", LOADER_SHA256),
            ("发布源码提交", V105_SOURCE_COMMIT),
        ):
            if expected not in text:
                fail(f"{path.relative_to(ROOT)} 缺少 v1.0.5 {label}")

    v106_identity_docs = [
        ROOT / "doc" / "releases" / "v1.0.6" / "release-notes.md",
        ROOT / "doc" / "releases" / "v1.0.6" / "verification.md",
    ]
    for path in v106_identity_docs:
        text = read_utf8(path)
        for label, expected in (
            ("Zip", V106_ZIP_SHA256),
            ("EXE", V106_EXE_SHA256),
            ("WebView2Loader", LOADER_SHA256),
            ("发布源码提交", V106_SOURCE_COMMIT),
        ):
            if expected not in text:
                fail(f"{path.relative_to(ROOT)} 缺少 v1.0.6 {label}")

    v107_identity_docs = [
        ROOT / "doc" / "releases" / "v1.0.7" / "release-notes.md",
        ROOT / "doc" / "releases" / "v1.0.7" / "verification.md",
    ]
    for path in v107_identity_docs:
        text = read_utf8(path)
        for label, expected in (
            ("Zip", V107_ZIP_SHA256),
            ("EXE", V107_EXE_SHA256),
            ("WebView2Loader", LOADER_SHA256),
            ("发布源码提交", V107_SOURCE_COMMIT),
        ):
            if expected not in text:
                fail(f"{path.relative_to(ROOT)} 缺少 v1.0.7 {label}")


def check_current_readmes() -> None:
    root_zh = read_utf8(ROOT / "README.md")
    root_en = read_utf8(ROOT / "README.en.md")
    app_readme = read_utf8(ROOT / "apps" / "windows-v1" / "README.md")
    release_url = "https://github.com/NzyZzz1998/LetsMakeMoney/releases/tag/v1.0.7"

    for label, text in (("README.md", root_zh), ("README.en.md", root_en)):
        required = (
            "v1.0.7 Stable",
            release_url,
            V107_SOURCE_COMMIT,
            V107_ZIP_SHA256,
            "package_v107.ps1",
            "verify_v107_package.ps1",
            "verify_v107.ps1",
        )
        for marker in required:
            if marker not in text:
                fail(f"{label} missing current release marker: {marker}")
        for stale in ("package_v103.ps1", "verify_v103_package.ps1"):
            if stale in text:
                fail(f"{label} still uses stale default command: {stale}")

    if "当前公开版本为 v1.0.7 Stable" not in app_readme:
        fail("apps/windows-v1/README.md current public version drift")
    if "v1.0.7 Stable；该版本已完成独立验收" not in app_readme:
        fail("apps/windows-v1/README.md current release state drift")
    if "scripts\\verify_windows_current.ps1" not in app_readme:
        fail("apps/windows-v1/README.md missing current aggregate verification command")
    if "scripts\\package_v107.ps1" not in app_readme:
        fail("apps/windows-v1/README.md missing current isolated packaging command")

    for path, text in (
        (ROOT / "README.md", root_zh),
        (ROOT / "README.en.md", root_en),
        (ROOT / "apps" / "windows-v1" / "README.md", app_readme),
    ):
        for script in re.findall(r"scripts[\\/]+([A-Za-z0-9_.-]+\.ps1)", text):
            if not (ROOT / "scripts" / script).is_file():
                fail(f"{path.relative_to(ROOT)} references missing script: {script}")
        if "\ufffd" in text or "锟斤拷" in text:
            fail(f"{path.relative_to(ROOT)} contains replacement or mojibake text")


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
        ROOT / "doc" / "releases" / "v1.0.4" / "prd.md",
        ROOT / "doc" / "releases" / "v1.0.4" / "dev_plan_v1.0.4.md",
        ROOT / "doc" / "releases" / "v1.0.4" / "progress_v1.0.4.md",
        ROOT / "doc" / "releases" / "v1.0.4" / "verification.md",
        ROOT / "doc" / "releases" / "v1.0.4" / "manual-verification.md",
        ROOT / "doc" / "releases" / "v1.0.4" / "release-checklist.md",
        ROOT / "doc" / "releases" / "v1.0.4" / "release-notes.md",
        ROOT / "doc" / "releases" / "v1.0.5" / "README.md",
        ROOT / "doc" / "releases" / "v1.0.5" / "prd.md",
        ROOT / "doc" / "releases" / "v1.0.5" / "dev_plan_v1.0.5.md",
        ROOT / "doc" / "releases" / "v1.0.5" / "progress_v1.0.5.md",
        ROOT / "doc" / "releases" / "v1.0.5" / "verification.md",
        ROOT / "doc" / "releases" / "v1.0.5" / "manual-verification.md",
        ROOT / "doc" / "releases" / "v1.0.5" / "release-checklist.md",
        ROOT / "doc" / "releases" / "v1.0.5" / "release-notes.md",
        ROOT / "doc" / "releases" / "v1.0.5" / "traceability.md",
        ROOT / "doc" / "releases" / "v1.0.6" / "README.md",
        ROOT / "doc" / "releases" / "v1.0.6" / "review.md",
        ROOT / "doc" / "releases" / "v1.0.6" / "issue-pool.md",
        ROOT / "doc" / "releases" / "v1.0.6" / "progress_v1.0.6.md",
        ROOT / "doc" / "releases" / "v1.0.6" / "verification.md",
        ROOT / "doc" / "logs" / "v1.0.6-bugfix-log.md",
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
    check_current_readmes()

    current = read_utf8(ROOT / "doc" / "current.md")
    if "当前公开版本 | Windows v1.0.7 Stable" not in current:
        fail("doc/current.md 未声明当前公开版本为 v1.0.7 Stable")
    if "当前公开 tag | `v1.0.7`" not in current:
        fail("doc/current.md 未声明当前公开 tag 为 v1.0.7")
    if "当前开发版本 | v1.0.7 发布后观察" not in current or "v1.0.7 GitHub Stable Release 已发布并复核" not in current:
        fail("doc/current.md 未声明 v1.0.7 发布后身份与里程碑")
    if "v0.9-beta" not in current:
        fail("doc/current.md 缺少 v0.9 回退基线")
    if "v1.0.7 已从干净源提交构建" not in current:
        fail("doc/current.md 未声明 v1.0.7 GitHub Release 发布事实")
    if V107_SOURCE_COMMIT not in current:
        fail("doc/current.md 未声明 v1.0.7 tag 与发布源提交")
    history_links = (
        "releases/v1.0/README.md",
        "releases/v1.0.1/README.md",
        "releases/v1.0.2/README.md",
        "releases/v1.0.3/release-notes.md",
        "releases/v1.0.4/release-notes.md",
        "releases/v1.0.5/README.md",
        "releases/v1.0.6/README.md",
        "releases/v1.0.7/README.md",
    )
    if any(link not in current for link in history_links):
        fail("doc/current.md 历史事实入口不完整")
    if len(current.splitlines()) > 100:
        fail("doc/current.md 重新膨胀为历史事实复述")
    if "多显示器：项目所有者确认暂不验证" not in current:
        fail("doc/current.md 未保留多显示器待补证边界")

    if FAILURES:
        print(f"v1.0 文档检查失败：{len(FAILURES)} 项")
        for item in FAILURES:
            print(f"- {item}")
        return 1

    print("v1.0 至 v1.0.7 当前与历史文档检查通过")
    print(f"- UTF-8 与乱码：{len(DOCUMENTS)} 份文档")
    print("- v1.0 至 v1.0.7 发布事实源及本地链接完整")
    print("- current 保持精简入口，历史事实由对应 release 文档承接")
    return 0


if __name__ == "__main__":
    sys.exit(main())
