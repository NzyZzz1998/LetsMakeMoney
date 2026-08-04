param(
    [string]$IcoOutputPath = (Join-Path $PSScriptRoot "..\src-tauri\icons\icon.ico"),
    [string]$PngOutputPath = (Join-Path $PSScriptRoot "..\src-tauri\icons\icon.png")
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

function New-RoundedRectanglePath {
    param(
        [float]$X,
        [float]$Y,
        [float]$Width,
        [float]$Height,
        [float]$Radius
    )

    $diameter = $Radius * 2
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddArc($X, $Y, $diameter, $diameter, 180, 90)
    $path.AddArc($X + $Width - $diameter, $Y, $diameter, $diameter, 270, 90)
    $path.AddArc($X + $Width - $diameter, $Y + $Height - $diameter, $diameter, $diameter, 0, 90)
    $path.AddArc($X, $Y + $Height - $diameter, $diameter, $diameter, 90, 90)
    $path.CloseFigure()
    return $path
}

function New-BrandBitmap {
    param([int]$Size)

    $bitmap = New-Object System.Drawing.Bitmap($Size, $Size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.Clear([System.Drawing.Color]::Transparent)

    $scale = $Size / 96.0
    $shellBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 238, 233, 223))
    $markBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 48, 48, 43))
    $activeBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 216, 155, 38))
    $trackBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 119, 139, 123))

    $shellPath = New-RoundedRectanglePath -X 0 -Y 0 -Width $Size -Height $Size -Radius (28 * $scale)
    $trackPath = New-RoundedRectanglePath -X (18 * $scale) -Y (68 * $scale) -Width (60 * $scale) -Height (10 * $scale) -Radius (5 * $scale)
    $activePath = New-RoundedRectanglePath -X (18 * $scale) -Y (68 * $scale) -Width (36 * $scale) -Height (10 * $scale) -Radius (5 * $scale)

    $leftPeak = [System.Drawing.PointF[]]@(
        [System.Drawing.PointF]::new(18 * $scale, 60 * $scale),
        [System.Drawing.PointF]::new(36 * $scale, 27 * $scale),
        [System.Drawing.PointF]::new(49 * $scale, 48 * $scale),
        [System.Drawing.PointF]::new(42 * $scale, 60 * $scale)
    )
    $rightPeak = [System.Drawing.PointF[]]@(
        [System.Drawing.PointF]::new(47 * $scale, 48 * $scale),
        [System.Drawing.PointF]::new(60 * $scale, 27 * $scale),
        [System.Drawing.PointF]::new(78 * $scale, 60 * $scale),
        [System.Drawing.PointF]::new(54 * $scale, 60 * $scale)
    )

    $graphics.FillPath($shellBrush, $shellPath)
    $graphics.FillPolygon($markBrush, $leftPeak)
    $graphics.FillPolygon($markBrush, $rightPeak)
    $graphics.FillPath($trackBrush, $trackPath)
    $graphics.FillPath($activeBrush, $activePath)

    $activePath.Dispose()
    $trackPath.Dispose()
    $shellPath.Dispose()
    $trackBrush.Dispose()
    $activeBrush.Dispose()
    $markBrush.Dispose()
    $shellBrush.Dispose()
    $graphics.Dispose()
    return $bitmap
}

function Convert-BitmapToPngBytes {
    param([System.Drawing.Bitmap]$Bitmap)

    $stream = New-Object System.IO.MemoryStream
    $Bitmap.Save($stream, [System.Drawing.Imaging.ImageFormat]::Png)
    $bytes = $stream.ToArray()
    $stream.Dispose()
    return $bytes
}

$resolvedIco = [System.IO.Path]::GetFullPath($IcoOutputPath)
$resolvedPng = [System.IO.Path]::GetFullPath($PngOutputPath)
New-Item -ItemType Directory -Path (Split-Path -Parent $resolvedIco) -Force | Out-Null
New-Item -ItemType Directory -Path (Split-Path -Parent $resolvedPng) -Force | Out-Null

$pngBitmap = New-BrandBitmap -Size 512
$pngBitmap.Save($resolvedPng, [System.Drawing.Imaging.ImageFormat]::Png)
$pngBitmap.Dispose()

$sizes = @(16, 20, 24, 32, 40, 48, 64, 128, 256)
$entries = @()
foreach ($size in $sizes) {
    $bitmap = New-BrandBitmap -Size $size
    $bytes = Convert-BitmapToPngBytes -Bitmap $bitmap
    $bitmap.Dispose()
    $entries += [PSCustomObject]@{ Size = $size; Bytes = $bytes }
}

$stream = [System.IO.File]::Open($resolvedIco, [System.IO.FileMode]::Create)
$writer = New-Object System.IO.BinaryWriter($stream)
$writer.Write([UInt16]0)
$writer.Write([UInt16]1)
$writer.Write([UInt16]$entries.Count)

$offset = 6 + (16 * $entries.Count)
foreach ($entry in $entries) {
    $dimension = if ($entry.Size -eq 256) { 0 } else { $entry.Size }
    $writer.Write([Byte]$dimension)
    $writer.Write([Byte]$dimension)
    $writer.Write([Byte]0)
    $writer.Write([Byte]0)
    $writer.Write([UInt16]1)
    $writer.Write([UInt16]32)
    $writer.Write([UInt32]$entry.Bytes.Length)
    $writer.Write([UInt32]$offset)
    $offset += $entry.Bytes.Length
}
foreach ($entry in $entries) {
    $writer.Write([byte[]]$entry.Bytes)
}
$writer.Flush()
$writer.Dispose()

Write-Host "Generated L2 oat-graphite brand assets:"
Write-Host "  ICO: $resolvedIco"
Write-Host "  PNG: $resolvedPng"
Write-Host "  ICO SHA256: $((Get-FileHash -LiteralPath $resolvedIco -Algorithm SHA256).Hash)"
Write-Host "  PNG SHA256: $((Get-FileHash -LiteralPath $resolvedPng -Algorithm SHA256).Hash)"
