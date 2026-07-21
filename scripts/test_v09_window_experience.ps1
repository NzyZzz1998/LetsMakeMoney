param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$GodotExe = $env:LMM_GODOT_EXE
)

$ErrorActionPreference = "Stop"
if ([string]::IsNullOrWhiteSpace($GodotExe) -or -not (Test-Path -LiteralPath $GodotExe)) {
    throw "Godot executable not found. Set LMM_GODOT_EXE or pass -GodotExe."
}

& $GodotExe --headless --path $ProjectRoot --script res://scripts/verify_v09_window_experience.gd
if ($LASTEXITCODE -ne 0) {
    throw "v0.9 window experience verification failed with exit code $LASTEXITCODE"
}
