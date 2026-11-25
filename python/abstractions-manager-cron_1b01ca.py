#!/usr/bin/env python3
# abstraction-provenance: {"artifact_sha256": "26561ff4b8a67447632dfbfdbaf319c6bccccaee788b42db75bee9136af26ffa", "source_sha256": "1b01ca0f5943b16d3905faf557953600ee54f15ecf1dc18c1461585eba94d376", "target_language": "python"}
# abstractions-manager-cron.sh — portiert nach python
# Quelle: shell, OpenClaw@gateway1:scripts/abstractions-manager-cron.sh
# Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py

import os
import sys
import fcntl
import subprocess

# Set the PATH environment variable
os.environ['PATH'] = "/home/openclaw/.local/bin:/usr/local/bin:/usr/bin:/bin"

# Load environment variables from .env file
with open('/home/openclaw/.openclaw/.env', 'r') as env_file:
    for line in env_file:
        key, value = line.strip().split('=', 1)
        os.environ[key] = value

# Check if OPENROUTER_API_KEY is set
if 'OPENROUTER_API_KEY' not in os.environ:
    raise EnvironmentError("OPENROUTER_API_KEY fehlt")

# Set GITHUB_TOKEN with fallbacks
os.environ['GITHUB_TOKEN'] = os.getenv('GITHUB_TOKEN', os.getenv('GH_TOKEN', os.getenv('GH_ACCESS_TOKEN', '')))

# Try to acquire a non-blocking lock
lock_file_path = '/home/openclaw/.openclaw/locks/abstractions-manager.lock'
try:
    with open(lock_file_path, 'w') as lock_file:
        fcntl.flock(lock_file, fcntl.LOCK_EX | fcntl.LOCK_NB)
        # Execute the ABSTRACTIONS_MANAGER.py script with command-line arguments
        subprocess.run(['/usr/bin/python3', '/home/openclaw/.openclaw/workspace/skills/script-abstractions-manager/scripts/ABSTRACTIONS_MANAGER.py'] + sys.argv[1:], check=True)
except BlockingIOError:
    print("Another instance of the script is already running.", file=sys.stderr)
