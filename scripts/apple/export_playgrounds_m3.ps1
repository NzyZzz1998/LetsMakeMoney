param(
    [string]$OutputRoot = 'build/apple-playgrounds',
    [string]$PackageName = 'LetsMakeMoneyM3',
    [string]$BundleIdentifier = 'com.example.letsmakemoney.m3',
    [switch]$ExcludePreviews
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
$package = Join-Path $output "$PackageName.swiftpm"
$zip = Join-Path $output "$PackageName-playgrounds.zip"
$appSource = Join-Path (Join-Path $root 'apple') 'App'
$coreSource = Join-Path (Join-Path (Join-Path (Join-Path (Join-Path $root 'apple') 'Packages') 'SalaryCore') 'Sources') 'SalaryCore'
$catalogPath = Join-Path (Join-Path (Join-Path (Join-Path $root 'apple') 'Shared') 'Resources') 'Localizable.xcstrings'
$holidayRoot = Join-Path (Join-Path (Join-Path (Join-Path $root 'shared') 'salary-schema') 'v1') 'holidays'

if (Test-Path -LiteralPath $package) { Remove-Item -LiteralPath $package -Recurse -Force }
if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Force }

$appTarget = Join-Path $package 'Sources\App'
$coreTarget = Join-Path $package 'Sources\SalaryCore'
$resources = Join-Path $appTarget 'Resources'
New-Item -ItemType Directory -Path $appTarget, $coreTarget, $resources -Force | Out-Null

Get-ChildItem $appSource -Recurse -Filter *.swift | ForEach-Object {
    if ($ExcludePreviews -and $_.Name -eq 'PreviewSupport.swift') { return }
    $relative = $_.FullName.Substring($appSource.Length).TrimStart([char[]]@('\', '/'))
    $destination = Join-Path $appTarget $relative
    New-Item -ItemType Directory -Path (Split-Path $destination) -Force | Out-Null
    if ($ExcludePreviews -and $_.Name -eq 'AppRootView.swift') {
        $source = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8
        $source = [regex]::Replace($source, '(?ms)\r?\n#Preview.*\z', '')
        [System.IO.File]::WriteAllText($destination, $source, [System.Text.UTF8Encoding]::new($false))
    } else {
        Copy-Item -LiteralPath $_.FullName -Destination $destination
    }
}
Copy-Item -Path (Join-Path $coreSource '*.swift') -Destination $coreTarget
$legacyStrings = Join-Path $resources 'zh-Hans.lproj\Localizable.strings'
ConvertTo-LegacyStrings `
    -CatalogPath $catalogPath `
    -DestinationPath $legacyStrings
Copy-Item -LiteralPath (Join-Path $holidayRoot 'cn-2025.json') -Destination $resources
Copy-Item -LiteralPath (Join-Path $holidayRoot 'cn-2026.json') -Destination $resources

$packageManifest = @'
// swift-tools-version: 6.0
import PackageDescription
import AppleProductTypes

let package = Package(
    name: "__PACKAGE_NAME__",
    defaultLocalization: "zh-Hans",
    platforms: [.iOS("18.0")],
    products: [
        .iOSApplication(
            name: "LetsMakeMoney",
            targets: ["App"],
            bundleIdentifier: "__BUNDLE_IDENTIFIER__",
            teamIdentifier: "",
            displayVersion: "0.1",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .checkmark),
            accentColor: .presetColor(.orange),
            supportedDeviceFamilies: [.phone, .pad],
            supportedInterfaceOrientations: [
                .portrait, .landscapeRight, .landscapeLeft
            ]
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
$packageManifest = $packageManifest.Replace('__PACKAGE_NAME__', $PackageName)
$packageManifest = $packageManifest.Replace('__BUNDLE_IDENTIFIER__', $BundleIdentifier)
[System.IO.File]::WriteAllText(
    (Join-Path $package 'Package.swift'),
    $packageManifest,
    [System.Text.UTF8Encoding]::new($false)
)

Compress-Archive -Path $package -DestinationPath $zip -CompressionLevel Optimal
$hash = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash
Write-Host "PLAYGROUNDS_PACKAGE=$package"
Write-Host "PLAYGROUNDS_ZIP=$zip"
Write-Host "PLAYGROUNDS_ZIP_SHA256=$hash"
