param(
    [string]$PackagePath = ""
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$releaseRoot = Join-Path $root "releases\v1.0.1"
if (-not $PackagePath) {
    $PackagePath = Join-Path $releaseRoot "LetsMakeMoney-v1.0.1-windows-x86_64.zip"
}
$PackagePath = [IO.Path]::GetFullPath($PackagePath)
if (-not (Test-Path -LiteralPath $PackagePath -PathType Leaf)) {
    throw "Package does not exist: $PackagePath"
}

$extractRoot = Join-Path $root ".tmp_package_v101"
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
        "calendar-data\manifest.json",
        "calendar-data\cn-2025.json",
        "calendar-data\cn-2026.json"
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

    $buildInfo = Get-Content -LiteralPath (Join-Path $payload.FullName "BUILD-INFO.json") `
        -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($buildInfo.version -ne "1.0.1") { throw "BUILD-INFO version is not 1.0.1." }
    if ($buildInfo.channel -ne "stable-candidate") { throw "Unexpected release channel." }

    $thirdPartyNotices = Get-Content -LiteralPath `
        (Join-Path $payload.FullName "THIRD_PARTY_NOTICES.md") -Raw -Encoding UTF8
    foreach ($noticeToken in @(
        "webview2-com-sys",
        "0.38.2",
        "WebView2Loader.dll",
        "WebView2 Runtime is not bundled"
    )) {
        if (-not $thirdPartyNotices.Contains($noticeToken)) {
            throw "THIRD_PARTY_NOTICES is missing the WebView2 distribution boundary: $noticeToken"
        }
    }

    $exeHash = (Get-FileHash -LiteralPath (Join-Path $payload.FullName "LetsMakeMoney.exe") -Algorithm SHA256).Hash
    $dllHash = (Get-FileHash -LiteralPath (Join-Path $payload.FullName "WebView2Loader.dll") -Algorithm SHA256).Hash
    $manifestPath = Join-Path $payload.FullName "calendar-data\manifest.json"
    $calendar2025Path = Join-Path $payload.FullName "calendar-data\cn-2025.json"
    $calendar2026Path = Join-Path $payload.FullName "calendar-data\cn-2026.json"
    $manifestHash = (Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash
    $calendar2025Hash = (Get-FileHash -LiteralPath $calendar2025Path -Algorithm SHA256).Hash
    $calendar2026Hash = (Get-FileHash -LiteralPath $calendar2026Path -Algorithm SHA256).Hash

    if ($buildInfo.executable_sha256 -ne $exeHash) { throw "EXE hash differs from BUILD-INFO." }
    if ($buildInfo.webview2_loader_sha256 -ne $dllHash) { throw "DLL hash differs from BUILD-INFO." }
    if ($buildInfo.calendar_manifest_sha256 -ne $manifestHash) { throw "Calendar manifest hash differs from BUILD-INFO." }
    if ($buildInfo.calendar_2025_sha256 -ne $calendar2025Hash) { throw "2025 calendar hash differs from BUILD-INFO." }
    if ($buildInfo.calendar_2026_sha256 -ne $calendar2026Hash) { throw "2026 calendar hash differs from BUILD-INFO." }

    $manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if (($manifest.supported_years -join ",") -ne "2025,2026") {
        throw "Calendar manifest supported years are incorrect."
    }
    foreach ($entry in $manifest.datasets) {
        $actual = if ($entry.year -eq 2025) { $calendar2025Hash } elseif ($entry.year -eq 2026) { $calendar2026Hash } else { "" }
        if (-not $actual -or $entry.sha256 -ne $actual) {
            throw "Calendar manifest dataset hash mismatch for year $($entry.year)."
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

    Write-Host "V1.0.1 package verification passed." -ForegroundColor Green
    Write-Host "Zip SHA256: $((Get-FileHash -LiteralPath $PackagePath -Algorithm SHA256).Hash)"
    Write-Host "EXE SHA256: $exeHash"
    Write-Host "DLL SHA256: $dllHash"
}
finally {
    if (Test-Path -LiteralPath $extractRoot) {
        Remove-Item -LiteralPath $extractRoot -Recurse -Force
    }
}
