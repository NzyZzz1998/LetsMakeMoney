param(
    [switch]$SkipInstall
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$SpikeRoot = Split-Path -Parent $ProjectRoot
$ToolchainRoot = Join-Path $SpikeRoot ".toolchains"
$CargoHome = Join-Path $ToolchainRoot "cargo"
$RustupHome = Join-Path $ToolchainRoot "rustup"
$VisualStudioRoot = "D:\Work\Software\swift-windows\vs-buildtools"
$VcVars = Join-Path $VisualStudioRoot "VC\Auxiliary\Build\vcvars64.bat"
$Node = "D:\Work\Software\nodejs\node.exe"
$Npm = "D:\Work\Software\nodejs\npm.cmd"

if (-not (Test-Path -LiteralPath $Node -PathType Leaf)) {
    throw "Node.js 22 not found: $Node"
}
if (-not (Test-Path -LiteralPath (Join-Path $CargoHome "bin\cargo.exe") -PathType Leaf)) {
    throw "Isolated Rust toolchain is not installed. Run ..\scripts\install-toolchains.ps1 -Toolchain Rust."
}
if (-not (Test-Path -LiteralPath $VcVars -PathType Leaf)) {
    throw "MSVC Build Tools not found: $VcVars"
}

Set-Location -LiteralPath $ProjectRoot
$env:RUSTUP_HOME = $RustupHome
$env:CARGO_HOME = $CargoHome
$env:npm_config_cache = Join-Path $ToolchainRoot "npm-cache"

$DeveloperEnvironment = & cmd.exe /d /s /c "`"$VcVars`" >nul && set"
foreach ($Entry in $DeveloperEnvironment) {
    if ($Entry -match '^([^=]+)=(.*)$') {
        [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
    }
}
$env:PATH = "$(Join-Path $CargoHome 'bin');D:\Work\Software\nodejs;$env:PATH"

if (-not $SkipInstall -or -not (Test-Path -LiteralPath (Join-Path $ProjectRoot "node_modules"))) {
    & $Npm install
    if ($LASTEXITCODE -ne 0) {
        throw "npm install failed."
    }
}

& $Npm run test:contract
if ($LASTEXITCODE -ne 0) {
    throw "Tauri contract verification failed."
}
& $Npm run build:web
if ($LASTEXITCODE -ne 0) {
    throw "Tauri web build failed."
}
& (Join-Path $CargoHome "bin\cargo.exe") +stable-x86_64-pc-windows-msvc test --locked --manifest-path (Join-Path $ProjectRoot "src-tauri\Cargo.toml")
if ($LASTEXITCODE -ne 0) {
    throw "Tauri Rust tests failed."
}
& $Npm run tauri -- build --no-bundle -- --locked
if ($LASTEXITCODE -ne 0) {
    throw "Tauri desktop build failed."
}

$Executable = Join-Path $ProjectRoot "src-tauri\target\release\lmm_v1_tauri_spike.exe"
if (-not (Test-Path -LiteralPath $Executable -PathType Leaf)) {
    throw "Tauri executable not found: $Executable"
}
Get-FileHash -LiteralPath $Executable -Algorithm SHA256
