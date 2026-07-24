$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Executable = Get-ChildItem -LiteralPath (Join-Path $ProjectRoot "bin") -Filter "LmmWinUiSpike.exe" -Recurse |
    Where-Object { $_.DirectoryName -match '[\\/]publish$' } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if ($null -eq $Executable) {
    throw "WINUI_RUNTIME_SMOKE_FAILED: published executable not found."
}

$Process = Start-Process -FilePath $Executable.FullName -PassThru
try {
    Start-Sleep -Seconds 5
    $Process.Refresh()
    if ($Process.HasExited) {
        throw "WINUI_RUNTIME_SMOKE_FAILED: process exited with code $($Process.ExitCode)."
    }
    if ($Process.MainWindowHandle -eq 0) {
        throw "WINUI_RUNTIME_SMOKE_FAILED: no visible main window."
    }
    Write-Host "WINUI_RUNTIME_SMOKE_OK: $($Process.MainWindowTitle)"
}
finally {
    if (-not $Process.HasExited) {
        taskkill /PID $Process.Id /F | Out-Null
    }
}
