param(
    [string]$GodotExe = ""
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

function Invoke-GodotCheck {
    param(
        [string]$Exe,
        [string[]]$Arguments,
        [string]$Label
    )

    Write-Host "== $Label =="
    $safeLabel = $Label -replace "[^A-Za-z0-9_-]", "_"
    $logDir = Join-Path ([System.IO.Path]::GetTempPath()) "LetsMakeMoneyGodotLogs"
    New-Item -ItemType Directory -Force -Path $logDir | Out-Null
    $logFile = Join-Path $logDir "$safeLabel.log"
    $effectiveArguments = @($Arguments) + @("--log-file", $logFile)
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $output = & $Exe @effectiveArguments 2>&1
    $ErrorActionPreference = $previousErrorActionPreference
    $exitCode = $LASTEXITCODE
    $outputText = ($output | Out-String).Trim()
    if ($outputText) {
        Write-Host $outputText
    }
    if ($exitCode -ne 0) {
        throw "$Label failed with exit code $exitCode."
    }
    if ($outputText -match "(?i)(parser error|invalid call|node not found|null instance|script error)") {
        throw "$Label emitted a blocking Godot error."
    }
}

$projectRoot = Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")
$resolvedGodot = Resolve-GodotExe -ExplicitPath $GodotExe
$scriptPath = Join-Path $projectRoot "scripts\verify_m4.gd"

Write-Host "Using Godot: $resolvedGodot"
Write-Host "Project: $projectRoot"

Invoke-GodotCheck `
    -Exe $resolvedGodot `
    -Arguments @("--headless", "--path", $projectRoot, "--script", $scriptPath) `
    -Label "M4 settings and wizard"
