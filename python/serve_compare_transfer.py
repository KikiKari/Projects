#!/usr/bin/env python3
# serve_compare_transfer.sh — portiert nach python
# Quelle: shell, OpenClaw@gateway1:scripts/serve_compare_transfer.sh
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

import os
import sys
import subprocess
import http.server
import socketserver
from pathlib import Path

COMPARE_DIR = "/home/openclaw/.openclaw/workspace/vscode/compare"
TRANSFER_DIR = "/home/openclaw/.openclaw/workspace/vscode/compare/transfer"
HOST_IP = "152.53.145.65"
PORT = 80
SELF_PATH = os.path.realpath(__file__)

def get_files():
    """Get all files in COMPARE_DIR except this script, sorted alphabetically"""
    compare_path = Path(COMPARE_DIR)
    files = []
    
    if compare_path.exists() and compare_path.is_dir():
        for item in compare_path.iterdir():
            if item.is_file() and item != Path(SELF_PATH):
                files.append(str(item))
    
    return sorted(files)

def main():
    files = get_files()
    
    if not files:
        print(f"Keine Dateien in {COMPARE_DIR} gefunden.")
        sys.exit(1)
    
    print()
    print(f"Bereitgestellte Dateien aus {COMPARE_DIR}:")
    for src in files:
        print(f"- {os.path.basename(src)}")
    
    print()
    print(f"Copy/Paste auf anderem Gateway (Download nach {TRANSFER_DIR}):")
    for src in files:
        file = os.path.basename(src)
        print(f"curl -fL --retry 3 --connect-timeout 10 -o {TRANSFER_DIR}/{file} http://{HOST_IP}:{PORT}/{file}")
    
    print()
    print(f"Server auf Port {PORT} aktiv. Beenden mit STRG+C.")
    print()
    
    # Change to compare directory and start HTTP server
    os.chdir(COMPARE_DIR)
    
    handler = http.server.SimpleHTTPRequestHandler
    with socketserver.TCPServer(("0.0.0.0", PORT), handler) as httpd:
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nServer gestoppt.")
            sys.exit(0)

if __name__ == "__main__":
    main()
