$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$GodotCandidates = @(
    "$env:LMM_GODOT_EXE",
    "$env:LMM_GODOT_EXE",
    "$env:LMM_GODOT_EXE",
    "$env:LMM_GODOT_EXE"
)

$Godot = $GodotCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $Godot) {
    throw "Godot executable not found. Checked: $($GodotCandidates -join ', ')"
}

Push-Location $ProjectRoot
try {
    $GodotUserRoot = Join-Path $ProjectRoot ".godot_user_v05"
    New-Item -ItemType Directory -Force (Join-Path $GodotUserRoot "Godot\app_userdata\LetsMakeMoney\logs") | Out-Null
    $PreviousAppData = $env:APPDATA
    $PreviousLocalAppData = $env:LOCALAPPDATA
    $env:APPDATA = $GodotUserRoot
    $env:LOCALAPPDATA = $GodotUserRoot

    & $Godot --headless --path $ProjectRoot --script "res://scripts/verify_v05.gd"
    if ($LASTEXITCODE -ne 0) {
        throw "v0.5 verification failed with exit code $LASTEXITCODE"
    }
    Write-Host "v0.5 verification passed"
}
finally {
    $env:APPDATA = $PreviousAppData
    $env:LOCALAPPDATA = $PreviousLocalAppData
    Pop-Location
}
