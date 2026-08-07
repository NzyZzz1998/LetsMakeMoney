param(
    [string]$CandidateId = "",
    [string]$PythonExe = ""
)

$ErrorActionPreference = "Stop"
$arguments = @{
    CandidateId = $CandidateId
    PythonExe = $PythonExe
    Version = "1.0.8"
    CandidatePrefix = "V10F"
    AggregateVerificationScript = "verify_windows_current.ps1"
    PackageVerificationScript = "verify_v10f_package.ps1"
}

& (Join-Path $PSScriptRoot "package_v105.ps1") @arguments
if ($LASTEXITCODE -ne 0) {
    throw "v1.0.8 candidate packaging failed with exit code $LASTEXITCODE"
}
