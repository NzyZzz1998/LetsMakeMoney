param(
    [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"
$bootstrap = Join-Path $ProjectRoot "scripts\bootstrap_native_dependencies.ps1"
if (-not (Test-Path -LiteralPath $bootstrap)) {
    throw "Missing native dependency bootstrap script: $bootstrap"
}

$sandbox = Join-Path ([IO.Path]::GetTempPath()) ("lmm-native-bootstrap-" + [Guid]::NewGuid().ToString("N"))
$source = Join-Path $sandbox "source"
$cache = Join-Path $sandbox "cache"
$destination = Join-Path $sandbox "godot-cpp"
$lockPath = Join-Path $sandbox "lock.json"

function Invoke-ExpectFailure {
    param([scriptblock]$Action, [string]$ExpectedText)

    $failed = $false
    try {
        & $Action
    }
    catch {
        $failed = $true
        if ($_.Exception.Message -notmatch [Regex]::Escape($ExpectedText)) {
            throw "Expected failure containing '$ExpectedText', got: $($_.Exception.Message)"
        }
    }
    if (-not $failed) {
        throw "Expected command to fail: $ExpectedText"
    }
}

try {
    New-Item -ItemType Directory -Path $source -Force | Out-Null
    git -C $source init --quiet
    git -C $source config user.name "Bootstrap Test"
    git -C $source config user.email "bootstrap@example.invalid"
    [IO.File]::WriteAllText((Join-Path $source "README.md"), "fixture`n", [Text.UTF8Encoding]::new($false))
    git -C $source add README.md
    git -C $source commit --quiet -m "fixture"
    $commit = (git -C $source rev-parse HEAD).Trim()

    $lock = [ordered]@{
        schema_version = 1
        godot_cpp = [ordered]@{
            source = $source
            commit = $commit
        }
    }
    [IO.File]::WriteAllText($lockPath, ($lock | ConvertTo-Json -Depth 5), [Text.UTF8Encoding]::new($false))

    & $bootstrap -ProjectRoot $ProjectRoot -LockPath $lockPath -CacheRoot $cache -GodotCppPath $destination
    if ((git -C $destination rev-parse HEAD).Trim() -ne $commit) {
        throw "Online bootstrap did not checkout the locked commit."
    }

    Add-Content -LiteralPath (Join-Path $destination "README.md") -Value "dirty"
    Invoke-ExpectFailure -ExpectedText "godot-cpp working tree has local changes" -Action {
        & $bootstrap -ProjectRoot $ProjectRoot -LockPath $lockPath -CacheRoot $cache -GodotCppPath $destination
    }
    git -C $destination checkout -- README.md

    Remove-Item -LiteralPath $destination -Recurse -Force
    & $bootstrap -ProjectRoot $ProjectRoot -LockPath $lockPath -CacheRoot $cache -GodotCppPath $destination -Offline
    if ((git -C $destination rev-parse HEAD).Trim() -ne $commit) {
        throw "Offline bootstrap did not checkout the locked commit."
    }

    Remove-Item -LiteralPath $destination -Recurse -Force
    Remove-Item -LiteralPath $cache -Recurse -Force
    Invoke-ExpectFailure -ExpectedText "Offline cache is missing" -Action {
        & $bootstrap -ProjectRoot $ProjectRoot -LockPath $lockPath -CacheRoot $cache -GodotCppPath $destination -Offline
    }

    $lock.godot_cpp.commit = "0000000000000000000000000000000000000000"
    [IO.File]::WriteAllText($lockPath, ($lock | ConvertTo-Json -Depth 5), [Text.UTF8Encoding]::new($false))
    Invoke-ExpectFailure -ExpectedText "Locked godot-cpp commit is unavailable" -Action {
        & $bootstrap -ProjectRoot $ProjectRoot -LockPath $lockPath -CacheRoot $cache -GodotCppPath $destination
    }

    Write-Host "Native dependency bootstrap tests passed." -ForegroundColor Green
}
finally {
    if (Test-Path -LiteralPath $sandbox) {
        Remove-Item -LiteralPath $sandbox -Recurse -Force
    }
}
