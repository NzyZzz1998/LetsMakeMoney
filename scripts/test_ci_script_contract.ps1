param([string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot))

$ErrorActionPreference = "Stop"

function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}

function Read-Required([string]$RelativePath) {
    $path = Join-Path $ProjectRoot $RelativePath
    Assert-True (Test-Path -LiteralPath $path) "Missing required file: $RelativePath"
    return Get-Content -LiteralPath $path -Raw -Encoding UTF8
}

$verification = Read-Required "scripts/verification_common.ps1"
$package = Read-Required "scripts/package_common.ps1"
$packageVerifier = Read-Required "scripts/verify_package_common.ps1"
$scriptTiers = Read-Required "scripts/script-tiers.json"

foreach ($token in @("Invoke-LmmWithIsolatedAppData", "Resolve-LmmGodotConsoleExecutable", "missing resource", "failed loading resource", "parse error")) {
    Assert-True ($verification.ToLowerInvariant().Contains($token.ToLowerInvariant())) "verification_common.ps1 missing contract: $token"
}
foreach ($token in @("New-LmmPackage", "Stage-LmmReleaseLicenses", "manifest.json", "checksums.txt")) {
    Assert-True ($package.Contains($token)) "package_common.ps1 missing contract: $token"
}
foreach ($token in @("Test-LmmPackage", "ExpectedVersion", "Unexpected binary", "APPDATA")) {
    Assert-True ($packageVerifier.Contains($token)) "verify_package_common.ps1 missing contract: $token"
}
foreach ($token in @('"active"', '"compat"', '"archive"', '"maintainer-assets"')) {
    Assert-True ($scriptTiers.Contains($token)) "script-tiers.json missing contract: $token"
}

foreach ($version in @("04", "05", "06")) {
    $packageWrapper = Read-Required "scripts/package_v$version.ps1"
    Assert-True ($packageWrapper.Contains("package_common.ps1")) "package_v$version.ps1 must call package_common.ps1"
    $verifyWrapper = Read-Required "scripts/verify_v${version}_package.ps1"
    Assert-True ($verifyWrapper.Contains("verify_package_common.ps1")) "verify_v${version}_package.ps1 must call verify_package_common.ps1"
}

foreach ($version in @("07", "08", "09")) {
    $packageWrapper = Read-Required "scripts/package_v$version.ps1"
    Assert-True ($packageWrapper.Contains("package_common.ps1")) "package_v$version.ps1 must call package_common.ps1"
    $verifyWrapper = Read-Required "scripts/verify_v${version}_package.ps1"
    Assert-True ($verifyWrapper.Contains("verify_package_common.ps1")) "verify_v${version}_package.ps1 must call verify_package_common.ps1"
}

$docsWorkflow = Read-Required ".github/workflows/windows-docs.yml"
$mainWorkflow = Read-Required ".github/workflows/windows-verify.yml"
$mainRunner = Read-Required "scripts/run_ci_verification.ps1"
Assert-True ($docsWorkflow.Contains("permissions:") -and $docsWorkflow.Contains("contents: read")) "Docs workflow must use read-only permissions"
Assert-True ($docsWorkflow.Contains("name: Windows docs and compliance")) "Docs job name must match the protected-branch status context"
Assert-True ($mainWorkflow.Contains("pull_request") -and $mainWorkflow.Contains("third_party/native-toolchain.lock.json")) "Main workflow must cover PRs and lock-aware caching"
Assert-True ($mainWorkflow.Contains("name: Windows native and Godot verification")) "Native job name must match the protected-branch status context"
Assert-True (-not $mainWorkflow.Contains("secrets.")) "Fork-safe verification workflow must not read secrets"
Assert-True ($mainWorkflow.Contains("id: msys2") -and $mainWorkflow.Contains("steps.msys2.outputs.msys2-location")) "Main workflow must use the setup-msys2 installation output"
Assert-True (-not $mainWorkflow.Contains("Get-Command bash")) "Main workflow must not accidentally select Git Bash"
Assert-True ($mainRunner.Contains("verify_v09.ps1")) "Main CI runner must use the current v0.9 aggregate verification"

$fakeGodotRoot = Join-Path ([IO.Path]::GetTempPath()) ("lmm-godot-resolution-" + [Guid]::NewGuid().ToString("N"))
try {
    New-Item -ItemType Directory -Force -Path $fakeGodotRoot | Out-Null
    $fakeGui = Join-Path $fakeGodotRoot "Godot_v4.7-stable_win64.exe"
    $fakeConsole = Join-Path $fakeGodotRoot "Godot_v4.7-stable_win64_console.exe"
    New-Item -ItemType File -Path $fakeGui | Out-Null
    New-Item -ItemType File -Path $fakeConsole | Out-Null
    . (Join-Path $ProjectRoot "scripts/verification_common.ps1")
    $resolvedGodot = Resolve-LmmGodotExecutable -ExplicitPath $fakeGui
    Assert-True ($resolvedGodot -eq $fakeConsole) "Godot GUI path must resolve to the console sibling on Windows"
} finally {
    if (Test-Path -LiteralPath $fakeGodotRoot) {
        Remove-Item -LiteralPath $fakeGodotRoot -Recurse -Force
    }
}

Write-Host "CI/script contract tests passed" -ForegroundColor Green
