#!/usr/bin/env pwsh
# ABSTRACTIONS_MANAGER.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway2:ABSTRACTIONS_MANAGER.py
# auch in: OpenClaw@gateway2:skills/script-abstractions-manager/scripts/ABSTRACTIONS_MANAGER.py
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

<# Compatibility entry point for the canonical Abstractions Manager. #>

$CANONICAL_MANAGER = "/home/openclaw/.openclaw/workspace/abstraction-manager/ABSTRACTIONS_MANAGER.py"

if (-not (Test-Path -Path $CANONICAL_MANAGER -PathType Leaf)) {
    Write-Error "Kanonischer Abstraction-Manager fehlt: $CANONICAL_MANAGER"
    exit 1
}

python3 $CANONICAL_MANAGER
