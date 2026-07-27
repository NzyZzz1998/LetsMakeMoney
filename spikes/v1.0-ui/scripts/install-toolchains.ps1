param(
    [ValidateSet("Rust", "DotNet", "All")]
    [string]$Toolchain = "All"
)

$ErrorActionPreference = "Stop"
$SpikeRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$ToolchainRoot = Join-Path $SpikeRoot ".toolchains"
New-Item -ItemType Directory -Path $ToolchainRoot -Force | Out-Null

function Install-RustToolchain {
    $RustupInit = Join-Path $ToolchainRoot "rustup-init.exe"
    $RustupHome = Join-Path $ToolchainRoot "rustup"
    $CargoHome = Join-Path $ToolchainRoot "cargo"
    if (-not (Test-Path -LiteralPath $RustupInit -PathType Leaf)) {
        Invoke-WebRequest -Uri "https://win.rustup.rs/x86_64" -OutFile $RustupInit
    }
    $env:RUSTUP_HOME = $RustupHome
    $env:CARGO_HOME = $CargoHome
    $env:PATH = "$(Join-Path $CargoHome 'bin');$env:PATH"

    $Rustup = Join-Path $CargoHome "bin\rustup.exe"
    if (-not (Test-Path -LiteralPath $Rustup -PathType Leaf)) {
        & $RustupInit -y --no-modify-path --default-host x86_64-pc-windows-msvc --profile minimal
        if ($LASTEXITCODE -ne 0) {
            throw "Rust bootstrap failed with exit code $LASTEXITCODE."
        }
    }

    $Installed = $false
    for ($Attempt = 1; $Attempt -le 3 -and -not $Installed; $Attempt++) {
        & $Rustup toolchain install stable-x86_64-pc-windows-msvc --profile minimal
        $Installed = $LASTEXITCODE -eq 0
        if (-not $Installed -and $Attempt -lt 3) {
            Start-Sleep -Seconds (3 * $Attempt)
        }
    }
    if (-not $Installed) {
        throw "Rust MSVC toolchain failed after three attempts."
    }
    & $Rustup default stable-x86_64-pc-windows-msvc
    & (Join-Path $CargoHome "bin\rustc.exe") +stable-x86_64-pc-windows-msvc --version
    & (Join-Path $CargoHome "bin\cargo.exe") +stable-x86_64-pc-windows-msvc --version
}

function Install-DotNetToolchain {
    $Installer = Join-Path $ToolchainRoot "dotnet-install.ps1"
    $InstallDirectory = Join-Path $ToolchainRoot "dotnet"
    $DotNet = Join-Path $InstallDirectory "dotnet.exe"
    if (-not (Test-Path -LiteralPath $Installer -PathType Leaf)) {
        Invoke-WebRequest -Uri "https://dot.net/v1/dotnet-install.ps1" -OutFile $Installer
    }
    & $Installer -Channel "8.0" -InstallDir $InstallDirectory -NoPath
    if ($null -ne $LASTEXITCODE -and $LASTEXITCODE -ne 0) {
        throw ".NET SDK bootstrap failed with exit code $LASTEXITCODE."
    }
    if (-not (Test-Path -LiteralPath $DotNet -PathType Leaf)) {
        throw ".NET SDK bootstrap completed without producing dotnet.exe."
    }
    & $DotNet --info
}

if ($Toolchain -in @("Rust", "All")) {
    Install-RustToolchain
}
if ($Toolchain -in @("DotNet", "All")) {
    Install-DotNetToolchain
}
