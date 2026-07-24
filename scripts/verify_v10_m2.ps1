param()

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$App = Join-Path $Root "apps\windows-v1"
. (Join-Path $PSScriptRoot "v10_tools.ps1")
$Python = Get-V10Python
$Cargo = Get-V10Cargo -RepoRoot $Root

& $Python (Join-Path $App "tests\verify_m2.py")
if ($LASTEXITCODE -ne 0) { throw "M2 static verification failed." }

Push-Location (Join-Path $App "src-tauri")
try {
    & $Cargo +stable-x86_64-pc-windows-msvc test --locked --offline --lib --quiet
    if ($LASTEXITCODE -ne 0) { throw "M2 Rust tests failed." }
    & $Cargo +stable-x86_64-pc-windows-msvc check --locked --offline --quiet
    if ($LASTEXITCODE -ne 0) { throw "M2 Rust compile check failed." }
}
finally {
    Pop-Location
}

Write-Host "V10-M2 PASS"
