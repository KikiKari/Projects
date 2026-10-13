#!/usr/bin/env pwsh
# tree_fallback.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway2:db-maintainer/scripts/tree_fallback.py
# Erzeugt: 2026-10-13 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
Fallback tree generator for when the `tree` binary is unavailable.

.DESCRIPTION
Produces output similar to `tree -a -L <depth>` and writes it to
important/openclaw-tree.txt with a timestamp header.
#>

$WORKSPACE = "/workspace"
$DEPTH = 6
$SKIP = @(".git", "node_modules", "__pycache__", "venv", ".cache", ".npm", ".local")
$OUT = Join-Path $WORKSPACE "important" "openclaw-tree.txt"

function Walk-Tree($path, $prefix = "", $depth = 0) {
    $lines = @()
    if ($depth -ge $DEPTH) {
        return $lines
    }
    try {
        $entries = Get-ChildItem -Path $path -Force | Sort-Object { if ($_.PSIsContainer) { 0 } else { 1 } }, Name
    } catch {
        return $lines
    }
    $entries = $entries | Where-Object { $SKIP -notcontains $_.Name }
    for ($i = 0; $i -lt $entries.Count; $i++) {
        $entry = $entries[$i]
        $last = $i -eq $entries.Count - 1
        $connector = if ($last) { "└── " } else { "├── " }
        $suffix = if ($entry.PSIsContainer) { "/" } else { "" }
        $lines += "$prefix$connector$($entry.Name)$suffix"
        if ($entry.PSIsContainer -and -not $entry.Target) {
            $extension = if ($last) { "    " } else { "│   " }
            $lines += Walk-Tree -path $entry.FullName -prefix "$prefix$extension" -depth ($depth + 1)
        }
    }
    return $lines
}

function Main() {
    $lines = @($WORKSPACE)
    $lines += Walk-Tree -path $WORKSPACE
    $body = ($lines -join "`n") + "`n"
    $header = @"
# OpenClaw Workspace Tree
# Generiert: $((Get-Date).ToString("o"))
# Fallback (tree binary nicht verfuegbar), Tiefe $DEPTH
# Diese Datei wird automatisch von db-maintainer aktualisiert

"@
    $outDir = Split-Path $OUT -Parent
    if (-not (Test-Path $outDir)) {
        New-Item -ItemType Directory -Path $outDir -Force | Out-Null
    }
    Set-Content -Path $OUT -Value ($header + $body)
    Write-Host "openclaw-tree.txt aktualisiert (Fallback): $OUT ($($lines.Count) Eintraege)"
}

Main
