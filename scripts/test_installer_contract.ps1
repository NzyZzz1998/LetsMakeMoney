param([string]$ProjectRoot=(Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference='Stop'
function Need([bool]$ok,[string]$message){if(-not $ok){throw $message}}
$issPath=Join-Path $ProjectRoot 'installer/LetsMakeMoney.iss';Need (Test-Path $issPath) 'Missing Inno Setup script'
$iss=Get-Content $issPath -Raw -Encoding UTF8
foreach($token in @('PrivilegesRequired=lowest','{localappdata}\Programs\LetsMakeMoney','ArchitecturesAllowed=x64compatible','LicenseFile=','AppMutex=LetsMakeMoneySingleton','CloseApplications=yes','RestartApplications=no','Uninstallable=yes','DeleteUserDataCheck','{userappdata}\LetsMakeMoney','PROJECT_LICENSE.txt','ASSETS_LICENSE.md','THIRD_PARTY_NOTICES.md')){Need $iss.Contains($token) "Installer contract missing: $token"}
Need ($iss -match 'Flags: unchecked') 'Desktop shortcut must be optional'
Need ($iss -match 'DeleteUserDataCheck.Checked := False') 'User data deletion must default to off during uninstall'
$build=Get-Content (Join-Path $ProjectRoot 'scripts/build_installer.ps1') -Raw -Encoding UTF8
foreach($token in @('6.7.3','ISCC.exe','installer-manifest.json','Get-AuthenticodeSignature','RequireSignature')){Need $build.Contains($token) "Installer build contract missing: $token"}
$verify=Get-Content (Join-Path $ProjectRoot 'scripts/verify_installer.ps1') -Raw -Encoding UTF8
foreach($token in @('ExpectedVersion','installer-manifest.json','RequireSignature','LetsMakeMoney-Setup')){Need $verify.Contains($token) "Installer verification contract missing: $token"}
Write-Host 'Installer contract tests passed' -ForegroundColor Green
