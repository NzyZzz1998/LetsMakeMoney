param([string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot))

$ErrorActionPreference = "Stop"
$manifestPath = Join-Path $PSScriptRoot "script-tiers.json"
$excludedNames = @("README.md", "script-tiers.json")

if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw "Missing script tier manifest: $manifestPath"
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($manifest.schema_version -ne 1) {
    throw "Unsupported script tier manifest schema: $($manifest.schema_version)"
}

$listed = @($manifest.tiers | ForEach-Object { $_.files })
$duplicates = @($listed | Group-Object | Where-Object Count -gt 1)
if ($duplicates.Count -gt 0) {
    throw "Scripts listed in more than one tier: $($duplicates.Name -join ', ')"
}

$actual = @(Get-ChildItem -LiteralPath $PSScriptRoot -File | Where-Object { $_.Name -notin $excludedNames } | Select-Object -ExpandProperty Name)
$missingFromManifest = @($actual | Where-Object { $_ -notin $listed })
$missingOnDisk = @($listed | Where-Object { $_ -notin $actual })
if ($missingFromManifest.Count -gt 0) {
    throw "Unclassified scripts: $($missingFromManifest -join ', ')"
}
if ($missingOnDisk.Count -gt 0) {
    throw "Manifest entries missing on disk: $($missingOnDisk -join ', ')"
}

$requiredTiers = @("active", "compat", "archive", "maintainer-assets")
$tierIds = @($manifest.tiers.id)
foreach ($tier in $requiredTiers) {
    if ($tier -notin $tierIds) { throw "Missing required script tier: $tier" }
}

$activeFiles = @($manifest.tiers | Where-Object id -eq "active" | ForEach-Object files)
foreach ($entry in @("run_ci_verification.ps1", "verify_v07.ps1", "package_v07.ps1", "build_native_windows.ps1")) {
    if ($entry -notin $activeFiles) { throw "Current entrypoint is not active: $entry" }
}

$archiveFiles = @($manifest.tiers | Where-Object id -eq "archive" | ForEach-Object files)
$currentEntryText = @(
    Get-Content -LiteralPath (Join-Path $PSScriptRoot "run_ci_verification.ps1") -Raw -Encoding UTF8
    Get-ChildItem -LiteralPath (Join-Path $ProjectRoot ".github\workflows") -File -ErrorAction SilentlyContinue | ForEach-Object {
        Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8
    }
) -join "`n"
foreach ($archived in $archiveFiles) {
    if ($currentEntryText.Contains($archived)) {
        throw "Archive-tier script is still referenced by a current CI entrypoint: $archived"
    }
}

Write-Host ("Script tier check passed: total={0}, active={1}, compat={2}, archive={3}, maintainer-assets={4}" -f
    $listed.Count,
    @($manifest.tiers | Where-Object id -eq "active" | ForEach-Object files).Count,
    @($manifest.tiers | Where-Object id -eq "compat" | ForEach-Object files).Count,
    $archiveFiles.Count,
    @($manifest.tiers | Where-Object id -eq "maintainer-assets" | ForEach-Object files).Count)
