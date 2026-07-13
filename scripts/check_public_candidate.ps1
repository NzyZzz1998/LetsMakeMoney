param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [int64]$LargeFileBytes = 10MB
)

$ErrorActionPreference = "Stop"
$utf8Strict = [Text.UTF8Encoding]::new($false, $true)
$failures = [System.Collections.Generic.List[object]]::new()
$warnings = [System.Collections.Generic.List[object]]::new()

function Add-Finding([string]$Level, [string]$Rule, [string]$Path, [string]$Risk) {
    $item = [pscustomobject]@{ Level = $Level; Rule = $Rule; Path = $Path; Risk = $Risk }
    if ($Level -eq "FAIL") { $failures.Add($item) } else { $warnings.Add($item) }
}

function Get-CandidateFiles {
    Push-Location $Root
    try {
        $insideGit = Test-Path -LiteralPath (Join-Path $Root '.git')
        if ($insideGit) {
            $paths = @(& git ls-files; & git ls-files --others --exclude-standard) | Sort-Object -Unique
            return @($paths | Where-Object { Test-Path -LiteralPath (Join-Path $Root $_) })
        }
        return @(Get-ChildItem -LiteralPath $Root -Recurse -File | ForEach-Object {
            $_.FullName.Substring($Root.Length).TrimStart('\').Replace('\','/')
        })
    } finally { Pop-Location }
}

$candidateFiles = @(Get-CandidateFiles)
$forbiddenRoots = @(".manual-test/", ".tmp_acceptance/", ".tmp_public_audit/", "releases/v0.4/", "releases/v0.5/", "releases/v0.6/", "temp/")
$sensitiveNames = '(?i)(^|/)(\.env($|\.)|.*\.(pfx|p12|pem|key|snk)|id_rsa|credentials\.json|secrets?\.json|debug\.log($|\.)|config\.json$)'
$unknownBinary = '(?i)\.(exe|dll|zip|7z|rar|pfx|p12|lib|exp)$'
$textExtensions = @('.md','.txt','.ps1','.gd','.gdshader','.tscn','.tres','.godot','.cfg','.json','.html','.css','.js','.xml','.yml','.yaml','.ini','.svg')
$activeLinkFiles = @('README.md','doc/current.md') + @($candidateFiles | Where-Object { $_ -like 'doc/releases/v0.7/*.md' })
$mojibakeChars = @([char]0x951B, [char]0x9286, [char]0x9225)

foreach ($relative in $candidateFiles) {
    $normalized = $relative.Replace('\','/')
    $full = Join-Path $Root $relative
    $file = Get-Item -LiteralPath $full

    foreach ($prefix in $forbiddenRoots) {
        if ($normalized.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
            Add-Finding "FAIL" "FORBIDDEN_PATH" $normalized "Excluded directory is present in the candidate tree."
            break
        }
    }
    if ($normalized -match $sensitiveNames) { Add-Finding "FAIL" "SENSITIVE_FILENAME" $normalized "Filename indicates credentials or private runtime data." }
    if ($file.Length -gt $LargeFileBytes) { Add-Finding "FAIL" "LARGE_FILE" $normalized "File exceeds the public candidate threshold." }
    if ($normalized -match $unknownBinary -and $normalized -notlike 'assets/*' -and $normalized -notlike 'icons/*') {
        Add-Finding "FAIL" "UNKNOWN_BINARY" $normalized "Binary/archive requires explicit manifest approval."
    }

    $extension = [IO.Path]::GetExtension($normalized).ToLowerInvariant()
    $name = [IO.Path]::GetFileName($normalized).ToLowerInvariant()
    $isText = $textExtensions -contains $extension -or $name -in @('.gitignore','.gitattributes','.editorconfig')
    if (-not $isText) { continue }

    try { $content = [IO.File]::ReadAllText($full, $utf8Strict) }
    catch { Add-Finding "FAIL" "INVALID_UTF8" $normalized "Text is not strict UTF-8."; continue }

    foreach ($marker in $mojibakeChars) {
        if ($content.Contains([string]$marker)) { Add-Finding "FAIL" "MOJIBAKE" $normalized "Common mojibake marker detected."; break }
    }
    if ($content -match '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----' -or
        $content -match '(?i)\bgh[pousr]_[A-Za-z0-9_]{20,}\b' -or
        $content -match '(?i)(api[_-]?key|token|password|secret)\s*[:=]\s*["''][^"'']{12,}["'']') {
        Add-Finding "FAIL" "SECRET_PATTERN" $normalized "Possible secret detected; value is redacted."
    }
    if ($content -match '(?i)\b[A-Z]:\\Users\\[^\\\s]+' -or $content -match '(?i)\b[A-Z]:\\(?!Windows\\)[^\r\n`]+') {
        Add-Finding "WARN" "ABSOLUTE_PATH" $normalized "Windows absolute path requires review."
    }

    if ($activeLinkFiles -contains $normalized -and $extension -eq '.md') {
        $matches = [regex]::Matches($content, '(?<!\!)\[[^\]]+\]\(([^)]+)\)')
        foreach ($match in $matches) {
            $target = $match.Groups[1].Value.Trim().Trim('<','>')
            if ($target -match '^(https?://|mailto:|#)' -or [string]::IsNullOrWhiteSpace($target)) { continue }
            $target = [Uri]::UnescapeDataString(($target -split '#')[0])
            $resolved = Join-Path (Split-Path $full -Parent) $target
            if (-not (Test-Path -LiteralPath $resolved)) { Add-Finding "FAIL" "BROKEN_LINK" $normalized "Missing local link target: $target" }
        }
    }
}

$currentPath = Join-Path $Root 'doc/current.md'
if (Test-Path -LiteralPath $currentPath) {
    $current = [IO.File]::ReadAllText($currentPath, $utf8Strict)
    if ($current -notmatch 'v0\.7 Beta' -or $current -notmatch 'v0\.7-beta' -or $current -notmatch 'GitHub Release') {
        Add-Finding "FAIL" "WRONG_STATUS" 'doc/current.md' "Current entry does not identify the published v0.7 tag and GitHub Release."
    }
}

Write-Host "Current-tree public candidate check (read-only)" -ForegroundColor Cyan
Write-Host "Scope: tracked files plus unignored untracked files. Full Git history is deferred to V07-A3."
foreach ($item in $warnings) { Write-Host ("WARN [{0}] {1} - {2}" -f $item.Rule,$item.Path,$item.Risk) -ForegroundColor Yellow }
foreach ($item in $failures) { Write-Host ("FAIL [{0}] {1} - {2}" -f $item.Rule,$item.Path,$item.Risk) -ForegroundColor Red }
Write-Host ("Summary: files={0}, failures={1}, warnings={2}" -f $candidateFiles.Count,$failures.Count,$warnings.Count)
if ($failures.Count -gt 0) { exit 1 }
exit 0
