#!/usr/bin/env python3
# abstractions-publish-gateway-cron.sh — portiert nach python
# Quelle: shell, Projects@clawhub:clawhub/Scripts/abstractions-publish-gateway-cron.sh
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# Wrapper für Linux-crontab - setzt sauberes Environment
import os
import subprocess
from datetime import datetime

# Setze Environment-Variablen
os.environ['HOME'] = '/home/openclaw'
os.environ['PATH'] = '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'

LOG_DIR = "/home/openclaw/.openclaw/logs/abstractions-publish-gateway"
os.makedirs(LOG_DIR, exist_ok=True)
CRON_LOG = os.path.join(LOG_DIR, "linux-cron.log")

# Öffne Log-Datei im Anhängmodus
with open(CRON_LOG, "a") as log_file:
    # Schreibe leere Zeile und Start-Nachricht
    log_file.write("\n")
    log_file.write(f"===== CRON START {datetime.now().strftime('%Y-%m-%d %H:%M:%S')} =====\n")
    
    # Führe das Shell-Skript aus und leite Ausgabe und Fehlerausgabe um
    try:
        result = subprocess.run(
            ["/home/openclaw/.openclaw/scripts/abstractions-publish-gateway.sh"],
            stdout=log_file,
            stderr=subprocess.STDOUT,
            text=True
        )
        exit_code = result.returncode
    except Exception as e:
        log_file.write(f"Fehler beim Ausführen des Skripts: {str(e)}\n")
        exit_code = 1
    
    # Schreibe End-Nachricht
    log_file.write(f"===== CRON END (exit {exit_code}) =====\n")
