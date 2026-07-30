param()

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$app = Join-Path $root "apps\windows-v1"
$releaseRoot = Join-Path $root "releases\v1.0.4"
$platform = "windows-x86_64"
$platformLabel = "Windows x86_64"
$channel = "Stable"
$expectedVersion = "1.0.4"
$packageName = "LetsMakeMoney-v$expectedVersion-$platform"
$finalZip = Join-Path $releaseRoot "$packageName.zip"
$finalChecksums = Join-Path $releaseRoot "SHA256SUMS.txt"
$candidateRoot = Join-Path $releaseRoot (".candidate-" + [Guid]::NewGuid().ToString("N"))
$stage = Join-Path $candidateRoot $packageName
$candidateZip = Join-Path $candidateRoot "$packageName.zip"
$nodeModules = Join-Path $app "node_modules"

. (Join-Path $PSScriptRoot "v10_tools.ps1")
$node = Get-V10Node
$python = Get-V10Python
$cargo = Get-V10Cargo -RepoRoot $root
$rustToolchain = Get-V10RustToolchain

function Assert-WorkspacePath([string]$Path) {
    $resolvedRoot = [IO.Path]::GetFullPath($root).TrimEnd('\') + '\'
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

$tauriConfig = Get-Content -LiteralPath (Join-Path $app "src-tauri\tauri.conf.json") `
    -Raw -Encoding UTF8 | ConvertFrom-Json
$packageJson = Get-Content -LiteralPath (Join-Path $app "package.json") `
    -Raw -Encoding UTF8 | ConvertFrom-Json
$cargoVersion = Read-CargoVersion (Join-Path $app "src-tauri\Cargo.toml")
$versionFacts = [ordered]@{
    tauri = [string]$tauriConfig.version
    npm = [string]$packageJson.version
    cargo = [string]$cargoVersion
}
foreach ($entry in $versionFacts.GetEnumerator()) {
    if ($entry.Value -ne $expectedVersion) {
        throw "$($entry.Key) version '$($entry.Value)' does not match $expectedVersion."
    }
}

& (Join-Path $PSScriptRoot "verify_calendar_data_v103.ps1")
if ($LASTEXITCODE -ne 0) {
    throw "Calendar data verification failed before packaging."
}

Push-Location $app
try {
    & $node (Join-Path $nodeModules "typescript\bin\tsc")
    if ($LASTEXITCODE -ne 0) { throw "TypeScript build failed." }
    & $node (Join-Path $nodeModules "vite\bin\vite.js") build
    if ($LASTEXITCODE -ne 0) { throw "Vite build failed." }
}
finally {
    Pop-Location
}

& $cargo "+$rustToolchain" build `
    --manifest-path (Join-Path $app "src-tauri\Cargo.toml") `
    --release --locked
if ($LASTEXITCODE -ne 0) { throw "Rust release build failed." }

New-Item -ItemType Directory -Path $releaseRoot -Force | Out-Null
Remove-WorkspaceItem $candidateRoot
New-Item -ItemType Directory -Path $stage -Force | Out-Null

try {
    $target = Join-Path $app "src-tauri\target\release"
    Copy-Item -LiteralPath (Join-Path $target "letsmakemoney_windows_v1.exe") `
        -Destination (Join-Path $stage "LetsMakeMoney.exe")
    $loader = Get-ChildItem -LiteralPath (Join-Path $target "build") -Recurse `
        -Filter "WebView2Loader.dll" -File |
        Where-Object { $_.FullName -match '\\out\\x64\\WebView2Loader\.dll$' } |
        Sort-Object LastWriteTimeUtc -Descending |
        Select-Object -First 1
    if (-not $loader) {
        throw "The x64 WebView2Loader.dll build output is missing."
    }
    Copy-Item -LiteralPath $loader.FullName -Destination (Join-Path $stage "WebView2Loader.dll")

    foreach ($file in @(
        "LICENSE",
        "THIRD_PARTY_NOTICES.md",
        "ASSETS_LICENSE.md",
        "ASSETS_MANIFEST.md"
    )) {
        Copy-Item -LiteralPath (Join-Path $root $file) -Destination $stage
    }
    Copy-Item -LiteralPath (Join-Path $root "releases\CHANGELOG.md") `
        -Destination (Join-Path $stage "CHANGELOG.md")

    $readmeTool = Join-Path $app "release-docs\portable_readme.py"
    & $python $readmeTool `
        --mode render `
        --package-root $stage `
        --version $expectedVersion `
        --platform $platformLabel `
        --channel $channel
    if ($LASTEXITCODE -ne 0) {
        throw "Portable README rendering or semantic validation failed."
    }

    $calendarSource = Join-Path $app "calendar-data"
    $calendarTarget = Join-Path $stage "calendar-data"
    Copy-Item -LiteralPath $calendarSource -Destination $calendarTarget -Recurse
    $calendarManifestPath = Join-Path $calendarTarget "manifest.json"
    $calendarManifest = Get-Content -LiteralPath $calendarManifestPath -Raw -Encoding UTF8 |
        ConvertFrom-Json
    $calendarIdentities = @(
        foreach ($entry in $calendarManifest.datasets) {
            $datasetPath = Join-Path $calendarTarget $entry.file
            [ordered]@{
                year = [int]$entry.year
                file = [string]$entry.file
                sha256 = (Get-FileHash -LiteralPath $datasetPath -Algorithm SHA256).Hash
            }
        }
    )

    $head = (git -C $root rev-parse HEAD).Trim()
    $dirty = [bool](git -C $root status --short)
    $buildInfo = [ordered]@{
        product = "LetsMakeMoney"
        version = $expectedVersion
        channel = "stable-candidate"
        platform = $platform
        source_head = $head
        source_tree_dirty = $dirty
        built_at_utc = [DateTime]::UtcNow.ToString("o")
        executable_sha256 = (Get-FileHash (Join-Path $stage "LetsMakeMoney.exe") -Algorithm SHA256).Hash
        webview2_loader_sha256 = (Get-FileHash (Join-Path $stage "WebView2Loader.dll") -Algorithm SHA256).Hash
        documentation = [ordered]@{
            readme_sha256 = (Get-FileHash (Join-Path $stage "README.md") -Algorithm SHA256).Hash
            readme_en_sha256 = (Get-FileHash (Join-Path $stage "README.en.md") -Algorithm SHA256).Hash
            source = "apps/windows-v1/release-docs"
        }
        calendar = [ordered]@{
            manifest_sha256 = (Get-FileHash $calendarManifestPath -Algorithm SHA256).Hash
            dataset_version = [string]$calendarManifest.dataset_version
            datasets = $calendarIdentities
        }
    }
    $buildInfo | ConvertTo-Json -Depth 8 | Set-Content `
        -LiteralPath (Join-Path $stage "BUILD-INFO.json") -Encoding UTF8

    Compress-Archive -LiteralPath $stage -DestinationPath $candidateZip -CompressionLevel Optimal
    & (Join-Path $PSScriptRoot "verify_v104_package.ps1") -PackagePath $candidateZip
    if ($LASTEXITCODE -ne 0) {
        throw "Candidate package verification failed."
    }

    $zipHash = (Get-FileHash -LiteralPath $candidateZip -Algorithm SHA256).Hash
    $candidateChecksums = Join-Path $candidateRoot "SHA256SUMS.txt"
    "$zipHash  $packageName.zip" | Set-Content -LiteralPath $candidateChecksums -Encoding ASCII

    $transactionId = [Guid]::NewGuid().ToString("N")
    $replacementZip = Join-Path $releaseRoot ".$packageName.$transactionId.new.zip"
    $replacementChecksums = Join-Path $releaseRoot ".SHA256SUMS.$transactionId.new.txt"
    $backupZip = Join-Path $releaseRoot ".$packageName.$transactionId.previous.zip"
    $backupChecksums = Join-Path $releaseRoot ".SHA256SUMS.$transactionId.previous.txt"
    Remove-WorkspaceItem $replacementZip
    Remove-WorkspaceItem $replacementChecksums
    Copy-Item -LiteralPath $candidateZip -Destination $replacementZip
    Copy-Item -LiteralPath $candidateChecksums -Destination $replacementChecksums
    try {
        if (Test-Path -LiteralPath $finalZip) {
            Move-Item -LiteralPath $finalZip -Destination $backupZip
        }
        if (Test-Path -LiteralPath $finalChecksums) {
            Move-Item -LiteralPath $finalChecksums -Destination $backupChecksums
        }
        Move-Item -LiteralPath $replacementZip -Destination $finalZip
        Move-Item -LiteralPath $replacementChecksums -Destination $finalChecksums
        Remove-WorkspaceItem $backupZip
        Remove-WorkspaceItem $backupChecksums
    }
    catch {
        Remove-WorkspaceItem $finalZip
        Remove-WorkspaceItem $finalChecksums
        if (Test-Path -LiteralPath $backupZip) {
            Move-Item -LiteralPath $backupZip -Destination $finalZip
        }
        if (Test-Path -LiteralPath $backupChecksums) {
            Move-Item -LiteralPath $backupChecksums -Destination $finalChecksums
        }
        throw
    }

    Write-Host "Package: $finalZip"
    Write-Host "SHA256: $zipHash"
}
finally {
    Remove-WorkspaceItem $candidateRoot
}
