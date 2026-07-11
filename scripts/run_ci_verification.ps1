param([ValidateSet('docs','main','all')][string]$Suite='all',[string]$GodotExe='')
$ErrorActionPreference='Stop'
$root=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$results=[System.Collections.Generic.List[object]]::new()
function Invoke-Step([string]$Name,[scriptblock]$Action){$start=Get-Date;try{& $Action;$results.Add([ordered]@{name=$Name;status='passed';exit_code=0;seconds=[math]::Round(((Get-Date)-$start).TotalSeconds,2)})}catch{$results.Add([ordered]@{name=$Name;status='failed';exit_code=1;seconds=[math]::Round(((Get-Date)-$start).TotalSeconds,2);message=$_.Exception.Message});throw}}
try{
 if($Suite -in @('docs','all')){
  Invoke-Step 'docs-status' {& (Join-Path $PSScriptRoot 'check_docs_status.ps1')}
  Invoke-Step 'public-candidate' {& (Join-Path $PSScriptRoot 'check_public_candidate.ps1')}
  Invoke-Step 'asset-licenses' {& (Join-Path $PSScriptRoot 'check_asset_licenses.ps1')}
  Invoke-Step 'third-party' {& (Join-Path $PSScriptRoot 'check_third_party_compliance.ps1')}
  Invoke-Step 'script-contracts' {& (Join-Path $PSScriptRoot 'test_ci_script_contract.ps1')}
  Invoke-Step 'failure-injection' {& (Join-Path $PSScriptRoot 'test_verification_failure_injection.ps1')}
 }
 if($Suite -in @('main','all')){
  if($GodotExe){$env:LMM_GODOT_EXE=$GodotExe}
  Invoke-Step 'v0.6-static' {& (Join-Path $PSScriptRoot 'verify_v06.ps1') -StaticOnly}
  Invoke-Step 'v0.5' {& (Join-Path $PSScriptRoot 'verify_v05.ps1') -GodotExe $GodotExe}
  Invoke-Step 'v0.4' {& (Join-Path $PSScriptRoot 'verify_v04.ps1') -GodotExe $GodotExe}
  Invoke-Step 'M4' {& (Join-Path $PSScriptRoot 'verify_m4.ps1') -GodotExe $GodotExe}
 }
} finally {
 $summary=[ordered]@{schema_version=1;suite=$Suite;runner=if($env:GITHUB_ACTIONS){'github-actions'}else{'local'};commit=(git -C $root rev-parse HEAD).Trim();generated_at=(Get-Date).ToUniversalTime().ToString('o');result=if($results.status -contains 'failed'){'failed'}else{'passed'};steps=@($results)}
 $out=Join-Path $root '.tmp_ci/verification-summary.json';New-Item -ItemType Directory -Force -Path (Split-Path $out -Parent)|Out-Null;$summary|ConvertTo-Json -Depth 8|Set-Content -LiteralPath $out -Encoding UTF8
 Write-Host "Verification summary: $out"
}
