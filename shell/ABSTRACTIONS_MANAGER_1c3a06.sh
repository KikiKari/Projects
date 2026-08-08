#!/usr/bin/env bash
# ABSTRACTIONS_MANAGER.py — portiert nach shell
# Quelle: python, OpenClaw@gateway2:ABSTRACTIONS_MANAGER.py
# auch in: OpenClaw@gateway2:skills/script-abstractions-manager/scripts/ABSTRACTIONS_MANAGER.py
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Compatibility entry point for the canonical Abstractions Manager.

CANONICAL_MANAGER="/home/openclaw/.openclaw/workspace/abstraction-manager/ABSTRACTIONS_MANAGER.py"

if [[ ! -f "$CANONICAL_MANAGER" ]]; then
    echo "Kanonischer Abstraction-Manager fehlt: $CANONICAL_MANAGER" >&2
    exit 1
fi

# Führe das Python-Skript aus
exec python3 "$CANONICAL_MANAGER" "$@"
