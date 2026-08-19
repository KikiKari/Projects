#!/usr/bin/env python3
# sandbox-vpn.sh — portiert nach python
# Quelle: shell, Onboarding@main:scripts/sandbox-vpn.sh
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

# Bringt die Sandbox reproduzierbar in das Tailscale-Tailnet des Nutzers —
# als Brücke am Agent-MITM-Proxy vorbei (sauberer Egress via SOCKS5) und mit
# Tailscale-SSH, damit die eigenen Geräte des Nutzers in die Sandbox kommen.
#
# Nutzt den WIEDERVERWENDBAREN Auth-Key aus der .env (nichts committet).
# userspace-networking: verändert NICHT die Host-Routen/den Agent-Proxy dieser
# Session; stellt einen SOCKS5-Proxy auf localhost:1055 bereit.
#
# Aufruf: scripts/sandbox-vpn.sh   (idempotent; No-op ohne Auth-Key/tailscale)

import os
import sys
import subprocess
import time
import re

def log(message):
    print(f'[sandbox-vpn] {message}')

def read_auth_key():
    """Liest den Auth-Key aus .env (ohne die gesamte .env zu sourcen)"""
    if not os.path.isfile('.env'):
        return ""
    
    with open('.env', 'r') as f:
        for line in f:
            match = re.match(r'^TAILSCALE_AUTH_KEY="(.*)"', line.strip())
            if match:
                return match.group(1)
    return ""

def command_exists(command):
    """Prüft ob ein Kommando existiert"""
    return subprocess.call(['which', command], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL) == 0

def main():
    # Arbeitsverzeichnis wechseln
    script_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(os.path.join(script_dir, '..'))
    
    # Auth-Key aus .env lesen
    key = read_auth_key()
    if not key:
        log("kein TAILSCALE_AUTH_KEY in .env — überspringe VPN")
        sys.exit(0)
    
    # Tailscale installieren, falls nicht vorhanden
    if not command_exists('tailscale'):
        log("installiere Tailscale …")
        try:
            subprocess.run(['curl', '-fsSL', 'https://tailscale.com/install.sh'], check=True, stdout=subprocess.DEVNULL)
            subprocess.run(['sh'], input='', capture_output=True, text=True)
        except subprocess.CalledProcessError:
            log("WARNUNG: Tailscale-Install fehlgeschlagen")
            sys.exit(0)
    
    # tailscaled im userspace-Modus starten
    try:
        subprocess.run(['tailscale', 'status'], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except subprocess.CalledProcessError:
        log("starte tailscaled (userspace, SOCKS5 localhost:1055) …")
        os.makedirs('/var/lib/tailscale', exist_ok=True)
        
        # Start tailscaled daemon
        with open('/tmp/tailscaled.log', 'w') as logfile:
            subprocess.Popen([
                'tailscaled',
                '--tun=userspace-networking',
                '--socks5-server=localhost:1055',
                '--outbound-http-proxy-listen=localhost:1056',
                '--statedir=/var/lib/tailscale'
            ], stdout=logfile, stderr=logfile)
        
        time.sleep(4)
    
    # Ins Tailnet, mit Tailscale-SSH aktiviert
    try:
        result = subprocess.run(['tailscale', 'status'], capture_output=True, text=True, check=True)
        if 'claude-sandbox' not in result.stdout:
            log("tailscale up (hostname=claude-sandbox, --ssh) …")
            subprocess.run([
                'tailscale', 'up',
                f'--authkey={key}',
                '--hostname=claude-sandbox',
                '--ssh',
                '--accept-routes'
            ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
        else:
            subprocess.run(['tailscale', 'set', '--ssh'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except subprocess.CalledProcessError:
        log("WARNUNG: tailscale up fehlgeschlagen")
    
    # Status anzeigen
    try:
        subprocess.run(['tailscale', 'status'], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        result = subprocess.run(['tailscale', 'ip', '-4'], capture_output=True, text=True)
        ip = result.stdout.strip().split('\n')[0] if result.stdout.strip() else "?"
        log(f"im Tailnet: claude-sandbox {ip} · SSH aktiv · SOCKS5 localhost:1055")
    except subprocess.CalledProcessError:
        pass
    
    sys.exit(0)

if __name__ == '__main__':
    main()
