param(
    [switch]$SkipRust,
    [switch]$SkipRegression,
    [string]$PythonExe = ""
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$AppRoot = Join-Path $RepoRoot "apps\windows-v1"
. (Join-Path $PSScriptRoot "v10_tools.ps1")

if ([string]::IsNullOrWhiteSpace($PythonExe)) {
    $PythonExe = Get-V10Python
}
$RustToolchain = Get-V10RustToolchain

& $PythonExe (Join-Path $AppRoot "tests\verify_v104_m0.py")
if ($LASTEXITCODE -ne 0) {
    throw "v1.0.4 M0 evidence verification failed with exit code $LASTEXITCODE"
}

& $PythonExe (Join-Path $AppRoot "tests\verify_v104_m0_tests.py")
if ($LASTEXITCODE -ne 0) {
    throw "v1.0.4 M0 negative contract tests failed with exit code $LASTEXITCODE"
}

& $PythonExe (Join-Path $AppRoot "tests\verify_portable_readme_v104_tests.py")
if ($LASTEXITCODE -ne 0) {
    throw "v1.0.4 portable README contract tests failed with exit code $LASTEXITCODE"
}

& $PythonExe (Join-Path $AppRoot "tests\verify_v104_evidence_tests.py")
if ($LASTEXITCODE -ne 0) {
    throw "v1.0.4 durable evidence contract tests failed with exit code $LASTEXITCODE"
}

& $PythonExe (Join-Path $AppRoot "tests\verify_v104_smoke_contract.py")
if ($LASTEXITCODE -ne 0) {
    throw "v1.0.4 desktop smoke contract tests failed with exit code $LASTEXITCODE"
}

& $PythonExe (Join-Path $AppRoot "tests\verify_v104_environment_contract.py")
if ($LASTEXITCODE -ne 0) {
    throw "v1.0.4 reproducible environment contract tests failed with exit code $LASTEXITCODE"
}

& (Join-Path $AppRoot "tests\verify_tool_resolution.ps1")
if ($LASTEXITCODE -ne 0) {
    throw "v1.0.4 unified tool resolution tests failed with exit code $LASTEXITCODE"
}

$Node = Get-V10Node
$NodeModules = Join-Path $AppRoot "node_modules"
Push-Location $AppRoot
try {
    & $Node (Join-Path $NodeModules "typescript\bin\tsc")
    if ($LASTEXITCODE -ne 0) {
        throw "v1.0.4 TypeScript build failed with exit code $LASTEXITCODE"
    }
    & $Node (Join-Path $NodeModules "vite\bin\vite.js") build
    if ($LASTEXITCODE -ne 0) {
        throw "v1.0.4 Vite build failed with exit code $LASTEXITCODE"
    }
}
finally {
    Pop-Location
}

if (-not $SkipRust) {
    $Cargo = Get-V10Cargo -RepoRoot $RepoRoot
    & $Cargo "+$RustToolchain" test `
        --manifest-path (Join-Path $AppRoot "src-tauri\Cargo.toml") `
        "v104_" `
        --no-fail-fast
    if ($LASTEXITCODE -ne 0) {
        throw "v1.0.4 M0 Rust geometry/config tests failed with exit code $LASTEXITCODE"
    }
}

if (-not $SkipRegression) {
    & (Join-Path $PSScriptRoot "verify_architecture.ps1")
    if ($LASTEXITCODE -ne 0) {
        throw "v1.0.4 inherited architecture verification failed with exit code $LASTEXITCODE"
    }

    & (Join-Path $PSScriptRoot "verify_v103.ps1") -SkipRust
    if ($LASTEXITCODE -ne 0) {
        throw "v1.0.3 regression verification failed with exit code $LASTEXITCODE"
    }
}

Push-Location $RepoRoot
try {
    git diff --check
    if ($LASTEXITCODE -ne 0) {
        throw "git diff --check failed."
    }
}
finally {
    Pop-Location
}

Write-Host "PASS LetsMakeMoney v1.0.4 aggregate verification (M0-M3 implemented scope)" -ForegroundColor Green
