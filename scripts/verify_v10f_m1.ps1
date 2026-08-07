param()

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$AppRoot = Join-Path $RepoRoot "apps\windows-v1"
. (Join-Path $PSScriptRoot "v10_tools.ps1")

$Python = Get-V10Python -RepoRoot $RepoRoot
$BrandGenerator = Join-Path $AppRoot "scripts\generate_brand_icon.ps1"

& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $BrandGenerator
if ($LASTEXITCODE -ne 0) {
    throw "v1.0.F brand generation failed with exit code $LASTEXITCODE"
}

& $Python (Join-Path $AppRoot "tests\verify_v10f_m1.py")
if ($LASTEXITCODE -ne 0) {
    throw "v1.0.F M1 contract verification failed with exit code $LASTEXITCODE"
}

Write-Host "PASS LetsMakeMoney v1.0.F M1 verification" -ForegroundColor Green
