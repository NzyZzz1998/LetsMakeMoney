param(
    [string]$OutputRoot = 'build/apple-playgrounds-calendar-ui-probe'
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$output = Join-Path $root $OutputRoot
$package = Join-Path $output 'LMMCalendarUIProbe.swiftpm'
$zip = Join-Path $output 'LMMCalendarUIProbe-playgrounds.zip'
$appTarget = Join-Path $package 'Sources\App'
$coreTarget = Join-Path $package 'Sources\SalaryCore'

if (Test-Path -LiteralPath $package) { Remove-Item -LiteralPath $package -Recurse -Force }
if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Force }
New-Item -ItemType Directory -Path $appTarget, $coreTarget -Force | Out-Null
Copy-Item -Path (Join-Path $root 'apple\Packages\SalaryCore\Sources\SalaryCore\*.swift') -Destination $coreTarget
Copy-Item -LiteralPath (Join-Path $root 'apple\App\AppModel.swift') -Destination $appTarget
Copy-Item -LiteralPath (Join-Path $root 'apple\App\Design\WarmTheme.swift') -Destination $appTarget
Copy-Item -LiteralPath (Join-Path $root 'apple\App\Features\Calendar\SalaryCalendarView.swift') -Destination $appTarget
Copy-Item -LiteralPath (Join-Path $root 'apple\App\Features\Calendar\DateOverrideSheet.swift') -Destination $appTarget

$manifest = @'
// swift-tools-version: 6.0
import PackageDescription
import AppleProductTypes

let package = Package(
    name: "LMMCalendarUIProbe",
    platforms: [.iOS("18.0")],
    products: [
        .iOSApplication(
            name: "LMM Calendar UI Probe",
            targets: ["App"],
            bundleIdentifier: "com.example.letsmakemoney.calendaruiprobe",
            teamIdentifier: "",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .checkmark),
            accentColor: .presetColor(.green),
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
struct LMMCalendarUIProbeApp: App {
    @StateObject private var model: AppModel

    init() {
        let root = FileManager.default.temporaryDirectory
            .appending(path: "LMMCalendarUIProbe")
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
            ZStack(alignment: .topTrailing) {
                SalaryCalendarView(compact: false)
                    .environmentObject(model)
                Text("CALENDAR UI PROBE")
                    .font(.caption.bold())
                    .padding(8)
                    .background(.green.opacity(0.24), in: Capsule())
                    .padding(12)
            }
            .task { await model.load() }
        }
    }
}
'@

$utf8 = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText((Join-Path $package 'Package.swift'), $manifest, $utf8)
[System.IO.File]::WriteAllText((Join-Path $appTarget 'LMMCalendarUIProbeApp.swift'), $source, $utf8)
Compress-Archive -Path $package -DestinationPath $zip -CompressionLevel Optimal

$hash = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash
Write-Host "CALENDAR_UI_PROBE_PACKAGE=$package"
Write-Host "CALENDAR_UI_PROBE_ZIP=$zip"
Write-Host "CALENDAR_UI_PROBE_ZIP_SHA256=$hash"
