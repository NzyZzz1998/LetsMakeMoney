param([string]$ProjectRoot=(Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference='Stop'
function Require([bool]$ok,[string]$message){if(-not $ok){throw $message}}
$contractPath=Join-Path $ProjectRoot 'doc/releases/v0.7/window-native-state-contract.md';Require (Test-Path $contractPath) 'Missing window/native state contract'
$contract=Get-Content $contractPath -Raw -Encoding UTF8
foreach($token in @('Single owner','normal mode','pure pet mode','Popup','Modal','available','degraded','unavailable','multi-display','DPI')){Require $contract.Contains($token) "State contract missing: $token"}
$protocolPath=Join-Path $ProjectRoot 'native/windows/native-protocol.json';Require (Test-Path $protocolPath) 'Missing native protocol manifest'
$protocol=Get-Content $protocolPath -Raw -Encoding UTF8|ConvertFrom-Json
Require ($protocol.schema_version -eq 1) 'Native protocol schema mismatch'
Require ($protocol.tray.callback_message -eq 32869) 'Tray callback message mismatch'
$commands=@{};foreach($entry in $protocol.tray.commands){$commands[$entry.name]=[int]$entry.id}
foreach($pair in @{'none'=0;'toggle'=1;'settings'=2;'about'=3;'exit'=4;'left_toggle'=5}.GetEnumerator()){Require ($commands[$pair.Key] -eq $pair.Value) "Tray command mismatch: $($pair.Key)"}
$header=Get-Content (Join-Path $ProjectRoot 'native/windows/src/tray_controller.h') -Raw -Encoding UTF8
foreach($id in 0..5){Require ($header -match "= $id;") "Native header no longer exposes command $id"}
$interface=Get-Content (Join-Path $ProjectRoot 'src/platform/platform_interface.gd') -Raw -Encoding UTF8
foreach($method in @('get_native_health','set_window_visible','set_taskbar_visible','set_mouse_passthrough','poll_tray_command')){Require ($interface.Contains("func $method")) "Platform contract missing: $method"}
Write-Host 'Window/native state contract tests passed' -ForegroundColor Green
