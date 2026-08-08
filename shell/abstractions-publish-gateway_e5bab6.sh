#!/usr/bin/env bash
# abstractions-publish-gateway.tcl — portiert nach shell
# Quelle: tcl, Projects@abstractions:tcl/abstractions-publish-gateway.tcl
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail
# abstractions-publish-gateway.sh — portiert nach tcl
# Quelle: shell, OpenClaw@gateway2:scripts/abstractions-publish-gateway.sh
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

# Workspace-visible wrapper for the gateway publish job.
exec /home/openclaw/.openclaw/scripts/abstractions-publish-gateway.sh "$@"
