param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [switch]$SkipExport
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "project_version.ps1")
$version = Get-LetsMakeMoneyVersion -ProjectRoot $ProjectRoot
$packageName = "LetsMakeMoney-v$version-windows-x86_64"
$releaseDir = Join-Path $ProjectRoot "releases\v0.6"
$stageDir = Join-Path $releaseDir $packageName
$zipPath = Join-Path $releaseDir "$packageName.zip"

if (-not $SkipExport) {
    & (Join-Path $PSScriptRoot "verify_m5.ps1") -OutputPath (Join-Path $ProjectRoot "build\LetsMakeMoney.exe")
    if ($LASTEXITCODE -ne 0) { throw "v0.6 export failed." }
}

$packageFiles = @(
    @{ Source = "build\LetsMakeMoney.exe"; Target = "LetsMakeMoney.exe"; Role = "application" },
    @{ Source = "build\letsmakemoney_native.dll"; Target = "letsmakemoney_native.dll"; Role = "native_bridge" },
    @{ Source = "icons\app_icon.ico"; Target = "app_icon.ico"; Role = "tray_icon" },
    @{ Source = "README.md"; Target = "README.md"; Role = "quick_start" },
    @{ Source = "releases\v0.6-beta-notes.md"; Target = "release-notes.md"; Role = "release_notes" }
)
foreach ($file in $packageFiles) {
    $source = Join-Path $ProjectRoot $file.Source
    if (-not (Test-Path -LiteralPath $source)) { throw "Missing package input: $source" }
}

New-Item -ItemType Directory -Force -Path $releaseDir | Out-Null
if (Test-Path -LiteralPath $stageDir) { Remove-Item -LiteralPath $stageDir -Recurse -Force }
New-Item -ItemType Directory -Force -Path $stageDir | Out-Null
foreach ($file in $packageFiles) {
    Copy-Item -LiteralPath (Join-Path $ProjectRoot $file.Source) -Destination (Join-Path $stageDir $file.Target) -Force
}

$manifestFiles = foreach ($file in $packageFiles) {
    $target = Join-Path $stageDir $file.Target
    [ordered]@{
        path = $file.Target
        role = $file.Role
        size = (Get-Item -LiteralPath $target).Length
        sha256 = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLowerInvariant()
    }
}
$manifest = [ordered]@{
    package_name = $packageName
    version = $version
    platform = "windows-x86_64"
    generated_at = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    config_path = "%APPDATA%\LetsMakeMoney\config.json"
    files = @($manifestFiles)
}
$manifest | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $stageDir "manifest.json") -Encoding UTF8

$checksumLines = foreach ($file in Get-ChildItem -LiteralPath $stageDir -File | Sort-Object Name) {
    $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    "$hash  $($file.Name)"
}
$checksumLines | Set-Content -LiteralPath (Join-Path $stageDir "checksums.txt") -Encoding UTF8
if (Test-Path -LiteralPath $zipPath) { Remove-Item -LiteralPath $zipPath -Force }
Compress-Archive -Path (Join-Path $stageDir "*") -DestinationPath $zipPath -Force
Write-Host "v0.6 package created: $zipPath"
