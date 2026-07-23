param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$GodotExe = "",
    [switch]$StaticOnly,
    [switch]$SkipExport
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
if ($GodotExe) { $env:LMM_GODOT_EXE = $GodotExe }
$resolvedGodotExe = $GodotExe
if (-not $resolvedGodotExe -and $env:LMM_GODOT_EXE) {
    $resolvedGodotExe = $env:LMM_GODOT_EXE
}

& (Join-Path $PSScriptRoot "test_v09_verification_contract.ps1") -ProjectRoot $root
& (Join-Path $PSScriptRoot "test_v09_exported_pet_payload.ps1") -ProjectRoot $root
& (Join-Path $PSScriptRoot "test_v09_behavior_baseline.ps1") -ProjectRoot $root -GodotExe $resolvedGodotExe -StaticOnly:$StaticOnly
if (-not $StaticOnly) {
    & (Join-Path $PSScriptRoot "test_v09_schedule.ps1") -ProjectRoot $root -GodotExe $resolvedGodotExe
    & (Join-Path $PSScriptRoot "test_v09_configuration_experience.ps1") -ProjectRoot $root -GodotExe $resolvedGodotExe
    & (Join-Path $PSScriptRoot "test_v09_window_experience.ps1") -ProjectRoot $root -GodotExe $resolvedGodotExe
	& (Join-Path $PSScriptRoot "test_v09_pet_package.ps1") -ProjectRoot $root -GodotExe $resolvedGodotExe
	& (Join-Path $PSScriptRoot "test_v09_pet_animation.ps1") -ProjectRoot $root -GodotExe $resolvedGodotExe
	& (Join-Path $PSScriptRoot "test_v09_pet_integration.ps1") -ProjectRoot $root -GodotExe $resolvedGodotExe
}
& (Join-Path $PSScriptRoot "verify_v08.ps1") -ProjectRoot $root -StaticOnly:$StaticOnly -ExpectedProjectVersion '0.9-beta'

if (-not $StaticOnly) {
    & (Join-Path $PSScriptRoot "verify_m4.ps1") -GodotExe $resolvedGodotExe
    if (-not $SkipExport) {
        & (Join-Path $PSScriptRoot "verify_m5.ps1") -GodotExe $resolvedGodotExe -SmokeAppDataRoot (Join-Path $root ".tmp_appdata\verify_v09_m5")
    }
}

Write-Host "v0.9 verification passed" -ForegroundColor Green
