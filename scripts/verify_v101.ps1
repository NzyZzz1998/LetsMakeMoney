param(
    [switch]$SkipReleaseBuild
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot

Push-Location $RepoRoot
try {
    & (Join-Path $PSScriptRoot "verify_v101_m0.ps1")
    if ($LASTEXITCODE -ne 0) {
        throw "v1.0.1 M0 verification failed."
    }

    & (Join-Path $PSScriptRoot "verify_v101_m1.ps1")
    if ($LASTEXITCODE -ne 0) {
        throw "v1.0.1 M1 verification failed."
    }

    & (Join-Path $PSScriptRoot "verify_v101_m2.ps1")
    if ($LASTEXITCODE -ne 0) {
        throw "v1.0.1 M2 verification failed."
    }

    & (Join-Path $PSScriptRoot "verify_v101_m3.ps1") -SkipFrontendBuild
    if ($LASTEXITCODE -ne 0) {
        throw "v1.0.1 M3 verification failed."
    }

    & (Join-Path $PSScriptRoot "verify_v101_m4.ps1") -SkipFrontendBuild
    if ($LASTEXITCODE -ne 0) {
        throw "v1.0.1 M4 verification failed."
    }

    & (Join-Path $PSScriptRoot "verify_v10.ps1") -SkipReleaseBuild:$SkipReleaseBuild
    if ($LASTEXITCODE -ne 0) {
        throw "v1.0 regression failed."
    }

    git diff --check
    if ($LASTEXITCODE -ne 0) {
        throw "git diff --check failed."
    }

    Write-Host "LetsMakeMoney v1.0.1 aggregate verification passed." -ForegroundColor Green
}
finally {
    Pop-Location
}
