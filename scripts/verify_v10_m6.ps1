param(
    [string]$PackagePath = ""
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$app = Join-Path $root "apps\windows-v1"
. (Join-Path $PSScriptRoot "v10_tools.ps1")
$Python = Get-V10Python
$Cargo = Get-V10Cargo -RepoRoot $root

Push-Location $root
try {
    $arguments = @("apps/windows-v1/tests/verify_m6.py")
    if ($PackagePath) {
        $arguments += @("--package", $PackagePath)
    }
    & $Python @arguments
    if ($LASTEXITCODE -ne 0) {
        throw "M6 static or package verification failed."
    }

    & $Cargo "+stable-x86_64-pc-windows-msvc" test `
        --manifest-path (Join-Path $app "src-tauri\Cargo.toml") `
        config::tests
    if ($LASTEXITCODE -ne 0) {
        throw "M6 config migration regression failed."
    }

    Write-Host "V10-M6 verification passed." -ForegroundColor Green
}
finally {
    Pop-Location
}
