param(
    [string]$NativePath = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")).Path "native\windows"),
    [string]$DependencyLockPath,
    [string]$GodotCppPath,
    [string]$CacheRoot,
    [string]$BuildCacheRoot,
    [string]$Msys2Bash = "$env:LMM_MSYS2_BASH",
    [int]$Jobs = 8,
    [ValidateSet("template_debug", "template_release")]
    [string]$Target = "template_debug",
    [switch]$BootstrapDependencies,
    [switch]$Offline,
    [switch]$ForceDependencies,
    [switch]$FetchGodotCpp,
    [switch]$ValidateOnly
)

$ErrorActionPreference = "Stop"
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

function ConvertTo-MsysPath {
    param([string]$Path)

    $resolved = (Resolve-Path -LiteralPath $Path).Path
    if ($resolved -notmatch '^([A-Za-z]):\\(.*)$') {
        throw "Cannot convert path to MSYS2 path: $resolved"
    }
    return "/" + $Matches[1].ToLowerInvariant() + "/" + ($Matches[2] -replace '\\', '/')
}

function Require-Command {
    param([string]$Name, [string]$Message)

    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if ($null -eq $command) {
        throw $Message
    }
    return $command.Source
}

function Invoke-Captured {
    param([scriptblock]$Action, [string]$FailureMessage)

    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $output = & $Action 2>&1 | Out-String
    $exitCode = $LASTEXITCODE
    $ErrorActionPreference = $previousPreference
    if ($exitCode -ne 0) {
        throw "$FailureMessage (exit $exitCode): $($output.Trim())"
    }
    return $output.Trim()
}

if (-not (Test-Path -LiteralPath $NativePath -PathType Container)) {
    throw "Native path not found: $NativePath"
}
if ([string]::IsNullOrWhiteSpace($DependencyLockPath)) {
    $DependencyLockPath = Join-Path $projectRoot "third_party\native-toolchain.lock.json"
}
if ([string]::IsNullOrWhiteSpace($GodotCppPath)) {
    $GodotCppPath = Join-Path $NativePath "godot-cpp"
}
if ([string]::IsNullOrWhiteSpace($CacheRoot)) {
    $CacheRoot = Join-Path $projectRoot ".cache\dependencies"
}
if ([string]::IsNullOrWhiteSpace($BuildCacheRoot)) {
    $BuildCacheRoot = Join-Path $projectRoot ".cache\native-build"
}
if (-not (Test-Path -LiteralPath $DependencyLockPath -PathType Leaf)) {
    throw "Native dependency lock not found: $DependencyLockPath"
}

$lock = Get-Content -LiteralPath $DependencyLockPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($lock.schema_version -ne 1 -or $lock.godot_cpp.commit -notmatch '^[0-9a-fA-F]{40}$') {
    throw "Native dependency lock is invalid: $DependencyLockPath"
}

if ($FetchGodotCpp) {
    $BootstrapDependencies = $true
}
if ($BootstrapDependencies) {
    $bootstrap = Join-Path $PSScriptRoot "bootstrap_native_dependencies.ps1"
    & $bootstrap -ProjectRoot $projectRoot -LockPath $DependencyLockPath -CacheRoot $CacheRoot -GodotCppPath $GodotCppPath -Offline:$Offline -Force:$ForceDependencies
}

if (-not (Test-Path -LiteralPath (Join-Path $GodotCppPath ".git"))) {
    throw "Missing verified godot-cpp checkout. Run bootstrap_native_dependencies.ps1 first: $GodotCppPath"
}
$actualCommit = (Invoke-Captured { git -C $GodotCppPath rev-parse HEAD } "Unable to read godot-cpp commit").ToLowerInvariant()
$expectedCommit = ([string]$lock.godot_cpp.commit).ToLowerInvariant()
if ($actualCommit -ne $expectedCommit) {
    throw "godot-cpp checkout does not match lock. Expected $expectedCommit, got $actualCommit"
}
$godotCppStatus = (& git -C $GodotCppPath status --porcelain | Out-String).Trim()
if (-not [string]::IsNullOrWhiteSpace($godotCppStatus)) {
    throw "godot-cpp working tree has local changes. Re-run the dependency bootstrap with -Force."
}

$pythonCommand = if ([string]::IsNullOrWhiteSpace($env:LMM_PYTHON_EXE)) {
    Require-Command "python" "python was not found. Set LMM_PYTHON_EXE or add Python to PATH."
}
else {
    if (-not (Test-Path -LiteralPath $env:LMM_PYTHON_EXE -PathType Leaf)) {
        throw "LMM_PYTHON_EXE does not exist: $env:LMM_PYTHON_EXE"
    }
    (Resolve-Path -LiteralPath $env:LMM_PYTHON_EXE).Path
}

$pythonVersion = Invoke-Captured { & $pythonCommand --version } "Unable to query Python"
$sconsVersion = Invoke-Captured { & $pythonCommand -m SCons --version } "Unable to query SCons"
$sconsIdentity = (($sconsVersion -split "`r?`n") | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^SCons:' } | Select-Object -First 1)
if ([string]::IsNullOrWhiteSpace($sconsIdentity)) {
    $sconsIdentity = ($sconsVersion -split "`r?`n")[0]
}

$compilerMode = "PATH"
$compilerIdentity = ""
if (-not [string]::IsNullOrWhiteSpace($Msys2Bash)) {
    if (-not (Test-Path -LiteralPath $Msys2Bash -PathType Leaf)) {
        throw "MSYS2 bash not found: $Msys2Bash"
    }
    $Msys2Bash = (Resolve-Path -LiteralPath $Msys2Bash).Path
    $compilerMode = "MSYS2 UCRT64"
    $compilerIdentity = Invoke-Captured { & $Msys2Bash -lc "export PATH=/ucrt64/bin:/usr/bin:`$PATH; g++ --version | head -n 1" } "Unable to query MSYS2 compiler"
}
else {
    $compiler = Require-Command "g++" "g++ was not found. Set LMM_MSYS2_BASH or add a Windows x86_64 compiler to PATH."
    $compilerIdentity = Invoke-Captured { & $compiler --version } "Unable to query compiler"
    $compilerIdentity = ($compilerIdentity -split "`r?`n")[0]
}

$godotDetected = "not configured; expected $($lock.godot.version) ($($lock.godot.commit))"
if (-not [string]::IsNullOrWhiteSpace($env:LMM_GODOT_EXE) -and (Test-Path -LiteralPath $env:LMM_GODOT_EXE -PathType Leaf)) {
    $godotHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $env:LMM_GODOT_EXE).Hash
    $godotFileName = [IO.Path]::GetFileName($env:LMM_GODOT_EXE)
    $expectedGodotHash = if ($godotFileName.EndsWith("_console.exe", [StringComparison]::OrdinalIgnoreCase)) {
        ([string]$lock.godot.windows_x86_64_console_executable_sha256).ToUpperInvariant()
    }
    else {
        ([string]$lock.godot.windows_x86_64_executable_sha256).ToUpperInvariant()
    }
    if ($godotHash -ne $expectedGodotHash) {
        throw "Godot executable SHA256 does not match lock. Expected $expectedGodotHash, got $godotHash"
    }
    $godotDetected = "$env:LMM_GODOT_EXE; sha256=$godotHash"
}

$nativeMsys = "not used"
$pythonMsys = "not used"
if ($compilerMode -eq "MSYS2 UCRT64") {
    $nativeMsys = ConvertTo-MsysPath $NativePath
    $pythonMsys = ConvertTo-MsysPath $pythonCommand
}

Write-Output "Native toolchain identity"
Write-Output "  Lock: $DependencyLockPath"
Write-Output "  Godot: $godotDetected"
Write-Output "  Python: $pythonVersion ($pythonCommand)"
Write-Output "  SCons: $sconsIdentity"
Write-Output "  Compiler: $compilerIdentity [$compilerMode]"
Write-Output "  Windows SDK: not required by the MSYS2 UCRT64 build path"
Write-Output "  godot-cpp: $actualCommit"
Write-Output "  Target: $Target / x86_64"
Write-Output "  MSYS native path: $nativeMsys"
Write-Output "  Build cache: $BuildCacheRoot"

if ($ValidateOnly) {
    Write-Output "Native build validation passed."
    return
}

if ($compilerMode -eq "MSYS2 UCRT64") {
    $msysHome = Join-Path $BuildCacheRoot "home"
    $msysTmp = Join-Path $BuildCacheRoot "tmp"
    New-Item -ItemType Directory -Force -Path $msysHome, $msysTmp | Out-Null

    $homeMsys = ConvertTo-MsysPath $msysHome
    $tmpMsys = ConvertTo-MsysPath $msysTmp
    $bashCommand = "export HOME='$homeMsys'; export TMPDIR='$tmpMsys'; export TEMP='$tmpMsys'; export TMP='$tmpMsys'; export PATH=/ucrt64/bin:/usr/bin:`$PATH; cd '$nativeMsys'; '$pythonMsys' -m SCons platform=windows use_mingw=yes target=$Target arch=x86_64 -j$Jobs"
    Invoke-Captured { & $Msys2Bash -lc $bashCommand } "Native build failed" | Write-Output
}
else {
    Push-Location $NativePath
    try {
        Invoke-Captured { & $pythonCommand -m SCons platform=windows target=$Target arch=x86_64 "-j$Jobs" } "Native build failed" | Write-Output
    }
    finally {
        Pop-Location
    }
}

$dll = Join-Path $NativePath "bin\win64\letsmakemoney_native.dll"
if (-not (Test-Path -LiteralPath $dll -PathType Leaf)) {
    throw "Native build finished but DLL was not found: $dll"
}

Write-Output "Native build passed: $dll"
