from __future__ import annotations

import importlib.util
import json
import re
import sys
from copy import deepcopy
from pathlib import Path


APP_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = APP_ROOT.parents[1]
CONTRACTS = APP_ROOT / "contracts"
FIXTURES = APP_ROOT / "tests" / "fixtures"
SCRIPTS = REPO_ROOT / "scripts"


def load_json(path: Path) -> object:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def load_manifest_module():
    path = SCRIPTS / "verify_current_manifest.py"
    spec = importlib.util.spec_from_file_location("verify_current_manifest", path)
    require(spec is not None and spec.loader is not None, "Cannot load current manifest validator")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def extract_typescript_interface_fields(source: str) -> set[str]:
    match = re.search(r"export interface AppConfig \{(?P<body>.*?)^\}", source, re.MULTILINE | re.DOTALL)
    require(match is not None, "TypeScript AppConfig interface is missing")
    return set(re.findall(r"^\s{2}([a-z][a-z0-9_]*)(?:\?)?:", match.group("body"), re.MULTILINE))


def extract_typescript_default_fields(source: str) -> set[str]:
    match = re.search(r"export const defaultConfig: AppConfig = \{(?P<body>.*?)^\};", source, re.MULTILINE | re.DOTALL)
    require(match is not None, "TypeScript defaultConfig is missing")
    return set(re.findall(r"^\s{2}([a-z][a-z0-9_]*):", match.group("body"), re.MULTILINE))


def extract_rust_config_fields(source: str) -> set[str]:
    match = re.search(r"pub struct AppConfig \{(?P<body>.*?)^\}", source, re.MULTILINE | re.DOTALL)
    require(match is not None, "Rust AppConfig struct is missing")
    return set(re.findall(r"^\s{4}pub ([a-z][a-z0-9_]*):", match.group("body"), re.MULTILINE))


def verify_current_manifest_and_negative_cases() -> None:
    module = load_manifest_module()
    manifest = load_json(SCRIPTS / "current-manifest.json")
    lifecycle_document = load_json(SCRIPTS / "script-lifecycle.json")
    require(isinstance(manifest, dict) and isinstance(lifecycle_document, dict), "Current documents must be objects")
    lifecycle = module.lifecycle_index(lifecycle_document)
    module.validate_repository(REPO_ROOT, SCRIPTS / "current-manifest.json")

    def exists(path: str) -> bool:
        return (REPO_ROOT / path).is_file()

    negative_cases: list[tuple[str, dict, object]] = []
    wrong_version = deepcopy(manifest)
    wrong_version["version"] = "1.0.6"
    negative_cases.append(("wrong version", wrong_version, exists))

    historical_gate = deepcopy(manifest)
    historical_gate["gates"][0] = {
        "id": "historical",
        "path": "scripts/verify_v106.ps1",
        "lifecycle": "historical",
    }
    negative_cases.append(("historical gate", historical_gate, exists))

    missing_gate = deepcopy(manifest)
    missing_gate["gates"][0]["path"] = "scripts/verify_v107_missing.ps1"
    negative_cases.append(("missing gate", missing_gate, lambda path: False if path.endswith("missing.ps1") else exists(path)))

    for label, candidate, file_exists in negative_cases:
        try:
            module.validate_manifest_data(candidate, lifecycle, "1.0.7", 8, file_exists)
        except module.ManifestError:
            continue
        raise AssertionError(f"Current manifest negative case was accepted: {label}")

    require(module.classify_exit_code(0) == "passed", "Zero exit code classification drift")
    require(module.classify_exit_code(1) == "failed", "Failure exit code classification drift")
    require(module.classify_exit_code(130) == "cancelled", "Cancelled gate must remain cancelled")


def verify_config_v8_alignment() -> None:
    schema = load_json(CONTRACTS / "config-v8.schema.json")
    defaults = load_json(CONTRACTS / "config-v8-defaults.json")
    require(isinstance(schema, dict) and isinstance(defaults, dict), "Canonical config contract must be objects")
    required = set(schema["required"])
    properties = set(schema["properties"])
    default_keys = set(defaults)
    require(required == properties == default_keys, "Config v8 schema/default key sets differ")
    require(defaults["config_version"] == 8, "Canonical defaults must target config v8")
    require(schema["properties"]["config_version"]["const"] == 8, "Canonical schema must target config v8")

    ts_source = (APP_ROOT / "src" / "domain" / "configuration.ts").read_text(encoding="utf-8")
    rust_source = (APP_ROOT / "src-tauri" / "src" / "config.rs").read_text(encoding="utf-8")
    require(extract_typescript_interface_fields(ts_source) == default_keys, "TypeScript AppConfig differs from config v8")
    require(extract_typescript_default_fields(ts_source) == default_keys, "TypeScript defaults differ from config v8")
    require(extract_rust_config_fields(rust_source) == default_keys, "Rust AppConfig differs from config v8")
    require(re.search(r"CURRENT_CONFIG_VERSION:\s*u32\s*=\s*8", rust_source) is not None, "Rust config version drift")
    require("CURRENT_CONFIG_VERSION = 8 as const" in ts_source, "TypeScript config version drift")
    require('config-v8-defaults.json' in rust_source, "Rust defaults must use the canonical config v8 document")
    require('config-v102-defaults.json' not in rust_source, "Rust must not treat a release-named defaults file as current")

    for migration in ("migrate_v5", "migrate_v6", "migrate_v7", "migrate_to_current"):
        require(f"fn {migration}" in rust_source, f"Missing config migration: {migration}")
    for behavior in (
        "failed_writes_preserve_old_config_and_draft",
        "unchanged_and_success_are_distinct",
        "migration_dispatcher_accepts_every_declared_legacy_version",
        "invalid_v8_theme_falls_back_and_is_persisted",
    ):
        require(behavior in rust_source.lower(), f"Missing config protection evidence: {behavior}")


def verify_version_identity() -> None:
    package = load_json(APP_ROOT / "package.json")
    package_lock = load_json(APP_ROOT / "package-lock.json")
    tauri = load_json(APP_ROOT / "src-tauri" / "tauri.conf.json")
    manifest = load_json(SCRIPTS / "current-manifest.json")
    cargo = (APP_ROOT / "src-tauri" / "Cargo.toml").read_text(encoding="utf-8")
    cargo_lock = (APP_ROOT / "src-tauri" / "Cargo.lock").read_text(encoding="utf-8")
    app_source = (APP_ROOT / "src" / "App.tsx").read_text(encoding="utf-8")
    service_source = (APP_ROOT / "src" / "services" / "versionService.ts").read_text(encoding="utf-8")
    window_capability = load_json(APP_ROOT / "src-tauri" / "capabilities" / "mini-window.json")
    version = "1.0.7"

    require(package["version"] == version, "package version drift")
    require(package_lock["version"] == version, "package-lock root version drift")
    require(package_lock["packages"][""]["version"] == version, "package-lock workspace version drift")
    require(tauri["version"] == version, "Tauri version drift")
    require(re.search(rf'^version = "{re.escape(version)}"$', cargo, re.MULTILINE) is not None, "Cargo version drift")
    local_lock = re.search(r'\[\[package\]\]\nname = "letsmakemoney_windows_v1"\nversion = "([^"]+)"', cargo_lock)
    require(local_lock is not None and local_lock.group(1) == version, "Cargo.lock application version drift")
    require(manifest["version"] == version, "Current manifest version drift")
    require(manifest["artifacts"]["zip_name"] == f"LetsMakeMoney-v{version}-windows-x86_64.zip", "Zip identity drift")

    require("versionService.read()" in app_source, "About/update must read the version service")
    require("evaluateUpdate(appVersion" in app_source, "Update request must use the metadata version")
    require(re.search(r'\b1\.0\.\d+\b', app_source) is None, "App UI contains a hard-coded release version")
    require('return "dev-preview"' in service_source, "Browser preview identity is missing")
    require("readTauriVersion" in service_source, "Desktop version must use Tauri package metadata")
    require("invalid_desktop_version_metadata" in service_source, "Invalid desktop metadata must fail closed")
    require(
        "core:app:allow-version" in window_capability["permissions"],
        "Product windows must have the least-privilege Tauri version permission",
    )
    require(
        "core:app:default" not in window_capability["permissions"],
        "Version metadata must not require the broad core:app default permission",
    )


def verify_workflow_and_documentation_entry() -> None:
    workflow = (REPO_ROOT / ".github" / "workflows" / "windows-v1-verify.yml").read_text(encoding="utf-8")
    require(workflow.count("./scripts/verify_windows_current.ps1") == 1, "CI must invoke the current gate exactly once")
    require(re.search(r"\./scripts/(?:verify|package)_v\d", workflow) is None, "CI must not invoke a versioned gate")
    require("Restore locked v1.0.3" not in workflow, "CI must not restore an unrelated historical release")

    for relative in ("README.md", "README.en.md", "CONTRIBUTING.md", "apps/windows-v1/README.md"):
        text = (REPO_ROOT / relative).read_text(encoding="utf-8")
        require("verify_windows_current.ps1" in text, f"{relative} must recommend the unique current gate")


def verify_ipc_fixtures() -> None:
    schema = load_json(CONTRACTS / "ipc-fixture-v1.schema.json")
    fixture = load_json(FIXTURES / "v107-ipc-contracts.json")
    require(isinstance(schema, dict) and isinstance(fixture, dict), "IPC contracts must be objects")
    require(fixture["contract_version"] == 1, "IPC fixture contract version drift")
    require(fixture["config_version"] == 8, "IPC fixture config version drift")
    scenarios = fixture["scenarios"]
    ids = [scenario["id"] for scenario in scenarios]
    require(len(ids) == len(set(ids)), "IPC fixture ids must be unique")
    require({"configuration", "dashboard", "window", "overtime"} == {scenario["domain"] for scenario in scenarios}, "IPC fixture domain coverage drift")
    overtime = [scenario for scenario in scenarios if scenario["domain"] == "overtime"]
    require(len(overtime) >= 5, "Overtime IPC coverage regressed below the M1 skeleton")
    overtime_statuses = {scenario["implementation_status"] for scenario in overtime}
    require(
        overtime_statuses in ({"skeleton"}, {"active"}),
        "Overtime IPC fixtures must advance atomically from skeleton to active",
    )

    rust_source = "\n".join(
        path.read_text(encoding="utf-8")
        for path in (APP_ROOT / "src-tauri" / "src").rglob("*.rs")
    )
    for scenario in scenarios:
        if scenario["implementation_status"] == "active":
            require(scenario["command"] in rust_source, f"Active IPC command is missing: {scenario['command']}")


def main() -> int:
    checks = [
        verify_current_manifest_and_negative_cases,
        verify_config_v8_alignment,
        verify_version_identity,
        verify_workflow_and_documentation_entry,
        verify_ipc_fixtures,
    ]
    try:
        for check in checks:
            check()
            print(f"PASS {check.__name__}")
    except (AssertionError, KeyError, TypeError, json.JSONDecodeError, OSError, ValueError) as error:
        print(f"FAIL {error}", file=sys.stderr)
        return 1
    print(f"PASS v1.0.7 M1 contracts ({len(checks)} groups)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
