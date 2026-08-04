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
$AppRoot = Join-Path $RepoRoot "apps\windows-v1"
. (Join-Path $PSScriptRoot "v10_tools.ps1")

$Node = Get-V10Node -RepoRoot $RepoRoot
$Probe = Join-Path $AppRoot "tests\cdp_v107_probe.mjs"
$ConfigFixture = Join-Path $AppRoot "tests\fixtures\v107-performance-config.json"
$UserConfigDirectory = Join-Path $env:APPDATA "io.letsmakemoney.windows"
$UserConfigPath = Join-Path $UserConfigDirectory "config.json"
$UserLogPath = Join-Path $UserConfigDirectory "debug.log"
if (-not $AllowUserProfileEvidence) {
    throw "This probe temporarily uses the real Windows app-data location. Re-run with -AllowUserProfileEvidence after closing LetsMakeMoney; the script backs up and restores config.json and debug.log."
}
if (Get-Process -Name "letsmakemoney_windows_v1" -ErrorAction SilentlyContinue) {
    throw "Close all LetsMakeMoney processes before collecting performance evidence."
}
if ([string]::IsNullOrWhiteSpace($ExePath)) {
    $ExePath = Join-Path $AppRoot "src-tauri\target\release\letsmakemoney_windows_v1.exe"
}
if (-not (Test-Path -LiteralPath $ExePath -PathType Leaf)) {
    throw "Performance candidate EXE is missing: $ExePath"
}
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $env:TEMP ("lmm-v107-performance-" + [DateTime]::UtcNow.ToString("yyyyMMddTHHmmssZ") + ".json")
}

function Get-FreeTcpPort {
    $Listener = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, 0)
    $Listener.Start()
    try { return ([Net.IPEndPoint]$Listener.LocalEndpoint).Port }
    finally { $Listener.Stop() }
}

function Get-CdpTargets([int]$Port) {
    try {
        return @(Invoke-RestMethod -Uri "http://127.0.0.1:$Port/json" -TimeoutSec 1)
    }
    catch { return @() }
}

function Wait-CdpTarget([int]$Port, [string]$WindowName, [int]$TimeoutSeconds = 15) {
    $Deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    $LastUrls = @()
    do {
        $Targets = @(Get-CdpTargets -Port $Port)
        $LastUrls = @($Targets | ForEach-Object { [string]$_.url })
        $Target = $Targets |
            Where-Object { $_.type -eq "page" -and $_.url -like "*window=$WindowName*" } |
            Select-Object -First 1
        if ($Target) { return $Target }
        Start-Sleep -Milliseconds 80
    } while ((Get-Date) -lt $Deadline)
    $Observed = if ($LastUrls.Count) { $LastUrls -join ", " } else { "none" }
    throw "Timed out waiting for the $WindowName WebView target on port $Port; observed URLs: $Observed"
}

function Invoke-CdpSnapshot([string]$WebSocketUrl) {
    for ($Attempt = 1; $Attempt -le 20; $Attempt++) {
        $PreviousPreference = $ErrorActionPreference
        try {
            $ErrorActionPreference = "Continue"
            $Raw = & $Node $Probe $WebSocketUrl snapshot 2>$null
        }
        finally { $ErrorActionPreference = $PreviousPreference }
        if ($LASTEXITCODE -eq 0) { return $Raw | ConvertFrom-Json }
        Start-Sleep -Milliseconds 100
    }
    throw "CDP snapshot failed after 20 attempts: $WebSocketUrl"
}

function Invoke-CdpExpression([string]$WebSocketUrl, [string]$Expression) {
    $Encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Expression))
    for ($Attempt = 1; $Attempt -le 20; $Attempt++) {
        $PreviousPreference = $ErrorActionPreference
        try {
            $ErrorActionPreference = "Continue"
            $Raw = & $Node $Probe $WebSocketUrl evaluate $Encoded 2>$null
        }
        finally { $ErrorActionPreference = $PreviousPreference }
        if ($LASTEXITCODE -eq 0) { return $Raw | ConvertFrom-Json }
        Start-Sleep -Milliseconds 100
    }
    throw "CDP evaluation failed after 20 attempts"
}

function Wait-CompleteSnapshot([string]$WebSocketUrl, [int]$TimeoutSeconds = 15) {
    $Deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    do {
        $Snapshot = Invoke-CdpSnapshot -WebSocketUrl $WebSocketUrl
        $Ready = $Snapshot.ready_state -eq "complete" -and
            $Snapshot.theme_ready -eq "true" -and
            $Snapshot.tauri_bridge_ready -eq $true -and
            [int]$Snapshot.body_text_length -gt 20
        if ($Ready) { return $Snapshot }
        Start-Sleep -Milliseconds 80
    } while ((Get-Date) -lt $Deadline)
    throw "Timed out waiting for a complete product frame"
}

function New-ProbeProfile([string]$Root) {
    $Local = Join-Path $Root "Local"
    New-Item -ItemType Directory -Force -Path $Local | Out-Null
    return [pscustomobject]@{ Root = $Root; Local = $Local }
}

function Convert-ToRedactedSnapshot([object]$Snapshot) {
    return [ordered]@{
        ready_state = $Snapshot.ready_state
        body_text_length = $Snapshot.body_text_length
        theme = $Snapshot.theme
        theme_ready = $Snapshot.theme_ready
        time_origin_epoch_ms = $Snapshot.time_origin_epoch_ms
        first_paint_ms = $Snapshot.first_paint_ms
        first_contentful_paint_ms = $Snapshot.first_contentful_paint_ms
        dom_content_loaded_ms = $Snapshot.dom_content_loaded_ms
        load_event_end_ms = $Snapshot.load_event_end_ms
        resource_count = $Snapshot.resource_count
        resource_transfer_bytes = $Snapshot.resource_transfer_bytes
        resource_encoded_bytes = $Snapshot.resource_encoded_bytes
        long_task_count = $Snapshot.long_task_count
        max_long_task_ms = $Snapshot.max_long_task_ms
        tauri_bridge_ready = $Snapshot.tauri_bridge_ready
    }
}

function Invoke-ProbeRun([string]$Kind, [int]$Index, [object]$Profile) {
    $Port = Get-FreeTcpPort
    $PreviousArguments = $env:WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS
    $PreviousUserData = $env:WEBVIEW2_USER_DATA_FOLDER
    $Process = $null
    try {
        $env:WEBVIEW2_USER_DATA_FOLDER = Join-Path $Profile.Local "WebView2"
        $env:WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS = "--remote-debugging-port=$Port"
        $StartedEpochMs = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
        $Process = Start-Process -FilePath $ExePath -WindowStyle Hidden -PassThru

        $MiniTarget = @(Wait-CdpTarget -Port $Port -WindowName "mini")[0]
        $MiniSocket = ([string]$MiniTarget.webSocketDebuggerUrl) -replace "localhost", "127.0.0.1"
        $Mini = Wait-CompleteSnapshot -WebSocketUrl $MiniSocket
        $MiniReadyEpochMs = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()

        $OpenWorkbench = "window.__TAURI_INTERNALS__.invoke('show_app_window', { label: 'workbench' })"
        [void](Invoke-CdpExpression -WebSocketUrl $MiniSocket -Expression $OpenWorkbench)
        $WorkbenchTarget = @(Wait-CdpTarget -Port $Port -WindowName "workbench")[0]
        $WorkbenchSocket = ([string]$WorkbenchTarget.webSocketDebuggerUrl) -replace "localhost", "127.0.0.1"
        $Workbench = Wait-CompleteSnapshot -WebSocketUrl $WorkbenchSocket
        $WorkbenchReadyEpochMs = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()

        return [ordered]@{
            kind = $Kind
            index = $Index
            process_start_epoch_ms = $StartedEpochMs
            mini_ready_epoch_ms = $MiniReadyEpochMs
            mini_ready_from_process_ms = $MiniReadyEpochMs - $StartedEpochMs
            mini_fcp_from_process_ms = if ($null -ne $Mini.first_contentful_paint_ms) { [math]::Round(($Mini.time_origin_epoch_ms + $Mini.first_contentful_paint_ms) - $StartedEpochMs, 3) } else { $null }
            workbench_ready_epoch_ms = $WorkbenchReadyEpochMs
            workbench_ready_from_process_ms = $WorkbenchReadyEpochMs - $StartedEpochMs
            workbench_fcp_from_process_ms = if ($null -ne $Workbench.first_contentful_paint_ms) { [math]::Round(($Workbench.time_origin_epoch_ms + $Workbench.first_contentful_paint_ms) - $StartedEpochMs, 3) } else { $null }
            mini = Convert-ToRedactedSnapshot -Snapshot $Mini
            workbench = Convert-ToRedactedSnapshot -Snapshot $Workbench
        }
    }
    finally {
        if ($Process) { Stop-Process -Id $Process.Id -Force -ErrorAction SilentlyContinue }
        $env:WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS = $PreviousArguments
        $env:WEBVIEW2_USER_DATA_FOLDER = $PreviousUserData
        Start-Sleep -Milliseconds 250
    }
}

function Get-Percentile([double[]]$Values, [double]$Percentile) {
    if (-not $Values -or $Values.Count -eq 0) { return $null }
    $Sorted = @($Values | Sort-Object)
    $Index = [math]::Ceiling(($Percentile / 100.0) * $Sorted.Count) - 1
    return [math]::Round($Sorted[[math]::Max(0, $Index)], 3)
}

$Root = Join-Path $env:TEMP ("lmm-v107-performance-profiles-" + [Guid]::NewGuid().ToString("N"))
$StateBackup = Join-Path $env:TEMP ("lmm-v107-performance-user-state-" + [Guid]::NewGuid().ToString("N"))
$Runs = [Collections.Generic.List[object]]::new()
$ConfigExisted = Test-Path -LiteralPath $UserConfigPath -PathType Leaf
$LogExisted = Test-Path -LiteralPath $UserLogPath -PathType Leaf
try {
    New-Item -ItemType Directory -Force -Path $StateBackup, $UserConfigDirectory | Out-Null
    if ($ConfigExisted) { Copy-Item -LiteralPath $UserConfigPath -Destination (Join-Path $StateBackup "config.json") -Force }
    if ($LogExisted) { Copy-Item -LiteralPath $UserLogPath -Destination (Join-Path $StateBackup "debug.log") -Force }
    Copy-Item -LiteralPath $ConfigFixture -Destination $UserConfigPath -Force

    for ($Index = 1; $Index -le $ColdRuns; $Index++) {
        $Profile = New-ProbeProfile -Root (Join-Path $Root "cold-$Index")
        $Runs.Add((Invoke-ProbeRun -Kind "cold" -Index $Index -Profile $Profile))
    }

    $WarmProfile = New-ProbeProfile -Root (Join-Path $Root "warm")
    [void](Invoke-ProbeRun -Kind "warmup" -Index 0 -Profile $WarmProfile)
    for ($Index = 1; $Index -le $WarmRuns; $Index++) {
        $Runs.Add((Invoke-ProbeRun -Kind "warm" -Index $Index -Profile $WarmProfile))
    }

    $JsFiles = @(Get-ChildItem -LiteralPath (Join-Path $AppRoot "dist\assets") -Filter "*.js" -File | Where-Object Name -NotLike "*.map")
    Add-Type -AssemblyName System.IO.Compression
    $Bundle = foreach ($File in $JsFiles) {
        $Input = [IO.File]::OpenRead($File.FullName)
        $Output = [IO.MemoryStream]::new()
        try {
            $Gzip = [IO.Compression.GZipStream]::new($Output, [IO.Compression.CompressionLevel]::Optimal, $true)
            $Input.CopyTo($Gzip)
            $Gzip.Dispose()
            [pscustomobject][ordered]@{ name = $File.Name; raw_bytes = $File.Length; gzip_bytes = $Output.Length }
        }
        finally { $Input.Dispose(); $Output.Dispose() }
    }

    $Measured = @($Runs | Where-Object { $_.kind -ne "warmup" })
    $Cold = @($Measured | Where-Object { $_.kind -eq "cold" })
    $Warm = @($Measured | Where-Object { $_.kind -eq "warm" })
    $AllLongTasks = @($Measured | ForEach-Object { @($_.mini.max_long_task_ms, $_.workbench.max_long_task_ms) })
    $ColdMiniP95 = Get-Percentile -Values @($Cold | ForEach-Object mini_ready_from_process_ms) -Percentile 95
    $WarmMiniP95 = Get-Percentile -Values @($Warm | ForEach-Object mini_ready_from_process_ms) -Percentile 95
    $ColdWorkbenchP95 = Get-Percentile -Values @($Cold | ForEach-Object workbench_ready_from_process_ms) -Percentile 95
    $WarmWorkbenchP95 = Get-Percentile -Values @($Warm | ForEach-Object workbench_ready_from_process_ms) -Percentile 95
    $MaxLongTask = if ($AllLongTasks.Count) { [math]::Round(($AllLongTasks | Measure-Object -Maximum).Maximum, 3) } else { 0 }
    $JsRawBytes = ($Bundle | Measure-Object raw_bytes -Sum).Sum
    $JsGzipBytes = ($Bundle | Measure-Object gzip_bytes -Sum).Sum
    $ThresholdAssessment = [ordered]@{
        cold_mini_exceeds = $ColdMiniP95 -gt 1200
        warm_mini_exceeds = $WarmMiniP95 -gt 1200
        cold_workbench_exceeds = $ColdWorkbenchP95 -gt 1500
        warm_workbench_exceeds = $WarmWorkbenchP95 -gt 1500
        js_gzip_exceeds = $JsGzipBytes -gt 184320
        long_task_exceeds = $MaxLongTask -gt 100
    }
    $OptimizationReviewRequired = [bool]($ThresholdAssessment.Values -contains $true)
    $Summary = [ordered]@{
        schema_version = 1
        milestone = "V107-M6"
        captured_at_utc = [DateTime]::UtcNow.ToString("o")
        source_head = (git -C $RepoRoot rev-parse HEAD).Trim()
        source_tree_dirty = [bool](git -C $RepoRoot status --short)
        executable = [ordered]@{
            name = [IO.Path]::GetFileName($ExePath)
            size = (Get-Item -LiteralPath $ExePath).Length
            sha256 = (Get-FileHash -LiteralPath $ExePath -Algorithm SHA256).Hash
        }
        environment = [ordered]@{
            os_family = "Windows 11"
            os_build = [Environment]::OSVersion.Version.ToString()
            display_count = @(Get-CimInstance Win32_DesktopMonitor | Where-Object Availability -eq 3).Count
            scope = "Windows 11 single-display; real DPI acceptance remains separate"
            app_data_mode = "temporary deterministic fixture with automatic backup and restore"
        }
        sample_count = [ordered]@{ cold = $Cold.Count; warm = $Warm.Count }
        thresholds = [ordered]@{
            cold_start_p95_ms = 2000
            mini_first_frame_p95_ms = 1200
            workbench_first_frame_p95_ms = 1500
            js_gzip_bytes = 184320
            long_task_ms = 100
            minimum_optimization_gain_percent = 15
        }
        metrics = [ordered]@{
            cold_mini_ready_p95_ms = $ColdMiniP95
            warm_mini_ready_p95_ms = $WarmMiniP95
            cold_workbench_ready_p95_ms = $ColdWorkbenchP95
            warm_workbench_ready_p95_ms = $WarmWorkbenchP95
            max_long_task_ms = $MaxLongTask
            js_raw_bytes = $JsRawBytes
            js_gzip_bytes = $JsGzipBytes
        }
        threshold_assessment = $ThresholdAssessment
        optimization_review_required = $OptimizationReviewRequired
        bundle = @($Bundle)
        runs = $Measured
        raw_evidence = [ordered]@{ availability = "external"; logical_id = "V107-M6-PERF-RAW" }
    }
    $OutputDirectory = Split-Path -Parent $OutputPath
    if ($OutputDirectory) { New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null }
    [IO.File]::WriteAllText($OutputPath, ($Summary | ConvertTo-Json -Depth 20), [Text.UTF8Encoding]::new($false))
    Write-Host "COLLECTED v1.0.7 performance baseline: $OutputPath" -ForegroundColor Green
    $Summary.metrics | Format-List
}
finally {
    Get-Process -Name "letsmakemoney_windows_v1" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    if ($ConfigExisted) {
        Copy-Item -LiteralPath (Join-Path $StateBackup "config.json") -Destination $UserConfigPath -Force
    } elseif (Test-Path -LiteralPath $UserConfigPath) {
        Remove-Item -LiteralPath $UserConfigPath -Force
    }
    if ($LogExisted) {
        Copy-Item -LiteralPath (Join-Path $StateBackup "debug.log") -Destination $UserLogPath -Force
    } elseif (Test-Path -LiteralPath $UserLogPath) {
        Remove-Item -LiteralPath $UserLogPath -Force
    }
    if (Test-Path -LiteralPath $StateBackup) {
        Remove-Item -LiteralPath $StateBackup -Recurse -Force -ErrorAction SilentlyContinue
    }
    if (-not $KeepProfiles -and (Test-Path -LiteralPath $Root)) {
        Remove-Item -LiteralPath $Root -Recurse -Force -ErrorAction SilentlyContinue
    }
}
