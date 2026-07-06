param(
    [string]$GodotExe = "$env:LMM_GODOT_EXE",
    [string]$ProjectPath = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [string]$VerifyAppDataRoot = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")).Path ".tmp_appdata\verify_v02")
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $GodotExe)) {
    throw "Godot executable not found: $GodotExe"
}

$logFile = Join-Path $ProjectPath ".tmp_verify_v02.log"

$originalAppData = $env:APPDATA
$originalLocalAppData = $env:LOCALAPPDATA
try {
    if (Test-Path -LiteralPath $VerifyAppDataRoot) {
        Remove-Item -LiteralPath $VerifyAppDataRoot -Recurse -Force
    }
    New-Item -ItemType Directory -Force -Path $VerifyAppDataRoot | Out-Null
    $env:APPDATA = $VerifyAppDataRoot
    $env:LOCALAPPDATA = $VerifyAppDataRoot

    & $GodotExe --headless --log-file $logFile --path $ProjectPath --script (Join-Path $ProjectPath "scripts\verify_v02.gd")
    if ($LASTEXITCODE -ne 0) {
        throw "v0.2 verification failed with exit code $LASTEXITCODE"
    }
} finally {
    $env:APPDATA = $originalAppData
    $env:LOCALAPPDATA = $originalLocalAppData
}

Remove-Item -LiteralPath $logFile -ErrorAction SilentlyContinue
Write-Host "v0.2 verification passed"
