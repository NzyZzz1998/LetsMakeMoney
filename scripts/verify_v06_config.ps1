param([string]$GodotExe = "")
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "verification_common.ps1")
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$godot = Resolve-LmmGodotExecutable -ExplicitPath $GodotExe
$oldAppData = $env:APPDATA
$isolatedAppData = Join-Path $projectRoot ".tmp_appdata\verify_v06_config"
if (Test-Path -LiteralPath $isolatedAppData) { Remove-Item -LiteralPath $isolatedAppData -Recurse -Force }
New-Item -ItemType Directory -Force -Path $isolatedAppData | Out-Null
try {
    $env:APPDATA = $isolatedAppData
    [void](Invoke-LmmGodotVerification -GodotExe $godot -ProjectRoot $projectRoot -ScriptPath "res://scripts/verify_v06.gd" -Label "v06-config" -SuccessMarker "v0.6 verification passed")
} finally {
    $env:APPDATA = $oldAppData
}
Write-Host "v0.6 config verification passed"
