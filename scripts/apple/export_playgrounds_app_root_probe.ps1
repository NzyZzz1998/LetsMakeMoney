param(
    [string]$OutputRoot = 'build/apple-playgrounds-app-root-body-probe'
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$output = Join-Path $root $OutputRoot
$package = Join-Path $output 'LMMAppRootBodyProbe.swiftpm'
$zip = Join-Path $output 'LMMAppRootBodyProbe-playgrounds.zip'
$appTarget = Join-Path $package 'Sources\App'
$coreTarget = Join-Path $package 'Sources\SalaryCore'

if (Test-Path -LiteralPath $package) { Remove-Item -LiteralPath $package -Recurse -Force }
if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Force }
New-Item -ItemType Directory -Path $appTarget, $coreTarget -Force | Out-Null
Copy-Item -Path (Join-Path $root 'apple\Packages\SalaryCore\Sources\SalaryCore\*.swift') -Destination $coreTarget
Copy-Item -LiteralPath (Join-Path $root 'apple\App\AppModel.swift') -Destination $appTarget
Copy-Item -LiteralPath (Join-Path $root 'apple\App\Design\WarmTheme.swift') -Destination $appTarget

$appRoot = Get-Content -LiteralPath (Join-Path $root 'apple\App\AppRootView.swift') -Raw -Encoding UTF8
$appRoot = [regex]::Replace($appRoot, '(?ms)\r?\n#Preview.*\z', '')
$appRoot = [regex]::Replace(
    $appRoot,
    '(?ms)\r?\n        \.toolbar \{.*?\r?\n        \.fullScreenCover\(isPresented: modalBinding\(\.onboarding\)\) \{ OnboardingView\(\) \}',
    ''
)

$manifest = @'
// swift-tools-version: 6.0
import PackageDescription
import AppleProductTypes

let package = Package(
    name: "LMMAppRootBodyProbe",
    platforms: [.iOS("18.0")],
    products: [
        .iOSApplication(
            name: "LMM App Root Body Probe",
            targets: ["App"],
            bundleIdentifier: "com.example.letsmakemoney.approotbodyprobe",
            teamIdentifier: "",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .checkmark),
            accentColor: .presetColor(.orange),
            supportedDeviceFamilies: [.phone, .pad],
            supportedInterfaceOrientations: [.portrait, .landscapeRight, .landscapeLeft]
        )
    ],
    targets: [
        .target(name: "SalaryCore"),
        .executableTarget(name: "App", dependencies: ["SalaryCore"])
    ]
)
'@

$stubs = @'
import SwiftUI

struct TodayView: View {
    var body: some View { Text("STUB TODAY") }
}

struct SalaryCalendarView: View {
    let compact: Bool
    var body: some View {
        Text(compact ? "STUB CALENDAR COMPACT" : "STUB CALENDAR")
    }
}

struct SettingsView: View {
    var body: some View { Text("STUB SETTINGS") }
}

struct OnboardingView: View {
    var body: some View { Text("STUB ONBOARDING") }
}
'@

$source = @'
import SalaryCore
import SwiftUI

@main
struct LMMAppRootBodyProbeApp: App {
    @StateObject private var model: AppModel

    init() {
        let root = FileManager.default.temporaryDirectory
            .appending(path: "LMMAppRootBodyProbe")
        _model = StateObject(wrappedValue: AppModel(
            store: ConfigurationStore(directoryURL: root),
            logger: LocalEventLogger(directoryURL: root),
            holidays: HolidayCalendar(
                version: "probe",
                officialDatasets: [],
                coveredYears: []
            )
        ))
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(model)
                .environment(\.horizontalSizeClass, .compact)
        }
    }
}
'@

$utf8 = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText((Join-Path $package 'Package.swift'), $manifest, $utf8)
[System.IO.File]::WriteAllText((Join-Path $appTarget 'AppRootView.swift'), $appRoot, $utf8)
[System.IO.File]::WriteAllText((Join-Path $appTarget 'StubFeatureViews.swift'), $stubs, $utf8)
[System.IO.File]::WriteAllText((Join-Path $appTarget 'LMMAppRootProbeApp.swift'), $source, $utf8)
Compress-Archive -Path $package -DestinationPath $zip -CompressionLevel Optimal

$hash = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash
Write-Host "APP_ROOT_PROBE_PACKAGE=$package"
Write-Host "APP_ROOT_PROBE_ZIP=$zip"
Write-Host "APP_ROOT_PROBE_ZIP_SHA256=$hash"
