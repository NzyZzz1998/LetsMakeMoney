param(
    [string]$CandidateExe = "",
    [string]$OutputPath = "",
    [switch]$SkipBuild,
    [switch]$KeepCandidate,
    [switch]$AllowUserProfileEvidence
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$AppRoot = Join-Path $RepoRoot "apps\windows-v1"
$Fixture = Join-Path $AppRoot "tests\fixtures\v107-csp-candidate.json"
$BaseConfig = Join-Path $AppRoot "src-tauri\tauri.conf.json"
$ConfigFixture = Join-Path $AppRoot "tests\fixtures\v107-performance-config.json"
$Probe = Join-Path $AppRoot "tests\cdp_v107_probe.mjs"
. (Join-Path $PSScriptRoot "v10_tools.ps1")

if (-not $AllowUserProfileEvidence) {
    throw "The CSP probe temporarily uses the real Windows app-data location. Re-run with -AllowUserProfileEvidence after closing LetsMakeMoney; user state is backed up and restored."
}
if (Get-Process -Name "letsmakemoney_windows_v1" -ErrorAction SilentlyContinue) {
    throw "Close all LetsMakeMoney processes before running the CSP probe."
}

$Node = Get-V10Node -RepoRoot $RepoRoot
$Cargo = Get-V10Cargo -RepoRoot $RepoRoot
$NodeDirectory = Split-Path $Node -Parent
$CargoDirectory = Split-Path $Cargo -Parent
$PreviousPath = $env:PATH
$PreviousTarget = $env:CARGO_TARGET_DIR
$PreviousArguments = $env:WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS
$PreviousUserData = $env:WEBVIEW2_USER_DATA_FOLDER
$TargetRoot = Join-Path $env:TEMP ("lmm-v107-csp-target-" + [Guid]::NewGuid().ToString("N"))
$WebViewRoot = Join-Path $env:TEMP ("lmm-v107-csp-webview-" + [Guid]::NewGuid().ToString("N"))
$StateBackup = Join-Path $env:TEMP ("lmm-v107-csp-user-state-" + [Guid]::NewGuid().ToString("N"))
$CandidateConfig = Join-Path $AppRoot ("src-tauri\.v107-csp-candidate-" + [Guid]::NewGuid().ToString("N") + ".json")
$UserDirectory = Join-Path $env:APPDATA "io.letsmakemoney.windows"
$ProtectedNames = @("config.json", "debug.log", "overtime-records.json")
$ProtectedState = @{}
$Process = $null

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $env:TEMP ("lmm-v107-csp-" + [DateTime]::UtcNow.ToString("yyyyMMddTHHmmssZ") + ".json")
}

function Get-FreeTcpPort {
    $Listener = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, 0)
    $Listener.Start()
    try { return ([Net.IPEndPoint]$Listener.LocalEndpoint).Port }
    finally { $Listener.Stop() }
}

function Get-CdpTargets([int]$Port) {
    try { return @(Invoke-RestMethod -Uri "http://127.0.0.1:$Port/json" -TimeoutSec 1) }
    catch { return @() }
}

function Wait-CdpTarget([int]$Port, [string]$WindowName, [int]$TimeoutSeconds = 20) {
    $Deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    do {
        $Target = Get-CdpTargets -Port $Port |
            Where-Object { $_.type -eq "page" -and $_.url -like "*window=$WindowName*" } |
            Select-Object -First 1
        if ($Target) { return $Target }
        Start-Sleep -Milliseconds 100
    } while ((Get-Date) -lt $Deadline)
    throw "Timed out waiting for the $WindowName WebView target."
}

function Invoke-CdpExpression([string]$WebSocketUrl, [string]$Expression) {
    $Encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Expression))
    $LastFailure = "unknown CDP failure"
    for ($Attempt = 1; $Attempt -le 20; $Attempt++) {
        $PreviousPreference = $ErrorActionPreference
        try {
            $ErrorActionPreference = "Continue"
            $Raw = & $Node $Probe $WebSocketUrl evaluate $Encoded 2>&1
        }
        finally { $ErrorActionPreference = $PreviousPreference }
        if ($LASTEXITCODE -eq 0) { return $Raw | ConvertFrom-Json }
        $FailureText = (($Raw | Out-String).Trim() -replace "[\r\n]+", " ")
        if (-not [string]::IsNullOrWhiteSpace($FailureText)) {
            $LastFailure = $FailureText.Substring(0, [Math]::Min(300, $FailureText.Length))
        }
        Start-Sleep -Milliseconds 100
    }
    throw "CDP evaluation failed after 20 attempts: $LastFailure"
}

function Get-WindowProbe([int]$Port, [string]$WindowName) {
    $Target = Wait-CdpTarget -Port $Port -WindowName $WindowName
    $Socket = ([string]$Target.webSocketDebuggerUrl) -replace "localhost", "127.0.0.1"
    $Expression = @"
(async () => {
  await new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve)));
  const text = document.body?.innerText ?? "";
  return {
    window: "$WindowName",
    ready: document.readyState === "complete",
    theme_ready: document.documentElement.dataset.themeReady === "true",
    tauri_bridge_ready: typeof window.__TAURI_INTERNALS__?.invoke === "function",
    body_text_length: text.length,
    image_count: document.images.length,
    stylesheet_count: document.styleSheets.length
  };
})()
"@
    return [pscustomobject]@{ Socket = $Socket; Result = (Invoke-CdpExpression -WebSocketUrl $Socket -Expression $Expression) }
}

try {
    New-Item -ItemType Directory -Force -Path $StateBackup, $UserDirectory, $WebViewRoot | Out-Null
    foreach ($Name in $ProtectedNames) {
        $Path = Join-Path $UserDirectory $Name
        $Exists = Test-Path -LiteralPath $Path -PathType Leaf
        $ProtectedState[$Name] = $Exists
        if ($Exists) { Copy-Item -LiteralPath $Path -Destination (Join-Path $StateBackup $Name) -Force }
    }
    Copy-Item -LiteralPath $ConfigFixture -Destination (Join-Path $UserDirectory "config.json") -Force

    if (-not $SkipBuild) {
        $env:PATH = "$NodeDirectory;$CargoDirectory;$PreviousPath"
        $env:CARGO_TARGET_DIR = $TargetRoot
        # Tauri code generation needs a complete config file here; a partial
        # overlay can build successfully while embedding an empty document.
        $CandidateDocument = Get-Content -LiteralPath $BaseConfig -Raw -Encoding UTF8 | ConvertFrom-Json
        $CandidateCsp = (Get-Content -LiteralPath $Fixture -Raw -Encoding UTF8 | ConvertFrom-Json).app.security.csp
        $CandidateDocument.app.security.csp = $CandidateCsp
        [IO.File]::WriteAllText(
            $CandidateConfig,
            ($CandidateDocument | ConvertTo-Json -Depth 100),
            [Text.UTF8Encoding]::new($false)
        )
        & (Join-Path $AppRoot "node_modules\.bin\tauri.cmd") build `
            --config $CandidateConfig `
            --no-bundle `
            --ci
        if ($LASTEXITCODE -ne 0) { throw "CSP candidate build failed with exit code $LASTEXITCODE" }
        $CandidateExe = Join-Path $TargetRoot "release\letsmakemoney_windows_v1.exe"
    }
    if (-not (Test-Path -LiteralPath $CandidateExe -PathType Leaf)) {
        throw "CSP candidate EXE is missing: $CandidateExe"
    }

    $Port = Get-FreeTcpPort
    $env:WEBVIEW2_USER_DATA_FOLDER = $WebViewRoot
    $env:WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS = "--remote-debugging-port=$Port"
    $Process = Start-Process -FilePath $CandidateExe -WindowStyle Hidden -PassThru
    Write-Host "Probing Mini window..."
    $MiniProbe = Get-WindowProbe -Port $Port -WindowName "mini"
    $MiniSocket = $MiniProbe.Socket

    $IpcExpression = @'
(async () => {
  const invoke = window.__TAURI_INTERNALS__.invoke;
  const results = {};
  const check = async (name, action) => {
    try {
      const value = await action();
      results[name] = { ok: true, value_type: value === null ? "null" : typeof value };
    } catch (error) {
      results[name] = { ok: false, error_name: error?.name ?? "Error" };
    }
  };
  await check("read_configuration", () => invoke("read_configuration"));
  await check("platform_capabilities", () => invoke("platform_capabilities"));
  await check("load_calendar_year", () => invoke("load_calendar_year", { year: 2026 }));
  await check("read_overtime_month", () => invoke("read_overtime_month", { month: "2026-08" }));
  await check("diagnostic_summary", () => invoke("diagnostic_summary"));
  await check("evaluate_update_response", () => invoke("evaluate_update_response", {
    currentVersion: "1.0.7",
    responseBody: null,
    failureReason: "controlled-csp-probe"
  }));
  await check("record_semantic_event", () => invoke("record_semantic_event", {
    event: "csp.probe",
    detail: "result=ipc_ready"
  }));
  try {
    const response = await fetch("https://api.github.com/repos/NzyZzz1998/LetsMakeMoney/releases/latest", {
      headers: { Accept: "application/vnd.github+json" }
    });
    results.github_update_query = { ok: response.ok, status: response.status };
  } catch (error) {
    results.github_update_query = { ok: false, error_name: error?.name ?? "Error" };
  }
  return results;
})()
'@
    $Windows = [Collections.Generic.List[object]]::new()
    $Windows.Add($MiniProbe.Result)
    $ProbeFailure = $null
    $IpcResults = [pscustomobject]@{}
    if (-not [bool]$MiniProbe.Result.tauri_bridge_ready -or [int]$MiniProbe.Result.body_text_length -le 20) {
        $ProbeFailure = "mini_bootstrap_unavailable"
        $IpcResults = [pscustomobject]@{
            probe = [pscustomobject]@{ ok = $false; error_name = "bootstrap_unavailable" }
        }
    }
    else {
        try {
            Write-Host "Probing IPC and update query..."
            $IpcResults = Invoke-CdpExpression -WebSocketUrl $MiniSocket -Expression $IpcExpression
            foreach ($Label in @("workbench", "settings", "wizard")) {
                Write-Host "Probing $Label window..."
                $Show = "window.__TAURI_INTERNALS__.invoke('show_app_window', { label: '$Label' })"
                [void](Invoke-CdpExpression -WebSocketUrl $MiniSocket -Expression $Show)
                $WindowProbe = Get-WindowProbe -Port $Port -WindowName $Label
                $Windows.Add($WindowProbe.Result)
                $Hide = "window.__TAURI_INTERNALS__.invoke('hide_app_window', { label: '$Label' })"
                [void](Invoke-CdpExpression -WebSocketUrl $MiniSocket -Expression $Hide)
            }
        }
        catch {
            $ProbeFailure = "ipc_or_window_probe_failed"
            $IpcResults = [pscustomobject]@{
                probe = [pscustomobject]@{ ok = $false; error_name = "cdp_evaluation_failed" }
            }
        }
    }

    $AllIpcReady = $null -eq $ProbeFailure -and @($IpcResults.psobject.Properties.Value | ForEach-Object { [bool]$_.ok }) -notcontains $false
    $AllWindowsReady = $Windows.Count -eq 4 -and @($Windows | ForEach-Object { [bool]$_.ready -and [bool]$_.theme_ready -and [bool]$_.tauri_bridge_ready -and [int]$_.body_text_length -gt 20 }) -notcontains $false
    $Document = [ordered]@{
        schema_version = 1
        milestone = "V107-M6"
        candidate = [ordered]@{
            size = (Get-Item -LiteralPath $CandidateExe).Length
            sha256 = (Get-FileHash -LiteralPath $CandidateExe -Algorithm SHA256).Hash
            source_head = (git -C $RepoRoot rev-parse HEAD).Trim()
            source_tree_dirty = [bool](git -C $RepoRoot status --short)
        }
        csp = (Get-Content -LiteralPath $Fixture -Raw -Encoding UTF8 | ConvertFrom-Json).app.security.csp
        windows = @($Windows)
        ipc = $IpcResults
        result = [ordered]@{
            windows_ready = $AllWindowsReady
            ipc_and_update_ready = $AllIpcReady
            passed = $AllWindowsReady -and $AllIpcReady
            failure_code = $ProbeFailure
        }
        raw_evidence = [ordered]@{ availability = "external"; logical_id = "V107-M6-CSP-RAW" }
    }
    $OutputDirectory = Split-Path -Parent $OutputPath
    if ($OutputDirectory) { New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null }
    [IO.File]::WriteAllText($OutputPath, ($Document | ConvertTo-Json -Depth 20), [Text.UTF8Encoding]::new($false))
    if (-not $Document.result.passed) { throw "CSP candidate regression failed; see $OutputPath" }
    Write-Host "PASS v1.0.7 isolated CSP candidate: $OutputPath" -ForegroundColor Green
}
finally {
    if ($Process) { Stop-Process -Id $Process.Id -Force -ErrorAction SilentlyContinue }
    Get-Process -Name "letsmakemoney_windows_v1" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    foreach ($Name in $ProtectedNames) {
        $Path = Join-Path $UserDirectory $Name
        if ($ProtectedState[$Name]) {
            Copy-Item -LiteralPath (Join-Path $StateBackup $Name) -Destination $Path -Force
        } elseif (Test-Path -LiteralPath $Path) {
            Remove-Item -LiteralPath $Path -Force
        }
    }
    $env:PATH = $PreviousPath
    $env:CARGO_TARGET_DIR = $PreviousTarget
    $env:WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS = $PreviousArguments
    $env:WEBVIEW2_USER_DATA_FOLDER = $PreviousUserData
    if (Test-Path -LiteralPath $CandidateConfig) { Remove-Item -LiteralPath $CandidateConfig -Force -ErrorAction SilentlyContinue }
    if (Test-Path -LiteralPath $StateBackup) { Remove-Item -LiteralPath $StateBackup -Recurse -Force -ErrorAction SilentlyContinue }
    if (-not $KeepCandidate) {
        if (Test-Path -LiteralPath $TargetRoot) { Remove-Item -LiteralPath $TargetRoot -Recurse -Force -ErrorAction SilentlyContinue }
        if (Test-Path -LiteralPath $WebViewRoot) { Remove-Item -LiteralPath $WebViewRoot -Recurse -Force -ErrorAction SilentlyContinue }
    }
}
