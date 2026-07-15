$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$target = Join-Path $root 'apple\App\Features\Today\TodayView.swift'
$backup = "$target.m3-test"

Push-Location $root
try {
    & (Join-Path $PSScriptRoot 'check_ios_m3.ps1') -RequireSwift
    if ($LASTEXITCODE -ne 0) { throw 'M3 positive gate failed.' }

    Move-Item -LiteralPath $target -Destination $backup
    try {
        $gate = Join-Path $PSScriptRoot 'check_ios_m3.ps1'
        & cmd.exe /d /c "powershell -NoProfile -ExecutionPolicy Bypass -File `"$gate`" -RequireSwift >nul 2>&1"
        $mutationExit = $LASTEXITCODE
        if ($mutationExit -eq 0) { throw 'Missing SwiftUI feature mutation was not rejected.' }
    } finally {
        Move-Item -LiteralPath $backup -Destination $target -Force
    }

    & (Join-Path $PSScriptRoot 'check_ios_m3.ps1') -RequireSwift
    if ($LASTEXITCODE -ne 0) { throw 'M3 gate did not recover after mutation.' }
    Write-Host 'IOS_M3_MUTATION_PASS'
} finally {
    if (Test-Path -LiteralPath $backup) {
        Move-Item -LiteralPath $backup -Destination $target -Force
    }
    Pop-Location
}
