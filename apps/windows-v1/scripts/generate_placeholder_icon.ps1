param(
    [string]$OutputPath = (Join-Path $PSScriptRoot "..\src-tauri\icons\icon.ico")
)

$ErrorActionPreference = "Stop"
Write-Warning "generate_placeholder_icon.ps1 is retained as a compatibility entry point. The approved L2 brand generator is used."
& (Join-Path $PSScriptRoot "generate_brand_icon.ps1") -IcoOutputPath $OutputPath
