param(
    [string]$NativePath = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")).Path "native\windows"),
    [string]$GodotCppUrl = "https://github.com/godotengine/godot-cpp.git",
    [string]$Msys2Bash = "$env:LMM_MSYS2_BASH",
    [int]$Jobs = 8,
    [switch]$FetchGodotCpp
)

$ErrorActionPreference = "Stop"

function ConvertTo-MsysPath {
    param([string]$Path)
    $resolved = (Resolve-Path -LiteralPath $Path).Path
    if ($resolved -notmatch "^([A-Za-z]):\\(.*)$") {
        throw "Cannot convert path to MSYS2 path: $resolved"
    }
    return "/" + $Matches[1].ToLowerInvariant() + "/" + ($Matches[2] -replace "\\", "/")
}

function Require-Command {
    param([string]$Name, [string]$Message)
    if ($null -eq (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw $Message
    }
}

if (-not (Test-Path -LiteralPath $NativePath)) {
    throw "Native path not found: $NativePath"
}

$godotCppPath = Join-Path $NativePath "godot-cpp"
if (-not (Test-Path -LiteralPath $godotCppPath)) {
    if (-not $FetchGodotCpp) {
        throw "Missing godot-cpp. Re-run with -FetchGodotCpp or clone it to: $godotCppPath"
    }
    Require-Command "git" "git is required to fetch godot-cpp."
    git clone --depth 1 $GodotCppUrl $godotCppPath
}

Require-Command "python" "python was not found."

if (-not [string]::IsNullOrWhiteSpace($Msys2Bash) -and (Test-Path -LiteralPath $Msys2Bash)) {
    $projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    $workspaceRoot = Split-Path -Parent $projectRoot
    $msysHome = Join-Path $workspaceRoot ".msys_home"
    $msysTmp = Join-Path $workspaceRoot ".msys_tmp"
    New-Item -ItemType Directory -Force -Path $msysHome, $msysTmp | Out-Null

    $pythonCommand = (Get-Command "python").Source
    $nativeMsys = ConvertTo-MsysPath $NativePath
    $pythonMsys = ConvertTo-MsysPath $pythonCommand
    $homeMsys = ConvertTo-MsysPath $msysHome
    $tmpMsys = ConvertTo-MsysPath $msysTmp

    $env:CHERE_INVOKING = "1"
    $env:MSYSTEM = "UCRT64"
    $env:HOME = $homeMsys

    $bashCommand = "export HOME='$homeMsys'; export TMPDIR='$tmpMsys'; export TEMP='$tmpMsys'; export TMP='$tmpMsys'; export PATH=/ucrt64/bin:/usr/bin:`$PATH; cd '$nativeMsys'; '$pythonMsys' -m SCons platform=windows target=template_debug arch=x86_64 -j$Jobs"
    & $Msys2Bash -lc $bashCommand
    if ($LASTEXITCODE -ne 0) {
        throw "Native build failed with exit code $LASTEXITCODE"
    }
}
else {
    Require-Command "g++" "g++ was not found. Install a Windows x86_64 MinGW/llvm-mingw toolchain and add its bin directory to PATH, or pass -Msys2Bash."

    Push-Location $NativePath
    try {
        python -m SCons platform=windows target=template_debug arch=x86_64 -j$Jobs
    }
    finally {
        Pop-Location
    }
}

$dll = Join-Path $NativePath "bin\win64\letsmakemoney_native.dll"
if (-not (Test-Path -LiteralPath $dll)) {
    throw "Native build finished but DLL was not found: $dll"
}

Write-Host "Native build passed: $dll"
