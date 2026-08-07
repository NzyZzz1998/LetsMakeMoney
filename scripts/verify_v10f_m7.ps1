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

& $PythonExe (Join-Path $AppRoot "tests\verify_v10f_m7.py")
if ($LASTEXITCODE -ne 0) {
    throw "v1.0.8 M7 verification failed with exit code $LASTEXITCODE"
}

Push-Location $RepoRoot
try {
    git diff --check
    if ($LASTEXITCODE -ne 0) {
        throw "git diff --check failed during M7 verification."
    }
}
finally {
    Pop-Location
}

Write-Host "PASS LetsMakeMoney v1.0.8 M7 verification" -ForegroundColor Green
