param(
    [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [string]$LockPath,
    [string]$CacheRoot,
    [string]$GodotCppPath,
    [switch]$Offline,
    [switch]$Force,
    [switch]$CleanCache
)

$ErrorActionPreference = "Stop"

function Invoke-Git {
    param([string[]]$Arguments)

    & git @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "git failed with exit code ${LASTEXITCODE}: git $($Arguments -join ' ')"
    }
}

function Assert-SafeCachePath {
    param([string]$Path)

    $full = [IO.Path]::GetFullPath($Path).TrimEnd('\')
    $root = [IO.Path]::GetPathRoot($full).TrimEnd('\')
    if ([string]::IsNullOrWhiteSpace($full) -or $full -eq $root -or $full.Length -lt 8) {
        throw "Refusing unsafe cache path: $Path"
    }
}

if ([string]::IsNullOrWhiteSpace($LockPath)) {
    $LockPath = Join-Path $ProjectRoot "third_party\native-toolchain.lock.json"
}
if ([string]::IsNullOrWhiteSpace($CacheRoot)) {
    $CacheRoot = Join-Path $ProjectRoot ".cache\dependencies"
}
if ([string]::IsNullOrWhiteSpace($GodotCppPath)) {
    $GodotCppPath = Join-Path $ProjectRoot "native\windows\godot-cpp"
}

if (-not (Test-Path -LiteralPath $LockPath -PathType Leaf)) {
    throw "Native dependency lock not found: $LockPath"
}
if ($null -eq (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "git is required to bootstrap native dependencies."
}

$lock = Get-Content -LiteralPath $LockPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($lock.schema_version -ne 1 -or [string]::IsNullOrWhiteSpace($lock.godot_cpp.source) -or $lock.godot_cpp.commit -notmatch '^[0-9a-fA-F]{40}$') {
    throw "Native dependency lock is invalid: $LockPath"
}

$source = [string]$lock.godot_cpp.source
$commit = ([string]$lock.godot_cpp.commit).ToLowerInvariant()
$mirror = Join-Path $CacheRoot "godot-cpp.git"

if ($CleanCache) {
    Assert-SafeCachePath $CacheRoot
    if (Test-Path -LiteralPath $CacheRoot) {
        Remove-Item -LiteralPath $CacheRoot -Recurse -Force
    }
    Write-Host "Native dependency cache removed: $CacheRoot"
    if (-not $Force) {
        return
    }
}

if (-not (Test-Path -LiteralPath $mirror)) {
    if ($Offline) {
        throw "Offline cache is missing: $mirror"
    }
    New-Item -ItemType Directory -Path $CacheRoot -Force | Out-Null
    Invoke-Git @("clone", "--mirror", $source, $mirror)
}
elseif (-not $Offline) {
    Invoke-Git @("-C", $mirror, "remote", "set-url", "origin", $source)
    Invoke-Git @("-C", $mirror, "remote", "update", "--prune")
}

$previousErrorPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
& git -C $mirror cat-file -e "$commit`^{commit}" 2>$null
$commitCheckExitCode = $LASTEXITCODE
$ErrorActionPreference = $previousErrorPreference
if ($commitCheckExitCode -ne 0) {
    throw "Locked godot-cpp commit is unavailable: $commit"
}

if (Test-Path -LiteralPath $GodotCppPath) {
    $gitDir = Join-Path $GodotCppPath ".git"
    if (-not (Test-Path -LiteralPath $gitDir)) {
        if (-not $Force) {
            throw "godot-cpp destination exists but is not a Git checkout: $GodotCppPath"
        }
        Remove-Item -LiteralPath $GodotCppPath -Recurse -Force
    }
    else {
        $current = (& git -C $GodotCppPath rev-parse HEAD).Trim().ToLowerInvariant()
        if ($LASTEXITCODE -ne 0) {
            throw "Unable to read godot-cpp checkout: $GodotCppPath"
        }
        if ($current -eq $commit) {
            $workingTree = (& git -C $GodotCppPath status --porcelain | Out-String).Trim()
            if ([string]::IsNullOrWhiteSpace($workingTree)) {
                Write-Host "godot-cpp already matches lock: $commit"
                return
            }
            if (-not $Force) {
                throw "godot-cpp working tree has local changes. Use -Force to replace it."
            }
        }
        elseif (-not $Force) {
            throw "godot-cpp checkout does not match lock. Expected $commit, got $current. Use -Force to replace it."
        }
        Remove-Item -LiteralPath $GodotCppPath -Recurse -Force
    }
}

$parent = Split-Path -Parent $GodotCppPath
New-Item -ItemType Directory -Path $parent -Force | Out-Null
Invoke-Git @("clone", "--no-checkout", $mirror, $GodotCppPath)
Invoke-Git @("-C", $GodotCppPath, "checkout", "--detach", $commit)

$actual = (& git -C $GodotCppPath rev-parse HEAD).Trim().ToLowerInvariant()
if ($actual -ne $commit) {
    throw "godot-cpp verification failed. Expected $commit, got $actual"
}

Write-Host "godot-cpp bootstrap passed: $actual"
Write-Host "Cache: $mirror"
