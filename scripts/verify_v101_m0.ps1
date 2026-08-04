param(
    [string]$PythonExe = ""
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "v10_tools.ps1")

if ([string]::IsNullOrWhiteSpace($PythonExe)) {
    $PythonExe = Get-V10Python
}

& $PythonExe (Join-Path $RepoRoot "apps\windows-v1\tests\verify_v101_m0.py")
if ($LASTEXITCODE -ne 0) {
    throw "v1.0.1 M0 verification failed with exit code $LASTEXITCODE"
}

Write-Host "PASS LetsMakeMoney v1.0.1 M0 verification" -ForegroundColor Green
