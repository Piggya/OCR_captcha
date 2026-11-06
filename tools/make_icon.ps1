# make_icon.ps1
# -----------------------------------------------------------------------------
# Generate assets\ocr-panel.ico (multi-size) from assets\logo.png.
# The .ico feeds the panel window/taskbar icon and the launcher shortcut
# (OCR 控制面板.lnk in the install root, created by tools\make_shortcut.ps1).
#
# Run only when the artwork changes; the .ico is committed so end users never
# need to generate it.
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\make_icon.ps1
#
# NOTE: every size is written as a PNG payload with bit-depth 32 in the ICO
# directory. Sizes 48+ used to be written with a 32-bit DIB header while the
# bytes were PNG, which made Explorer/GDI+ show noise instead of the logo.
# -----------------------------------------------------------------------------

param(
    [string]$OutFile = "",
    [string]$Source = ""
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
if (-not $OutFile) { $OutFile = Join-Path $root "assets\ocr-panel.ico" }
if (-not $Source) { $Source = Join-Path $root "assets\logo.png" }

if (-not (Test-Path -LiteralPath $Source)) {
    throw ("Logo not found: " + $Source)
}

$outDir = Split-Path -Parent $OutFile
if (-not (Test-Path -LiteralPath $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

Add-Type -AssemblyName System.Drawing

$sourceImage = [System.Drawing.Image]::FromFile((Resolve-Path -LiteralPath $Source).Path)
$transparent = [System.Drawing.Color]::Transparent

function New-IconBitmap([int]$size) {
    # Square canvas, transparent background, logo scaled with high quality.
    # Small sizes get a tiny padding so the artwork is not clipped at the edge.
    $bmp = New-Object System.Drawing.Bitmap $size, $size
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.Clear($transparent)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    # Keep a 1px margin at 16/24 so the scan-frame corners stay visible.
    $pad = $(if ($size -le 24) { 1 } else { 0 })
    $inner = $size - 2 * $pad
    $g.DrawImage($script:sourceImage, $pad, $pad, $inner, $inner)
    $g.Dispose()
    return $bmp
}

function ConvertTo-IconDib([System.Drawing.Bitmap]$bmp) {
    # 32bpp BGRA DIB in ICO layout: BITMAPINFOHEADER with doubled height,
    # bottom-up BGRA rows, then the 1bpp AND mask (all zero = "use alpha").
    $w = $bmp.Width
    $h = $bmp.Height
    $ms = New-Object System.IO.MemoryStream
    $bw = New-Object System.IO.BinaryWriter($ms)
    $bw.Write([UInt32]40)          # biSize
    $bw.Write([Int32]$w)           # biWidth
    $bw.Write([Int32]($h * 2))     # biHeight (XOR + AND mask)
    $bw.Write([UInt16]1)           # biPlanes
    $bw.Write([UInt16]32)          # biBitCount
    $bw.Write([UInt32]0)           # biCompression = BI_RGB
    $bw.Write([UInt32]($w * $h * 4))
    $bw.Write([Int32]0); $bw.Write([Int32]0)
    $bw.Write([UInt32]0); $bw.Write([UInt32]0)

    for ($y = $h - 1; $y -ge 0; $y--) {
        for ($x = 0; $x -lt $w; $x++) {
            $c = $bmp.GetPixel($x, $y)
            $bw.Write([Byte]$c.B)
            $bw.Write([Byte]$c.G)
            $bw.Write([Byte]$c.R)
            $bw.Write([Byte]$c.A)
        }
    }

    $maskStride = [int]([Math]::Ceiling($w / 32.0) * 4)
    $mask = New-Object 'Byte[]' ($maskStride * $h)
    $bw.Write($mask)
    $bw.Flush()
    $bytes = $ms.ToArray()
    $bw.Dispose()
    $ms.Dispose()
    return , $bytes
}

# Build a real .ico: header + directory + one 32bpp DIB per size.
# Everything is DIB, including 256x256. GDI+ (System.Drawing.Icon) does not
# decode PNG-compressed entries, so mixing PNG payloads made 64+ render as
# noise; a plain 256x256 DIB is ~256 KB and universally understood.
$sizes = @(16, 24, 32, 48, 64, 128, 256)
$payloads = @()
foreach ($s in $sizes) {
    $bmp = New-IconBitmap $s
    $payloads += , @{ Size = $s; Bytes = (ConvertTo-IconDib $bmp) }
    $bmp.Dispose()
}

$fs = [System.IO.File]::Create($OutFile)
$bw = New-Object System.IO.BinaryWriter($fs)
try {
    $bw.Write([UInt16]0)               # reserved
    $bw.Write([UInt16]1)               # type = icon
    $bw.Write([UInt16]$payloads.Count) # image count

    $offset = 6 + 16 * $payloads.Count
    foreach ($p in $payloads) {
        $dim = $(if ($p.Size -ge 256) { 0 } else { $p.Size })   # 0 means 256
        $bw.Write([Byte]$dim)          # width
        $bw.Write([Byte]$dim)          # height
        $bw.Write([Byte]0)             # color count
        $bw.Write([Byte]0)             # reserved
        $bw.Write([UInt16]1)           # planes
        $bw.Write([UInt16]32)          # bit count
        $bw.Write([UInt32]$p.Bytes.Length)
        $bw.Write([UInt32]$offset)
        $offset += $p.Bytes.Length
    }
    foreach ($p in $payloads) { $bw.Write($p.Bytes) }
} finally {
    $bw.Dispose()
    $fs.Dispose()
    $sourceImage.Dispose()
}

Write-Host ("source=" + $Source)
Write-Host ("icon=" + $OutFile)
Write-Host ("size=" + (Get-Item -LiteralPath $OutFile).Length)
Write-Host ("sizes=" + ($sizes -join ","))
