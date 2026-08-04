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
$Node = Get-V10Node -RepoRoot $RepoRoot
$Esbuild = Get-ChildItem -LiteralPath (Join-Path $AppRoot "node_modules") -Filter "esbuild.exe" -File -Recurse |
    Select-Object -First 1 -ExpandProperty FullName
if (-not $Esbuild) {
    throw "esbuild.exe was not found under apps\windows-v1\node_modules."
}

& $PythonExe (Join-Path $AppRoot "tests\verify_v107_m1.py")
if ($LASTEXITCODE -ne 0) {
    throw "v1.0.7 M1 contract verification failed with exit code $LASTEXITCODE"
}

& $PythonExe (Join-Path $AppRoot "tests\verify_contracts.py")
if ($LASTEXITCODE -ne 0) {
    throw "Canonical config contract verification failed with exit code $LASTEXITCODE"
}

foreach ($Test in @("version-metadata.behavior.ts", "v107-ipc-fixtures.behavior.ts")) {
    $Source = Join-Path $AppRoot "tests\$Test"
    $Bundle = Join-Path $env:TEMP ("lmm-v107-m1-" + [IO.Path]::GetFileNameWithoutExtension($Test) + "-$PID.mjs")
    try {
        & $Esbuild $Source --bundle --platform=node --format=esm --outfile=$Bundle
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to bundle M1 behavior test: $Test"
        }
        & $Node $Bundle
        if ($LASTEXITCODE -ne 0) {
            throw "M1 behavior test failed: $Test"
        }
    }
    finally {
        Remove-Item -LiteralPath $Bundle -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "PASS LetsMakeMoney v1.0.7 M1 verification" -ForegroundColor Green
