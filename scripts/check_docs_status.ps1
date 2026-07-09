param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

function Read-Text {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Missing required document: $Path"
    }
    return Get-Content -LiteralPath $Path -Raw -Encoding UTF8
}

function Add-Issue {
    param(
        [System.Collections.Generic.List[string]]$Issues,
        [string]$Message
    )
    [void]$Issues.Add($Message)
}

$issues = [System.Collections.Generic.List[string]]::new()

$currentPath = Join-Path $Root "doc/current.md"
$v05Dir = Join-Path $Root "doc/releases/v0.5"
$statusPath = Join-Path $v05Dir "status.md"
$progressPath = Join-Path $v05Dir "progress_v0.5.md"
$planPath = Join-Path $v05Dir "dev_plan_v0.5.md"
$prdPath = Join-Path $v05Dir "prd.md"
$verificationPath = Join-Path $v05Dir "verification.md"
$releaseChecklistPath = Join-Path $v05Dir "release-checklist.md"
$logsReadmePath = Join-Path $Root "doc/logs/README.md"

$requiredFiles = @(
    $currentPath,
    $statusPath,
    $progressPath,
    $planPath,
    $prdPath,
    $verificationPath,
    $releaseChecklistPath,
    $logsReadmePath
)

foreach ($file in $requiredFiles) {
    if (-not (Test-Path -LiteralPath $file)) {
        Add-Issue $issues "Missing required file: $file"
    }
}

if ($issues.Count -eq 0) {
    $status = Read-Text $statusPath
    $progress = Read-Text $progressPath
    $checklist = Read-Text $releaseChecklistPath
    $logsReadme = Read-Text $logsReadmePath

    if ($status -notmatch "v0\.5 Beta") {
        Add-Issue $issues "status.md does not identify v0.5 Beta."
    }

    if ($status -notmatch "V05-M0") {
        Add-Issue $issues "status.md should reference the active V05-M0 implementation milestone."
    }

    if ($progress -notmatch "V05-M0") {
        Add-Issue $issues "progress_v0.5.md does not contain V05-M0."
    }

    if ($progress -notmatch "dev-log" -or $progress -notmatch "bugfix-log" -or $progress -notmatch "spike-log") {
        Add-Issue $issues "progress_v0.5.md does not state progress/log boundaries."
    }

    if ($checklist -notmatch "package_v05\.ps1") {
        Add-Issue $issues "release-checklist.md does not reference v0.5 package script."
    }

    if ($logsReadme -notmatch "dev-log" -or $logsReadme -notmatch "bugfix-log" -or $logsReadme -notmatch "spike-log") {
        Add-Issue $issues "doc/logs/README.md does not define dev-log/bugfix-log/spike-log boundaries."
    }
}

if ($issues.Count -gt 0) {
    Write-Host "Docs status check failed:" -ForegroundColor Red
    foreach ($issue in $issues) {
        Write-Host " - $issue" -ForegroundColor Red
    }
    exit 1
}

Write-Host "Docs status check passed." -ForegroundColor Green
