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
$v07Current = Read-Utf8 (Join-Path $Root "doc/releases/v0.7/current.md")
$readme = Read-Utf8 (Join-Path $Root "README.md")
$project = Read-Utf8 (Join-Path $Root "project.godot")
$v06Status = Read-Utf8 (Join-Path $Root "doc/releases/v0.6/status.md")
$v06Verification = Read-Utf8 (Join-Path $Root "doc/releases/v0.6/verification.md")

if (-not ($current -match "v0\.7 Beta")) { $issues.Add("current.md does not identify v0.7 Beta as the current release.") }
if (-not ($current -match "v0\.6 Beta")) { $issues.Add("current.md does not preserve the v0.6 Beta baseline.") }
if (-not $current.Contains("v0.7-beta") -or -not $current.Contains("e79149d91e8e0adb3cbf1e53cd8819f072f7154f")) { $issues.Add("current.md is missing the published v0.7 tag or commit identity.") }
if (-not $v07Current.Contains("GitHub Pre-release") -or -not $v07Current.Contains("16F47A844EFD78D387E9D08FBCD3DE76C8C8BDD518731C1B0BA022E7F598121F")) { $issues.Add("v0.7 current snapshot is missing the published release state or Zip hash.") }
if (-not $readme.Contains("scripts\verify_v07.ps1") -or -not $readme.Contains("scripts\package_v07.ps1")) { $issues.Add("README does not expose the current v0.7 verification and packaging entry points.") }
if (-not ($project -match 'config/version="0\.7-beta"')) { $issues.Add("project.godot does not identify version 0.7-beta.") }
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
