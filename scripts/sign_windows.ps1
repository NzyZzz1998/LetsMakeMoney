param(
 [Parameter(Mandatory=$true)][string[]]$Path,
 [string]$Publisher='',
 [string]$CertificatePath=$env:LMM_SIGN_CERT_PATH,
 [string]$TimestampUrl=$env:LMM_SIGN_TIMESTAMP_URL
)
$ErrorActionPreference='Stop'
if(-not $CertificatePath -or -not(Test-Path $CertificatePath)){throw 'Signing certificate is unavailable. Set LMM_SIGN_CERT_PATH in the secure release environment.'}
if(-not $env:LMM_SIGN_CERT_PASSWORD){throw 'Signing certificate password is unavailable. Set LMM_SIGN_CERT_PASSWORD in the secure release environment.'}
if(-not $TimestampUrl){throw 'Timestamp service is unavailable. Set LMM_SIGN_TIMESTAMP_URL.'}
$secure=ConvertTo-SecureString $env:LMM_SIGN_CERT_PASSWORD -AsPlainText -Force
$cert=New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($CertificatePath,$secure,[System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::EphemeralKeySet)
foreach($item in $Path){
 if(-not(Test-Path $item)){throw "Signing input missing: $item"}
 $result=Set-AuthenticodeSignature -FilePath $item -Certificate $cert -TimestampServer $TimestampUrl -HashAlgorithm SHA256 -IncludeChain All
 if($result.Status -ne 'Valid'){throw "Authenticode signing failed for $item: $($result.Status)"}
 $verified=Get-AuthenticodeSignature $item
 if($verified.Status -ne 'Valid'){throw "Authenticode verification failed for $item: $($verified.Status)"}
 if($Publisher -and $verified.SignerCertificate.Subject -notlike "*$Publisher*"){throw "Publisher mismatch for $item"}
 Write-Host "Signed and verified: $(Split-Path $item -Leaf)"
}
