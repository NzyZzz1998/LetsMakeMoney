param(
    [string]$PythonExe = ""
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$AppRoot = Join-Path $RepoRoot "apps\windows-v1"
. (Join-Path $PSScriptRoot "v10_tools.ps1")

if ([string]::IsNullOrWhiteSpace($PythonExe)) {
    $PythonExe = Get-V10Python -RepoRoot $RepoRoot
}

& $PythonExe (Join-Path $AppRoot "tests\verify_v110.py")
if ($LASTEXITCODE -ne 0) {
    throw "v1.1.0 verification failed with exit code $LASTEXITCODE"
}

Push-Location $RepoRoot
try {
    git diff --check
    if ($LASTEXITCODE -ne 0) {
        throw "git diff --check failed during v1.1.0 verification."
    }
}
finally {
    Pop-Location
}

Write-Host "PASS LetsMakeMoney v1.1.0 release contract verification" -ForegroundColor Green
