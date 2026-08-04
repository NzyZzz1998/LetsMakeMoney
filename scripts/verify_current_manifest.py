from __future__ import annotations

import argparse
import json
from pathlib import Path, PurePosixPath
from typing import Callable


ALLOWED_GATE_LIFECYCLES = {"current", "reusable"}


class ManifestError(ValueError):
    pass


def load_json(path: Path) -> object:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def normalized_repo_path(value: str) -> str:
    normalized = value.replace("\\", "/")
    path = PurePosixPath(normalized)
    if path.is_absolute() or ".." in path.parts or not normalized.startswith("scripts/"):
        raise ManifestError(f"invalid repository script path: {value}")
    return path.as_posix()


def lifecycle_index(document: dict) -> dict[str, str]:
    if document.get("schema_version") != 1:
        raise ManifestError("unsupported script lifecycle schema")
    result: dict[str, str] = {}
    statuses = document.get("statuses")
    if not isinstance(statuses, dict):
        raise ManifestError("script lifecycle statuses are missing")
    for status in ("current", "reusable", "manual", "historical"):
        paths = statuses.get(status)
        if not isinstance(paths, list):
            raise ManifestError(f"script lifecycle group is missing: {status}")
        for raw_path in paths:
            path = normalized_repo_path(str(raw_path))
            if path in result:
                raise ManifestError(f"script has multiple lifecycle statuses: {path}")
            result[path] = status
    return result


def validate_manifest_data(
    manifest: dict,
    lifecycle: dict,
    expected_version: str,
    expected_config_version: int,
    file_exists: Callable[[str], bool],
) -> None:
    if manifest.get("schema_version") != 1:
        raise ManifestError("unsupported current manifest schema")
    if manifest.get("product") != "LetsMakeMoney Windows":
        raise ManifestError("current manifest product identity mismatch")
    if manifest.get("version") != expected_version:
        raise ManifestError("current manifest version mismatch")
    if manifest.get("config_version") != expected_config_version:
        raise ManifestError("current manifest config version mismatch")
    if normalized_repo_path(str(manifest.get("aggregate", ""))) != "scripts/verify_windows_current.ps1":
        raise ManifestError("current manifest aggregate must use the unique current entry")

    gates = manifest.get("gates")
    if not isinstance(gates, list) or not gates:
        raise ManifestError("current manifest has no sub-gates")
    ids: set[str] = set()
    for gate in gates:
        if not isinstance(gate, dict):
            raise ManifestError("current gate must be an object")
        gate_id = str(gate.get("id", ""))
        if not gate_id or gate_id in ids:
            raise ManifestError(f"invalid or duplicate current gate id: {gate_id}")
        ids.add(gate_id)
        path = normalized_repo_path(str(gate.get("path", "")))
        status = str(gate.get("lifecycle", ""))
        if status not in ALLOWED_GATE_LIFECYCLES:
            raise ManifestError(f"current gate cannot use lifecycle '{status}': {path}")
        if lifecycle.get(path) != status:
            raise ManifestError(f"current gate lifecycle differs from index: {path}")
        if not file_exists(path):
            raise ManifestError(f"current sub-gate is missing: {path}")

    artifacts = manifest.get("artifacts")
    if not isinstance(artifacts, dict):
        raise ManifestError("current artifact identity is missing")
    expected_zip = f"LetsMakeMoney-v{expected_version}-windows-x86_64.zip"
    if artifacts.get("zip_name") != expected_zip:
        raise ManifestError("current Zip filename does not match version")
    if artifacts.get("checksum_name") != "SHA256SUMS.txt":
        raise ManifestError("checksum filename contract drift")
    if artifacts.get("build_info_name") != "BUILD-INFO.json":
        raise ManifestError("BUILD-INFO filename contract drift")
    if artifacts.get("executable_name") != "LetsMakeMoney.exe":
        raise ManifestError("executable filename contract drift")


def classify_exit_code(exit_code: int) -> str:
    if exit_code == 0:
        return "passed"
    if exit_code in {130, -1073741510, 3221225786}:
        return "cancelled"
    return "failed"


def validate_repository(repo_root: Path, manifest_path: Path) -> None:
    manifest = load_json(manifest_path)
    lifecycle_document = load_json(repo_root / "scripts" / "script-lifecycle.json")
    if not isinstance(manifest, dict) or not isinstance(lifecycle_document, dict):
        raise ManifestError("manifest documents must be JSON objects")
    lifecycle = lifecycle_index(lifecycle_document)

    actual_scripts = {
        path.relative_to(repo_root).as_posix()
        for path in (repo_root / "scripts").glob("*.ps1")
    }
    indexed_scripts = set(lifecycle)
    if actual_scripts != indexed_scripts:
        missing = sorted(actual_scripts - indexed_scripts)
        stale = sorted(indexed_scripts - actual_scripts)
        raise ManifestError(f"script lifecycle coverage mismatch: missing={missing} stale={stale}")

    package = load_json(repo_root / "apps" / "windows-v1" / "package.json")
    defaults = load_json(repo_root / "apps" / "windows-v1" / "contracts" / "config-v8-defaults.json")
    if not isinstance(package, dict) or not isinstance(defaults, dict):
        raise ManifestError("package and defaults must be JSON objects")
    validate_manifest_data(
        manifest,
        lifecycle,
        str(package.get("version")),
        int(defaults.get("config_version", -1)),
        lambda path: (repo_root / PurePosixPath(path)).is_file(),
    )


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate the LetsMakeMoney current verification manifest")
    parser.add_argument("--repo-root", type=Path, required=True)
    parser.add_argument("--manifest", type=Path, required=True)
    args = parser.parse_args()
    try:
        validate_repository(args.repo_root.resolve(), args.manifest.resolve())
    except (ManifestError, json.JSONDecodeError, OSError, TypeError, ValueError) as error:
        print(f"FAIL current manifest: {error}")
        return 1
    print("PASS current manifest and script lifecycle")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
