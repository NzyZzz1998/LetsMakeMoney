param(
    [string]$OutputRoot = 'build/apple-playgrounds-settings-onboarding-probe'
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$output = Join-Path $root $OutputRoot
$package = Join-Path $output 'LMMSettingsOnboardingProbe.swiftpm'
$zip = Join-Path $output 'LMMSettingsOnboardingProbe-playgrounds.zip'
$appTarget = Join-Path $package 'Sources\App'
$coreTarget = Join-Path $package 'Sources\SalaryCore'

if (Test-Path -LiteralPath $package) { Remove-Item -LiteralPath $package -Recurse -Force }
if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Force }
New-Item -ItemType Directory -Path $appTarget, $coreTarget -Force | Out-Null
Copy-Item -Path (Join-Path $root 'apple\Packages\SalaryCore\Sources\SalaryCore\*.swift') -Destination $coreTarget
Copy-Item -LiteralPath (Join-Path $root 'apple\App\AppModel.swift') -Destination $appTarget
Copy-Item -LiteralPath (Join-Path $root 'apple\App\Design\WarmTheme.swift') -Destination $appTarget
Copy-Item -LiteralPath (Join-Path $root 'apple\App\Features\Settings\SettingsView.swift') -Destination $appTarget
Copy-Item -LiteralPath (Join-Path $root 'apple\App\Features\Onboarding\OnboardingView.swift') -Destination $appTarget

$manifest = @'
// swift-tools-version: 6.0
import PackageDescription
import AppleProductTypes

let package = Package(
    name: "LMMSettingsOnboardingProbe",
    platforms: [.iOS("18.0")],
    products: [
        .iOSApplication(
            name: "LMM Settings Onboarding Probe",
            targets: ["App"],
            bundleIdentifier: "com.example.letsmakemoney.settingsonboardingprobe",
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

$source = @'
import Foundation
import SalaryCore
import SwiftUI

@main
struct LMMSettingsOnboardingProbeApp: App {
    @StateObject private var model: AppModel

    init() {
        let root = FileManager.default.temporaryDirectory
            .appending(path: "LMMSettingsOnboardingProbe")
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
            SettingsOnboardingProbeView()
                .environmentObject(model)
                .task { await model.load() }
        }
    }
}

private struct SettingsOnboardingProbeView: View {
    @State private var screen = ProbeScreen.settings

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { screen = .settings } label: { Text("SHOW SETTINGS") }
                Button { screen = .onboarding } label: { Text("SHOW ONBOARDING") }
            }
            .buttonStyle(.borderedProminent)
            .padding(8)

            switch screen {
            case .settings:
                SettingsView()
            case .onboarding:
                OnboardingView()
            }
        }
    }
}

private enum ProbeScreen {
    case settings
    case onboarding
}
'@

$utf8 = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText((Join-Path $package 'Package.swift'), $manifest, $utf8)
[System.IO.File]::WriteAllText((Join-Path $appTarget 'LMMSettingsOnboardingProbeApp.swift'), $source, $utf8)
Compress-Archive -Path $package -DestinationPath $zip -CompressionLevel Optimal

$hash = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash
Write-Host "SETTINGS_ONBOARDING_PROBE_PACKAGE=$package"
Write-Host "SETTINGS_ONBOARDING_PROBE_ZIP=$zip"
Write-Host "SETTINGS_ONBOARDING_PROBE_ZIP_SHA256=$hash"
