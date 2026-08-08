#!/usr/bin/env python3
# abstractions-publish-gateway.ps1 — portiert nach python
# Quelle: powershell, Projects@abstractions:powershell/abstractions-publish-gateway.ps1
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# abstractions-publish-gateway.sh — portiert nach powershell
# Quelle: shell, OpenClaw@gateway2:scripts/abstractions-publish-gateway.sh
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

import subprocess
import sys
import os

# Workspace-visible wrapper for the gateway publish job.
script_path = '/home/openclaw/.openclaw/scripts/abstractions-publish-gateway.sh'
subprocess.run([script_path] + sys.argv[1:], check=True)
