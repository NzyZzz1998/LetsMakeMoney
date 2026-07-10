$ErrorActionPreference = "Stop"

$script:BlockingPatterns = @(
    '(?i)parser error',
    '(?i)script error',
    '(?i)invalid call',
    '(?i)node not found',
    '(?i)null instance',
    '(?i)failed to load script',
    '(?i)cannot get class'
)

function Resolve-LmmGodotExecutable {
    param([string]$ExplicitPath = "")

    if ($ExplicitPath -and (Test-Path -LiteralPath $ExplicitPath)) {
        return (Resolve-Path -LiteralPath $ExplicitPath).Path
    }
    $candidates = @(
        "$env:LMM_GODOT_EXE",
        "$env:LMM_GODOT_EXE",
        "$env:LMM_GODOT_EXE",
        "$env:LMM_GODOT_EXE"
    )
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }
    foreach ($command in @("godot", "godot4")) {
        $resolved = Get-Command $command -ErrorAction SilentlyContinue
        if ($resolved) { return $resolved.Source }
    }
    throw "Godot executable not found. Pass -GodotExe explicitly."
}

function Initialize-LmmGodotClassCache {
    param(
        [Parameter(Mandatory=$true)][string]$GodotExe,
        [Parameter(Mandatory=$true)][string]$ProjectRoot
    )
    $cachePath = Join-Path $ProjectRoot ".godot\global_script_class_cache.cfg"
    if (Test-Path -LiteralPath $cachePath) { return }
    $prepareLog = Join-Path ([System.IO.Path]::GetTempPath()) "LetsMakeMoneyGodotLogs\class-cache.log"
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $prepareLog) | Out-Null
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $prepareOutput = & $GodotExe --headless --editor --path $ProjectRoot --quit --log-file $prepareLog 2>&1
    $prepareExit = $LASTEXITCODE
    $ErrorActionPreference = $previousPreference
    if ($prepareExit -ne 0 -or -not (Test-Path -LiteralPath $cachePath)) {
        throw "Godot class cache preparation failed with exit code $prepareExit.`n$($prepareOutput | Out-String)"
    }
}

function Assert-LmmVerificationOutput {
    param(
        [Parameter(Mandatory=$true)][string]$OutputText,
        [Parameter(Mandatory=$true)][int]$ExitCode,
        [Parameter(Mandatory=$true)][string]$Label,
        [string]$SuccessMarker = ""
    )
    if ($ExitCode -ne 0) {
        throw "$Label failed with exit code $ExitCode.`n$OutputText"
    }
    foreach ($pattern in $script:BlockingPatterns) {
        if ($OutputText -match $pattern) {
            throw "$Label emitted blocking output matching '$pattern'.`n$OutputText"
        }
    }
    if ($SuccessMarker -and $OutputText -notmatch [regex]::Escape($SuccessMarker)) {
        throw "$Label did not emit success marker '$SuccessMarker'.`n$OutputText"
    }
}

function Invoke-LmmGodotVerification {
    param(
        [Parameter(Mandatory=$true)][string]$GodotExe,
        [Parameter(Mandatory=$true)][string]$ProjectRoot,
        [Parameter(Mandatory=$true)][string]$ScriptPath,
        [Parameter(Mandatory=$true)][string]$Label,
        [string]$SuccessMarker = ""
    )

    Initialize-LmmGodotClassCache -GodotExe $GodotExe -ProjectRoot $ProjectRoot
    $logRoot = Join-Path ([System.IO.Path]::GetTempPath()) "LetsMakeMoneyGodotLogs"
    New-Item -ItemType Directory -Force -Path $logRoot | Out-Null
    $safeLabel = $Label -replace '[^A-Za-z0-9_-]', '_'
    $engineLog = Join-Path $logRoot "$safeLabel.engine.log"
    $arguments = @("--headless", "--path", $ProjectRoot, "--script", $ScriptPath, "--log-file", $engineLog)

    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $output = & $GodotExe @arguments 2>&1
    $exitCode = $LASTEXITCODE
    $ErrorActionPreference = $previousPreference
    $outputText = ($output | Out-String).Trim()
    if (-not $outputText -and (Test-Path -LiteralPath $engineLog)) {
        $engineText = Get-Content -LiteralPath $engineLog -Raw -ErrorAction SilentlyContinue
        if ($engineText) { $outputText = "$outputText`n$engineText".Trim() }
    }
    Assert-LmmVerificationOutput -OutputText $outputText -ExitCode $exitCode -Label $Label -SuccessMarker $SuccessMarker
    return $outputText
}
