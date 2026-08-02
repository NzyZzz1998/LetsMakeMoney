param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("candidate", "published")]
    [string]$Mode,
    [Parameter(Mandatory = $true)]
    [string]$PackagePath,
    [Parameter(Mandatory = $true)]
    [string]$ExpectedSourceHead,
    [string]$ExpectedVersion = "1.0.6",
    [string]$ExpectedZipSha256 = "",
    [string]$Tag = "",
    [string]$TagTargetCommit = "",
    [string]$ReleaseUrl = "",
    [string]$ChecksumsPath = "",
    [switch]$SkipLocationCheck,
    [string]$PythonExe = ""
)

$ErrorActionPreference = "Stop"
if ($ExpectedVersion -ne "1.0.6") {
    throw "v1.0.6 package verification cannot validate version '$ExpectedVersion'."
}
$arguments = @{
    Mode = $Mode
    PackagePath = $PackagePath
    ExpectedSourceHead = $ExpectedSourceHead
    ExpectedVersion = $ExpectedVersion
    ExpectedZipSha256 = $ExpectedZipSha256
    Tag = $Tag
    TagTargetCommit = $TagTargetCommit
    ReleaseUrl = $ReleaseUrl
    ChecksumsPath = $ChecksumsPath
    SkipLocationCheck = $SkipLocationCheck
    PythonExe = $PythonExe
}

& (Join-Path $PSScriptRoot "verify_v105_package.ps1") @arguments
if ($LASTEXITCODE -ne 0) {
    throw "v1.0.6 $Mode package identity verification failed with exit code $LASTEXITCODE"
}
