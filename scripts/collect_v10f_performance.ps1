param(
    [string]$ExePath = "",
    [string]$OutputPath = "",
    [ValidateRange(1, 50)]
    [int]$ColdRuns = 10,
    [ValidateRange(1, 50)]
    [int]$WarmRuns = 10,
    [switch]$KeepProfiles,
    [switch]$AllowUserProfileEvidence
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$HistoricalCollector = Join-Path $PSScriptRoot "collect_v107_performance.ps1"

if (-not $AllowUserProfileEvidence) {
    throw "This probe temporarily uses the real Windows app-data location. Re-run with -AllowUserProfileEvidence after closing LetsMakeMoney; config.json and debug.log are restored automatically."
}
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $RepoRoot "doc\releases\v1.0.F\evidence\m6-cold-start-performance.json"
}

$RawPath = Join-Path $env:TEMP ("lmm-v10f-performance-raw-" + [Guid]::NewGuid().ToString("N") + ".json")
try {
    $Arguments = @{
        OutputPath = $RawPath
        ColdRuns = $ColdRuns
        WarmRuns = $WarmRuns
        AllowUserProfileEvidence = $true
    }
    if (-not [string]::IsNullOrWhiteSpace($ExePath)) { $Arguments.ExePath = $ExePath }
    if ($KeepProfiles) { $Arguments.KeepProfiles = $true }
    & $HistoricalCollector @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Performance collector failed with exit code $LASTEXITCODE"
    }

    $Evidence = Get-Content -LiteralPath $RawPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $Evidence.milestone = "V10F-M6"
    $Evidence.raw_evidence = [ordered]@{
        availability = "repository-summary"
        logical_id = "V10F-M6-PERF"
    }

    $ColdStartP95 = [double]$Evidence.metrics.cold_mini_ready_p95_ms
    $Assessment = [ordered]@{
        cold_start_exceeds = $ColdStartP95 -gt 2000
        mini_first_frame_exceeds = [bool]$Evidence.threshold_assessment.cold_mini_exceeds
        workbench_first_frame_exceeds = [bool]$Evidence.threshold_assessment.cold_workbench_exceeds
        js_gzip_exceeds = [bool]$Evidence.threshold_assessment.js_gzip_exceeds
        long_task_exceeds = [bool]$Evidence.threshold_assessment.long_task_exceeds
    }
    $Evidence.threshold_assessment = $Assessment
    $Evidence.optimization_review_required = [bool]($Assessment.Values -contains $true)
    $Evidence | Add-Member -NotePropertyName decision -NotePropertyValue "measurement_only_pending_review" -Force
    $Evidence | Add-Member -NotePropertyName optimization -NotePropertyValue ([ordered]@{
        attempted = $false
        target = $null
        gain_percent = $null
        retained = $false
        reason = "pending_threshold_review"
    }) -Force

    $OutputDirectory = Split-Path -Parent $OutputPath
    New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
    [IO.File]::WriteAllText(
        $OutputPath,
        ($Evidence | ConvertTo-Json -Depth 20),
        [Text.UTF8Encoding]::new($false)
    )
    Write-Host "COLLECTED v1.0.F cold-start evidence: $OutputPath" -ForegroundColor Green
}
finally {
    if (Test-Path -LiteralPath $RawPath) {
        Remove-Item -LiteralPath $RawPath -Force -ErrorAction SilentlyContinue
    }
}
