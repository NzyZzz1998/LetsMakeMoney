param([string]$ProjectRoot=(Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference='Stop'
function Need([bool]$ok,[string]$message){if(-not $ok){throw $message}}
$config=Get-Content (Join-Path $ProjectRoot 'src/autoload/config.gd') -Raw -Encoding UTF8
foreach($token in @('update_channel','check_updates_on_start','beta')){Need $config.Contains($token) "Config update contract missing: $token"}
$service=Get-Content (Join-Path $ProjectRoot 'src/utils/update_service.gd') -Raw -Encoding UTF8
foreach($token in @('api.github.com/repos/NzyZzz1998/LetsMakeMoney/releases','User-Agent','download_update','cancel_download','SHA256','update_check_failed','update_download_failed','update_download_verified','redact_url','validate_download_asset','insufficient_disk_space','verify_authenticode','open_releases_page')){Need $service.Contains($token) "Update service contract missing: $token"}
$settings=Get-Content (Join-Path $ProjectRoot 'src/scenes/settings/settings_dialog.gd') -Raw -Encoding UTF8
foreach($token in @('update_channel_option','check_updates_toggle','check_update_button','_on_check_update_pressed','_on_update_status_changed','UpdateInstallConfirmDialog','_on_update_download_ready')){Need $settings.Contains($token) "Settings update UI missing: $token"}
$main=Get-Content (Join-Path $ProjectRoot 'src/scenes/main/main.gd') -Raw -Encoding UTF8
foreach($token in @('prepare_update_exit','update_installer_started','shutdown_tray','create_update_backup','_check_updates_after_startup')){Need $main.Contains($token) "Update exit contract missing: $token"}
$bridge=Get-Content (Join-Path $ProjectRoot 'native/windows/src/lmm_native_bridge.cpp') -Raw -Encoding UTF8
foreach($token in @('WinVerifyTrust','CryptQueryObject','expected_publisher')){Need $bridge.Contains($token) "Native signature contract missing: $token"}
Write-Host 'Update integration contract passed' -ForegroundColor Green
