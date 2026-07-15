param(
    [switch]$RequireSwift
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$required = @(
    'apple/Packages/SalaryCore/Sources/SalaryCore/AppFlow.swift',
    'apple/Packages/SalaryCore/Sources/SalaryCore/AppPresentation.swift',
    'apple/Packages/SalaryCore/Sources/SalaryCore/DateOverrideEditor.swift',
    'apple/App/LetsMakeMoneyApp.swift',
    'apple/App/AppModel.swift',
    'apple/App/AppRootView.swift',
    'apple/App/Design/WarmTheme.swift',
    'apple/App/Features/Today/TodayView.swift',
    'apple/App/Features/Calendar/SalaryCalendarView.swift',
    'apple/App/Features/Calendar/DateOverrideSheet.swift',
    'apple/App/Features/Settings/SettingsView.swift',
    'apple/App/Features/Onboarding/OnboardingView.swift',
    'scripts/apple/tests/test_app_root_playgrounds_compatibility.py',
    'scripts/apple/tests/test_apple_sdk_workflow.py',
    'scripts/apple/tests/test_ios_m3_source_contract.py',
    'scripts/apple/tests/test_playgrounds_m3_export.py'
)

$missing = @($required | Where-Object {
    -not (Test-Path -LiteralPath (Join-Path $root $_) -PathType Leaf)
})
if ($missing.Count -gt 0) {
    throw "Missing M3 files: $($missing -join ', ')"
}

Push-Location $root
try {
    & (Join-Path $PSScriptRoot 'check_ios_m2.ps1') -RequireSwift:$RequireSwift
    if ($LASTEXITCODE -ne 0) { throw 'M2 prerequisite gate failed.' }

    python -m unittest scripts.apple.tests.test_ios_m3_source_contract -v
    if ($LASTEXITCODE -ne 0) { throw 'M3 SwiftUI source contract failed.' }

    python -m unittest scripts.apple.tests.test_playgrounds_m3_export -v
    if ($LASTEXITCODE -ne 0) { throw 'M3 Playgrounds export contract failed.' }

    python -m unittest scripts.apple.tests.test_app_root_playgrounds_compatibility scripts.apple.tests.test_apple_sdk_workflow -v
    if ($LASTEXITCODE -ne 0) { throw 'M3 navigation and Apple workflow compatibility contract failed.' }

    python scripts/apple/validate_apple_localization.py --root $root
    if ($LASTEXITCODE -ne 0) { throw 'M3 localization validation failed.' }

    Write-Host 'IOS_M3_WINDOWS_GATES_PASS'
    Write-Warning 'APPLE_PLATFORM_BUILD_PENDING: SwiftUI Preview, iOS compilation and real-device layout require Swift Playgrounds or macOS/Xcode.'
} finally {
    Pop-Location
}
