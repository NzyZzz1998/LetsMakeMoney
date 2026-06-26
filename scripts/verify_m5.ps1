param(
    [string]$GodotExe = "",
    [string]$OutputPath = ""
)

$ErrorActionPreference = "Stop"

function Resolve-GodotExe {
    param([string]$ExplicitPath)

    if ($ExplicitPath -and (Test-Path -LiteralPath $ExplicitPath)) {
        return (Resolve-Path -LiteralPath $ExplicitPath).Path
    }

    $commands = @("godot", "godot4", "Godot_v4.7-stable_win64_console")
    foreach ($command in $commands) {
        $resolved = Get-Command $command -ErrorAction SilentlyContinue
        if ($resolved) {
            return $resolved.Source
        }
    }

    $candidateRoots = @(
        "$env:LMM_GODOT_ROOT",
        "$env:USERPROFILE\Desktop",
        "$env:USERPROFILE\Downloads",
        "$env:ProgramFiles",
        "${env:ProgramFiles(x86)}"
    )

    foreach ($root in $candidateRoots) {
        if (-not (Test-Path -LiteralPath $root)) {
            continue
        }
        $match = Get-ChildItem -LiteralPath $root -Recurse -Filter "Godot*_console.exe" -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if ($match) {
            return $match.FullName
        }
    }

    throw "Godot console executable not found. Pass -GodotExe with the full path to Godot_v4.7-stable_win64_console.exe."
}

$projectRoot = Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")
$resolvedGodot = Resolve-GodotExe -ExplicitPath $GodotExe
$templatesDir = Join-Path $env:APPDATA "Godot\export_templates\4.7.stable"
$releaseTemplate = Join-Path $templatesDir "windows_release_x86_64.exe"
$debugTemplate = Join-Path $templatesDir "windows_debug_x86_64.exe"

if (-not (Test-Path -LiteralPath $releaseTemplate)) {
    throw "Missing Godot release export template: $releaseTemplate"
}
if (-not (Test-Path -LiteralPath $debugTemplate)) {
    throw "Missing Godot debug export template: $debugTemplate"
}

if (-not $OutputPath) {
    $OutputPath = Join-Path $projectRoot "build\LetsMakeMoney.exe"
}

$outputDir = Split-Path -Parent $OutputPath
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

Write-Host "Using Godot: $resolvedGodot"
Write-Host "Project: $projectRoot"
Write-Host "Export: $OutputPath"

& $resolvedGodot --headless --path $projectRoot --export-release "LetsMakeMoney" $OutputPath --log-file (Join-Path ([System.IO.Path]::GetTempPath()) "LetsMakeMoney_export.log")
if ($LASTEXITCODE -ne 0) {
    throw "Godot export failed with exit code $LASTEXITCODE."
}

$exe = Get-Item -LiteralPath $OutputPath
if ($exe.Length -le 0) {
    throw "Exported exe is empty: $OutputPath"
}

Write-Host "Exported $($exe.FullName) ($($exe.Length) bytes)"

$process = Start-Process -FilePath $exe.FullName -PassThru
Start-Sleep -Seconds 4
$running = Get-Process -Id $process.Id -ErrorAction SilentlyContinue
if ($null -eq $running) {
    throw "Exported exe exited before smoke check completed."
}

Write-Host ("Started PID={0}; Title='{1}'; Responding={2}" -f $running.Id, $running.MainWindowTitle, $running.Responding)
Stop-Process -Id $running.Id -Force
Write-Host "M5 export smoke test passed."
