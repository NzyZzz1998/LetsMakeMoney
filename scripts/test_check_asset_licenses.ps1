param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path)

$ErrorActionPreference = "Stop"
$checker = Join-Path $Root 'scripts/check_asset_licenses.ps1'
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ("lmm-asset-license-" + [guid]::NewGuid().ToString('N'))
$utf8 = [Text.UTF8Encoding]::new($false)

function Write-Text([string]$Path, [string]$Content) {
    New-Item -ItemType Directory -Path (Split-Path $Path -Parent) -Force | Out-Null
    [IO.File]::WriteAllText($Path, $Content, $utf8)
}

try {
    $clean = Join-Path $tempRoot 'clean'
    Write-Text (Join-Path $clean 'LICENSE') "MIT License`nCopyright (c) 2026 NzyZzz1998`n"
    Write-Text (Join-Path $clean 'ASSETS_LICENSE.md') '# ASSETS'
    Write-Text (Join-Path $clean 'ASSETS_MANIFEST.md') '# MANIFEST'
    Write-Text (Join-Path $clean 'README.md') 'LICENSE ASSETS_LICENSE.md ASSETS_MANIFEST.md CONTRIBUTING.md'
    Write-Text (Join-Path $clean 'README.en.md') 'LICENSE ASSETS_LICENSE.md ASSETS_MANIFEST.md CONTRIBUTING.md'
    Write-Text (Join-Path $clean 'CONTRIBUTING.md') 'LICENSE ASSETS_LICENSE.md'
    Write-Text (Join-Path $clean 'assets/README.md') 'ASSETS_LICENSE'
    Write-Text (Join-Path $clean 'icons/README.md') 'ASSETS_LICENSE'
    Write-Text (Join-Path $clean 'doc/prototypes/README.md') 'ASSETS_LICENSE'
    Write-Text (Join-Path $clean 'assets/cat/cat.png') 'fixture'
    Write-Text (Join-Path $clean 'assets/asset-license-manifest.json') '{"entries":[{"id":"CAT","path":"assets/cat","source":"owner","status":"approved_restricted","license":"ASSETS_LICENSE.md"}]}'
    & $checker -Root $clean
    $cleanPassed = $?
    if (-not $cleanPassed) { throw 'Clean asset fixture must pass.' }

    Write-Text (Join-Path $clean 'assets/unknown/unknown.png') 'fixture'
    & $checker -Root $clean
    $riskPassed = $?
    if ($riskPassed) { throw 'Unregistered asset fixture must fail.' }

    Write-Host 'Asset license checker tests passed.' -ForegroundColor Green
} finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
