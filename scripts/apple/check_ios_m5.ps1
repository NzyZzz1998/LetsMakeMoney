param(
    [switch]$RequireSwift
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$required = @(
    'apple/Packages/SalaryCore/Sources/SalaryCore/WatchConnectivityContract.swift',
    'apple/Packages/SalaryCore/Tests/SalaryCoreTests/WatchConnectivityContractTests.swift',
    'apple/Shared/Watch/WatchConnectivityController.swift',
    'apple/Shared/Watch/WatchMessageStore.swift',
    'apple/WatchApp/LetsMakeMoneyWatchApp.swift',
    'apple/WatchApp/WatchHomeView.swift',
    'apple/WatchWidgetExtension/LetsMakeMoneyWatchWidgetBundle.swift',
    'apple/WatchWidgetExtension/WatchProgressWidget.swift',
    'apple/WatchWidgetExtension/WatchMetricIntent.swift',
    'scripts/apple/tests/test_watch_product_targets.py'
)

$missing = @($required | Where-Object {
    -not (Test-Path -LiteralPath (Join-Path $root $_) -PathType Leaf)
})
if ($missing.Count -gt 0) {
    throw "Missing M5 Watch files: $($missing -join ', ')"
}

Push-Location $root
try {
    & (Join-Path $PSScriptRoot 'check_ios_m4.ps1') -RequireSwift:$RequireSwift
    if ($LASTEXITCODE -ne 0) { throw 'M4 prerequisite gate failed.' }

    python -m unittest scripts.apple.tests.test_watch_product_targets -v
    if ($LASTEXITCODE -ne 0) { throw 'M5 Watch product source contract failed.' }

    $swift = Get-Command swift -ErrorAction SilentlyContinue
    if ($null -eq $swift) {
        if ($RequireSwift) { throw 'Swift is required for the M5 contract gate.' }
        Write-Warning 'SWIFT_WATCH_CONTRACTS_SKIPPED: Swift was not found on PATH.'
    } else {
        swift test --package-path apple/Packages/SalaryCore --filter WatchConnectivityContractTests
        if ($LASTEXITCODE -ne 0) { throw 'M5 WatchConnectivityContractTests failed.' }
    }

    Write-Host 'IOS_M5_WINDOWS_CONTRACTS_PASS'
    Write-Warning 'WATCH_PRODUCT_BUILD_PENDING: GitHub macOS must compile the formal Watch App and Watch Widget targets.'
} finally {
    Pop-Location
}
