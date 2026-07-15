param(
    [string]$OutputRoot = 'build/apple-playgrounds-resource-probe'
)

$ErrorActionPreference = 'Stop'

function ConvertTo-LegacyStrings {
    param(
        [Parameter(Mandatory = $true)][string]$CatalogPath,
        [Parameter(Mandatory = $true)][string]$DestinationPath
    )

    $catalog = Get-Content -LiteralPath $CatalogPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $lines = foreach ($property in $catalog.strings.PSObject.Properties | Sort-Object Name) {
        $key = $property.Name
        $localization = $property.Value.localizations.'zh-Hans'.stringUnit.value
        $value = if ($null -eq $localization) { $key } else { [string]$localization }
        $escapedKey = $key.Replace('\', '\\').Replace('"', '\"')
        $escapedValue = $value.Replace('\', '\\').Replace('"', '\"').Replace("`r", '\r').Replace("`n", '\n').Replace("`t", '\t')
        '"{0}" = "{1}";' -f $escapedKey, $escapedValue
    }
    New-Item -ItemType Directory -Path (Split-Path $DestinationPath) -Force | Out-Null
    [System.IO.File]::WriteAllLines(
        $DestinationPath,
        $lines,
        [System.Text.UTF8Encoding]::new($false)
    )
}

$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$output = Join-Path $root $OutputRoot
$package = Join-Path $output 'LMMMainResourceProbe.swiftpm'
$zip = Join-Path $output 'LMMMainResourceProbe-playgrounds.zip'
$appTarget = Join-Path $package 'Sources\App'
$resources = Join-Path $appTarget 'Resources'

if (Test-Path -LiteralPath $package) { Remove-Item -LiteralPath $package -Recurse -Force }
if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Force }
New-Item -ItemType Directory -Path $appTarget, $resources -Force | Out-Null

ConvertTo-LegacyStrings `
    -CatalogPath (Join-Path $root 'apple\Shared\Resources\Localizable.xcstrings') `
    -DestinationPath (Join-Path $resources 'zh-Hans.lproj\Localizable.strings')
Copy-Item -LiteralPath (Join-Path $root 'shared\salary-schema\v1\holidays\cn-2026.json') -Destination $resources

$manifest = @'
// swift-tools-version: 6.0
import PackageDescription
import AppleProductTypes

let package = Package(
    name: "LMMMainResourceProbe",
    defaultLocalization: "zh-Hans",
    platforms: [.iOS("18.0")],
    products: [
        .iOSApplication(
            name: "LMM Main Resource Probe",
            targets: ["App"],
            bundleIdentifier: "com.example.letsmakemoney.mainresourceprobe",
            teamIdentifier: "",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .checkmark),
            accentColor: .presetColor(.blue),
            supportedDeviceFamilies: [.phone, .pad],
            supportedInterfaceOrientations: [.portrait, .landscapeRight, .landscapeLeft]
        )
    ],
    targets: [
        .executableTarget(
            name: "App",
            resources: [.process("Resources")]
        )
    ]
)
'@

$source = @'
import Foundation
import SwiftUI

@main
struct LMMMainResourceProbeApp: App {
    private let mainJSON = Bundle.main.url(forResource: "cn-2026", withExtension: "json") != nil
    private let mainText = String(localized: "today.amount", bundle: .main)

    var body: some Scene {
        WindowGroup {
            ZStack {
                Color.blue.opacity(0.14).ignoresSafeArea()
                VStack(alignment: .leading, spacing: 16) {
                    Text("RESOURCE PROBE")
                        .font(.system(size: 34, weight: .bold))
                    ProbeRow(label: "MAIN JSON", passed: mainJSON)
                    Text("MAIN STRING: \(mainText)")
                }
                .font(.title3.monospaced())
                .padding(32)
            }
        }
    }
}

private struct ProbeRow: View {
    let label: String
    let passed: Bool

    var body: some View {
        HStack {
            Image(systemName: passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(passed ? .green : .red)
            Text("\(label): \(passed ? "OK" : "FAIL")")
        }
    }
}
'@

$utf8 = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText((Join-Path $package 'Package.swift'), $manifest, $utf8)
[System.IO.File]::WriteAllText((Join-Path $appTarget 'LMMMainResourceProbeApp.swift'), $source, $utf8)
Compress-Archive -Path $package -DestinationPath $zip -CompressionLevel Optimal

$hash = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash
Write-Host "RESOURCE_PROBE_PACKAGE=$package"
Write-Host "RESOURCE_PROBE_ZIP=$zip"
Write-Host "RESOURCE_PROBE_ZIP_SHA256=$hash"
