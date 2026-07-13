$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$managerPath = Join-Path $root "src\autoload\pet_manager.gd"
$manager = Get-Content -LiteralPath $managerPath -Raw
$requiredResources = @(
    "assets\pets\cat\orange_v2\cat_orange_v2_resource.tres",
    "assets\pets\cat_orange_v1\cat_orange_v1_resource.tres",
    "assets\pets\cat\cat_resource.tres"
)
foreach ($resource in $requiredResources) {
    if (-not (Test-Path -LiteralPath (Join-Path $root $resource))) {
        throw "Required pet fallback resource is missing: $resource"
    }
}
if ($manager -notmatch 'const DEFAULT_PET_ID = "cat_orange_v2"') {
    throw "PetManager default pet contract changed"
}
if ($manager -notmatch 'const FALLBACK_PET_ID = "cat_orange_v1"') {
    throw "PetManager v1 fallback contract changed"
}
$defaultIndex = $manager.IndexOf('next_pet = _find_pet_by_id(DEFAULT_PET_ID)')
$fallbackIndex = $manager.IndexOf('next_pet = _find_pet_by_id(FALLBACK_PET_ID)')
$lastResortIndex = $manager.IndexOf('next_pet = available_pets[0]')
if ($defaultIndex -lt 0 -or $fallbackIndex -le $defaultIndex -or $lastResortIndex -le $fallbackIndex) {
    throw "Pet fallback order must remain v2 -> v1 -> first available placeholder"
}
Write-Host "v0.8 pet fallback verification passed"
