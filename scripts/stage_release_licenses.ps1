param(
    [Parameter(Mandatory=$true)][string]$StageDir,
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$licenseRoot = Join-Path $StageDir 'LICENSES'
$runtimeLicenses = @(
    'licenses/third-party/Godot/LICENSE.txt',
    'licenses/third-party/Godot/COPYRIGHT.txt',
    'licenses/third-party/godot-cpp/LICENSE.md',
    'licenses/third-party/MinGW-w64/COPYING',
    'licenses/third-party/MinGW-w64/COPYING.RUNTIME',
    'licenses/third-party/GCC/COPYING3',
    'licenses/third-party/GCC/COPYING.RUNTIME'
)

$rootFiles = @(
    @{ Source='LICENSE'; Target='PROJECT_LICENSE.txt' },
    @{ Source='ASSETS_LICENSE.md'; Target='ASSETS_LICENSE.md' },
    @{ Source='ASSETS_MANIFEST.md'; Target='ASSETS_MANIFEST.md' },
    @{ Source='THIRD_PARTY_NOTICES.md'; Target='THIRD_PARTY_NOTICES.md' },
    @{ Source='third_party/dependencies.json'; Target='dependencies.json' }
)

foreach ($item in $rootFiles) {
    $source = Join-Path $ProjectRoot $item.Source
    if (-not (Test-Path -LiteralPath $source)) { throw "Missing release license input: $($item.Source)" }
    $target = Join-Path $licenseRoot $item.Target
    New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force | Out-Null
    Copy-Item -LiteralPath $source -Destination $target -Force
}

foreach ($relative in $runtimeLicenses) {
    $source = Join-Path $ProjectRoot $relative
    if (-not (Test-Path -LiteralPath $source)) { throw "Missing runtime license: $relative" }
    $subpath = $relative.Substring('licenses/third-party/'.Length)
    $target = Join-Path (Join-Path $licenseRoot 'third-party') $subpath
    New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force | Out-Null
    Copy-Item -LiteralPath $source -Destination $target -Force
}

Write-Host "Release licenses staged: $licenseRoot"
