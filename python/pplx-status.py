#!/usr/bin/env python3
# pplx-status.sh — portiert nach python
# Quelle: shell, OpenClaw@main:scripts/pplx-tools/pplx-status.sh
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

# Quick status of the codespace Perplexity daemon session.
import os
import sys
import json
import subprocess

CFG = os.environ.get('PERPLEXITY_CONFIG_DIR', os.path.join(os.path.expanduser('~'), '.perplexity-mcp'))
PROFILE = os.environ.get('PERPLEXITY_PROFILE', 'codespace')
STAT = os.path.join(CFG, 'profiles', PROFILE, 'daemon-status.json')

if os.path.isfile(STAT):
    with open(STAT, 'r') as f:
        data = json.load(f)
        print(json.dumps(data, indent=4))
else:
    print(f"no daemon-status.json at {STAT}")

print("--- recent auth lines ---")
try:
    result = subprocess.run(
        ['grep', '-iE', 'Authenticated as user|Account tier|Injected .* cookies|Reinit requested|not-logged-in', os.path.join(CFG, 'daemon.log')],
        capture_output=True,
        text=True,
        check=True
    )
    lines = result.stdout.strip().split('\n')
    for line in lines[-6:]:
        print(line)
except subprocess.CalledProcessError:
    pass
except FileNotFoundError:
    pass
