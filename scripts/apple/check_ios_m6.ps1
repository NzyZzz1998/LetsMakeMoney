param(
    [switch]$RequireSwift
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$required = @(
    'apple/Packages/SalaryCore/Sources/SalaryCore/CrossTargetConsistency.swift',
    'apple/Packages/SalaryCore/Tests/SalaryCoreTests/CrossTargetConsistencyTests.swift',
    'scripts/apple/validate_apple_product_quality.py',
    'scripts/apple/validate_ios_prototype_contract.py',
    'doc/releases/ios-v0.1/privacy.md',
    'doc/releases/ios-v0.1/known-limitations.md',
    'doc/releases/ios-v0.1/m6-device-verification.md'
)

$missing = @($required | Where-Object {
    -not (Test-Path -LiteralPath (Join-Path $root $_) -PathType Leaf)
})
if ($missing.Count -gt 0) {
    throw "Missing M6 files: $($missing -join ', ')"
}

Push-Location $root
try {
    & (Join-Path $PSScriptRoot 'check_ios_m5.ps1') -RequireSwift:$RequireSwift
    if ($LASTEXITCODE -ne 0) { throw 'M5 prerequisite gate failed.' }

    python -m unittest `
        scripts.apple.tests.test_apple_product_quality `
        scripts.apple.tests.test_ios_prototype_contract `
        scripts.apple.tests.test_ios_m6_gate -v
    if ($LASTEXITCODE -ne 0) { throw 'M6 Python contract tests failed.' }

    python scripts/apple/validate_apple_localization.py
    if ($LASTEXITCODE -ne 0) { throw 'Apple localization validation failed.' }

    python scripts/apple/validate_apple_product_quality.py
    if ($LASTEXITCODE -ne 0) { throw 'Apple product quality validation failed.' }

    python scripts/apple/validate_ios_prototype_contract.py
    if ($LASTEXITCODE -ne 0) { throw 'iOS prototype contract validation failed.' }

    $swift = Get-Command swift -ErrorAction SilentlyContinue
    if ($null -eq $swift) {
        if ($RequireSwift) { throw 'Swift is required for the M6 consistency gate.' }
        Write-Warning 'SWIFT_CROSS_TARGET_CONSISTENCY_SKIPPED: Swift was not found on PATH.'
    } else {
        swift test --package-path apple/Packages/SalaryCore --filter CrossTargetConsistencyTests
        if ($LASTEXITCODE -ne 0) { throw 'CrossTargetConsistencyTests failed.' }
    }

    Write-Host 'IOS_M6_AUTOMATED_GATE_PASS'
    Write-Warning 'M6_REAL_DEVICE_MATRIX_PENDING: appearance, accessibility, timezone, lock-screen, restart and low-power evidence must be completed on Apple devices.'
} finally {
    Pop-Location
}
