#!/usr/bin/env python3
# abstractions-manager.sh — portiert nach python
# Quelle: shell, OpenClaw@gateway2:scripts/abstractions-manager.sh
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

import subprocess
import sys
import os

def main():
    # Führe das Cron-Skript aus und leite alle Argumente weiter
    script_path = "/home/openclaw/.openclaw/scripts/abstractions-manager-cron.sh"
    
    # Prüfe ob das Skript existiert
    if not os.path.exists(script_path):
        print(f"Fehler: {script_path} nicht gefunden", file=sys.stderr)
        sys.exit(1)
    
    try:
        # Führe das Shell-Skript mit allen übergebenen Argumenten aus
        result = subprocess.run([script_path] + sys.argv[1:])
        sys.exit(result.returncode)
    except Exception as e:
        print(f"Fehler beim Ausführen des Skripts: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
