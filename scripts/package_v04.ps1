param([string]$ProjectRoot=(Split-Path -Parent $PSScriptRoot),[string]$Version='0.4-beta')
$ErrorActionPreference='Stop';. (Join-Path $PSScriptRoot 'package_common.ps1')
New-LmmPackage -ProjectRoot $ProjectRoot -Version $Version -ReleaseDirectory 'releases/v0.4' -ReleaseNotes 'releases/v0.4-beta-notes.md'
