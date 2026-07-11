$ErrorActionPreference = "Stop"

function Get-LmmRelativePath([string]$BasePath, [string]$Path) {
    $base = (Resolve-Path -LiteralPath $BasePath).Path.TrimEnd('\') + '\'
    $full = (Resolve-Path -LiteralPath $Path).Path
    if (-not $full.StartsWith($base, [StringComparison]::OrdinalIgnoreCase)) { throw "Path is outside package root: $full" }
    return $full.Substring($base.Length).Replace('\','/')
}

function Stage-LmmReleaseLicenses {
    param([string]$ProjectRoot, [string]$StageDir)
    & (Join-Path $ProjectRoot "scripts/stage_release_licenses.ps1") -ProjectRoot $ProjectRoot -StageDir $StageDir
}

function New-LmmPackage {
    param(
        [Parameter(Mandatory=$true)][string]$ProjectRoot,
        [Parameter(Mandatory=$true)][string]$Version,
        [Parameter(Mandatory=$true)][string]$ReleaseDirectory,
        [Parameter(Mandatory=$true)][string]$ReleaseNotes,
        [switch]$IncludeLicenses
    )
    $packageName = "LetsMakeMoney-v$Version-windows-x86_64"
    $releaseDir = Join-Path $ProjectRoot $ReleaseDirectory
    $stageDir = Join-Path $releaseDir $packageName
    $zipPath = Join-Path $releaseDir "$packageName.zip"
    $packageFiles = @(
        @{ Source = "build/LetsMakeMoney.exe"; Target = "LetsMakeMoney.exe"; Role = "application" },
        @{ Source = "build/letsmakemoney_native.dll"; Target = "letsmakemoney_native.dll"; Role = "native_bridge" },
        @{ Source = "icons/app_icon.ico"; Target = "app_icon.ico"; Role = "tray_icon" },
        @{ Source = "README.md"; Target = "README.md"; Role = "quick_start" },
        @{ Source = $ReleaseNotes; Target = "release-notes.md"; Role = "release_notes" }
    )
    foreach ($file in $packageFiles) {
        $source = Join-Path $ProjectRoot $file.Source
        if (-not (Test-Path -LiteralPath $source)) { throw "Missing package input: $($file.Source)" }
    }
    New-Item -ItemType Directory -Force -Path $releaseDir | Out-Null
    if (Test-Path -LiteralPath $stageDir) { Remove-Item -LiteralPath $stageDir -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $stageDir | Out-Null
    foreach ($file in $packageFiles) {
        Copy-Item -LiteralPath (Join-Path $ProjectRoot $file.Source) -Destination (Join-Path $stageDir $file.Target) -Force
    }
    if ($IncludeLicenses) { Stage-LmmReleaseLicenses -ProjectRoot $ProjectRoot -StageDir $stageDir }
    $manifestFiles = foreach ($file in Get-ChildItem -LiteralPath $stageDir -Recurse -File | Sort-Object FullName) {
        $relative = Get-LmmRelativePath $stageDir $file.FullName
        [ordered]@{ path=$relative; role=if($relative.StartsWith('LICENSES/')){'license'}else{($packageFiles | Where-Object Target -eq $relative | Select-Object -First 1).Role}; size=$file.Length; sha256=(Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant() }
    }
    $manifest = [ordered]@{ package_name=$packageName; version=$Version; platform="windows-x86_64"; generated_at=(Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ"); config_path="%APPDATA%\LetsMakeMoney\config.json"; files=@($manifestFiles) }
    $manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $stageDir "manifest.json") -Encoding UTF8
    $checksumLines = foreach ($file in Get-ChildItem -LiteralPath $stageDir -Recurse -File | Where-Object Name -ne 'checksums.txt' | Sort-Object FullName) {
        $relative = Get-LmmRelativePath $stageDir $file.FullName
        "{0}  {1}" -f (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant(), $relative
    }
    $checksumLines | Set-Content -LiteralPath (Join-Path $stageDir "checksums.txt") -Encoding UTF8
    if (Test-Path -LiteralPath $zipPath) { Remove-Item -LiteralPath $zipPath -Force }
    Compress-Archive -Path (Join-Path $stageDir '*') -DestinationPath $zipPath -Force
    Write-Host "Package created: $zipPath"
    return $zipPath
}
