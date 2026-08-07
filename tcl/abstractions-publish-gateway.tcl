#!/usr/bin/env tclsh8.6
# abstractions-publish-gateway.sh — portiert nach tcl
# Quelle: shell, OpenClaw@gateway2:scripts/abstractions-publish-gateway.sh
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

# Workspace-visible wrapper for the gateway publish job.
exec /home/openclaw/.openclaw/scripts/abstractions-publish-gateway.sh {*}$argv
