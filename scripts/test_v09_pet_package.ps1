param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$GodotExe = $env:LMM_GODOT_EXE
)

$ErrorActionPreference = "Stop"
if (-not $GodotExe) { throw "Godot executable is required. Set LMM_GODOT_EXE or pass -GodotExe." }
$output = & $GodotExe --headless --path $ProjectRoot --script res://scripts/verify_v09_pet_package.gd 2>&1 | Out-String
$exitCode = $LASTEXITCODE
Write-Host $output
if ($exitCode -ne 0 -or $output -match "SCRIPT ERROR|Parse Error|Compile Error" -or $output -notmatch "V09 pet package verification passed") {
    throw "v0.9 pet package verification failed with exit code $exitCode"
}
