$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$preset = Get-Content -LiteralPath (Join-Path $root "export_presets.cfg") -Raw

foreach ($pattern in @("doc/**", "scripts/**", "releases/**", "deliverables/**")) {
    if (-not $preset.Contains($pattern)) {
        throw "Export preset must exclude repository-only path: $pattern"
    }
}

foreach ($version in @("04", "05", "06", "07")) {
    $verifier = Get-Content -LiteralPath (Join-Path $root "scripts\verify_v${version}_package.ps1") -Raw
    if (-not $verifier.Contains(".tmp_release")) {
        throw "Package verifier v$version must extract under .tmp_release"
    }
}

Write-Host "v0.8 release boundary contract passed"
