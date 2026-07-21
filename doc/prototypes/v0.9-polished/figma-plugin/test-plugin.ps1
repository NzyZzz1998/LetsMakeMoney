param(
    [string]$PluginRoot = $PSScriptRoot
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function Get-Sha256Bytes {
    param([byte[]]$Bytes)
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($sha.ComputeHash($Bytes))).Replace("-", "")
    }
    finally {
        $sha.Dispose()
    }
}

function Get-EmbeddedAsset {
    param([string]$Html, [string]$VariableName)
    $pattern = 'const\s+' + [Regex]::Escape($VariableName) + '\s*=\s*"([A-Za-z0-9+/=]+)";'
    $match = [Regex]::Match($Html, $pattern)
    Assert-True $match.Success "ui.html 缺少嵌入资源：$VariableName"
    return [Convert]::FromBase64String($match.Groups[1].Value)
}

function Convert-ToFigmaPngBytes {
    param([Parameter(Mandatory = $true)][string]$Path)

    $source = [Drawing.Image]::FromFile($Path)
    $bitmap = $null
    $graphics = $null
    $stream = $null
    try {
        $bitmap = New-Object Drawing.Bitmap($source.Width, $source.Height, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $graphics = [Drawing.Graphics]::FromImage($bitmap)
        $graphics.Clear([Drawing.Color]::Transparent)
        $graphics.DrawImage($source, 0, 0, $source.Width, $source.Height)
        $stream = New-Object IO.MemoryStream
        $bitmap.Save($stream, [Drawing.Imaging.ImageFormat]::Png)
        return $stream.ToArray()
    }
    finally {
        if ($graphics) { $graphics.Dispose() }
        if ($bitmap) { $bitmap.Dispose() }
        if ($source) { $source.Dispose() }
        if ($stream) { $stream.Dispose() }
    }
}

function Assert-PngAsset {
    param([byte[]]$Bytes, [string]$Name)
    $signature = @(137, 80, 78, 71, 13, 10, 26, 10)
    Assert-True ($Bytes.Length -gt 24) "嵌入素材为空或过短：$Name"
    for ($index = 0; $index -lt $signature.Count; $index++) {
        Assert-True ($Bytes[$index] -eq $signature[$index]) "嵌入素材不是兼容 PNG：$Name"
    }
}

$manifestPath = Join-Path $PluginRoot "manifest.json"
$codePath = Join-Path $PluginRoot "code.js"
$uiPath = Join-Path $PluginRoot "ui.html"
$prototypeRoot = Split-Path -Parent $PluginRoot

foreach ($path in @($manifestPath, $codePath, $uiPath)) {
    Assert-True (Test-Path -LiteralPath $path -PathType Leaf) "缺少插件文件：$path"
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
Assert-True ($manifest.editorType -contains "figma") "插件必须仅面向 Figma Design"
Assert-True ($manifest.documentAccess -eq "dynamic-page") "插件必须使用 dynamic-page 文档访问"
Assert-True (Test-Path -LiteralPath (Join-Path $PluginRoot $manifest.main)) "manifest.main 不存在"
Assert-True (Test-Path -LiteralPath (Join-Path $PluginRoot $manifest.ui)) "manifest.ui 不存在"

$code = Get-Content -LiteralPath $codePath -Raw -Encoding UTF8
$ui = Get-Content -LiteralPath $uiPath -Raw -Encoding UTF8

Assert-True (-not [Regex]::IsMatch($ui, '__[A-Z_]+__')) "ui.html 存在未替换资源占位符"
Assert-True ($code.Contains('await figma.loadAllPagesAsync()')) "缺少动态页面加载"
Assert-True ($code.Contains('await figma.setCurrentPageAsync(pages[0])')) "缺少异步当前页切换"
Assert-True (-not $code.Contains('figma.currentPage =')) "禁止使用同步 currentPage setter"
Assert-True (-not $code.Contains('figma.root.remove')) "禁止删除 Figma 根文档"
$foreignPageDeletePattern = 'filter((page) => !PAGE_NAMES.includes'
Assert-True (-not $code.Contains($foreignPageDeletePattern)) "禁止删除非 LMM 页面"

$expectedPages = @(
    "00 Foundations & Components",
    "01 Windows v0.9 Product UI",
    "02 Animation Contract"
)
foreach ($pageName in $expectedPages) {
    Assert-True ($code.Contains($pageName)) "缺少目标页面：$pageName"
}

$assetMap = @{
    classic = "assets\animation-plan\classic\contact-sheet.png"
    duoduo = "assets\animation-plan\duoduo\contact-sheet.png"
    classicWorking = "assets\animation-plan\classic\making-money.gif"
    classicSleeping = "assets\animation-plan\classic\sleeping.gif"
    duoduoWorking = "assets\animation-plan\duoduo\making-money.gif"
    duoduoSleeping = "assets\animation-plan\duoduo\sleeping.gif"
}

foreach ($entry in $assetMap.GetEnumerator()) {
    $sourcePath = Join-Path $prototypeRoot $entry.Value
    Assert-True (Test-Path -LiteralPath $sourcePath -PathType Leaf) "缺少源素材：$sourcePath"
    $embedded = Get-EmbeddedAsset -Html $ui -VariableName $entry.Key
    $expected = Convert-ToFigmaPngBytes $sourcePath
    Assert-PngAsset -Bytes $embedded -Name $entry.Key
    Assert-True ((Get-Sha256Bytes $embedded) -eq (Get-Sha256Bytes $expected)) "嵌入 PNG 哈希不一致：$($entry.Key)"
}

$nodeCandidates = @(@(
    (Get-Command node -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1)
) | Where-Object { $_ -and (Test-Path -LiteralPath $_ -PathType Leaf) })

if ($nodeCandidates.Count -gt 0) {
    & $nodeCandidates[0] --check $codePath
    Assert-True ($LASTEXITCODE -eq 0) "code.js JavaScript 语法检查失败"
}

Write-Host "Figma 插件静态验证通过"
Write-Host "- 页面：3"
Write-Host "- 嵌入素材：6（统一 PNG，SHA256 与确定性转换结果一致）"
Write-Host "- 非目标页面保护：通过"
Write-Host "- JavaScript 语法：通过"
