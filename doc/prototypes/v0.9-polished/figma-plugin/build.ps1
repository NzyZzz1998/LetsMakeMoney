param(
    [string]$PluginRoot = $PSScriptRoot
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

function Convert-ToFigmaPngBase64 {
    param([Parameter(Mandatory = $true)][string]$Path)

    $source = [Drawing.Image]::FromFile($Path)
    $bitmap = $null
    $graphics = $null
    $stream = $null
    try {
        # Re-encode every review asset as a static RGBA PNG. Figma can display GIFs,
        # but large plugin messages can leave individual GIF/PNG fills blank.
        $bitmap = New-Object Drawing.Bitmap($source.Width, $source.Height, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $graphics = [Drawing.Graphics]::FromImage($bitmap)
        $graphics.Clear([Drawing.Color]::Transparent)
        $graphics.DrawImage($source, 0, 0, $source.Width, $source.Height)
        $stream = New-Object IO.MemoryStream
        $bitmap.Save($stream, [Drawing.Imaging.ImageFormat]::Png)
        return [Convert]::ToBase64String($stream.ToArray())
    }
    finally {
        if ($graphics) { $graphics.Dispose() }
        if ($bitmap) { $bitmap.Dispose() }
        if ($source) { $source.Dispose() }
        if ($stream) { $stream.Dispose() }
    }
}

$prototypeRoot = Split-Path -Parent $PluginRoot
$templatePath = Join-Path $PluginRoot "ui.template.html"
$outputPath = Join-Path $PluginRoot "ui.html"
$classicPath = Join-Path $prototypeRoot "assets\animation-plan\classic\contact-sheet.png"
$duoduoPath = Join-Path $prototypeRoot "assets\animation-plan\duoduo\contact-sheet.png"
$classicWorkingPath = Join-Path $prototypeRoot "assets\animation-plan\classic\making-money.gif"
$classicSleepingPath = Join-Path $prototypeRoot "assets\animation-plan\classic\sleeping.gif"
$duoduoWorkingPath = Join-Path $prototypeRoot "assets\animation-plan\duoduo\making-money.gif"
$duoduoSleepingPath = Join-Path $prototypeRoot "assets\animation-plan\duoduo\sleeping.gif"

foreach ($requiredPath in @(
    $templatePath,
    $classicPath,
    $duoduoPath,
    $classicWorkingPath,
    $classicSleepingPath,
    $duoduoWorkingPath,
    $duoduoSleepingPath
)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "缺少 Figma 插件输入文件：$requiredPath"
    }
}

$template = Get-Content -LiteralPath $templatePath -Raw -Encoding UTF8
$classicBase64 = Convert-ToFigmaPngBase64 $classicPath
$duoduoBase64 = Convert-ToFigmaPngBase64 $duoduoPath
$classicWorkingBase64 = Convert-ToFigmaPngBase64 $classicWorkingPath
$classicSleepingBase64 = Convert-ToFigmaPngBase64 $classicSleepingPath
$duoduoWorkingBase64 = Convert-ToFigmaPngBase64 $duoduoWorkingPath
$duoduoSleepingBase64 = Convert-ToFigmaPngBase64 $duoduoSleepingPath

$html = $template.Replace("__CLASSIC_BASE64__", $classicBase64)
$html = $html.Replace("__DUODUO_BASE64__", $duoduoBase64)
$html = $html.Replace("__CLASSIC_WORKING_BASE64__", $classicWorkingBase64)
$html = $html.Replace("__CLASSIC_SLEEPING_BASE64__", $classicSleepingBase64)
$html = $html.Replace("__DUODUO_WORKING_BASE64__", $duoduoWorkingBase64)
$html = $html.Replace("__DUODUO_SLEEPING_BASE64__", $duoduoSleepingBase64)

[IO.File]::WriteAllText($outputPath, $html, [Text.UTF8Encoding]::new($false))

$output = Get-Item -LiteralPath $outputPath
Write-Host "Figma 插件资源已生成：$($output.FullName)"
Write-Host "大小：$($output.Length) 字节"
