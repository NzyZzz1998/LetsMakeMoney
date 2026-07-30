param(
    [switch]$SkipRust
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$app = Join-Path $root "apps\windows-v1"
$nodeModules = Join-Path $app "node_modules"
. (Join-Path $PSScriptRoot "v10_tools.ps1")
$node = Get-V10Node
$esbuild = Get-ChildItem -LiteralPath $nodeModules -Filter "esbuild.exe" -File -Recurse |
    Select-Object -First 1 -ExpandProperty FullName

if (-not $esbuild) {
    throw "esbuild.exe was not found under apps\windows-v1\node_modules."
}

$behaviorTests = @(
    "calendar-state.behavior.ts",
    "authoritative-sync.behavior.ts",
    "dashboard-lifecycle.behavior.ts"
)

& (Join-Path $PSScriptRoot "verify_calendar_data_v103.ps1")
if ($LASTEXITCODE -ne 0) {
    throw "v1.0.3 calendar data verification failed."
}

& python (Join-Path $app "tests\verify_webview_suspend_v103.py")
if ($LASTEXITCODE -ne 0) {
    throw "v1.0.3 native WebView2 suspend contract failed."
}

foreach ($test in $behaviorTests) {
    $source = Join-Path $app "tests\$test"
    $bundle = Join-Path $env:TEMP ("lmm-v103-" + [IO.Path]::GetFileNameWithoutExtension($test) + ".cjs")
    & $esbuild $source --bundle --platform=node --format=cjs --outfile=$bundle
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to bundle $test."
    }
    & $node $bundle
    if ($LASTEXITCODE -ne 0) {
        throw "Behavior test failed: $test"
    }
}

if (-not $SkipRust) {
    $cargo = Get-V10Cargo -RepoRoot $root
    & $cargo "+stable-x86_64-pc-windows-msvc" test --manifest-path (Join-Path $app "src-tauri\Cargo.toml")
    if ($LASTEXITCODE -ne 0) {
        throw "Rust tests failed."
    }
}

& (Join-Path $PSScriptRoot "verify_v102.ps1") -SkipReleaseBuild
if ($LASTEXITCODE -ne 0) {
    throw "v1.0.2 regression verification failed."
}

Write-Host "v1.0.3 verification passed."
