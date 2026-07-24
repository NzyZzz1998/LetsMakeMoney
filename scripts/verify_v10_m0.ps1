param(
    [string]$PythonExe = ""
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$AppRoot = Join-Path $RepoRoot "apps\windows-v1"
. (Join-Path $PSScriptRoot "v10_tools.ps1")

if ([string]::IsNullOrWhiteSpace($PythonExe)) {
    $PythonExe = Get-V10Python
}

$requiredFiles = @(
    "contracts\config-v1.schema.json",
    "contracts\config-defaults.json",
    "contracts\migration-contract.json",
    "contracts\window-contract.json",
    "contracts\log-contract.json",
    "contracts\visual-contract.json",
    "tests\fixtures\salary-schedule-fixtures.json",
    "tests\fixtures\migration-fixtures.json",
    "tests\fixtures\window-fixtures.json",
    "tests\verify_contracts.py",
    "package.json",
    "src-tauri\Cargo.toml",
    "src-tauri\tauri.conf.json"
)

foreach ($relativePath in $requiredFiles) {
    $path = Join-Path $AppRoot $relativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Missing M0 file: $relativePath"
    }
}

$jsonRoots = @(
    (Join-Path $AppRoot "contracts"),
    (Join-Path $AppRoot "tests\fixtures")
)
$jsonFiles = $jsonRoots | ForEach-Object {
    Get-ChildItem -LiteralPath $_ -Recurse -File -Filter "*.json"
}
$jsonFiles += Get-Item -LiteralPath (Join-Path $AppRoot "package.json")
$jsonFiles += Get-Item -LiteralPath (Join-Path $AppRoot "src-tauri\tauri.conf.json")

$jsonFiles | ForEach-Object {
    $null = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
}
Write-Host "PASS JSON parse"

& $PythonExe (Join-Path $AppRoot "tests\verify_contracts.py")
if ($LASTEXITCODE -ne 0) {
    throw "Contract verification failed with exit code $LASTEXITCODE"
}

Write-Host "PASS no pet capability in formal app production code"

$legacyPaths = @("src", "native", "assets\pets", "project.godot")
$remainingLegacy = $legacyPaths | Where-Object {
    Test-Path -LiteralPath (Join-Path $RepoRoot $_)
}
if ($remainingLegacy) {
    throw "Retired v0.9 paths remain in the v1.0 active tree: $($remainingLegacy -join ', ')"
}
Write-Host "PASS v0.9 implementation retired from active tree"

Write-Host "PASS LetsMakeMoney v1.0 M0 verification"
