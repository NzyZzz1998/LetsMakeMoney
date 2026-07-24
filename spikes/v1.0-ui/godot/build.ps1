param(
    [string]$GodotExe = "D:\Work\Software\godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe"
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$BuildDirectory = Join-Path $ProjectRoot "build"
$RuntimeDirectory = Join-Path $BuildDirectory "runtime"
$OriginalAppData = $env:APPDATA

if (-not (Test-Path -LiteralPath $GodotExe -PathType Leaf)) {
    throw "Godot 4.7 not found: $GodotExe"
}

New-Item -ItemType Directory -Path $RuntimeDirectory -Force | Out-Null
$env:APPDATA = $RuntimeDirectory
$env:LOCALAPPDATA = $RuntimeDirectory

$TemplateVersion = "4.7.stable"
$TemplateSource = Join-Path $OriginalAppData "Godot\export_templates\$TemplateVersion"
$TemplateTarget = Join-Path $RuntimeDirectory "Godot\export_templates\$TemplateVersion"
New-Item -ItemType Directory -Path $TemplateTarget -Force | Out-Null
foreach ($TemplateName in @("windows_debug_x86_64.exe", "windows_release_x86_64.exe")) {
    $SourcePath = Join-Path $TemplateSource $TemplateName
    $TargetPath = Join-Path $TemplateTarget $TemplateName
    if (-not (Test-Path -LiteralPath $SourcePath -PathType Leaf)) {
        throw "Godot export template not found: $SourcePath"
    }
    if (-not (Test-Path -LiteralPath $TargetPath -PathType Leaf)) {
        Copy-Item -LiteralPath $SourcePath -Destination $TargetPath
    }
}

& $GodotExe --headless --path $ProjectRoot --script "res://verify.gd"
if ($LASTEXITCODE -ne 0) {
    throw "Godot spike contract verification failed."
}

New-Item -ItemType Directory -Path $BuildDirectory -Force | Out-Null
& $GodotExe --headless --path $ProjectRoot --export-release "Windows Desktop" (Join-Path $BuildDirectory "LMM-v1.0-Godot-Spike.exe")
if ($LASTEXITCODE -ne 0) {
    throw "Godot spike export failed."
}

Get-FileHash -LiteralPath (Join-Path $BuildDirectory "LMM-v1.0-Godot-Spike.exe") -Algorithm SHA256
