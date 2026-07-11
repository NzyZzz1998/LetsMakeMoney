param([string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot))

$ErrorActionPreference = 'Stop'
$checker = Join-Path $ProjectRoot 'scripts/check_third_party_compliance.ps1'
$stager = Join-Path $ProjectRoot 'scripts/stage_release_licenses.ps1'
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ("lmm-third-party-" + [guid]::NewGuid().ToString('N'))

function Invoke-Check([string]$Root, [string]$Package = '') {
    if ($Package) { & $checker -ProjectRoot $Root -PackageRoot $Package }
    else { & $checker -ProjectRoot $Root }
    return $?
}

try {
    New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
    foreach ($relative in @('LICENSE','ASSETS_LICENSE.md','ASSETS_MANIFEST.md','THIRD_PARTY_NOTICES.md')) {
        Copy-Item -LiteralPath (Join-Path $ProjectRoot $relative) -Destination (Join-Path $tempRoot $relative) -Force
    }
    Copy-Item -LiteralPath (Join-Path $ProjectRoot 'third_party') -Destination (Join-Path $tempRoot 'third_party') -Recurse -Force
    Copy-Item -LiteralPath (Join-Path $ProjectRoot 'licenses') -Destination (Join-Path $tempRoot 'licenses') -Recurse -Force

    $package = Join-Path $tempRoot 'package'
    New-Item -ItemType Directory -Path $package -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $package 'LetsMakeMoney.exe'), 'fixture')
    [IO.File]::WriteAllText((Join-Path $package 'letsmakemoney_native.dll'), 'fixture')
    [IO.File]::WriteAllText((Join-Path $package 'manifest.json'), '{"package_name":"fixture","version":"0.7-beta","files":[]}')
    & $stager -ProjectRoot $tempRoot -StageDir $package
    if (-not (Invoke-Check $tempRoot $package)) { throw 'Normal controlled package must pass.' }

    $depsPath = Join-Path $tempRoot 'third_party/dependencies.json'
    $depsBackup = [IO.File]::ReadAllText($depsPath)
    $deps = $depsBackup | ConvertFrom-Json
    $deps.dependencies = @($deps.dependencies | Where-Object { $_.name -ne 'Godot Engine' })
    $deps | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $depsPath -Encoding UTF8
    if (Invoke-Check $tempRoot) { throw 'Missing manifest dependency must fail.' }
    [IO.File]::WriteAllText($depsPath, $depsBackup)

    $licensePath = Join-Path $tempRoot 'licenses/third-party/Godot/LICENSE.txt'
    $licenseBackup = [IO.File]::ReadAllBytes($licensePath)
    Remove-Item -LiteralPath $licensePath -Force
    if (Invoke-Check $tempRoot) { throw 'Missing license text must fail.' }
    [IO.File]::WriteAllBytes($licensePath, $licenseBackup)

    [IO.File]::WriteAllText((Join-Path $package 'unregistered.dll'), 'fixture')
    if (Invoke-Check $tempRoot $package) { throw 'Unregistered package DLL must fail.' }
    Remove-Item -LiteralPath (Join-Path $package 'unregistered.dll') -Force

    [IO.File]::WriteAllText((Join-Path $package 'unregistered.ttf'), 'fixture')
    if (Invoke-Check $tempRoot $package) { throw 'Unregistered package font must fail.' }
    Remove-Item -LiteralPath (Join-Path $package 'unregistered.ttf') -Force

    $noticePath = Join-Path $tempRoot 'THIRD_PARTY_NOTICES.md'
    $noticeBackup = [IO.File]::ReadAllText($noticePath)
    [IO.File]::WriteAllText($noticePath, $noticeBackup.Replace('4.7.stable.official.5b4e0cb0f','4.7.invalid'))
    if (Invoke-Check $tempRoot) { throw 'Notice version mismatch must fail.' }
    [IO.File]::WriteAllText($noticePath, $noticeBackup)

    if (-not (Invoke-Check $tempRoot $package)) { throw 'Restored controlled package must pass.' }
    Write-Host 'Third-party compliance tests passed.' -ForegroundColor Green
} finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
