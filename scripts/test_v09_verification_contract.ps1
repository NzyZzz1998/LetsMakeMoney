param([string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot))

$ErrorActionPreference = "Stop"
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path

$requiredFiles = @(
    "scripts\verify_v09.ps1",
    "scripts\verify_v09_behavior_baseline.gd",
    "scripts\test_v09_behavior_baseline.ps1",
    "scripts\package_v09.ps1",
    "scripts\verify_v09_package.ps1",
    "scripts\test_v09_exported_pet_payload.ps1",
    "doc\releases\v0.9\verification.md",
    "doc\releases\v0.9\manual-verification.md",
    "doc\releases\v0.9\release-notes.md",
    "doc\releases\v0.9\release-checklist.md"
)

foreach ($relativePath in $requiredFiles) {
    $path = Join-Path $root $relativePath
    if (-not (Test-Path -LiteralPath $path)) {
        throw "v0.9 verification contract is missing: $relativePath"
    }
}

$project = Get-Content -LiteralPath (Join-Path $root "project.godot") -Raw
if ($project -notmatch 'config/version="0\.9-beta"') {
    throw "project.godot does not identify v0.9-beta"
}

$package = Get-Content -LiteralPath (Join-Path $root "scripts\package_v09.ps1") -Raw
foreach ($requiredToken in @("0.9-beta", "releases/v0.9", "release-notes.md", "IncludeLicenses", "SHA256SUMS.txt")) {
    if ($package -notmatch [regex]::Escape($requiredToken)) {
        throw "package_v09.ps1 is missing: $requiredToken"
    }
}

$packageVerification = Get-Content -LiteralPath (Join-Path $root "scripts\verify_v09_package.ps1") -Raw
foreach ($requiredToken in @("0.9-beta", "verify_v09_package", "RequireLicenses")) {
    if ($packageVerification -notmatch [regex]::Escape($requiredToken)) {
        throw "verify_v09_package.ps1 is missing: $requiredToken"
    }
}

$verify = Get-Content -LiteralPath (Join-Path $root "scripts\verify_v09.ps1") -Raw
foreach ($requiredGate in @(
    "verify_v08.ps1",
    "verify_m4.ps1",
    "verify_m5.ps1",
    "test_v09_behavior_baseline.ps1"
)) {
    if ($verify -notmatch [regex]::Escape($requiredGate)) {
        throw "verify_v09.ps1 does not include required gate: $requiredGate"
    }
}

Write-Host "v0.9 verification contract passed"
