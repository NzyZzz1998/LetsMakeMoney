$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path

Push-Location $root
try {
    & (Join-Path $PSScriptRoot 'check_ios_m1.ps1')
    if ($LASTEXITCODE -ne 0) { throw 'M1 positive gate failed.' }

    $manifest = 'shared/salary-schema/v1/holidays/manifest.json'
    $original = Get-Content -Raw -Encoding UTF8 $manifest
    try {
        $mutated = $original -replace '9920DF6D9EA2E5CF7747910B24AF1041BDA94716465D6E65448B9A5345203C3F', ('0' * 64)
        [System.IO.File]::WriteAllText((Resolve-Path $manifest), $mutated, [System.Text.UTF8Encoding]::new($false))
        $previousPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        python scripts/apple/validate_salary_contract.py holidays $manifest *> $null
        $mutationExit = $LASTEXITCODE
        $ErrorActionPreference = $previousPreference
        if ($mutationExit -eq 0) { throw 'Mutated checksum was not rejected.' }
    } finally {
        [System.IO.File]::WriteAllText((Resolve-Path $manifest), $original, [System.Text.UTF8Encoding]::new($false))
    }

    python scripts/apple/validate_salary_contract.py holidays $manifest *> $null
    if ($LASTEXITCODE -ne 0) { throw 'Mutation test did not restore manifest.' }
    Write-Host 'IOS_M1_MUTATION_PASS'
} finally {
    Pop-Location
}
