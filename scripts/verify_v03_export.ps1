param(
    [string]$ExePath = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")).Path "build\LetsMakeMoney.exe"),
    [string]$SmokeAppDataRoot = ""
)

$ErrorActionPreference = "Stop"

$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$GDExtension = Join-Path $ProjectRoot "native\windows\letsmakemoney_native.gdextension"
$Dll = Join-Path $ProjectRoot "native\windows\bin\win64\letsmakemoney_native.dll"
if (-not $SmokeAppDataRoot) {
    $SmokeAppDataRoot = Join-Path $ProjectRoot ".tmp_appdata\verify_v03_export"
}
$ConfigDir = Join-Path $env:APPDATA "LetsMakeMoney"
$ConfigPath = Join-Path $ConfigDir "config.json"
$ConfigBackup = $null

function Set-JsonProperty {
    param(
        [Parameter(Mandatory=$true)]$Object,
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)]$Value
    )
    if ($Object.PSObject.Properties.Name -contains $Name) {
        $Object.$Name = $Value
    } else {
        $Object | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
    }
}

function Set-SmokeConfig {
    New-Item -ItemType Directory -Force -Path $ConfigDir | Out-Null
    if (Test-Path -LiteralPath $ConfigPath) {
        $script:ConfigBackup = Join-Path $ConfigDir ("config.verify-v03-export-backup-" + (Get-Date -Format "yyyyMMddHHmmss") + ".json")
        Copy-Item -LiteralPath $ConfigPath -Destination $script:ConfigBackup -Force
        $data = Get-Content -Raw -LiteralPath $ConfigPath | ConvertFrom-Json
    } else {
        $data = New-Object PSObject
    }
    Set-JsonProperty $data "minimize_to_tray" $false
    Set-JsonProperty $data "pure_pet_mode" $false
    $data | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $ConfigPath -Encoding UTF8
}

function Restore-SmokeConfig {
    if ($script:ConfigBackup -and (Test-Path -LiteralPath $script:ConfigBackup)) {
        Copy-Item -LiteralPath $script:ConfigBackup -Destination $ConfigPath -Force
        Remove-Item -LiteralPath $script:ConfigBackup -ErrorAction SilentlyContinue
    }
}

if (-not (Test-Path -LiteralPath $ExePath)) {
    throw "Missing exported exe: $ExePath"
}
if (-not (Test-Path -LiteralPath $GDExtension)) {
    throw "Missing gdextension file: $GDExtension"
}
if (-not (Test-Path -LiteralPath $Dll)) {
    throw "Missing native dll: $Dll"
}

$OriginalAppData = $env:APPDATA
$env:APPDATA = $SmokeAppDataRoot
$ConfigDir = Join-Path $env:APPDATA "LetsMakeMoney"
$ConfigPath = Join-Path $ConfigDir "config.json"

Set-SmokeConfig
try {
    $process = Start-Process -FilePath $ExePath -PassThru
    Start-Sleep -Seconds 3
    if ($process.HasExited) {
        throw "LetsMakeMoney.exe exited during smoke test with code $($process.ExitCode)"
    }

    $process.CloseMainWindow() | Out-Null
    Start-Sleep -Seconds 2
    $forceStopped = $false
    if (-not $process.HasExited) {
        $forceStopped = $true
        Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
        $process.WaitForExit(5000) | Out-Null
    }
    if (-not $forceStopped -and $process.HasExited -and $process.ExitCode -ne 0 -and $process.ExitCode -ne $null) {
        throw "LetsMakeMoney.exe exited with code $($process.ExitCode)"
    }
} finally {
    Restore-SmokeConfig
    $env:APPDATA = $OriginalAppData
}

Write-Host "v0.3 export smoke passed"
