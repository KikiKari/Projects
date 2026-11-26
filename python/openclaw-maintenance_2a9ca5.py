#!/usr/bin/env python3
# abstraction-provenance: {"artifact_sha256": "fc10bae36b4f85b5508d38c1317ffe8383f7f7c98bdf5f9ea7c17ea10d3a266b", "source_sha256": "2a9ca592fdc915cfb281aa77dde9f07ffd3de83ce5abb8d87c77d46668d75dd6", "target_language": "python"}
# openclaw-maintenance.sh — portiert nach python
# Quelle: shell, OpenClaw@gateway1:scripts/openclaw-maintenance.sh
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import subprocess
import sys

def run_command(command):
    """Führt einen Shell-Befehl aus und gibt den Return Code zurück"""
    try:
        result = subprocess.run(command, shell=True, check=True, capture_output=True, text=True)
        return result.returncode
    except subprocess.CalledProcessError as e:
        print(f"Fehler beim Ausführen von: {command}", file=sys.stderr)
        print(f"Exit-Code: {e.returncode}", file=sys.stderr)
        if e.stdout:
            print(f"STDOUT: {e.stdout}", file=sys.stderr)
        if e.stderr:
            print(f"STDERR: {e.stderr}", file=sys.stderr)
        return e.returncode

def main():
    # === 1. Service-/Config-Drift ===
    run_command("openclaw doctor")

    # === 2. Plugin-Stage (aktive Varianten, NICHT plugins doctor) ===
    run_command("openclaw plugins registry --refresh")
    run_command("openclaw plugins update --all")

    # === 3. Tasks ===
    run_command("openclaw tasks maintenance --apply")

    # === 4. Sessions – alle Agents auf einmal ===
    run_command("openclaw sessions cleanup --enforce --all-agents")

    # === 5. Memory – status/index decken alle Agents ab ===
    run_command("openclaw memory status --deep --fix")
    run_command("openclaw memory index --force")

    # === 6. Memory promote – MUSS pro Agent ===
    agents = ["main", "knecht", "docs", "ops-hub", "cron"]
    for agent in agents:
        run_command(f'openclaw memory promote --apply --agent "{agent}"')

    # === 7. Secrets ===
    run_command("openclaw secrets reload")

if __name__ == "__main__":
    main()
