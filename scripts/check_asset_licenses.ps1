param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"
$issues = [System.Collections.Generic.List[string]]::new()

function Require-File([string]$RelativePath) {
    $path = Join-Path $Root $RelativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        $issues.Add("Missing required file: $RelativePath")
        return $null
    }
    return $path
}

$licensePath = Require-File 'LICENSE'
$assetsLicensePath = Require-File 'ASSETS_LICENSE.md'
$assetsManifestPath = Require-File 'ASSETS_MANIFEST.md'
$machineManifestPath = Require-File 'assets/asset-license-manifest.json'
$readmePath = Require-File 'README.md'
$englishReadmePath = Require-File 'README.en.md'
$contributingPath = Require-File 'CONTRIBUTING.md'

if ($licensePath) {
    $license = [IO.File]::ReadAllText($licensePath, [Text.Encoding]::UTF8)
    if ($license -notmatch '^MIT License' -or $license -notmatch 'Copyright \(c\) 2026 NzyZzz1998') {
        $issues.Add('LICENSE does not contain the approved MIT identity.')
    }
}

$manifest = $null
if ($machineManifestPath) {
    try { $manifest = Get-Content -LiteralPath $machineManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json }
    catch { $issues.Add('Asset license manifest is not valid JSON.') }
}

$allowedStatuses = @('approved_restricted','approved_third_party','excluded_private')
if ($manifest) {
    if (-not $manifest.entries -or @($manifest.entries).Count -eq 0) { $issues.Add('Asset license manifest has no entries.') }
    foreach ($entry in @($manifest.entries)) {
        if ([string]::IsNullOrWhiteSpace([string]$entry.id) -or [string]::IsNullOrWhiteSpace([string]$entry.path)) {
            $issues.Add('Asset manifest entry is missing id or path.')
            continue
        }
        if ($allowedStatuses -notcontains [string]$entry.status) { $issues.Add("Unknown asset status at entry: $($entry.id)") }
        if ([string]$entry.status -eq 'approved_restricted' -and [string]$entry.license -ne 'ASSETS_LICENSE.md') {
            $issues.Add("Restricted asset has an invalid license reference: $($entry.id)")
        }
        if ([string]$entry.status -match '^approved_' -and [string]::IsNullOrWhiteSpace([string]$entry.source)) {
            $issues.Add("Approved asset is missing source evidence: $($entry.id)")
        }
    }
}

function Get-CandidateVisualFiles {
    Push-Location $Root
    try {
        if (Test-Path -LiteralPath (Join-Path $Root '.git')) {
            $paths = @(& git ls-files; & git ls-files --others --exclude-standard) | Sort-Object -Unique
        } else {
            $paths = @(Get-ChildItem -LiteralPath $Root -Recurse -File | ForEach-Object { $_.FullName.Substring($Root.Length).TrimStart('\').Replace('\','/') })
        }
        return @($paths | Where-Object { $_ -match '(?i)\.(png|jpg|jpeg|webp|gif|svg|ico|wav|mp3|ogg)$' })
    } finally { Pop-Location }
}

if ($manifest) {
    $entries = @($manifest.entries)
    foreach ($visualPath in @(Get-CandidateVisualFiles)) {
        $normalized = $visualPath.Replace('\','/')
        $covered = $false
        foreach ($entry in $entries) {
            $prefix = ([string]$entry.path).Replace('\','/').TrimEnd('/')
            if ($normalized.Equals($prefix, [StringComparison]::OrdinalIgnoreCase) -or $normalized.StartsWith($prefix + '/', [StringComparison]::OrdinalIgnoreCase)) {
                $covered = $true
                break
            }
        }
        if (-not $covered) { $issues.Add("Unregistered visual asset: $normalized") }
    }
}

foreach ($pair in @(
    @($readmePath, @('LICENSE','ASSETS_LICENSE.md','ASSETS_MANIFEST.md','CONTRIBUTING.md')),
    @($englishReadmePath, @('LICENSE','ASSETS_LICENSE.md','ASSETS_MANIFEST.md','CONTRIBUTING.md')),
    @($contributingPath, @('LICENSE','ASSETS_LICENSE.md'))
)) {
    if (-not $pair[0]) { continue }
    $content = [IO.File]::ReadAllText($pair[0], [Text.Encoding]::UTF8)
    foreach ($needle in $pair[1]) {
        if ($content -notmatch [regex]::Escape($needle)) { $issues.Add("Missing license/contribution link in $($pair[0]): $needle") }
    }
}

foreach ($relative in @('assets/README.md','icons/README.md','doc/prototypes/README.md')) {
    $path = Require-File $relative
    if ($path) {
        $content = [IO.File]::ReadAllText($path, [Text.Encoding]::UTF8)
        if ($content -notmatch 'ASSETS_LICENSE') { $issues.Add("Asset directory entry does not reference ASSETS_LICENSE: $relative") }
    }
}

if ($issues.Count -gt 0) {
    Write-Host 'Asset license check failed:' -ForegroundColor Red
    $issues | Sort-Object -Unique | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

Write-Host 'Asset license check passed: all candidate visual files have an approved or excluded manifest status.' -ForegroundColor Green
