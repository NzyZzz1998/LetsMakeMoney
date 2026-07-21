param(
    [string]$ProjectRoot=(Split-Path -Parent $PSScriptRoot),
    [string]$GodotExe=$env:LMM_GODOT_EXE,
    [switch]$SkipExport
)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'project_version.ps1')
. (Join-Path $PSScriptRoot 'package_common.ps1')
if(-not $SkipExport){
    & (Join-Path $PSScriptRoot 'verify_v09.ps1') -ProjectRoot $ProjectRoot -GodotExe $GodotExe
    if($LASTEXITCODE -ne 0){throw 'v0.9 export failed.'}
}
$version=Get-LetsMakeMoneyVersion -ProjectRoot $ProjectRoot
if($version -ne '0.9-beta'){throw "Unexpected project version: $version"}
New-LmmPackage -ProjectRoot $ProjectRoot -Version $version -ReleaseDirectory 'releases/v0.9' -ReleaseNotes 'doc/releases/v0.9/release-notes.md' -IncludeLicenses
