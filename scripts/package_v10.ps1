param()

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$app = Join-Path $root "apps\windows-v1"
$releaseRoot = Join-Path $root "releases\v1.0"
$packageName = "LetsMakeMoney-v1.0-windows-x86_64"
$stage = Join-Path $releaseRoot $packageName
$zip = Join-Path $releaseRoot "$packageName.zip"
$nodeModules = Join-Path $app "node_modules"
$approvedNodeModules = Join-Path $root "spikes\v1.0-ui\tauri-react\node_modules"
. (Join-Path $PSScriptRoot "v10_tools.ps1")
$node = Get-V10Node
$cargo = Get-V10Cargo -RepoRoot $root
$createdJunction = $false

function Remove-WorkspaceItem([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return }
    $resolvedRoot = [IO.Path]::GetFullPath($root).TrimEnd('\') + '\'
    $resolvedPath = [IO.Path]::GetFullPath($Path)
    if (-not $resolvedPath.StartsWith($resolvedRoot, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to remove path outside workspace: $resolvedPath"
    }
    Remove-Item -LiteralPath $resolvedPath -Recurse -Force
}

try {
    if (-not (Test-Path -LiteralPath $nodeModules)) {
        if (-not (Test-Path -LiteralPath $approvedNodeModules)) {
            throw "Frontend dependencies are missing. Run 'npm ci' in apps\windows-v1."
        }
        New-Item -ItemType Junction -Path $nodeModules -Target $approvedNodeModules | Out-Null
        $createdJunction = $true
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

    & $cargo "+stable-x86_64-pc-windows-msvc" build `
        --manifest-path (Join-Path $app "src-tauri\Cargo.toml") `
        --release --locked --offline
    if ($LASTEXITCODE -ne 0) { throw "Rust release build failed." }

    New-Item -ItemType Directory -Path $releaseRoot -Force | Out-Null
    Remove-WorkspaceItem $stage
    Remove-WorkspaceItem $zip
    New-Item -ItemType Directory -Path $stage -Force | Out-Null

    $target = Join-Path $app "src-tauri\target\release"
    Copy-Item -LiteralPath (Join-Path $target "letsmakemoney_windows_v1.exe") `
        -Destination (Join-Path $stage "LetsMakeMoney.exe")
    Copy-Item -LiteralPath (Join-Path $target "WebView2Loader.dll") -Destination $stage
    foreach ($file in @(
        "README.md",
        "README.en.md",
        "LICENSE",
        "THIRD_PARTY_NOTICES.md",
        "ASSETS_LICENSE.md",
        "ASSETS_MANIFEST.md"
    )) {
        Copy-Item -LiteralPath (Join-Path $root $file) -Destination $stage
    }
    Copy-Item -LiteralPath (Join-Path $root "releases\CHANGELOG.md") `
        -Destination (Join-Path $stage "CHANGELOG.md")

    $head = (git -C $root rev-parse HEAD).Trim()
    $dirty = [bool](git -C $root status --short)
    $buildInfo = [ordered]@{
        product = "LetsMakeMoney"
        version = "1.0.0"
        channel = "stable-candidate"
        platform = "windows-x86_64"
        source_head = $head
        source_tree_dirty = $dirty
        built_at_utc = [DateTime]::UtcNow.ToString("o")
        executable_sha256 = (Get-FileHash (Join-Path $stage "LetsMakeMoney.exe") -Algorithm SHA256).Hash
        webview2_loader_sha256 = (Get-FileHash (Join-Path $stage "WebView2Loader.dll") -Algorithm SHA256).Hash
    }
    $buildInfo | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $stage "BUILD-INFO.json") -Encoding UTF8

    Compress-Archive -LiteralPath $stage -DestinationPath $zip -CompressionLevel Optimal
    $zipHash = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash
    "$zipHash  $packageName.zip" | Set-Content `
        -LiteralPath (Join-Path $releaseRoot "SHA256SUMS.txt") -Encoding ASCII

    Write-Host "Package: $zip"
    Write-Host "SHA256: $zipHash"
}
finally {
    if ($createdJunction -and (Test-Path -LiteralPath $nodeModules)) {
        $item = Get-Item -LiteralPath $nodeModules -Force
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            [IO.Directory]::Delete($nodeModules)
        }
    }
}
