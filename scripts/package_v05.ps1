param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$Version = "0.5-beta"
)

$ErrorActionPreference = "Stop"

$PackageName = "LetsMakeMoney-v0.5-beta-windows-x86_64"
$ReleaseDir = Join-Path $ProjectRoot "releases\v0.5"
$StageDir = Join-Path $ReleaseDir $PackageName
$ZipPath = Join-Path $ReleaseDir "$PackageName.zip"

$packageFiles = @(
    @{ Source = "build\LetsMakeMoney.exe"; Target = "LetsMakeMoney.exe"; Role = "application" },
    @{ Source = "build\letsmakemoney_native.dll"; Target = "letsmakemoney_native.dll"; Role = "native_bridge" },
    @{ Source = "icons\app_icon.ico"; Target = "app_icon.ico"; Role = "tray_icon" },
    @{ Source = "README.md"; Target = "README.md"; Role = "quick_start" },
    @{ Source = "releases\v0.5-beta-notes.md"; Target = "release-notes.md"; Role = "release_notes" }
)

foreach ($file in $packageFiles) {
    $sourcePath = Join-Path $ProjectRoot $file.Source
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        throw "Missing package input: $sourcePath"
    }
}

New-Item -ItemType Directory -Force -Path $ReleaseDir | Out-Null
if (Test-Path -LiteralPath $StageDir) {
    Remove-Item -LiteralPath $StageDir -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $StageDir | Out-Null

foreach ($file in $packageFiles) {
    Copy-Item -LiteralPath (Join-Path $ProjectRoot $file.Source) -Destination (Join-Path $StageDir $file.Target) -Force
}

$manifestFiles = @()
foreach ($file in $packageFiles) {
    $targetPath = Join-Path $StageDir $file.Target
    $manifestFiles += [ordered]@{
        path = $file.Target
        role = $file.Role
        size = (Get-Item -LiteralPath $targetPath).Length
        sha256 = (Get-FileHash -LiteralPath $targetPath -Algorithm SHA256).Hash.ToLowerInvariant()
    }
}

$manifest = [ordered]@{
    package_name = $PackageName
    version = $Version
    platform = "windows-x86_64"
    generated_at = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    config_path = "%APPDATA%\LetsMakeMoney\config.json"
    files = $manifestFiles
}

$manifestPath = Join-Path $StageDir "manifest.json"
$manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $manifestPath -Encoding UTF8

$checksumLines = @()
foreach ($filePath in Get-ChildItem -LiteralPath $StageDir -File | Sort-Object Name) {
    if ($filePath.Name -eq "checksums.txt") {
        continue
    }
    $hash = (Get-FileHash -LiteralPath $filePath.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    $checksumLines += "$hash  $($filePath.Name)"
}
$checksumLines | Set-Content -LiteralPath (Join-Path $StageDir "checksums.txt") -Encoding UTF8

if (Test-Path -LiteralPath $ZipPath) {
    Remove-Item -LiteralPath $ZipPath -Force
}
Compress-Archive -Path (Join-Path $StageDir "*") -DestinationPath $ZipPath -Force

Write-Host "v0.5 package created: $ZipPath"
