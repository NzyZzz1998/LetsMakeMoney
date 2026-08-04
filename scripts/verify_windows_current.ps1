param(
    [string]$ManifestPath = ""
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$AppRoot = Join-Path $RepoRoot "apps\windows-v1"
. (Join-Path $PSScriptRoot "v10_tools.ps1")

if ([string]::IsNullOrWhiteSpace($ManifestPath)) {
    $ManifestPath = Join-Path $PSScriptRoot "current-manifest.json"
}
if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
    throw "Current manifest is missing: $ManifestPath"
}

$Python = Get-V10Python -RepoRoot $RepoRoot
$Node = Get-V10Node -RepoRoot $RepoRoot
$Cargo = Get-V10Cargo -RepoRoot $RepoRoot
$RustToolchain = Get-V10RustToolchain
$CargoManifest = Join-Path $AppRoot "src-tauri\Cargo.toml"

& $Python (Join-Path $PSScriptRoot "verify_current_manifest.py") --repo-root $RepoRoot --manifest $ManifestPath
if ($LASTEXITCODE -ne 0) {
    throw "Current manifest validation failed with exit code $LASTEXITCODE"
}

$Manifest = Get-Content -LiteralPath $ManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
foreach ($Gate in $Manifest.gates) {
    $GatePath = Join-Path $RepoRoot ([string]$Gate.path).Replace("/", "\")
    Write-Host "RUN current gate $($Gate.id): $($Gate.path)" -ForegroundColor Cyan
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $GatePath
    $ExitCode = $LASTEXITCODE
    if ($ExitCode -ne 0) {
        if ($ExitCode -in @(130, -1073741510, 3221225786)) {
            throw "Current gate was cancelled: $($Gate.id)"
        }
        throw "Current gate failed: $($Gate.id), exit code $ExitCode"
    }
}

Push-Location $AppRoot
try {
    & $Node (Join-Path $AppRoot "node_modules\typescript\bin\tsc")
    if ($LASTEXITCODE -ne 0) {
        throw "Current TypeScript strict verification failed with exit code $LASTEXITCODE"
    }
    & $Node (Join-Path $AppRoot "node_modules\vite\bin\vite.js") build
    if ($LASTEXITCODE -ne 0) {
        throw "Current Vite production build failed with exit code $LASTEXITCODE"
    }
}
finally {
    Pop-Location
}

& $Cargo "+$RustToolchain" test --manifest-path $CargoManifest --locked --no-fail-fast
if ($LASTEXITCODE -ne 0) {
    throw "Current cargo test failed with exit code $LASTEXITCODE"
}
& $Cargo "+$RustToolchain" fmt --manifest-path $CargoManifest -- --check
if ($LASTEXITCODE -ne 0) {
    throw "Current cargo fmt failed with exit code $LASTEXITCODE"
}
& $Cargo "+$RustToolchain" clippy --manifest-path $CargoManifest --locked --all-targets -- -D warnings
if ($LASTEXITCODE -ne 0) {
    throw "Current cargo clippy failed with exit code $LASTEXITCODE"
}

Push-Location $RepoRoot
try {
    git diff --check
    if ($LASTEXITCODE -ne 0) {
        throw "git diff --check failed."
    }
}
finally {
    Pop-Location
}

Write-Host "PASS LetsMakeMoney Windows current verification v$($Manifest.version)" -ForegroundColor Green
