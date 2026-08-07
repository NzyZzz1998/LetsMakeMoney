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
    "architecture-runtime.behavior.ts",
    "authoritative-sync.behavior.ts",
    "browser-preview-boundary.behavior.ts",
    "calendar-layout.behavior.ts",
    "calendar-v105-presentation.behavior.ts",
    "calendar-state.behavior.ts",
    "combobox.behavior.ts",
    "configuration-domain.behavior.ts",
    "dashboard-lifecycle.behavior.ts",
    "date-overtime-decision.behavior.ts",
    "date-override-state.behavior.ts",
    "desktop-services.behavior.ts",
    "high-risk-combinations.behavior.ts",
    "mini-edge-auto-hide.behavior.ts",
    "monthly-summary.behavior.ts",
    "overtime-month-state.behavior.ts",
    "overtime-service.behavior.ts",
    "overtime-state.behavior.ts",
    "privacy-tab-presentation.behavior.ts",
    "presentation.behavior.ts",
    "presentation-utils.behavior.ts",
    "theme.behavior.ts",
    "time-field.behavior.ts",
    "window-surface-v105.behavior.ts"
)

foreach ($test in $behaviorTests) {
    $source = Join-Path $app "tests\$test"
    $bundle = Join-Path $env:TEMP ("lmm-architecture-" + [IO.Path]::GetFileNameWithoutExtension($test) + "-$PID.mjs")
    try {
        & $esbuild $source --bundle --platform=node --format=esm --outfile=$bundle
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to bundle architecture behavior test: $test"
        }
        & $node $bundle
        if ($LASTEXITCODE -ne 0) {
            throw "Architecture behavior test failed: $test"
        }
    }
    finally {
        Remove-Item -LiteralPath $bundle -Force -ErrorAction SilentlyContinue
    }
}

& $python (Join-Path $app "tests\verify_architecture_structure.py")
if ($LASTEXITCODE -ne 0) {
    throw "Architecture structure verification failed."
}

& $python (Join-Path $app "tests\verify_v104_m6.py")
if ($LASTEXITCODE -ne 0) {
    throw "v1.0.4 Mini edge auto-hide contract verification failed."
}

& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $app "tests\verify_tool_resolution.ps1")
if ($LASTEXITCODE -ne 0) {
    throw "Tool resolution verification failed."
}

Write-Host "Architecture verification passed."
