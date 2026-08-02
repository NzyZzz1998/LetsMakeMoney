param(
    [ValidateSet("M5", "M6")]
    [string]$Milestone = "M5",
    [string]$PythonExe = "",
    [string]$CandidatePath = ""
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$AppRoot = Join-Path $RepoRoot "apps\windows-v1"
. (Join-Path $PSScriptRoot "v10_tools.ps1")

if ([string]::IsNullOrWhiteSpace($PythonExe)) {
    $PythonExe = Get-V10Python -RepoRoot $RepoRoot
}
$Node = Get-V10Node -RepoRoot $RepoRoot
$Cargo = Get-V10Cargo -RepoRoot $RepoRoot
$RustToolchain = Get-V10RustToolchain
$CargoManifest = Join-Path $AppRoot "src-tauri\Cargo.toml"

& $PythonExe (Join-Path $AppRoot "tests\verify_v106.py")
if ($LASTEXITCODE -ne 0) {
    throw "v1.0.6 targeted contract verification failed with exit code $LASTEXITCODE"
}

& (Join-Path $PSScriptRoot "verify_architecture.ps1")
if ($LASTEXITCODE -ne 0) {
    throw "v1.0.6 architecture verification failed with exit code $LASTEXITCODE"
}

Push-Location $AppRoot
try {
    & $Node (Join-Path $AppRoot "node_modules\typescript\bin\tsc")
    if ($LASTEXITCODE -ne 0) {
        throw "v1.0.6 TypeScript strict verification failed with exit code $LASTEXITCODE"
    }
    & $Node (Join-Path $AppRoot "node_modules\vite\bin\vite.js") build
    if ($LASTEXITCODE -ne 0) {
        throw "v1.0.6 Vite production build failed with exit code $LASTEXITCODE"
    }
}
finally {
    Pop-Location
}

& $Cargo "+$RustToolchain" test --manifest-path $CargoManifest --locked --no-fail-fast
if ($LASTEXITCODE -ne 0) {
    throw "v1.0.6 cargo test failed with exit code $LASTEXITCODE"
}
& $Cargo "+$RustToolchain" fmt --manifest-path $CargoManifest -- --check
if ($LASTEXITCODE -ne 0) {
    throw "v1.0.6 cargo fmt failed with exit code $LASTEXITCODE"
}
& $Cargo "+$RustToolchain" clippy --manifest-path $CargoManifest --locked --all-targets -- -D warnings
if ($LASTEXITCODE -ne 0) {
    throw "v1.0.6 cargo clippy failed with exit code $LASTEXITCODE"
}

& (Join-Path $PSScriptRoot "verify_v10_docs.ps1")
if ($LASTEXITCODE -ne 0) {
    throw "v1.0.6 documentation verification failed with exit code $LASTEXITCODE"
}

if ($Milestone -eq "M6") {
    if ([string]::IsNullOrWhiteSpace($CandidatePath)) {
        throw "M6 requires -CandidatePath pointing to a v1.0.6 candidate Zip."
    }
    $SourceHead = (git -C $RepoRoot rev-parse HEAD).Trim()
    & (Join-Path $PSScriptRoot "verify_v106_package.ps1") `
        -Mode candidate `
        -PackagePath $CandidatePath `
        -ExpectedSourceHead $SourceHead `
        -PythonExe $PythonExe
    if ($LASTEXITCODE -ne 0) {
        throw "v1.0.6 M6 package verification failed with exit code $LASTEXITCODE"
    }
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

Write-Host "PASS LetsMakeMoney v1.0.6 aggregate verification ($Milestone)" -ForegroundColor Green
