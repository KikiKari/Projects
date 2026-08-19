#!/usr/bin/env python3
# setup-xvfb-node3.sh — portiert nach python
# Quelle: shell, OpenClaw@gateway1:scripts/setup-xvfb-node3.sh
# auch in: OpenClaw@gateway2:scripts/setup-xvfb-node3.sh
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

# Xvfb Setup für Node 3 (xNetX VPS)
# Erstellt: 2026-04-09
# Hinweis: Altes VNC-Setup wird entfernt

import subprocess
import sys
import os

def run_command(command, ignore_errors=False):
    """Führt einen Shell-Befehl aus und gibt stdout und stderr zurück"""
    try:
        result = subprocess.run(command, shell=True, check=True, text=True, capture_output=True)
        return result.stdout, result.stderr
    except subprocess.CalledProcessError as e:
        if ignore_errors:
            return e.stdout, e.stderr
        else:
            print(f"Fehler beim Ausführen von: {command}")
            print(f"Exit code: {e.returncode}")
            print(f"stdout: {e.stdout}")
            print(f"stderr: {e.stderr}")
            sys.exit(1)

def main():
    print("=== Xvfb + Chromium Setup für Node 3 ===")
    print("=== Entferne altes VNC-Setup ===")

    # Altes VNC stoppen & entfernen (falls vorhanden)
    run_command("sudo systemctl stop vncserver@* 2>/dev/null", ignore_errors=True)
    run_command("sudo systemctl disable vncserver@* 2>/dev/null", ignore_errors=True)
    run_command("sudo apt-get remove -y tightvncserver tigervnc-standalone-server 2>/dev/null", ignore_errors=True)
    
    # Entferne VNC-Dateien
    try:
        if os.path.exists(os.path.expanduser("~/.vnc")):
            run_command("sudo rm -rf ~/.vnc")
        run_command("sudo rm -rf /tmp/.X11-unix/X*", ignore_errors=True)
    except Exception as e:
        print(f"Warnung beim Löschen von VNC-Dateien: {e}")

    print("=== Installiere Xvfb + Chromium ===")

    # Update & Install
    run_command("sudo apt-get update")
    
    packages = [
        "xvfb",
        "chromium",
        "chromium-driver",
        "fonts-liberation",
        "libappindicator3-1",
        "libasound2",
        "libatk-bridge2.0-0",
        "libatk1.0-0",
        "libcups2",
        "libgtk-3-0",
        "libnspr4",
        "libnss3",
        "libxss1",
        "xdg-utils"
    ]
    
    install_cmd = "sudo apt-get install -y " + " ".join(packages)
    run_command(install_cmd)

    # Xvfb Systemd Service erstellen
    service_content = """[Unit]
Description=X Virtual Framebuffer
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/Xvfb :99 -screen 0 1920x1080x24 -ac +extension GLX +render -noreset
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
"""

    with open("/tmp/xvfb.service", "w") as f:
        f.write(service_content)
    
    run_command("sudo mv /tmp/xvfb.service /etc/systemd/system/xvfb.service")
    
    # Service aktivieren
    run_command("sudo systemctl daemon-reload")
    run_command("sudo systemctl enable xvfb")
    run_command("sudo systemctl start xvfb")

    print("=== Xvfb läuft auf DISPLAY :99 ===")
    print("Chromium Version:")
    
    stdout, _ = run_command("chromium --version", ignore_errors=True)
    if stdout.strip():
        print(stdout.strip())
    else:
        print("Chromium nicht gefunden")

    print("=== Setup abgeschlossen ===")
    print("=== Altes VNC-Setup wurde entfernt ===")

if __name__ == "__main__":
    main()
