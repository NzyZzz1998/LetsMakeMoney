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
$sharedHeaderPath=Join-Path $ProjectRoot 'native/windows/src/native_protocol.h';Require (Test-Path $sharedHeaderPath) 'Missing shared native protocol header'
$sharedHeader=Get-Content $sharedHeaderPath -Raw -Encoding UTF8
Require ($header.Contains('#include "native_protocol.h"')) 'Tray controller must consume shared native protocol constants'
foreach($id in 0..5){Require ($sharedHeader -match "= $id;") "Native protocol no longer exposes command $id"}
foreach($name in @('COMMAND_NONE','COMMAND_TOGGLE','COMMAND_SETTINGS','COMMAND_ABOUT','COMMAND_EXIT','COMMAND_LEFT_TOGGLE','TRAY_CALLBACK_MESSAGE')){Require $sharedHeader.Contains($name) "Shared native protocol missing: $name"}
$interface=Get-Content (Join-Path $ProjectRoot 'src/platform/platform_interface.gd') -Raw -Encoding UTF8
foreach($method in @('get_native_health','set_window_visible','set_taskbar_visible','invalidate_taskbar_visibility_cache','set_mouse_passthrough','poll_tray_command')){Require ($interface.Contains("func $method")) "Platform contract missing: $method"}
$runtimeContractPath=Join-Path $ProjectRoot 'doc/releases/v0.8/window-runtime-state-contract.md';Require (Test-Path $runtimeContractPath) 'Missing v0.8 window runtime state contract'
$runtimeContract=Get-Content $runtimeContractPath -Raw -Encoding UTF8
foreach($token in @('WindowRuntimeState','OverlayLifecycle','Single cache owner','Platform cache invalidation','PetWindowGeometry','Behavior matrix','Geometry contract')){Require $runtimeContract.Contains($token) "Runtime state contract missing: $token"}
foreach($source in @('src/utils/window_runtime_state.gd','src/utils/pet_window_geometry.gd','src/utils/overlay_lifecycle.gd','src/utils/context_menu_builder.gd')){Require (Test-Path (Join-Path $ProjectRoot $source)) "Missing C4 source: $source"}
$main=Get-Content (Join-Path $ProjectRoot 'src/scenes/main/main.gd') -Raw -Encoding UTF8
Require (-not $main.Contains('_last_taskbar_visible')) 'Main must not own a second taskbar visibility cache'
$windowsPlatform=Get-Content (Join-Path $ProjectRoot 'src/platform/windows_platform.gd') -Raw -Encoding UTF8
Require ($windowsPlatform.Contains('func invalidate_taskbar_visibility_cache')) 'WindowsPlatform must expose cache invalidation through the platform contract'
Write-Host 'Window/native state contract tests passed' -ForegroundColor Green
