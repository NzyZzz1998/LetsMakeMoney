param(
    [Parameter(Mandatory = $true)]
    [int]$ProcessId,
    [double]$DurationMinutes = 120,
    [int]$SampleSeconds = 5,
    [string]$EvidenceDirectory = "",
    [string]$LogPath = ""
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
if ($DurationMinutes -le 0) { throw "DurationMinutes must be positive." }
if ($SampleSeconds -lt 1) { throw "SampleSeconds must be at least one second." }
if (-not $EvidenceDirectory) {
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $EvidenceDirectory = Join-Path $root ".tmp_acceptance\v1.0.3-stability-$stamp"
}
$EvidenceDirectory = [IO.Path]::GetFullPath($EvidenceDirectory)
New-Item -ItemType Directory -Path $EvidenceDirectory -Force | Out-Null

if (-not $LogPath) {
    $LogPath = Join-Path $env:APPDATA "io.letsmakemoney.windows\debug.log"
}
$LogPath = [IO.Path]::GetFullPath($LogPath)
$csvPath = Join-Path $EvidenceDirectory "process-samples.csv"
$summaryPath = Join-Path $EvidenceDirectory "stability-summary.json"
$startedAt = [DateTimeOffset]::Now
$deadline = $startedAt.AddMinutes($DurationMinutes)
$initialLogBytes = if (Test-Path -LiteralPath $LogPath -PathType Leaf) {
    (Get-Item -LiteralPath $LogPath).Length
} else {
    0
}
$initialAuthorityCount = if (Test-Path -LiteralPath $LogPath -PathType Leaf) {
    @(Select-String -LiteralPath $LogPath -SimpleMatch "event=earnings.authoritative_sync.requested").Count
} else {
    0
}

$samples = [System.Collections.Generic.List[object]]::new()
$lastCpuSeconds = $null
$lastSampleAt = $null
while ([DateTimeOffset]::Now -lt $deadline) {
    $process = Get-Process -Id $ProcessId -ErrorAction Stop
    $capturedAt = [DateTimeOffset]::Now
    $cpuPercent = $null
    if ($null -ne $lastCpuSeconds -and $null -ne $lastSampleAt) {
        $elapsed = ($capturedAt - $lastSampleAt).TotalSeconds
        if ($elapsed -gt 0) {
            $cpuPercent = [Math]::Round(
                (($process.CPU - $lastCpuSeconds) / $elapsed / [Environment]::ProcessorCount) * 100,
                3
            )
        }
    }
    $logBytes = if (Test-Path -LiteralPath $LogPath -PathType Leaf) {
        (Get-Item -LiteralPath $LogPath).Length
    } else {
        0
    }
    $samples.Add([pscustomobject]@{
        captured_at = $capturedAt.ToString("o")
        process_id = $process.Id
        cpu_total_seconds = [Math]::Round($process.CPU, 3)
        cpu_percent_normalized = $cpuPercent
        working_set_bytes = $process.WorkingSet64
        private_memory_bytes = $process.PrivateMemorySize64
        handles = $process.HandleCount
        threads = $process.Threads.Count
        log_bytes = $logBytes
    })
    $lastCpuSeconds = $process.CPU
    $lastSampleAt = $capturedAt
    Start-Sleep -Seconds $SampleSeconds
}

$samples | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding UTF8
$finishedAt = [DateTimeOffset]::Now
$finalLogBytes = if (Test-Path -LiteralPath $LogPath -PathType Leaf) {
    (Get-Item -LiteralPath $LogPath).Length
} else {
    0
}
$finalAuthorityCount = if (Test-Path -LiteralPath $LogPath -PathType Leaf) {
    @(Select-String -LiteralPath $LogPath -SimpleMatch "event=earnings.authoritative_sync.requested").Count
} else {
    0
}
$numericCpu = @($samples | Where-Object { $null -ne $_.cpu_percent_normalized } |
    ForEach-Object { [double]$_.cpu_percent_normalized })
$summary = [ordered]@{
    schema_version = 1
    process_id = $ProcessId
    started_at = $startedAt.ToString("o")
    finished_at = $finishedAt.ToString("o")
    elapsed_seconds = [Math]::Round(($finishedAt - $startedAt).TotalSeconds, 3)
    requested_duration_minutes = $DurationMinutes
    sample_seconds = $SampleSeconds
    sample_count = $samples.Count
    process_survived = $true
    cpu_percent_normalized = [ordered]@{
        average = if ($numericCpu.Count) {
            [Math]::Round(($numericCpu | Measure-Object -Average).Average, 3)
        } else { $null }
        maximum = if ($numericCpu.Count) {
            [Math]::Round(($numericCpu | Measure-Object -Maximum).Maximum, 3)
        } else { $null }
    }
    working_set_bytes = [ordered]@{
        first = if ($samples.Count) { $samples[0].working_set_bytes } else { $null }
        last = if ($samples.Count) { $samples[$samples.Count - 1].working_set_bytes } else { $null }
        maximum = if ($samples.Count) {
            ($samples | Measure-Object -Property working_set_bytes -Maximum).Maximum
        } else { $null }
    }
    private_memory_bytes = [ordered]@{
        first = if ($samples.Count) { $samples[0].private_memory_bytes } else { $null }
        last = if ($samples.Count) { $samples[$samples.Count - 1].private_memory_bytes } else { $null }
        maximum = if ($samples.Count) {
            ($samples | Measure-Object -Property private_memory_bytes -Maximum).Maximum
        } else { $null }
    }
    handle_count = [ordered]@{
        first = if ($samples.Count) { $samples[0].handles } else { $null }
        last = if ($samples.Count) { $samples[$samples.Count - 1].handles } else { $null }
        maximum = if ($samples.Count) {
            ($samples | Measure-Object -Property handles -Maximum).Maximum
        } else { $null }
    }
    authority_request_count = $finalAuthorityCount - $initialAuthorityCount
    log_growth_bytes = $finalLogBytes - $initialLogBytes
    evidence = [ordered]@{
        samples = [IO.Path]::GetFileName($csvPath)
        summary = [IO.Path]::GetFileName($summaryPath)
    }
}
$summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $summaryPath -Encoding UTF8

Write-Host "Stability evidence: $EvidenceDirectory"
Write-Host "Samples: $($samples.Count)"
Write-Host "Authority requests: $($summary.authority_request_count)"
Write-Host "Log growth: $($summary.log_growth_bytes) bytes"
