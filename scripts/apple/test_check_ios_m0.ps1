param([string]$ProjectRoot = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))

$ErrorActionPreference = 'Stop'
$checker = Join-Path $PSScriptRoot 'check_ios_m0.ps1'
$powershellExe = (Get-Process -Id $PID).Path

& $powershellExe -NoProfile -ExecutionPolicy Bypass -File $checker -ProjectRoot $ProjectRoot
if ($LASTEXITCODE -ne 0) {
    throw 'Real project M0 check should pass.'
}

$fixture = Join-Path ([IO.Path]::GetTempPath()) ("lmm-ios-m0-" + [Guid]::NewGuid().ToString('N'))
try {
    New-Item -ItemType Directory -Path $fixture -Force | Out-Null
    $requiredFiles = @(
        'apple/README.md','apple/PROJECT_LAYOUT.md','apple/Config/Identifiers.example.xcconfig',
        'apple/Packages/SalaryCore/README.md','apple/Shared/Models/README.md','apple/Shared/Resources/README.md',
        'apple/App/README.md','apple/WidgetExtension/README.md','apple/WatchApp/README.md',
        'apple/WatchWidgetExtension/README.md','apple/Tests/README.md','apple/Playgrounds/README.md',
        'shared/salary-schema/v1/README.md','doc/releases/ios-v0.1/prd.md',
        'doc/releases/ios-v0.1/dev_plan_ios-v0.1.md','doc/releases/ios-v0.1/progress_ios-v0.1.md',
        'doc/releases/ios-v0.1/baseline.md','doc/releases/ios-v0.1/environment-and-identifiers.md',
        'doc/releases/ios-v0.1/playgrounds-verification.md'
    )
    foreach ($relative in $requiredFiles) {
        $path = Join-Path $fixture $relative
        New-Item -ItemType Directory -Path (Split-Path $path) -Force | Out-Null
        [IO.File]::WriteAllText($path, "fixture`n", [Text.UTF8Encoding]::new($false))
    }
    [IO.File]::WriteAllText(
        (Join-Path $fixture 'apple/Config/Identifiers.example.xcconfig'),
        "DEVELOPMENT_TEAM = YOUR_TEAM_ID`nORGANIZATION_IDENTIFIER = com.example`n",
        [Text.UTF8Encoding]::new($false)
    )
    & git -C $fixture init --quiet

    & $powershellExe -NoProfile -ExecutionPolicy Bypass -File $checker -ProjectRoot $fixture -AllowNonIosBranch
    if ($LASTEXITCODE -ne 0) {
        throw 'Clean fixture should pass.'
    }

    [IO.File]::AppendAllText((Join-Path $fixture 'apple/README.md'), "C:\Users\private-user\secret`n")
    & $powershellExe -NoProfile -ExecutionPolicy Bypass -File $checker -ProjectRoot $fixture -AllowNonIosBranch *> $null
    if ($LASTEXITCODE -eq 0) {
        throw 'Absolute user path fixture should fail.'
    }

    Remove-Item -LiteralPath (Join-Path $fixture 'apple/README.md') -Force
    & $powershellExe -NoProfile -ExecutionPolicy Bypass -File $checker -ProjectRoot $fixture -AllowNonIosBranch *> $null
    if ($LASTEXITCODE -eq 0) {
        throw 'Missing required file fixture should fail.'
    }
} finally {
    if (Test-Path -LiteralPath $fixture) {
        Remove-Item -LiteralPath $fixture -Recurse -Force
    }
}

Write-Host 'iOS M0 checker tests passed' -ForegroundColor Green
