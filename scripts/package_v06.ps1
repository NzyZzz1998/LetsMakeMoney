param([string]$ProjectRoot=(Split-Path -Parent $PSScriptRoot),[switch]$SkipExport)
$ErrorActionPreference='Stop';. (Join-Path $PSScriptRoot 'project_version.ps1');. (Join-Path $PSScriptRoot 'package_common.ps1')
if(-not $SkipExport){& (Join-Path $PSScriptRoot 'verify_m5.ps1') -OutputPath (Join-Path $ProjectRoot 'build/LetsMakeMoney.exe');if($LASTEXITCODE -ne 0){throw 'v0.6 export failed.'}}
$version=Get-LetsMakeMoneyVersion -ProjectRoot $ProjectRoot
New-LmmPackage -ProjectRoot $ProjectRoot -Version $version -ReleaseDirectory 'releases/v0.6' -ReleaseNotes 'releases/v0.6-beta-notes.md' -IncludeLicenses
