param([string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot), [string]$GodotExe = "")

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "verification_common.ps1")
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$godot = Resolve-LmmGodotExecutable -ExplicitPath $GodotExe
[void](Invoke-LmmGodotVerification -GodotExe $godot -ProjectRoot $root -ScriptPath "res://scripts/verify_v09_schedule.gd" -Label "v09-schedule" -SuccessMarker "v0.9 schedule verification passed")
Write-Host "v0.9 schedule verification passed"
