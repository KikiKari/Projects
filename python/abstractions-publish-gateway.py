#!/usr/bin/env python3
# abstractions-publish-gateway.js — portiert nach python
# Quelle: javascript, Projects@abstractions:javascript/abstractions-publish-gateway.js
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# abstractions-publish-gateway.sh — portiert nach javascript
# Quelle: shell, OpenClaw@gateway2:scripts/abstractions-publish-gateway.sh
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

# Workspace-visible wrapper for the gateway publish job.
import subprocess
import sys
import os

script_path = os.path.join('/home/openclaw/.openclaw/scripts/abstractions-publish-gateway.sh')

try:
    result = subprocess.run([script_path] + sys.argv[1:])
    sys.exit(result.returncode)
except FileNotFoundError:
    print(f"Failed to start script: {script_path} not found", file=sys.stderr)
    sys.exit(1)
except Exception as err:
    print(f"Failed to start script: {err}", file=sys.stderr)
    sys.exit(1)
