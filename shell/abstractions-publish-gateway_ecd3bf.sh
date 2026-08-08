#!/usr/bin/env bash
# abstractions-publish-gateway.py — portiert nach shell
# Quelle: python, Projects@abstractions:python/abstractions-publish-gateway.py
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# abstractions-publish-gateway.sh — portiert nach python
# Quelle: shell, OpenClaw@gateway2:scripts/abstractions-publish-gateway.sh
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Define the path to the actual script
script_path='/home/openclaw/.openclaw/scripts/abstractions-publish-gateway.sh'

# Check if the script exists
if [[ ! -x "$script_path" ]]; then
    echo "Error: Script not found at $script_path" >&2
    exit 1
fi

# Execute the script with all passed arguments
"$script_path" "$@"
