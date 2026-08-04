param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("candidate", "published")]
    [string]$Mode,
    [Parameter(Mandatory = $true)]
    [string]$PackagePath,
    [Parameter(Mandatory = $true)]
    [string]$ExpectedSourceHead,
    [string]$ExpectedVersion = "1.0.7",
    [string]$ExpectedZipSha256 = "",
    [string]$Tag = "",
    [string]$TagTargetCommit = "",
    [string]$ReleaseUrl = "",
    [string]$ChecksumsPath = "",
    [switch]$SkipLocationCheck,
    [string]$PythonExe = ""
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$AppRoot = Join-Path $RepoRoot "apps\windows-v1"
. (Join-Path $PSScriptRoot "v10_tools.ps1")

if ($ExpectedVersion -ne "1.0.7") {
    throw "v1.0.7 package verification cannot validate version '$ExpectedVersion'."
}
if ([string]::IsNullOrWhiteSpace($PythonExe)) {
    $PythonExe = Get-V10Python -RepoRoot $RepoRoot
}

$arguments = @(
    (Join-Path $AppRoot "tests\verify_v107_package.py"),
    "--mode", $Mode,
    "--package", ([IO.Path]::GetFullPath($PackagePath)),
    "--version", $ExpectedVersion,
    "--platform", "windows-x86_64",
    "--architecture", "x86_64",
    "--source-head", $ExpectedSourceHead
)

if (-not $SkipLocationCheck) {
    $artifactRoot = if ($Mode -eq "candidate") {
        Join-Path $RepoRoot ".artifacts\candidates\v$ExpectedVersion"
    }
    else {
        Join-Path $RepoRoot ".artifacts\published\v$ExpectedVersion"
    }
    $arguments += @("--artifact-root", $artifactRoot)
}

if ($Mode -eq "published") {
    foreach ($required in @{
        ExpectedZipSha256 = $ExpectedZipSha256
        Tag = $Tag
        TagTargetCommit = $TagTargetCommit
        ReleaseUrl = $ReleaseUrl
        ChecksumsPath = $ChecksumsPath
    }.GetEnumerator()) {
        if ([string]::IsNullOrWhiteSpace([string]$required.Value)) {
            throw "Published mode requires -$($required.Key)."
        }
    }
    $arguments += @(
        "--expected-zip-sha256", $ExpectedZipSha256,
        "--tag", $Tag,
        "--tag-target-commit", $TagTargetCommit,
        "--release-url", $ReleaseUrl,
        "--checksums", ([IO.Path]::GetFullPath($ChecksumsPath))
    )
}
elseif (-not [string]::IsNullOrWhiteSpace($ExpectedZipSha256)) {
    $arguments += @("--expected-zip-sha256", $ExpectedZipSha256)
}

& $PythonExe @arguments
if ($LASTEXITCODE -ne 0) {
    throw "v1.0.7 $Mode package identity verification failed with exit code $LASTEXITCODE"
}
