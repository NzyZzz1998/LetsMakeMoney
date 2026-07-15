param(
    [switch]$RequireSwift
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$required = @(
    'apple/Packages/ApplePlatformGate/Package.swift',
    'apple/Packages/ApplePlatformGate/Sources/G3AppProbe/G3AppProbe.swift',
    'apple/Packages/ApplePlatformGate/Sources/G3WidgetActivityProbe/G3WidgetActivityProbe.swift',
    'apple/Packages/ApplePlatformGate/Sources/G3WatchProbe/G3WatchProbe.swift',
    'scripts/apple/tests/test_apple_platform_gate.py'
)

$missing = @($required | Where-Object {
    -not (Test-Path -LiteralPath (Join-Path $root $_) -PathType Leaf)
})
if ($missing.Count -gt 0) {
    throw "Missing M4 platform gate files: $($missing -join ', ')"
}

Push-Location $root
try {
    & (Join-Path $PSScriptRoot 'check_ios_m3.ps1') -RequireSwift:$RequireSwift
    if ($LASTEXITCODE -ne 0) { throw 'M3 prerequisite gate failed.' }

    python -m unittest scripts.apple.tests.test_apple_platform_gate -v
    if ($LASTEXITCODE -ne 0) { throw 'M4 Apple platform source contract failed.' }

    Write-Host 'IOS_M4_WINDOWS_CONTRACTS_PASS'
    Write-Warning 'APPLE_PLATFORM_G3_BUILD_PENDING: GitHub macOS must compile the App, Widget/Activity and Watch probes before M4-001 can pass.'
} finally {
    Pop-Location
}
