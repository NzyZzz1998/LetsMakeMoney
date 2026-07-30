$script:V10ToolsRepoRoot = Split-Path -Parent $PSScriptRoot

function Resolve-V10Tool {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$ExplicitVariable,
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,
        [Parameter(Mandatory = $true)]
        [string]$CacheRelativePath
    )

    $explicitPath = [Environment]::GetEnvironmentVariable($ExplicitVariable, "Process")
    if (-not [string]::IsNullOrWhiteSpace($explicitPath)) {
        if (-not (Test-Path -LiteralPath $explicitPath -PathType Leaf)) {
            throw "Explicit tool variable $ExplicitVariable does not point to an existing file."
        }
        return [pscustomobject]@{
            Name = $Name
            Path = [IO.Path]::GetFullPath($explicitPath)
            Source = "explicit:$ExplicitVariable"
        }
    }

    $command = Get-Command $Name -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($command) {
        return [pscustomobject]@{
            Name = $Name
            Path = [IO.Path]::GetFullPath($command.Source)
            Source = "PATH"
        }
    }

    $cachePath = Join-Path ([IO.Path]::GetFullPath($RepoRoot)) $CacheRelativePath
    if (Test-Path -LiteralPath $cachePath -PathType Leaf) {
        return [pscustomobject]@{
            Name = $Name
            Path = [IO.Path]::GetFullPath($cachePath)
            Source = "repo-cache"
        }
    }

    throw "Required tool '$Name' was not found. Checked $ExplicitVariable, PATH, and repository cache '$CacheRelativePath'."
}

function Get-V10NodeResolution {
    param([string]$RepoRoot = $script:V10ToolsRepoRoot)
    return Resolve-V10Tool `
        -Name "node" `
        -ExplicitVariable "LMM_NODE" `
        -RepoRoot $RepoRoot `
        -CacheRelativePath ".toolchains\node\node.exe"
}

function Get-V10PythonResolution {
    param([string]$RepoRoot = $script:V10ToolsRepoRoot)
    return Resolve-V10Tool `
        -Name "python" `
        -ExplicitVariable "LMM_PYTHON" `
        -RepoRoot $RepoRoot `
        -CacheRelativePath ".toolchains\python\python.exe"
}

function Get-V10CargoResolution {
    param([string]$RepoRoot = $script:V10ToolsRepoRoot)

    $resolution = Resolve-V10Tool `
        -Name "cargo" `
        -ExplicitVariable "LMM_CARGO" `
        -RepoRoot $RepoRoot `
        -CacheRelativePath ".toolchains\cargo\bin\cargo.exe"

    if ($resolution.Source -eq "explicit:LMM_CARGO") {
        if (-not [string]::IsNullOrWhiteSpace($env:LMM_CARGO_HOME)) {
            $env:CARGO_HOME = [IO.Path]::GetFullPath($env:LMM_CARGO_HOME)
        }
        if (-not [string]::IsNullOrWhiteSpace($env:LMM_RUSTUP_HOME)) {
            $env:RUSTUP_HOME = [IO.Path]::GetFullPath($env:LMM_RUSTUP_HOME)
        }
    }
    elseif ($resolution.Source -eq "repo-cache") {
        $repoPath = [IO.Path]::GetFullPath($RepoRoot)
        $env:CARGO_HOME = Join-Path $repoPath ".toolchains\cargo"
        $env:RUSTUP_HOME = Join-Path $repoPath ".toolchains\rustup"
    }

    return $resolution
}

function Get-V10Node {
    param([string]$RepoRoot = $script:V10ToolsRepoRoot)
    return (Get-V10NodeResolution -RepoRoot $RepoRoot).Path
}

function Get-V10Python {
    param([string]$RepoRoot = $script:V10ToolsRepoRoot)
    return (Get-V10PythonResolution -RepoRoot $RepoRoot).Path
}

function Get-V10Cargo {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot
    )
    return (Get-V10CargoResolution -RepoRoot $RepoRoot).Path
}

function Get-V10RustToolchain {
    return "1.97.1-x86_64-pc-windows-msvc"
}
