param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$Msys2Root = $env:LMM_MSYS2_ROOT
)

$ErrorActionPreference = 'Stop'
$targetRoot = Join-Path $ProjectRoot 'licenses/third-party'

$remote = @(
    @{ Path='Godot/LICENSE.txt'; Url='https://raw.githubusercontent.com/godotengine/godot/4.7-stable/LICENSE.txt'; Sha256='B0435E3B3E4E55238F05F4B306F30524A1B2E20147810D436EAA554FA6855C80' },
    @{ Path='Godot/COPYRIGHT.txt'; Url='https://raw.githubusercontent.com/godotengine/godot/4.7-stable/COPYRIGHT.txt'; Sha256='CB1980C88089573BCACD7221D777C689BB8BBD778799F24C27FCA0FE5F774D6D' },
    @{ Path='godot-cpp/LICENSE.md'; Url='https://raw.githubusercontent.com/godotengine/godot-cpp/ba0edfed90512ec64aba51d4295a3e7e30112f86/LICENSE.md'; Sha256='26A5B210D90760156CE886267CE9DF235787DCC6CEBFD7ECD95EF5B6FDCC95BF' },
    @{ Path='Inno-Setup/LICENSE.txt'; Url='https://jrsoftware.org/files/is/license.txt'; Sha256='2E5346868C2A18434489824E11D65C3031620F792FEFC415D05F19CD441ABF5C' },
    @{ Path='Python/LICENSE.txt'; Url='https://raw.githubusercontent.com/python/cpython/v3.12.8/LICENSE'; Sha256='3B2F81FE21D181C499C59A256C8E1968455D6689D269AA85373BFB6AF41DA3BF' },
    @{ Path='SCons/LICENSE.txt'; Url='https://raw.githubusercontent.com/SCons/scons/4.10.1/LICENSE'; Sha256='2F6AC9A1FC98394D18B80DBA9BEDB9D5626006D44DB3FECF7CF3E21CFF7E8B1C' },
    @{ Path='Pillow/LICENSE.txt'; Url='https://raw.githubusercontent.com/python-pillow/Pillow/12.2.0/LICENSE'; Sha256='15181E7363DCA9AED78B79BEBEBC7FDE7F1814B8BD311EA3B87AE8CCADFC185B' },
    @{ Path='Git/COPYING'; Url='https://raw.githubusercontent.com/git-for-windows/git/v2.54.0.windows.1/COPYING'; Sha256='5B2198D1645F767585E8A88AC0499B04472164C0D2DA22E75ECF97EF443AB32E' },
    @{ Path='PowerShell/LICENSE.txt'; Url='https://raw.githubusercontent.com/PowerShell/PowerShell/v7.5.2/LICENSE.txt'; Sha256='7C77A44A8ACD9B41FDC209864A8016B3D430B5D0E09309818D5B7444336DF744' }
)

foreach ($item in $remote) {
    $target = Join-Path $targetRoot $item.Path
    New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force | Out-Null
    $temp = "$target.download"
    Invoke-WebRequest -Uri $item.Url -UseBasicParsing -OutFile $temp
    $actual = (Get-FileHash -LiteralPath $temp -Algorithm SHA256).Hash
    if ($actual -ne $item.Sha256) {
        Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue
        throw "Third-party license hash mismatch: $($item.Path)"
    }
    if ($item.Path -eq 'Inno-Setup/LICENSE.txt') {
        # The upstream file uses CRLF. Normalize the repository copy so its
        # manifest hash is stable after Git checks it out with eol=lf.
        $content = [IO.File]::ReadAllText($temp).Replace("`r`n", "`n")
        [IO.File]::WriteAllText($temp, $content, (New-Object Text.UTF8Encoding($false)))
    }
    Move-Item -LiteralPath $temp -Destination $target -Force
}

if ($Msys2Root) {
    $local = @(
        @{ Path='MinGW-w64/COPYING'; Source='ucrt64/share/licenses/crt/COPYING'; Sha256='99A69660981156C21336FDB5661F89341B013C94E4BF9E1C7467B4745718397F' },
        @{ Path='MinGW-w64/COPYING.RUNTIME'; Source='ucrt64/share/licenses/crt/COPYING.MinGW-w64-runtime.txt'; Sha256='1DB8DA07B436C68833C0673FFEE3D9FCB2526047F3820B81661865DFEDC79A1F' },
        @{ Path='GCC/COPYING3'; Source='ucrt64/share/licenses/gcc-libs/COPYING3'; Sha256='8CEB4B9EE5ADEDDE47B31E975C1D90C73AD27B6B165A1DCD80C7C545EB65B903' },
        @{ Path='GCC/COPYING.RUNTIME'; Source='ucrt64/share/licenses/gcc-libs/COPYING.RUNTIME'; Sha256='9D6B43CE4D8DE0C878BF16B54D8E7A10D9BD42B75178153E3AF6A815BDC90F74' }
    )
    foreach ($item in $local) {
        $source = Join-Path $Msys2Root $item.Source
        if (-not (Test-Path -LiteralPath $source)) { throw "Missing installed toolchain license: $source" }
        $actual = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
        if ($actual -ne $item.Sha256) { throw "Installed toolchain license hash mismatch: $($item.Path)" }
        $target = Join-Path $targetRoot $item.Path
        New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force | Out-Null
        Copy-Item -LiteralPath $source -Destination $target -Force
    }
}

Write-Host "Third-party license texts synchronized: $targetRoot"
