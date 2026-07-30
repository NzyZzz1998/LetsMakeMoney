function Resolve-V10Executable {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [string[]]$FallbackPaths = @()
    )

    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    foreach ($path in $FallbackPaths) {
        if ($path -and (Test-Path -LiteralPath $path -PathType Leaf)) {
            return [IO.Path]::GetFullPath($path)
        }
    }

    throw "Required tool '$Name' was not found. Install it or add it to PATH."
}

function Get-V10Python {
    $fallback = if ($env:USERPROFILE) {
        Join-Path $env:USERPROFILE ".cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"
    } else {
        ""
    }
    return Resolve-V10Executable -Name "python" -FallbackPaths @($fallback)
}

function Get-V10Node {
    $fallback = if ($env:USERPROFILE) {
        Join-Path $env:USERPROFILE ".cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe"
    } else {
        ""
    }
    return Resolve-V10Executable -Name "node" -FallbackPaths @($fallback)
}

function Get-V10Cargo {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot
    )

    $localRustup = Join-Path $RepoRoot "spikes\v1.0-ui\.toolchains\rustup"
    $localCargoHome = Join-Path $RepoRoot "spikes\v1.0-ui\.toolchains\cargo"
    $localCargo = Join-Path $localCargoHome "bin\cargo.exe"
    if (Test-Path -LiteralPath $localCargo -PathType Leaf) {
        $env:RUSTUP_HOME = $localRustup
        $env:CARGO_HOME = $localCargoHome
        return $localCargo
    }

    if ($env:LMM_CARGO -and (Test-Path -LiteralPath $env:LMM_CARGO -PathType Leaf)) {
        if ($env:LMM_CARGO_HOME) {
            $env:CARGO_HOME = [IO.Path]::GetFullPath($env:LMM_CARGO_HOME)
        }
        if ($env:LMM_RUSTUP_HOME) {
            $env:RUSTUP_HOME = [IO.Path]::GetFullPath($env:LMM_RUSTUP_HOME)
        }
        return [IO.Path]::GetFullPath($env:LMM_CARGO)
    }

    $configuredCargoHome = if ($env:LMM_CARGO_HOME) {
        $env:LMM_CARGO_HOME
    } else {
        $env:CARGO_HOME
    }
    $cargoHomeExecutable = if ($configuredCargoHome) {
        Join-Path $configuredCargoHome "bin\cargo.exe"
    } else {
        ""
    }
    $userCargo = if ($env:USERPROFILE) {
        Join-Path $env:USERPROFILE ".cargo\bin\cargo.exe"
    } else {
        ""
    }

    return Resolve-V10Executable -Name "cargo" -FallbackPaths @(
        $cargoHomeExecutable,
        $userCargo
    )
}
