param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [switch]$StaticOnly
)

$ErrorActionPreference = "Stop"

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) {
        throw $Message
    }
}

function Read-Utf8 {
    param([string]$RelativePath)
    $path = Join-Path $ProjectRoot $RelativePath
    Assert-True (Test-Path -LiteralPath $path) "Missing required file: $RelativePath"
    return Get-Content -LiteralPath $path -Raw -Encoding UTF8
}

$project = Read-Utf8 "project.godot"
Assert-True ($project -match '(?m)^config/version="0\.6-beta"$') "project.godot must define application/config/version=0.6-beta"

$versionHelper = Read-Utf8 "src/utils/app_version.gd"
Assert-True ($versionHelper.Contains('application/config/version')) "Godot version helper must read application/config/version"
Assert-True ($versionHelper.Contains('ProjectSettings.get_setting')) "Godot version helper must read from ProjectSettings"

$psVersionHelper = Read-Utf8 "scripts/project_version.ps1"
Assert-True ($psVersionHelper.Contains('config/version')) "PowerShell version helper must read config/version from project.godot"

$about = Read-Utf8 "src/autoload/drag_resize_system.gd"
Assert-True (-not $about.Contains('LetsMakeMoney v0.4 Beta')) "About dialog must not hard-code v0.4 Beta"
Assert-True ($about.Contains('AppVersionScript.get_display_version')) "About dialog must use the shared version helper"

$main = Read-Utf8 "src/scenes/main/main.gd"
Assert-True ($main.Contains('app_started: version=%s')) "Main startup log must include the shared app version"

$platform = Read-Utf8 "src/autoload/platform.gd"
Assert-True ($platform.Contains('func write_info_log')) "Platform must expose an info log API"
Assert-True ($platform.Contains('func write_error_log')) "Platform must expose an error log API"
Assert-True ($platform.Contains('LOG_MAX_BYTES')) "Platform must define a bounded log size"
Assert-True ($platform.Contains('debug.log.1')) "Platform must retain a single rotated log backup"

$pet = Read-Utf8 "src/scenes/pet/pet.gd"
Assert-True ($pet.Contains('_should_capture_interaction_snapshots')) "Interaction screenshots must be guarded"
Assert-True ($pet.Contains('LETSMAKEMONEY_CAPTURE_INTERACTION_SCREENSHOTS')) "Isolated verification must be able to enable screenshots"

$diagnostics = Read-Utf8 "src/utils/diagnostics_service.gd"
foreach ($token in @(
    'build_summary',
    'open_app_data_directory',
    'copy_summary_to_clipboard',
    'classify_clipboard_write_result',
    'CLIPBOARD_READBACK_ATTEMPTS',
    'verification_uncertain',
    'debug.log.1',
    'clipboard_get',
    'MAX_LOG_SCAN_BYTES'
)) {
    Assert-True ($diagnostics.Contains($token)) "Diagnostics service missing contract: $token"
}
$settings = Read-Utf8 "src/scenes/settings/settings_dialog.gd"
Assert-True ($settings.Contains('DiagnosticsServiceScript')) "Settings must load the diagnostics service"
Assert-True ($settings.Contains('_on_open_app_data_pressed')) "Settings must expose the open data directory action"
Assert-True ($settings.Contains('_on_copy_diagnostics_pressed')) "Settings must expose the copy diagnostics action"
Assert-True ($settings.Contains('FEEDBACK_HIDE_SECONDS')) "Settings feedback must auto-hide"
Assert-True ($settings.Contains('diagnostics_copy_verification_uncertain')) "Settings must log uncertain clipboard verification without reporting a false failure"
foreach ($token in @('_capture_external_state', '_restore_external_state', 'settings_transaction_rollback')) {
    Assert-True ($settings.Contains($token)) "Settings transaction missing contract: $token"
}

$config = Read-Utf8 "src/autoload/config.gd"
foreach ($token in @('CONFIG_TEMP_SUFFIX', 'CONFIG_PREVIOUS_SUFFIX', '_preserve_invalid_config', 'consume_recovery_notice', 'config_recovered')) {
    Assert-True ($config.Contains($token)) "Config persistence missing contract: $token"
}

$wizard = Read-Utf8 "src/scenes/wizard/wizard_dialog.gd"
foreach ($token in @('_entry_config_snapshot', '_entry_pet_id', '_restore_entry_state', 'wizard_state_restored')) {
    Assert-True ($wizard.Contains($token)) "Wizard transaction missing contract: $token"
}

$verificationCommon = Read-Utf8 "scripts/verification_common.ps1"
Assert-True ($verificationCommon.Contains('Invoke-LmmGodotVerification')) "Verification scripts must share a trusted Godot runner"
Assert-True ($verificationCommon.Contains('BlockingPatterns')) "Trusted runner must scan blocking output"

foreach ($wrapper in @('scripts/verify_v04.ps1', 'scripts/verify_v05.ps1', 'scripts/verify_m4.ps1', 'scripts/verify_m5.ps1')) {
    $wrapperText = Read-Utf8 $wrapper
    Assert-True ($wrapperText.Contains('verification_common.ps1')) "$wrapper must use verification_common.ps1"
}

$trayVerifier = Read-Utf8 "scripts/verify_v06_tray.ps1"
foreach ($token in @('LetsMakeMoneyTrayMessageWindow', 'PostMessage', 'pure_pet_mode', '10', 'try', 'finally')) {
    Assert-True ($trayVerifier.Contains($token)) "Tray verifier missing contract: $token"
}
$nativeTray = Read-Utf8 "native/windows/src/tray_controller.cpp"
Assert-True ($nativeTray.Contains('COMMAND_SETTINGS') -and $nativeTray.Contains('COMMAND_ABOUT') -and $nativeTray.Contains('COMMAND_EXIT')) "Native tray menu must retain lifecycle entries"
Assert-True (-not $nativeTray.Contains('COMMAND_WIZARD')) "Native tray menu must not expose Wizard"

foreach ($packagingScript in @('scripts/package_v06.ps1', 'scripts/verify_v06_package.ps1')) {
    $packagingText = Read-Utf8 $packagingScript
    Assert-True ($packagingText.Contains('project_version.ps1')) "$packagingScript must use the shared project version"
}

foreach ($relative in @(
    'doc/releases/v0.6/README.md',
    'doc/releases/v0.6/status.md',
    'doc/releases/v0.6/verification.md',
    'doc/releases/v0.6/release-checklist.md'
)) {
    [void](Read-Utf8 $relative)
}

if (-not $StaticOnly) {
    $gdScript = Join-Path $ProjectRoot "scripts\verify_v06.gd"
    Assert-True (Test-Path -LiteralPath $gdScript) "Missing scripts/verify_v06.gd"
    . (Join-Path $ProjectRoot "scripts\verification_common.ps1")
    $godot = Resolve-LmmGodotExecutable
    $oldAppData = $env:APPDATA
    $oldCapture = $env:LETSMAKEMONEY_CAPTURE_INTERACTION_SCREENSHOTS
    $isolatedAppData = Join-Path $ProjectRoot ".tmp_appdata\verify_v06"
    if (Test-Path -LiteralPath $isolatedAppData) { Remove-Item -LiteralPath $isolatedAppData -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $isolatedAppData | Out-Null
    try {
        $env:APPDATA = $isolatedAppData
        $env:LETSMAKEMONEY_CAPTURE_INTERACTION_SCREENSHOTS = "1"
        [void](Invoke-LmmGodotVerification -GodotExe $godot -ProjectRoot $ProjectRoot -ScriptPath "res://scripts/verify_v06.gd" -Label "v06" -SuccessMarker "v0.6 verification passed")
    } finally {
        $env:APPDATA = $oldAppData
        $env:LETSMAKEMONEY_CAPTURE_INTERACTION_SCREENSHOTS = $oldCapture
    }
}

Write-Host "v0.6 verification passed" -ForegroundColor Green
