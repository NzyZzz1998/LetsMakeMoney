param(
    [string]$GodotExe = "$env:LMM_GODOT_EXE",
    [string]$ProjectPath = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $GodotExe)) {
    throw "Godot executable not found: $GodotExe"
}

$logFile = Join-Path $ProjectPath ".tmp_verify_v02.log"

& $GodotExe --headless --log-file $logFile --path $ProjectPath --script (Join-Path $ProjectPath "scripts\verify_v02.gd")
if ($LASTEXITCODE -ne 0) {
    throw "v0.2 verification failed with exit code $LASTEXITCODE"
}

Remove-Item -LiteralPath $logFile -ErrorAction SilentlyContinue
Write-Host "v0.2 verification passed"
