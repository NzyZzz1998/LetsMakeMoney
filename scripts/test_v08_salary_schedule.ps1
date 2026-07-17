param([string]$GodotExe = "")
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "verification_common.ps1")
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$godot = Resolve-LmmGodotExecutable -ExplicitPath $GodotExe
[void](Invoke-LmmGodotVerification -GodotExe $godot -ProjectRoot $root -ScriptPath "res://scripts/verify_v08_salary_schedule.gd" -Label "v08-salary-schedule" -SuccessMarker "v0.8 salary schedule verification passed")
Write-Host "v0.8 salary schedule verification passed"
