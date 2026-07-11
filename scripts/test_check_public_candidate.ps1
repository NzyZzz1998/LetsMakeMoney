param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path)

$ErrorActionPreference = "Stop"
$checker = Join-Path $Root 'scripts/check_public_candidate.ps1'
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ("lmm-public-check-" + [guid]::NewGuid().ToString('N'))

try {
    $clean = Join-Path $tempRoot 'clean'
    New-Item -ItemType Directory -Path (Join-Path $clean 'doc/releases/v0.7') -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $clean 'README.md'), "# Sample`n", [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path $clean 'doc/current.md'), "# Current`nv0.7 Beta`nV07-A0`n", [Text.UTF8Encoding]::new($false))
    & $checker -Root $clean
    if ($LASTEXITCODE -ne 0) { throw 'Clean fixture must pass.' }

    $risky = Join-Path $tempRoot 'risky'
    New-Item -ItemType Directory -Path (Join-Path $risky 'temp') -Force | Out-Null
    $riskContent = "pass" + "word='" + ("a" * 16) + "'"
    [IO.File]::WriteAllText((Join-Path $risky 'temp/secret.txt'), $riskContent, [Text.UTF8Encoding]::new($false))
    & $checker -Root $risky
    if ($LASTEXITCODE -eq 0) { throw 'Risk fixture must fail.' }

    Write-Host 'Public candidate checker tests passed.' -ForegroundColor Green
} finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
