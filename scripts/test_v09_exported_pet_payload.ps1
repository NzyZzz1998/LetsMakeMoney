param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$BrokenPackagePath = ""
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path

$presetPath = Join-Path $root "export_presets.cfg"
$preset = Get-Content -LiteralPath $presetPath -Raw
foreach ($requiredFilter in @(
    "assets/pets/packages/**/*.webp",
    "assets/pets/packages/**/*.json",
    "assets/pets/packages/**/*.md"
)) {
    if ($preset -notmatch [regex]::Escape($requiredFilter)) {
        throw "Godot export does not preserve raw pet package payload: $requiredFilter"
    }
}

$petPackageRoot = Join-Path $root "assets/pets/packages"
foreach ($webp in Get-ChildItem -LiteralPath $petPackageRoot -Filter "*.webp" -File -Recurse) {
    $importPath = "$($webp.FullName).import"
    if (-not (Test-Path -LiteralPath $importPath)) {
        throw "Pet package WebP is missing its raw export sidecar: $($webp.FullName.Substring($root.Length + 1))"
    }
    $importText = Get-Content -LiteralPath $importPath -Raw
    if ($importText -notmatch 'importer="keep"') {
        throw "Pet package WebP would be converted instead of exported as original bytes: $($webp.FullName.Substring($root.Length + 1))"
    }
}

$wrapperPath = Join-Path $root "scripts/verify_v09_package.ps1"
$wrapper = Get-Content -LiteralPath $wrapperPath -Raw
foreach ($requiredMarker in @(
    "PetManager.package shadow_loaded id=letsmakemoney-classic-pro",
    "PetManager.package shadow_loaded id=duoduo-cat",
    "PetManager.package rejected root=res://assets/pets/packages/"
)) {
    if ($wrapper -notmatch [regex]::Escape($requiredMarker)) {
        throw "v0.9 package verification does not enforce runtime pet evidence: $requiredMarker"
    }
}

if ($BrokenPackagePath) {
    $resolvedBrokenPackage = (Resolve-Path -LiteralPath $BrokenPackagePath).Path
    $acceptedBrokenPackage = $false
    try {
        & $wrapperPath -ProjectRoot $root -PackagePath $resolvedBrokenPackage -SmokeSeconds 2
        $acceptedBrokenPackage = $true
    } catch {
        Write-Host "Known-broken package rejected as expected: $($_.Exception.Message.Split([Environment]::NewLine)[0])"
    }
    if ($acceptedBrokenPackage) {
        throw "Known-broken v0.9 package was accepted despite missing runtime pet payload"
    }
}

Write-Host "v0.9 exported pet payload contract passed"
