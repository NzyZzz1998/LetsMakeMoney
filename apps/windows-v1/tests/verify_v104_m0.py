from __future__ import annotations

import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Any


APP_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = APP_ROOT.parents[1]
FIXTURES = APP_ROOT / "tests" / "fixtures"
RELEASE_ROOT = REPO_ROOT / "doc" / "releases" / "v1.0.4"
EVIDENCE_PATH = RELEASE_ROOT / "evidence" / "m0-baseline.json"
GEOMETRY_PATH = FIXTURES / "v104-mini-edge-geometry.json"
COMPATIBILITY_PATH = FIXTURES / "v104-config-compatibility.json"

EXPECTED_RELEASE_COMMIT = "87f6766a33fd6ff284f0fb3a42dc18c5a7292bf4"
EXPECTED_ZIP_SHA256 = "259CAE23D785FC7712CAC0EFD42991C8EE210C0BCEA1EB5C07FC171DFB993B28"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        value = json.load(handle)
    require(isinstance(value, dict), f"{path.name} must contain a JSON object")
    return value


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def contains_unredacted_secret(value: Any) -> bool:
    if isinstance(value, dict):
        for key, child in value.items():
            normalized = re.sub(r"[^a-z0-9]", "", str(key).lower())
            if normalized in {"token", "password", "privatekey"}:
                if child not in (None, "", "redacted", "[redacted]"):
                    return True
            if contains_unredacted_secret(child):
                return True
        return False
    if isinstance(value, list):
        return any(contains_unredacted_secret(child) for child in value)
    return False


def verify_required_files() -> None:
    required = [
        RELEASE_ROOT / "m0-baseline.md",
        RELEASE_ROOT / "evidence" / "README.md",
        EVIDENCE_PATH,
        GEOMETRY_PATH,
        COMPATIBILITY_PATH,
        APP_ROOT / "src-tauri" / "src" / "platform.rs",
        APP_ROOT / "src-tauri" / "src" / "config.rs",
        REPO_ROOT / "scripts" / "verify_v104.ps1",
    ]
    missing = [
        path.relative_to(REPO_ROOT).as_posix()
        for path in required
        if not path.is_file()
    ]
    require(not missing, f"missing v1.0.4 M0 files: {missing}")


def validate_evidence(evidence: dict[str, Any]) -> None:
    require(evidence.get("schema_version") == 1, "unsupported evidence schema")
    require(evidence.get("milestone") == "V104-M0", "evidence milestone drift")
    git = evidence["git"]
    require(git["branch"] == "main", "M0 branch must be main")
    require(
        git["development_head"] == "09f838d05c67efb5219437ec2208920e441f3f52",
        "M0 development baseline drift",
    )
    require(git["release_commit"] == EXPECTED_RELEASE_COMMIT, "release commit drift")

    payload = evidence["release_payload"]
    require(payload["zip"]["sha256"] == EXPECTED_ZIP_SHA256, "release Zip hash drift")
    require(
        payload["build_info"]["source_head"] == EXPECTED_RELEASE_COMMIT,
        "BUILD-INFO source does not match release commit",
    )
    require(
        payload["build_info"]["source_tree_dirty"] is False,
        "release BUILD-INFO must describe a clean tree",
    )

    decisions = evidence["decisions"]
    require(
        decisions["mini_edge_state_storage"] == "config_v8_optional_fields",
        "M0 storage decision drift",
    )
    require(
        decisions["window_state_json_required"] is False,
        "window-state.json must not be introduced after compatibility passed",
    )
    require(
        decisions["normal_position_persistence"] == "expanded_only",
        "normal position contract drift",
    )
    require(
        decisions["retracted_position_persistence"] == "never",
        "retracted position must never be persisted",
    )

    rust = evidence["rust_comparison"]
    require(
        rust["stable"]["rustc"] == rust["fixed"]["rustc"],
        "stable/fixed Rust identities differ",
    )
    require(
        rust["decision"] == "pin_exact_1.97.1_in_M3",
        "Rust pin decision drift",
    )

    inherited = evidence["inherited_evidence"]
    require(inherited["FR-007"]["status"] == "inherited", "FR-007 baseline drift")
    require(inherited["FR-009"]["status"] == "inherited", "FR-009 baseline drift")

    serialized = json.dumps(evidence, ensure_ascii=False)
    require(
        not re.search(r"(?i)[A-Z]:[\\/](?:Users|Work|codex)[\\/]", serialized),
        "evidence contains a local absolute path",
    )
    require(
        not contains_unredacted_secret(evidence),
        "evidence may contain a secret value",
    )


def verify_evidence() -> None:
    validate_evidence(load_json(EVIDENCE_PATH))


def verify_geometry_fixture() -> None:
    fixture = load_json(GEOMETRY_PATH)
    contract = fixture["contract"]
    require(contract["dock_threshold_logical_px"] == 16, "dock threshold drift")
    require(contract["privacy_tab_logical_px"] == 10, "privacy tab width drift")
    require(contract["undock_threshold_logical_px"] == 24, "undock threshold drift")
    require(contract["fallback_margin_logical_px"] == 12, "fallback margin drift")
    dock_ids = {item["id"] for item in fixture["dock_cases"]}
    require(
        {
            "right-edge-100-taskbar-work-area",
            "left-edge-125-negative-monitor",
            "right-edge-150-taskbar-work-area",
            "center-does-not-dock",
        }
        <= dock_ids,
        "work-area/DPI geometry matrix is incomplete",
    )
    require(len(fixture["fallback_cases"]) >= 2, "monitor fallback matrix is incomplete")
    require(len(fixture["undock_cases"]) >= 2, "undock threshold matrix is incomplete")


def verify_config_compatibility_fixture() -> None:
    fixture = load_json(COMPATIBILITY_PATH)
    config = fixture["config"]
    behavior = fixture["expected_legacy_behavior"]
    decision = fixture["decision"]
    require(config["config_version"] == 8, "compatibility fixture must remain config v8")
    require(config["mini_edge_auto_hide"] is False, "fixture must exercise a non-default toggle")
    require(config["mini_edge_dock"] == "left", "fixture must exercise a persisted dock side")
    require(behavior["read_succeeds"] is True, "v1.0.3 read must succeed")
    require(behavior["save_succeeds"] is True, "v1.0.3 save must succeed")
    require(
        set(behavior["unknown_fields_are_dropped"])
        == {"mini_edge_auto_hide", "mini_edge_dock"},
        "legacy unknown-field contract drift",
    )
    require(
        decision["storage"] == "config_v8_optional_fields",
        "fixture storage decision drift",
    )
    require(
        decision["window_state_json_required"] is False,
        "fixture unexpectedly requires window-state.json",
    )


def verify_release_identity() -> None:
    zip_path = REPO_ROOT / "releases" / "v1.0.3" / "LetsMakeMoney-v1.0.3-windows-x86_64.zip"
    require(zip_path.is_file(), "v1.0.3 release Zip is missing")
    require(sha256(zip_path) == EXPECTED_ZIP_SHA256, "local v1.0.3 Zip hash mismatch")
    release_commit = subprocess.check_output(
        ["git", "rev-parse", "v1.0.3^{}"],
        cwd=REPO_ROOT,
        text=True,
        encoding="utf-8",
    ).strip()
    require(release_commit == EXPECTED_RELEASE_COMMIT, "v1.0.3 tag target drift")


def main() -> int:
    checks = [
        verify_required_files,
        verify_evidence,
        verify_geometry_fixture,
        verify_config_compatibility_fixture,
        verify_release_identity,
    ]
    try:
        for check in checks:
            check()
            print(f"PASS {check.__name__}")
    except (
        AssertionError,
        KeyError,
        TypeError,
        json.JSONDecodeError,
        subprocess.CalledProcessError,
    ) as error:
        print(f"FAIL {error}", file=sys.stderr)
        return 1
    print(f"PASS v1.0.4 M0 contracts ({len(checks)} checks)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
