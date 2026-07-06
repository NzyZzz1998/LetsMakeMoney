param(
    [string]$PackagePath = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")).Path "releases\v0.4\LetsMakeMoney-v0.4-beta-windows-x86_64.zip"),
    [string]$ExtractRoot = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")).Path ".tmp_release\verify_v04_stability"),
    [string]$SmokeAppDataRoot = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")).Path ".tmp_appdata\verify_v04_stability"),
    [int]$DurationSeconds = 60,
    [int]$PollSeconds = 5
)

$ErrorActionPreference = "Stop"

if ($DurationSeconds -lt 10) {
    throw "DurationSeconds should be at least 10 for a meaningful stability smoke test."
}
if ($PollSeconds -lt 1) {
    throw "PollSeconds should be at least 1."
}
if (-not (Test-Path -LiteralPath $PackagePath)) {
    throw "Missing v0.4 package: $PackagePath"
}

if (Test-Path -LiteralPath $ExtractRoot) {
    Remove-Item -LiteralPath $ExtractRoot -Recurse -Force
}
if (Test-Path -LiteralPath $SmokeAppDataRoot) {
    Remove-Item -LiteralPath $SmokeAppDataRoot -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $ExtractRoot | Out-Null
Expand-Archive -LiteralPath $PackagePath -DestinationPath $ExtractRoot -Force

$exe = Join-Path $ExtractRoot "LetsMakeMoney.exe"
if (-not (Test-Path -LiteralPath $exe)) {
    throw "Package is missing LetsMakeMoney.exe"
}
if (-not (Test-Path -LiteralPath (Join-Path $ExtractRoot "letsmakemoney_native.dll"))) {
    throw "Package is missing letsmakemoney_native.dll"
}

$originalAppData = $env:APPDATA
$originalLocalAppData = $env:LOCALAPPDATA
$env:APPDATA = $SmokeAppDataRoot
$env:LOCALAPPDATA = $SmokeAppDataRoot
New-Item -ItemType Directory -Force -Path (Join-Path $env:APPDATA "LetsMakeMoney") | Out-Null
@{
    debug_mode = $false
    minimize_to_tray = $false
    pure_pet_mode = $false
    pet_id = "cat_orange_v2"
    monthly_salary = 0
} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $env:APPDATA "LetsMakeMoney\config.json") -Encoding UTF8

$process = $null
try {
    $process = Start-Process -FilePath $exe -WorkingDirectory $ExtractRoot -WindowStyle Hidden -PassThru
    $deadline = (Get-Date).AddSeconds($DurationSeconds)
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Seconds $PollSeconds
        $process.Refresh()
        if ($process.HasExited) {
            throw "LetsMakeMoney.exe exited during $DurationSeconds second stability smoke with code $($process.ExitCode)"
        }
    }
} finally {
    if ($process -ne $null) {
        $process.Refresh()
        if (-not $process.HasExited) {
            $process.CloseMainWindow() | Out-Null
            Start-Sleep -Seconds 2
            $process.Refresh()
        }
        if (-not $process.HasExited) {
            Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
            $process.WaitForExit(5000) | Out-Null
        }
    }
    $env:APPDATA = $originalAppData
    $env:LOCALAPPDATA = $originalLocalAppData
}

$configPath = Join-Path $SmokeAppDataRoot "LetsMakeMoney\config.json"
if (-not (Test-Path -LiteralPath $configPath)) {
    throw "Stability smoke did not leave a config file at expected path: $configPath"
}

$debugLogPath = Join-Path $SmokeAppDataRoot "LetsMakeMoney\debug.log"
if (-not (Test-Path -LiteralPath $debugLogPath)) {
    throw "Stability smoke did not leave a debug log at expected path: $debugLogPath"
}
$debugLog = Get-Content -LiteralPath $debugLogPath -Raw
$scanMatch = [regex]::Match($debugLog, "PetManager\._ready: scanned pets=(\d+)")
if (-not $scanMatch.Success) {
    throw "Stability smoke debug log is missing PetManager scan count."
}
$scannedPets = [int]$scanMatch.Groups[1].Value
if ($scannedPets -le 0) {
    throw "Stability smoke found no exported pet resources. PetManager scanned pets=$scannedPets"
}
if ($debugLog -match "PetManager\._ready: current_pet=null") {
    throw "Stability smoke selected no current pet."
}

Write-Host "v0.4 stability smoke passed for $DurationSeconds seconds"
