param([string]$GodotExe = "")
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "verification_common.ps1")
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$godot = Resolve-LmmGodotExecutable -ExplicitPath $GodotExe
[void](Invoke-LmmGodotVerification -GodotExe $godot -ProjectRoot $projectRoot -ScriptPath "res://scripts/verify_v05.gd" -Label "v05" -SuccessMarker "v0.5 verification passed")
Write-Host "v0.5 verification passed"
