param(
    [switch]$RequireSwift
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$required = @(
    'shared/salary-schema/v1/schema.json',
    'shared/salary-schema/v1/README.md',
    'shared/salary-schema/v1/vectors/salary-vectors.json',
    'shared/salary-schema/v1/holidays/manifest.json',
    'shared/salary-schema/v1/holidays/cn-2025.json',
    'shared/salary-schema/v1/holidays/cn-2026.json',
    'shared/salary-schema/v1/holidays/cn-2027-unavailable.json',
    'apple/Packages/SalaryCore/Package.swift',
    'apple/Packages/SalaryCore/Sources/SalaryCore/SalaryCalculator.swift',
    'apple/Packages/SalaryCore/Tests/SalaryCoreTests/SalaryVectorTests.swift',
    'scripts/apple/validate_salary_contract.py'
)

$missing = @($required | Where-Object {
    -not (Test-Path -LiteralPath (Join-Path $root $_) -PathType Leaf)
})
if ($missing.Count -gt 0) {
    throw "Missing M1 files: $($missing -join ', ')"
}

Push-Location $root
try {
    python -m unittest scripts.apple.tests.test_salary_contract -v
    if ($LASTEXITCODE -ne 0) { throw 'Cross-platform contract tests failed.' }

    $swift = Get-Command swift -ErrorAction SilentlyContinue
    if ($null -eq $swift) {
        if ($RequireSwift) { throw 'G1 pending: Swift toolchain was not found.' }
        Write-Warning 'SWIFT_UNAVAILABLE: reference checks passed; G1 still requires swift test.'
    } else {
        & $swift.Source test --package-path apple/Packages/SalaryCore
        if ($LASTEXITCODE -ne 0) { throw 'Swift SalaryCore tests failed.' }
        Write-Host 'SWIFT_TEST_PASS'
    }

    Write-Host 'IOS_M1_CONTRACT_PASS'
} finally {
    Pop-Location
}
