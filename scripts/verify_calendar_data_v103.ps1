param(
    [string]$CalendarRoot = ""
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$app = Join-Path $root "apps\windows-v1"
. (Join-Path $PSScriptRoot "v10_tools.ps1")
$python = Get-V10Python

if (-not $CalendarRoot) {
    $CalendarRoot = Join-Path $app "calendar-data"
}
$CalendarRoot = [IO.Path]::GetFullPath($CalendarRoot)

& $python (Join-Path $app "tests\verify_calendar_data_v103.py") `
    --calendar-root $CalendarRoot `
    --contracts-root (Join-Path $app "contracts")
if ($LASTEXITCODE -ne 0) {
    throw "v1.0.3 calendar data verification failed."
}

if ($CalendarRoot -eq [IO.Path]::GetFullPath((Join-Path $app "calendar-data"))) {
    & $python (Join-Path $app "tests\verify_calendar_data_v103_tests.py")
    if ($LASTEXITCODE -ne 0) {
        throw "v1.0.3 calendar data negative tests failed."
    }
}

Write-Host "v1.0.3 calendar data verification passed." -ForegroundColor Green
