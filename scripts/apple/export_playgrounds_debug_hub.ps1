param(
    [string]$OutputRoot = 'build/apple-playgrounds-debug-hub',
    [string]$PackageName = 'LMMDebugHub',
    [string]$BundleIdentifier = 'com.nzyzzz.letsmakemoney.debughub'
)

$ErrorActionPreference = 'Stop'

function Join-Parts {
    param([string]$Base, [string[]]$Parts)
    $path = $Base
    foreach ($part in $Parts) { $path = Join-Path $path $part }
    return $path
}

function ConvertTo-LegacyStrings {
    param([string]$CatalogPath, [string]$DestinationPath)
    $catalog = Get-Content -LiteralPath $CatalogPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $lines = foreach ($property in $catalog.strings.PSObject.Properties | Sort-Object Name) {
        $key = $property.Name
        $localized = $property.Value.localizations.'zh-Hans'.stringUnit.value
        $value = if ($null -eq $localized) { $key } else { [string]$localized }
        $escapedKey = $key.Replace('\', '\\').Replace('"', '\"')
        $escapedValue = $value.Replace('\', '\\').Replace('"', '\"').Replace("`r", '\r').Replace("`n", '\n').Replace("`t", '\t')
        '"{0}" = "{1}";' -f $escapedKey, $escapedValue
    }
    New-Item -ItemType Directory -Path (Split-Path $DestinationPath) -Force | Out-Null
    [System.IO.File]::WriteAllLines($DestinationPath, $lines, [System.Text.UTF8Encoding]::new($false))
}

$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$output = Join-Path $root $OutputRoot
$package = Join-Path $output 'LMMDebugHub.swiftpm'
$zip = Join-Path $output 'LMMDebugHub-playgrounds.zip'
$appSource = Join-Parts $root @('apple', 'App')
$coreSource = Join-Parts $root @('apple', 'Packages', 'SalaryCore', 'Sources', 'SalaryCore')
$catalog = Join-Parts $root @('apple', 'Shared', 'Resources', 'Localizable.xcstrings')
$holidayRoot = Join-Parts $root @('shared', 'salary-schema', 'v1', 'holidays')
$appTarget = Join-Parts $package @('Sources', 'App')
$coreTarget = Join-Parts $package @('Sources', 'SalaryCore')
$resources = Join-Path $appTarget 'Resources'

if (Test-Path -LiteralPath $package) { Remove-Item -LiteralPath $package -Recurse -Force }
if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Force }
New-Item -ItemType Directory -Path $appTarget, $coreTarget, $resources -Force | Out-Null

Get-ChildItem -LiteralPath $appSource -Recurse -Filter *.swift | Where-Object {
    $_.Name -notin @('LetsMakeMoneyApp.swift', 'PreviewSupport.swift')
} | ForEach-Object {
    $relative = $_.FullName.Substring($appSource.Length).TrimStart([char[]]@('\', '/'))
    $destination = Join-Path $appTarget $relative
    New-Item -ItemType Directory -Path (Split-Path $destination) -Force | Out-Null
    $source = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8
    if ($_.Name -eq 'AppRootView.swift') {
        $source = [regex]::Replace($source, '(?ms)\r?\n#Preview.*\z', '')
    }
    [System.IO.File]::WriteAllText($destination, $source, [System.Text.UTF8Encoding]::new($false))
}
Copy-Item -Path (Join-Path $coreSource '*.swift') -Destination $coreTarget
ConvertTo-LegacyStrings -CatalogPath $catalog -DestinationPath (Join-Parts $resources @('zh-Hans.lproj', 'Localizable.strings'))
Copy-Item -LiteralPath (Join-Path $holidayRoot 'cn-2025.json') -Destination $resources
Copy-Item -LiteralPath (Join-Path $holidayRoot 'cn-2026.json') -Destination $resources

$manifest = @'
// swift-tools-version: 6.0
import PackageDescription
import AppleProductTypes

let package = Package(
    name: "__PACKAGE_NAME__",
    defaultLocalization: "zh-Hans",
    platforms: [.iOS("18.0")],
    products: [
        .iOSApplication(
            name: "LMM Debug Hub",
            targets: ["App"],
            bundleIdentifier: "__BUNDLE_IDENTIFIER__",
            teamIdentifier: "",
            displayVersion: "0.1",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .checkmark),
            accentColor: .presetColor(.orange),
            supportedDeviceFamilies: [.phone, .pad],
            supportedInterfaceOrientations: [.portrait, .landscapeRight, .landscapeLeft]
        )
    ],
    targets: [
        .target(name: "SalaryCore"),
        .executableTarget(
            name: "App",
            dependencies: ["SalaryCore"],
            resources: [.process("Resources")]
        )
    ]
)
'@
$manifest = $manifest.Replace('__PACKAGE_NAME__', $PackageName).Replace('__BUNDLE_IDENTIFIER__', $BundleIdentifier)

$hubSource = @'
import Foundation
import SalaryCore
import SwiftUI

private enum DebugBootTrace {
    private static let stageKey = "lmm.debug.current_stage"

    static func beginSession() -> String {
        let lastStage = UserDefaults.standard.string(forKey: stageKey) ?? "none"
        mark("hub.launch")
        return lastStage
    }

    static func mark(_ stage: String) {
        UserDefaults.standard.set(stage, forKey: stageKey)
    }
}

private enum DebugModule: String, CaseIterable, Identifiable {
    case core
    case model
    case navigation
    case today
    case calendar
    case settings
    case onboarding
    case fullApp

    var id: String { rawValue }
    var title: String { rawValue.uppercased() }
}

@main
struct LMMDebugHubApp: App {
    @StateObject private var model: AppModel
    private let lastStage: String

    init() {
        lastStage = DebugBootTrace.beginSession()
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appending(path: "LMMDebugHub")
        _model = StateObject(wrappedValue: AppModel(
            store: ConfigurationStore(directoryURL: root),
            logger: LocalEventLogger(directoryURL: root),
            holidays: HolidayDataLoader.load()
        ))
    }

    var body: some Scene {
        WindowGroup {
            DebugHubView(lastStage: lastStage)
                .environmentObject(model)
                .task { await model.load() }
        }
    }
}

private struct DebugHubView: View {
    @EnvironmentObject private var model: AppModel
    @State private var selected: DebugModule?
    @State private var currentStage = "hub.launch"
    let lastStage: String

    var body: some View {
        NavigationStack {
            List {
                Section("LAST SESSION") {
                    LabeledContent("LAST STAGE", value: lastStage)
                    LabeledContent("CURRENT STAGE", value: currentStage)
                }
                Section("OPEN ONE LAYER AT A TIME") {
                    ForEach(DebugModule.allCases) { module in
                        Button {
                            markOpening(module)
                            selected = module
                        } label: {
                            HStack {
                                Text(module.title)
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                        }
                    }
                }
                Section("RECOVERY") {
                    Text("If a module silently crashes, relaunch this app. LAST STAGE identifies the failing boundary.")
                        .font(.footnote)
                }
            }
            .navigationTitle("LMM DEBUG HUB")
        }
        .sheet(item: $selected) { module in
            NavigationStack {
                moduleView(module)
                    .navigationTitle(module.title)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("DONE") { selected = nil }
                        }
                    }
            }
            .onAppear { markVisible(module) }
            .environmentObject(model)
        }
    }

    private func markOpening(_ module: DebugModule) {
        currentStage = "opening." + module.rawValue
        DebugBootTrace.mark(currentStage)
    }

    private func markVisible(_ module: DebugModule) {
        currentStage = "visible." + module.rawValue
        DebugBootTrace.mark(currentStage)
    }

    @ViewBuilder
    private func moduleView(_ module: DebugModule) -> some View {
        switch module {
        case .core:
            DebugStatusView(title: "SALARY CORE", value: String(model.configuration.standardWorkSeconds))
        case .model:
            DebugStatusView(title: "APP MODEL", value: String(describing: model.navigation.destination))
        case .navigation:
            DebugNavigationView()
        case .today:
            TodayView()
        case .calendar:
            SalaryCalendarView(compact: false)
        case .settings:
            SettingsView()
        case .onboarding:
            OnboardingView()
        case .fullApp:
            AppRootView()
        }
    }
}

private struct DebugNavigationView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        TabView(selection: destinationBinding) {
            Text("TAB TODAY")
                .tabItem { Label("TODAY", systemImage: "yensign.circle") }
                .tag(AppDestination.today)
            Text("TAB CALENDAR")
                .tabItem { Label("CALENDAR", systemImage: "calendar") }
                .tag(AppDestination.calendar)
        }
    }

    private var destinationBinding: Binding<AppDestination> {
        Binding(get: { model.navigation.destination }, set: { model.select($0) })
    }
}

private struct DebugStatusView: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
            Text(title).font(.largeTitle.bold())
            Text(value).font(.title3.monospacedDigit())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.green.opacity(0.08).ignoresSafeArea())
    }
}
'@

$utf8 = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText((Join-Path $package 'Package.swift'), $manifest, $utf8)
[System.IO.File]::WriteAllText((Join-Path $appTarget 'LMMDebugHubApp.swift'), $hubSource, $utf8)
Compress-Archive -Path $package -DestinationPath $zip -CompressionLevel Optimal
$hash = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash
Write-Host "DEBUG_HUB_PACKAGE=$package"
Write-Host "DEBUG_HUB_ZIP=$zip"
Write-Host "DEBUG_HUB_ZIP_SHA256=$hash"
