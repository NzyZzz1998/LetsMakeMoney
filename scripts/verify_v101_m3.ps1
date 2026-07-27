param(
    [switch]$SkipFrontendBuild
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$AppRoot = Join-Path $RepoRoot "apps\windows-v1"
. (Join-Path $PSScriptRoot "v10_tools.ps1")

$Python = Get-V10Python
$Node = Get-V10Node
$Cargo = Get-V10Cargo -RepoRoot $RepoRoot
$NodeModules = Join-Path $AppRoot "node_modules"

& $Python (Join-Path $AppRoot "tests\verify_v101_m3.py")
if ($LASTEXITCODE -ne 0) {
    throw "v1.0.1 M3 static verification failed."
}

Push-Location (Join-Path $AppRoot "src-tauri")
try {
    & $Cargo +stable-x86_64-pc-windows-msvc test --locked --offline --lib --quiet
    if ($LASTEXITCODE -ne 0) {
        throw "Native owner-date and salary tests failed."
    }
}
finally {
    Pop-Location
}

if (-not $SkipFrontendBuild) {
    Push-Location $AppRoot
    try {
        & $Node (Join-Path $NodeModules "typescript\bin\tsc")
        if ($LASTEXITCODE -ne 0) {
            throw "TypeScript verification failed."
        }
        & $Node (Join-Path $NodeModules "vite\bin\vite.js") build
        if ($LASTEXITCODE -ne 0) {
            throw "Frontend build failed."
        }
    }
    finally {
        Pop-Location
    }
}

Write-Host "PASS LetsMakeMoney v1.0.1 M3 verification" -ForegroundColor Green
