param(
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$App = Join-Path $Root "apps\windows-v1"
. (Join-Path $PSScriptRoot "v10_tools.ps1")
$Python = Get-V10Python
$Cargo = Get-V10Cargo -RepoRoot $Root

if (-not $SkipBuild) {
    & (Join-Path $Root "scripts\verify_v10_m4.ps1")
    if ($LASTEXITCODE -ne 0) { throw "M4 regression failed." }
}

& $Python (Join-Path $App "tests\verify_m5.py")
if ($LASTEXITCODE -ne 0) { throw "M5 static verification failed." }

Push-Location (Join-Path $App "src-tauri")
try {
    & $Cargo +stable-x86_64-pc-windows-msvc test --locked --offline --lib --quiet
    if ($LASTEXITCODE -ne 0) { throw "M5 Rust tests failed." }
    & $Cargo +stable-x86_64-pc-windows-msvc check --locked --offline --quiet
    if ($LASTEXITCODE -ne 0) { throw "M5 Rust compile check failed." }
}
finally {
    Pop-Location
}

Write-Host "V10-M5 PASS"
