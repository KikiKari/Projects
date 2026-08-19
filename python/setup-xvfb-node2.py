#!/usr/bin/env python3
# setup-xvfb-node2.sh — portiert nach python
# Quelle: shell, OpenClaw@gateway1:scripts/setup-xvfb-node2.sh
# auch in: OpenClaw@gateway2:scripts/setup-xvfb-node2.sh
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

# Xvfb Setup für Node 2 (Netcup VPS)
# Erstellt: 2026-04-09

import subprocess
import sys
import os

def run_command(command, check=True):
    """Führt einen Shell-Befehl aus und gibt das Ergebnis zurück"""
    try:
        result = subprocess.run(command, shell=True, check=check, 
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE, 
                              text=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f"Fehler beim Ausführen von: {command}")
        print(f"stderr: {e.stderr}")
        if check:
            sys.exit(1)
        return None

def main():
    print("=== Xvfb + Chromium Setup für Node 2 ===")
    
    # Update & Install
    run_command("sudo apt-get update")
    packages = [
        "xvfb",
        "chromium-browser",
        "chromium-chromedriver",
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
    run_command(f"sudo apt-get install -y {' '.join(packages)}")
    
    # Xvfb Systemd Service erstellen
    xvfb_service_content = """[Unit]
Description=X Virtual Framebuffer
After=network.target

[Service]
Type=simple
User=openclaw
ExecStart=/usr/bin/Xvfb :99 -screen 0 1920x1080x24 -ac +extension GLX +render -noreset
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
"""
    
    with open("/tmp/xvfb.service", "w") as f:
        f.write(xvfb_service_content)
    
    run_command("sudo mv /tmp/xvfb.service /etc/systemd/system/xvfb.service")
    
    # Service aktivieren
    run_command("sudo systemctl daemon-reload")
    run_command("sudo systemctl enable xvfb")
    run_command("sudo systemctl start xvfb")
    
    print("=== Xvfb läuft auf DISPLAY :99 ===")
    print("Chromium Version:")
    
    try:
        version_output = run_command("chromium-browser --version", check=False)
        if version_output:
            print(version_output)
        else:
            print("Chromium nicht gefunden")
    except:
        print("Chromium nicht gefunden")
    
    print("=== Setup abgeschlossen ===")

if __name__ == "__main__":
    if os.geteuid() != 0:
        print("Dieses Skript sollte mit sudo ausgeführt werden")
        sys.exit(1)
    main()
