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

if (-not ($current -match "v0\.7 Beta")) { $issues.Add("current.md does not identify v0.7 Beta.") }
if (-not ($current -match "v0\.6 Beta")) { $issues.Add("current.md does not preserve the v0.6 Beta baseline.") }
$hasAcceptedState = $current.Contains("Acceptance")
$hasReleaseClosing = $current.Contains("V07-ACC-001")
if (-not $hasAcceptedState -or -not $hasReleaseClosing) { $issues.Add("current.md does not identify the v0.7 accepted, release-closing state.") }
if ($v07Status -notmatch "V07-A0" -or $v07Status -notmatch "v0\.7") { $issues.Add("v0.7 status does not record A0.") }
if ($v07Progress -notmatch "V07-A0-001" -or $v07Progress -notmatch "V07-A0-008") { $issues.Add("v0.7 progress is missing A0 tasks.") }
if ($v07Readiness -notmatch "A0/A1/A2/A3" -or $v07Readiness -notmatch "v0\.7") { $issues.Add("public-readiness does not preserve repository and v0.7 release gates.") }
if ($v06Status -notmatch "v0\.6-beta") { $issues.Add("v0.6 status no longer identifies the release tag.") }
if ($v06Verification -notmatch "V06-ACC-M6-015") { $issues.Add("v0.6 verification no longer preserves the startup evidence row.") }

if ($issues.Count -gt 0) {
    Write-Host "Docs status check failed:" -ForegroundColor Red
    $issues | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

Write-Host "Docs status check passed: v0.7 release and v0.6 baseline facts are consistent." -ForegroundColor Green
