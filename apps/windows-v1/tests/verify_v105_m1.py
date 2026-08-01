from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Any


APP_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = APP_ROOT.parents[1]
RELEASE_ROOT = REPO_ROOT / "doc" / "releases" / "v1.0.5"
EVIDENCE_PATH = RELEASE_ROOT / "evidence" / "m1-contract.json"
CONTRACT_ROOT = APP_ROOT / "tests" / "contracts"

OFFICIAL_V104_SHA256 = "C4F28892831891A4266C4D9B12D432CD5C970BB3C9B36A6B8DB21FA2566DE50E"
DIRTY_V104_SHA256 = "C67E730BF81741D03BFAF6D14F3F16EB74FD8591D8B3AB76D45A980E854C249B"
EXPECTED_DIRECTORIES = {
    (".artifacts/candidates/v1.0.5/<candidate-id>/", "build-task", False, "candidate"),
    (".artifacts/acceptance/v1.0.5/<candidate-id>/", "acceptance-task", False, "raw-evidence"),
    ("doc/releases/v1.0.5/evidence/<candidate-id>/", "documentation-task", True, "redacted-summary"),
    (".artifacts/published/v1.0.5/<tag>/<downloaded-at>/", "release-verification-task", False, "published-cache"),
    ("releases/v1.0.5/", "release-closing-task", False, "staging"),
}
EXPECTED_SCHEMAS = {
    "v105-build-info.schema.json",
    "v105-acceptance-summary.schema.json",
    "v105-raw-evidence-index.schema.json",
    "v105-published-cache-index.schema.json",
}


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        value = json.load(handle)
    require(isinstance(value, dict), f"{path.name} must contain a JSON object")
    return value


def git(*args: str, check: bool = True) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", *args],
        cwd=REPO_ROOT,
        text=True,
        encoding="utf-8",
        capture_output=True,
        check=check,
    )


def contains_sensitive_value(value: Any) -> bool:
    serialized = json.dumps(value, ensure_ascii=False)
    if re.search(r"(?i)[A-Z]:[\\/](?:Users|Work|codex)[\\/]", serialized):
        return True
    if isinstance(value, dict):
        for key, child in value.items():
            normalized = re.sub(r"[^a-z0-9]", "", str(key).lower())
            if normalized in {"token", "password", "privatekey", "secret"}:
                if child not in (None, "", "redacted", "[redacted]"):
                    return True
            if contains_sensitive_value(child):
                return True
    elif isinstance(value, list):
        return any(contains_sensitive_value(child) for child in value)
    return False


def validate_contract(value: dict[str, Any]) -> None:
    require(value.get("schema_version") == 1, "M1 schema version drift")
    require(value.get("milestone") == "V105-M1", "M1 milestone drift")
    require(value.get("release_version") == "1.0.5", "M1 release version drift")

    baseline = value["public_baseline"]
    require(baseline["version"] == "1.0.4", "public baseline version drift")
    require(baseline["tag"] == "v1.0.4", "public baseline tag drift")
    require(baseline["zip_sha256"] == OFFICIAL_V104_SHA256, "official v1.0.4 hash drift")

    directories = {
        (entry["path"], entry["owner"], entry["tracked"], entry["kind"])
        for entry in value["directories"]
    }
    require(directories == EXPECTED_DIRECTORIES, "artifact directory ownership drift")

    schema_names = {Path(path).name for path in value["schemas"]}
    require(schema_names == EXPECTED_SCHEMAS, "M1 schema inventory drift")

    candidate = value["candidate_contract"]
    require(candidate == {
        "allows_dirty": True,
        "requires_source_head": True,
        "requires_payload_hashes": True,
        "can_claim_published": False,
    }, "candidate contract drift")

    published = value["published_contract"]
    require(published == {
        "allows_dirty": False,
        "requires_tag_target_match": True,
        "requires_release_url_match": True,
        "requires_downloaded_zip_sha256": True,
        "requires_checksums_match": True,
    }, "published contract drift")

    evidence = value["evidence_contract"]
    require(evidence["repository_content"] == "redacted-summary-and-index-only", "repository evidence drift")
    require(evidence["raw_content"] == "external-owner-managed", "raw evidence policy drift")
    require(evidence["unique_copy_deletion_allowed"] is False, "unique evidence deletion must be denied")
    require(evidence["replacement_evidence_can_overwrite_history"] is False, "historical evidence overwrite must be denied")

    dirty = value["dirty_v104_candidate"]
    require(dirty["zip_sha256"] == DIRTY_V104_SHA256, "dirty candidate hash drift")
    require(dirty["deleted"] is False, "dirty candidate was marked deleted")
    require(dirty["deletion_authorized"] is False, "dirty candidate deletion is not authorized")
    require(dirty["published_cache_reverified"] is False, "published cache was not reverified in M1")
    require(dirty["disposition"] == "retained_pending_separate_authorization", "dirty candidate disposition drift")

    require(value["business_code_modified"] is False, "M1 business-code boundary drift")
    require(value["build_or_package_executed"] is False, "M1 must not build or package")
    require(not contains_sensitive_value(value), "M1 contract contains an absolute path or secret-like value")


def verify_required_files() -> None:
    required = [
        RELEASE_ROOT / "artifact-and-evidence-contract.md",
        RELEASE_ROOT / "evidence" / "README.md",
        EVIDENCE_PATH,
        APP_ROOT / "tests" / "verify_v105_package.py",
        APP_ROOT / "tests" / "verify_v105_package_tests.py",
        APP_ROOT / "tests" / "verify_v105_m1.py",
        APP_ROOT / "tests" / "verify_v105_m1_tests.py",
        REPO_ROOT / "scripts" / "verify_v105_package.ps1",
    ] + [CONTRACT_ROOT / name for name in EXPECTED_SCHEMAS]
    missing = [path.relative_to(REPO_ROOT).as_posix() for path in required if not path.is_file()]
    require(not missing, f"missing M1 contract files: {missing}")


def verify_contract_evidence() -> None:
    validate_contract(load_json(EVIDENCE_PATH))


def verify_schema_contracts() -> None:
    for name in EXPECTED_SCHEMAS:
        schema = load_json(CONTRACT_ROOT / name)
        require(schema.get("$schema") == "https://json-schema.org/draft/2020-12/schema", f"{name} draft drift")
        require(schema.get("type") == "object", f"{name} root type drift")
        require(schema.get("additionalProperties") is False, f"{name} must reject extra fields")
        require(isinstance(schema.get("required"), list) and schema["required"], f"{name} required fields missing")
    build = load_json(CONTRACT_ROOT / "v105-build-info.schema.json")
    for field in ("source_head", "source_tree_dirty", "build_timestamp_utc", "architecture"):
        require(field in build["required"], f"BUILD-INFO schema missing {field}")


def verify_directory_contract() -> None:
    ignored = (
        ".artifacts/candidates/v1.0.5/V105-probe/file.zip",
        ".artifacts/acceptance/v1.0.5/V105-probe/capture.png",
        ".artifacts/published/v1.0.5/v1.0.5/20260801T000000Z/file.zip",
        "releases/v1.0.5/file.zip",
    )
    for path in ignored:
        result = git("check-ignore", "-q", "--no-index", path, check=False)
        require(result.returncode == 0, f"artifact path is not ignored: {path}")
    evidence = "doc/releases/v1.0.5/evidence/V105-probe/summary.json"
    result = git("check-ignore", "-q", "--no-index", evidence, check=False)
    require(result.returncode == 1, "repository evidence path must remain trackable")
    tracked = git("ls-files", ".artifacts").stdout.strip()
    require(not tracked, f"local artifact directories must not be tracked: {tracked}")


def verify_verifier_surface() -> None:
    python_text = (APP_ROOT / "tests" / "verify_v105_package.py").read_text(encoding="utf-8")
    powershell_text = (REPO_ROOT / "scripts" / "verify_v105_package.ps1").read_text(encoding="utf-8")
    for marker in ("candidate", "published", "source_tree_dirty", "tag_target_commit", "expected_zip_sha256"):
        require(marker in python_text, f"Python package verifier missing {marker}")
    for marker in ('ValidateSet("candidate", "published")', "ExpectedSourceHead", "ExpectedZipSha256", "ChecksumsPath"):
        require(marker in powershell_text, f"PowerShell package verifier missing {marker}")


def verify_readme_facts() -> None:
    for relative in ("README.md", "README.en.md"):
        text = (REPO_ROOT / relative).read_text(encoding="utf-8")
        require("v1.0.4 Stable" in text, f"{relative} current public version drift")
        require("releases/tag/v1.0.4" in text, f"{relative} Release link drift")
        require("package_v104.ps1" in text and "verify_v104_package.ps1" in text, f"{relative} current commands drift")
        require("package_v103.ps1" not in text and "verify_v103_package.ps1" not in text, f"{relative} stale default command")
    app_readme = (APP_ROOT / "README.md").read_text(encoding="utf-8")
    require("当前公开版本为 v1.0.4 Stable" in app_readme, "application README version drift")
    require("scripts\\verify_v104.ps1" in app_readme, "application README verification command drift")


def verify_dirty_candidate_retained() -> None:
    m0 = load_json(RELEASE_ROOT / "evidence" / "m0-baseline.json")
    relative = m0["local_dirty_candidate"]["path"]
    candidate = REPO_ROOT / relative
    require(candidate.is_file(), "dirty v1.0.4 candidate must remain present in M1")
    require(m0["local_dirty_candidate"]["deleted"] is False, "M0 dirty candidate state drift")


def verify_business_code_unchanged() -> None:
    status = git(
        "status",
        "--porcelain",
        "--untracked-files=all",
        "--",
        "apps/windows-v1/src",
        "apps/windows-v1/src-tauri/src",
    ).stdout.strip()
    require(not status, f"M1 business code changed unexpectedly: {status}")


def main() -> int:
    checks = [
        verify_required_files,
        verify_contract_evidence,
        verify_schema_contracts,
        verify_directory_contract,
        verify_verifier_surface,
        verify_readme_facts,
        verify_dirty_candidate_retained,
        verify_business_code_unchanged,
    ]
    try:
        for check in checks:
            check()
            print(f"PASS {check.__name__}")
    except (AssertionError, KeyError, TypeError, OSError, UnicodeDecodeError, json.JSONDecodeError, subprocess.CalledProcessError) as error:
        print(f"FAIL {error}", file=sys.stderr)
        return 1
    print(f"PASS v1.0.5 M1 contracts ({len(checks)} checks)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
