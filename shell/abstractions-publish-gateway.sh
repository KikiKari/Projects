#!/usr/bin/env bash
# abstractions-publish-gateway.js — portiert nach shell
# Quelle: javascript, Projects@abstractions:javascript/abstractions-publish-gateway.js
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail
# abstractions-publish-gateway.sh — portiert nach javascript
# Quelle: shell, OpenClaw@gateway2:scripts/abstractions-publish-gateway.sh
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

# Workspace-visible wrapper for the gateway publish job.
script_path="/home/openclaw/.openclaw/scripts/abstractions-publish-gateway.sh"

if [[ ! -x "$script_path" ]]; then
    echo "Script not found or not executable: $script_path" >&2
    exit 1
fi

"$script_path" "${@:1}"
