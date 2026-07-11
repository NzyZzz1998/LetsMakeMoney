param(
 [string]$ProjectRoot=(Split-Path -Parent $PSScriptRoot),
 [string]$SourceDir='',
 [string]$Version='0.7-beta',
 [string]$OutputDir='',
 [string]$IsccPath='',
 [switch]$RequireSignature
)
$ErrorActionPreference='Stop'
$requiredInnoVersion='6.7.3'
if(-not $SourceDir){$SourceDir=Join-Path $ProjectRoot "releases/v0.7/LetsMakeMoney-v$Version-windows-x86_64"}
if(-not $OutputDir){$OutputDir=Join-Path $ProjectRoot 'releases/v0.7/installer'}
if(-not $IsccPath){$candidates=@("$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe","${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe","$env:ProgramFiles\Inno Setup 6\ISCC.exe");$IsccPath=$candidates|Where-Object{Test-Path $_}|Select-Object -First 1}
if(-not $IsccPath -or -not(Test-Path $IsccPath)){throw "Inno Setup $requiredInnoVersion ISCC.exe not found."}
foreach($name in @('LetsMakeMoney.exe','letsmakemoney_native.dll','app_icon.ico','README.md','release-notes.md','LICENSES/PROJECT_LICENSE.txt','LICENSES/ASSETS_LICENSE.md','LICENSES/THIRD_PARTY_NOTICES.md')){if(-not(Test-Path (Join-Path $SourceDir $name))){throw "Installer payload missing: $name"}}
New-Item -ItemType Directory -Force -Path $OutputDir|Out-Null
$iss=Join-Path $ProjectRoot 'installer/LetsMakeMoney.iss'
& $IsccPath "/DAppVersion=$Version" "/DSourceDir=$SourceDir" "/DOutputDir=$OutputDir" $iss
if($LASTEXITCODE -ne 0){throw "Inno Setup compilation failed: $LASTEXITCODE"}
$setup=Join-Path $OutputDir "LetsMakeMoney-Setup-v$Version-windows-x86_64.exe";if(-not(Test-Path $setup)){throw "Installer output missing: $setup"}
$signature=Get-AuthenticodeSignature $setup
if($RequireSignature -and $signature.Status -ne 'Valid'){throw "Installer signature gate failed: $($signature.Status)"}
$manifest=[ordered]@{schema_version=1;version=$Version;inno_setup_version=$requiredInnoVersion;installer=(Split-Path $setup -Leaf);size=(Get-Item $setup).Length;sha256=(Get-FileHash $setup -Algorithm SHA256).Hash.ToLowerInvariant();signature_status=[string]$signature.Status;public_release_eligible=($signature.Status -eq 'Valid');generated_at=(Get-Date).ToUniversalTime().ToString('o')}
$manifest|ConvertTo-Json -Depth 6|Set-Content -LiteralPath (Join-Path $OutputDir 'installer-manifest.json') -Encoding UTF8
Write-Host "Installer built: $setup (signature=$($signature.Status))"
Write-Output $setup
