param([string]$ProjectRoot=(Split-Path -Parent $PSScriptRoot),[string]$GodotExe=$env:LMM_GODOT_EXE,[switch]$SkipExport)
$ErrorActionPreference='Stop';. (Join-Path $PSScriptRoot 'project_version.ps1');. (Join-Path $PSScriptRoot 'package_common.ps1')
if(-not $SkipExport){& (Join-Path $PSScriptRoot 'verify_m5.ps1') -GodotExe $GodotExe -OutputPath (Join-Path $ProjectRoot 'build/LetsMakeMoney.exe');if($LASTEXITCODE -ne 0){throw 'v0.7 export failed.'}}
$version=Get-LetsMakeMoneyVersion -ProjectRoot $ProjectRoot
if($version -ne '0.7-beta'){throw "Unexpected project version: $version"}
New-LmmPackage -ProjectRoot $ProjectRoot -Version $version -ReleaseDirectory 'releases/v0.7' -ReleaseNotes 'doc/releases/v0.7/release-notes.md' -IncludeLicenses
