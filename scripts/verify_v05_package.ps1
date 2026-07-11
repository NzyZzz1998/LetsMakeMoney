param([string]$PackagePath=(Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'releases/v0.5/LetsMakeMoney-v0.5-beta-windows-x86_64.zip'),[int]$SmokeSeconds=5)
$ErrorActionPreference='Stop';$root=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path;. (Join-Path $PSScriptRoot 'verify_package_common.ps1')
Test-LmmPackage -PackagePath $PackagePath -ExpectedVersion '0.5-beta' -ExtractRoot (Join-Path $root '.tmp_release/verify_v05_package') -SmokeAppDataRoot (Join-Path $root '.tmp_appdata/verify_v05_package') -SmokeSeconds $SmokeSeconds
