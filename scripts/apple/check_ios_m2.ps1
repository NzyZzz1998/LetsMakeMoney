param(
    [switch]$RequireSwift
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$required = @(
    'apple/Packages/SalaryCore/Sources/SalaryCore/AppConfiguration.swift',
    'apple/Packages/SalaryCore/Sources/SalaryCore/ConfigurationPersistence.swift',
    'apple/Packages/SalaryCore/Sources/SalaryCore/SharedSnapshots.swift',
    'apple/Packages/SalaryCore/Sources/SalaryCore/LocalEventLogger.swift',
    'apple/Shared/Resources/Localizable.xcstrings',
    'scripts/apple/validate_apple_localization.py'
)

$missing = @($required | Where-Object {
    -not (Test-Path -LiteralPath (Join-Path $root $_) -PathType Leaf)
})
if ($missing.Count -gt 0) {
    throw "Missing M2 files: $($missing -join ', ')"
}

Push-Location $root
try {
    & (Join-Path $PSScriptRoot 'check_ios_m1.ps1') -RequireSwift:$RequireSwift
    if ($LASTEXITCODE -ne 0) { throw 'M1 prerequisite gate failed.' }

    python -m unittest scripts.apple.tests.test_apple_localization -v
    if ($LASTEXITCODE -ne 0) { throw 'Localization validator tests failed.' }

    python scripts/apple/validate_apple_localization.py --root $root
    if ($LASTEXITCODE -ne 0) { throw 'Apple localization validation failed.' }

    Write-Host 'IOS_M2_DATA_LAYER_PASS'
} finally {
    Pop-Location
}
