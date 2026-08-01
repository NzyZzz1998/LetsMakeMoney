from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
import zipfile
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path, PurePosixPath
from typing import Any, Literal


Mode = Literal["candidate", "published"]
SHA256_PATTERN = re.compile(r"^[A-F0-9]{64}$")
COMMIT_PATTERN = re.compile(r"^[0-9a-f]{40}$")
REPOSITORY = "NzyZzz1998/LetsMakeMoney"
REQUIRED_PAYLOAD_FILES = {
    "LetsMakeMoney.exe",
    "WebView2Loader.dll",
    "README.md",
    "README.en.md",
    "LICENSE",
    "THIRD_PARTY_NOTICES.md",
    "ASSETS_LICENSE.md",
    "ASSETS_MANIFEST.md",
    "CHANGELOG.md",
    "BUILD-INFO.json",
    "calendar-data/manifest.json",
}


class IdentityError(ValueError):
    pass


@dataclass(frozen=True)
class IdentityExpectation:
    mode: Mode
    version: str
    platform: str
    architecture: str
    source_head: str
    expected_zip_sha256: str | None = None
    tag: str | None = None
    tag_target_commit: str | None = None
    release_url: str | None = None
    checksums_path: Path | None = None
    artifact_root: Path | None = None


def require(condition: bool, message: str) -> None:
    if not condition:
        raise IdentityError(message)


def sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest().upper()


def sha256(path: Path) -> str:
    return sha256_bytes(path.read_bytes())


def require_sha256(value: Any, label: str) -> str:
    normalized = str(value).upper()
    require(bool(SHA256_PATTERN.fullmatch(normalized)), f"{label} is not SHA256")
    return normalized


def parse_timestamp(value: Any) -> str:
    text = str(value)
    try:
        parsed = datetime.fromisoformat(text.replace("Z", "+00:00"))
    except ValueError as error:
        raise IdentityError("build_timestamp_utc is not ISO-8601") from error
    require(parsed.tzinfo is not None, "build_timestamp_utc must include UTC offset")
    require(parsed.utcoffset() is not None and parsed.utcoffset().total_seconds() == 0,
            "build_timestamp_utc must be UTC")
    return text


def validate_member_names(names: list[str], expected_root: str) -> None:
    require(names, "package is empty")
    for name in names:
        member = PurePosixPath(name)
        require(not member.is_absolute(), f"package contains absolute member: {name}")
        require(".." not in member.parts, f"package contains traversal member: {name}")
        require("\\" not in name, f"package member uses a backslash: {name}")
        require(member.parts and member.parts[0] == expected_root,
                f"package member is outside expected root: {name}")
    roots = {PurePosixPath(name).parts[0] for name in names if PurePosixPath(name).parts}
    require(roots == {expected_root}, f"package root drift: {sorted(roots)}")


def validate_location(package_path: Path, expectation: IdentityExpectation) -> None:
    if expectation.artifact_root is None:
        return
    root = expectation.artifact_root.resolve()
    package = package_path.resolve()
    try:
        relative = package.relative_to(root)
    except ValueError as error:
        raise IdentityError(
            f"{expectation.mode} package is outside its owned artifact root"
        ) from error
    parts = relative.parts
    if expectation.mode == "candidate":
        require(len(parts) == 2, "candidate path must be <candidate-id>/<zip>")
        require(bool(re.fullmatch(r"[A-Za-z0-9._-]{6,96}", parts[0])),
                "candidate-id is invalid")
    else:
        require(len(parts) == 3, "published path must be <tag>/<downloaded-at>/<zip>")
        require(parts[0] == expectation.tag, "published cache tag directory drift")
        require(bool(re.fullmatch(r"[0-9]{8}T[0-9]{6}Z", parts[1])),
                "published cache timestamp directory is invalid")


def validate_build_info(info: dict[str, Any], expectation: IdentityExpectation) -> None:
    required = {
        "schema_version",
        "product",
        "version",
        "channel",
        "platform",
        "architecture",
        "source_head",
        "source_tree_dirty",
        "build_timestamp_utc",
        "executable_sha256",
        "webview2_loader_sha256",
        "documentation",
        "licenses",
        "calendar",
    }
    require(set(info) == required, "BUILD-INFO fields do not match the v1.0.5 contract")
    require(info["schema_version"] == "1.0", "BUILD-INFO schema drift")
    require(info["product"] == "LetsMakeMoney", "product identity drift")
    require(info["version"] == expectation.version, "BUILD-INFO version mismatch")
    require(info["channel"] == "stable-candidate", "BUILD-INFO channel mismatch")
    require(info["platform"] == expectation.platform, "BUILD-INFO platform mismatch")
    require(info["architecture"] == expectation.architecture,
            "BUILD-INFO architecture mismatch")
    require(bool(COMMIT_PATTERN.fullmatch(str(info["source_head"]))),
            "BUILD-INFO source_head is invalid")
    require(info["source_head"] == expectation.source_head,
            "BUILD-INFO source_head mismatch")
    require(isinstance(info["source_tree_dirty"], bool),
            "source_tree_dirty must be boolean")
    parse_timestamp(info["build_timestamp_utc"])
    require_sha256(info["executable_sha256"], "executable_sha256")
    require_sha256(info["webview2_loader_sha256"], "webview2_loader_sha256")

    documentation = info["documentation"]
    require(isinstance(documentation, dict), "documentation identity must be an object")
    require(set(documentation) == {"readme_sha256", "readme_en_sha256", "source"},
            "documentation identity fields drift")
    require_sha256(documentation["readme_sha256"], "README.md identity")
    require_sha256(documentation["readme_en_sha256"], "README.en.md identity")
    require(documentation["source"] == "apps/windows-v1/release-docs",
            "portable README source drift")

    licenses = info["licenses"]
    expected_license_fields = {
        "license_sha256",
        "third_party_notices_sha256",
        "assets_license_sha256",
        "assets_manifest_sha256",
    }
    require(isinstance(licenses, dict) and set(licenses) == expected_license_fields,
            "license identity fields drift")
    for field in expected_license_fields:
        require_sha256(licenses[field], field)

    calendar = info["calendar"]
    require(isinstance(calendar, dict), "calendar identity must be an object")
    require(set(calendar) == {"manifest_sha256", "dataset_version", "datasets"},
            "calendar identity fields drift")
    require_sha256(calendar["manifest_sha256"], "calendar manifest identity")
    require(isinstance(calendar["dataset_version"], str) and calendar["dataset_version"],
            "calendar dataset_version is missing")
    require(isinstance(calendar["datasets"], list) and calendar["datasets"],
            "calendar datasets are missing")
    for entry in calendar["datasets"]:
        require(isinstance(entry, dict) and set(entry) == {"year", "file", "sha256"},
                "calendar dataset identity fields drift")
        require(isinstance(entry["year"], int), "calendar year must be an integer")
        require(bool(re.fullmatch(r"[A-Za-z0-9._-]+\.json", str(entry["file"]))),
                "calendar dataset filename is invalid")
        require_sha256(entry["sha256"], "calendar dataset identity")

    if expectation.mode == "published":
        require(info["source_tree_dirty"] is False,
                "published package must come from a clean source tree")
        require(expectation.tag is not None, "published mode requires a tag")
        require(expectation.tag_target_commit is not None,
                "published mode requires tag target commit")
        require(expectation.tag_target_commit == info["source_head"],
                "tag target and BUILD-INFO source_head differ")
        expected_url = (
            f"https://github.com/{REPOSITORY}/releases/tag/{expectation.tag}"
        )
        require(expectation.release_url == expected_url, "published Release URL mismatch")


def member_bytes(archive: zipfile.ZipFile, root: str, relative: str) -> bytes:
    name = f"{root}/{relative}"
    try:
        value = archive.read(name)
    except KeyError as error:
        raise IdentityError(f"required package file is missing: {relative}") from error
    require(value, f"required package file is empty: {relative}")
    return value


def validate_payload_hashes(
    archive: zipfile.ZipFile,
    root: str,
    info: dict[str, Any],
) -> None:
    mappings = {
        "LetsMakeMoney.exe": info["executable_sha256"],
        "WebView2Loader.dll": info["webview2_loader_sha256"],
        "README.md": info["documentation"]["readme_sha256"],
        "README.en.md": info["documentation"]["readme_en_sha256"],
        "LICENSE": info["licenses"]["license_sha256"],
        "THIRD_PARTY_NOTICES.md": info["licenses"]["third_party_notices_sha256"],
        "ASSETS_LICENSE.md": info["licenses"]["assets_license_sha256"],
        "ASSETS_MANIFEST.md": info["licenses"]["assets_manifest_sha256"],
        "calendar-data/manifest.json": info["calendar"]["manifest_sha256"],
    }
    for relative, expected in mappings.items():
        require(sha256_bytes(member_bytes(archive, root, relative)) == expected,
                f"{relative} hash differs from BUILD-INFO")

    manifest = json.loads(
        member_bytes(archive, root, "calendar-data/manifest.json").decode("utf-8-sig")
    )
    require(manifest.get("dataset_version") == info["calendar"]["dataset_version"],
            "calendar dataset version differs from BUILD-INFO")
    manifest_entries = {
        (int(entry["year"]), str(entry["file"])): str(entry["sha256"]).upper()
        for entry in manifest.get("datasets", [])
    }
    build_entries = {
        (int(entry["year"]), str(entry["file"])): str(entry["sha256"]).upper()
        for entry in info["calendar"]["datasets"]
    }
    require(manifest_entries == build_entries, "calendar dataset identities drift")
    for (_, filename), expected in manifest_entries.items():
        actual = sha256_bytes(member_bytes(archive, root, f"calendar-data/{filename}"))
        require(actual == expected, f"calendar dataset hash mismatch: {filename}")


def validate_checksums(path: Path, zip_name: str, zip_hash: str) -> None:
    require(path.is_file() and path.stat().st_size > 0,
            "published SHA256SUMS.txt is missing or empty")
    entries: dict[str, str] = {}
    for raw_line in path.read_text(encoding="utf-8-sig").splitlines():
        line = raw_line.strip()
        if not line:
            continue
        match = re.fullmatch(r"([A-Fa-f0-9]{64})\s+\*?([^\\/:]+)", line)
        require(match is not None, "SHA256SUMS.txt contains an invalid line")
        digest, name = match.groups()
        require(name not in entries, f"SHA256SUMS.txt duplicates {name}")
        entries[name] = digest.upper()
    require(entries.get(zip_name) == zip_hash,
            "SHA256SUMS.txt does not match the downloaded Zip")


def validate_package(
    package_path: Path,
    expectation: IdentityExpectation,
) -> dict[str, Any]:
    require(package_path.is_file(), f"package does not exist: {package_path}")
    expected_root = f"LetsMakeMoney-v{expectation.version}-{expectation.platform}"
    require(package_path.name == f"{expected_root}.zip", "package filename mismatch")
    validate_location(package_path, expectation)

    zip_hash = sha256(package_path)
    if expectation.expected_zip_sha256 is not None:
        require(zip_hash == require_sha256(expectation.expected_zip_sha256,
                                            "expected Zip SHA256"),
                "Zip SHA256 differs from the locked identity")
    if expectation.mode == "published":
        require(expectation.expected_zip_sha256 is not None,
                "published mode requires locked Zip SHA256")
        require(expectation.checksums_path is not None,
                "published mode requires SHA256SUMS.txt")
        validate_checksums(expectation.checksums_path, package_path.name, zip_hash)

    with zipfile.ZipFile(package_path) as archive:
        names = archive.namelist()
        validate_member_names(names, expected_root)
        present = {
            str(PurePosixPath(name).relative_to(expected_root))
            for name in names
            if not name.endswith("/")
        }
        missing = sorted(REQUIRED_PAYLOAD_FILES - present)
        require(not missing, f"package required files are missing: {missing}")
        info = json.loads(member_bytes(archive, expected_root, "BUILD-INFO.json")
                          .decode("utf-8-sig"))
        require(isinstance(info, dict), "BUILD-INFO must contain an object")
        validate_build_info(info, expectation)
        validate_payload_hashes(archive, expected_root, info)

    return {
        "mode": expectation.mode,
        "version": expectation.version,
        "source_head": expectation.source_head,
        "source_tree_dirty": bool(info["source_tree_dirty"]),
        "zip_sha256": zip_hash,
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Verify LetsMakeMoney v1.0.5 candidate or published identity."
    )
    parser.add_argument("--mode", choices=("candidate", "published"), required=True)
    parser.add_argument("--package", type=Path, required=True)
    parser.add_argument("--version", default="1.0.5")
    parser.add_argument("--platform", default="windows-x86_64")
    parser.add_argument("--architecture", default="x86_64")
    parser.add_argument("--source-head", required=True)
    parser.add_argument("--expected-zip-sha256")
    parser.add_argument("--tag")
    parser.add_argument("--tag-target-commit")
    parser.add_argument("--release-url")
    parser.add_argument("--checksums", type=Path)
    parser.add_argument("--artifact-root", type=Path)
    return parser


def main() -> int:
    args = build_parser().parse_args()
    expectation = IdentityExpectation(
        mode=args.mode,
        version=args.version,
        platform=args.platform,
        architecture=args.architecture,
        source_head=args.source_head,
        expected_zip_sha256=args.expected_zip_sha256,
        tag=args.tag,
        tag_target_commit=args.tag_target_commit,
        release_url=args.release_url,
        checksums_path=args.checksums,
        artifact_root=args.artifact_root,
    )
    try:
        result = validate_package(args.package, expectation)
    except (IdentityError, OSError, UnicodeDecodeError, json.JSONDecodeError,
            zipfile.BadZipFile, KeyError, TypeError, ValueError) as error:
        print(f"FAIL {error}", file=sys.stderr)
        return 1
    print(json.dumps(result, ensure_ascii=False, sort_keys=True))
    print(f"PASS v1.0.5 {args.mode} package identity")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
