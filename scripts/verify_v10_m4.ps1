param(
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$App = Join-Path $Root "apps\windows-v1"
. (Join-Path $PSScriptRoot "v10_tools.ps1")
$Python = Get-V10Python

if (-not $SkipBuild) {
    & (Join-Path $Root "scripts\verify_v10_m1.ps1")
    if ($LASTEXITCODE -ne 0) { throw "Frontend build regression failed." }
}

& $Python (Join-Path $App "tests\verify_m4.py")
if ($LASTEXITCODE -ne 0) { throw "M4 static verification failed." }

& (Join-Path $Root "scripts\verify_v10_m2.ps1")
if ($LASTEXITCODE -ne 0) { throw "Configuration transaction regression failed." }

Write-Host "V10-M4 PASS"
