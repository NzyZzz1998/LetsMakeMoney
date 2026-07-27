param(
    [switch]$SkipReleaseBuild
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "v10_tools.ps1")

Push-Location $root
try {
    foreach ($index in 0..6) {
        $script = Join-Path $root "scripts\verify_v10_m$index.ps1"
        if ($index -eq 5) {
            & $script -SkipBuild
        }
        else {
            & $script
        }
        if ($LASTEXITCODE -ne 0) {
            throw "V10 M$index verification failed."
        }
    }

    & (Join-Path $root "scripts\verify_v10_docs.ps1")
    if ($LASTEXITCODE -ne 0) {
        throw "V10 documentation verification failed."
    }

    if (-not $SkipReleaseBuild) {
        $cargo = Get-V10Cargo -RepoRoot $root
        & $cargo "+stable-x86_64-pc-windows-msvc" test `
            --manifest-path (Join-Path $root "apps\windows-v1\src-tauri\Cargo.toml") `
            --locked --offline --quiet
        if ($LASTEXITCODE -ne 0) {
            throw "V10 full Rust regression failed."
        }
    }

    git diff --check
    if ($LASTEXITCODE -ne 0) {
        throw "git diff --check failed."
    }
    Write-Host "LetsMakeMoney v1.0 aggregate verification passed." -ForegroundColor Green
}
finally {
    Pop-Location
}
