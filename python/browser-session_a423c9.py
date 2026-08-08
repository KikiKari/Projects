#!/usr/bin/env python3
# browser-session.ps1 — portiert nach python
# Quelle: powershell, Projects@abstractions:powershell/browser-session.ps1
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# browser-session.py — portiert von powershell
# Quelle: powershell, browser-session.ps1
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

"""
.SYNOPSIS
Persistente Browser-Sitzung der Sandbox.

.DESCRIPTION
Zweck: Plattformen ohne (nutzbare) API — WaveSpeed-Konsole, Perplexity,
Canva, Stock-Portale — erfordern einen echten Web-Login. Diese Sitzung
speichert Cookies/LocalStorage DAUERHAFT in einem user-data-dir, akzeptiert
Cookie-Banner automatisch und bleibt über Skript-Läufe hinweg angemeldet.

Profil-Verzeichnis: <repo>/.browser-profile (gitignored — enthält Secrets).

Nutzung (immer unter Xvfb, damit echtes Chrome mit Codecs läuft):
  xvfb-run -a python3 browser-session.py open <URL>          # öffnen, Cookies akzeptieren, Screenshot
  xvfb-run -a python3 browser-session.py login <URL> [--user-field ..] [--pass-field ..] [--env-user X] [--env-pass Y]
  xvfb-run -a python3 browser-session.py shot <URL> [--out file.png] [--wait ms] [--full]
  xvfb-run -a python3 browser-session.py state                 # gespeicherte Cookies auflisten (Domains)

Die Sitzung wird NICHT geschlossen-und-verworfen: das Profil bleibt auf Platte.
"""

import argparse
import asyncio
import os
import re
import sys
import time
from pathlib import Path
from urllib.parse import urlparse

from playwright.async_api import async_playwright


def get_flag_value(args, name, default=None):
    """Hilfsfunktion für Parameterverarbeitung"""
    flag_name = f"--{name}"
    if flag_name in args.rest:
        idx = args.rest.index(flag_name)
        if idx + 1 < len(args.rest):
            return args.rest[idx + 1]
    return default


def has_flag(args, name):
    """Prüft ob ein Flag gesetzt ist"""
    return f"--{name}" in args.rest


def load_env(repo_path):
    """Umgebungsvariablen laden"""
    env_path = Path(repo_path) / ".env"
    env_vars = {}
    if env_path.exists():
        with open(env_path, 'r') as f:
            for line in f:
                match = re.match(r'^\s*([A-Z0-9_]+)\s*=\s*"?([^"]*)"?$', line.strip())
                if match:
                    env_vars[match.group(1)] = match.group(2)
    return env_vars


async def accept_cookies(page):
    """Cookie Consent akzeptieren"""
    labels = [
        "Accept all", "Accept All", "Alle akzeptieren", "Accept all cookies",
        "Alle Cookies akzeptieren", "I agree", "Ich stimme zu", "Zustimmen",
        "Allow all", "Akzeptieren", "Accept", "Got it", "Agree"
    ]
    
    for name in labels:
        try:
            btn = await page.get_by_role("button", name=name).first
            if await btn.is_visible(timeout=800):
                await btn.click(timeout=1500)
                return name
        except Exception:
            pass
    
    # Generische Consent-IDs
    selectors = ["#onetrust-accept-btn-handler", "[aria-label*='accept' i]", "button[title*='accept' i]"]
    for sel in selectors:
        try:
            el = await page.query_selector(sel)
            if el and await el.is_visible(timeout=500):
                await el.click(timeout=1500)
                return sel
        except Exception:
            pass
    return None


async def main():
    parser = argparse.ArgumentParser(description="Browser Session Manager")
    parser.add_argument("cmd", nargs="?", help="Befehl: open, shot, login, state")
    parser.add_argument("target", nargs="?", help="Ziel URL")
    parser.add_argument("rest", nargs="*", help="Zusätzliche Parameter")
    
    args = parser.parse_args()
    
    # Pfad-Konfiguration
    script_path = Path(__file__).resolve()
    repo = script_path.parent.parent
    profile_dir = os.environ.get("BROWSER_PROFILE_DIR", str(repo / ".browser-profile"))
    chrome_paths = ["/usr/bin/google-chrome-stable", "/usr/bin/google-chrome"]
    chrome_executable = next((p for p in chrome_paths if Path(p).exists()), None)
    
    # Profil-Verzeichnis erstellen
    Path(profile_dir).mkdir(parents=True, exist_ok=True)
    
    # Proxy-Konfiguration
    socks = get_flag_value(args, "socks")
    if socks:
        proxy_url = f"socks5://{socks}"
    else:
        proxy_url = os.environ.get("HTTPS_PROXY") or os.environ.get("https_proxy")
    
    # Browser-Kontext starten
    browser_args = [
        "--no-sandbox",
        "--autoplay-policy=no-user-gesture-required",
        "--disable-blink-features=AutomationControlled"
    ]
    
    if proxy_url:
        browser_args.append("--ssl-version-max=tls1.2")
    
    async with async_playwright() as p:
        browser = await p.chromium.launch_persistent_context(
            user_data_dir=profile_dir,
            headless=False,
            executable_path=chrome_executable,
            viewport={"width": 1440, "height": 900},
            accept_downloads=True,
            ignore_https_errors=has_flag(args, "insecure"),
            proxy={"server": proxy_url} if proxy_url else None,
            args=browser_args
        )
        
        page = browser.pages[0] if browser.pages else await browser.new_page()
        
        try:
            if args.cmd == "state":
                cookies = await browser.cookies()
                domains = sorted(list(set(c['domain'] for c in cookies)))
                print(f"Profil: {profile_dir}")
                print(f"{len(cookies)} Cookies über {len(domains)} Domains:")
                for domain in domains:
                    print(f"  {domain}")
            
            elif args.cmd in ["open", "shot"]:
                if not args.target:
                    raise ValueError("URL fehlt")
                
                await page.goto(args.target, wait_until="domcontentloaded", timeout=60000)
                wait_time = int(get_flag_value(args, "wait", "2500"))
                await asyncio.sleep(wait_time / 1000)
                accepted = await accept_cookies(page)
                if accepted:
                    print(f"Cookie-Consent bestätigt via: {accepted}")
                await asyncio.sleep(1)
                
                out_file = get_flag_value(args, "out", f"/tmp/browser-{int(time.time()*1000000)}.png")
                full_page = has_flag(args, "full")
                await page.screenshot(path=out_file, full_page=full_page)
                print(f"Screenshot: {out_file}")
                print(f"URL final: {page.url}")
            
            elif args.cmd == "login":
                if not args.target:
                    raise ValueError("URL fehlt")
                
                env_vars = load_env(repo)
                user = env_vars.get(get_flag_value(args, "env-user", ""), get_flag_value(args, "user", ""))
                password = env_vars.get(get_flag_value(args, "env-pass", ""), get_flag_value(args, "pass", ""))
                
                await page.goto(args.target, wait_until="domcontentloaded", timeout=60000)
                await asyncio.sleep(2.5)
                await accept_cookies(page)
                
                if user:
                    uf = get_flag_value(args, "user-field", "input[type=email], input[name=email], input[name=username], input[id*=email i]")
                    user_field = await page.query_selector(uf)
                    if user_field:
                        await user_field.fill(user, timeout=8000)
                
                if password:
                    pf = get_flag_value(args, "pass-field", "input[type=password]")
                    pass_field = await page.query_selector(pf)
                    if pass_field:
                        await pass_field.fill(password, timeout=8000)
                
                out_file = get_flag_value(args, "out", f"/tmp/login-{int(time.time()*1000000)}.png")
                await page.screenshot(path=out_file)
                user_set = "gesetzt" if user else "-"
                pass_set = "gesetzt" if password else "-"
                print(f"Login-Formular ausgefüllt (user={user_set}, pass={pass_set}). Screenshot: {out_file}")
                print("Absenden bewusst NICHT automatisch — nächster Schritt nach Sichtprüfung.")
            
            else:
                print("Befehle: open <URL> | shot <URL> | login <URL> | state")
        
        finally:
            await browser.close()  # Profil (Cookies) bleibt auf Platte erhalten


if __name__ == "__main__":
    asyncio.run(main())
