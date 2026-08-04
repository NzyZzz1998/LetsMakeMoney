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

& $PythonExe (Join-Path $AppRoot "tests\verify_v107_m5.py")
if ($LASTEXITCODE -ne 0) {
    throw "v1.0.7 M5 static verification failed with exit code $LASTEXITCODE"
}

$Tests = @(
    "combobox.behavior.ts",
    "window-surface.behavior.ts"
)
foreach ($Test in $Tests) {
    $Source = Join-Path $AppRoot "tests\$Test"
    $Bundle = Join-Path $env:TEMP ("lmm-v107-m5-" + [IO.Path]::GetFileNameWithoutExtension($Test) + "-$PID.mjs")
    try {
        & $Esbuild $Source --bundle --platform=node --format=esm --outfile=$Bundle
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to bundle M5 behavior test: $Test"
        }
        & $Node $Bundle
        if ($LASTEXITCODE -ne 0) {
            throw "M5 behavior test failed: $Test"
        }
    }
    finally {
        Remove-Item -LiteralPath $Bundle -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "PASS LetsMakeMoney v1.0.7 M5 verification" -ForegroundColor Green
