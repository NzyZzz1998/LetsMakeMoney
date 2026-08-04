param(
    [switch]$IncludePaths,
    [switch]$AsJson
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "v10_tools.ps1")

function Read-CommandVersion {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [string[]]$Arguments = @("--version")
    )

    $output = & $Path @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Version command failed for $([IO.Path]::GetFileName($Path))."
    }
    return (($output | Select-Object -First 1) -as [string]).Trim()
}

function New-ToolResult {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [object]$Resolution,
        [Parameter(Mandatory = $true)]
        [string]$Version
    )

    $result = [ordered]@{
        name = $Name
        status = "available"
        source = $Resolution.Source
        version = $Version
    }
    if ($IncludePaths) {
        $result.path = $Resolution.Path
    }
    return $result
}

function Find-Msvc {
    $vswhereCandidates = @(
        (Join-Path ${env:ProgramFiles(x86)} "Microsoft Visual Studio\Installer\vswhere.exe"),
        (Join-Path $env:ProgramFiles "Microsoft Visual Studio\Installer\vswhere.exe")
    ) | Where-Object { $_ -and (Test-Path -LiteralPath $_ -PathType Leaf) }

    foreach ($vswhere in $vswhereCandidates) {
        $installation = (& $vswhere -latest -products * `
            -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
            -property installationPath 2>$null | Select-Object -First 1)
        if (-not [string]::IsNullOrWhiteSpace($installation)) {
            return [ordered]@{
                status = "available"
                source = "Visual Studio Installer"
                version = Split-Path -Leaf $installation
                path = $installation
            }
        }
    }

    $cl = Get-Command cl.exe -CommandType Application -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($cl) {
        return [ordered]@{
            status = "available"
            source = "PATH"
            version = "cl.exe"
            path = $cl.Source
        }
    }
    return [ordered]@{
        status = "missing"
        source = "not-found"
        version = ""
    }
}

function Find-WindowsSdk {
    $roots = @(
        "HKLM:\SOFTWARE\Microsoft\Windows Kits\Installed Roots",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows Kits\Installed Roots"
    )
    foreach ($key in $roots) {
        try {
            $kitsRoot = (Get-ItemProperty -LiteralPath $key -ErrorAction Stop).KitsRoot10
            if ($kitsRoot) {
                $includeRoot = Join-Path $kitsRoot "Include"
                $version = Get-ChildItem -LiteralPath $includeRoot -Directory -ErrorAction SilentlyContinue |
                    Sort-Object Name -Descending |
                    Select-Object -First 1 -ExpandProperty Name
                if ($version) {
                    return [ordered]@{
                        status = "available"
                        source = "Windows Kits registry"
                        version = $version
                        path = $kitsRoot
                    }
                }
            }
        }
        catch {
            continue
        }
    }
    return [ordered]@{
        status = "missing"
        source = "not-found"
        version = ""
    }
}

function Find-WebView2 {
    $clientId = "{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}"
    $keys = @(
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\$clientId",
        "HKLM:\SOFTWARE\Microsoft\EdgeUpdate\Clients\$clientId",
        "HKCU:\Software\Microsoft\EdgeUpdate\Clients\$clientId"
    )
    foreach ($key in $keys) {
        try {
            $properties = Get-ItemProperty -LiteralPath $key -ErrorAction Stop
            if ($properties.pv) {
                return [ordered]@{
                    status = "available"
                    source = "EdgeUpdate registry"
                    version = [string]$properties.pv
                }
            }
        }
        catch {
            continue
        }
    }

    $edgeUpdate = Get-ItemProperty `
        -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\*" `
        -ErrorAction SilentlyContinue |
        Where-Object { $_.name -match "WebView2" -and $_.pv } |
        Select-Object -First 1
    if ($edgeUpdate) {
        return [ordered]@{
            status = "available"
            source = "EdgeUpdate registry"
            version = [string]$edgeUpdate.pv
        }
    }
    return [ordered]@{
        status = "missing"
        source = "not-found"
        version = ""
    }
}

$errors = [System.Collections.Generic.List[string]]::new()
$tools = [System.Collections.Generic.List[object]]::new()
foreach ($definition in @(
    @{ Name = "Node.js"; Resolver = { Get-V10NodeResolution -RepoRoot $RepoRoot } },
    @{ Name = "Python"; Resolver = { Get-V10PythonResolution -RepoRoot $RepoRoot } },
    @{ Name = "Cargo"; Resolver = { Get-V10CargoResolution -RepoRoot $RepoRoot } }
)) {
    try {
        $resolution = & $definition.Resolver
        $tools.Add((New-ToolResult `
            -Name $definition.Name `
            -Resolution $resolution `
            -Version (Read-CommandVersion -Path $resolution.Path)))
    }
    catch {
        $errors.Add("$($definition.Name): $($_.Exception.Message)")
        $tools.Add([ordered]@{
            name = $definition.Name
            status = "missing"
            source = "not-found"
            version = ""
        })
    }
}

$msvc = Find-Msvc
$sdk = Find-WindowsSdk
$webview2 = Find-WebView2
foreach ($requirement in @(
    @{ Name = "MSVC"; Value = $msvc },
    @{ Name = "Windows SDK"; Value = $sdk },
    @{ Name = "WebView2"; Value = $webview2 }
)) {
    if ($requirement.Value.status -ne "available") {
        $errors.Add("$($requirement.Name): not found")
    }
    if (-not $IncludePaths -and $requirement.Value.Contains("path")) {
        $requirement.Value.Remove("path")
    }
}

$report = [ordered]@{
    contract = "lmm-v1.0.4-environment"
    rust_toolchain = Get-V10RustToolchain
    tools = $tools
    prerequisites = [ordered]@{
        msvc = $msvc
        windows_sdk = $sdk
        webview2 = $webview2
    }
    ready = $errors.Count -eq 0
    errors = $errors
}

if ($AsJson) {
    $report | ConvertTo-Json -Depth 8
}
else {
    Write-Host "LetsMakeMoney v1.0.4 environment diagnosis"
    foreach ($tool in $tools) {
        Write-Host ("- {0}: {1} ({2})" -f $tool.name, $tool.version, $tool.source)
        if ($IncludePaths -and $tool.path) {
            Write-Host ("  path: {0}" -f $tool.path)
        }
    }
    Write-Host ("- MSVC: {0} {1}" -f $msvc.status, $msvc.version)
    Write-Host ("- Windows SDK: {0} {1}" -f $sdk.status, $sdk.version)
    Write-Host ("- WebView2: {0} {1}" -f $webview2.status, $webview2.version)
}

if (-not $report.ready) {
    foreach ($message in $errors) {
        Write-Error $message
    }
    exit 1
}

Write-Host "PASS LetsMakeMoney v1.0.4 environment is ready" -ForegroundColor Green
