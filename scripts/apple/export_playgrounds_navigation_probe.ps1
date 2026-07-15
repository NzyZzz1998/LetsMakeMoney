param(
    [string]$OutputRoot = 'build/apple-playgrounds-navigation-closure-probe'
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$output = Join-Path $root $OutputRoot
$package = Join-Path $output 'LMMNavigationClosureProbe.swiftpm'
$zip = Join-Path $output 'LMMNavigationClosureProbe-playgrounds.zip'
$appTarget = Join-Path $package 'Sources\App'
$coreTarget = Join-Path $package 'Sources\SalaryCore'

if (Test-Path -LiteralPath $package) { Remove-Item -LiteralPath $package -Recurse -Force }
if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Force }
New-Item -ItemType Directory -Path $appTarget, $coreTarget -Force | Out-Null
Copy-Item -Path (Join-Path $root 'apple\Packages\SalaryCore\Sources\SalaryCore\*.swift') -Destination $coreTarget
Copy-Item -LiteralPath (Join-Path $root 'apple\App\AppModel.swift') -Destination $appTarget

$manifest = @'
// swift-tools-version: 6.0
import PackageDescription
import AppleProductTypes

let package = Package(
    name: "LMMNavigationClosureProbe",
    platforms: [.iOS("18.0")],
    products: [
        .iOSApplication(
            name: "LMM Navigation Closure Probe",
            targets: ["App"],
            bundleIdentifier: "com.example.letsmakemoney.navigationclosureprobe",
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
struct LMMNavigationClosureProbeApp: App {
    @StateObject private var model: AppModel

    init() {
        let root = FileManager.default.temporaryDirectory
            .appending(path: "LMMNavigationClosureProbe")
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
            NavigationProbeView()
                .environmentObject(model)
        }
    }
}

private struct NavigationProbeView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        TabView(selection: destinationBinding) {
            ProbePage(title: "TAB TODAY", color: .orange)
                .tabItem { Label("TODAY", systemImage: "yensign.circle") }
                .tag(AppDestination.today)
            ProbePage(title: "TAB CALENDAR", color: .green)
                .tabItem { Label("CALENDAR", systemImage: "calendar") }
                .tag(AppDestination.calendar)
        }
    }

    private var destinationBinding: Binding<AppDestination> {
        Binding(get: { model.navigation.destination }, set: { model.select($0) })
    }
}

private struct ProbePage: View {
    let title: String
    let color: Color

    var body: some View {
        ZStack {
            color.opacity(0.16).ignoresSafeArea()
            Text(title).font(.system(size: 38, weight: .bold))
        }
    }
}
'@

$utf8 = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText((Join-Path $package 'Package.swift'), $manifest, $utf8)
[System.IO.File]::WriteAllText((Join-Path $appTarget 'LMMNavigationProbeApp.swift'), $source, $utf8)
Compress-Archive -Path $package -DestinationPath $zip -CompressionLevel Optimal

$hash = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash
Write-Host "NAVIGATION_PROBE_PACKAGE=$package"
Write-Host "NAVIGATION_PROBE_ZIP=$zip"
Write-Host "NAVIGATION_PROBE_ZIP_SHA256=$hash"
