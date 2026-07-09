param(
    [string]$PackagePath = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")).Path "releases\v0.5\LetsMakeMoney-v0.5-beta-windows-x86_64.zip"),
    [string]$ExtractRoot = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")).Path ".tmp_release\verify_v05_package"),
    [string]$SmokeAppDataRoot = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")).Path ".tmp_appdata\verify_v05_package"),
    [int]$SmokeSeconds = 5
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $PackagePath)) {
    throw "Missing v0.5 package: $PackagePath"
}

if (Test-Path -LiteralPath $ExtractRoot) {
    Remove-Item -LiteralPath $ExtractRoot -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $ExtractRoot | Out-Null
Expand-Archive -LiteralPath $PackagePath -DestinationPath $ExtractRoot -Force

$requiredFiles = @(
    "LetsMakeMoney.exe",
    "letsmakemoney_native.dll",
    "app_icon.ico",
    "README.md",
    "release-notes.md",
    "manifest.json",
    "checksums.txt"
)

foreach ($file in $requiredFiles) {
    $path = Join-Path $ExtractRoot $file
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Package is missing required file: $file"
    }
}

$manifest = Get-Content -Raw -LiteralPath (Join-Path $ExtractRoot "manifest.json") | ConvertFrom-Json
if ($manifest.package_name -ne "LetsMakeMoney-v0.5-beta-windows-x86_64") {
    throw "Unexpected package_name in manifest: $($manifest.package_name)"
}
if ($manifest.config_path -ne "%APPDATA%\LetsMakeMoney\config.json") {
    throw "Unexpected config_path in manifest: $($manifest.config_path)"
}
if ($manifest.version -ne "0.5-beta") {
    throw "Unexpected version in manifest: $($manifest.version)"
}

foreach ($file in $manifest.files) {
    $filePath = Join-Path $ExtractRoot $file.path
    if (-not (Test-Path -LiteralPath $filePath)) {
        throw "Manifest file is missing from package: $($file.path)"
    }
    $actualHash = (Get-FileHash -LiteralPath $filePath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actualHash -ne $file.sha256) {
        throw "SHA256 mismatch for $($file.path): expected $($file.sha256), got $actualHash"
    }
}

$checksumPath = Join-Path $ExtractRoot "checksums.txt"
$checksumLines = Get-Content -LiteralPath $checksumPath | Where-Object { $_.Trim().Length -gt 0 }
foreach ($line in $checksumLines) {
    $parts = $line -split "\s+", 2
    if ($parts.Count -ne 2) {
        throw "Invalid checksum line: $line"
    }
    $expectedHash = $parts[0].Trim().ToLowerInvariant()
    $fileName = $parts[1].Trim()
    $filePath = Join-Path $ExtractRoot $fileName
    if (-not (Test-Path -LiteralPath $filePath)) {
        throw "Checksum file entry missing from package: $fileName"
    }
    $actualHash = (Get-FileHash -LiteralPath $filePath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actualHash -ne $expectedHash) {
        throw "Checksum mismatch for $fileName"
    }
}

$originalAppData = $env:APPDATA
$env:APPDATA = $SmokeAppDataRoot
New-Item -ItemType Directory -Force -Path (Join-Path $env:APPDATA "LetsMakeMoney") | Out-Null
@{
    minimize_to_tray = $false
    pure_pet_mode = $false
    debug_mode = $false
} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $env:APPDATA "LetsMakeMoney\config.json") -Encoding UTF8

try {
    $exe = Join-Path $ExtractRoot "LetsMakeMoney.exe"
    $process = Start-Process -FilePath $exe -WorkingDirectory $ExtractRoot -WindowStyle Hidden -PassThru
    Start-Sleep -Seconds $SmokeSeconds
    if ($process.HasExited) {
        throw "LetsMakeMoney.exe exited during v0.5 package smoke test with code $($process.ExitCode)"
    }

    $process.CloseMainWindow() | Out-Null
    Start-Sleep -Seconds 2
    if (-not $process.HasExited) {
        Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
        $process.WaitForExit(5000) | Out-Null
    }
} finally {
    $env:APPDATA = $originalAppData
}

Write-Host "v0.5 package smoke passed"
