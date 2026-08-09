#!/usr/bin/env python3
# fix_gateway_node_path.sh — portiert nach python
# Quelle: shell, OpenClaw@gateway1:scripts/fix_gateway_node_path.sh
# auch in: OpenClaw@gateway2:scripts/fix_gateway_node_path.sh
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

import os
import shutil
import subprocess
import sys
from datetime import datetime

def main():
    # Backup der originalen Service-Datei
    service_file = "/etc/systemd/system/openclaw-gateway.service"
    backup_suffix = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_file = f"/etc/systemd/system/openclaw-gateway.service.backup-{backup_suffix}"
    
    try:
        shutil.copy2(service_file, backup_file)
    except Exception as e:
        print(f"Fehler beim Erstellen des Backups: {e}", file=sys.stderr)
        sys.exit(1)

    # Korrektur des Node.js Pfads in der Service-Datei
    # Annahme: Node.js ist unter /usr/bin/node verfügbar (wie von 'which node' gezeigt)
    try:
        with open(service_file, 'r') as file:
            content = file.read()
        
        content = content.replace('/home/openclaw/.nvm/versions/node/v22.22.2/bin/node', '/usr/bin/node')
        
        with open(service_file, 'w') as file:
            file.write(content)
    except Exception as e:
        print(f"Fehler beim Aktualisieren der Service-Datei: {e}", file=sys.stderr)
        sys.exit(1)

    # Service neu laden und neu starten
    try:
        subprocess.run(['systemctl', 'daemon-reload'], check=True)
        subprocess.run(['systemctl', 'restart', 'openclaw-gateway'], check=True)
    except subprocess.CalledProcessError as e:
        print(f"Fehler beim Neustarten des Services: {e}", file=sys.stderr)
        sys.exit(1)

    # Status prüfen
    try:
        result = subprocess.run(['systemctl', 'status', 'openclaw-gateway', '--no-pager'], 
                              check=True, capture_output=True, text=True)
        print(result.stdout)
    except subprocess.CalledProcessError as e:
        print(f"Fehler beim Abfragen des Service-Status: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
