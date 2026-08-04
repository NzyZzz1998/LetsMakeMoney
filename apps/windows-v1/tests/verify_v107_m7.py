from __future__ import annotations

import hashlib
import json
import sys
import tempfile
import zipfile
from pathlib import Path


APP_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = APP_ROOT.parents[1]
TEST_ROOT = APP_ROOT / "tests"
SCRIPTS = REPO_ROOT / "scripts"
RELEASE = REPO_ROOT / "doc" / "releases" / "v1.0.7"
sys.path.insert(0, str(TEST_ROOT))

import verify_v105_package as base  # noqa: E402
import verify_v107_package as v107_package  # noqa: E402


VERSION = "1.0.7"
SOURCE_HEAD = "a" * 40
PLATFORM = "windows-x86_64"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def sha(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest().upper()


def make_package(
    directory: Path,
    *,
    dirty: bool,
    omit: str | None = None,
    extra: tuple[str, bytes] | None = None,
    readme: bytes = b"LetsMakeMoney portable user guide",
) -> Path:
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
        "LetsMakeMoney.exe": b"MZ-v107-test-exe",
        "WebView2Loader.dll": b"MZ-v107-test-loader",
        "README.md": readme,
        "README.en.md": b"LetsMakeMoney portable guide",
        "LICENSE": b"MIT",
        "THIRD_PARTY_NOTICES.md": b"Third party notices",
        "ASSETS_LICENSE.md": b"Asset license",
        "ASSETS_MANIFEST.md": b"Asset manifest",
        "CHANGELOG.md": b"v1.0.7",
        "calendar-data/manifest.json": calendar_manifest,
        "calendar-data/cn-2026.json": calendar_data,
    }
    if omit is not None:
        payload.pop(omit)
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
        "build_timestamp_utc": "2026-08-03T00:00:00Z",
        "executable_sha256": sha(payload["LetsMakeMoney.exe"]),
        "webview2_loader_sha256": sha(payload["WebView2Loader.dll"]),
        "documentation": {
            "readme_sha256": sha(payload.get("README.md", b"missing")),
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


def candidate_expectation(**overrides: object) -> base.IdentityExpectation:
    values: dict[str, object] = {
        "mode": "candidate",
        "version": VERSION,
        "platform": PLATFORM,
        "architecture": "x86_64",
        "source_head": SOURCE_HEAD,
    }
    values.update(overrides)
    return base.IdentityExpectation(**values)  # type: ignore[arg-type]


def expect_failure(callback, expected: str) -> None:
    try:
        callback()
    except base.IdentityError as error:
        require(expected in str(error), f"Unexpected failure: {error}")
        return
    raise AssertionError(f"Negative fixture unexpectedly passed: {expected}")


def verify_version_and_release_entrypoints() -> None:
    package = json.loads((APP_ROOT / "package.json").read_text(encoding="utf-8"))
    tauri = json.loads((APP_ROOT / "src-tauri" / "tauri.conf.json").read_text(encoding="utf-8"))
    cargo = (APP_ROOT / "src-tauri" / "Cargo.toml").read_text(encoding="utf-8")
    require(package["version"] == VERSION, "npm version identity drift")
    require(tauri["version"] == VERSION, "Tauri version identity drift")
    require('version = "1.0.7"' in cargo, "Cargo version identity drift")
    for name in ("package_v107.ps1", "verify_v107.ps1", "verify_v107_package.ps1"):
        require((SCRIPTS / name).is_file(), f"Missing v1.0.7 release entry: {name}")


def verify_candidate_and_published_negative_fixtures() -> None:
    with tempfile.TemporaryDirectory(prefix="lmm-v107-package-tests-") as raw:
        root = Path(raw)
        candidate = make_package(root, dirty=True)
        result = base.validate_package(candidate, candidate_expectation())
        v107_package.validate_v107_payload(candidate, VERSION, PLATFORM)
        require(result["source_tree_dirty"] is True, "Candidate dirty identity was lost")

        expect_failure(
            lambda: base.validate_package(candidate, candidate_expectation(source_head="b" * 40)),
            "source_head mismatch",
        )

        missing = make_package(root / "missing", dirty=True, omit="README.md")
        expect_failure(
            lambda: base.validate_package(missing, candidate_expectation()),
            "required files are missing",
        )

        extra = make_package(root / "extra", dirty=True, extra=("debug.log", b"private"))
        base.validate_package(extra, candidate_expectation())
        expect_failure(
            lambda: v107_package.validate_v107_payload(extra, VERSION, PLATFORM),
            "unregistered files",
        )

        leaked = make_package(root / "leaked", dirty=True, readme=b"C:\\Users\\private\\file")
        base.validate_package(leaked, candidate_expectation())
        expect_failure(
            lambda: v107_package.validate_v107_payload(leaked, VERSION, PLATFORM),
            "absolute path",
        )

        urls = make_package(
            root / "urls",
            dirty=True,
            readme=b"https://github.com/NzyZzz1998/LetsMakeMoney/releases",
        )
        base.validate_package(urls, candidate_expectation())
        v107_package.validate_v107_payload(urls, VERSION, PLATFORM)

        published = candidate_expectation(
            mode="published",
            expected_zip_sha256=base.sha256(candidate),
            tag="v1.0.7",
            tag_target_commit=SOURCE_HEAD,
            release_url="https://github.com/NzyZzz1998/LetsMakeMoney/releases/tag/v1.0.7",
            checksums_path=root / "SHA256SUMS.txt",
        )
        (root / "SHA256SUMS.txt").write_text(
            f"{base.sha256(candidate)}  {candidate.name}\n", encoding="ascii"
        )
        expect_failure(
            lambda: base.validate_package(candidate, published),
            "clean source tree",
        )

        clean = make_package(root / "clean", dirty=False)
        clean_hash = base.sha256(clean)
        clean_sums = root / "clean-SHA256SUMS.txt"
        clean_sums.write_text(f"{clean_hash}  {clean.name}\n", encoding="ascii")
        clean_published = candidate_expectation(
            mode="published",
            expected_zip_sha256=clean_hash,
            tag="v1.0.7",
            tag_target_commit=SOURCE_HEAD,
            release_url="https://github.com/NzyZzz1998/LetsMakeMoney/releases/tag/v1.0.7",
            checksums_path=clean_sums,
        )
        base.validate_package(clean, clean_published)
        v107_package.validate_v107_payload(clean, VERSION, PLATFORM)

        wrong_hash = candidate_expectation(expected_zip_sha256="0" * 64)
        expect_failure(
            lambda: base.validate_package(clean, wrong_hash),
            "locked identity",
        )


def verify_release_document_skeleton() -> None:
    for name in (
        "README.md",
        "manual-verification.md",
        "release-checklist.md",
        "release-notes.md",
        "verification.md",
        "progress_v1.0.7.md",
    ):
        require((RELEASE / name).is_file(), f"Missing v1.0.7 release document: {name}")


def main() -> int:
    checks = [
        verify_version_and_release_entrypoints,
        verify_candidate_and_published_negative_fixtures,
        verify_release_document_skeleton,
    ]
    try:
        for check in checks:
            check()
            print(f"PASS {check.__name__}")
    except (AssertionError, base.IdentityError, OSError, ValueError, zipfile.BadZipFile) as error:
        print(f"FAIL {error}", file=sys.stderr)
        return 1
    print(f"PASS v1.0.7 M7 release engineering ({len(checks)} groups)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
