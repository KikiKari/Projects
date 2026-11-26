#!/usr/bin/env pwsh
# abstraction-provenance: {"artifact_sha256": "61a9d3eb0f43cd5919b01c005adb497cc02ec8ea2aeee0b6a5ca0aae5acd78a7", "source_sha256": "b339455e9e618c836ccf2e3732e4fec9897f079730d8814eadb716e2459df453", "target_language": "powershell"}
# frame.sh — portiert nach powershell
# Quelle: shell, OpenClaw@gateway1:skills/video-frames/scripts/frame.sh
# auch in: OpenClaw@gateway2:skills/video-frames/scripts/frame.sh
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

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
  exit 2
}

if ($args.Count -eq 0 -or $args[0] -eq "-h" -or $args[0] -eq "--help") {
  Show-Usage
}

$in = $args[0]
$args = $args[1..($args.Length - 1)]

$time = ""
$index = ""
$out = ""

$i = 0
while ($i -lt $args.Count) {
  $arg = $args[$i]
  switch ($arg) {
    "--time" {
      if ($i + 1 -ge $args.Count) { throw "Missing value for --time" }
      $time = $args[$i + 1]
      $i += 2
    }
    "--index" {
      if ($i + 1 -ge $args.Count) { throw "Missing value for --index" }
      $index = $args[$i + 1]
      $i += 2
    }
    "--out" {
      if ($i + 1 -ge $args.Count) { throw "Missing value for --out" }
      $out = $args[$i + 1]
      $i += 2
    }
    default {
      Write-Error "Unknown arg: $arg"
      Show-Usage
    }
  }
}

if (-not (Test-Path $in)) {
  Write-Error "File not found: $in"
  exit 1
}

if ([string]::IsNullOrEmpty($out)) {
  Write-Error "Missing --out"
  Show-Usage
}

$dir = Split-Path $out -Parent
if (-not [string]::IsNullOrEmpty($dir) -and -not (Test-Path $dir)) {
  New-Item -ItemType Directory -Path $dir | Out-Null
}

if (-not [string]::IsNullOrEmpty($index)) {
  ffmpeg -hide_banner -loglevel error -y `
    -i "$in" `
    -vf "select=eq(n\,$index)" `
    -vframes 1 `
    "$out"
} elseif (-not [string]::IsNullOrEmpty($time)) {
  ffmpeg -hide_banner -loglevel error -y `
    -ss "$time" `
    -i "$in" `
    -frames:v 1 `
    "$out"
} else {
  ffmpeg -hide_banner -loglevel error -y `
    -i "$in" `
    -vf "select=eq(n\,0)" `
    -vframes 1 `
    "$out"
}

Write-Output $out
