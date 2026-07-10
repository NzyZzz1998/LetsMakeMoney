function Get-LetsMakeMoneyVersion {
    param([string]$ProjectRoot)

    $projectPath = Join-Path $ProjectRoot "project.godot"
    if (-not (Test-Path -LiteralPath $projectPath)) {
        throw "Missing project.godot: $projectPath"
    }
    $projectText = Get-Content -LiteralPath $projectPath -Raw -Encoding UTF8
    $match = [regex]::Match($projectText, '(?m)^config/version="([^"]+)"$')
    if (-not $match.Success -or [string]::IsNullOrWhiteSpace($match.Groups[1].Value)) {
        throw "project.godot does not define application/config/version"
    }
    return $match.Groups[1].Value.Trim()
}
