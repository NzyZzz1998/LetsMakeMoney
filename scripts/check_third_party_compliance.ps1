param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$PackageRoot = ''
)

$ErrorActionPreference = 'Stop'
$issues = [System.Collections.Generic.List[string]]::new()

function Read-Json([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { $issues.Add("Missing JSON: $Path"); return $null }
    try { return Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json }
    catch { $issues.Add("Invalid JSON: $Path"); return $null }
}

foreach ($relative in @('LICENSE','ASSETS_LICENSE.md','ASSETS_MANIFEST.md','THIRD_PARTY_NOTICES.md','third_party/dependencies.json','third_party/license-files.json')) {
    $path = Join-Path $ProjectRoot $relative
    if (-not (Test-Path -LiteralPath $path) -or (Get-Item -LiteralPath $path).Length -eq 0) { $issues.Add("Missing or empty compliance file: $relative") }
}

$manifest = Read-Json (Join-Path $ProjectRoot 'third_party/dependencies.json')
$licenseManifest = Read-Json (Join-Path $ProjectRoot 'third_party/license-files.json')
$allowedStatuses = @('reviewed','reviewed_system_component','reviewed_reference_only','planned_pending_version','planned_pending_selection')
$requiredDependencies = @('Godot Engine','godot-cpp','MinGW-w64 UCRT headers/runtime','GCC','Python','SCons','Pillow','Git for Windows','Windows PowerShell / .NET Framework','Inno Setup','GitHub Actions')

if ($manifest) {
    $names = @($manifest.dependencies | ForEach-Object { [string]$_.name })
    foreach ($required in $requiredDependencies) { if ($names -notcontains $required) { $issues.Add("Missing dependency manifest entry: $required") } }
    foreach ($dep in @($manifest.dependencies)) {
        foreach ($field in @('name','version_or_commit','source','license','usage','distribution_scope','notice_required','license_file','review_status')) {
            if ($dep.PSObject.Properties.Name -notcontains $field -or $null -eq $dep.$field) { $issues.Add("Dependency field missing: $($dep.name).$field") }
        }
        if ($allowedStatuses -notcontains [string]$dep.review_status) { $issues.Add("Unknown dependency review status: $($dep.name)") }
        foreach ($licenseFile in @($dep.license_file)) {
            if (-not $licenseFile) { continue }
            $path = Join-Path $ProjectRoot $licenseFile
            if (-not (Test-Path -LiteralPath $path) -or (Get-Item -LiteralPath $path).Length -eq 0) { $issues.Add("Missing dependency license file: $licenseFile") }
        }
    }

    $notices = [IO.File]::ReadAllText((Join-Path $ProjectRoot 'THIRD_PARTY_NOTICES.md'), [Text.Encoding]::UTF8)
    foreach ($dep in @($manifest.dependencies | Where-Object { $_.notice_required -eq $true })) {
        if ($notices -notmatch [regex]::Escape([string]$dep.name)) { $issues.Add("Notices missing dependency: $($dep.name)") }
        if ([string]$dep.review_status -notlike 'planned_*' -and $notices -notmatch [regex]::Escape([string]$dep.version_or_commit)) {
            $issues.Add("Notices version mismatch: $($dep.name)")
        }
    }
}

if ($licenseManifest) {
    foreach ($entry in @($licenseManifest.files)) {
        $path = Join-Path $ProjectRoot $entry.path
        if (-not (Test-Path -LiteralPath $path)) { $issues.Add("Missing pinned license text: $($entry.path)"); continue }
        $actual = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
        if ($actual -ne [string]$entry.sha256) { $issues.Add("License text hash mismatch: $($entry.path)") }
    }
}

if ($PackageRoot) {
    if (-not (Test-Path -LiteralPath $PackageRoot -PathType Container)) { $issues.Add("Package root missing: $PackageRoot") }
    else {
        $requiredPackageFiles = @(
            'LICENSES/PROJECT_LICENSE.txt','LICENSES/ASSETS_LICENSE.md','LICENSES/ASSETS_MANIFEST.md',
            'LICENSES/THIRD_PARTY_NOTICES.md','LICENSES/dependencies.json',
            'LICENSES/third-party/Godot/LICENSE.txt','LICENSES/third-party/Godot/COPYRIGHT.txt',
            'LICENSES/third-party/godot-cpp/LICENSE.md','LICENSES/third-party/MinGW-w64/COPYING',
            'LICENSES/third-party/MinGW-w64/COPYING.RUNTIME','LICENSES/third-party/GCC/COPYING3',
            'LICENSES/third-party/GCC/COPYING.RUNTIME','manifest.json'
        )
        foreach ($relative in $requiredPackageFiles) {
            $path = Join-Path $PackageRoot $relative
            if (-not (Test-Path -LiteralPath $path) -or (Get-Item -LiteralPath $path).Length -eq 0) { $issues.Add("Package missing compliance file: $relative") }
        }

        $packageDeps = Read-Json (Join-Path $PackageRoot 'LICENSES/dependencies.json')
        if ($packageDeps -and $manifest) {
            $projectJson = $manifest | ConvertTo-Json -Depth 12 -Compress
            $packageJson = $packageDeps | ConvertTo-Json -Depth 12 -Compress
            if ($projectJson -ne $packageJson) { $issues.Add('Package dependency manifest does not match the project manifest.') }
        }

        $allowedThirdPartyBinaries = @('letsmakemoney_native.dll')
        $binaryFiles = @(Get-ChildItem -LiteralPath $PackageRoot -Recurse -File | Where-Object { $_.Extension -match '(?i)^\.(dll|ttf|otf|woff|woff2)$' })
        foreach ($file in $binaryFiles) {
            if ($allowedThirdPartyBinaries -notcontains $file.Name) { $issues.Add("Unregistered package DLL/font: $($file.Name)") }
        }
        foreach ($item in @(Get-ChildItem -LiteralPath $PackageRoot -Recurse -Force)) {
            $relative = $item.FullName.Substring((Resolve-Path $PackageRoot).Path.Length).TrimStart('\').Replace('\','/')
            if ($relative -match '(?i)(^|/)(\.tmp_acceptance|\.manual-test|temp)(/|$)' -or $relative -match '(?i)(^|/)(debug\.log|config\.json)$' -or $relative -match '(?i)\.(pfx|pem|key)$') {
                $issues.Add("Excluded/private path in package: $relative")
            }
        }
    }
}

if ($issues.Count -gt 0) {
    Write-Host 'Third-party compliance check failed:' -ForegroundColor Red
    $issues | Sort-Object -Unique | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

Write-Host 'Third-party compliance check passed.' -ForegroundColor Green
