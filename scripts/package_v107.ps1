param(
    [string]$CandidateId = "",
    [string]$PythonExe = ""
)

$ErrorActionPreference = "Stop"
$arguments = @{
    CandidateId = $CandidateId
    PythonExe = $PythonExe
    Version = "1.0.7"
    CandidatePrefix = "V107"
    AggregateVerificationScript = "verify_v107.ps1"
    PackageVerificationScript = "verify_v107_package.ps1"
}

& (Join-Path $PSScriptRoot "package_v105.ps1") @arguments
if ($LASTEXITCODE -ne 0) {
    throw "v1.0.7 candidate packaging failed with exit code $LASTEXITCODE"
}
