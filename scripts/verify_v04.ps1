param([string]$GodotExe = "")
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "verification_common.ps1")
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$godot = Resolve-LmmGodotExecutable -ExplicitPath $GodotExe
[void](Invoke-LmmGodotVerification -GodotExe $godot -ProjectRoot $projectRoot -ScriptPath "res://scripts/verify_v04.gd" -Label "v04" -SuccessMarker "v0.4 verification passed")
Write-Host "v0.4 verification passed"
