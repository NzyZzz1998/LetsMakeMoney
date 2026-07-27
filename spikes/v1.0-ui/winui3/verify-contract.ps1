$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Xaml = Get-Content -LiteralPath (Join-Path $ProjectRoot "MainWindow.xaml") -Raw -Encoding UTF8
$Code = Get-Content -LiteralPath (Join-Path $ProjectRoot "MainWindow.xaml.cs") -Raw -Encoding UTF8
$Tray = Get-Content -LiteralPath (Join-Path $ProjectRoot "TrayIconService.cs") -Raw -Encoding UTF8
$Project = [xml](Get-Content -LiteralPath (Join-Path $ProjectRoot "LmmWinUiSpike.csproj") -Raw -Encoding UTF8)

$Required = @(
    'x:Name="MiniView"',
    'x:Name="WorkbenchView"',
    'x:Name="SettingsView"',
    'x:Name="SalaryInput"',
    'x:Name="FailureToggle"',
    'x:Name="FeedbackText"',
    "SaveSettings_Click",
    "File.WriteAllTextAsync",
    "File.Move",
    "ResizeClientDip(344, 120)",
    "ResizeClientDip(820, 620)",
    "ResizeClientDip(720, 540)",
    "ShellNotifyIcon",
    "WmLeftButtonUp",
    "TrackPopupMenu"
)

$Combined = "$Xaml`n$Code`n$Tray"
$Missing = @($Required | Where-Object { -not $Combined.Contains($_) })
if ($Missing.Count -gt 0) {
    throw "WINUI_SPIKE_VERIFY_FAILED: $($Missing -join ', ')"
}
if ($Project.Project.PropertyGroup.WindowsPackageType -ne "None") {
    throw "WinUI spike must remain unpackaged."
}
Write-Host "WINUI_SPIKE_VERIFY_OK"
