#!/data/data/com.termux/files/usr/bin/python3.12
# openclaw-node-autostart-termux.sh — portiert nach python
# Quelle: shell, OpenClaw@gateway1:scripts/openclaw-node-autostart-termux.sh
# auch in: OpenClaw@gateway2:scripts/openclaw-node-autostart-termux.sh
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

# OpenClaw Node Mode Autostart für Termux (Node 5 - Redmi Note 11)
# Installiert nach: ~/.termux/boot/openclaw-node.py
# Getestet mit: Termux + Android + OpenClaw

import os
import subprocess
import time
from datetime import datetime

SESSION = "openclaw-node"
LOGFILE = os.path.expanduser("~/.openclaw/node.log")
GATEWAY = "10.10.0.1"
PORT = "18789"

# Log-Verzeichnis erstellen
os.makedirs(os.path.expanduser("~/.openclaw"), exist_ok=True)

def log_message(message):
    """Schreibt eine Nachricht mit Zeitstempel in die Logdatei"""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_entry = f"[{timestamp}] {message}\n"
    with open(LOGFILE, "a") as f:
        f.write(log_entry)
    # Ausgabe auf stdout falls interaktiv
    if os.isatty(1):
        print(log_entry.strip())

def check_tmux_session():
    """Prüft ob tmux Session bereits läuft"""
    try:
        result = subprocess.run(
            ["tmux", "has-session", "-t", SESSION],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
        return result.returncode == 0
    except FileNotFoundError:
        log_message("FEHLER: tmux nicht gefunden!")
        return False

def main():
    """Hauptfunktion zum Starten des OpenClaw Node Modes"""
    # Prüfen ob tmux Session bereits läuft
    if check_tmux_session():
        log_message(f"OpenClaw Node läuft bereits in tmux Session '{SESSION}'")
        return

    # tmux Kommando zum Starten der Session
    tmux_cmd = [
        "tmux", "new-session", "-d", "-s", SESSION, "-n", "node",
        "while true; do "
        f"echo \"[$(date)] Starting OpenClaw Node Mode...\" | tee -a '{LOGFILE}'; "
        f"if ! ping -c 1 -W 3 {GATEWAY} >/dev/null 2>&1; then "
        f"echo \"[$(date)] FEHLER: WireGuard Gateway {GATEWAY} nicht erreichbar!\" | tee -a '{LOGFILE}'; "
        f"echo \"[$(date)] Warte 10 Sekunden...\" | tee -a '{LOGFILE}'; "
        "sleep 10; "
        "continue; "
        "fi; "
        f"openclaw node run --host {GATEWAY} --port {PORT} 2>&1 | tee -a '{LOGFILE}'; "
        f"echo \"[$(date)] OpenClaw beendet. Neustart in 5 Sekunden...\" | tee -a '{LOGFILE}'; "
        "sleep 5; "
        "done"
    ]

    try:
        subprocess.run(tmux_cmd, check=True)
        log_message(f"OpenClaw Node Autostart aktiviert (tmux Session: {SESSION})")
        
        # Optional: tmux attach Hinweis falls interaktiv gestartet
        if os.isatty(1):
            print(f"OpenClaw Node Mode gestartet in tmux Session '{SESSION}'")
            print(f"Zum Anschauen: tmux attach -t {SESSION}")
            print(f"Log-Datei: {LOGFILE}")
    except subprocess.CalledProcessError as e:
        log_message(f"FEHLER beim Starten der tmux Session: {e}")
    except Exception as e:
        log_message(f"Unerwarteter Fehler: {e}")

if __name__ == "__main__":
    main()
