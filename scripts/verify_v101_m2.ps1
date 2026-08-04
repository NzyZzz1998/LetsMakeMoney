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
$BehaviorBundle = Join-Path $env:TEMP "lmm-v101-date-override-state-$PID.mjs"

try {
    & $Python (Join-Path $AppRoot "tests\verify_v101_m2.py")
    if ($LASTEXITCODE -ne 0) {
        throw "v1.0.1 M2 static verification failed."
    }

    $Esbuild = Get-ChildItem `
        -LiteralPath $NodeModules `
        -Recurse `
        -Filter "esbuild.exe" `
        -File |
        Select-Object -First 1 -ExpandProperty FullName
    if (-not $Esbuild) {
        throw "esbuild.exe was not found under apps\windows-v1\node_modules."
    }

    & $Esbuild `
        (Join-Path $AppRoot "tests\date-override-state.behavior.ts") `
        --bundle `
        --platform=node `
        --format=esm `
        "--outfile=$BehaviorBundle"
    if ($LASTEXITCODE -ne 0) {
        throw "Date override behavior bundle failed."
    }
    & $Node $BehaviorBundle
    if ($LASTEXITCODE -ne 0) {
        throw "Date override behavior verification failed."
    }

    Push-Location (Join-Path $AppRoot "src-tauri")
    try {
        & $Cargo +stable-x86_64-pc-windows-msvc test `
            --locked `
            --offline `
            --lib `
            --quiet
        if ($LASTEXITCODE -ne 0) {
            throw "Native date override tests failed."
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

    Write-Host "PASS LetsMakeMoney v1.0.1 M2 verification" -ForegroundColor Green
}
finally {
    if (Test-Path -LiteralPath $BehaviorBundle -PathType Leaf) {
        Remove-Item -LiteralPath $BehaviorBundle -Force
    }
}
