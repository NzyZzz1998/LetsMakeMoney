from __future__ import annotations

import copy
import hashlib
import json
import tempfile
import zipfile
from pathlib import Path
from typing import Any, Callable

import verify_v105_package as verifier


VERSION = "1.0.5"
PLATFORM = "windows-x86_64"
ARCHITECTURE = "x86_64"
SOURCE_HEAD = "a" * 40
TAG = "v1.0.5"
RELEASE_URL = "https://github.com/NzyZzz1998/LetsMakeMoney/releases/tag/v1.0.5"
ZIP_NAME = f"LetsMakeMoney-v{VERSION}-{PLATFORM}.zip"


def encode_json(value: Any) -> bytes:
    return (json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":")) + "\n").encode(
        "utf-8"
    )


def digest(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest().upper()


def write_deterministic_zip(path: Path, root: str, files: dict[str, bytes]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(path, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for relative in sorted(files):
            info = zipfile.ZipInfo(f"{root}/{relative}", date_time=(2026, 8, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            archive.writestr(info, files[relative])


def make_package(
    artifact_root: Path,
    *,
    mode: verifier.Mode,
    dirty: bool = False,
    candidate_id: str = "candidate-clean",
    build_mutator: Callable[[dict[str, Any]], None] | None = None,
    payload_mutator: Callable[[dict[str, bytes]], None] | None = None,
    wrong_location: bool = False,
) -> Path:
    dataset = encode_json({"year": 2026, "days": []})
    manifest = encode_json(
        {
            "dataset_version": "synthetic-2026.08",
            "datasets": [
                {"year": 2026, "file": "cn-2026.json", "sha256": digest(dataset)}
            ],
        }
    )
    payload = {
        "LetsMakeMoney.exe": b"MZ synthetic v1.0.5 executable",
        "WebView2Loader.dll": b"MZ synthetic WebView2 loader",
        "README.md": "# LetsMakeMoney v1.0.5\n".encode("utf-8"),
        "README.en.md": b"# LetsMakeMoney v1.0.5\n",
        "LICENSE": b"MIT synthetic fixture\n",
        "THIRD_PARTY_NOTICES.md": b"# Third-party notices\n",
        "ASSETS_LICENSE.md": b"# Assets license\n",
        "ASSETS_MANIFEST.md": b"# Assets manifest\n",
        "CHANGELOG.md": b"# Changelog\n",
        "calendar-data/manifest.json": manifest,
        "calendar-data/cn-2026.json": dataset,
    }
    build_info: dict[str, Any] = {
        "schema_version": "1.0",
        "product": "LetsMakeMoney",
        "version": VERSION,
        "channel": "stable-candidate",
        "platform": PLATFORM,
        "architecture": ARCHITECTURE,
        "source_head": SOURCE_HEAD,
        "source_tree_dirty": dirty,
        "build_timestamp_utc": "2026-08-01T00:00:00Z",
        "executable_sha256": digest(payload["LetsMakeMoney.exe"]),
        "webview2_loader_sha256": digest(payload["WebView2Loader.dll"]),
        "documentation": {
            "readme_sha256": digest(payload["README.md"]),
            "readme_en_sha256": digest(payload["README.en.md"]),
            "source": "apps/windows-v1/release-docs",
        },
        "licenses": {
            "license_sha256": digest(payload["LICENSE"]),
            "third_party_notices_sha256": digest(payload["THIRD_PARTY_NOTICES.md"]),
            "assets_license_sha256": digest(payload["ASSETS_LICENSE.md"]),
            "assets_manifest_sha256": digest(payload["ASSETS_MANIFEST.md"]),
        },
        "calendar": {
            "manifest_sha256": digest(manifest),
            "dataset_version": "synthetic-2026.08",
            "datasets": [
                {"year": 2026, "file": "cn-2026.json", "sha256": digest(dataset)}
            ],
        },
    }
    if build_mutator is not None:
        build_mutator(build_info)
    payload["BUILD-INFO.json"] = encode_json(build_info)
    if payload_mutator is not None:
        payload_mutator(payload)

    root = f"LetsMakeMoney-v{VERSION}-{PLATFORM}"
    if wrong_location:
        package = artifact_root / ZIP_NAME
    elif mode == "candidate":
        package = artifact_root / candidate_id / ZIP_NAME
    else:
        package = artifact_root / TAG / "20260801T000000Z" / ZIP_NAME
    write_deterministic_zip(package, root, payload)
    return package


def expectation(
    artifact_root: Path,
    *,
    mode: verifier.Mode,
    package: Path,
    expected_source_head: str = SOURCE_HEAD,
    release_url: str = RELEASE_URL,
    tag_target: str = SOURCE_HEAD,
) -> verifier.IdentityExpectation:
    if mode == "candidate":
        return verifier.IdentityExpectation(
            mode=mode,
            version=VERSION,
            platform=PLATFORM,
            architecture=ARCHITECTURE,
            source_head=expected_source_head,
            artifact_root=artifact_root,
        )
    package_hash = verifier.sha256(package)
    checksums = package.parent / "SHA256SUMS.txt"
    checksums.write_text(f"{package_hash}  {package.name}\n", encoding="utf-8")
    return verifier.IdentityExpectation(
        mode=mode,
        version=VERSION,
        platform=PLATFORM,
        architecture=ARCHITECTURE,
        source_head=expected_source_head,
        expected_zip_sha256=package_hash,
        tag=TAG,
        tag_target_commit=tag_target,
        release_url=release_url,
        checksums_path=checksums,
        artifact_root=artifact_root,
    )


def require_rejected(label: str, action: Callable[[], None]) -> None:
    try:
        action()
    except verifier.IdentityError:
        print(f"PASS rejected {label}")
        return
    raise AssertionError(f"invalid package contract was accepted: {label}")


def main() -> int:
    with tempfile.TemporaryDirectory(prefix="lmm-v105-package-contract-") as temporary:
        root = Path(temporary)

        candidate_root = root / ".artifacts" / "candidates" / f"v{VERSION}"
        clean = make_package(candidate_root, mode="candidate")
        result = verifier.validate_package(clean, expectation(candidate_root, mode="candidate", package=clean))
        assert result["source_tree_dirty"] is False
        print("PASS accepted clean candidate")

        dirty = make_package(candidate_root, mode="candidate", dirty=True, candidate_id="candidate-dirty")
        result = verifier.validate_package(dirty, expectation(candidate_root, mode="candidate", package=dirty))
        assert result["source_tree_dirty"] is True
        print("PASS accepted explicitly identified dirty candidate")

        wrong_source = make_package(candidate_root, mode="candidate", candidate_id="wrong-source")
        require_rejected(
            "candidate source HEAD drift",
            lambda: verifier.validate_package(
                wrong_source,
                expectation(candidate_root, mode="candidate", package=wrong_source, expected_source_head="b" * 40),
            ),
        )

        wrong_version = make_package(
            candidate_root,
            mode="candidate",
            candidate_id="wrong-version",
            build_mutator=lambda info: info.__setitem__("version", "1.0.4"),
        )
        require_rejected(
            "candidate version drift",
            lambda: verifier.validate_package(
                wrong_version, expectation(candidate_root, mode="candidate", package=wrong_version)
            ),
        )

        for field in ("architecture", "build_timestamp_utc"):
            package = make_package(
                candidate_root,
                mode="candidate",
                candidate_id=f"missing-{field.replace('_', '-')}",
                build_mutator=lambda info, name=field: info.pop(name),
            )
            require_rejected(
                f"missing BUILD-INFO {field}",
                lambda package=package: verifier.validate_package(
                    package, expectation(candidate_root, mode="candidate", package=package)
                ),
            )

        tampered = make_package(
            candidate_root,
            mode="candidate",
            candidate_id="tampered-exe",
            payload_mutator=lambda payload: payload.__setitem__("LetsMakeMoney.exe", b"tampered"),
        )
        require_rejected(
            "candidate payload hash drift",
            lambda: verifier.validate_package(
                tampered, expectation(candidate_root, mode="candidate", package=tampered)
            ),
        )

        misplaced = make_package(candidate_root, mode="candidate", wrong_location=True)
        require_rejected(
            "candidate outside candidate-id directory",
            lambda: verifier.validate_package(
                misplaced, expectation(candidate_root, mode="candidate", package=misplaced)
            ),
        )

        published_root = root / ".artifacts" / "published" / f"v{VERSION}"
        published = make_package(published_root, mode="published")
        verifier.validate_package(
            published, expectation(published_root, mode="published", package=published)
        )
        print("PASS accepted published cache identity")

        dirty_published = make_package(
            published_root / "dirty-case", mode="published", dirty=True
        )
        dirty_expectation = expectation(
            published_root / "dirty-case", mode="published", package=dirty_published
        )
        require_rejected(
            "dirty published package",
            lambda: verifier.validate_package(dirty_published, dirty_expectation),
        )

        require_rejected(
            "published tag target drift",
            lambda: verifier.validate_package(
                published,
                expectation(
                    published_root,
                    mode="published",
                    package=published,
                    tag_target="b" * 40,
                ),
            ),
        )
        require_rejected(
            "published Release URL drift",
            lambda: verifier.validate_package(
                published,
                expectation(
                    published_root,
                    mode="published",
                    package=published,
                    release_url="https://example.invalid/v1.0.5",
                ),
            ),
        )

        wrong_hash = copy.copy(expectation(published_root, mode="published", package=published))
        object.__setattr__(wrong_hash, "expected_zip_sha256", "0" * 64)
        require_rejected(
            "published downloaded Zip SHA drift",
            lambda: verifier.validate_package(published, wrong_hash),
        )

        bad_checksums = expectation(published_root, mode="published", package=published)
        assert bad_checksums.checksums_path is not None
        bad_checksums.checksums_path.write_text(f"{'0' * 64}  {ZIP_NAME}\n", encoding="utf-8")
        require_rejected(
            "published SHA256SUMS drift",
            lambda: verifier.validate_package(published, bad_checksums),
        )

        misplaced_published_root = root / "misplaced-published"
        misplaced_published = make_package(
            misplaced_published_root, mode="published", wrong_location=True
        )
        misplaced_expectation = expectation(
            misplaced_published_root, mode="published", package=misplaced_published
        )
        require_rejected(
            "published cache directory drift",
            lambda: verifier.validate_package(misplaced_published, misplaced_expectation),
        )

    print("PASS v1.0.5 package identity contracts (3 positive, 12 negative)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
