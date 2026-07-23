param(
    [string]$ProjectRoot=(Split-Path -Parent $PSScriptRoot),
    [string]$PackagePath='',
    [int]$SmokeSeconds=5
)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'verify_package_common.ps1')
$version='0.9-beta'
if(-not $PackagePath){
    $PackagePath=Join-Path $ProjectRoot "releases/v0.9/LetsMakeMoney-v$version-windows-x86_64.zip"
}
$requiredPetEvidence = @(
    'PetManager.package shadow_loaded id=letsmakemoney-classic-pro',
    'PetManager.package shadow_loaded id=duoduo-cat'
)
$forbiddenPetEvidence = @(
    'PetManager.package rejected root=res://assets/pets/packages/'
)
Test-LmmPackage `
    -PackagePath $PackagePath `
    -ExpectedVersion $version `
    -ExtractRoot (Join-Path $ProjectRoot '.tmp_release/verify_v09_package') `
    -SmokeAppDataRoot (Join-Path $ProjectRoot '.tmp_appdata/verify_v09_package') `
    -SmokeSeconds $SmokeSeconds `
    -RequireLicenses `
    -RequiredRuntimeLogPatterns $requiredPetEvidence `
    -ForbiddenRuntimeLogPatterns $forbiddenPetEvidence
