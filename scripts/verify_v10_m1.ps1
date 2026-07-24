param(
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$App = Join-Path $Root "apps\windows-v1"
$NodeModules = Join-Path $App "node_modules"
$ApprovedNodeModules = Join-Path $Root "spikes\v1.0-ui\tauri-react\node_modules"
. (Join-Path $PSScriptRoot "v10_tools.ps1")
$Node = Get-V10Node
$Python = Get-V10Python
$Cargo = Get-V10Cargo -RepoRoot $Root
$CreatedJunction = $false

try {
    if (-not $SkipBuild) {
        if (-not (Test-Path -LiteralPath $NodeModules)) {
            if (-not (Test-Path -LiteralPath $ApprovedNodeModules)) {
                throw "Frontend dependencies are missing. Run 'npm ci' in apps\windows-v1."
            }
            New-Item -ItemType Junction -Path $NodeModules -Target $ApprovedNodeModules | Out-Null
            $CreatedJunction = $true
        }

        Push-Location $App
        try {
            & $Node (Join-Path $NodeModules "typescript\bin\tsc")
            if ($LASTEXITCODE -ne 0) { throw "TypeScript build failed." }
            & $Node (Join-Path $NodeModules "vite\bin\vite.js") build
            if ($LASTEXITCODE -ne 0) { throw "Frontend build failed." }
        }
        finally {
            Pop-Location
        }
    }

    & $Python (Join-Path $App "tests\verify_m1.py")
    if ($LASTEXITCODE -ne 0) { throw "M1 contract verification failed." }

    Push-Location (Join-Path $App "src-tauri")
    try {
        & $Cargo +stable check --locked --offline --quiet
        if ($LASTEXITCODE -ne 0) { throw "Rust/Tauri compile check failed." }
    }
    finally {
        Pop-Location
    }

    Write-Host "V10-M1 PASS"
}
finally {
    if ($CreatedJunction -and (Test-Path -LiteralPath $NodeModules)) {
        $item = Get-Item -LiteralPath $NodeModules -Force
        if ($item.FullName -eq $NodeModules -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            [System.IO.Directory]::Delete($NodeModules)
        }
    }
}
