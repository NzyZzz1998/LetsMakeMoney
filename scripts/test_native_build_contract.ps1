param(
    [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [string]$Msys2Bash = "$env:LMM_MSYS2_BASH"
)

$ErrorActionPreference = "Stop"
$build = Join-Path $ProjectRoot "scripts\build_native_windows.ps1"
$lock = Join-Path $ProjectRoot "third_party\native-toolchain.lock.json"
$godotCpp = Join-Path $ProjectRoot "native\windows\godot-cpp"
$bootstrapGodot = Get-Content -LiteralPath (Join-Path $ProjectRoot "scripts\bootstrap_godot.ps1") -Raw -Encoding UTF8
$lockData = Get-Content -LiteralPath $lock -Raw -Encoding UTF8 | ConvertFrom-Json

if ([string]::IsNullOrWhiteSpace([string]$lockData.godot.windows_x86_64_executable_sha256) -or
    [string]::IsNullOrWhiteSpace([string]$lockData.godot.windows_x86_64_console_executable_sha256)) {
    throw "Native toolchain lock must pin both Godot GUI and console executable hashes."
}
if ($lockData.godot.windows_x86_64_executable_sha256 -eq $lockData.godot.windows_x86_64_console_executable_sha256) {
    throw "Godot GUI and console executable hashes must be independently pinned."
}
if (-not $bootstrapGodot.Contains("windows_x86_64_console_executable_sha256")) {
    throw "Godot bootstrap must validate the console executable against its dedicated hash."
}

$output = & $build -DependencyLockPath $lock -GodotCppPath $godotCpp -Msys2Bash $Msys2Bash -ValidateOnly 2>&1 | Out-String
if ($LASTEXITCODE -ne 0) {
    throw "Native build validation failed: $output"
}

foreach ($required in @("Python:", "SCons:", "4.10.1", "godot-cpp:", "Compiler:", "MSYS native path:", "Build cache:", "Native build validation passed")) {
    if ($output -notmatch [Regex]::Escape($required)) {
        throw "Native build validation output is missing '$required'. Output: $output"
    }
}

$sandbox = Join-Path ([IO.Path]::GetTempPath()) ("lmm-native-build-contract-" + [Guid]::NewGuid().ToString("N"))
try {
    New-Item -ItemType Directory -Path $sandbox -Force | Out-Null
    $dirtyRepo = Join-Path $sandbox "godot-cpp"
    New-Item -ItemType Directory -Path $dirtyRepo -Force | Out-Null
    git -C $dirtyRepo init --quiet
    git -C $dirtyRepo config user.name "Build Contract Test"
    git -C $dirtyRepo config user.email "build-contract@example.invalid"
    [IO.File]::WriteAllText((Join-Path $dirtyRepo "README.md"), "fixture`n", [Text.UTF8Encoding]::new($false))
    git -C $dirtyRepo add README.md
    git -C $dirtyRepo commit --quiet -m "fixture"
    $dirtyCommit = (git -C $dirtyRepo rev-parse HEAD).Trim()
    Add-Content -LiteralPath (Join-Path $dirtyRepo "README.md") -Value "dirty"
    $dirtyLock = Get-Content -LiteralPath $lock -Raw -Encoding UTF8 | ConvertFrom-Json
    $dirtyLock.godot_cpp.commit = $dirtyCommit
    $dirtyLockPath = Join-Path $sandbox "dirty-lock.json"
    [IO.File]::WriteAllText($dirtyLockPath, ($dirtyLock | ConvertTo-Json -Depth 10), [Text.UTF8Encoding]::new($false))
    $dirtyFailed = $false
    try {
        & $build -DependencyLockPath $dirtyLockPath -GodotCppPath $dirtyRepo -Msys2Bash $Msys2Bash -ValidateOnly | Out-Null
    }
    catch {
        $dirtyFailed = $true
        if ($_.Exception.Message -notmatch "godot-cpp working tree has local changes") {
            throw
        }
    }
    if (-not $dirtyFailed) {
        throw "Native build validation accepted a dirty godot-cpp checkout."
    }

    $fakeGodot = Join-Path $sandbox "godot.exe"
    [IO.File]::WriteAllText($fakeGodot, "not-godot", [Text.UTF8Encoding]::new($false))
    $previousGodot = $env:LMM_GODOT_EXE
    $env:LMM_GODOT_EXE = $fakeGodot
    $failed = $false
    try {
        & $build -DependencyLockPath $lock -GodotCppPath $godotCpp -Msys2Bash $Msys2Bash -ValidateOnly | Out-Null
    }
    catch {
        $failed = $true
        if ($_.Exception.Message -notmatch "Godot executable SHA256 does not match lock") {
            throw
        }
    }
    if (-not $failed) {
        throw "Native build validation accepted a Godot executable with the wrong SHA256."
    }
}
finally {
    $env:LMM_GODOT_EXE = $previousGodot
    if (Test-Path -LiteralPath $sandbox) {
        Remove-Item -LiteralPath $sandbox -Recurse -Force
    }
}

Write-Host "Native build contract tests passed." -ForegroundColor Green
