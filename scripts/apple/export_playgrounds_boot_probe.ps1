param(
    [string]$OutputRoot = 'build/apple-playgrounds-boot-probe'
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$output = Join-Path $root $OutputRoot
$package = Join-Path $output 'LMMBootProbe.swiftpm'
$zip = Join-Path $output 'LMMBootProbe-playgrounds.zip'
$sourceDirectory = Join-Path $package 'Sources\App'

if (Test-Path -LiteralPath $package) { Remove-Item -LiteralPath $package -Recurse -Force }
if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Force }
New-Item -ItemType Directory -Path $sourceDirectory -Force | Out-Null

$manifest = @'
// swift-tools-version: 6.0
import PackageDescription
import AppleProductTypes

let package = Package(
    name: "LMMBootProbe",
    platforms: [.iOS("18.0")],
    products: [
        .iOSApplication(
            name: "LMM Boot Probe",
            targets: ["App"],
            bundleIdentifier: "com.example.letsmakemoney.bootprobe",
            teamIdentifier: "",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .checkmark),
            accentColor: .presetColor(.green),
            supportedDeviceFamilies: [.phone, .pad],
            supportedInterfaceOrientations: [.portrait, .landscapeRight, .landscapeLeft]
        )
    ],
    targets: [.executableTarget(name: "App")]
)
'@

$source = @'
import SwiftUI

@main
struct LMMBootProbeApp: App {
    var body: some Scene {
        WindowGroup {
            ZStack {
                Color.green.opacity(0.22).ignoresSafeArea()
                VStack(spacing: 18) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(.green)
                    Text("BOOT OK")
                        .font(.system(size: 42, weight: .bold))
                    Text("Swift Playgrounds can run this app")
                        .font(.title3)
                }
            }
        }
    }
}
'@

$utf8 = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText((Join-Path $package 'Package.swift'), $manifest, $utf8)
[System.IO.File]::WriteAllText((Join-Path $sourceDirectory 'LMMBootProbeApp.swift'), $source, $utf8)
Compress-Archive -Path $package -DestinationPath $zip -CompressionLevel Optimal

$hash = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash
Write-Host "BOOT_PROBE_PACKAGE=$package"
Write-Host "BOOT_PROBE_ZIP=$zip"
Write-Host "BOOT_PROBE_ZIP_SHA256=$hash"
