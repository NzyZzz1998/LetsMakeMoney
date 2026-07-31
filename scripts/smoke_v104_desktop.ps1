param(
    [Parameter(Mandatory = $true)]
    [string]$PackagePath,
    [ValidateSet("FirstRun", "Configured")]
    [string]$Mode = "FirstRun",
    [switch]$Interactive,
    [string]$EvidenceOutput = ""
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$expectedZipName = "LetsMakeMoney-v1.0.4-windows-x86_64.zip"
$expectedPayloadName = "LetsMakeMoney-v1.0.4-windows-x86_64"
$startedAt = [DateTime]::UtcNow
$runId = "LMM-V104-SMOKE-" + $startedAt.ToString("yyyyMMddHHmmss")
$smokeRoot = Join-Path $root ".tmp_v104_desktop_smoke"
$runRoot = Join-Path $smokeRoot $runId
$extractRoot = Join-Path $runRoot "runtime"
$backupRoot = Join-Path $runRoot "backup"
$backupData = Join-Path $backupRoot "app-data"
$appDataParent = [IO.Path]::GetFullPath($env:APPDATA)
$appDataPath = [IO.Path]::GetFullPath((Join-Path $appDataParent "io.letsmakemoney.windows"))
$process = $null
$exePath = $null
$result = $null
$originalDataExisted = Test-Path -LiteralPath $appDataPath -PathType Container
$originalDataDigest = $null
$forcedCleanup = $false
$normalExit = $false
$observed = [ordered]@{
    first_window = $false
    mini = $false
    workbench = $false
    settings = $false
    wizard = $false
    tray_recovery = $false
}

if ([string]::IsNullOrWhiteSpace($EvidenceOutput)) {
    $EvidenceOutput = Join-Path $root "doc\releases\v1.0.4\evidence\desktop-smoke-latest.json"
}
$EvidenceOutput = [IO.Path]::GetFullPath($EvidenceOutput)

Add-Type -TypeDefinition @"
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;

public sealed class LmmWindowRecord
{
    public long Handle { get; set; }
    public string Title { get; set; }
}

public static class LmmWindowProbe
{
    private delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    [DllImport("user32.dll")]
    private static extern bool EnumWindows(EnumWindowsProc callback, IntPtr lParam);

    [DllImport("user32.dll")]
    private static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);

    [DllImport("user32.dll")]
    private static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    private static extern int GetWindowTextLength(IntPtr hWnd);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    private static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int maxCount);

    public static LmmWindowRecord[] Find(int processId)
    {
        var result = new List<LmmWindowRecord>();
        EnumWindows(delegate(IntPtr hWnd, IntPtr lParam)
        {
            uint ownerProcessId;
            GetWindowThreadProcessId(hWnd, out ownerProcessId);
            if (ownerProcessId != (uint)processId || !IsWindowVisible(hWnd))
            {
                return true;
            }

            var length = GetWindowTextLength(hWnd);
            var text = new StringBuilder(length + 1);
            GetWindowText(hWnd, text, text.Capacity);
            result.Add(new LmmWindowRecord
            {
                Handle = hWnd.ToInt64(),
                Title = text.ToString()
            });
            return true;
        }, IntPtr.Zero);
        return result.ToArray();
    }
}
"@

function Assert-ChildPath([string]$Path, [string]$Parent, [string]$Description) {
    $resolvedParent = [IO.Path]::GetFullPath($Parent).TrimEnd('\') + '\'
    $resolvedPath = [IO.Path]::GetFullPath($Path)
    if (-not $resolvedPath.StartsWith($resolvedParent, [StringComparison]::OrdinalIgnoreCase)) {
        throw "$Description is outside the approved parent: $resolvedPath"
    }
    return $resolvedPath
}

function Remove-ApprovedItem([string]$Path, [string]$Parent, [string]$Description) {
    if (-not (Test-Path -LiteralPath $Path)) { return }
    $resolvedPath = Assert-ChildPath $Path $Parent $Description
    Remove-Item -LiteralPath $resolvedPath -Recurse -Force
}

function Get-DirectoryDigest([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        return $null
    }
    $resolvedRoot = [IO.Path]::GetFullPath($Path).TrimEnd('\')
    $rows = @(Get-ChildItem -LiteralPath $resolvedRoot -Recurse -File | Sort-Object FullName | ForEach-Object {
        $relativePath = $_.FullName.Substring($resolvedRoot.Length).TrimStart('\')
        $hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
        "$relativePath`t$($_.Length)`t$hash"
    })
    $bytes = [Text.Encoding]::UTF8.GetBytes(($rows -join "`n"))
    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($sha256.ComputeHash($bytes))).Replace("-", "")
    }
    finally {
        $sha256.Dispose()
    }
}

function ConvertFrom-CodePoints([int[]]$CodePoints) {
    return -join @($CodePoints | ForEach-Object { [char]$_ })
}

function Get-LmmWindows([int]$ProcessId) {
    return @([LmmWindowProbe]::Find($ProcessId))
}

function Observe-Phase([string]$Phase) {
    $windows = @(Get-LmmWindows $process.Id)
    if ($windows.Count -gt 0) {
        $observed.first_window = $true
    }
    $workbenchMarker = ConvertFrom-CodePoints @(0x4ECA, 0x65E5, 0x5DE5, 0x4F5C, 0x53F0)
    $settingsMarker = ConvertFrom-CodePoints @(0x8BBE, 0x7F6E)
    $wizardMarker = ConvertFrom-CodePoints @(0x5F00, 0x59CB, 0x914D, 0x7F6E)
    foreach ($window in $windows) {
        if ($window.Title -eq "LetsMakeMoney") {
            $observed.mini = $true
        }
        if ($window.Title.Contains($workbenchMarker)) {
            $observed.workbench = $true
        }
        if ($window.Title.Contains($settingsMarker)) {
            $observed.settings = $true
        }
        if ($window.Title.Contains($wizardMarker)) {
            $observed.wizard = $true
        }
    }
    Write-Host "Observed phase '$Phase': $($windows.Count) primary window(s)."
}

$PackagePath = [IO.Path]::GetFullPath($PackagePath)
if (-not (Test-Path -LiteralPath $PackagePath -PathType Leaf)) {
    throw "Candidate package does not exist: $PackagePath"
}
if ([IO.Path]::GetFileName($PackagePath) -ne $expectedZipName) {
    throw "Desktop smoke only accepts $expectedZipName."
}

$resolvedSmokeRoot = Assert-ChildPath $smokeRoot $root "smoke root"
$resolvedRunRoot = Assert-ChildPath $runRoot $resolvedSmokeRoot "smoke run directory"
$resolvedDataPath = Assert-ChildPath $appDataPath $appDataParent "LetsMakeMoney application data"
$runRootPrefix = $resolvedRunRoot.TrimEnd('\') + '\'
if ($EvidenceOutput -eq $resolvedRunRoot -or
    $EvidenceOutput.StartsWith($runRootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Evidence output cannot be inside the temporary smoke run directory."
}
if ((Split-Path -Leaf $resolvedDataPath) -ne "io.letsmakemoney.windows") {
    throw "Unexpected LetsMakeMoney data directory name."
}

$existing = @(Get-Process -Name "LetsMakeMoney" -ErrorAction SilentlyContinue)
if ($existing.Count -gt 0) {
    throw "An existing LetsMakeMoney process is running. Exit it before the smoke test."
}

New-Item -ItemType Directory -Path $extractRoot -Force | Out-Null
New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null

try {
    if ($originalDataExisted) {
        $originalDataDigest = Get-DirectoryDigest $appDataPath
        Copy-Item -LiteralPath $appDataPath -Destination $backupData -Recurse
    }
    if ($Mode -eq "FirstRun") {
        Remove-ApprovedItem $appDataPath $appDataParent "test application data"
    }

    Expand-Archive -LiteralPath $PackagePath -DestinationPath $extractRoot
    $payloads = @(Get-ChildItem -LiteralPath $extractRoot -Directory)
    if ($payloads.Count -ne 1 -or $payloads[0].Name -ne $expectedPayloadName) {
        throw "The candidate package root is invalid."
    }
    $exePath = Join-Path $payloads[0].FullName "LetsMakeMoney.exe"
    if (-not (Test-Path -LiteralPath $exePath -PathType Leaf)) {
        throw "Candidate EXE is missing."
    }

    $process = Start-Process -FilePath $exePath -WorkingDirectory $payloads[0].FullName -PassThru
    $deadline = [DateTime]::UtcNow.AddSeconds(20)
    do {
        Start-Sleep -Milliseconds 250
        $process.Refresh()
        if ($process.HasExited) {
            throw "Candidate exited before presenting a window."
        }
        Observe-Phase "startup"
    } while (-not $observed.first_window -and [DateTime]::UtcNow -lt $deadline)
    if (-not $observed.first_window) {
        throw "Candidate did not present a primary window within 20 seconds."
    }

    if ($Interactive) {
        Write-Host ""
        Write-Host "Computer Use / manual smoke sequence:" -ForegroundColor Cyan
        Write-Host "1. Confirm the visible Mini or first-run Wizard, then press Enter."
        [void](Read-Host)
        Observe-Phase "initial"
        Write-Host "2. Open Workbench, keep it focused, then press Enter."
        [void](Read-Host)
        Observe-Phase "workbench"
        Write-Host "3. Open Settings, keep it focused, then press Enter."
        [void](Read-Host)
        Observe-Phase "settings"
        Write-Host "4. Open/reopen Wizard, keep it focused, then press Enter."
        [void](Read-Host)
        Observe-Phase "wizard"
        Write-Host "5. Hide and recover Mini from the real Windows notification area."
        Write-Host "   Type PASS only after recovery; any other value records failure."
        $trayResult = Read-Host
        $observed.tray_recovery = $trayResult.Trim().ToUpperInvariant() -eq "PASS"
        Write-Host "6. Exit from the tray menu, then press Enter."
        [void](Read-Host)
        Start-Sleep -Seconds 1
        $process.Refresh()
        $normalExit = $process.HasExited
        if (-not $normalExit) {
            throw "The process is still running after the requested tray exit."
        }
    }

    $result = if ($Interactive -and $normalExit -and -not ($observed.Values -contains $false)) {
        "passed"
    } elseif ($observed.first_window) {
        "partial"
    } else {
        "failed"
    }
}
finally {
    if ($process) {
        $process.Refresh()
        if (-not $process.HasExited) {
            Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
            $forcedCleanup = $true
            $process.WaitForExit(5000)
        }
    }

    Remove-ApprovedItem $appDataPath $appDataParent "test application data"
    if ($originalDataExisted -and (Test-Path -LiteralPath $backupData -PathType Container)) {
        Copy-Item -LiteralPath $backupData -Destination $appDataPath -Recurse
    }

    $restored = if ($originalDataExisted) {
        (Test-Path -LiteralPath $appDataPath -PathType Container) -and
            ((Get-DirectoryDigest $appDataPath) -eq $originalDataDigest)
    } else {
        -not (Test-Path -LiteralPath $appDataPath)
    }
    $remaining = @(Get-Process -Name "LetsMakeMoney" -ErrorAction SilentlyContinue)

    $evidence = [ordered]@{
        schema_version = "1.0"
        run_id = $runId
        package = [ordered]@{
            name = [IO.Path]::GetFileName($PackagePath)
            size = (Get-Item -LiteralPath $PackagePath).Length
            sha256 = (Get-FileHash -LiteralPath $PackagePath -Algorithm SHA256).Hash
        }
        executable = [ordered]@{
            name = "LetsMakeMoney.exe"
            size = if ($exePath -and (Test-Path -LiteralPath $exePath)) {
                (Get-Item -LiteralPath $exePath).Length
            } else { 0 }
            sha256 = if ($exePath -and (Test-Path -LiteralPath $exePath)) {
                (Get-FileHash -LiteralPath $exePath -Algorithm SHA256).Hash
            } else { $null }
        }
        mode = $Mode
        interactive = [bool]$Interactive
        result = if ($result) { $result } else { "failed" }
        observed = $observed
        normal_exit = $normalExit
        forced_cleanup = $forcedCleanup
        environment_restored = $restored
        environment_restored_exact = $restored
        residual_process_count = $remaining.Count
        started_at = $startedAt.ToString("o")
        finished_at = [DateTime]::UtcNow.ToString("o")
        privacy = "No user path, configuration value, salary, raw log line, or window title is retained."
    }
    $evidenceParent = Split-Path -Parent $EvidenceOutput
    New-Item -ItemType Directory -Path $evidenceParent -Force | Out-Null
    $evidence | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $EvidenceOutput -Encoding UTF8

    Remove-ApprovedItem $runRoot $resolvedSmokeRoot "smoke run directory"

    if (-not $restored) {
        throw "LetsMakeMoney application data was not restored."
    }
    if ($remaining.Count -gt 0) {
        throw "LetsMakeMoney process remained after smoke cleanup."
    }
}

Write-Host "Desktop smoke result: $result"
Write-Host "Evidence: $EvidenceOutput"
