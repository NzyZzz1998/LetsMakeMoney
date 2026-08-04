from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path
from typing import Any

from verify_v105_package import IdentityExpectation, validate_package


APP_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = APP_ROOT.parents[1]
RELEASE_ROOT = REPO_ROOT / "doc" / "releases" / "v1.0.5"
VERSION = "1.0.5"
PLATFORM = "windows-x86_64"
ZIP_NAME = f"LetsMakeMoney-v{VERSION}-{PLATFORM}.zip"
SHA256_RE = re.compile(r"^[A-F0-9]{64}$")
HEAD_RE = re.compile(r"^[0-9a-f]{40}$")
ABSOLUTE_PATH_RE = re.compile(r"(?i)(?:[A-Z]:[\\/]|/Users/|/home/)")


class M6Error(ValueError):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise M6Error(message)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def load_json(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8-sig"))
    require(isinstance(value, dict), f"{path.name} must contain an object")
    return value


def validate_candidate_identity(
    value: dict[str, Any],
    *,
    candidate_id: str,
    package_path: Path | None = None,
) -> None:
    required = {
        "schema_version",
        "candidate_id",
        "release_version",
        "source_head",
        "source_tree_dirty",
        "build_timestamp_utc",
        "publication_allowed",
        "publication_blockers",
        "artifacts",
        "verification",
    }
    require(set(value) == required, "candidate identity fields drift")
    require(value["schema_version"] == "1.0", "candidate identity schema drift")
    require(value["candidate_id"] == candidate_id, "candidate directory identity drift")
    require(value["release_version"] == VERSION, "candidate version drift")
    require(bool(HEAD_RE.fullmatch(value["source_head"])), "candidate source HEAD is invalid")
    require(type(value["source_tree_dirty"]) is bool, "candidate dirty state must be boolean")
    require(value["publication_allowed"] is False, "unaccepted candidate must not be publishable")
    require(value["verification"] == "candidate-package-contract-passed", "candidate verification drift")

    blockers = value["publication_blockers"]
    require(isinstance(blockers, list) and all(isinstance(item, str) for item in blockers),
            "publication blockers must be a string list")
    require("independent acceptance is not complete" in blockers,
            "independent acceptance blocker is missing")
    expected_source_blocker = (
        "source tree is dirty"
        if value["source_tree_dirty"]
        else "release authorization is not granted"
    )
    require(expected_source_blocker in blockers, "source/publication blocker does not match identity")

    artifacts = value["artifacts"]
    require(isinstance(artifacts, list) and len(artifacts) == 5,
            "candidate must identify Zip, EXE, DLL and two README files")
    expected_names = {
        ZIP_NAME,
        "LetsMakeMoney.exe",
        "WebView2Loader.dll",
        "README.md",
        "README.en.md",
    }
    names: set[str] = set()
    for artifact in artifacts:
        require(isinstance(artifact, dict), "candidate artifact identity must be an object")
        require(set(artifact) == {"name", "size", "sha256"}, "candidate artifact fields drift")
        require(isinstance(artifact["name"], str), "candidate artifact name is invalid")
        require(isinstance(artifact["size"], int) and artifact["size"] > 0,
                "candidate artifact size is invalid")
        require(bool(SHA256_RE.fullmatch(artifact["sha256"])),
                "candidate artifact SHA256 is invalid")
        require(not ABSOLUTE_PATH_RE.search(artifact["name"]),
                "candidate artifact leaks an absolute path")
        require(artifact["name"] not in names, "candidate artifact names are duplicated")
        names.add(artifact["name"])
    require(names == expected_names, "candidate artifact set drift")

    if package_path is not None:
        package = next(item for item in artifacts if item["name"] == ZIP_NAME)
        require(package["size"] == package_path.stat().st_size,
                "candidate Zip size differs from candidate identity")
        require(package["sha256"] == sha256(package_path),
                "candidate Zip SHA256 differs from candidate identity")

    serialized = json.dumps(value, ensure_ascii=False)
    require(not ABSOLUTE_PATH_RE.search(serialized), "candidate identity leaks an absolute path")


def read_cargo_version(path: Path) -> str:
    match = re.search(
        r'(?ms)^\[package\]\s*.*?^version\s*=\s*"(?P<version>\d+\.\d+\.\d+)"',
        path.read_text(encoding="utf-8"),
    )
    require(match is not None, "Cargo package version could not be read")
    return match.group("version")


def validate_app_version_contract(app_source: str) -> None:
    update_versions = re.findall(r'\.evaluateUpdate\("(\d+\.\d+\.\d+)"', app_source)
    require(
        len(update_versions) == 2 and all(version == VERSION for version in update_versions),
        "update evaluator current version drift",
    )
    require(
        app_source.count(f"<dt>版本</dt><dd>{VERSION}</dd>") == 1,
        "About version drift",
    )


def validate_source_versions() -> None:
    package = load_json(APP_ROOT / "package.json")
    lock = load_json(APP_ROOT / "package-lock.json")
    tauri = load_json(APP_ROOT / "src-tauri" / "tauri.conf.json")
    cargo_lock = (APP_ROOT / "src-tauri" / "Cargo.lock").read_text(encoding="utf-8")
    app_source = (APP_ROOT / "src" / "App.tsx").read_text(encoding="utf-8")

    require(package["version"] == VERSION, "package.json version drift")
    require(lock["version"] == VERSION, "package-lock root version drift")
    require(lock["packages"][""]["version"] == VERSION, "package-lock package version drift")
    require(tauri["version"] == VERSION, "tauri.conf.json version drift")
    require(read_cargo_version(APP_ROOT / "src-tauri" / "Cargo.toml") == VERSION,
            "Cargo.toml version drift")
    require(
        re.search(
            rf'(?ms)^name = "letsmakemoney_windows_v1"\s+version = "{re.escape(VERSION)}"$',
            cargo_lock,
        ) is not None,
        "Cargo.lock application version drift",
    )
    validate_app_version_contract(app_source)


def validate_candidate_documents(identity: dict[str, Any]) -> None:
    candidate_id = identity["candidate_id"]
    zip_hash = next(
        item["sha256"] for item in identity["artifacts"] if item["name"] == ZIP_NAME
    )
    source_state = "dirty" if identity["source_tree_dirty"] else "clean"
    docs = {
        "verification.md": RELEASE_ROOT / "verification.md",
        "manual-verification.md": RELEASE_ROOT / "manual-verification.md",
        "release-checklist.md": RELEASE_ROOT / "release-checklist.md",
        "release-notes.md": RELEASE_ROOT / "release-notes.md",
        "progress_v1.0.5.md": RELEASE_ROOT / "progress_v1.0.5.md",
    }
    for name, path in docs.items():
        text = path.read_text(encoding="utf-8")
        require(candidate_id in text, f"{name} misses candidate id")
        require(zip_hash in text, f"{name} misses candidate Zip SHA256")
        require(source_state in text.lower(), f"{name} misses candidate source state")
        require("不可发布" in text or "不得发布" in text,
                f"{name} must keep the candidate publication blocker")
        require(not ABSOLUTE_PATH_RE.search(text), f"{name} leaks an absolute local path")

    current = (REPO_ROOT / "doc" / "current.md").read_text(encoding="utf-8")
    require("Windows v1.0.5" in current, "current.md misses v1.0.5 development identity")
    require("Windows v1.0.4 Stable" in current, "current.md public release identity drift")
    require("不可发布" in current, "current.md must preserve the candidate blocker")


def validate_checksums(candidate_dir: Path, package_path: Path) -> None:
    path = candidate_dir / "SHA256SUMS.txt"
    require(path.is_file(), "candidate SHA256SUMS.txt is missing")
    lines = [line.strip() for line in path.read_text(encoding="ascii").splitlines() if line.strip()]
    require(lines == [f"{sha256(package_path)}  {ZIP_NAME}"],
            "candidate SHA256SUMS.txt drift")


def validate_evidence_summary(identity: dict[str, Any]) -> None:
    path = RELEASE_ROOT / "evidence" / "m6-candidate-summary.json"
    require(path.is_file(), "M6 durable candidate summary is missing")
    summary = load_json(path)
    require(
        set(summary)
        == {
            "schema_version",
            "milestone",
            "candidate",
            "artifacts",
            "verification",
            "completion",
            "publication",
            "evidence",
        },
        "M6 candidate summary fields drift",
    )
    require(summary["schema_version"] == "1.0", "M6 summary schema drift")
    require(summary["milestone"] == "V105-M6", "M6 summary milestone drift")
    require(
        summary["candidate"]
        == {
            "candidate_id": identity["candidate_id"],
            "source_head": identity["source_head"],
            "source_tree_dirty": identity["source_tree_dirty"],
            "build_timestamp_utc": identity["build_timestamp_utc"],
        },
        "M6 summary candidate identity drift",
    )

    artifacts = {item["name"]: item for item in identity["artifacts"]}
    expected = {
        "zip": artifacts[ZIP_NAME],
        "executable": artifacts["LetsMakeMoney.exe"],
        "webview2_loader": artifacts["WebView2Loader.dll"],
    }
    for key, artifact in expected.items():
        require(summary["artifacts"].get(key) == artifact,
                f"M6 summary {key} identity drift")
    require(
        summary["artifacts"].get("readme")
        == {"sha256": artifacts["README.md"]["sha256"]},
        "M6 summary README identity drift",
    )
    require(
        summary["artifacts"].get("readme_en")
        == {"sha256": artifacts["README.en.md"]["sha256"]},
        "M6 summary English README identity drift",
    )
    require(summary["publication"].get("allowed") is False,
            "M6 summary must remain non-publishable")
    require(
        set(summary["publication"].get("blockers", []))
        == set(identity["publication_blockers"]),
        "M6 summary publication blockers drift",
    )
    serialized = json.dumps(summary, ensure_ascii=False)
    require(not ABSOLUTE_PATH_RE.search(serialized),
            "M6 durable summary leaks an absolute local path")


def validate_candidate(package_path: Path) -> dict[str, Any]:
    candidate_dir = package_path.resolve().parent
    artifact_root = REPO_ROOT / ".artifacts" / "candidates" / f"v{VERSION}"
    require(candidate_dir.parent.resolve() == artifact_root.resolve(),
            "candidate is outside the isolated candidate root")
    identity_path = candidate_dir / "candidate-identity.json"
    require(identity_path.is_file(), "candidate identity file is missing")
    identity = load_json(identity_path)
    validate_candidate_identity(
        identity,
        candidate_id=candidate_dir.name,
        package_path=package_path,
    )
    validate_package(
        package_path,
        IdentityExpectation(
            mode="candidate",
            version=VERSION,
            platform=PLATFORM,
            architecture="x86_64",
            source_head=identity["source_head"],
            expected_zip_sha256=sha256(package_path),
            artifact_root=artifact_root,
        ),
    )
    validate_checksums(candidate_dir, package_path)
    validate_source_versions()
    validate_candidate_documents(identity)
    validate_evidence_summary(identity)
    return identity


def main() -> int:
    parser = argparse.ArgumentParser(description="Verify the v1.0.5 M6 controlled candidate.")
    parser.add_argument("--candidate-path", type=Path, required=True)
    args = parser.parse_args()
    try:
        identity = validate_candidate(args.candidate_path)
    except (M6Error, OSError, UnicodeError, json.JSONDecodeError, KeyError, TypeError, ValueError) as error:
        print(f"FAIL {error}", file=sys.stderr)
        return 1
    status = "dirty-controlled" if identity["source_tree_dirty"] else "clean-unaccepted"
    print(f"PASS v1.0.5 M6 candidate identity ({status})")
    print("- publication remains blocked until a clean-source candidate and independent acceptance exist")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
