param([string]$InstallerPath,[string]$ExpectedVersion='0.7-beta',[switch]$RequireSignature)
$ErrorActionPreference='Stop'
if(-not $InstallerPath){throw 'Pass -InstallerPath to LetsMakeMoney-Setup.'}
if(-not(Test-Path $InstallerPath)){throw "Installer missing: $InstallerPath"}
$manifestPath=Join-Path (Split-Path $InstallerPath -Parent) 'installer-manifest.json';if(-not(Test-Path $manifestPath)){throw 'installer-manifest.json is missing.'}
$manifest=Get-Content $manifestPath -Raw -Encoding UTF8|ConvertFrom-Json
if($manifest.version -ne $ExpectedVersion){throw "Installer version mismatch: $($manifest.version)"}
if($manifest.installer -ne (Split-Path $InstallerPath -Leaf)){throw 'Installer manifest filename mismatch.'}
$hash=(Get-FileHash $InstallerPath -Algorithm SHA256).Hash.ToLowerInvariant();if($hash -ne $manifest.sha256){throw 'Installer SHA256 mismatch.'}
$signature=Get-AuthenticodeSignature $InstallerPath;if($RequireSignature -and $signature.Status -ne 'Valid'){throw "Installer signature is not valid: $($signature.Status)"}
Write-Host "Installer verification passed: $ExpectedVersion (signature=$($signature.Status))" -ForegroundColor Green
