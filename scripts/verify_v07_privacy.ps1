param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$GodotExe = ''
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'verification_common.ps1')
$godot = Resolve-LmmGodotExecutable -ExplicitPath $GodotExe
$isolated = Join-Path $ProjectRoot '.tmp_appdata/v07_privacy'
$oldAppData = $env:APPDATA
$oldLocalAppData = $env:LOCALAPPDATA
try {
    if (Test-Path -LiteralPath $isolated) { Remove-Item -LiteralPath $isolated -Recurse -Force }
    New-Item -ItemType Directory -Path $isolated -Force | Out-Null
    $env:APPDATA = $isolated
    $env:LOCALAPPDATA = $isolated
    [void](Invoke-LmmGodotVerification -GodotExe $godot -ProjectRoot $ProjectRoot -ScriptPath 'res://scripts/verify_v07_privacy.gd' -Label 'v07-privacy' -SuccessMarker 'v0.7 diagnostics privacy verification passed')
} finally {
    $env:APPDATA = $oldAppData
    $env:LOCALAPPDATA = $oldLocalAppData
    Remove-Item -LiteralPath $isolated -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host 'v0.7 privacy verification passed.'
