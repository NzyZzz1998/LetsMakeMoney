param(
    [string]$CandidateId = "",
    [string]$PythonExe = ""
)

$ErrorActionPreference = "Stop"
$arguments = @{
    CandidateId = $CandidateId
    PythonExe = $PythonExe
    Version = "1.0.6"
    CandidatePrefix = "V106"
    AggregateVerificationScript = "verify_v106.ps1"
    PackageVerificationScript = "verify_v106_package.ps1"
}

& (Join-Path $PSScriptRoot "package_v105.ps1") @arguments
if ($LASTEXITCODE -ne 0) {
    throw "v1.0.6 candidate packaging failed with exit code $LASTEXITCODE"
}
