from __future__ import annotations

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def read(relative: str) -> str:
    path = ROOT / relative
    require(path.is_file(), f"required environment-contract file is missing: {relative}")
    return path.read_text(encoding="utf-8")


def main() -> int:
    diagnostic = read("scripts/diagnose_v104_environment.ps1")
    resolver = read("scripts/v10_tools.ps1")
    workflow = read(".github/workflows/windows-v1-verify.yml")
    root_readme = read("README.md")
    contributing = read("CONTRIBUTING.md")
    app_readme = read("apps/windows-v1/README.md")
    toolchain = read("rust-toolchain.toml")
    package = read("scripts/package_v104.ps1")
    aggregate = read("scripts/verify_v104.ps1")
    verify_v103 = read("scripts/verify_v103.ps1")
    verify_v102 = read("scripts/verify_v102.ps1")
    tsc_index = aggregate.find("typescript\\bin\\tsc")
    vite_index = aggregate.find("vite\\bin\\vite.js")
    rust_test_index = aggregate.find('"v104_"')

    checks = {
        "diagnostic resolves all tools": all(
            marker in diagnostic
            for marker in (
                "Get-V10NodeResolution",
                "Get-V10PythonResolution",
                "Get-V10CargoResolution",
            )
        ),
        "diagnostic reports build prerequisites": all(
            marker in diagnostic for marker in ("MSVC", "Windows SDK", "WebView2")
        ),
        "diagnostic supports private-path redaction": "IncludePaths" in diagnostic,
        "resolver has explicit variables": all(
            marker in resolver for marker in ("LMM_NODE", "LMM_PYTHON", "LMM_CARGO")
        ),
        "resolver has repository caches": all(
            marker in resolver
            for marker in (
                ".toolchains\\node\\node.exe",
                ".toolchains\\python\\python.exe",
                ".toolchains\\cargo\\bin\\cargo.exe",
            )
        ),
        "formal resolver excludes private fallback": all(
            marker not in resolver
            for marker in ("spikes\\v1.0-ui\\.toolchains", "codex-runtimes", "USERPROFILE")
        ),
        "CI pins Python": "actions/setup-python@" in workflow and 'python-version: "3.12"' in workflow,
        "CI pins Node": 'node-version: "22"' in workflow,
        "CI pins Rust": re.search(r"toolchain:\s*[\"']?1\.97\.1", workflow) is not None,
        "CI records and verifies environment": all(
            marker in workflow
            for marker in ("diagnose_v104_environment.ps1", "verify_v104.ps1")
        ),
        "root Rust toolchain is fixed": 'channel = "1.97.1"' in toolchain
        and 'targets = ["x86_64-pc-windows-msvc"]' in toolchain,
        "v104 package uses fixed toolchain": "Get-V10RustToolchain" in package,
        "aggregate builds web before Rust tests": (
            -1 < tsc_index < vite_index < rust_test_index
        ),
        "formal inherited scripts use resolver": "& python" not in verify_v103.lower()
        and '$python = "python"' not in verify_v102.lower(),
        "root README documents clean environment": all(
            marker in root_readme
            for marker in (
                "Python 3.12",
                "MSVC",
                "Windows SDK",
                "diagnose_v104_environment.ps1",
            )
        ),
        "contribution guide documents diagnosis": all(
            marker in contributing
            for marker in ("Python 3.12", "diagnose_v104_environment.ps1")
        ),
        "app README documents unified resolution": all(
            marker in app_readme
            for marker in ("LMM_NODE", "LMM_PYTHON", ".toolchains")
        ),
    }
    for label, passed in checks.items():
        require(passed, f"environment contract failed: {label}")
        print(f"PASS {label}")

    formal_scripts = [
        path
        for path in (ROOT / "scripts").glob("*.ps1")
        if path.name not in {"verify_v104_environment_contract.py"}
    ]
    forbidden = "spikes\\v1.0-ui\\.toolchains"
    offenders = [
        path.relative_to(ROOT).as_posix()
        for path in formal_scripts
        if forbidden in path.read_text(encoding="utf-8")
    ]
    require(not offenders, f"formal scripts still depend on spike toolchain: {offenders}")
    print("PASS no formal script depends on spike toolchain")
    print(f"PASS v1.0.4 environment contract ({len(checks) + 1}/{len(checks) + 1})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
