#!/usr/bin/env python3
# abstraction-provenance: {"artifact_sha256": "2192a59caed2eb376d92eae3c9c54801583d64fbba50f81d3445fedec5b96452", "source_sha256": "76a9327ec4d8b7b9abcabfcbbbf89350cb4a3a4fdc0c949a0b343fe059dc87a8", "target_language": "python"}
# abstractions-manager.sh — portiert nach python
# Quelle: shell, OpenClaw@gateway2:scripts/abstractions-manager.sh
# Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py

import subprocess
import sys
import os

def main():
    """Execute the abstractions manager cron script with passed arguments"""
    script_path = "/home/openclaw/.openclaw/scripts/abstractions-manager-cron.sh"
    
    # Execute the shell script with all passed arguments
    try:
        result = subprocess.run([script_path] + sys.argv[1:], check=True)
        sys.exit(result.returncode)
    except subprocess.CalledProcessError as e:
        sys.exit(e.returncode)
    except FileNotFoundError:
        print(f"Error: Script not found at {script_path}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
