param([string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference='Stop'
. (Join-Path $ProjectRoot 'scripts/package_common.ps1')
. (Join-Path $ProjectRoot 'scripts/verify_package_common.ps1')

$root=Join-Path ([IO.Path]::GetTempPath()) ('lmm-package-common-'+[guid]::NewGuid().ToString('N'))
$fixture=Join-Path $root 'project';$release=Join-Path $fixture 'release';New-Item -ItemType Directory -Force -Path $fixture,$release|Out-Null
try {
  foreach($path in @('build/LetsMakeMoney.exe','build/letsmakemoney_native.dll','icons/app_icon.ico','README.md','notes.md')){$full=Join-Path $fixture $path;New-Item -ItemType Directory -Force -Path (Split-Path $full -Parent)|Out-Null;Set-Content -LiteralPath $full -Value $path -Encoding UTF8}
  $zip=New-LmmPackage -ProjectRoot $fixture -Version '9.9-test' -ReleaseDirectory 'release' -ReleaseNotes 'notes.md'
  Test-LmmPackage -PackagePath $zip -ExpectedVersion '9.9-test' -ExtractRoot (Join-Path $root 'ok') -SmokeAppDataRoot (Join-Path $root 'appdata') -SkipSmoke
  $wrong=$false;try{Test-LmmPackage -PackagePath $zip -ExpectedVersion '9.8-test' -ExtractRoot (Join-Path $root 'wrong') -SmokeAppDataRoot (Join-Path $root 'appdata2') -SkipSmoke}catch{$wrong=$true};if(-not $wrong){throw 'Wrong version package was accepted'}
  $unpack=Join-Path $root 'mutate';Expand-Archive $zip $unpack;Set-Content (Join-Path $unpack 'unknown.dll') 'x';$badZip=Join-Path $root 'bad.zip';Compress-Archive (Join-Path $unpack '*') $badZip
  $unknown=$false;try{Test-LmmPackage -PackagePath $badZip -ExpectedVersion '9.9-test' -ExtractRoot (Join-Path $root 'unknown') -SmokeAppDataRoot (Join-Path $root 'appdata3') -SkipSmoke}catch{$unknown=$true};if(-not $unknown){throw 'Unregistered DLL was accepted'}
  Write-Host 'Package common tests passed' -ForegroundColor Green
} finally {if(Test-Path $root){Remove-Item $root -Recurse -Force}}
