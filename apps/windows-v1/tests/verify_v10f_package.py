from __future__ import annotations

import json
import re
import sys
import zipfile
from pathlib import Path, PurePosixPath

import verify_v105_package as base


TEXT_PAYLOAD_FILES = {
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
FORBIDDEN_MEMBER_PARTS = {
    ".git",
    ".artifacts",
    ".tmp",
    "node_modules",
    "target",
    "screenshots",
    "evidence",
    "logs",
    "cache",
}
FORBIDDEN_FILE_NAMES = {
    "config.json",
    "debug.log",
    "candidate-identity.json",
    "sha256sums.txt",
}
ABSOLUTE_PATH = re.compile(r"(?:(?<![A-Za-z])[A-Za-z]:[\\/]|/Users/|/home/|\\Users\\)")
SECRET_PATTERNS = (
    re.compile(r"github_pat_[A-Za-z0-9_]+"),
    re.compile(r"ghp_[A-Za-z0-9]+"),
    re.compile(r"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----"),
    re.compile(r"AKIA[0-9A-Z]{16}"),
)


def validate_payload(package_path: Path, version: str, platform: str) -> None:
    root = f"LetsMakeMoney-v{version}-{platform}"
    with zipfile.ZipFile(package_path) as archive:
        names = [name for name in archive.namelist() if not name.endswith("/")]
        relative_names = {
            str(PurePosixPath(name).relative_to(root))
            for name in names
        }
        manifest = json.loads(
            archive.read(f"{root}/calendar-data/manifest.json").decode("utf-8-sig")
        )
        calendar_files = {
            f"calendar-data/{entry['file']}" for entry in manifest.get("datasets", [])
        }
        allowed = base.REQUIRED_PAYLOAD_FILES | calendar_files
        unexpected = sorted(relative_names - allowed)
        base.require(not unexpected, f"package contains unregistered files: {unexpected}")

        for relative in relative_names:
            path = PurePosixPath(relative)
            lowered_parts = {part.lower() for part in path.parts}
            base.require(
                not lowered_parts.intersection(FORBIDDEN_MEMBER_PARTS),
                f"package contains a forbidden path: {relative}",
            )
            base.require(
                path.name.lower() not in FORBIDDEN_FILE_NAMES,
                f"package contains a private or temporary file: {relative}",
            )
            if path.suffix.lower() in {".exe", ".dll"}:
                base.require(
                    relative in {"LetsMakeMoney.exe", "WebView2Loader.dll"},
                    f"package contains an unregistered binary: {relative}",
                )

        for relative in sorted(TEXT_PAYLOAD_FILES | calendar_files):
            raw = archive.read(f"{root}/{relative}")
            try:
                text = raw.decode("utf-8-sig")
            except UnicodeDecodeError as error:
                raise base.IdentityError(f"package text is not UTF-8: {relative}") from error
            base.require("\ufffd" not in text, f"package text contains replacement characters: {relative}")
            base.require(not ABSOLUTE_PATH.search(text), f"package text leaks an absolute path: {relative}")
            for pattern in SECRET_PATTERNS:
                base.require(not pattern.search(text), f"package text may contain a secret: {relative}")


def main() -> int:
    args = base.build_parser().parse_args()
    expectation = base.IdentityExpectation(
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
        result = base.validate_package(args.package, expectation)
        validate_payload(args.package, args.version, args.platform)
    except (
        base.IdentityError,
        OSError,
        UnicodeDecodeError,
        json.JSONDecodeError,
        zipfile.BadZipFile,
        KeyError,
        TypeError,
        ValueError,
    ) as error:
        print(f"FAIL {error}", file=sys.stderr)
        return 1
    print(json.dumps(result, ensure_ascii=False, sort_keys=True))
    print(f"PASS v{args.version} {args.mode} package identity and content audit")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
