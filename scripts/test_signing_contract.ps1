param([string]$ProjectRoot=(Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference='Stop'
function Need([bool]$ok,[string]$message){if(-not $ok){throw $message}}
$sign=Get-Content (Join-Path $ProjectRoot 'scripts/sign_windows.ps1') -Raw -Encoding UTF8
foreach($token in @('LMM_SIGN_CERT_PATH','LMM_SIGN_CERT_PASSWORD','LMM_SIGN_TIMESTAMP_URL','Set-AuthenticodeSignature','Get-AuthenticodeSignature','Valid','Publisher')){Need $sign.Contains($token) "Signing contract missing: $token"}
Need (-not $sign.Contains('password=')) 'Signing script must not embed a password'
$iss=Get-Content (Join-Path $ProjectRoot 'installer/LetsMakeMoney.iss') -Raw -Encoding UTF8
foreach($token in @('InitializeUninstall','DeleteUserDataCheck','CurUninstallStepChanged','DelTree','mbConfirmation')){Need $iss.Contains($token) "Uninstall data contract missing: $token"}
Need (-not $iss.Contains('Tasks: deleteuserdata')) 'User data deletion must be chosen during uninstall, not install'
Write-Host 'Signing and uninstall contracts passed' -ForegroundColor Green
