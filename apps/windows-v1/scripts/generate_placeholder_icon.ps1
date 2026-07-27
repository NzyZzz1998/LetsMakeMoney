param(
    [string]$OutputPath = (Join-Path $PSScriptRoot "..\src-tauri\icons\icon.ico")
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$resolvedOutput = [System.IO.Path]::GetFullPath($OutputPath)
$outputDirectory = Split-Path -Parent $resolvedOutput
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null

$size = 256
$bitmap = New-Object System.Drawing.Bitmap($size, $size)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$graphics.Clear([System.Drawing.Color]::Transparent)

$coinBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 246, 179, 48))
$inkBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 48, 43, 38))
$outlinePen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 226, 147, 19), 8)
$font = New-Object System.Drawing.Font("Arial", 116, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
$format = New-Object System.Drawing.StringFormat
$format.Alignment = [System.Drawing.StringAlignment]::Center
$format.LineAlignment = [System.Drawing.StringAlignment]::Center

$coinBounds = New-Object System.Drawing.RectangleF(18, 18, 220, 220)
$graphics.FillEllipse($coinBrush, $coinBounds)
$graphics.DrawEllipse($outlinePen, $coinBounds)
$graphics.DrawString([char]0x00A5, $font, $inkBrush, $coinBounds, $format)

$pngStream = New-Object System.IO.MemoryStream
$bitmap.Save($pngStream, [System.Drawing.Imaging.ImageFormat]::Png)
$pngBytes = $pngStream.ToArray()

# ICO may contain PNG payloads. A single deterministic 256px entry is enough
# for the M0 compilation skeleton; final branding remains an M1 decision.
$fileStream = [System.IO.File]::Open($resolvedOutput, [System.IO.FileMode]::Create)
$writer = New-Object System.IO.BinaryWriter($fileStream)
$writer.Write([UInt16]0)
$writer.Write([UInt16]1)
$writer.Write([UInt16]1)
$writer.Write([Byte]0)
$writer.Write([Byte]0)
$writer.Write([Byte]0)
$writer.Write([Byte]0)
$writer.Write([UInt16]1)
$writer.Write([UInt16]32)
$writer.Write([UInt32]$pngBytes.Length)
$writer.Write([UInt32]22)
$writer.Write($pngBytes)
$writer.Flush()
$writer.Dispose()

$pngStream.Dispose()
$format.Dispose()
$font.Dispose()
$outlinePen.Dispose()
$inkBrush.Dispose()
$coinBrush.Dispose()
$graphics.Dispose()
$bitmap.Dispose()

$hash = (Get-FileHash -LiteralPath $resolvedOutput -Algorithm SHA256).Hash
Write-Host "Generated placeholder icon: $resolvedOutput"
Write-Host "SHA256: $hash"
