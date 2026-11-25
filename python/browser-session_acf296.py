#!/usr/bin/env python3
# abstraction-provenance: {"artifact_sha256": "2289f473dbd0e4ff5d2fbcd7898bce45b0fb309d6dbd7bb054aba941be72250b", "source_sha256": "acf29634657ddc4b0dd7488e70f24c496bf7bd82883eecf4ebbed3a1486457cd", "target_language": "python"}
# browser-session.mjs — portiert nach python
# Quelle: javascript, Onboarding@main:scripts/browser-session.mjs
# Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py

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
import asyncio
import os
import sys
from pathlib import Path
from playwright.async_api import async_playwright

REPO = Path(__file__).parent.parent
PROFILE = Path(os.environ.get("BROWSER_PROFILE_DIR", REPO / ".browser-profile"))
CHROME_PATHS = ["/usr/bin/google-chrome-stable", "/usr/bin/google-chrome"]
CHROME = next((p for p in CHROME_PATHS if Path(p).exists()), None)

def parse_args():
    """Parse command line arguments and flags."""
    args = sys.argv[1:]
    cmd = args[0] if len(args) > 0 else None
    target = args[1] if len(args) > 1 else None
    rest = args[2:] if len(args) > 2 else []
    
    def get_flag(name, default=None):
        try:
            idx = rest.index(f"--{name}")
            return rest[idx + 1] if idx + 1 < len(rest) else default
        except ValueError:
            return default
    
    def has_flag(name):
        return f"--{name}" in rest
    
    return cmd, target, rest, get_flag, has_flag

def load_env():
    """Lade .env Datei für Login-Credentials (nichts wird geloggt)."""
    env_file = REPO / ".env"
    if not env_file.exists():
        return {}
    
    env_vars = {}
    with open(env_file, 'r') as f:
        for line in f:
            line = line.strip()
            if line and '=' in line:
                match = line.split('=', 1)
                if len(match) == 2:
                    key, value = match
                    # Entferne optionale Anführungszeichen
                    if value.startswith('"') and value.endswith('"'):
                        value = value[1:-1]
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
            pass  # weiter
    
    # Generische Consent-IDs
    selectors = [
        "#onetrust-accept-btn-handler",
        "[aria-label*='accept' i]",
        "button[title*='accept' i]"
    ]
    
    for selector in selectors:
        try:
            el = page.locator(selector).first
            if await el.is_visible(timeout=500):
                await el.click(timeout=1500)
                return selector
        except:
            pass  # weiter
    
    return None

async def main():
    cmd, target, rest, get_flag, has_flag = parse_args()
    
    # Erstelle Profil-Verzeichnis
    PROFILE.mkdir(parents=True, exist_ok=True)
    
    # Sandbox-Egress läuft über den Agent-Proxy (MITM mit CA in /root/.ccr).
    # Chrome muss den Proxy nutzen; die CA ist zuvor via certutil in ~/.pki/nssdb
    # importiert (siehe docs/VISUAL_QA.md), damit TLS ohne Fehler verifiziert.
    # --socks <server>: leitet den Browser über einen SOCKS5-Proxy (z. B. den
    # Tailscale-Userspace-Proxy localhost:1055) — sauberer Egress am Agent-MITM-
    # Proxy vorbei, nötig für github.com/Codespaces. Sonst der Agent-HTTPS-Proxy.
    socks = get_flag("socks")
    proxy_server = (
        f"socks5://{socks}" if socks 
        else os.environ.get("HTTPS_PROXY", os.environ.get("https_proxy"))
    )
    
    async with async_playwright() as p:
        context = await p.chromium.launch_persistent_context(
            str(PROFILE),
            headless=False,
            executable_path=CHROME,
            viewport={"width": 1440, "height": 900},
            accept_downloads=True,
            # --insecure: akzeptiert das re-signierte Zertifikat des eigenen Agent-MITM-
            # Proxys (z. B. HSTS-Hosts wie github.com, wo der NSS-Trust im persistenten
            # Kontext nicht greift). Nur für den bekannten Sandbox-Proxy gedacht.
            ignore_https_errors=has_flag("insecure"),
            # Playwright verwaltet den Proxy zuverlässiger als das rohe --proxy-server-Arg;
            # bypass für loopback (Dev-Server) und interne Hosts.
            proxy={
                "server": proxy_server,
                "bypass": "localhost,127.0.0.1,::1"
            } if proxy_server else None,
            args=[
                "--no-sandbox",
                "--autoplay-policy=no-user-gesture-required",
                "--disable-blink-features=AutomationControlled",
                # Der Agent-MITM-Proxy resettet TLS-1.3-Handshakes (Chrome/BoringSSL) —
                # TLS 1.2 max lässt den re-terminierten Tunnel durch. curl/OpenSSL wäre
                # nicht betroffen, Chrome schon. Ohne das: ERR_CONNECTION_RESET extern.
                *(["--ssl-version-max=tls1.2"] if proxy_server else [])
            ]
        )
        
        page = context.pages[0] if context.pages else await context.new_page()
        
        try:
            if cmd == "state":
                cookies = await context.cookies()
                domains = sorted(set(c['domain'] for c in cookies))
                print(f"Profil: {PROFILE}")
                print(f"{len(cookies)} Cookies über {len(domains)} Domains:")
                for domain in domains:
                    print(f"  {domain}")
            
            elif cmd in ("open", "shot"):
                if not target:
                    raise Exception("URL fehlt")
                
                await page.goto(target, wait_until="domcontentloaded", timeout=60000)
                await page.wait_for_timeout(int(get_flag("wait", "2500")))
                accepted = await accept_cookies(page)
                if accepted:
                    print(f"Cookie-Consent bestätigt via: {accepted}")
                await page.wait_for_timeout(1000)
                
                out = get_flag("out", f"/tmp/browser-{int(asyncio.get_event_loop().time() * 1000)}.png")
                await page.screenshot(path=out, full_page=has_flag("full"))
                print(f"Screenshot: {out}")
                print(f"URL final: {page.url}")
            
            elif cmd == "login":
                if not target:
                    raise Exception("URL fehlt")
                
                env = load_env()
                user = env.get(get_flag("env-user", ""), get_flag("user", ""))
                pass_val = env.get(get_flag("env-pass", ""), get_flag("pass", ""))
                
                await page.goto(target, wait_until="domcontentloaded", timeout=60000)
                await page.wait_for_timeout(2500)
                await accept_cookies(page)
                
                if user:
                    uf = get_flag("user-field", "input[type=email], input[name=email], input[name=username], input[id*=email i]")
                    await page.locator(uf).first.fill(user, timeout=8000)
                
                if pass_val:
                    pf = get_flag("pass-field", "input[type=password]")
                    await page.locator(pf).first.fill(pass_val, timeout=8000)
                
                out = get_flag("out", f"/tmp/login-{int(asyncio.get_event_loop().time() * 1000)}.png")
                await page.screenshot(path=out)
                print(f"Login-Formular ausgefüllt (user={'gesetzt' if user else '-'}, pass={'gesetzt' if pass_val else '-'}) Screenshot: {out}")
                print("Absenden bewusst NICHT automatisch — nächster Schritt nach Sichtprüfung.")
            
            else:
                print("Befehle: open <URL> | shot <URL> | login <URL> | state")
        
        finally:
            await context.close()  # Profil (Cookies) bleibt auf Platte erhalten

if __name__ == "__main__":
    asyncio.run(main())
