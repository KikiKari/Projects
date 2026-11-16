#!/usr/bin/env python3
# abstractions-manager-cron.sh — portiert nach python
# Quelle: shell, OpenClaw@gateway1:scripts/abstractions-manager-cron.sh
# Erzeugt: 2026-11-16 durch ABSTRACTIONS_MANAGER.py

import os
import sys
import subprocess
from pathlib import Path

def main():
    # Set PATH
    os.environ["PATH"] = "/home/openclaw/.local/bin:/usr/local/bin:/usr/bin:/bin"
    
    # Load environment variables from file
    env_file = Path("/home/openclaw/.openclaw/.env")
    if env_file.exists():
        with open(env_file) as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    os.environ[key] = value
    
    # Check required environment variable
    if "OPENROUTER_API_KEY" not in os.environ:
        raise SystemExit("OPENROUTER_API_KEY fehlt")
    
    # Set GITHUB_TOKEN with fallback chain
    github_token = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN") or os.environ.get("GH_ACCESS_TOKEN")
    if github_token:
        os.environ["GITHUB_TOKEN"] = github_token
    
    # Execute with flock
    lock_file = "/home/openclaw/.openclaw/locks/abstractions-manager.lock"
    script_path = "/home/openclaw/.openclaw/workspace/skills/script-abstractions-manager/scripts/ABSTRACTIONS_MANAGER.py"
    
    cmd = [
        "/usr/bin/flock",
        "--nonblock",
        lock_file,
        "/usr/bin/python3",
        script_path
    ] + sys.argv[1:]
    
    try:
        result = subprocess.run(cmd, check=True)
        sys.exit(result.returncode)
    except subprocess.CalledProcessError as e:
        sys.exit(e.returncode)

if __name__ == "__main__":
    main()
