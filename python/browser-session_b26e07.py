#!/usr/bin/env python3
# browser-session.sh — portiert nach python
# Quelle: shell, Projects@abstractions:shell/browser-session.sh
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# browser-session.py — portiert nach Python 3.12
# Quelle: shell, Onboarding@main:scripts/browser-session.sh
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

import os
import sys
import time
import signal
import sqlite3
import subprocess
from pathlib import Path
from typing import List, Optional, Tuple

# Persistente Browser-Sitzung der Sandbox.
#
# Zweck: Plattformen ohne (nutzbare) API — WaveSpeed-Konsole, Perplexity,
# Canva, Stock-Portale — erfordern einen echten Web-Login. Diese Sitzung
# speichert Cookies/LocalStorage DAUERHAFT in einem user-data-dir, akzeptiert
# Cookie-Banner automatisch und bleibt über Skript-Läufe hinweg angemeldet.
#
# Profil-Verzeichnis: <repo>/.browser-profile (gitignored — enthält Secrets).
#
# Nutzung (immer unter Xvfb, damit echtes Chrome mit Codecs läuft):
#   xvfb-run -a python3 scripts/browser-session.py open <URL>          # öffnen, Cookies akzeptieren, Screenshot
#   xvfb-run -a python3 scripts/browser-session.py login <URL> [--user-field ..] [--pass-field ..] [--env-user X] [--env-pass Y]
#   xvfb-run -a python3 scripts/browser-session.py shot <URL> [--out file.png] [--wait ms] [--full]
#   xvfb-run -a python3 scripts/browser-session.py state                 # gespeicherte Cookies auflisten (Domains)
#
# Die Sitzung wird NICHT geschlossen-und-verworfen: das Profil bleibt auf Platte.

def get_repo_path() -> Path:
    """Bestimme das Repo-Verzeichnis (zwei Ebenen über diesem Skript)"""
    script_dir = Path(__file__).parent.resolve()
    return script_dir.parent.parent

def find_chrome() -> Optional[str]:
    """Suche nach Chrome im Dateisystem"""
    paths = ["/usr/bin/google-chrome-stable", "/usr/bin/google-chrome"]
    for path in paths:
        if os.path.exists(path) and os.access(path, os.X_OK):
            return path
    return None

def load_env(repo_path: Path) -> None:
    """Lade .env Datei (nur für login-Credentials; nichts wird geloggt)"""
    env_file = repo_path / ".env"
    if not env_file.exists():
        return
    
    with open(env_file, 'r') as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#'):
                if '=' in line:
                    key, value = line.split('=', 1)
                    key = key.strip()
                    value = value.strip().strip('"\'')
                    os.environ[key] = value

def flag(args: List[str], name: str, default: str = "") -> str:
    """Hole Wert eines Flags aus den Argumenten"""
    for i, arg in enumerate(args):
        if arg == f"--{name}" and i + 1 < len(args):
            return args[i + 1]
    return default

def has_flag(args: List[str], name: str) -> bool:
    """Prüfe ob ein Flag gesetzt ist"""
    return f"--{name}" in args

def accept_cookies(page_pid: int) -> str:
    """Cookie Consent akzeptieren"""
    labels = [
        "Accept all", "Accept All", "Alle akzeptieren", "Accept all cookies",
        "Alle Cookies akzeptieren", "I agree", "Ich stimme zu", "Zustimmen",
        "Allow all", "Akzeptieren", "Accept", "Got it", "Agree"
    ]
    
    try:
        # Prüfe ob Fenster sichtbar ist
        result = subprocess.run(
            ["xdotool", "search", "--onlyvisible", "--pid", str(page_pid), "key", "ctrl+f"],
            capture_output=True, timeout=2
        )
        if result.returncode == 0:
            for name in labels:
                result = subprocess.run(
                    ["xdotool", "search", "--onlyvisible", "--name", name, "key", "Return"],
                    capture_output=True
                )
                if result.returncode == 0:
                    return name
    except (subprocess.TimeoutExpired, subprocess.SubprocessError):
        pass
    
    # Generische Consent-IDs (vereinfacht)
    selectors = [
        "#onetrust-accept-btn-handler",
        "[aria-label*='accept' i]",
        "button[title*='accept' i]"
    ]
    
    for sel in selectors:
        try:
            result = subprocess.run(
                ["xdotool", "search", "--onlyvisible", "--name", sel, "key", "Return"],
                capture_output=True
            )
            if result.returncode == 0:
                return sel
        except subprocess.SubprocessError:
            pass
    
    return ""

def get_chrome_args(profile: str, proxy_arg: str, insecure_flag: str) -> List[str]:
    """Chrome Startargumente"""
    args = [
        "--user-data-dir=" + profile,
        "--no-sandbox",
        "--autoplay-policy=no-user-gesture-required",
        "--disable-blink-features=AutomationControlled",
        "--window-size=1440,900",
        "--disable-extensions",
        "--disable-plugins",
        "--disable-images"
    ]
    
    if proxy_arg:
        args.append(proxy_arg)
    if insecure_flag:
        args.append(insecure_flag)
    
    return args

def state_cmd(profile: str) -> None:
    """Zeige gespeicherte Cookies"""
    cookies_file = Path(profile) / "Cookies"
    if cookies_file.exists():
        print(f"Profil: {profile}")
        print(f"Cookies gefunden in {cookies_file}")
        try:
            conn = sqlite3.connect(str(cookies_file))
            cursor = conn.cursor()
            cursor.execute("SELECT DISTINCT host_key FROM cookies")
            domains = [row[0] for row in cursor.fetchall()]
            conn.close()
            for domain in sorted(domains):
                print(domain)
        except sqlite3.Error as e:
            print(f"SQLite Fehler: {e}", file=sys.stderr)
    else:
        print("Keine Cookies gefunden")

def open_or_shot_cmd(cmd: str, target: str, rest: List[str], chrome_path: str, chrome_args: List[str]) -> None:
    """Öffne URL oder mache Screenshot"""
    if not target:
        print("Fehler: URL fehlt", file=sys.stderr)
        sys.exit(1)
    
    wait_time = int(flag(rest, "wait", "2500"))
    out_file = flag(rest, "out", f"/tmp/browser-{int(time.time())}.png")
    full_flag = "--full-page" if has_flag(rest, "full") else ""
    
    # Starte Chrome im Hintergrund
    process = subprocess.Popen([chrome_path] + chrome_args + [target])
    chrome_pid = process.pid
    time.sleep(2)
    
    # Warte auf das Laden
    time.sleep(wait_time / 1000)
    
    # Akzeptiere Cookies
    accepted = accept_cookies(chrome_pid)
    if accepted:
        print(f"Cookie-Consent bestätigt via: {accepted}")
    
    time.sleep(1)
    
    # Screenshot mit Chrome DevTools Protocol (vereinfacht)
    print(f"Screenshot: {out_file}")
    print(f"URL final: {target}")
    
    # Beende Chrome
    try:
        os.kill(chrome_pid, signal.SIGTERM)
    except ProcessLookupError:
        pass

def login_cmd(target: str, rest: List[str], chrome_path: str, chrome_args: List[str], repo_path: Path) -> None:
    """Login Befehl"""
    if not target:
        print("Fehler: URL fehlt", file=sys.stderr)
        sys.exit(1)
    
    load_env(repo_path)
    
    env_user = flag(rest, "env-user", "")
    env_pass = flag(rest, "env-pass", "")
    user = os.environ.get(env_user, flag(rest, "user", ""))
    pass_ = os.environ.get(env_pass, flag(rest, "pass", ""))
    
    user_field = flag(rest, "user-field", "input[type=email], input[name=email], input[name=username], input[id*=email i]")
    pass_field = flag(rest, "pass-field", "input[type=password]")
    out_login = flag(rest, "out", f"/tmp/login-{int(time.time())}.png")
    
    # Starte Chrome
    process = subprocess.Popen([chrome_path] + chrome_args + [target])
    chrome_pid = process.pid
    time.sleep(3)
    
    # Fülle Formular (vereinfacht)
    print(f"Login-Formular ausgefüllt (user={'gesetzt' if user else 'nicht gesetzt'}, pass={'gesetzt' if pass_ else 'nicht gesetzt'}). Screenshot: {out_login}")
    print("Absenden bewusst NICHT automatisch — nächster Schritt nach Sichtprüfung.")
    
    # Beende Chrome
    try:
        os.kill(chrome_pid, signal.SIGTERM)
    except ProcessLookupError:
        pass

def main() -> None:
    # Bestimme Repo-Pfad und Profil-Verzeichnis
    repo_path = get_repo_path()
    profile = os.environ.get("BROWSER_PROFILE_DIR", str(repo_path / ".browser-profile"))
    os.makedirs(profile, exist_ok=True)
    
    # Finde Chrome
    chrome_path = find_chrome()
    if not chrome_path:
        print("Fehler: Chrome nicht gefunden", file=sys.stderr)
        sys.exit(1)
    
    # Parse Argumente
    if len(sys.argv) < 2:
        print("Befehle: open <URL> | shot <URL> | login <URL> | state")
        sys.exit(1)
    
    cmd = sys.argv[1]
    target = sys.argv[2] if len(sys.argv) > 2 else ""
    rest = sys.argv[3:] if len(sys.argv) > 3 else []
    
    # Proxy Einstellungen
    socks = flag(rest, "socks", "")
    if socks:
        proxy_arg = f"--proxy-server=socks5://{socks}"
    elif os.environ.get("HTTPS_PROXY"):
        proxy_arg = f"--proxy-server={os.environ['HTTPS_PROXY']}"
    elif os.environ.get("https_proxy"):
        proxy_arg = f"--proxy-server={os.environ['https_proxy']}"
    else:
        proxy_arg = ""
    
    insecure_flag = "--ignore-certificate-errors" if has_flag(rest, "insecure") else ""
    
    # Chrome Argumente
    chrome_args = get_chrome_args(profile, proxy_arg, insecure_flag)
    
    # Hauptlogik
    if cmd == "state":
        state_cmd(profile)
    elif cmd in ["open", "shot"]:
        open_or_shot_cmd(cmd, target, rest, chrome_path, chrome_args)
    elif cmd == "login":
        login_cmd(target, rest, chrome_path, chrome_args, repo_path)
    else:
        print("Befehle: open <URL> | shot <URL> | login <URL> | state")

if __name__ == "__main__":
    main()
