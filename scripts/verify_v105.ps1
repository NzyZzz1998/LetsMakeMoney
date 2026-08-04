param(
    [ValidateSet("M0", "M1", "M2", "M3", "M4", "M5", "M6")]
    [string]$Milestone = "M0",
    [string]$PythonExe = "",
    [string]$CandidatePath = ""
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$AppRoot = Join-Path $RepoRoot "apps\windows-v1"
. (Join-Path $PSScriptRoot "v10_tools.ps1")

if ([string]::IsNullOrWhiteSpace($PythonExe)) {
    $PythonExe = Get-V10Python
}

if ($Milestone -in @("M5", "M6")) {
    & $PythonExe (Join-Path $AppRoot "tests\verify_v105_m5.py")
    if ($LASTEXITCODE -ne 0) {
        throw "v1.0.5 M5 evidence verification failed with exit code $LASTEXITCODE"
    }

    & $PythonExe (Join-Path $AppRoot "tests\verify_v105_m5_tests.py")
    if ($LASTEXITCODE -ne 0) {
        throw "v1.0.5 M5 negative contract tests failed with exit code $LASTEXITCODE"
    }

    & (Join-Path $PSScriptRoot "verify_architecture.ps1")
    if ($LASTEXITCODE -ne 0) {
        throw "v1.0.5 M5 architecture verification failed with exit code $LASTEXITCODE"
    }
}
elseif ($Milestone -eq "M4") {
    & $PythonExe (Join-Path $AppRoot "tests\verify_v105_m4.py")
    if ($LASTEXITCODE -ne 0) {
        throw "v1.0.5 M4 evidence verification failed with exit code $LASTEXITCODE"
    }

    & $PythonExe (Join-Path $AppRoot "tests\verify_v105_m4_tests.py")
    if ($LASTEXITCODE -ne 0) {
        throw "v1.0.5 M4 negative contract tests failed with exit code $LASTEXITCODE"
    }

    & (Join-Path $PSScriptRoot "verify_architecture.ps1")
    if ($LASTEXITCODE -ne 0) {
        throw "v1.0.5 M4 architecture verification failed with exit code $LASTEXITCODE"
    }
}
elseif ($Milestone -eq "M3") {
    & $PythonExe (Join-Path $AppRoot "tests\verify_v105_m3.py")
    if ($LASTEXITCODE -ne 0) {
        throw "v1.0.5 M3 evidence verification failed with exit code $LASTEXITCODE"
    }

    & $PythonExe (Join-Path $AppRoot "tests\verify_v105_m3_tests.py")
    if ($LASTEXITCODE -ne 0) {
        throw "v1.0.5 M3 negative contract tests failed with exit code $LASTEXITCODE"
    }

    & (Join-Path $PSScriptRoot "verify_architecture.ps1")
    if ($LASTEXITCODE -ne 0) {
        throw "v1.0.5 M3 architecture verification failed with exit code $LASTEXITCODE"
    }
}
else {
    & $PythonExe (Join-Path $AppRoot "tests\verify_v105_m0.py")
    if ($LASTEXITCODE -ne 0) {
        throw "v1.0.5 M0 evidence verification failed with exit code $LASTEXITCODE"
    }

    & $PythonExe (Join-Path $AppRoot "tests\verify_v105_m0_tests.py")
    if ($LASTEXITCODE -ne 0) {
        throw "v1.0.5 M0 negative contract tests failed with exit code $LASTEXITCODE"
    }
}

if ($Milestone -in @("M1", "M2")) {
    & $PythonExe (Join-Path $AppRoot "tests\verify_v105_m1.py")
    if ($LASTEXITCODE -ne 0) {
        throw "v1.0.5 M1 evidence verification failed with exit code $LASTEXITCODE"
    }

    & $PythonExe (Join-Path $AppRoot "tests\verify_v105_m1_tests.py")
    if ($LASTEXITCODE -ne 0) {
        throw "v1.0.5 M1 negative contract tests failed with exit code $LASTEXITCODE"
    }

    & $PythonExe (Join-Path $AppRoot "tests\verify_v105_package_tests.py")
    if ($LASTEXITCODE -ne 0) {
        throw "v1.0.5 package identity contract tests failed with exit code $LASTEXITCODE"
    }
}

if ($Milestone -eq "M2") {
    & $PythonExe (Join-Path $AppRoot "tests\verify_v105_m2.py")
    if ($LASTEXITCODE -ne 0) {
        throw "v1.0.5 M2 evidence verification failed with exit code $LASTEXITCODE"
    }

    & $PythonExe (Join-Path $AppRoot "tests\verify_v105_m2_tests.py")
    if ($LASTEXITCODE -ne 0) {
        throw "v1.0.5 M2 negative contract tests failed with exit code $LASTEXITCODE"
    }

    $node = Get-V10Node -RepoRoot $RepoRoot
    $esbuild = Get-ChildItem -LiteralPath (Join-Path $AppRoot "node_modules") -Filter "esbuild.exe" -File -Recurse |
        Select-Object -First 1 -ExpandProperty FullName
    if (-not $esbuild) {
        throw "esbuild.exe was not found under apps\windows-v1\node_modules."
    }

    $artifactRoot = Join-Path $RepoRoot ".artifacts\acceptance\v1.0.5"
    New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null

    $characterizationSource = Join-Path $AppRoot "tests\mini-edge-auto-hide.m2-characterization.behavior.ts"
    $characterizationBundle = Join-Path $artifactRoot "m2-characterization.mjs"
    & $esbuild $characterizationSource --bundle --platform=node --format=esm --outfile=$characterizationBundle
    if ($LASTEXITCODE -ne 0) {
        throw "M2 characterization bundle failed with exit code $LASTEXITCODE"
    }
    & $node $characterizationBundle
    if ($LASTEXITCODE -ne 0) {
        throw "M2 characterization behavior failed with exit code $LASTEXITCODE"
    }

    $targetSource = Join-Path $AppRoot "tests\mini-edge-auto-hide.m2-target.behavior.ts"
    $targetBundle = Join-Path $artifactRoot "m2-target.mjs"
    & $esbuild $targetSource --bundle --platform=node --format=esm --outfile=$targetBundle
    if ($LASTEXITCODE -ne 0) {
        throw "M2 target bundle failed with exit code $LASTEXITCODE"
    }

    $targetStdout = Join-Path $artifactRoot "m2-target.stdout.txt"
    $targetStderr = Join-Path $artifactRoot "m2-target.stderr.txt"
    $targetProcess = Start-Process `
        -FilePath $node `
        -ArgumentList @($targetBundle) `
        -NoNewWindow `
        -Wait `
        -PassThru `
        -RedirectStandardOutput $targetStdout `
        -RedirectStandardError $targetStderr
    $targetOutput = @(
        Get-Content -LiteralPath $targetStdout -Raw -ErrorAction SilentlyContinue
        Get-Content -LiteralPath $targetStderr -Raw -ErrorAction SilentlyContinue
    ) -join "`n"
    $targetExitCode = $targetProcess.ExitCode
    if ($targetExitCode -eq 0) {
        throw "M2 target behavior unexpectedly passed before M3 implementation."
    }
    if ($targetOutput -notmatch "M2_RED_NO_POINTERLEAVE_RETRACT") {
        throw "M2 target behavior failed without the expected red-test marker."
    }
    Write-Host "PASS M2 target behavior remains red with the expected marker" -ForegroundColor Yellow
}

if ($Milestone -eq "M6") {
    if ([string]::IsNullOrWhiteSpace($CandidatePath)) {
        throw "M6 requires -CandidatePath pointing to the isolated v1.0.5 candidate Zip."
    }
    $CandidatePath = [IO.Path]::GetFullPath($CandidatePath)
    if (-not (Test-Path -LiteralPath $CandidatePath -PathType Leaf)) {
        throw "M6 candidate Zip does not exist: $CandidatePath"
    }

    & $PythonExe (Join-Path $AppRoot "tests\verify_v105_package_tests.py")
    if ($LASTEXITCODE -ne 0) {
        throw "v1.0.5 package identity negative tests failed with exit code $LASTEXITCODE"
    }

    & $PythonExe (Join-Path $AppRoot "tests\verify_v105_m6_tests.py")
    if ($LASTEXITCODE -ne 0) {
        throw "v1.0.5 M6 negative contract tests failed with exit code $LASTEXITCODE"
    }

    & $PythonExe (Join-Path $AppRoot "tests\verify_v105_m6.py") `
        --candidate-path $CandidatePath
    if ($LASTEXITCODE -ne 0) {
        throw "v1.0.5 M6 candidate verification failed with exit code $LASTEXITCODE"
    }

    $Node = Get-V10Node -RepoRoot $RepoRoot
    $NodeModules = Join-Path $AppRoot "node_modules"
    Push-Location $AppRoot
    try {
        & $Node (Join-Path $NodeModules "typescript\bin\tsc")
        if ($LASTEXITCODE -ne 0) {
            throw "v1.0.5 TypeScript strict verification failed with exit code $LASTEXITCODE"
        }
        & $Node (Join-Path $NodeModules "vite\bin\vite.js") build
        if ($LASTEXITCODE -ne 0) {
            throw "v1.0.5 Vite production build failed with exit code $LASTEXITCODE"
        }
    }
    finally {
        Pop-Location
    }

    $Cargo = Get-V10Cargo -RepoRoot $RepoRoot
    $RustToolchain = Get-V10RustToolchain
    $CargoManifest = Join-Path $AppRoot "src-tauri\Cargo.toml"

    & $Cargo "+$RustToolchain" test --manifest-path $CargoManifest --locked --no-fail-fast
    if ($LASTEXITCODE -ne 0) {
        throw "v1.0.5 cargo test failed with exit code $LASTEXITCODE"
    }
    & $Cargo "+$RustToolchain" fmt --manifest-path $CargoManifest -- --check
    if ($LASTEXITCODE -ne 0) {
        throw "v1.0.5 cargo fmt check failed with exit code $LASTEXITCODE"
    }
    & $Cargo "+$RustToolchain" clippy --manifest-path $CargoManifest --locked --all-targets -- -D warnings
    if ($LASTEXITCODE -ne 0) {
        throw "v1.0.5 cargo clippy failed with exit code $LASTEXITCODE"
    }
    & $Cargo "+$RustToolchain" build --manifest-path $CargoManifest --release --locked
    if ($LASTEXITCODE -ne 0) {
        throw "v1.0.5 cargo release build failed with exit code $LASTEXITCODE"
    }
}

& (Join-Path $PSScriptRoot "verify_v10_docs.ps1")
if ($LASTEXITCODE -ne 0) {
    throw "v1.0.5 inherited documentation verification failed with exit code $LASTEXITCODE"
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

Write-Host "PASS LetsMakeMoney v1.0.5 aggregate verification ($Milestone)" -ForegroundColor Green
