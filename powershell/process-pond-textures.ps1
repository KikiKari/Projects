#!/usr/bin/env pwsh
# process-pond-textures.py — portiert nach powershell
# Quelle: python, Onboarding@main:scripts/process-pond-textures.py
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
Chroma-key pond textures to add a clean alpha channel.

.DESCRIPTION
The leaf/blossom source webps ship on solid backgrounds (dark green or white)
rather than transparency, so `alphaTest` clipping in three.js has nothing to
key on. This produces RGBA PNGs with a soft alpha mask so the R3F planes clip
to the real silhouette.
#>

using namespace System.Drawing
using namespace System.Drawing.Imaging

$BASE = "public/media/pond"
$OUT = "$BASE/processed"

if (-not (Test-Path $OUT)) {
    New-Item -ItemType Directory -Path $OUT -Force | Out-Null
}

function ConvertTo-GrayscaleBitmap {
    param(
        [System.Drawing.Bitmap]$image
    )
    
    $width = $image.Width
    $height = $image.Height
    $grayscale = New-Object System.Drawing.Bitmap($width, $height)
    
    for ($y = 0; $y -lt $height; $y++) {
        for ($x = 0; $x -lt $width; $x++) {
            $pixel = $image.GetPixel($x, $y)
            $grayValue = [System.Math]::Round(($pixel.R + $pixel.G + $pixel.B) / 3.0)
            $grayscale.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($grayValue, $grayValue, $grayValue))
        }
    }
    
    return $grayscale
}

function Key-Out {
    param(
        [string]$path,
        [string]$out,
        [string]$mode,
        [float]$feather = 2.0
    )
    
    $im = [System.Drawing.Bitmap]::FromFile($path)
    $width = $im.Width
    $height = $im.Height
    
    # Create arrays for RGB channels
    $r = New-Object 'int[,]' $width, $height
    $g = New-Object 'int[,]' $width, $height
    $b = New-Object 'int[,]' $width, $height
    
    # Extract RGB values
    for ($y = 0; $y -lt $height; $y++) {
        for ($x = 0; $x -lt $width; $x++) {
            $pixel = $im.GetPixel($x, $y)
            $r[$x, $y] = $pixel.R
            $g[$x, $y] = $pixel.G
            $b[$x, $y] = $pixel.B
        }
    }
    
    # Create alpha array
    $alpha = New-Object 'byte[,]' $width, $height
    
    if ($mode -eq "green") {
        # Dark-green background: low overall brightness AND green-dominant-but-dark.
        # Foreground leaf is much brighter / lighter green.
        for ($y = 0; $y -lt $height; $y++) {
            for ($x = 0; $x -lt $width; $x++) {
                $lum = ($r[$x, $y] + $g[$x, $y] + $b[$x, $y]) / 3.0
                # background pixels: very dark (lum < ~35) — the bg is ~(3,50,0)=17
                if ($lum -lt 40.0) {
                    $alpha[$x, $y] = 0
                } else {
                    $alpha[$x, $y] = 255
                }
            }
        }
    } elseif ($mode -eq "white") {
        # White background: near-white, low saturation.
        for ($y = 0; $y -lt $height; $y++) {
            for ($x = 0; $x -lt $width; $x++) {
                $mn = [Math]::Min([Math]::Min($r[$x, $y], $g[$x, $y]), $b[$x, $y])
                $mx = [Math]::Max([Math]::Max($r[$x, $y], $g[$x, $y]), $b[$x, $y])
                # background: bright and low chroma
                if (($mn -gt 218.0) -and (($mx - $mn) -lt 28.0)) {
                    $alpha[$x, $y] = 0
                } else {
                    $alpha[$x, $y] = 255
                }
            }
        }
    } else {
        throw "Invalid mode: $mode"
    }
    
    # Create alpha image
    $aImg = New-Object System.Drawing.Bitmap($width, $height)
    for ($y = 0; $y -lt $height; $y++) {
        for ($x = 0; $x -lt $width; $x++) {
            $value = $alpha[$x, $y]
            $aImg.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($value, $value, $value))
        }
    }
    
    # Apply Gaussian blur for feathering
    if ($feather -gt 0) {
        # Since we can't easily apply Gaussian blur in pure PowerShell/.NET without external libraries,
        # we'll approximate it by averaging neighboring pixels
        $blurredImg = New-Object System.Drawing.Bitmap($width, $height)
        $radius = [Math]::Ceiling($feather)
        
        for ($y = 0; $y -lt $height; $y++) {
            for ($x = 0; $x -lt $width; $x++) {
                $sum = 0
                $count = 0
                
                for ($dy = -$radius; $dy -le $radius; $dy++) {
                    for ($dx = -$radius; $dx -le $radius; $dx++) {
                        $nx = $x + $dx
                        $ny = $y + $dy
                        
                        if ($nx -ge 0 -and $nx -lt $width -and $ny -ge 0 -and $ny -lt $height) {
                            $pixelValue = $aImg.GetPixel($nx, $ny).R
                            # Apply simple weight based on distance
                            $distance = [Math]::Sqrt(($dx * $dx) + ($dy * $dy))
                            if ($distance -le $radius) {
                                $weight = 1.0 - ($distance / ($radius + 1))
                                $sum += $pixelValue * $weight
                                $count += $weight
                            }
                        }
                    }
                }
                
                if ($count -gt 0) {
                    $avg = [Math]::Round($sum / $count)
                    $blurredImg.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($avg, $avg, $avg))
                } else {
                    $original = $aImg.GetPixel($x, $y).R
                    $blurredImg.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($original, $original, $original))
                }
            }
        }
        $aImg = $blurredImg
    }
    
    # Create RGBA image
    $rgba = New-Object System.Drawing.Bitmap($width, $height)
    for ($y = 0; $y -lt $height; $y++) {
        for ($x = 0; $x -lt $width; $x++) {
            $originalPixel = $im.GetPixel($x, $y)
            $alphaValue = $aImg.GetPixel($x, $y).R
            $newPixel = [System.Drawing.Color]::FromArgb($alphaValue, $originalPixel.R, $originalPixel.G, $originalPixel.B)
            $rgba.SetPixel($x, $y, $newPixel)
        }
    }
    
    # Find bounding box
    $minX = $width
    $minY = $height
    $maxX = 0
    $maxY = 0
    
    for ($y = 0; $y -lt $height; $y++) {
        for ($x = 0; $x -lt $width; $x++) {
            if ($rgba.GetPixel($x, $y).A -gt 0) {
                if ($x -lt $minX) { $minX = $x }
                if ($x -gt $maxX) { $maxX = $x }
                if ($y -lt $minY) { $minY = $y }
                if ($y -gt $maxY) { $maxY = $y }
            }
        }
    }
    
    # Crop if bbox exists
    if ($minX -lt $maxX -and $minY -lt $maxY) {
        $cropWidth = $maxX - $minX + 1
        $cropHeight = $maxY - $minY + 1
        $cropped = New-Object System.Drawing.Bitmap($cropWidth, $cropHeight)
        
        for ($y = 0; $y -lt $cropHeight; $y++) {
            for ($x = 0; $x -lt $cropWidth; $x++) {
                $pixel = $rgba.GetPixel($minX + $x, $minY + $y)
                $cropped.SetPixel($x, $y, $pixel)
            }
        }
        
        $rgba = $cropped
    }
    
    # Save image
    $encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
    $encoderParam = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::ColorDepth, 32)
    $encoderParams.Param[0] = $encoderParam
    
    $pngEncoder = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/png" }
    $rgba.Save($out, $pngEncoder, $encoderParams)
    
    Write-Host "$([System.IO.Path]::GetFileName($path)) -> $([System.IO.Path]::GetFileName($out)) $($rgba.Width)x$($rgba.Height) ($mode)"
    
    # Clean up
    $im.Dispose()
    $aImg.Dispose()
    $rgba.Dispose()
}

# Lily pads
Key-Out "$BASE/blaetter/12130585.webp" "$OUT/leaf-a.png" "green"
Key-Out "$BASE/blaetter/48178242.webp" "$OUT/leaf-b.png" "white"

# Blossoms with white backgrounds -> clean cutouts (only these two key cleanly)
Key-Out "$BASE/blueten/78370994.webp" "$OUT/blossom-a.png" "white" 3.0
Key-Out "$BASE/blueten/70017289.webp" "$OUT/blossom-b.png" "white" 3.0

Write-Host "done"
