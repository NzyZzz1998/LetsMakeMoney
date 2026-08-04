param()

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "v10_tools.ps1")

$Python = Get-V10Python -RepoRoot $RepoRoot
& $Python (Join-Path $RepoRoot "apps\windows-v1\tests\verify_v10f_m5.py")
if ($LASTEXITCODE -ne 0) {
    throw "v1.0.F M5 verification failed with exit code $LASTEXITCODE"
}

Write-Host "PASS LetsMakeMoney v1.0.F M5 verification" -ForegroundColor Green
