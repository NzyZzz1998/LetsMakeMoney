param([string]$ProjectRoot=(Split-Path -Parent $PSScriptRoot),[string]$PackagePath='',[int]$SmokeSeconds=5)
$ErrorActionPreference='Stop';. (Join-Path $PSScriptRoot 'verify_package_common.ps1')
$version='0.8-beta';if(-not $PackagePath){$PackagePath=Join-Path $ProjectRoot "releases/v0.8/LetsMakeMoney-v$version-windows-x86_64.zip"}
Test-LmmPackage -PackagePath $PackagePath -ExpectedVersion $version -ExtractRoot (Join-Path $ProjectRoot '.tmp_release/verify_v08_package') -SmokeAppDataRoot (Join-Path $ProjectRoot '.tmp_appdata/verify_v08_package') -SmokeSeconds $SmokeSeconds -RequireLicenses
