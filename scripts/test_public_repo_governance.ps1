param([string]$ProjectRoot=(Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference='Stop'
function Need([bool]$Ok,[string]$Message){if(-not $Ok){throw $Message}}

$required=@('README.md','README.en.md','LICENSE','ASSETS_LICENSE.md','THIRD_PARTY_NOTICES.md','CONTRIBUTING.md','CODE_OF_CONDUCT.md','SECURITY.md','.github/ISSUE_TEMPLATE/bug_report.yml','.github/ISSUE_TEMPLATE/feature_request.yml','.github/PULL_REQUEST_TEMPLATE.md')
foreach($relative in $required){Need (Test-Path -LiteralPath (Join-Path $ProjectRoot $relative)) "Missing public repository file: $relative"}
$zh=Get-Content (Join-Path $ProjectRoot 'README.md') -Raw -Encoding UTF8
$en=Get-Content (Join-Path $ProjectRoot 'README.en.md') -Raw -Encoding UTF8
foreach($token in @('v0.6 Beta','v0.7 Beta','Windows x86_64','GitHub Releases','CONTRIBUTING.md','SECURITY.md','ASSETS_LICENSE.md','run_ci_verification.ps1')){Need $zh.Contains($token) "Chinese README missing: $token";Need $en.Contains($token) "English README missing: $token"}
$workflows=(Get-ChildItem (Join-Path $ProjectRoot '.github/workflows') -Filter *.yml | ForEach-Object {Get-Content $_.FullName -Raw -Encoding UTF8}) -join "`n"
Need (-not ($workflows -match 'uses:\s+[^\s]+@v\d')) 'GitHub Actions must be pinned to immutable commits'
Need ($workflows -match 'permissions:\s*\r?\n\s+contents:\s+read') 'Workflows must use read-only contents permission'
Write-Host 'Public repository governance contract passed' -ForegroundColor Green
