param([string]$ProjectRoot=(Split-Path -Parent $PSScriptRoot),[switch]$StaticOnly)
$ErrorActionPreference='Stop'
$env:LMM_GODOT_EXE=$env:LMM_GODOT_EXE
& (Join-Path $PSScriptRoot 'verify_v06.ps1') -ProjectRoot $ProjectRoot -StaticOnly:$StaticOnly -ExpectedProjectVersion '0.7-beta'
& (Join-Path $PSScriptRoot 'test_installer_contract.ps1') -ProjectRoot $ProjectRoot
& (Join-Path $PSScriptRoot 'test_signing_contract.ps1') -ProjectRoot $ProjectRoot
& (Join-Path $PSScriptRoot 'test_update_contract.ps1') -ProjectRoot $ProjectRoot
& (Join-Path $PSScriptRoot 'test_public_repo_governance.ps1') -ProjectRoot $ProjectRoot
if (-not $StaticOnly) {
    . (Join-Path $PSScriptRoot 'verification_common.ps1')
    $godot = Resolve-LmmGodotExecutable
    [void](Invoke-LmmGodotVerification -GodotExe $godot -ProjectRoot $ProjectRoot -ScriptPath 'res://scripts/verify_v07_ui_contract.gd' -Label 'v07-ui-contract' -SuccessMarker 'v0.7 UI contract passed')
}
Write-Host 'v0.7 verification passed' -ForegroundColor Green
