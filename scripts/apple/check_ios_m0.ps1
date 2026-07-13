param(
    [string]$ProjectRoot = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)),
    [switch]$AllowNonIosBranch
)

$ErrorActionPreference = 'Stop'
$failures = [System.Collections.Generic.List[string]]::new()

function Add-Failure([string]$Rule, [string]$Path) {
    $failures.Add("[$Rule] $Path")
}

$requiredFiles = @(
    'apple/README.md',
    'apple/PROJECT_LAYOUT.md',
    'apple/Config/Identifiers.example.xcconfig',
    'apple/Packages/SalaryCore/README.md',
    'apple/Shared/Models/README.md',
    'apple/Shared/Resources/README.md',
    'apple/App/README.md',
    'apple/WidgetExtension/README.md',
    'apple/WatchApp/README.md',
    'apple/WatchWidgetExtension/README.md',
    'apple/Tests/README.md',
    'apple/Playgrounds/README.md',
    'shared/salary-schema/v1/README.md',
    'doc/releases/ios-v0.1/prd.md',
    'doc/releases/ios-v0.1/dev_plan_ios-v0.1.md',
    'doc/releases/ios-v0.1/progress_ios-v0.1.md',
    'doc/releases/ios-v0.1/baseline.md',
    'doc/releases/ios-v0.1/environment-and-identifiers.md',
    'doc/releases/ios-v0.1/playgrounds-verification.md'
)

foreach ($relative in $requiredFiles) {
    $path = Join-Path $ProjectRoot $relative
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Add-Failure 'required-file' $relative
    }
}

$branch = (& git -C $ProjectRoot branch --show-current 2>$null).Trim()
if (-not $AllowNonIosBranch -and $branch -ne 'ios-main') {
    Add-Failure 'branch' "expected ios-main, actual $branch"
}

$scanRoots = @('apple', 'shared/salary-schema/v1', 'doc/releases/ios-v0.1', 'scripts/apple')
$textFiles = @()
foreach ($relative in $scanRoots) {
    $root = Join-Path $ProjectRoot $relative
    if (Test-Path -LiteralPath $root) {
        $textFiles += Get-ChildItem -LiteralPath $root -Recurse -File | Where-Object {
            $_.Extension -in @('.md', '.ps1', '.json', '.swift', '.xcconfig', '.yml', '.yaml')
        }
    }
}

$strictUtf8 = [System.Text.UTF8Encoding]::new($false, $true)
$mojibakeMarkers = @(
    [string]::Concat([char]0x951F, [char]0x65A4, [char]0x62F7),
    [string]::Concat([char]0x70EB, [char]0x70EB, [char]0x70EB),
    [string]::Concat([char]0x5C6F, [char]0x5C6F, [char]0x5C6F)
)
$absolutePathScanExclusions = @(
    'scripts/apple/check_ios_m0.ps1',
    'scripts/apple/test_check_ios_m0.ps1'
)
$projectRootPrefix = $ProjectRoot.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar

foreach ($file in $textFiles) {
    if (-not $file.FullName.StartsWith($projectRootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        Add-Failure 'scan-boundary' $file.FullName
        continue
    }
    $relative = $file.FullName.Substring($projectRootPrefix.Length).Replace('\', '/')
    try {
        $content = [IO.File]::ReadAllText($file.FullName, $strictUtf8)
    } catch {
        Add-Failure 'utf8' $relative
        continue
    }

    $hasMojibake = $content.Contains([char]0xFFFD)
    foreach ($marker in $mojibakeMarkers) {
        if ($content.Contains($marker)) {
            $hasMojibake = $true
            break
        }
    }
    if ($hasMojibake) {
        Add-Failure 'mojibake' $relative
    }

    if ($relative -notin $absolutePathScanExclusions -and
        $content -match '(?i)(?:[A-Z]:\\Users\\[^\\\s]+|/Users/[^/\s]+|/home/[^/\s]+)') {
        Add-Failure 'absolute-user-path' $relative
    }

    if ($content -match '(?i)(?:BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY|gh[pousr]_[A-Za-z0-9_]{20,}|AIza[0-9A-Za-z_-]{30,})') {
        Add-Failure 'secret-pattern' $relative
    }
}

$identifierPath = Join-Path $ProjectRoot 'apple/Config/Identifiers.example.xcconfig'
if (Test-Path -LiteralPath $identifierPath) {
    $identifierText = [IO.File]::ReadAllText($identifierPath, $strictUtf8)
    if ($identifierText -notmatch 'DEVELOPMENT_TEAM\s*=\s*YOUR_TEAM_ID') {
        Add-Failure 'team-placeholder' 'apple/Config/Identifiers.example.xcconfig'
    }
    if ($identifierText -notmatch 'ORGANIZATION_IDENTIFIER\s*=\s*com\.example') {
        Add-Failure 'organization-placeholder' 'apple/Config/Identifiers.example.xcconfig'
    }
}

$localIdentifier = Join-Path $ProjectRoot 'apple/Config/Identifiers.local.xcconfig'
if (Test-Path -LiteralPath $localIdentifier) {
    & git -C $ProjectRoot check-ignore --quiet -- 'apple/Config/Identifiers.local.xcconfig'
    if ($LASTEXITCODE -ne 0) {
        Add-Failure 'private-config-ignore' 'apple/Config/Identifiers.local.xcconfig'
    }
}

if ($failures.Count -gt 0) {
    Write-Host "iOS M0 check failed ($($failures.Count))" -ForegroundColor Red
    $failures | Sort-Object -Unique | ForEach-Object { Write-Host $_ }
    exit 1
}

Write-Host "iOS M0 check passed: branch=$branch files=$($requiredFiles.Count) scanned=$($textFiles.Count)" -ForegroundColor Green
exit 0
