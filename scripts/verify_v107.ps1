param(
    [ValidateSet("M5", "M7")]
    [string]$Milestone = "M5",
    [string]$PythonExe = "",
    [string]$CandidatePath = ""
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "v10_tools.ps1")

if ([string]::IsNullOrWhiteSpace($PythonExe)) {
    $PythonExe = Get-V10Python -RepoRoot $RepoRoot
}

& (Join-Path $PSScriptRoot "verify_windows_current.ps1")
if ($LASTEXITCODE -ne 0) {
    throw "v1.0.7 current aggregate verification failed with exit code $LASTEXITCODE"
}

if ($Milestone -eq "M7") {
    if ([string]::IsNullOrWhiteSpace($CandidatePath)) {
        throw "M7 requires -CandidatePath pointing to a v1.0.7 candidate Zip."
    }
    $SourceHead = (git -C $RepoRoot rev-parse HEAD).Trim()
    & (Join-Path $PSScriptRoot "verify_v107_package.ps1") `
        -Mode candidate `
        -PackagePath $CandidatePath `
        -ExpectedSourceHead $SourceHead `
        -PythonExe $PythonExe
    if ($LASTEXITCODE -ne 0) {
        throw "v1.0.7 M7 package verification failed with exit code $LASTEXITCODE"
    }
}

Write-Host "PASS LetsMakeMoney v1.0.7 aggregate verification ($Milestone)" -ForegroundColor Green
