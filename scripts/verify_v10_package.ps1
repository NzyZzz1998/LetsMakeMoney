param(
    [string]$PackagePath = ""
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$releaseRoot = Join-Path $root "releases\v1.0"
if (-not $PackagePath) {
    $PackagePath = Join-Path $releaseRoot "LetsMakeMoney-v1.0-windows-x86_64.zip"
}
$PackagePath = [IO.Path]::GetFullPath($PackagePath)
if (-not (Test-Path -LiteralPath $PackagePath -PathType Leaf)) {
    throw "Package does not exist: $PackagePath"
}

$extractRoot = Join-Path $root ".tmp_package_v10"
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

    $required = @(
        "LetsMakeMoney.exe",
        "WebView2Loader.dll",
        "README.md",
        "README.en.md",
        "LICENSE",
        "THIRD_PARTY_NOTICES.md",
        "ASSETS_LICENSE.md",
        "ASSETS_MANIFEST.md",
        "CHANGELOG.md",
        "BUILD-INFO.json"
    )
    foreach ($name in $required) {
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
    if ($buildInfo.executable_sha256 -ne $exeHash) { throw "EXE hash differs from BUILD-INFO." }
    if ($buildInfo.webview2_loader_sha256 -ne $dllHash) { throw "DLL hash differs from BUILD-INFO." }

    powershell -ExecutionPolicy Bypass -File (Join-Path $root "scripts\verify_v10_m6.ps1") `
        -PackagePath $PackagePath
    if ($LASTEXITCODE -ne 0) { throw "M6 package boundary verification failed." }

    Write-Host "V10 package verification passed." -ForegroundColor Green
    Write-Host "Zip SHA256: $((Get-FileHash -LiteralPath $PackagePath -Algorithm SHA256).Hash)"
    Write-Host "EXE SHA256: $exeHash"
    Write-Host "DLL SHA256: $dllHash"
}
finally {
    if (Test-Path -LiteralPath $extractRoot) {
        Remove-Item -LiteralPath $extractRoot -Recurse -Force
    }
}
