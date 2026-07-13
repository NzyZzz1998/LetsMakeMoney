param([string]$ProjectRoot=(Split-Path -Parent $PSScriptRoot),[string]$Destination='',[switch]$Offline)
$ErrorActionPreference='Stop'
$lock=Get-Content -LiteralPath (Join-Path $ProjectRoot 'third_party/native-toolchain.lock.json') -Raw -Encoding UTF8|ConvertFrom-Json
if(-not $Destination){$Destination=Join-Path $ProjectRoot '.cache/godot'}
$archive=Join-Path $Destination 'godot.zip';$extract=Join-Path $Destination 'runtime'
New-Item -ItemType Directory -Force -Path $Destination|Out-Null
if(-not(Test-Path $archive)){if($Offline){throw "Offline Godot archive is missing: $archive"};Invoke-WebRequest -Uri $lock.godot.windows_x86_64_url -OutFile $archive}
$actual=(Get-FileHash $archive -Algorithm SHA256).Hash.ToUpperInvariant();if($actual -ne ([string]$lock.godot.windows_x86_64_archive_sha256).ToUpperInvariant()){throw "Godot archive SHA256 mismatch."}
if(-not(Test-Path $extract)){New-Item -ItemType Directory -Force -Path $extract|Out-Null;Expand-Archive -LiteralPath $archive -DestinationPath $extract -Force}
$exe=Get-ChildItem $extract -Recurse -Filter 'Godot_v*_console.exe'|Select-Object -First 1;if(-not $exe){throw 'Godot console executable was not found in the pinned archive.'}
$exeHash=(Get-FileHash $exe.FullName -Algorithm SHA256).Hash.ToUpperInvariant();if($exeHash -ne ([string]$lock.godot.windows_x86_64_console_executable_sha256).ToUpperInvariant()){throw 'Godot console executable SHA256 mismatch.'}
Write-Output $exe.FullName
