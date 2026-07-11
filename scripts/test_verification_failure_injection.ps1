param([string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot))

$ErrorActionPreference = "Stop"
. (Join-Path $ProjectRoot "scripts/verification_common.ps1")

foreach ($sample in @(
    "Parser Error: injected",
    "Parse Error: injected",
    "Script Error: injected",
    "Invalid call. injected",
    "Failed loading resource: res://missing.tres",
    "Missing resource: res://missing.tres"
)) {
    $failed = $false
    try { Assert-LmmVerificationOutput -OutputText $sample -ExitCode 0 -Label "injection" } catch { $failed = $true }
    if (-not $failed) { throw "Blocking output was accepted: $sample" }
}

Assert-LmmVerificationOutput -OutputText "verification passed" -ExitCode 0 -Label "control" -SuccessMarker "verification passed"
Write-Host "Verification failure injection tests passed" -ForegroundColor Green
