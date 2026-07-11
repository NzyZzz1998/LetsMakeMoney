param(
    [string]$GodotExe = "",
    [string]$OutputPath = "",
    [string]$SmokeAppDataRoot = ""
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "verification_common.ps1")

function Set-JsonProperty {
    param(
        [Parameter(Mandatory=$true)]$Object,
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)]$Value
    )
    if ($Object.PSObject.Properties.Name -contains $Name) {
        $Object.$Name = $Value
    } else {
        $Object | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
    }
}

function Set-SmokeConfig {
    param(
        [Parameter(Mandatory=$true)][string]$ConfigDir,
        [Parameter(Mandatory=$true)][string]$ConfigPath
    )
    New-Item -ItemType Directory -Force -Path $ConfigDir | Out-Null
    $backup = $null
    if (Test-Path -LiteralPath $ConfigPath) {
        $backup = Join-Path $ConfigDir ("config.verify-m5-backup-" + (Get-Date -Format "yyyyMMddHHmmss") + ".json")
        Copy-Item -LiteralPath $ConfigPath -Destination $backup -Force
        $data = Get-Content -Raw -LiteralPath $ConfigPath | ConvertFrom-Json
    } else {
        $data = New-Object PSObject
    }
    Set-JsonProperty $data "minimize_to_tray" $false
    Set-JsonProperty $data "pure_pet_mode" $false
    $data | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $ConfigPath -Encoding UTF8
    return $backup
}

function Restore-SmokeConfig {
    param(
        [string]$ConfigBackup,
        [Parameter(Mandatory=$true)][string]$ConfigPath
    )
    if ($ConfigBackup -and (Test-Path -LiteralPath $ConfigBackup)) {
        Copy-Item -LiteralPath $ConfigBackup -Destination $ConfigPath -Force
        Remove-Item -LiteralPath $ConfigBackup -ErrorAction SilentlyContinue
    }
}

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
        if ([string]::IsNullOrWhiteSpace($root)) { continue }
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

$previousPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
$exportOutput = & $resolvedGodot --headless --path $projectRoot --export-release "LetsMakeMoney" $OutputPath --log-file (Join-Path ([System.IO.Path]::GetTempPath()) "LetsMakeMoney_export.log") 2>&1
$exportExit = $LASTEXITCODE
$ErrorActionPreference = $previousPreference
Assert-LmmVerificationOutput -OutputText (($exportOutput | Out-String).Trim()) -ExitCode $exportExit -Label "M5 export"

$exe = Get-Item -LiteralPath $OutputPath
if ($exe.Length -le 0) {
    throw "Exported exe is empty: $OutputPath"
}

Write-Host "Exported $($exe.FullName) ($($exe.Length) bytes)"

$originalAppData = $env:APPDATA
if (-not $SmokeAppDataRoot) {
    $SmokeAppDataRoot = Join-Path $projectRoot ".tmp_appdata\verify_m5"
}
$env:APPDATA = $SmokeAppDataRoot
$configDir = Join-Path $env:APPDATA "LetsMakeMoney"
$configPath = Join-Path $configDir "config.json"
$configBackup = Set-SmokeConfig -ConfigDir $configDir -ConfigPath $configPath
try {
    $process = Start-Process -FilePath $exe.FullName -PassThru
    Start-Sleep -Seconds 4
    $running = Get-Process -Id $process.Id -ErrorAction SilentlyContinue
    if ($null -eq $running) {
        throw "Exported exe exited before smoke check completed with code $($process.ExitCode)."
    }

    Write-Host ("Started PID={0}; Title='{1}'; Responding={2}" -f $running.Id, $running.MainWindowTitle, $running.Responding)
    $process.CloseMainWindow() | Out-Null
    Start-Sleep -Seconds 2
    $forceStopped = $false
    if (-not $process.HasExited) {
        $forceStopped = $true
        Stop-Process -Id $running.Id -Force -ErrorAction SilentlyContinue
        $process.WaitForExit(5000) | Out-Null
    }
    if (-not $forceStopped -and $process.ExitCode -ne 0) {
        throw "Exported exe exited with code $($process.ExitCode)."
    }
} finally {
    Restore-SmokeConfig -ConfigBackup $configBackup -ConfigPath $configPath
    $env:APPDATA = $originalAppData
}
Write-Host "M5 export smoke test passed."
