from __future__ import annotations

import hashlib
import json
import re
import subprocess
import sys
import zipfile
from pathlib import Path
from typing import Any


APP_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = APP_ROOT.parents[1]
RELEASE_ROOT = REPO_ROOT / "doc" / "releases" / "v1.0.5"
EVIDENCE_PATH = RELEASE_ROOT / "evidence" / "m0-baseline.json"

EXPECTED_DEVELOPMENT_HEAD = "8a63da7836fb24c3b7f8ff12f896ac40571adeb7"
EXPECTED_RELEASE_TAG_OBJECT = "2e4fec17520524ac1e53a4e1bc993448d9255981"
EXPECTED_RELEASE_COMMIT = "4d06dc73dbc5c27d7a97462d8262a553dd97d5b6"
EXPECTED_OFFICIAL_ZIP_SHA256 = (
    "C4F28892831891A4266C4D9B12D432CD5C970BB3C9B36A6B8DB21FA2566DE50E"
)
EXPECTED_LOCAL_ZIP_SHA256 = (
    "C67E730BF81741D03BFAF6D14F3F16EB74FD8591D8B3AB76D45A980E854C249B"
)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        value = json.load(handle)
    require(isinstance(value, dict), f"{path.name} must contain a JSON object")
    return value


def sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest().upper()


def sha256(path: Path) -> str:
    return sha256_bytes(path.read_bytes())


def contains_unredacted_secret(value: Any) -> bool:
    if isinstance(value, dict):
        for key, child in value.items():
            normalized = re.sub(r"[^a-z0-9]", "", str(key).lower())
            if normalized in {"token", "password", "privatekey", "secret"}:
                if child not in (None, "", "redacted", "[redacted]"):
                    return True
            if contains_unredacted_secret(child):
                return True
        return False
    if isinstance(value, list):
        return any(contains_unredacted_secret(child) for child in value)
    return False


def git_text(*args: str) -> str:
    return subprocess.check_output(
        ["git", *args],
        cwd=REPO_ROOT,
        text=True,
        encoding="utf-8",
    ).strip()


def verify_required_files() -> None:
    required = [
        RELEASE_ROOT / "prd.md",
        RELEASE_ROOT / "traceability.md",
        RELEASE_ROOT / "dev_plan_v1.0.5.md",
        RELEASE_ROOT / "progress_v1.0.5.md",
        RELEASE_ROOT / "m0-baseline.md",
        RELEASE_ROOT / "fr004-reproduction-contract.md",
        RELEASE_ROOT / "evidence-matrix.md",
        RELEASE_ROOT / "verification.md",
        RELEASE_ROOT / "evidence" / "README.md",
        EVIDENCE_PATH,
        REPO_ROOT / "doc" / "logs" / "dev_log_v1.0.5.md",
        REPO_ROOT / "doc" / "current.md",
        REPO_ROOT / "scripts" / "verify_v105.ps1",
        APP_ROOT / "tests" / "verify_v105_m0.py",
        APP_ROOT / "tests" / "verify_v105_m0_tests.py",
    ]
    missing = [
        path.relative_to(REPO_ROOT).as_posix()
        for path in required
        if not path.is_file()
    ]
    require(not missing, f"missing v1.0.5 M0 files: {missing}")


def validate_evidence(evidence: dict[str, Any]) -> None:
    require(evidence.get("schema_version") == 1, "unsupported evidence schema")
    require(evidence.get("milestone") == "V105-M0", "evidence milestone drift")

    git = evidence["git"]
    require(git["branch"] == "main", "M0 branch must be main")
    require(
        git["development_head"] == EXPECTED_DEVELOPMENT_HEAD,
        "M0 development baseline drift",
    )
    require(git["remote_main"] == EXPECTED_DEVELOPMENT_HEAD, "remote main drift")
    require(git["release_tag"] == "v1.0.4", "release tag drift")
    require(
        git["release_tag_object"] == EXPECTED_RELEASE_TAG_OBJECT,
        "release tag object drift",
    )
    require(git["release_commit"] == EXPECTED_RELEASE_COMMIT, "release commit drift")
    require(git["business_code_modified"] is False, "business code must be unchanged")

    official = evidence["official_release"]
    require(official["draft"] is False, "official release cannot be a draft")
    require(official["prerelease"] is False, "official release cannot be a prerelease")
    require(
        official["zip"]["sha256"] == EXPECTED_OFFICIAL_ZIP_SHA256,
        "official release Zip hash drift",
    )
    require(
        official["build_info"]["source_head"] == EXPECTED_RELEASE_COMMIT,
        "official BUILD-INFO source drift",
    )
    require(
        official["build_info"]["source_tree_dirty"] is False,
        "official BUILD-INFO must describe a clean tree",
    )

    local = evidence["local_dirty_candidate"]
    require(local["deleted"] is False, "dirty candidate must not be deleted in M0")
    require(
        local["disposition"] == "retained_pending_separate_authorization",
        "dirty candidate disposition drift",
    )
    require(
        local["zip"]["sha256"] == EXPECTED_LOCAL_ZIP_SHA256,
        "local dirty candidate Zip hash drift",
    )
    require(
        local["build_info"]["source_tree_dirty"] is True,
        "local candidate must retain its dirty identity",
    )
    require(
        local["zip"]["sha256"] != official["zip"]["sha256"],
        "local dirty candidate was confused with the official asset",
    )
    require(
        local["build_info"]["source_head"]
        != official["build_info"]["source_head"],
        "local and official source identities must remain distinct",
    )
    require(
        local["executable"]["sha256"] != official["executable"]["sha256"],
        "local and official executable identities must remain distinct",
    )

    decisions = evidence["decisions"]
    require(decisions["prd_confirmed"] is True, "PRD decision drift")
    require(
        decisions["calendar_today_scheme"]
        == "A_top_left_today_badge_and_bold_date",
        "calendar today scheme drift",
    )
    require(decisions["fr004_reproduction_runs"] == 20, "FR-004 run count drift")
    require(
        decisions["fr004_zero_reproduction_outcome"]
        == "do_not_implement_keep_observation",
        "FR-004 zero-reproduction route drift",
    )
    require(
        decisions["fr008_surface_gate"] == "real_tauri_shell_required",
        "FR-008 real-shell gate drift",
    )
    require(
        decisions["fr008_failure_outcome"] == "retain_v1.0.4_surface",
        "FR-008 rollback decision drift",
    )
    require(
        decisions["dirty_candidate_deletion_authorized"] is False,
        "dirty candidate deletion was not authorized",
    )

    mini = evidence["mini_baseline"]
    require(
        mini["phases"] == ["expanded", "retract_pending", "retracted"],
        "Mini phase baseline drift",
    )
    require(mini["retract_delay_ms"] == 600, "Mini retract delay drift")
    require(mini["transition_ms"] == 180, "Mini transition drift")
    require(mini["dock_threshold_logical_px"] == 16, "dock threshold drift")
    require(mini["privacy_tab_logical_px"] == 10, "v1.0.4 tab width drift")
    require(mini["undock_threshold_logical_px"] == 24, "undock threshold drift")
    require(mini["fallback_margin_logical_px"] == 12, "fallback margin drift")
    require(mini["config_version"] == 8, "configuration baseline drift")
    require(
        set(mini["confirmed_gaps"])
        == {
            "drag completion does not provide release-time pointer intent",
            "drag completion retains stale pointerInside",
            "browser focus and explicit lmm:window-shown share reveal handling",
        },
        "Mini confirmed gap set drift",
    )

    fr = evidence["fr_baseline"]
    require(set(fr) == {f"FR-{index:03d}" for index in range(1, 11)}, "FR map drift")

    contract = evidence["evidence_contract"]
    require(contract["mini_matrix_count"] == 24, "Mini evidence matrix count drift")
    require(set(contract["themes"]) == {"light", "dark"}, "theme matrix drift")
    require(set(contract["dpi"]) == {100, 125, 150}, "DPI matrix drift")
    require(set(contract["edges"]) == {"left", "right"}, "edge matrix drift")

    serialized = json.dumps(evidence, ensure_ascii=False)
    require(
        not re.search(r"(?i)[A-Z]:[\\/](?:Users|Work|codex)[\\/]", serialized),
        "evidence contains a local absolute path",
    )
    require(not contains_unredacted_secret(evidence), "evidence may contain a secret value")


def verify_evidence() -> None:
    validate_evidence(load_json(EVIDENCE_PATH))


def verify_git_identity() -> None:
    require(git_text("branch", "--show-current") == "main", "current branch drift")
    require(git_text("rev-parse", "HEAD") == EXPECTED_DEVELOPMENT_HEAD, "current HEAD drift")
    require(
        git_text("rev-parse", "refs/remotes/origin/main") == EXPECTED_DEVELOPMENT_HEAD,
        "local origin/main tracking ref drift",
    )
    require(
        git_text("rev-parse", "v1.0.4") == EXPECTED_RELEASE_TAG_OBJECT,
        "v1.0.4 tag object drift",
    )
    require(
        git_text("rev-parse", "v1.0.4^{}") == EXPECTED_RELEASE_COMMIT,
        "v1.0.4 tag target drift",
    )


def find_single_member(names: list[str], suffix: str) -> str:
    matches = [name for name in names if name.endswith(suffix)]
    require(len(matches) == 1, f"expected one {suffix} in candidate, found {matches}")
    return matches[0]


def verify_local_dirty_candidate() -> None:
    evidence = load_json(EVIDENCE_PATH)["local_dirty_candidate"]
    zip_path = REPO_ROOT / evidence["path"]
    checksums_path = REPO_ROOT / evidence["checksums"]["path"]
    require(zip_path.is_file(), "local dirty candidate Zip is missing")
    require(checksums_path.is_file(), "local dirty candidate SHA256SUMS is missing")
    require(zip_path.stat().st_size == evidence["zip"]["size"], "local Zip size drift")
    require(sha256(zip_path) == evidence["zip"]["sha256"], "local Zip hash mismatch")
    require(
        checksums_path.stat().st_size == evidence["checksums"]["size"],
        "local SHA256SUMS size drift",
    )
    require(
        sha256(checksums_path) == evidence["checksums"]["sha256"],
        "local SHA256SUMS hash drift",
    )
    require(
        evidence["zip"]["sha256"] in checksums_path.read_text(encoding="utf-8").upper(),
        "local SHA256SUMS does not name the local candidate hash",
    )

    with zipfile.ZipFile(zip_path) as archive:
        names = archive.namelist()
        build_name = find_single_member(names, "/BUILD-INFO.json")
        exe_name = find_single_member(names, "/LetsMakeMoney.exe")
        loader_name = find_single_member(names, "/WebView2Loader.dll")
        build_bytes = archive.read(build_name)
        build_info = json.loads(build_bytes.decode("utf-8-sig"))
        require(
            sha256_bytes(build_bytes) == evidence["build_info"]["sha256"],
            "local BUILD-INFO hash drift",
        )
        require(build_info["version"] == evidence["build_info"]["version"], "version drift")
        require(build_info["channel"] == evidence["build_info"]["channel"], "channel drift")
        require(
            build_info["source_head"] == evidence["build_info"]["source_head"],
            "local BUILD-INFO source drift",
        )
        require(build_info["source_tree_dirty"] is True, "local BUILD-INFO lost dirty state")
        exe_bytes = archive.read(exe_name)
        require(len(exe_bytes) == evidence["executable"]["size"], "local EXE size drift")
        require(
            sha256_bytes(exe_bytes) == evidence["executable"]["sha256"],
            "local EXE hash drift",
        )
        loader_bytes = archive.read(loader_name)
        require(
            len(loader_bytes) == evidence["webview2_loader"]["size"],
            "local WebView2Loader size drift",
        )
        require(
            sha256_bytes(loader_bytes) == evidence["webview2_loader"]["sha256"],
            "local WebView2Loader hash drift",
        )


def verify_document_contracts() -> None:
    baseline = (RELEASE_ROOT / "m0-baseline.md").read_text(encoding="utf-8")
    reproduction = (RELEASE_ROOT / "fr004-reproduction-contract.md").read_text(
        encoding="utf-8"
    )
    matrix = (RELEASE_ROOT / "evidence-matrix.md").read_text(encoding="utf-8")
    verification = (RELEASE_ROOT / "verification.md").read_text(encoding="utf-8")

    require("方案 A：左上“今”角标 + 日期数字加粗" in baseline, "scheme A not frozen")
    require("业务代码 | 未修改" in baseline, "business-code boundary missing")
    runs = re.findall(r"^\| (0[1-9]|1[0-9]|20) \|", reproduction, re.MULTILINE)
    require(runs == [f"{index:02d}" for index in range(1, 21)], "FR-004 table drift")
    matrix_ids = set(re.findall(r"V105-EVM-(\d{3})", matrix))
    require(matrix_ids == {f"{index:03d}" for index in range(1, 25)}, "evidence matrix drift")
    require("FR-008 即回退 v1.0.4 表面" in matrix, "FR-008 rollback text missing")
    require(
        "source HEAD" in verification and "整套候选自动与 GUI 证据失效" in verification,
        "candidate invalidation rule missing",
    )
    require("未执行 FR-004 的 20 次真实桌面操作" in verification, "M0 scope guard missing")


def verify_business_code_unchanged() -> None:
    status = git_text(
        "status",
        "--porcelain",
        "--untracked-files=all",
        "--",
        "apps/windows-v1/src",
        "apps/windows-v1/src-tauri/src",
    )
    require(not status, f"M0 business code changed unexpectedly: {status}")


def main() -> int:
    checks = [
        verify_required_files,
        verify_evidence,
        verify_git_identity,
        verify_local_dirty_candidate,
        verify_document_contracts,
        verify_business_code_unchanged,
    ]
    try:
        for check in checks:
            check()
            print(f"PASS {check.__name__}")
    except (
        AssertionError,
        KeyError,
        TypeError,
        OSError,
        UnicodeDecodeError,
        json.JSONDecodeError,
        zipfile.BadZipFile,
        subprocess.CalledProcessError,
    ) as error:
        print(f"FAIL {error}", file=sys.stderr)
        return 1
    print(f"PASS v1.0.5 M0 contracts ({len(checks)} checks)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
