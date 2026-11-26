#!/data/data/com.termux/files/usr/bin/python3
# abstraction-provenance: {"artifact_sha256": "b052c0d2c9d2f3dea6983bfb100c5983121398f1b074cfec6737d7c206abf5d4", "source_sha256": "dd115a5287b5db772bd4af098a6620a66b294c0e327633048101753a48a3976b", "target_language": "python"}
# openclaw-node-autostart-termux.sh — portiert nach python
# Quelle: shell, OpenClaw@gateway1:scripts/openclaw-node-autostart-termux.sh
# auch in: OpenClaw@gateway2:scripts/openclaw-node-autostart-termux.sh
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import os
import subprocess
import time
from datetime import datetime

SESSION = "openclaw-node"
LOGFILE = os.path.expanduser("~/.openclaw/node.log")
GATEWAY = "10.10.0.1"
PORT = "18789"

def log_message(message):
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_entry = f"[{timestamp}] {message}"
    with open(LOGFILE, "a") as f:
        f.write(log_entry + "\n")

def check_tmux_session_exists(session_name):
    try:
        result = subprocess.run(
            ["tmux", "has-session", "-t", session_name],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
        return result.returncode == 0
    except FileNotFoundError:
        return False

def main():
    os.makedirs(os.path.dirname(LOGFILE), exist_ok=True)

    if check_tmux_session_exists(SESSION):
        log_message(f"OpenClaw Node läuft bereits in tmux Session '{SESSION}'")
        return

    script_content = f"""
import subprocess
import time
import sys
from datetime import datetime

def log_message(msg):
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    entry = f"[{{timestamp}}] {{msg}}"
    print(entry)
    with open("{LOGFILE}", "a") as f:
        f.write(entry + "\\n")

while True:
    log_message("Starting OpenClaw Node Mode...")
    
    try:
        subprocess.run(["ping", "-c", "1", "-W", "3", "{GATEWAY}"], 
                      stdout=subprocess.DEVNULL, 
                      stderr=subprocess.DEVNULL, 
                      check=True)
    except subprocess.CalledProcessError:
        log_message(f"FEHLER: WireGuard Gateway {GATEWAY} nicht erreichbar!")
        log_message("Warte 10 Sekunden...")
        time.sleep(10)
        continue
    
    try:
        result = subprocess.run([
            "openclaw", "node", "run", "--host", "{GATEWAY}", "--port", "{PORT}"
        ], stdout=sys.stdout, stderr=subprocess.STDOUT)
    except Exception as e:
        log_message(f"Fehler beim Starten von OpenClaw: {{e}}")
    
    log_message("OpenClaw beendet. Neustart in 5 Sekunden...")
    time.sleep(5)
"""

    try:
        subprocess.run([
            "tmux", "new-session", "-d", "-s", SESSION, "-n", "node",
            sys.executable, "-c", script_content
        ])
        log_message(f"OpenClaw Node Autostart aktiviert (tmux Session: {SESSION})")
        
        if sys.stdin.isatty():
            print(f"OpenClaw Node Mode gestartet in tmux Session '{SESSION}'")
            print(f"Zum Anschauen: tmux attach -t {SESSION}")
            print(f"Log-Datei: {LOGFILE}")
            
    except FileNotFoundError:
        log_message("FEHLER: tmux nicht gefunden!")
        print("FEHLER: tmux nicht gefunden!")

if __name__ == "__main__":
    main()
