#!/usr/bin/env python3
# abstractions-publish-gateway.tcl — portiert nach python
# Quelle: tcl, Projects@abstractions:tcl/abstractions-publish-gateway.tcl
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# abstractions-publish-gateway.sh — portiert nach tcl
# Quelle: shell, OpenClaw@gateway2:scripts/abstractions-publish-gateway.sh
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

# Workspace-visible wrapper for the gateway publish job.
import subprocess
import sys
import os

# Führe das Shell-Skript mit denselben Argumenten aus
result = subprocess.run([
    '/home/openclaw/.openclaw/scripts/abstractions-publish-gateway.sh'
] + sys.argv[1:])

# Beende das Python-Skript mit demselben Exit-Code wie das aufgerufene Skript
sys.exit(result.returncode)
