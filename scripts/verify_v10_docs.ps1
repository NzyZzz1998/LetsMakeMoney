$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "v10_tools.ps1")
$python = Get-V10Python

Push-Location $root
try {
    & $python "apps/windows-v1/tests/verify_docs.py"
    if ($LASTEXITCODE -ne 0) {
        throw "v1.0 documentation verification failed."
    }

    Write-Host "V10 documentation verification passed." -ForegroundColor Green
}
finally {
    Pop-Location
}
