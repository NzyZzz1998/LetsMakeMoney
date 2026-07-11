$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "verification_common.ps1")

function Test-LmmPackage {
    param(
        [Parameter(Mandatory=$true)][string]$PackagePath,
        [Parameter(Mandatory=$true)][string]$ExpectedVersion,
        [Parameter(Mandatory=$true)][string]$ExtractRoot,
        [Parameter(Mandatory=$true)][string]$SmokeAppDataRoot,
        [int]$SmokeSeconds = 5,
        [switch]$RequireLicenses,
        [switch]$SkipSmoke
    )
    if (-not (Test-Path -LiteralPath $PackagePath)) { throw "Missing package: $PackagePath" }
    foreach ($path in @($ExtractRoot,$SmokeAppDataRoot)) { if(Test-Path -LiteralPath $path){Remove-Item -LiteralPath $path -Recurse -Force} }
    New-Item -ItemType Directory -Force -Path $ExtractRoot | Out-Null
    Expand-Archive -LiteralPath $PackagePath -DestinationPath $ExtractRoot -Force
    $required = @('LetsMakeMoney.exe','letsmakemoney_native.dll','app_icon.ico','README.md','release-notes.md','manifest.json','checksums.txt')
    if ($RequireLicenses) { $required += @('LICENSES/PROJECT_LICENSE.txt','LICENSES/ASSETS_LICENSE.md','LICENSES/THIRD_PARTY_NOTICES.md') }
    foreach($name in $required){ if(-not(Test-Path -LiteralPath (Join-Path $ExtractRoot $name))){throw "Package missing $name"} }
    $unexpected = Get-ChildItem -LiteralPath $ExtractRoot -Recurse -File | Where-Object { $_.Extension -in @('.ps1','.gd','.pdb') }
    if($unexpected){throw "Unexpected binary or internal file: $($unexpected.FullName -join ', ')"}
    $manifest = Get-Content -LiteralPath (Join-Path $ExtractRoot 'manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    if($manifest.version -ne $ExpectedVersion){throw "Package version mismatch: $($manifest.version)"}
    if($manifest.package_name -ne "LetsMakeMoney-v$ExpectedVersion-windows-x86_64"){throw "Package name mismatch"}
    foreach($entry in $manifest.files){$path=Join-Path $ExtractRoot $entry.path;if(-not(Test-Path -LiteralPath $path)){throw "Manifest file missing: $($entry.path)"};$hash=(Get-FileHash $path -Algorithm SHA256).Hash.ToLowerInvariant();if($hash -ne $entry.sha256){throw "Manifest hash mismatch: $($entry.path)"}}
    $registered = @($manifest.files | ForEach-Object { $_.path.Replace('\','/').ToLowerInvariant() }) + @('manifest.json','checksums.txt')
    $extraBinaries = Get-ChildItem -LiteralPath $ExtractRoot -Recurse -File | Where-Object {
        $_.Extension -in @('.exe','.dll','.ttf','.otf') -and
        -not ($registered -contains $_.FullName.Substring((Resolve-Path $ExtractRoot).Path.TrimEnd('\').Length + 1).Replace('\','/').ToLowerInvariant())
    }
    if($extraBinaries){throw "Unexpected binary: $($extraBinaries.FullName -join ', ')"}
    foreach($line in Get-Content -LiteralPath (Join-Path $ExtractRoot 'checksums.txt') -Encoding UTF8){if(-not $line.Trim()){continue};$parts=$line -split '\s+',2;$path=Join-Path $ExtractRoot $parts[1].Trim();if(-not(Test-Path $path)){throw "Checksum entry missing: $($parts[1])"};if((Get-FileHash $path -Algorithm SHA256).Hash.ToLowerInvariant() -ne $parts[0].ToLowerInvariant()){throw "Checksum mismatch: $($parts[1])"}}
    if (-not $SkipSmoke) {
      $process=$null
      Invoke-LmmWithIsolatedAppData -Root $SmokeAppDataRoot -ScriptBlock {
        $configDir=Join-Path $env:APPDATA 'LetsMakeMoney';New-Item -ItemType Directory -Force -Path $configDir|Out-Null
        @{monthly_salary=12000;minimize_to_tray=$false;pure_pet_mode=$false;debug_mode=$false}|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $configDir 'config.json') -Encoding UTF8
        try{$process=Start-Process -FilePath (Join-Path $ExtractRoot 'LetsMakeMoney.exe') -WorkingDirectory $ExtractRoot -WindowStyle Hidden -PassThru;Start-Sleep -Seconds $SmokeSeconds;if($process.HasExited){throw "Packaged exe exited with code $($process.ExitCode)"}}finally{if($process -and -not $process.HasExited){Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue;$process.WaitForExit(5000)|Out-Null}}
      }
    }
    Write-Host "Package verification passed: $ExpectedVersion" -ForegroundColor Green
}
