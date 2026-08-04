from __future__ import annotations

import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path


APP_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = APP_ROOT.parents[1]
BASELINE_PATH = REPO_ROOT / "doc" / "releases" / "v1.0.7" / "evidence" / "m0-baseline.json"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def read(relative: str) -> str:
    return (REPO_ROOT / relative).read_text(encoding="utf-8")


def load(relative: str) -> dict:
    return json.loads(read(relative))


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest().upper()


def git(*args: str) -> str:
    return subprocess.check_output(
        ["git", *args], cwd=REPO_ROOT, text=True, encoding="utf-8"
    ).strip()


def verify_baseline() -> None:
    baseline = json.loads(BASELINE_PATH.read_text(encoding="utf-8"))
    require(baseline["schema_version"] == 1, "baseline schema drift")
    require(baseline["milestone"] == "V107-M0", "baseline milestone drift")
    require(git("branch", "--show-current") == baseline["git"]["branch"], "branch drift")
    require(git("rev-parse", "HEAD") == baseline["git"]["baseline_head"], "M0 HEAD drift")
    require(
        git("rev-parse", "origin/main") == baseline["git"]["origin_main"],
        "origin/main drift",
    )
    require(
        git("rev-parse", "v1.0.6^{}") == baseline["published_release"]["source_commit"],
        "v1.0.6 release commit drift",
    )
    for contract in baseline["frozen_contracts"]:
        path = REPO_ROOT / contract["path"]
        require(path.is_file(), f"frozen contract missing: {contract['path']}")
        require(path.stat().st_size == contract["size"], f"size drift: {contract['path']}")
        require(sha256(path) == contract["sha256"], f"hash drift: {contract['path']}")


def verify_config_red_light() -> None:
    rust = read("apps/windows-v1/src-tauri/src/config.rs")
    domain = read("apps/windows-v1/src/domain/configuration.ts")
    defaults = load("apps/windows-v1/contracts/config-v102-defaults.json")
    schema = load("apps/windows-v1/contracts/config-v102.schema.json")
    require("CURRENT_CONFIG_VERSION: u32 = 8" in rust, "Rust config version drift")
    require("CURRENT_CONFIG_VERSION = 8 as const" in domain, "TypeScript config version drift")
    require(defaults["config_version"] == 8, "defaults config version drift")
    require(defaults["mini_edge_auto_hide"] is True, "Mini privacy default drift")
    require(defaults["mini_edge_dock"] == "none", "Mini dock default drift")
    required = set(schema.get("required", []))
    properties = set(schema.get("properties", {}))
    require("mini_edge_auto_hide" not in required, "M0 schema red light closed without M1")
    require("mini_edge_dock" not in required, "M0 schema red light closed without M1")
    require("mini_edge_auto_hide" not in properties, "M0 schema properties unexpectedly changed")
    require("mini_edge_dock" not in properties, "M0 schema properties unexpectedly changed")
    for marker in ("pub fn migrate_v5", "pub fn migrate_v6", "pub fn migrate_v7"):
        require(marker in rust, f"missing migration marker: {marker}")
    for version in (5, 6, 7):
        require(
            f"Some({version}) => migrate_v{version}(source)" in rust,
            f"migration dispatcher missing v{version}",
        )


def verify_current_red_lights() -> None:
    workflow = read(".github/workflows/windows-v1-verify.yml")
    require("v1.0.3" in workflow and "verify_v104.ps1" in workflow, "CI drift was not captured")
    runner = read("scripts/verify_architecture.ps1")
    require(
        "mini-edge-auto-hide.m2-characterization.behavior.ts" not in runner,
        "historical red test must not be in the passing architecture gate",
    )
    require(
        (APP_ROOT / "tests" / "mini-edge-auto-hide.m2-characterization.behavior.ts").is_file(),
        "historical characterization evidence missing",
    )
    rust = read("apps/windows-v1/src-tauri/src/lib.rs")
    move_match = re.search(
        r"fn move_app_window[\s\S]{0,2500}?safe_window_position\(&window\)", rust
    )
    require(move_match is not None, "current per-frame drag clamp red light drift")
    source_files = list((APP_ROOT / "src").rglob("*.ts")) + list((APP_ROOT / "src").rglob("*.tsx"))
    source_files += list((APP_ROOT / "src-tauri" / "src").rglob("*.rs"))
    source_text = "\n".join(path.read_text(encoding="utf-8") for path in source_files)
    require("OvertimeRecord" not in source_text, "overtime domain appeared before M3")


def verify_fixtures() -> None:
    windows = load("apps/windows-v1/tests/fixtures/v107-m0-window-characterization.json")
    overtime = load("apps/windows-v1/tests/fixtures/v107-date-overtime-vectors.json")
    calendar = load("apps/windows-v1/tests/fixtures/v107-calendar-dpi-matrix.json")
    require(len(windows["mini_workbench_entry_states"]) == 4, "window state matrix incomplete")
    require(len(windows["auto_hide_states"]) == 6, "auto-hide matrix incomplete")
    require(len(overtime["hour_vectors"]) == 7, "overtime precision matrix incomplete")
    require(len(overtime["transaction_vectors"]) == 9, "overtime transaction matrix incomplete")
    require(len(overtime["shared_date_override_vectors"]) == 7, "date transaction matrix incomplete")
    require(len(calendar["scenarios"]) == 12, "calendar DPI matrix must contain 12 cases")
    require({item["dpi"] for item in calendar["scenarios"]} == {100, 125, 150}, "DPI set drift")
    require({item["theme"] for item in calendar["scenarios"]} == {"light", "dark"}, "theme set drift")
    require({item["weeks"] for item in calendar["scenarios"]} == {5, 6}, "week set drift")


def verify_scope() -> None:
    status = git("status", "--short").splitlines()
    forbidden = (
        "apps/windows-v1/src/",
        "apps/windows-v1/src-tauri/src/",
        "apps/windows-v1/package.json",
        "apps/windows-v1/package-lock.json",
        "apps/windows-v1/src-tauri/Cargo.toml",
        "apps/windows-v1/src-tauri/Cargo.lock",
    )
    for line in status:
        path = line[3:].replace("\\", "/")
        require(not path.startswith(forbidden), f"M0 changed product/build code: {path}")


def verify_no_local_paths_in_json() -> None:
    json_files = [BASELINE_PATH]
    json_files.extend((APP_ROOT / "tests" / "fixtures").glob("v107-*.json"))
    local_path = re.compile(r"(?:(?<![A-Za-z0-9])[A-Za-z]:[\\/]|/Users/|/home/)")
    for path in json_files:
        text = path.read_text(encoding="utf-8")
        require(local_path.search(text) is None, f"local absolute path leaked: {path.name}")


def main() -> int:
    verify_baseline()
    verify_config_red_light()
    verify_current_red_lights()
    verify_fixtures()
    verify_scope()
    verify_no_local_paths_in_json()
    print("v1.0.7 M0 baseline verification passed (7 evidence groups).")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (AssertionError, OSError, subprocess.CalledProcessError, json.JSONDecodeError) as error:
        print(f"v1.0.7 M0 baseline verification failed: {error}", file=sys.stderr)
        raise SystemExit(1)
