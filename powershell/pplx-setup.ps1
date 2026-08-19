#!/usr/bin/env pwsh
# pplx-setup.sh — portiert nach powershell
# Quelle: shell, OpenClaw@main:scripts/pplx-tools/pplx-setup.sh
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

# One-time (idempotent): make sure the Perplexity VS Code extension daemon can
# find a Chromium. The daemon uses its OWN bundled patchright, which pins a
# specific chromium revision; install exactly that revision.

$ErrorActionPreference = "Stop"

$extprDirs = Get-ChildItem -Path "$env:HOME/.vscode-remote/extensions" -Directory | Where-Object { $_.Name -like "nskha.perplexity-vscode-*" }
if ($extprDirs.Count -eq 0) {
    Write-Host "[setup] extension patchright not found — is the Perplexity extension installed?"
    exit 0
}

$sortedDirs = $extprDirs | ForEach-Object { $_.FullName } | Sort-Object
$latestDir = $sortedDirs[-1]
$extpr = Join-Path $latestDir "dist/node_modules/patchright"

if (-not (Test-Path $extpr)) {
    Write-Host "[setup] extension patchright not found — is the Perplexity extension installed?"
    exit 0
}

try {
    $exp = node -e "const {chromium}=require('$extpr');console.log(chromium.executablePath())" 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Node command failed"
    }
} catch {
    $exp = $null
}

if ($exp -and (Test-Path $exp -PathType Leaf)) {
    Write-Host "[setup] daemon browser already present: $exp"
    exit 0
}

Write-Host "[setup] installing matching chromium for the extension daemon (expected: $(if ($exp) { $exp } else { 'unknown' }))..."
node "$extpr/cli.js" install chromium
Write-Host "[setup] done."
