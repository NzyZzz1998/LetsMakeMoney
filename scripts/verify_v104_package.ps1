param(
    [string]$PackagePath = ""
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$app = Join-Path $root "apps\windows-v1"
$releaseRoot = Join-Path $root "releases\v1.0.4"
$expectedVersion = "1.0.4"
$expectedPlatform = "windows-x86_64"
$expectedPlatformLabel = "Windows x86_64"
$expectedChannel = "Stable"
$expectedRoot = "LetsMakeMoney-v$expectedVersion-$expectedPlatform"
$expectedFile = "$expectedRoot.zip"

. (Join-Path $PSScriptRoot "v10_tools.ps1")
$python = Get-V10Python

if (-not $PackagePath) {
    $PackagePath = Join-Path $releaseRoot $expectedFile
}
$PackagePath = [IO.Path]::GetFullPath($PackagePath)
if (-not (Test-Path -LiteralPath $PackagePath -PathType Leaf)) {
    throw "Package does not exist: $PackagePath"
}
if ([IO.Path]::GetFileName($PackagePath) -ne $expectedFile) {
    throw "Package filename must be $expectedFile."
}

$extractRoot = Join-Path $root (".tmp_package_v104_" + [Guid]::NewGuid().ToString("N"))
$resolvedRoot = [IO.Path]::GetFullPath($root).TrimEnd('\') + '\'
$resolvedExtract = [IO.Path]::GetFullPath($extractRoot)
if (-not $resolvedExtract.StartsWith($resolvedRoot, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Unsafe extraction path."
}
New-Item -ItemType Directory -Path $extractRoot | Out-Null

try {
    Expand-Archive -LiteralPath $PackagePath -DestinationPath $extractRoot
    $payloads = @(Get-ChildItem -LiteralPath $extractRoot -Directory)
    if ($payloads.Count -ne 1 -or $payloads[0].Name -ne $expectedRoot) {
        throw "Package must contain exactly one root directory named $expectedRoot."
    }
    $payload = $payloads[0]

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

    & $python (Join-Path $app "release-docs\portable_readme.py") `
        --mode verify `
        --package-root $payload.FullName `
        --version $expectedVersion `
        --platform $expectedPlatformLabel `
        --channel $expectedChannel
    if ($LASTEXITCODE -ne 0) {
        throw "Portable README semantic verification failed."
    }

    $calendarRoot = Join-Path $payload.FullName "calendar-data"
    & (Join-Path $PSScriptRoot "verify_calendar_data_v103.ps1") -CalendarRoot $calendarRoot
    if ($LASTEXITCODE -ne 0) {
        throw "Package calendar data verification failed."
    }

    $buildInfo = Get-Content -LiteralPath (Join-Path $payload.FullName "BUILD-INFO.json") `
        -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($buildInfo.product -ne "LetsMakeMoney") { throw "Unexpected product identity." }
    if ($buildInfo.version -ne $expectedVersion) { throw "BUILD-INFO version mismatch." }
    if ($buildInfo.channel -ne "stable-candidate") { throw "Unexpected release channel." }
    if ($buildInfo.platform -ne $expectedPlatform) { throw "Unexpected release platform." }

    $exePath = Join-Path $payload.FullName "LetsMakeMoney.exe"
    $dllPath = Join-Path $payload.FullName "WebView2Loader.dll"
    $exeHash = (Get-FileHash -LiteralPath $exePath -Algorithm SHA256).Hash
    $dllHash = (Get-FileHash -LiteralPath $dllPath -Algorithm SHA256).Hash
    if ($buildInfo.executable_sha256 -ne $exeHash) { throw "EXE hash differs from BUILD-INFO." }
    if ($buildInfo.webview2_loader_sha256 -ne $dllHash) { throw "DLL hash differs from BUILD-INFO." }

    $productVersion = (Get-Item -LiteralPath $exePath).VersionInfo.ProductVersion
    if (-not $productVersion -or -not $productVersion.StartsWith($expectedVersion)) {
        throw "EXE ProductVersion '$productVersion' does not match $expectedVersion."
    }

    $readmeHash = (Get-FileHash -LiteralPath (Join-Path $payload.FullName "README.md") -Algorithm SHA256).Hash
    $readmeEnHash = (Get-FileHash -LiteralPath (Join-Path $payload.FullName "README.en.md") -Algorithm SHA256).Hash
    if ($buildInfo.documentation.readme_sha256 -ne $readmeHash) {
        throw "README.md hash differs from BUILD-INFO."
    }
    if ($buildInfo.documentation.readme_en_sha256 -ne $readmeEnHash) {
        throw "README.en.md hash differs from BUILD-INFO."
    }
    if ($buildInfo.documentation.source -ne "apps/windows-v1/release-docs") {
        throw "Unexpected package README source."
    }

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
        $datasetPath = Join-Path $calendarRoot $entry.file
        $actualHash = (Get-FileHash -LiteralPath $datasetPath -Algorithm SHA256).Hash
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

    $binaries = @(Get-ChildItem -LiteralPath $payload.FullName -Recurse -File |
        Where-Object { $_.Extension -in @(".exe", ".dll") })
    $allowedBinaries = @("LetsMakeMoney.exe", "WebView2Loader.dll")
    $unknownBinaries = @($binaries | Where-Object { $_.Name -notin $allowedBinaries })
    if ($unknownBinaries.Count -gt 0) {
        throw "Package contains an unregistered executable or DLL."
    }

    $forbidden = @(Get-ChildItem -LiteralPath $payload.FullName -Recurse -Force | Where-Object {
        $_.Name -match '(?i)(debug\.log|config\.json|\.env|\.tmp|acceptance|private|secret|token)' -or
        $_.Extension -match '(?i)^\.(png|jpg|jpeg|gif|webp|mp4|mov|zip|pfx|p12|key)$'
    })
    if ($forbidden.Count -gt 0) {
        throw "Package contains forbidden private, temporary, screenshot, archive, or signing files."
    }

    & (Join-Path $PSScriptRoot "verify_v10_m6.ps1") -PackagePath $PackagePath
    if ($LASTEXITCODE -ne 0) { throw "M6 package boundary verification failed." }

    Write-Host "V1.0.4 package verification passed." -ForegroundColor Green
    Write-Host "Zip SHA256: $((Get-FileHash -LiteralPath $PackagePath -Algorithm SHA256).Hash)"
    Write-Host "README.md SHA256: $readmeHash"
    Write-Host "README.en.md SHA256: $readmeEnHash"
    Write-Host "EXE SHA256: $exeHash"
    Write-Host "DLL SHA256: $dllHash"
}
finally {
    if (Test-Path -LiteralPath $extractRoot) {
        $resolvedCleanup = [IO.Path]::GetFullPath($extractRoot)
        if (-not $resolvedCleanup.StartsWith($resolvedRoot, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to clean an extraction path outside the workspace."
        }
        Remove-Item -LiteralPath $resolvedCleanup -Recurse -Force
    }
}
