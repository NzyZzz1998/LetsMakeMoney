param(
    [string]$OutputRoot = 'build/apple-playgrounds-app-model-probe'
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$output = Join-Path $root $OutputRoot
$package = Join-Path $output 'LMMAppModelProbe.swiftpm'
$zip = Join-Path $output 'LMMAppModelProbe-playgrounds.zip'
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
    name: "LMMAppModelProbe",
    platforms: [.iOS("18.0")],
    products: [
        .iOSApplication(
            name: "LMM App Model Probe",
            targets: ["App"],
            bundleIdentifier: "com.example.letsmakemoney.appmodelprobe",
            teamIdentifier: "",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .checkmark),
            accentColor: .presetColor(.purple),
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
import SalaryCore
import SwiftUI

@main
struct LMMAppModelProbeApp: App {
    @StateObject private var model: AppModel

    init() {
        let root = FileManager.default.temporaryDirectory
            .appending(path: "LMMAppModelProbe")
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
            AppModelProbeView(model: model)
        }
    }
}

private struct AppModelProbeView: View {
    @ObservedObject var model: AppModel
    @State private var loadCompleted = false

    var body: some View {
        ZStack {
            Color.purple.opacity(0.14).ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: loadCompleted ? "checkmark.circle.fill" : "hourglass.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(loadCompleted ? .green : .purple)
                Text(loadCompleted ? "APP MODEL OK" : "APP MODEL LOADING")
                    .font(.system(size: 36, weight: .bold))
                Text("effective seconds: \(model.configuration.standardWorkSeconds)")
                    .font(.title3.monospacedDigit())
                Text("modal: \(model.navigation.modal?.rawValue ?? "none")")
                    .font(.title3.monospaced())
            }
        }
        .task {
            await model.load()
            loadCompleted = true
        }
    }
}
'@

$utf8 = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText((Join-Path $package 'Package.swift'), $manifest, $utf8)
[System.IO.File]::WriteAllText((Join-Path $appTarget 'LMMAppModelProbeApp.swift'), $source, $utf8)
Compress-Archive -Path $package -DestinationPath $zip -CompressionLevel Optimal

$hash = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash
Write-Host "APP_MODEL_PROBE_PACKAGE=$package"
Write-Host "APP_MODEL_PROBE_ZIP=$zip"
Write-Host "APP_MODEL_PROBE_ZIP_SHA256=$hash"
