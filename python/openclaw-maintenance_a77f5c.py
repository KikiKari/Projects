#!/usr/bin/env python3
# openclaw-maintenance.sh — portiert nach python
# Quelle: shell, OpenClaw@gateway2:scripts/openclaw-maintenance.sh
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

import os
import subprocess
import sys

OPENCLAW_BIN = os.environ.get('OPENCLAW_BIN', os.path.expanduser('~/.local/bin/openclaw'))

if not os.path.isfile(OPENCLAW_BIN) or not os.access(OPENCLAW_BIN, os.X_OK):
    print(f"ERROR: OpenClaw binary not found: {OPENCLAW_BIN}", file=sys.stderr)
    sys.exit(1)

def run_command(cmd):
    result = subprocess.run(cmd, capture_output=True, text=True)
    print(result.stdout)
    if result.stderr:
        print(result.stderr, file=sys.stderr)
    if result.returncode != 0:
        sys.exit(result.returncode)

print("Using OpenClaw:", end=" ")
run_command([OPENCLAW_BIN, "--version"])

# === 1. Service-/Config-Drift ===
run_command([OPENCLAW_BIN, "doctor"])

# === 2. Plugin-Stage (Registry refresh only; updates are explicit/manual) ===
run_command([OPENCLAW_BIN, "plugins", "registry", "--refresh"])
if os.environ.get("RUN_PLUGIN_UPDATE", "0") == "1":
    run_command([OPENCLAW_BIN, "plugins", "update", "--all"])
else:
    print("Skipping plugin update. Run with RUN_PLUGIN_UPDATE=1 to enable.")

# === 3. Tasks ===
run_command([OPENCLAW_BIN, "tasks", "maintenance", "--apply"])

# === 4. Sessions – alle Agents auf einmal ===
run_command([OPENCLAW_BIN, "sessions", "cleanup", "--enforce", "--all-agents"])

# === 5. Memory – status/index decken alle Agents ab ===
run_command([OPENCLAW_BIN, "memory", "status", "--deep", "--fix"])
run_command([OPENCLAW_BIN, "memory", "index", "--force"])

# === 6. Memory promote – MUSS pro Agent ===
agents = ["main", "knecht", "docs", "ops-hub", "cron"]
for agent in agents:
    run_command([OPENCLAW_BIN, "memory", "promote", "--apply", "--agent", agent])

# === 7. Secrets ===
run_command([OPENCLAW_BIN, "secrets", "reload"])
