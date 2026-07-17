param([string]$ProjectRoot=(Split-Path -Parent $PSScriptRoot),[switch]$StaticOnly)
$ErrorActionPreference='Stop'
& (Join-Path $PSScriptRoot 'verify_v07.ps1') -ProjectRoot $ProjectRoot -StaticOnly:$StaticOnly -ExpectedProjectVersion '0.8-beta'
if (-not $StaticOnly) {
    & (Join-Path $PSScriptRoot 'test_v08_salary_schedule.ps1') -ProjectRoot $ProjectRoot
    & (Join-Path $PSScriptRoot 'test_v08_settings_governance.ps1') -ProjectRoot $ProjectRoot
}
Write-Host 'v0.8 verification passed' -ForegroundColor Green
