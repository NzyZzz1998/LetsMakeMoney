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
$v06Dir = Join-Path $Root "doc/releases/v0.6"
$statusPath = Join-Path $v06Dir "status.md"
$progressPath = Join-Path $v06Dir "progress_v0.6.md"
$planPath = Join-Path $v06Dir "dev_plan_v0.6.md"
$prdPath = Join-Path $v06Dir "prd.md"
$verificationPath = Join-Path $v06Dir "verification.md"
$releaseChecklistPath = Join-Path $v06Dir "release-checklist.md"
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

    if ($status -notmatch "v0\.6 Beta") {
        Add-Issue $issues "status.md does not identify v0.6 Beta."
    }

    if ($status -notmatch "V06-M0") {
        Add-Issue $issues "status.md should reference the active V06-M0 implementation milestone."
    }

    if ($progress -notmatch "V06-M0") {
        Add-Issue $issues "progress_v0.6.md does not contain V06-M0."
    }

    if ($progress -notmatch "dev-log" -or $progress -notmatch "bugfix-log" -or $progress -notmatch "spike-log") {
        Add-Issue $issues "progress_v0.6.md does not state progress/log boundaries."
    }

    if ($checklist -notmatch "package_v06\.ps1") {
        Add-Issue $issues "release-checklist.md does not reference v0.6 package script."
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
