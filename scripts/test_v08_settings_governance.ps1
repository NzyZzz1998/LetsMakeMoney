param([string]$GodotExe = "")
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "verification_common.ps1")
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$godot = Resolve-LmmGodotExecutable -ExplicitPath $GodotExe
[void](Invoke-LmmGodotVerification -GodotExe $godot -ProjectRoot $root -ScriptPath "res://scripts/verify_v08_settings_governance.gd" -Label "v08-settings-governance" -SuccessMarker "v0.8 settings governance passed")
Write-Host "v0.8 settings governance passed"
