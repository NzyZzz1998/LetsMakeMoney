$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
. (Join-Path $repoRoot "scripts\v10_tools.ps1")

function Assert-Equal([object]$Actual, [object]$Expected, [string]$Message) {
    if ($Actual -ne $Expected) {
        throw "$Message Expected '$Expected', got '$Actual'."
    }
}

function Write-FixtureExecutable([string]$Path) {
    New-Item -ItemType Directory -Path (Split-Path -Parent $Path) -Force | Out-Null
    Set-Content -LiteralPath $Path -Value "fixture" -Encoding ascii
}

$sandbox = [IO.Path]::GetFullPath((Join-Path $env:TEMP "lmm-v104-tool-resolution-$PID"))
$tempRoot = [IO.Path]::GetFullPath($env:TEMP).TrimEnd('\') + '\'
if (-not $sandbox.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Tool-resolution sandbox escaped the temporary directory."
}

$explicitRoot = Join-Path $sandbox "explicit"
$pathRoot = Join-Path $sandbox "path"
$cacheRoot = Join-Path $sandbox "cache-repo"
$emptyRoot = Join-Path $sandbox "empty-repo"
$toolNames = @("NODE", "PYTHON", "CARGO")
$savedEnvironment = @{}
foreach ($name in @("PATH", "LMM_NODE", "LMM_PYTHON", "LMM_CARGO", "LMM_CARGO_HOME", "LMM_RUSTUP_HOME", "CARGO_HOME", "RUSTUP_HOME")) {
    $savedEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, "Process")
}

try {
    $explicitNode = Join-Path $explicitRoot "node.exe"
    $explicitPython = Join-Path $explicitRoot "python.exe"
    $explicitCargo = Join-Path $explicitRoot "cargo.exe"
    $pathNode = Join-Path $pathRoot "node.exe"
    $pathPython = Join-Path $pathRoot "python.exe"
    $pathCargo = Join-Path $pathRoot "cargo.exe"
    $cacheNode = Join-Path $cacheRoot ".toolchains\node\node.exe"
    $cachePython = Join-Path $cacheRoot ".toolchains\python\python.exe"
    $cacheCargo = Join-Path $cacheRoot ".toolchains\cargo\bin\cargo.exe"
    foreach ($path in @(
        $explicitNode, $explicitPython, $explicitCargo,
        $pathNode, $pathPython, $pathCargo,
        $cacheNode, $cachePython, $cacheCargo
    )) {
        Write-FixtureExecutable $path
    }
    New-Item -ItemType Directory -Path $emptyRoot -Force | Out-Null

    $env:PATH = ""
    $env:LMM_NODE = $explicitNode
    $env:LMM_PYTHON = $explicitPython
    $env:LMM_CARGO = $explicitCargo
    $nodeResolution = Get-V10NodeResolution -RepoRoot $cacheRoot
    $pythonResolution = Get-V10PythonResolution -RepoRoot $cacheRoot
    $cargoResolution = Get-V10CargoResolution -RepoRoot $cacheRoot
    Assert-Equal $nodeResolution.Path ([IO.Path]::GetFullPath($explicitNode)) "Node explicit resolution failed."
    Assert-Equal $nodeResolution.Source "explicit:LMM_NODE" "Node explicit source failed."
    Assert-Equal $pythonResolution.Path ([IO.Path]::GetFullPath($explicitPython)) "Python explicit resolution failed."
    Assert-Equal $pythonResolution.Source "explicit:LMM_PYTHON" "Python explicit source failed."
    Assert-Equal $cargoResolution.Path ([IO.Path]::GetFullPath($explicitCargo)) "Cargo explicit resolution failed."
    Assert-Equal $cargoResolution.Source "explicit:LMM_CARGO" "Cargo explicit source failed."
    Write-Host "PASS explicit tool variables"

    foreach ($name in $toolNames) {
        Remove-Item "Env:LMM_$name" -ErrorAction SilentlyContinue
    }
    $env:PATH = $pathRoot
    Assert-Equal (Get-V10NodeResolution -RepoRoot $cacheRoot).Source "PATH" "Node PATH source failed."
    Assert-Equal (Get-V10PythonResolution -RepoRoot $cacheRoot).Source "PATH" "Python PATH source failed."
    Assert-Equal (Get-V10CargoResolution -RepoRoot $cacheRoot).Source "PATH" "Cargo PATH source failed."
    Write-Host "PASS PATH tools"

    $env:PATH = ""
    $cargoCacheResolution = Get-V10CargoResolution -RepoRoot $cacheRoot
    Assert-Equal (Get-V10NodeResolution -RepoRoot $cacheRoot).Source "repo-cache" "Node cache source failed."
    Assert-Equal (Get-V10PythonResolution -RepoRoot $cacheRoot).Source "repo-cache" "Python cache source failed."
    Assert-Equal $cargoCacheResolution.Source "repo-cache" "Cargo cache source failed."
    Assert-Equal $env:CARGO_HOME ([IO.Path]::GetFullPath((Join-Path $cacheRoot ".toolchains\cargo"))) "Cargo cache home failed."
    Assert-Equal $env:RUSTUP_HOME ([IO.Path]::GetFullPath((Join-Path $cacheRoot ".toolchains\rustup"))) "Rustup cache home failed."
    Write-Host "PASS repository tool cache"

    $failure = $null
    try {
        Get-V10NodeResolution -RepoRoot $emptyRoot | Out-Null
    }
    catch {
        $failure = $_.Exception.Message
    }
    if (-not $failure -or
        $failure -notmatch "LMM_NODE" -or
        $failure -notmatch "PATH" -or
        $failure -notmatch "\.toolchains") {
        throw "Missing-tool failure must name the explicit variable, PATH, and repository cache."
    }
    Write-Host "PASS actionable missing-tool failure"

    $resolverText = Get-Content -LiteralPath (Join-Path $repoRoot "scripts\v10_tools.ps1") -Raw -Encoding utf8
    foreach ($forbidden in @("spikes\v1.0-ui\.toolchains", "codex-runtimes", "USERPROFILE")) {
        if ($resolverText.Contains($forbidden)) {
            throw "Formal resolver still references private or spike path: $forbidden"
        }
    }
    Write-Host "PASS no private or spike fallback"
}
finally {
    foreach ($name in $savedEnvironment.Keys) {
        $savedValue = $savedEnvironment[$name]
        if ($null -eq $savedValue) {
            [Environment]::SetEnvironmentVariable($name, $null, "Process")
        } else {
            [Environment]::SetEnvironmentVariable($name, $savedValue, "Process")
        }
    }
    if (Test-Path -LiteralPath $sandbox) {
        Remove-Item -LiteralPath $sandbox -Recurse -Force
    }
}

Write-Host "PASS v1.0.4 tool resolution (5/5)"
