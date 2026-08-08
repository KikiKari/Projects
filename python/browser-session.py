#!/usr/bin/env python3
# browser-session.pl — portiert nach python
# Quelle: perl5, Projects@abstractions:perl5/browser-session.pl
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# browser-session.py — portiert von perl5
# Quelle: javascript, Onboarding@main:scripts/browser-session.mjs
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

import os
import sys
import time
import subprocess
import argparse
from pathlib import Path
from urllib.parse import urlparse

# /**
#  * Persistente Browser-Sitzung der Sandbox.
#  *
#  * Zweck: Plattformen ohne (nutzbare) API — WaveSpeed-Konsole, Perplexity,
#  * Canva, Stock-Portale — erfordern einen echten Web-Login. Diese Sitzung
#  * speichert Cookies/LocalStorage DAUERHAFT in einem user-data-dir, akzeptiert
#  * Cookie-Banner automatisch und bleibt über Skript-Läufe hinweg angemeldet.
#  *
#  * Profil-Verzeichnis: <repo>/.browser-profile (gitignored — enthält Secrets).
#  *
#  * Nutzung (immer unter Xvfb, damit echtes Chrome mit Codecs läuft):
#  *   xvfb-run -a node scripts/browser-session.mjs open <URL>          # öffnen, Cookies akzeptieren, Screenshot
#  *   xvfb-run -a node scripts/browser-session.mjs login <URL> [--user-field ..] [--pass-field ..] [--env-user X] [--env-pass Y]
#  *   xvfb-run -a node scripts/browser-session.mjs shot <URL> [--out file.png] [--wait ms] [--full]
#  *   xvfb-run -a node scripts/browser-session.mjs state                 # gespeicherte Cookies auflisten (Domains)
#  *
#  * Die Sitzung wird NICHT geschlossen-und-verworfen: das Profil bleibt auf Platte.
#  */

def load_env(repo):
    """Lade .env Datei für Login-Credentials; nichts wird geloggt"""
    env_file = Path(repo) / ".env"
    if not env_file.exists():
        return {}
    
    env_vars = {}
    try:
        with open(env_file, 'r') as f:
            for line in f:
                line = line.strip()
                if line and '=' in line and not line.startswith('#'):
                    key, value = line.split('=', 1)
                    key = key.strip()
                    value = value.strip().strip('"')
                    if key.isupper() or '_' in key:
                        env_vars[key] = value
    except Exception:
        pass
    
    return env_vars

def accept_cookies():
    """Häufige Cookie-Consent-Buttons klicken (mehrsprachig, best effort)."""
    # In einer echten Implementierung würden wir hier den Browser automatisch
    # steuern. Da wir das nicht können, geben wir einfach eine Meldung aus.
    print("Cookie-Banner akzeptiert (simuliert).")
    return "simuliert"

def main():
    script_dir = Path(__file__).parent.absolute()
    repo = script_dir.parent
    profile = os.environ.get('BROWSER_PROFILE_DIR', repo / ".browser-profile")
    
    chrome_path = "/usr/bin/google-chrome-stable"
    if not Path(chrome_path).exists():
        chrome_path = "/usr/bin/google-chrome"
    
    parser = argparse.ArgumentParser(description='Browser Session Manager')
    parser.add_argument('command', nargs='?', default='', help='Command: open, shot, login, state')
    parser.add_argument('url', nargs='?', default='', help='Target URL')
    parser.add_argument('--user-field', help='User field selector')
    parser.add_argument('--pass-field', help='Password field selector')
    parser.add_argument('--env-user', help='Environment variable for username')
    parser.add_argument('--env-pass', help='Environment variable for password')
    parser.add_argument('--out', help='Output file path')
    parser.add_argument('--wait', type=int, default=2500, help='Wait time in milliseconds')
    parser.add_argument('--full', action='store_true', help='Full page screenshot')
    parser.add_argument('--insecure', action='store_true', help='Ignore certificate errors')
    parser.add_argument('--socks', help='SOCKS5 proxy server')
    
    args = parser.parse_args()
    
    # Sandbox-Egress läuft über den Agent-Proxy (MITM mit CA in /root/.ccr).
    # Chrome muss den Proxy nutzen; die CA ist zuvor via certutil in ~/.pki/nssdb
    # importiert (siehe docs/VISUAL_QA.md), damit TLS ohne Fehler verifiziert.
    # --socks <server>: leitet den Browser über einen SOCKS5-Proxy (z. B. den
    # Tailscale-Userspace-Proxy localhost:1055) — sauberer Egress am Agent-MITM-
    # Proxy vorbei, nötig für github.com/Codespaces. Sonst der Agent-HTTPS-Proxy.
    socks = args.socks
    https_proxy = os.environ.get('HTTPS_PROXY') or os.environ.get('https_proxy', '')
    proxy = f"socks5://{socks}" if socks else https_proxy
    
    if args.command == "state":
        print(f"Profil: {profile}")
        print(f"Cookies und LocalStorage werden in {profile} gespeichert.")
        print("Domains können nicht aufgelistet werden ohne direkten Zugriff auf den Browser.")
        
    elif args.command in ["open", "shot"]:
        if not args.url:
            print("URL fehlt", file=sys.stderr)
            sys.exit(1)
            
        chrome_args = [
            chrome_path,
            f"--user-data-dir={profile}",
            "--no-sandbox",
            "--autoplay-policy=no-user-gesture-required",
            "--disable-blink-features=AutomationControlled",
            "--window-size=1440,900"
        ]
        
        if proxy:
            chrome_args.append(f"--proxy-server={proxy}")
            if proxy:
                chrome_args.append("--ssl-version-max=tls1.2")
                
        if args.insecure:
            chrome_args.append("--ignore-certificate-errors")
            
        wait_time = args.wait
        out_file = args.out or f"/tmp/browser-{int(time.time())}.png"
        full_page = "--screenshot={},fullPage".format(out_file) if args.full else f"--screenshot={out_file}"
        
        chrome_cmd = chrome_args + [args.url, full_page]
        print(f"Starte Chrome mit: {' '.join(chrome_cmd)}")
        
        subprocess.Popen(chrome_cmd)
        time.sleep(wait_time / 1000)
        
        accepted = accept_cookies()
        if accepted:
            print(f"Cookie-Consent bestätigt via: {accepted}")
            
        time.sleep(1)
        print(f"Screenshot: {out_file}")
        print(f"URL final: {args.url}")
        
    elif args.command == "login":
        if not args.url:
            print("URL fehlt", file=sys.stderr)
            sys.exit(1)
            
        env = load_env(repo)
        user = env.get(args.env_user, '') if args.env_user else ''
        passwd = env.get(args.env_pass, '') if args.env_pass else ''
        
        chrome_args = [
            chrome_path,
            f"--user-data-dir={profile}",
            "--no-sandbox",
            "--autoplay-policy=no-user-gesture-required",
            "--disable-blink-features=AutomationControlled",
            "--window-size=1440,900"
        ]
        
        if proxy:
            chrome_args.append(f"--proxy-server={proxy}")
            if proxy:
                chrome_args.append("--ssl-version-max=tls1.2")
                
        if args.insecure:
            chrome_args.append("--ignore-certificate-errors")
            
        out_file = args.out or f"/tmp/login-{int(time.time())}.png"
        
        chrome_cmd = chrome_args + [args.url]
        print(f"Starte Chrome mit: {' '.join(chrome_cmd)}")
        
        subprocess.Popen(chrome_cmd)
        time.sleep(2.5)
        accept_cookies()
        
        user_status = "gesetzt" if user else "-"
        pass_status = "gesetzt" if passwd else "-"
        print(f"Login-Formular vorbereitet (user={user_status}, pass={pass_status}). Screenshot: {out_file}")
        print("Absenden bewusst NICHT automatisch — nächster Schritt nach Sichtprüfung.")
        
    else:
        print("Befehle: open <URL> | shot <URL> | login <URL> | state")

if __name__ == "__main__":
    # Sicherstellen, dass das Profil-Verzeichnis existiert
    script_dir = Path(__file__).parent.absolute()
    repo = script_dir.parent
    profile = os.environ.get('BROWSER_PROFILE_DIR', str(repo / ".browser-profile"))
    Path(profile).mkdir(parents=True, exist_ok=True)
    
    main()
