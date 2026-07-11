param([string]$ProjectRoot=(Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference='Stop'
$settings=Get-Content -LiteralPath (Join-Path $ProjectRoot 'src/scenes/settings/settings_dialog.gd') -Raw -Encoding UTF8
if($settings -notmatch 'func _build_compact_ui\(\)'){throw 'Compact Settings UI entry is missing.'}
if($settings -match 'func _build_ui\(\)'){throw 'Legacy Settings _build_ui path is still present.'}
foreach($legacy in @('func _add_card_grid','func _add_status_card','func _add_info_card','func get_v02_control_names')){if($settings.Contains($legacy)){throw "Legacy Settings helper is still present: $legacy"}}
foreach($wrapper in @('package_v04.ps1','package_v05.ps1','package_v06.ps1')){if(-not(Get-Content (Join-Path $ProjectRoot "scripts/$wrapper") -Raw -Encoding UTF8).Contains('package_common.ps1')){throw "$wrapper is not a common-core wrapper"}}
Write-Host 'Settings slimming contract passed' -ForegroundColor Green
