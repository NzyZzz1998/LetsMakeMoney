param(
    [string]$PluginRoot = $PSScriptRoot
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

function Convert-ToDeterministicPng {
    param(
        [Parameter(Mandatory = $true)][string]$SourcePath,
        [Parameter(Mandatory = $true)][string]$OutputPath
    )

    $source = [Drawing.Image]::FromFile($SourcePath)
    $bitmap = $null
    $graphics = $null
    try {
        $bitmap = New-Object Drawing.Bitmap($source.Width, $source.Height, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $graphics = [Drawing.Graphics]::FromImage($bitmap)
        $graphics.Clear([Drawing.Color]::Transparent)
        $graphics.CompositingMode = [Drawing.Drawing2D.CompositingMode]::SourceCopy
        $graphics.DrawImage($source, 0, 0, $source.Width, $source.Height)

        $visiblePixels = 0
        $sampleStepX = [Math]::Max(1, [Math]::Floor($bitmap.Width / 96))
        $sampleStepY = [Math]::Max(1, [Math]::Floor($bitmap.Height / 96))
        for ($y = 0; $y -lt $bitmap.Height; $y += $sampleStepY) {
            for ($x = 0; $x -lt $bitmap.Width; $x += $sampleStepX) {
                if ($bitmap.GetPixel($x, $y).A -gt 0) { $visiblePixels += 1 }
            }
        }
        if ($visiblePixels -eq 0) { throw "宠物关键帧是空白图片：$SourcePath" }

        $directory = Split-Path -Parent $OutputPath
        if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
            New-Item -ItemType Directory -Path $directory | Out-Null
        }
        $bitmap.Save($OutputPath, [Drawing.Imaging.ImageFormat]::Png)
        $bytes = [IO.File]::ReadAllBytes($OutputPath)
        $sha256 = (Get-FileHash -LiteralPath $OutputPath -Algorithm SHA256).Hash.ToLowerInvariant()
        return [ordered]@{
            base64 = [Convert]::ToBase64String($bytes)
            width = $bitmap.Width
            height = $bitmap.Height
            bytes = $bytes.Length
            sha256 = $sha256
        }
    }
    finally {
        if ($graphics) { $graphics.Dispose() }
        if ($bitmap) { $bitmap.Dispose() }
        if ($source) { $source.Dispose() }
    }
}

$prototypeRoot = Split-Path -Parent $PluginRoot
$templatePath = Join-Path $PluginRoot "ui.template.html"
$outputPath = Join-Path $PluginRoot "ui.html"
$generatedRoot = Join-Path $PluginRoot "generated-assets"
$manifestOutput = Join-Path $generatedRoot "asset-manifest.json"

function Get-RelativePathText {
    param([string]$BasePath, [string]$TargetPath)
    $baseUri = [Uri]((Resolve-Path -LiteralPath $BasePath).Path.TrimEnd('\') + '\')
    $targetUri = [Uri](Resolve-Path -LiteralPath $TargetPath).Path
    return [Uri]::UnescapeDataString($baseUri.MakeRelativeUri($targetUri).ToString())
}

$assetSources = [ordered]@{
    classicWorking = Join-Path $prototypeRoot "assets\animation-plan\classic\making-money.gif"
    classicAwake = Join-Path $prototypeRoot "assets\animation-plan\classic\eating.gif"
    classicSleeping = Join-Path $prototypeRoot "assets\animation-plan\classic\sleeping.gif"
    duoduoWorking = Join-Path $prototypeRoot "assets\animation-plan\duoduo\making-money.gif"
    duoduoAwake = Join-Path $prototypeRoot "assets\animation-plan\duoduo\eating.gif"
    duoduoSleeping = Join-Path $prototypeRoot "assets\animation-plan\duoduo\sleeping.gif"
}

foreach ($requiredPath in @($templatePath) + @($assetSources.Values)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "缺少 Figma 插件输入文件：$requiredPath"
    }
}

$payload = [ordered]@{}
$assetManifest = [ordered]@{
    schema = "lmm-figma-static-assets/v1"
    generated_by = "figma-plugin/build.ps1"
    screenshot_assets = 0
    assets = [ordered]@{}
}

foreach ($name in $assetSources.Keys) {
    $outputAsset = Join-Path $generatedRoot "$name.png"
    $metadata = Convert-ToDeterministicPng -SourcePath $assetSources[$name] -OutputPath $outputAsset
    $payload[$name] = $metadata
    $assetManifest.assets[$name] = [ordered]@{
        source = Get-RelativePathText -BasePath $prototypeRoot -TargetPath $assetSources[$name]
        output = Get-RelativePathText -BasePath $PluginRoot -TargetPath $outputAsset
        width = $metadata.width
        height = $metadata.height
        bytes = $metadata.bytes
        sha256 = $metadata.sha256
        role = "product-pet-keyframe"
        runtime_screenshot = $false
    }
}

$template = Get-Content -LiteralPath $templatePath -Raw -Encoding UTF8
$payloadJson = $payload | ConvertTo-Json -Depth 6 -Compress
$html = $template.Replace("__ASSET_PAYLOAD_JSON__", $payloadJson)
if ($html.Contains("__ASSET_PAYLOAD_JSON__")) { throw "ui.html 仍存在素材占位符" }

[IO.File]::WriteAllText($outputPath, $html, [Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText($manifestOutput, ($assetManifest | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))

Write-Host "Figma 插件资源已生成：$outputPath"
Write-Host "确定性 PNG：$($assetSources.Count) 张"
Write-Host "素材清单：$manifestOutput"
