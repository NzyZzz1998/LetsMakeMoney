param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$GodotExe = $env:LMM_GODOT_EXE
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "verification_common.ps1")

$godot = Resolve-LmmGodotExecutable -ExplicitPath $GodotExe
$output = Invoke-LmmGodotVerification `
    -GodotExe $godot `
    -ProjectRoot $ProjectRoot `
    -ScriptPath "res://scripts/verify_v09_window_experience.gd" `
    -Label "v0.9 window experience verification" `
    -SuccessMarker "V09 window experience verification passed"
Write-Output $output
