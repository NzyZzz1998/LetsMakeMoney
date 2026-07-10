param(
    [string]$ExePath = "",
    [int]$Rounds = 10
)

$ErrorActionPreference = "Stop"
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
if (-not $ExePath) { $ExePath = Join-Path $projectRoot "build\LetsMakeMoney.exe" }
if (-not (Test-Path -LiteralPath $ExePath)) { throw "LetsMakeMoney executable not found: $ExePath" }

if (-not ("LmmTrayVerification.Native" -as [type])) {
    Add-Type -TypeDefinition @"
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;
namespace LmmTrayVerification {
  public static class Native {
    public delegate bool EnumWindowsProc(IntPtr hwnd, IntPtr lParam);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern IntPtr FindWindow(string cls, string title);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern IntPtr FindWindowEx(IntPtr parent, IntPtr childAfter, string cls, string title);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr hwnd, uint msg, IntPtr wParam, IntPtr lParam);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hwnd);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc callback, IntPtr lParam);
    [DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr parent, EnumWindowsProc callback, IntPtr lParam);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassName(IntPtr hwnd, StringBuilder name, int maxCount);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hwnd, out uint processId);
    [DllImport("user32.dll")] public static extern int GetWindowLong(IntPtr hwnd, int index);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hwnd, out RECT rect);
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
    public static IntPtr FindLargestWindow(uint pid) {
      IntPtr best = IntPtr.Zero; long bestArea = -1;
      EnumWindows((hwnd, unused) => {
        uint owner; GetWindowThreadProcessId(hwnd, out owner);
        if (owner != pid) return true;
        RECT rect; if (!GetWindowRect(hwnd, out rect)) return true;
        long area = Math.Max(0, rect.Right - rect.Left) * (long)Math.Max(0, rect.Bottom - rect.Top);
        if (area > bestArea) { bestArea = area; best = hwnd; }
        return true;
      }, IntPtr.Zero);
      return best;
    }
    public static IntPtr FindMessageWindow(string className) {
      IntPtr direct = FindWindowEx(new IntPtr(-3), IntPtr.Zero, className, null);
      if (direct != IntPtr.Zero) return direct;
      IntPtr found = IntPtr.Zero;
      EnumChildWindows(new IntPtr(-3), (hwnd, unused) => {
        var text = new StringBuilder(256);
        GetClassName(hwnd, text, text.Capacity);
        if (text.ToString() == className) { found = hwnd; return false; }
        return true;
      }, IntPtr.Zero);
      return found;
    }
    public static IntPtr FindProcessClassWindow(uint pid, string className) {
      IntPtr found = IntPtr.Zero;
      EnumWindows((hwnd, unused) => {
        uint owner; GetWindowThreadProcessId(hwnd, out owner);
        if (owner != pid) return true;
        var text = new StringBuilder(256);
        GetClassName(hwnd, text, text.Capacity);
        if (text.ToString() == className) { found = hwnd; return false; }
        return true;
      }, IntPtr.Zero);
      return found;
    }
  }
}
"@
}

function Wait-Until {
    param([scriptblock]$Condition, [int]$TimeoutMs = 8000, [string]$Failure)
    $watch = [Diagnostics.Stopwatch]::StartNew()
    while ($watch.ElapsedMilliseconds -lt $TimeoutMs) {
        if (& $Condition) { return }
        Start-Sleep -Milliseconds 100
    }
    throw $Failure
}

function Write-TestConfig {
    param([string]$Root, [bool]$PurePetMode)
    $dir = Join-Path $Root "LetsMakeMoney"
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    @{
        monthly_salary = 12000
        config_version = 3
        rest_mode = "double"
        work_hours_per_day = 8.0
        work_start_time = "09:00"
        work_end_time = "18:00"
        pet_id = "cat_orange_v2"
        window_mode = "top"
        debug_mode = $false
        auto_start = $false
        minimize_to_tray = $true
        native_integration_enabled = $true
        system_tray_enabled = $true
        mouse_passthrough_enabled = $true
        transparent_pet_window_enabled = $true
        pure_pet_mode = $PurePetMode
        opacity = 1.0
        scale = 1.0
    } | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $dir "config.json") -Encoding UTF8
}

function Invoke-TrayModeVerification {
    param([bool]$PurePetMode)
    $modeName = if ($PurePetMode) { "pure" } else { "normal" }
    $appDataRoot = Join-Path $projectRoot ".tmp_appdata\verify_v06_tray_$modeName"
    if (Test-Path -LiteralPath $appDataRoot) { Remove-Item -LiteralPath $appDataRoot -Recurse -Force }
    Write-TestConfig -Root $appDataRoot -PurePetMode $PurePetMode
    $oldAppData = $env:APPDATA
    $process = $null
    try {
        $env:APPDATA = $appDataRoot
        $process = Start-Process -FilePath $ExePath -PassThru
        Wait-Until -Failure "Tray message window was not created ($modeName)." -Condition {
            [LmmTrayVerification.Native]::FindProcessClassWindow([uint32]$process.Id, "LetsMakeMoneyTrayMessageWindow") -ne [IntPtr]::Zero
        }
        $trayHwnd = [LmmTrayVerification.Native]::FindProcessClassWindow([uint32]$process.Id, "LetsMakeMoneyTrayMessageWindow")
        $logPath = Join-Path $appDataRoot "LetsMakeMoney\debug.log"
        Wait-Until -Failure "Pet host window was not logged ($modeName)." -Condition {
            (Test-Path -LiteralPath $logPath) -and ((Get-Content -LiteralPath $logPath -Raw -Encoding UTF8) -match 'setup_pet_window hwnd=(\d+)')
        }
        $startupLog = Get-Content -LiteralPath $logPath -Raw -Encoding UTF8
        $hostMatch = [regex]::Match($startupLog, 'setup_pet_window hwnd=(\d+)')
        $hostHwnd = [IntPtr]([int64]$hostMatch.Groups[1].Value)
        for ($round = 1; $round -le $Rounds; $round++) {
            if (-not [LmmTrayVerification.Native]::PostMessage($trayHwnd, 0x8065, [IntPtr]1, [IntPtr]0x0202)) {
                throw "PostMessage hide failed ($modeName round $round)."
            }
            Start-Sleep -Milliseconds 550
            if ([LmmTrayVerification.Native]::IsWindowVisible($hostHwnd)) {
                throw "Window remained visible after tray hide ($modeName round $round)."
            }
            if (-not [LmmTrayVerification.Native]::PostMessage($trayHwnd, 0x8065, [IntPtr]1, [IntPtr]0x0202)) {
                throw "PostMessage restore failed ($modeName round $round)."
            }
            Start-Sleep -Milliseconds 550
            if (-not [LmmTrayVerification.Native]::IsWindowVisible($hostHwnd)) {
                throw "Window did not restore after tray toggle ($modeName round $round)."
            }
            $exStyle = [LmmTrayVerification.Native]::GetWindowLong($hostHwnd, -20)
            $hasToolWindow = ($exStyle -band 0x80) -ne 0
            $hasAppWindow = ($exStyle -band 0x40000) -ne 0
            if ($PurePetMode -and (-not $hasToolWindow -or $hasAppWindow)) {
                throw "Pure pet taskbar policy was not restored (round $round, style=$exStyle)."
            }
            if (-not $PurePetMode -and $hasToolWindow) {
                throw "Normal mode unexpectedly kept tool-window taskbar policy (round $round, style=$exStyle)."
            }
        }
        Wait-Until -Failure "debug.log missing after tray verification ($modeName)." -Condition { Test-Path -LiteralPath $logPath }
        $log = Get-Content -LiteralPath $logPath -Raw -Encoding UTF8
        $requested = ([regex]::Matches($log, "tray_left_toggle_requested:")).Count
        $results = ([regex]::Matches($log, "tray_left_toggle_result:")).Count
        $policies = ([regex]::Matches($log, "window_policy_reapplied:")).Count
        $expected = $Rounds * 2
        if ($requested -ne $expected -or $results -ne $expected) {
            throw "Tray semantic log mismatch ($modeName): requested=$requested result=$results expected=$expected."
        }
        if ($policies -lt $Rounds) {
            throw "Window policy logs missing ($modeName): $policies."
        }
        Write-Host "Tray mode $modeName passed: $Rounds rounds."
    } finally {
        if ($process -and -not $process.HasExited) {
            Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
            $process.WaitForExit(5000) | Out-Null
        }
        $env:APPDATA = $oldAppData
    }
}

Invoke-TrayModeVerification -PurePetMode $false
Invoke-TrayModeVerification -PurePetMode $true
Write-Host "v0.6 tray verification passed"
