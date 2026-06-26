param(
    [string]$GodotExe = "",
    [int]$QuitAfterFrames = 30
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
    $output = & $Exe @Arguments 2>&1
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
$projectFile = Join-Path $projectRoot "project.godot"
$mainScene = "res://src/scenes/main/main.tscn"

if (-not (Test-Path -LiteralPath $projectFile)) {
    throw "project.godot not found at $projectFile"
}

$projectText = Get-Content -Encoding UTF8 -Raw -LiteralPath $projectFile
if ($projectText -notmatch [regex]::Escape("run/main_scene=`"$mainScene`"")) {
    throw "project.godot does not set run/main_scene to $mainScene"
}
if ($projectText -notmatch 'PanelSystem="\*res://src/autoload/panel_system.gd"') {
    throw "project.godot does not register PanelSystem autoload."
}

$resolvedGodot = Resolve-GodotExe -ExplicitPath $GodotExe
Write-Host "Using Godot: $resolvedGodot"
Write-Host "Project: $projectRoot"

Invoke-GodotCheck `
    -Exe $resolvedGodot `
    -Arguments @("--headless", "--path", $projectRoot, "--quit") `
    -Label "Project load"

Invoke-GodotCheck `
    -Exe $resolvedGodot `
    -Arguments @("--headless", "--path", $projectRoot, "--scene", $mainScene, "--quit-after", "$QuitAfterFrames") `
    -Label "Main scene smoke test"

Write-Host "M3 automated verification passed."
