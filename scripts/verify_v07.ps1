param([string]$ProjectRoot=(Split-Path -Parent $PSScriptRoot),[switch]$StaticOnly)
$ErrorActionPreference='Stop'
$env:LMM_GODOT_EXE=$env:LMM_GODOT_EXE
& (Join-Path $PSScriptRoot 'verify_v06.ps1') -ProjectRoot $ProjectRoot -StaticOnly:$StaticOnly -ExpectedProjectVersion '0.7-beta'
& (Join-Path $PSScriptRoot 'test_installer_contract.ps1') -ProjectRoot $ProjectRoot
& (Join-Path $PSScriptRoot 'test_signing_contract.ps1') -ProjectRoot $ProjectRoot
& (Join-Path $PSScriptRoot 'test_update_contract.ps1') -ProjectRoot $ProjectRoot
& (Join-Path $PSScriptRoot 'test_public_repo_governance.ps1') -ProjectRoot $ProjectRoot
Write-Host 'v0.7 verification passed' -ForegroundColor Green
