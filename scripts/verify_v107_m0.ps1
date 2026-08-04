$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$app = Join-Path $root "apps\windows-v1"
$nodeModules = Join-Path $app "node_modules"
. (Join-Path $PSScriptRoot "v10_tools.ps1")

$node = Get-V10Node
$python = Get-V10Python
$esbuild = Get-ChildItem -LiteralPath $nodeModules -Filter "esbuild.exe" -File -Recurse |
    Select-Object -First 1 -ExpandProperty FullName

if (-not $esbuild) {
    throw "esbuild.exe was not found under apps\windows-v1\node_modules."
}

$behaviorTests = @(
    "mini-edge-auto-hide.behavior.ts",
    "v107-m0-window-characterization.behavior.ts"
)

foreach ($test in $behaviorTests) {
    $source = Join-Path $app "tests\$test"
    $bundle = Join-Path $env:TEMP ("lmm-v107-m0-" + [IO.Path]::GetFileNameWithoutExtension($test) + "-$PID.mjs")
    try {
        & $esbuild $source --bundle --platform=node --format=esm --outfile=$bundle
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to bundle v1.0.7 M0 behavior test: $test"
        }
        & $node $bundle
        if ($LASTEXITCODE -ne 0) {
            throw "v1.0.7 M0 behavior test failed: $test"
        }
    }
    finally {
        Remove-Item -LiteralPath $bundle -Force -ErrorAction SilentlyContinue
    }
}

& $python (Join-Path $app "tests\verify_v107_m0.py")
if ($LASTEXITCODE -ne 0) {
    throw "v1.0.7 M0 baseline verification failed."
}

git -C $root diff --check
if ($LASTEXITCODE -ne 0) {
    throw "git diff --check failed."
}

Write-Host "v1.0.7 M0 verification passed." -ForegroundColor Green
