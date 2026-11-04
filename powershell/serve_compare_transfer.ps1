#!/usr/bin/env pwsh
# serve_compare_transfer.sh — portiert nach powershell
# Quelle: shell, OpenClaw@gateway1:scripts/serve_compare_transfer.sh
# Erzeugt: 2026-11-04 durch ABSTRACTIONS_MANAGER.py

$COMPARE_DIR = "/home/openclaw/.openclaw/workspace/vscode/compare"
$TRANSFER_DIR = "/home/openclaw/.openclaw/workspace/vscode/compare/transfer"
$HOST_IP = "152.53.145.65"
$PORT = "80"
$SELF_PATH = (Get-Item $MyInvocation.MyCommand.Path).FullName

$FILES = Get-ChildItem -Path $COMPARE_DIR -File | Where-Object { $_.FullName -ne $SELF_PATH } | Sort-Object Name

if ($FILES.Count -eq 0) {
    Write-Host "Keine Dateien in ${COMPARE_DIR} gefunden."
    exit 1
}

Write-Host ""
Write-Host "Bereitgestellte Dateien aus ${COMPARE_DIR}:"
foreach ($src in $FILES) {
    Write-Host "- $($src.Name)"
}

Write-Host ""
Write-Host "Copy/Paste auf anderem Gateway (Download nach ${TRANSFER_DIR}):"
foreach ($src in $FILES) {
    $file = $src.Name
    Write-Host "curl -fL --retry 3 --connect-timeout 10 -o ${TRANSFER_DIR}/${file} http://${HOST_IP}:${PORT}/${file}"
}

Write-Host ""
Write-Host "Server auf Port ${PORT} aktiv. Beenden mit STRG+C."
Write-Host ""

Set-Location $COMPARE_DIR
python3 -m http.server $PORT --bind 0.0.0.0
