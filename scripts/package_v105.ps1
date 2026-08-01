param(
    [string]$CandidateId = "",
    [string]$PythonExe = ""
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$AppRoot = Join-Path $RepoRoot "apps\windows-v1"
$Version = "1.0.5"
$Platform = "windows-x86_64"
$Architecture = "x86_64"
$PackageName = "LetsMakeMoney-v$Version-$Platform"
$CandidateRoot = Join-Path $RepoRoot ".artifacts\candidates\v$Version"
$NodeModules = Join-Path $AppRoot "node_modules"

. (Join-Path $PSScriptRoot "v10_tools.ps1")

$Node = Get-V10Node -RepoRoot $RepoRoot
if ([string]::IsNullOrWhiteSpace($PythonExe)) {
    $PythonExe = Get-V10Python -RepoRoot $RepoRoot
}
$Cargo = Get-V10Cargo -RepoRoot $RepoRoot
$RustToolchain = Get-V10RustToolchain

function Assert-WorkspacePath([string]$Path) {
    $resolvedRoot = [IO.Path]::GetFullPath($RepoRoot).TrimEnd('\') + '\'
    $resolvedPath = [IO.Path]::GetFullPath($Path)
    if (-not $resolvedPath.StartsWith($resolvedRoot, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Path is outside the workspace: $resolvedPath"
    }
    return $resolvedPath
}

function Remove-WorkspaceItem([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return }
    $resolvedPath = Assert-WorkspacePath $Path
    Remove-Item -LiteralPath $resolvedPath -Recurse -Force
}

function Read-CargoVersion([string]$CargoToml) {
    $content = Get-Content -LiteralPath $CargoToml -Raw -Encoding UTF8
    $match = [regex]::Match(
        $content,
        '(?ms)^\[package\]\s*.*?^version\s*=\s*"(?<version>\d+\.\d+\.\d+)"'
    )
    if (-not $match.Success) {
        throw "Cargo package version could not be read."
    }
    return $match.Groups["version"].Value
}

function File-Identity([string]$Path) {
    $item = Get-Item -LiteralPath $Path
    return [ordered]@{
        name = $item.Name
        size = [int64]$item.Length
        sha256 = (Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash
    }
}

$SourceHead = (git -C $RepoRoot rev-parse HEAD).Trim()
if ($SourceHead -notmatch '^[0-9a-f]{40}$') {
    throw "Git HEAD is not a full commit identity."
}
$SourceTreeDirty = [bool](git -C $RepoRoot status --short --untracked-files=all)
$SourceState = if ($SourceTreeDirty) { "dirty" } else { "clean" }
$Timestamp = [DateTime]::UtcNow.ToString("yyyyMMddTHHmmssZ")
if ([string]::IsNullOrWhiteSpace($CandidateId)) {
    $CandidateId = "V105-$Timestamp-$($SourceHead.Substring(0, 8))-$SourceState"
}
if ($CandidateId -notmatch '^[A-Za-z0-9._-]{6,96}$') {
    throw "CandidateId contains unsupported characters or has an invalid length."
}

$FinalDirectory = Join-Path $CandidateRoot $CandidateId
if (Test-Path -LiteralPath $FinalDirectory) {
    throw "Candidate already exists and will not be overwritten: $CandidateId"
}
$StagingDirectory = Join-Path $CandidateRoot (".staging-" + [Guid]::NewGuid().ToString("N"))
$PayloadDirectory = Join-Path $StagingDirectory $PackageName
$StagingZip = Join-Path $StagingDirectory "$PackageName.zip"
$MovedToFinal = $false

$tauriConfig = Get-Content -LiteralPath (Join-Path $AppRoot "src-tauri\tauri.conf.json") `
    -Raw -Encoding UTF8 | ConvertFrom-Json
$packageJson = Get-Content -LiteralPath (Join-Path $AppRoot "package.json") `
    -Raw -Encoding UTF8 | ConvertFrom-Json
$cargoVersion = Read-CargoVersion (Join-Path $AppRoot "src-tauri\Cargo.toml")
foreach ($entry in ([ordered]@{
    tauri = [string]$tauriConfig.version
    npm = [string]$packageJson.version
    cargo = [string]$cargoVersion
}).GetEnumerator()) {
    if ($entry.Value -ne $Version) {
        throw "$($entry.Key) version '$($entry.Value)' does not match $Version."
    }
}

& (Join-Path $PSScriptRoot "verify_v105.ps1") -Milestone M5 -PythonExe $PythonExe
if ($LASTEXITCODE -ne 0) {
    throw "v1.0.5 M5 verification failed before packaging."
}

Push-Location $AppRoot
try {
    & $Node (Join-Path $NodeModules "typescript\bin\tsc")
    if ($LASTEXITCODE -ne 0) { throw "TypeScript build failed." }
    & $Node (Join-Path $NodeModules "vite\bin\vite.js") build
    if ($LASTEXITCODE -ne 0) { throw "Vite build failed." }
}
finally {
    Pop-Location
}

& $Cargo "+$RustToolchain" build `
    --manifest-path (Join-Path $AppRoot "src-tauri\Cargo.toml") `
    --release --locked
if ($LASTEXITCODE -ne 0) { throw "Rust release build failed." }

New-Item -ItemType Directory -Force -Path $CandidateRoot | Out-Null
New-Item -ItemType Directory -Force -Path $PayloadDirectory | Out-Null

try {
    $TargetRoot = Join-Path $AppRoot "src-tauri\target\release"
    Copy-Item -LiteralPath (Join-Path $TargetRoot "letsmakemoney_windows_v1.exe") `
        -Destination (Join-Path $PayloadDirectory "LetsMakeMoney.exe")

    $Loader = Get-ChildItem -LiteralPath (Join-Path $TargetRoot "build") -Recurse `
        -Filter "WebView2Loader.dll" -File |
        Where-Object { $_.FullName -match '\\out\\x64\\WebView2Loader\.dll$' } |
        Sort-Object LastWriteTimeUtc -Descending |
        Select-Object -First 1
    if (-not $Loader) {
        throw "The x64 WebView2Loader.dll build output is missing."
    }
    Copy-Item -LiteralPath $Loader.FullName `
        -Destination (Join-Path $PayloadDirectory "WebView2Loader.dll")

    foreach ($file in @(
        "LICENSE",
        "THIRD_PARTY_NOTICES.md",
        "ASSETS_LICENSE.md",
        "ASSETS_MANIFEST.md"
    )) {
        Copy-Item -LiteralPath (Join-Path $RepoRoot $file) -Destination $PayloadDirectory
    }
    Copy-Item -LiteralPath (Join-Path $RepoRoot "releases\CHANGELOG.md") `
        -Destination (Join-Path $PayloadDirectory "CHANGELOG.md")

    & $PythonExe (Join-Path $AppRoot "release-docs\portable_readme.py") `
        --mode render `
        --package-root $PayloadDirectory `
        --version $Version `
        --platform "Windows x86_64" `
        --channel "Stable"
    if ($LASTEXITCODE -ne 0) {
        throw "Portable README rendering or semantic validation failed."
    }

    $CalendarTarget = Join-Path $PayloadDirectory "calendar-data"
    Copy-Item -LiteralPath (Join-Path $AppRoot "calendar-data") `
        -Destination $CalendarTarget -Recurse
    $CalendarManifestPath = Join-Path $CalendarTarget "manifest.json"
    $CalendarManifest = Get-Content -LiteralPath $CalendarManifestPath `
        -Raw -Encoding UTF8 | ConvertFrom-Json
    $CalendarIdentities = @(
        foreach ($entry in $CalendarManifest.datasets) {
            $datasetPath = Join-Path $CalendarTarget $entry.file
            [ordered]@{
                year = [int]$entry.year
                file = [string]$entry.file
                sha256 = (Get-FileHash -LiteralPath $datasetPath -Algorithm SHA256).Hash
            }
        }
    )

    $BuildTimestamp = [DateTime]::UtcNow.ToString("o")
    $BuildInfo = [ordered]@{
        schema_version = "1.0"
        product = "LetsMakeMoney"
        version = $Version
        channel = "stable-candidate"
        platform = $Platform
        architecture = $Architecture
        source_head = $SourceHead
        source_tree_dirty = $SourceTreeDirty
        build_timestamp_utc = $BuildTimestamp
        executable_sha256 = (Get-FileHash (Join-Path $PayloadDirectory "LetsMakeMoney.exe") -Algorithm SHA256).Hash
        webview2_loader_sha256 = (Get-FileHash (Join-Path $PayloadDirectory "WebView2Loader.dll") -Algorithm SHA256).Hash
        documentation = [ordered]@{
            readme_sha256 = (Get-FileHash (Join-Path $PayloadDirectory "README.md") -Algorithm SHA256).Hash
            readme_en_sha256 = (Get-FileHash (Join-Path $PayloadDirectory "README.en.md") -Algorithm SHA256).Hash
            source = "apps/windows-v1/release-docs"
        }
        licenses = [ordered]@{
            license_sha256 = (Get-FileHash (Join-Path $PayloadDirectory "LICENSE") -Algorithm SHA256).Hash
            third_party_notices_sha256 = (Get-FileHash (Join-Path $PayloadDirectory "THIRD_PARTY_NOTICES.md") -Algorithm SHA256).Hash
            assets_license_sha256 = (Get-FileHash (Join-Path $PayloadDirectory "ASSETS_LICENSE.md") -Algorithm SHA256).Hash
            assets_manifest_sha256 = (Get-FileHash (Join-Path $PayloadDirectory "ASSETS_MANIFEST.md") -Algorithm SHA256).Hash
        }
        calendar = [ordered]@{
            manifest_sha256 = (Get-FileHash $CalendarManifestPath -Algorithm SHA256).Hash
            dataset_version = [string]$CalendarManifest.dataset_version
            datasets = $CalendarIdentities
        }
    }
    $BuildInfo | ConvertTo-Json -Depth 8 | Set-Content `
        -LiteralPath (Join-Path $PayloadDirectory "BUILD-INFO.json") -Encoding UTF8

    Compress-Archive -LiteralPath $PayloadDirectory `
        -DestinationPath $StagingZip -CompressionLevel Optimal
    $ZipIdentity = File-Identity $StagingZip
    "$($ZipIdentity.sha256)  $($ZipIdentity.name)" | Set-Content `
        -LiteralPath (Join-Path $StagingDirectory "SHA256SUMS.txt") -Encoding ASCII

    & (Join-Path $PSScriptRoot "verify_v105_package.ps1") `
        -Mode candidate `
        -PackagePath $StagingZip `
        -ExpectedSourceHead $SourceHead `
        -ExpectedVersion $Version `
        -ExpectedZipSha256 $ZipIdentity.sha256 `
        -SkipLocationCheck `
        -PythonExe $PythonExe
    if ($LASTEXITCODE -ne 0) {
        throw "Staged v1.0.5 candidate verification failed."
    }

    $CandidateIdentity = [ordered]@{
        schema_version = "1.0"
        candidate_id = $CandidateId
        release_version = $Version
        source_head = $SourceHead
        source_tree_dirty = $SourceTreeDirty
        build_timestamp_utc = $BuildTimestamp
        publication_allowed = $false
        publication_blockers = @(
            "independent acceptance is not complete",
            $(if ($SourceTreeDirty) { "source tree is dirty" } else { "release authorization is not granted" })
        )
        artifacts = @(
            $ZipIdentity,
            (File-Identity (Join-Path $PayloadDirectory "LetsMakeMoney.exe")),
            (File-Identity (Join-Path $PayloadDirectory "WebView2Loader.dll")),
            (File-Identity (Join-Path $PayloadDirectory "README.md")),
            (File-Identity (Join-Path $PayloadDirectory "README.en.md"))
        )
        verification = "candidate-package-contract-passed"
    }
    $CandidateIdentity | ConvertTo-Json -Depth 6 | Set-Content `
        -LiteralPath (Join-Path $StagingDirectory "candidate-identity.json") -Encoding UTF8

    Move-Item -LiteralPath $StagingDirectory -Destination $FinalDirectory
    $MovedToFinal = $true
    $FinalZip = Join-Path $FinalDirectory "$PackageName.zip"

    & (Join-Path $PSScriptRoot "verify_v105_package.ps1") `
        -Mode candidate `
        -PackagePath $FinalZip `
        -ExpectedSourceHead $SourceHead `
        -ExpectedVersion $Version `
        -ExpectedZipSha256 $ZipIdentity.sha256 `
        -PythonExe $PythonExe
    if ($LASTEXITCODE -ne 0) {
        throw "Final v1.0.5 candidate location or identity verification failed."
    }

    Write-Host "CANDIDATE_ID=$CandidateId"
    Write-Host "PACKAGE=$FinalZip"
    Write-Host "SHA256=$($ZipIdentity.sha256)"
    Write-Host "SOURCE_HEAD=$SourceHead"
    Write-Host "SOURCE_TREE_DIRTY=$SourceTreeDirty"
}
catch {
    if ($MovedToFinal) {
        Remove-WorkspaceItem $FinalDirectory
    }
    throw
}
finally {
    if (Test-Path -LiteralPath $StagingDirectory) {
        Remove-WorkspaceItem $StagingDirectory
    }
}
