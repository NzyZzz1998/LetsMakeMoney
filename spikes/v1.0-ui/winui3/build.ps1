param(
    [switch]$SkipRestore
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$SpikeRoot = Split-Path -Parent $ProjectRoot
$DotNet = Join-Path $SpikeRoot ".toolchains\dotnet\dotnet.exe"
$NuGetCache = Join-Path $SpikeRoot ".toolchains\nuget-packages"

if (-not (Test-Path -LiteralPath $DotNet -PathType Leaf)) {
    throw "Isolated .NET SDK is not installed. Run ..\scripts\install-toolchains.ps1 -Toolchain DotNet."
}

$env:NUGET_PACKAGES = $NuGetCache
$env:DOTNET_CLI_HOME = Join-Path $SpikeRoot ".toolchains\dotnet-home"
$env:DOTNET_NOLOGO = "1"

& (Join-Path $ProjectRoot "verify-contract.ps1")
if (-not $SkipRestore) {
    & $DotNet restore (Join-Path $ProjectRoot "LmmWinUiSpike.csproj") -p:Platform=x64
    if ($LASTEXITCODE -ne 0) {
        throw "WinUI restore failed."
    }
}
& $DotNet publish (Join-Path $ProjectRoot "LmmWinUiSpike.csproj") `
    -c Release `
    -r win-x64 `
    --self-contained true `
    -p:Platform=x64 `
    --no-restore
if ($LASTEXITCODE -ne 0) {
    throw "WinUI publish failed."
}

$Executable = Get-ChildItem -LiteralPath (Join-Path $ProjectRoot "bin") -Filter "LmmWinUiSpike.exe" -Recurse |
    Where-Object { $_.DirectoryName -match '[\\/]publish$' } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
if ($null -eq $Executable) {
    throw "WinUI executable not found."
}
Get-FileHash -LiteralPath $Executable.FullName -Algorithm SHA256
