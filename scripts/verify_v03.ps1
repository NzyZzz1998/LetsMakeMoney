param(
    [string]$GodotExe = "",
    [string]$ProjectPath = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$candidates = @()
if ($GodotExe -ne "") {
    $candidates += $GodotExe
}
$candidates += "$env:LMM_GODOT_EXE"

$resolvedGodot = $null
foreach ($candidate in $candidates) {
    if ([string]::IsNullOrWhiteSpace($candidate)) { continue }
    if (Test-Path -LiteralPath $candidate) {
        $resolvedGodot = $candidate
        break
    }
}

if ($null -eq $resolvedGodot) {
    throw "Godot executable not found. Pass -GodotExe explicitly."
}

$logFile = Join-Path $ProjectPath ".tmp_verify_v03.log"

& $resolvedGodot --headless --log-file $logFile --path $ProjectPath --script (Join-Path $ProjectPath "scripts\verify_v03.gd")
if ($LASTEXITCODE -ne 0) {
    throw "v0.3 verification failed with exit code $LASTEXITCODE"
}

Remove-Item -LiteralPath $logFile -ErrorAction SilentlyContinue
Write-Host "v0.3 verification passed"
