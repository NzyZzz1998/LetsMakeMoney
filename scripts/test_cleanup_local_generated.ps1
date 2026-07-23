param([string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot))

$ErrorActionPreference = "Stop"
$sandbox = Join-Path ([IO.Path]::GetTempPath()) ("lmm-cleanup-contract-" + [Guid]::NewGuid().ToString("N"))
try {
    New-Item -ItemType Directory -Force -Path $sandbox | Out-Null
    foreach ($relativePath in @(
        ".tmp_appdata\case",
        ".tmp_ci",
        ".tmp_release\case",
        ".tmp_ui_review",
        ".tmp_ui_review_appdata",
        ".tmp_acceptance\evidence",
        ".cache",
        ".godot",
        "build",
        "deliverables",
        "releases",
        "native"
    )) {
        New-Item -ItemType Directory -Force -Path (Join-Path $sandbox $relativePath) | Out-Null
    }
    Set-Content -LiteralPath (Join-Path $sandbox ".tmp_appdata\case\data.txt") -Value "generated"
    Set-Content -LiteralPath (Join-Path $sandbox ".tmp_release\case\payload.txt") -Value "generated"
    Set-Content -LiteralPath (Join-Path $sandbox ".tmp_acceptance\evidence\keep.txt") -Value "evidence"
    Set-Content -LiteralPath (Join-Path $sandbox ".tmp_parse.log") -Value "generated"
    Set-Content -LiteralPath (Join-Path $sandbox "build\keep.txt") -Value "launch"

    & (Join-Path $ProjectRoot "scripts\cleanup_local_generated.ps1") -ProjectRoot $sandbox | Out-Null
    if (-not (Test-Path -LiteralPath (Join-Path $sandbox ".tmp_appdata"))) {
        throw "Preview mode must not remove generated directories."
    }

    & (Join-Path $ProjectRoot "scripts\cleanup_local_generated.ps1") -ProjectRoot $sandbox -Apply | Out-Null
    foreach ($relativePath in @(".tmp_appdata", ".tmp_ci", ".tmp_release", ".tmp_ui_review", ".tmp_ui_review_appdata", ".tmp_parse.log")) {
        if (Test-Path -LiteralPath (Join-Path $sandbox $relativePath)) {
            throw "Apply mode did not remove generated path: $relativePath"
        }
    }
    foreach ($relativePath in @(".tmp_acceptance", ".cache", ".godot", "build", "deliverables", "releases", "native")) {
        if (-not (Test-Path -LiteralPath (Join-Path $sandbox $relativePath))) {
            throw "Apply mode removed protected path: $relativePath"
        }
    }
    Write-Host "Local generated cleanup contract passed" -ForegroundColor Green
} finally {
    if (Test-Path -LiteralPath $sandbox) {
        Remove-Item -LiteralPath $sandbox -Recurse -Force
    }
}
