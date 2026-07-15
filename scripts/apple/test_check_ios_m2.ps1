$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$mutation = Join-Path $root 'apple\App\.localization-mutation.swift'

Push-Location $root
try {
    & (Join-Path $PSScriptRoot 'check_ios_m2.ps1') -RequireSwift
    if ($LASTEXITCODE -ne 0) { throw 'M2 positive gate failed.' }

    New-Item -ItemType Directory -Path (Split-Path $mutation) -Force | Out-Null
    [System.IO.File]::WriteAllText(
        $mutation,
        'let mutation = "hardcoded-CJK-' + [char]0x4E2D + [char]0x6587 + '"',
        [System.Text.UTF8Encoding]::new($false)
    )
    try {
        $previousPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        python scripts/apple/validate_apple_localization.py --root $root *> $null
        $mutationExit = $LASTEXITCODE
        $ErrorActionPreference = $previousPreference
        if ($mutationExit -eq 0) { throw 'Hardcoded localization mutation was not rejected.' }
    } finally {
        Remove-Item -LiteralPath $mutation -Force -ErrorAction SilentlyContinue
    }

    python scripts/apple/validate_apple_localization.py --root $root
    if ($LASTEXITCODE -ne 0) { throw 'Mutation test did not restore localization state.' }
    Write-Host 'IOS_M2_MUTATION_PASS'
} finally {
    Pop-Location
}
