#!/usr/bin/env python3
# browser-session.mjs — portiert nach python
# Quelle: javascript, Onboarding@main:scripts/browser-session.mjs
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

"""
Persistente Browser-Sitzung der Sandbox.

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
import os
import sys
import time
import argparse
from pathlib import Path
import asyncio
from playwright.async_api import async_playwright

# Konstanten
REPO = Path(__file__).parent.parent
PROFILE = Path(os.environ.get("BROWSER_PROFILE_DIR", REPO / ".browser-profile"))
CHROME_PATHS = ["/usr/bin/google-chrome-stable", "/usr/bin/google-chrome"]
CHROME = next((p for p in CHROME_PATHS if Path(p).exists()), None)

def load_env():
    """Lade .env Datei (nur für login-Credentials; nichts wird geloggt)"""
    env_file = REPO / ".env"
    if not env_file.exists():
        return {}
    
    env_vars = {}
    with open(env_file, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith("#"):
                match = line.split("=", 1)
                if len(match) == 2:
                    key, value = match
                    key = key.strip()
                    value = value.strip().strip('"')
                    env_vars[key] = value
    return env_vars

async def accept_cookies(page):
    """Häufige Cookie-Consent-Buttons klicken (mehrsprachig, best effort)."""
    labels = [
        "Accept all", "Accept All", "Alle akzeptieren", "Accept all cookies",
        "Alle Cookies akzeptieren", "I agree", "Ich stimme zu", "Zustimmen",
        "Allow all", "Akzeptieren", "Accept", "Got it", "Agree",
    ]
    
    for name in labels:
        try:
            btn = page.get_by_role("button", name=name, exact=False).first
            if await btn.is_visible(timeout=800):
                await btn.click(timeout=1500)
                return name
        except:
            pass
    
    # Generische Consent-IDs
    selectors = ["#onetrust-accept-btn-handler", "[aria-label*='accept' i]", "button[title*='accept' i]"]
    for sel in selectors:
        try:
            el = page.locator(sel).first
            if await el.is_visible(timeout=500):
                await el.click(timeout=1500)
                return sel
        except:
            pass
    
    return None

def parse_args():
    parser = argparse.ArgumentParser(description="Browser Session Manager")
    parser.add_argument("command", choices=["open", "shot", "login", "state"], help="Befehl")
    parser.add_argument("url", nargs="?", help="Ziel-URL")
    parser.add_argument("--user-field", default="input[type=email], input[name=email], input[name=username], input[id*=email i]", help="CSS-Selektor für Benutzerfeld")
    parser.add_argument("--pass-field", default="input[type=password]", help="CSS-Selektor für Passwortfeld")
    parser.add_argument("--env-user", default="", help="Umgebungsvariable für Benutzername")
    parser.add_argument("--env-pass", default="", help="Umgebungsvariable für Passwort")
    parser.add_argument("--user", default="", help="Benutzername")
    parser.add_argument("--pass", dest="password", default="", help="Passwort")
    parser.add_argument("--out", help="Ausgabedatei für Screenshot")
    parser.add_argument("--wait", type=int, default=2500, help="Wartezeit in ms")
    parser.add_argument("--full", action="store_true", help="Vollständiger Screenshot")
    parser.add_argument("--socks", help="SOCKS5 Proxy Server")
    parser.add_argument("--insecure", action="store_true", help="Ignoriere HTTPS Fehler")
    
    return parser.parse_args()

async def main():
    args = parse_args()
    
    # Erstelle Profil-Verzeichnis
    PROFILE.mkdir(parents=True, exist_ok=True)
    
    # Proxy-Konfiguration
    socks = args.socks
    proxy_server = None
    if socks:
        proxy_server = f"socks5://{socks}"
    else:
        proxy_server = os.environ.get("HTTPS_PROXY") or os.environ.get("https_proxy")
    
    # Starte Playwright
    async with async_playwright() as p:
        # Starte den Browser mit persistentem Kontext
        context = await p.chromium.launch_persistent_context(
            str(PROFILE),
            headless=False,
            executable_path=CHROME,
            viewport={"width": 1440, "height": 900},
            accept_downloads=True,
            ignore_https_errors=args.insecure,
            proxy={"server": proxy_server, "bypass": "localhost,127.0.0.1,::1"} if proxy_server else None,
            args=[
                "--no-sandbox",
                "--autoplay-policy=no-user-gesture-required",
                "--disable-blink-features=AutomationControlled",
                "--ssl-version-max=tls1.2"
            ] if proxy_server else [
                "--no-sandbox",
                "--autoplay-policy=no-user-gesture-required",
                "--disable-blink-features=AutomationControlled"
            ]
        )
        
        try:
            page = context.pages[0] if context.pages else await context.new_page()
            
            if args.command == "state":
                cookies = await context.cookies()
                domains = sorted(list(set(cookie["domain"] for cookie in cookies)))
                print(f"Profil: {PROFILE}")
                print(f"{len(cookies)} Cookies über {len(domains)} Domains:")
                for domain in domains:
                    print(f"  {domain}")
            
            elif args.command in ["open", "shot"]:
                if not args.url:
                    raise ValueError("URL fehlt")
                
                await page.goto(args.url, wait_until="domcontentloaded", timeout=60000)
                await page.wait_for_timeout(args.wait)
                
                accepted = await accept_cookies(page)
                if accepted:
                    print(f"Cookie-Consent bestätigt via: {accepted}")
                
                await page.wait_for_timeout(1000)
                
                out_file = args.out or f"/tmp/browser-{int(time.time() * 1000)}.png"
                await page.screenshot(path=out_file, full_page=args.full)
                print(f"Screenshot: {out_file}")
                print(f"URL final: {page.url}")
            
            elif args.command == "login":
                if not args.url:
                    raise ValueError("URL fehlt")
                
                env = load_env()
                user = env.get(args.env_user, args.user)
                password = env.get(args.env_pass, args.password)
                
                await page.goto(args.url, wait_until="domcontentloaded", timeout=60000)
                await page.wait_for_timeout(2500)
                await accept_cookies(page)
                
                if user:
                    await page.locator(args.user_field).first.fill(user, timeout=8000)
                
                if password:
                    await page.locator(args.pass_field).first.fill(password, timeout=8000)
                
                out_file = args.out or f"/tmp/login-{int(time.time() * 1000)}.png"
                await page.screenshot(path=out_file)
                print(f"Login-Formular ausgefüllt (user={'gesetzt' if user else '-'}, pass={'gesetzt' if password else '-'}). Screenshot: {out_file}")
                print("Absenden bewusst NICHT automatisch — nächster Schritt nach Sichtprüfung.")
            
            else:
                print("Befehle: open <URL> | shot <URL> | login <URL> | state")
        
        finally:
            await context.close()  # Profil (Cookies) bleibt auf Platte erhalten

if __name__ == "__main__":
    asyncio.run(main())
