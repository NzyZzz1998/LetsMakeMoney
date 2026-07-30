param(
    [string]$PackagePath = ""
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$releaseRoot = Join-Path $root "releases\v1.0.3"
if (-not $PackagePath) {
    $PackagePath = Join-Path $releaseRoot "LetsMakeMoney-v1.0.3-windows-x86_64.zip"
}
$PackagePath = [IO.Path]::GetFullPath($PackagePath)
if (-not (Test-Path -LiteralPath $PackagePath -PathType Leaf)) {
    throw "Package does not exist: $PackagePath"
}

$extractRoot = Join-Path $root ".tmp_package_v103"
$resolvedRoot = [IO.Path]::GetFullPath($root).TrimEnd('\') + '\'
$resolvedExtract = [IO.Path]::GetFullPath($extractRoot)
if (-not $resolvedExtract.StartsWith($resolvedRoot, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Unsafe extraction path."
}
if (Test-Path -LiteralPath $extractRoot) {
    Remove-Item -LiteralPath $extractRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $extractRoot | Out-Null

try {
    Expand-Archive -LiteralPath $PackagePath -DestinationPath $extractRoot
    $payload = Get-ChildItem -LiteralPath $extractRoot -Directory | Select-Object -First 1
    if (-not $payload) { throw "Package root directory is missing." }

    $requiredFiles = @(
        "LetsMakeMoney.exe",
        "WebView2Loader.dll",
        "README.md",
        "README.en.md",
        "LICENSE",
        "THIRD_PARTY_NOTICES.md",
        "ASSETS_LICENSE.md",
        "ASSETS_MANIFEST.md",
        "CHANGELOG.md",
        "BUILD-INFO.json",
        "calendar-data\manifest.json"
    )
    foreach ($name in $requiredFiles) {
        $path = Join-Path $payload.FullName $name
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw "Required package file is missing: $name"
        }
        if ((Get-Item -LiteralPath $path).Length -eq 0) {
            throw "Package file is empty: $name"
        }
    }

    $calendarRoot = Join-Path $payload.FullName "calendar-data"
    & (Join-Path $PSScriptRoot "verify_calendar_data_v103.ps1") -CalendarRoot $calendarRoot
    if ($LASTEXITCODE -ne 0) {
        throw "Package calendar data verification failed."
    }

    $buildInfo = Get-Content -LiteralPath (Join-Path $payload.FullName "BUILD-INFO.json") `
        -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($buildInfo.version -ne "1.0.3") { throw "BUILD-INFO version is not 1.0.3." }
    if ($buildInfo.channel -ne "stable-candidate") { throw "Unexpected release channel." }

    $exeHash = (Get-FileHash -LiteralPath (Join-Path $payload.FullName "LetsMakeMoney.exe") -Algorithm SHA256).Hash
    $dllHash = (Get-FileHash -LiteralPath (Join-Path $payload.FullName "WebView2Loader.dll") -Algorithm SHA256).Hash
    if ($buildInfo.executable_sha256 -ne $exeHash) { throw "EXE hash differs from BUILD-INFO." }
    if ($buildInfo.webview2_loader_sha256 -ne $dllHash) { throw "DLL hash differs from BUILD-INFO." }

    $manifestPath = Join-Path $calendarRoot "manifest.json"
    $manifestHash = (Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash
    $manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($buildInfo.calendar.manifest_sha256 -ne $manifestHash) {
        throw "Calendar manifest hash differs from BUILD-INFO."
    }
    if ($buildInfo.calendar.dataset_version -ne $manifest.dataset_version) {
        throw "Calendar dataset version differs from BUILD-INFO."
    }
    $buildDatasets = @($buildInfo.calendar.datasets)
    if ($buildDatasets.Count -ne @($manifest.datasets).Count) {
        throw "Calendar dataset count differs from BUILD-INFO."
    }
    foreach ($entry in $manifest.datasets) {
        $path = Join-Path $calendarRoot $entry.file
        $actualHash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
        $buildEntry = @($buildDatasets | Where-Object {
            [int]$_.year -eq [int]$entry.year -and [string]$_.file -eq [string]$entry.file
        })
        if ($buildEntry.Count -ne 1) {
            throw "BUILD-INFO calendar identity is missing or duplicated for year $($entry.year)."
        }
        if ($entry.sha256 -ne $actualHash -or $buildEntry[0].sha256 -ne $actualHash) {
            throw "Calendar hash mismatch for year $($entry.year)."
        }
    }

    $forbidden = Get-ChildItem -LiteralPath $payload.FullName -Recurse -Force | Where-Object {
        $_.Name -match '(?i)(debug\.log|config\.json|\.env|\.tmp|acceptance|private|secret|token)'
    }
    if ($forbidden) {
        throw "Package contains forbidden private or temporary files."
    }

    powershell.exe -NoProfile -ExecutionPolicy Bypass `
        -File (Join-Path $root "scripts\verify_v10_m6.ps1") -PackagePath $PackagePath
    if ($LASTEXITCODE -ne 0) { throw "M6 package boundary verification failed." }

    Write-Host "V1.0.3 package verification passed." -ForegroundColor Green
    Write-Host "Zip SHA256: $((Get-FileHash -LiteralPath $PackagePath -Algorithm SHA256).Hash)"
    Write-Host "EXE SHA256: $exeHash"
    Write-Host "DLL SHA256: $dllHash"
}
finally {
    if (Test-Path -LiteralPath $extractRoot) {
        Remove-Item -LiteralPath $extractRoot -Recurse -Force
    }
}
