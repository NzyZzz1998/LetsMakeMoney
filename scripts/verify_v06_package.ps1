param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$PackagePath = "",
    [int]$SmokeSeconds = 5
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "project_version.ps1")
$version = Get-LetsMakeMoneyVersion -ProjectRoot $ProjectRoot
$packageName = "LetsMakeMoney-v$version-windows-x86_64"
if (-not $PackagePath) { $PackagePath = Join-Path $ProjectRoot "releases\v0.6\$packageName.zip" }
if (-not (Test-Path -LiteralPath $PackagePath)) { throw "Missing v0.6 package: $PackagePath" }

$extractRoot = Join-Path $ProjectRoot ".tmp_release\verify_v06_package"
$smokeAppData = Join-Path $ProjectRoot ".tmp_appdata\verify_v06_package"
if (Test-Path -LiteralPath $extractRoot) { Remove-Item -LiteralPath $extractRoot -Recurse -Force }
if (Test-Path -LiteralPath $smokeAppData) { Remove-Item -LiteralPath $smokeAppData -Recurse -Force }
New-Item -ItemType Directory -Force -Path $extractRoot | Out-Null
Expand-Archive -LiteralPath $PackagePath -DestinationPath $extractRoot -Force

$required = @("LetsMakeMoney.exe", "letsmakemoney_native.dll", "app_icon.ico", "README.md", "release-notes.md", "manifest.json", "checksums.txt")
foreach ($name in $required) {
    if (-not (Test-Path -LiteralPath (Join-Path $extractRoot $name))) { throw "Package missing $name" }
}
$unexpected = Get-ChildItem -LiteralPath $extractRoot -Recurse -File | Where-Object { $_.Extension -in @(".ps1", ".gd", ".pdb") }
if ($unexpected) { throw "Package contains internal files: $($unexpected.Name -join ', ')" }

$manifest = Get-Content -LiteralPath (Join-Path $extractRoot "manifest.json") -Raw -Encoding UTF8 | ConvertFrom-Json
if ($manifest.package_name -ne $packageName -or $manifest.version -ne $version) { throw "Package version metadata mismatch." }
foreach ($file in $manifest.files) {
    $path = Join-Path $extractRoot $file.path
    $actual = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actual -ne $file.sha256) { throw "Manifest SHA256 mismatch: $($file.path)" }
}
foreach ($line in Get-Content -LiteralPath (Join-Path $extractRoot "checksums.txt") -Encoding UTF8) {
    if (-not $line.Trim()) { continue }
    $parts = $line -split '\s+', 2
    $path = Join-Path $extractRoot $parts[1].Trim()
    $actual = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actual -ne $parts[0].ToLowerInvariant()) { throw "Checksum mismatch: $($parts[1])" }
}

$oldAppData = $env:APPDATA
$process = $null
try {
    $env:APPDATA = $smokeAppData
    $configDir = Join-Path $smokeAppData "LetsMakeMoney"
    New-Item -ItemType Directory -Force -Path $configDir | Out-Null
    @{ monthly_salary = 12000; minimize_to_tray = $false; pure_pet_mode = $false; debug_mode = $false } |
        ConvertTo-Json | Set-Content -LiteralPath (Join-Path $configDir "config.json") -Encoding UTF8
    $process = Start-Process -FilePath (Join-Path $extractRoot "LetsMakeMoney.exe") -WorkingDirectory $extractRoot -WindowStyle Hidden -PassThru
    Start-Sleep -Seconds $SmokeSeconds
    if ($process.HasExited) { throw "Packaged exe exited during smoke test with code $($process.ExitCode)." }
    $logPath = Join-Path $configDir "debug.log"
    if (-not (Test-Path -LiteralPath $logPath)) { throw "Packaged exe did not create debug.log." }
    $log = Get-Content -LiteralPath $logPath -Raw -Encoding UTF8
    if ($log -notmatch "app_started: version=$([regex]::Escape($version))") { throw "Packaged runtime version log mismatch." }
} finally {
    if ($process -and -not $process.HasExited) {
        Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
        $process.WaitForExit(5000) | Out-Null
    }
    $env:APPDATA = $oldAppData
}
Write-Host "v0.6 package verification passed"
