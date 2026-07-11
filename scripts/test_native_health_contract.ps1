param([string]$ProjectRoot=(Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference='Stop'
$source=Get-Content -LiteralPath (Join-Path $ProjectRoot 'src/platform/windows_platform.gd') -Raw -Encoding UTF8
foreach($token in @('CAPABILITY_AVAILABLE','CAPABILITY_DEGRADED','CAPABILITY_UNAVAILABLE','_set_capability_state','capabilities','last_error')){if(-not $source.Contains($token)){throw "Windows native health contract missing: $token"}}
foreach($capability in @('tray','window','passthrough','taskbar')){if(-not $source.Contains('"'+$capability+'"')){throw "Native capability missing: $capability"}}
$interface=Get-Content -LiteralPath (Join-Path $ProjectRoot 'src/platform/platform_interface.gd') -Raw -Encoding UTF8
if(-not $interface.Contains('"capabilities"')){throw 'PlatformInterface fallback health must expose capabilities.'}
Write-Host 'Native health contract tests passed' -ForegroundColor Green
