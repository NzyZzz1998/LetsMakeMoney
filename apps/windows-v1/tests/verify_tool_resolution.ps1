$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
. (Join-Path $repoRoot "scripts\v10_tools.ps1")

$sandbox = Join-Path $env:TEMP "lmm-tool-resolution-$PID"
$explicitCargo = Join-Path $sandbox "explicit\cargo.exe"
$cargoHome = Join-Path $sandbox "cargo-home"
$cargoHomeExecutable = Join-Path $cargoHome "bin\cargo.exe"
$savedLmmCargo = $env:LMM_CARGO
$savedCargoHome = $env:CARGO_HOME

try {
    New-Item -ItemType Directory -Path (Split-Path -Parent $explicitCargo) -Force | Out-Null
    New-Item -ItemType Directory -Path (Split-Path -Parent $cargoHomeExecutable) -Force | Out-Null
    Set-Content -LiteralPath $explicitCargo -Value "fixture" -Encoding ascii
    Set-Content -LiteralPath $cargoHomeExecutable -Value "fixture" -Encoding ascii

    $env:LMM_CARGO = $explicitCargo
    $env:CARGO_HOME = $cargoHome
    $resolvedExplicit = Get-V10Cargo -RepoRoot $sandbox
    if ($resolvedExplicit -ne [IO.Path]::GetFullPath($explicitCargo)) {
        throw "LMM_CARGO must take precedence over CARGO_HOME."
    }

    Remove-Item Env:LMM_CARGO
    $resolvedCargoHome = Get-V10Cargo -RepoRoot $sandbox
    if ($resolvedCargoHome -ne [IO.Path]::GetFullPath($cargoHomeExecutable)) {
        throw "Get-V10Cargo must resolve CARGO_HOME\\bin\\cargo.exe."
    }
}
finally {
    if ($null -eq $savedLmmCargo) {
        Remove-Item Env:LMM_CARGO -ErrorAction SilentlyContinue
    } else {
        $env:LMM_CARGO = $savedLmmCargo
    }
    if ($null -eq $savedCargoHome) {
        Remove-Item Env:CARGO_HOME -ErrorAction SilentlyContinue
    } else {
        $env:CARGO_HOME = $savedCargoHome
    }
    Remove-Item -LiteralPath $sandbox -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "tool resolution verification: 2/2 passed"
