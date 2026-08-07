from __future__ import annotations

import hashlib
import json
import re
import sys
import tempfile
import zipfile
from pathlib import Path


APP_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = APP_ROOT.parents[1]
TEST_ROOT = APP_ROOT / "tests"
SCRIPTS = REPO_ROOT / "scripts"
RELEASE = REPO_ROOT / "doc" / "releases" / "v1.0.F"
sys.path.insert(0, str(TEST_ROOT))

import verify_v105_package as base  # noqa: E402
import verify_v10f_package as package_audit  # noqa: E402


VERSION = "1.0.8"
SOURCE_HEAD = "a" * 40
PLATFORM = "windows-x86_64"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def sha(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest().upper()


def make_package(directory: Path, *, dirty: bool, extra: tuple[str, bytes] | None = None) -> Path:
    directory.mkdir(parents=True, exist_ok=True)
    root = f"LetsMakeMoney-v{VERSION}-{PLATFORM}"
    calendar_data = json.dumps({"year": 2026, "dates": []}, sort_keys=True).encode()
    calendar_manifest = json.dumps(
        {
            "dataset_version": "test-1",
            "datasets": [{"year": 2026, "file": "cn-2026.json", "sha256": sha(calendar_data)}],
        },
        sort_keys=True,
    ).encode()
    payload: dict[str, bytes] = {
        "LetsMakeMoney.exe": b"MZ-v108-test-exe",
        "WebView2Loader.dll": b"MZ-v108-test-loader",
        "README.md": b"LetsMakeMoney portable user guide",
        "README.en.md": b"LetsMakeMoney portable guide",
        "LICENSE": b"MIT",
        "THIRD_PARTY_NOTICES.md": b"Third party notices",
        "ASSETS_LICENSE.md": b"Asset license",
        "ASSETS_MANIFEST.md": b"Asset manifest",
        "CHANGELOG.md": b"v1.0.8",
        "calendar-data/manifest.json": calendar_manifest,
        "calendar-data/cn-2026.json": calendar_data,
    }
    if extra is not None:
        payload[extra[0]] = extra[1]
    info = {
        "schema_version": "1.0",
        "product": "LetsMakeMoney",
        "version": VERSION,
        "channel": "stable-candidate",
        "platform": PLATFORM,
        "architecture": "x86_64",
        "source_head": SOURCE_HEAD,
        "source_tree_dirty": dirty,
        "build_timestamp_utc": "2026-08-04T00:00:00Z",
        "executable_sha256": sha(payload["LetsMakeMoney.exe"]),
        "webview2_loader_sha256": sha(payload["WebView2Loader.dll"]),
        "documentation": {
            "readme_sha256": sha(payload["README.md"]),
            "readme_en_sha256": sha(payload["README.en.md"]),
            "source": "apps/windows-v1/release-docs",
        },
        "licenses": {
            "license_sha256": sha(payload["LICENSE"]),
            "third_party_notices_sha256": sha(payload["THIRD_PARTY_NOTICES.md"]),
            "assets_license_sha256": sha(payload["ASSETS_LICENSE.md"]),
            "assets_manifest_sha256": sha(payload["ASSETS_MANIFEST.md"]),
        },
        "calendar": {
            "manifest_sha256": sha(calendar_manifest),
            "dataset_version": "test-1",
            "datasets": [{"year": 2026, "file": "cn-2026.json", "sha256": sha(calendar_data)}],
        },
    }
    payload["BUILD-INFO.json"] = json.dumps(info, sort_keys=True).encode()
    package = directory / f"{root}.zip"
    with zipfile.ZipFile(package, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        for relative, value in sorted(payload.items()):
            archive.writestr(f"{root}/{relative}", value)
    return package


def expectation(*, dirty: bool | None = None) -> base.IdentityExpectation:
    del dirty
    return base.IdentityExpectation(
        mode="candidate",
        version=VERSION,
        platform=PLATFORM,
        architecture="x86_64",
        source_head=SOURCE_HEAD,
    )


def verify_version_and_entrypoints() -> None:
    package = json.loads((APP_ROOT / "package.json").read_text(encoding="utf-8"))
    tauri = json.loads((APP_ROOT / "src-tauri" / "tauri.conf.json").read_text(encoding="utf-8"))
    cargo = (APP_ROOT / "src-tauri" / "Cargo.toml").read_text(encoding="utf-8")
    manifest = json.loads((SCRIPTS / "current-manifest.json").read_text(encoding="utf-8"))
    require(package["version"] == VERSION, "npm version identity drift")
    require(tauri["version"] == VERSION, "Tauri version identity drift")
    require(re.search(r'^version = "1\.0\.8"$', cargo, re.MULTILINE) is not None, "Cargo version identity drift")
    require(manifest["version"] == VERSION, "current manifest version drift")
    require(manifest["artifacts"]["build_info_name"] == "BUILD-INFO.json", "BUILD-INFO contract drift")
    for name in ("package_v10f.ps1", "verify_v10f_package.ps1", "verify_v10f_m7.ps1"):
        require((SCRIPTS / name).is_file(), f"missing v1.0.8 release entry: {name}")


def verify_package_fixtures() -> None:
    with tempfile.TemporaryDirectory(prefix="lmm-v108-package-tests-") as raw:
        root = Path(raw)
        candidate = make_package(root, dirty=True)
        result = base.validate_package(candidate, expectation())
        package_audit.validate_payload(candidate, VERSION, PLATFORM)
        require(result["source_tree_dirty"] is True, "candidate dirty identity was lost")

        leaked = make_package(root / "leaked", dirty=True, extra=("debug.log", b"private"))
        base.validate_package(leaked, expectation())
        try:
            package_audit.validate_payload(leaked, VERSION, PLATFORM)
        except base.IdentityError as error:
            require("unregistered files" in str(error), f"unexpected package rejection: {error}")
        else:
            raise AssertionError("private package fixture unexpectedly passed")

        clean = make_package(root / "clean", dirty=False)
        clean_hash = base.sha256(clean)
        checksums = root / "SHA256SUMS.txt"
        checksums.write_text(f"{clean_hash}  {clean.name}\n", encoding="ascii")
        published = base.IdentityExpectation(
            mode="published",
            version=VERSION,
            platform=PLATFORM,
            architecture="x86_64",
            source_head=SOURCE_HEAD,
            expected_zip_sha256=clean_hash,
            tag="v1.0.8",
            tag_target_commit=SOURCE_HEAD,
            release_url="https://github.com/NzyZzz1998/LetsMakeMoney/releases/tag/v1.0.8",
            checksums_path=checksums,
        )
        base.validate_package(clean, published)
        package_audit.validate_payload(clean, VERSION, PLATFORM)


def verify_release_documents() -> None:
    required = {
        "README.md": "开发实现完成",
        "verification.md": "候选身份",
        "manual-verification.md": "100%",
        "release-checklist.md": "干净提交",
        "release-notes.md": "v1.0.8",
        "progress_v1.0.F.md": "M7",
    }
    for name, marker in required.items():
        path = RELEASE / name
        require(path.is_file(), f"missing v1.0.8 release document: {name}")
        text = path.read_text(encoding="utf-8")
        require(marker in text, f"release document lacks required marker: {name}")
        require("\ufffd" not in text, f"release document contains replacement characters: {name}")


def verify_dirty_packaging_blocker_is_documented() -> None:
    progress = (RELEASE / "progress_v1.0.F.md").read_text(encoding="utf-8")
    checklist = (RELEASE / "release-checklist.md").read_text(encoding="utf-8")
    require("当前 dirty 工作区不得生成正式候选" in progress, "dirty candidate boundary missing")
    require("不得从 dirty 工作区发布" in checklist, "dirty publication boundary missing")


def main() -> int:
    checks = [
        verify_version_and_entrypoints,
        verify_package_fixtures,
        verify_release_documents,
        verify_dirty_packaging_blocker_is_documented,
    ]
    try:
        for check in checks:
            check()
            print(f"PASS {check.__name__}")
    except (AssertionError, base.IdentityError, OSError, ValueError, zipfile.BadZipFile) as error:
        print(f"FAIL {error}", file=sys.stderr)
        return 1
    print(f"PASS v1.0.8 M7 release engineering ({len(checks)} groups)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
