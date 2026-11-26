#!/usr/bin/env python3
# abstraction-provenance: {"artifact_sha256": "99f706355865fa08764340228043462bf3113c5c24405a78eab86d53cb3af478", "source_sha256": "a77f5c2629fe7fafac268cfbf2f0b3e77a194322aee8f9c06967eb6c33db043e", "target_language": "python"}
# openclaw-maintenance.sh — portiert nach python
# Quelle: shell, OpenClaw@gateway2:scripts/openclaw-maintenance.sh
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import os
import subprocess
import sys

def get_openclaw_bin():
    openclaw_bin = os.environ.get('OPENCLAW_BIN', os.path.expanduser('~/.local/bin/openclaw'))
    if not os.path.isfile(openclaw_bin) or not os.access(openclaw_bin, os.X_OK):
        print(f"ERROR: OpenClaw binary not found: {openclaw_bin}", file=sys.stderr)
        sys.exit(1)
    return openclaw_bin

def run_command(command):
    result = subprocess.run(command, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Command failed: {' '.join(command)}", file=sys.stderr)
        print(result.stderr, file=sys.stderr)
        sys.exit(result.returncode)
    return result.stdout.strip()

def main():
    openclaw_bin = get_openclaw_bin()
    
    version_output = run_command([openclaw_bin, '--version'])
    print(f"Using OpenClaw: {version_output}")
    
    # === 1. Service-/Config-Drift ===
    run_command([openclaw_bin, 'doctor'])
    
    # === 2. Plugin-Stage (Registry refresh only; updates are explicit/manual) ===
    run_command([openclaw_bin, 'plugins', 'registry', '--refresh'])
    if os.environ.get('RUN_PLUGIN_UPDATE', '0') == '1':
        run_command([openclaw_bin, 'plugins', 'update', '--all'])
    else:
        print("Skipping plugin update. Run with RUN_PLUGIN_UPDATE=1 to enable.")
    
    # === 3. Tasks ===
    run_command([openclaw_bin, 'tasks', 'maintenance', '--apply'])
    
    # === 4. Sessions – alle Agents auf einmal ===
    run_command([openclaw_bin, 'sessions', 'cleanup', '--enforce', '--all-agents'])
    
    # === 5. Memory – status/index decken alle Agents ab ===
    run_command([openclaw_bin, 'memory', 'status', '--deep', '--fix'])
    run_command([openclaw_bin, 'memory', 'index', '--force'])
    
    # === 6. Memory promote – MUSS pro Agent ===
    agents = ['main', 'knecht', 'docs', 'ops-hub', 'cron']
    for agent in agents:
        run_command([openclaw_bin, 'memory', 'promote', '--apply', '--agent', agent])
    
    # === 7. Secrets ===
    run_command([openclaw_bin, 'secrets', 'reload'])

if __name__ == '__main__':
    main()
