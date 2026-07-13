param([string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot))

$ErrorActionPreference = "Stop"
$checker = Join-Path $PSScriptRoot "check_script_tiers.ps1"
& $checker -ProjectRoot $ProjectRoot

$manifest = Get-Content -LiteralPath (Join-Path $PSScriptRoot "script-tiers.json") -Raw -Encoding UTF8 | ConvertFrom-Json
$all = @($manifest.tiers | ForEach-Object files)
if ($all.Count -ne @($all | Sort-Object -Unique).Count) {
    throw "Script tier manifest contains duplicate entries."
}
if (@($manifest.tiers | Where-Object id -eq "archive").Count -ne 1) {
    throw "Script tier manifest must contain exactly one archive tier."
}

Write-Host "Script tier contract tests passed" -ForegroundColor Green
