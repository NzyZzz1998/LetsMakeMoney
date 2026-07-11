param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"
$issues = [System.Collections.Generic.List[string]]::new()

function Read-Utf8([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) {
        $issues.Add("Missing required document: $Path")
        return ""
    }
    return [IO.File]::ReadAllText($Path, [Text.UTF8Encoding]::new($false, $true))
}

$current = Read-Utf8 (Join-Path $Root "doc/current.md")
$v07Status = Read-Utf8 (Join-Path $Root "doc/releases/v0.7/status.md")
$v07Progress = Read-Utf8 (Join-Path $Root "doc/releases/v0.7/progress_v0.7.md")
$v07Readiness = Read-Utf8 (Join-Path $Root "doc/releases/v0.7/public-readiness.md")
$v06Status = Read-Utf8 (Join-Path $Root "doc/releases/v0.6/status.md")
$v06Verification = Read-Utf8 (Join-Path $Root "doc/releases/v0.6/verification.md")

if ($current -notmatch "v0\.7 Beta") { $issues.Add("current.md does not identify v0.7 Beta.") }
if ($current -notmatch "v0\.6 Beta") { $issues.Add("current.md does not preserve the v0.6 Beta baseline.") }
if ($current -notmatch "V07-A[0-9]" -or $current -notmatch "e6f25ae8cb4d9583aa3e629cb79416e278060117") { $issues.Add("current.md does not preserve the v0.7 A-series Git identity.") }
if ($v07Status -notmatch "V07-A0" -or $v07Status -notmatch "v0\.7") { $issues.Add("v0.7 status does not record A0.") }
if ($v07Progress -notmatch "V07-A0-001" -or $v07Progress -notmatch "V07-A0-008") { $issues.Add("v0.7 progress is missing A0 tasks.") }
if ($v07Readiness -notmatch "V07-A3" -or $v07Readiness -notmatch "A1/A2/A3") { $issues.Add("public-readiness does not preserve downstream gates.") }
if ($v06Status -notmatch "v0\.6-beta") { $issues.Add("v0.6 status no longer identifies the release tag.") }
if ($v06Verification -notmatch "V06-ACC-M6-015") { $issues.Add("v0.6 verification no longer preserves the startup evidence row.") }

if ($issues.Count -gt 0) {
    Write-Host "Docs status check failed:" -ForegroundColor Red
    $issues | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

Write-Host "Docs status check passed: v0.7 development and v0.6 release facts are consistent." -ForegroundColor Green
