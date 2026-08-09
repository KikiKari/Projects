#!/usr/bin/env pwsh
# frame.sh — portiert nach powershell
# Quelle: shell, OpenClaw@gateway1:skills/video-frames/scripts/frame.sh
# auch in: OpenClaw@gateway2:skills/video-frames/scripts/frame.sh
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

$ErrorActionPreference = "Stop"

function Show-Usage {
  Write-Error @"
Usage:
  frame.ps1 <video-file> [--time HH:MM:SS] [--index N] --out /path/to/frame.jpg

Examples:
  frame.ps1 video.mp4 --out /tmp/frame.jpg
  frame.ps1 video.mp4 --time 00:00:10 --out /tmp/frame-10s.jpg
  frame.ps1 video.mp4 --index 0 --out /tmp/frame0.png
"@ -ErrorAction Stop
}

if ($args.Count -eq 0 -or $args[0] -eq "-h" -or $args[0] -eq "--help") {
  Show-Usage
}

$in = $args[0]
$remainingArgs = $args[1..$args.Length]

$time = ""
$index = ""
$out = ""

$i = 0
while ($i -lt $remainingArgs.Count) {
  $arg = $remainingArgs[$i]
  switch ($arg) {
    "--time" {
      $i++
      $time = $remainingArgs[$i]
    }
    "--index" {
      $i++
      $index = $remainingArgs[$i]
    }
    "--out" {
      $i++
      $out = $remainingArgs[$i]
    }
    default {
      Write-Error "Unknown arg: $arg" -ErrorAction Stop
      Show-Usage
    }
  }
  $i++
}

if (-not (Test-Path $in -PathType Leaf)) {
  Write-Error "File not found: $in" -ErrorAction Stop
}

if ($out -eq "") {
  Write-Error "Missing --out" -ErrorAction Stop
  Show-Usage
}

$dir = Split-Path $out -Parent
if ($dir -and -not (Test-Path $dir)) {
  New-Item -ItemType Directory -Path $dir | Out-Null
}

if ($index -ne "") {
  $filter = "select=eq(n\,$index)"
  ffmpeg -hide_banner -loglevel error -y -i $in -vf $filter -vframes 1 $out
} elseif ($time -ne "") {
  ffmpeg -hide_banner -loglevel error -y -ss $time -i $in -frames:v 1 $out
} else {
  $filter = "select=eq(n\,0)"
  ffmpeg -hide_banner -loglevel error -y -i $in -vf $filter -vframes 1 $out
}

Write-Output $out
