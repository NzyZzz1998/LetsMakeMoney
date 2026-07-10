param([string]$GodotExe = "")
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "verification_common.ps1")
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$godot = Resolve-LmmGodotExecutable -ExplicitPath $GodotExe
[void](Invoke-LmmGodotVerification -GodotExe $godot -ProjectRoot $projectRoot -ScriptPath "res://scripts/verify_m4.gd" -Label "m4" -SuccessMarker "M4 automated verification passed")
Write-Host "M4 automated verification passed"
