param(
    [string]$OutputRoot = 'build/apple-playgrounds-core-probe'
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$output = Join-Path $root $OutputRoot
$package = Join-Path $output 'LMMCoreProbe.swiftpm'
$zip = Join-Path $output 'LMMCoreProbe-playgrounds.zip'
$appTarget = Join-Path $package 'Sources\App'
$coreTarget = Join-Path $package 'Sources\SalaryCore'

if (Test-Path -LiteralPath $package) { Remove-Item -LiteralPath $package -Recurse -Force }
if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Force }
New-Item -ItemType Directory -Path $appTarget, $coreTarget -Force | Out-Null
Copy-Item -Path (Join-Path $root 'apple\Packages\SalaryCore\Sources\SalaryCore\*.swift') -Destination $coreTarget

$manifest = @'
// swift-tools-version: 6.0
import PackageDescription
import AppleProductTypes

let package = Package(
    name: "LMMCoreProbe",
    platforms: [.iOS("18.0")],
    products: [
        .iOSApplication(
            name: "LMM Core Probe",
            targets: ["App"],
            bundleIdentifier: "com.example.letsmakemoney.coreprobe",
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
import SalaryCore
import SwiftUI

@main
struct LMMCoreProbeApp: App {
    private let configuration = AppConfiguration.defaultValue

    var body: some Scene {
        WindowGroup {
            ZStack {
                Color.orange.opacity(0.18).ignoresSafeArea()
                VStack(spacing: 18) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(.orange)
                    Text("SALARY CORE OK")
                        .font(.system(size: 38, weight: .bold))
                    Text("effective seconds: \(configuration.standardWorkSeconds)")
                        .font(.title3.monospacedDigit())
                }
            }
        }
    }
}
'@

$utf8 = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText((Join-Path $package 'Package.swift'), $manifest, $utf8)
[System.IO.File]::WriteAllText((Join-Path $appTarget 'LMMCoreProbeApp.swift'), $source, $utf8)
Compress-Archive -Path $package -DestinationPath $zip -CompressionLevel Optimal

$hash = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash
Write-Host "CORE_PROBE_PACKAGE=$package"
Write-Host "CORE_PROBE_ZIP=$zip"
Write-Host "CORE_PROBE_ZIP_SHA256=$hash"
