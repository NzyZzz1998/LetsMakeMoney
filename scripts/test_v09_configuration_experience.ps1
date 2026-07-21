param([string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot), [string]$GodotExe = "")

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "verification_common.ps1")
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$godot = Resolve-LmmGodotExecutable -ExplicitPath $GodotExe
[void](Invoke-LmmGodotVerification -GodotExe $godot -ProjectRoot $root -ScriptPath "res://scripts/verify_v09_configuration_experience.gd" -Label "v09-configuration-experience" -SuccessMarker "v0.9 configuration experience verification passed")
Write-Host "v0.9 configuration experience verification passed"
