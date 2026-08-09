#!/usr/bin/env bash
# ABSTRACTIONS_MANAGER.py — portiert nach shell
# Quelle: python, OpenClaw@gateway2:skills/script-abstractions-manager/scripts/ABSTRACTIONS_MANAGER.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Skill-Einstieg fuer den kanonischen Abstractions Manager.

KANONISCHER_MANAGER="/home/openclaw/.openclaw/workspace/abstractions/ABSTRACTIONS_MANAGER.py"

if [[ ! -f "$KANONISCHER_MANAGER" ]]; then
    echo "Kanonischer Abstractions Manager fehlt: $KANONISCHER_MANAGER" >&2
    exit 1
fi

exec python3 "$KANONISCHER_MANAGER" "$@"
