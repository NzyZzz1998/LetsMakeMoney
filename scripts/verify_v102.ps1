param(
    [switch]$SkipReleaseBuild
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$AppRoot = Join-Path $RepoRoot "apps\windows-v1"
. (Join-Path $PSScriptRoot "v10_tools.ps1")
$Node = Get-V10Node
$Python = Get-V10Python
$NodeModules = Join-Path $AppRoot "node_modules"
$BehaviorBundles = @()

Push-Location $RepoRoot
try {
    foreach ($milestone in 0..4) {
        $script = Join-Path $PSScriptRoot "verify_v101_m$milestone.ps1"
        $arguments = if ($milestone -ge 3) { @("-SkipFrontendBuild") } else { @() }
        & $script @arguments
        if ($LASTEXITCODE -ne 0) {
            throw "v1.0.1 M$milestone regression failed."
        }
    }

    & $Python (Join-Path $RepoRoot "apps\windows-v1\tests\verify_v102.py")
    if ($LASTEXITCODE -ne 0) {
        throw "v1.0.2 targeted verification failed."
    }

    $Esbuild = Get-ChildItem -LiteralPath $NodeModules -Recurse `
        -Filter "esbuild.exe" -File |
        Select-Object -First 1 -ExpandProperty FullName
    if (-not $Esbuild) {
        throw "esbuild.exe was not found under apps\windows-v1\node_modules."
    }
    foreach ($behaviorName in @("presentation", "theme")) {
        $source = Join-Path $AppRoot "tests\$behaviorName.behavior.ts"
        $bundle = Join-Path $env:TEMP "lmm-v102-$behaviorName-$PID.mjs"
        $BehaviorBundles += $bundle
        & $Esbuild $source --bundle --platform=node --format=esm "--outfile=$bundle"
        if ($LASTEXITCODE -ne 0) {
            throw "v1.0.2 $behaviorName behavior bundle failed."
        }
        & $Node $bundle
        if ($LASTEXITCODE -ne 0) {
            throw "v1.0.2 $behaviorName behavior verification failed."
        }
    }

    & (Join-Path $PSScriptRoot "verify_v10.ps1") -SkipReleaseBuild:$SkipReleaseBuild
    if ($LASTEXITCODE -ne 0) {
        throw "v1.0 regression failed."
    }

    git diff --check
    if ($LASTEXITCODE -ne 0) {
        throw "git diff --check failed."
    }

    Write-Host "LetsMakeMoney v1.0.2 aggregate verification passed." -ForegroundColor Green
}
finally {
    Pop-Location
    foreach ($bundle in $BehaviorBundles) {
        if (Test-Path -LiteralPath $bundle -PathType Leaf) {
            Remove-Item -LiteralPath $bundle -Force
        }
    }
}
