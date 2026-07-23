param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [switch]$Apply,
    [switch]$AcceptanceRuntimeCopies
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path.TrimEnd('\', '/')
$rootPrefix = $root + [IO.Path]::DirectorySeparatorChar

$directoryCandidates = @(
    ".tmp_appdata",
    ".tmp_ci",
    ".tmp_release",
    ".tmp_ui_review",
    ".tmp_ui_review_appdata",
    ".tmp_installer",
    ".manual-test",
    "_lmm_verify",
    ".godot_user_v05"
)
$filePatterns = @(".tmp_*.log")
$protectedPaths = @(
    ".tmp_acceptance",
    ".cache",
    ".godot",
    "build",
    "deliverables",
    "releases",
    "native"
)

function Resolve-SafeCandidate {
    param([Parameter(Mandatory=$true)][string]$Path)

    $resolved = (Resolve-Path -LiteralPath $Path).Path
    if (-not $resolved.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to inspect a path outside the project root: $resolved"
    }
    $item = Get-Item -LiteralPath $resolved -Force
    if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
        throw "Refusing to remove a reparse point: $resolved"
    }
    return $item
}

$candidates = [System.Collections.Generic.List[object]]::new()
foreach ($relativePath in $directoryCandidates) {
    $path = Join-Path $root $relativePath
    if (-not (Test-Path -LiteralPath $path)) { continue }
    $item = Resolve-SafeCandidate -Path $path
    $files = @(Get-ChildItem -LiteralPath $item.FullName -Recurse -Force -File -ErrorAction Stop)
    $candidates.Add([pscustomobject]@{
        relative_path = $relativePath
        full_path = $item.FullName
        type = "directory"
        file_count = $files.Count
        bytes = [int64](($files | Measure-Object Length -Sum).Sum)
    })
}
foreach ($pattern in $filePatterns) {
    foreach ($file in @(Get-ChildItem -LiteralPath $root -File -Force -Filter $pattern)) {
        $item = Resolve-SafeCandidate -Path $file.FullName
        $candidates.Add([pscustomobject]@{
            relative_path = $item.Name
            full_path = $item.FullName
            type = "file"
            file_count = 1
            bytes = [int64]$item.Length
        })
    }
}
if ($AcceptanceRuntimeCopies) {
    $acceptanceRoot = Join-Path $root ".tmp_acceptance"
    if (Test-Path -LiteralPath $acceptanceRoot -PathType Container) {
        foreach ($caseDirectory in @(Get-ChildItem -LiteralPath $acceptanceRoot -Directory -Force)) {
            foreach ($runtimeName in @("extract", "extracted", "unpacked", "package")) {
                $runtimePath = Join-Path $caseDirectory.FullName $runtimeName
                if (-not (Test-Path -LiteralPath $runtimePath -PathType Container)) { continue }
                $item = Resolve-SafeCandidate -Path $runtimePath
                $files = @(Get-ChildItem -LiteralPath $item.FullName -Recurse -Force -File -ErrorAction Stop)
                $relativePath = $item.FullName.Substring($rootPrefix.Length)
                $candidates.Add([pscustomobject]@{
                    relative_path = $relativePath
                    full_path = $item.FullName
                    type = "acceptance-runtime-copy"
                    file_count = $files.Count
                    bytes = [int64](($files | Measure-Object Length -Sum).Sum)
                })
            }
        }
    }
}

$candidatePaths = @($candidates | ForEach-Object { $_.relative_path })
foreach ($protectedPath in $protectedPaths) {
    if ($candidatePaths -contains $protectedPath) {
        throw "Protected path entered the cleanup candidate list: $protectedPath"
    }
}

$totalBytes = [int64](($candidates | Measure-Object bytes -Sum).Sum)
$totalFiles = [int](($candidates | Measure-Object file_count -Sum).Sum)
$mode = if ($Apply) { "apply" } else { "preview" }
Write-Host "Local generated cleanup ($mode)" -ForegroundColor Cyan
$candidates | Select-Object relative_path, type, file_count, bytes | Format-Table -AutoSize
Write-Host "Summary: candidates=$($candidates.Count), files=$totalFiles, bytes=$totalBytes"
Write-Host "Protected: $($protectedPaths -join ', ')"

if (-not $Apply) {
    Write-Host "Preview only. Re-run with -Apply to remove these candidates."
    return
}

foreach ($candidate in $candidates) {
    if ($candidate.type -in @("directory", "acceptance-runtime-copy")) {
        Remove-Item -LiteralPath $candidate.full_path -Recurse -Force
    } else {
        Remove-Item -LiteralPath $candidate.full_path -Force
    }
}
Write-Host "Local generated cleanup completed." -ForegroundColor Green
