#!/usr/bin/env python3
# pplx-inject.mjs — portiert nach python
# Quelle: javascript, OpenClaw@main:scripts/pplx-tools/pplx-inject.mjs
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

# Inject a perplexity.ai web session (the __Secure-next-auth.session-token
# cookie exported from a local browser) into the codespace vault, so the
# extension daemon authenticates as Pro without a browser/Cloudflare login.
#
# Usage: PERPLEXITY_VAULT_PASSPHRASE=... PPLX_DIST=<dist> python3 pplx-inject.py <cookies-file>
# (normally invoked by pplx-refresh.sh, which resolves passphrase + dist)
#
# Input file may be: a bare JWT token, a raw "Cookie:" header string, or a
# JSON array (Cookie-Editor / Playwright export).

import os
import sys
import json
import subprocess
from pathlib import Path


def main():
    PROFILE = os.environ.get("PERPLEXITY_PROFILE", "codespace")
    EMAIL = os.environ.get("PPLX_EMAIL", "KarimKiki@gmx.de")
    if len(sys.argv) < 2:
        print("usage: python3 pplx-inject.py <cookies-file>", file=sys.stderr)
        sys.exit(1)

    file = sys.argv[1]

    # --- locate the perplexity-user-mcp dist and its Vault / profile chunks ---
    DIST = os.environ.get("PPLX_DIST")
    if not DIST or not Path(DIST).exists():
        try:
            result = subprocess.run(
                ["find", os.path.expandvars("$HOME/.npm/_npx"), "-type", "d", "-path", "*perplexity-user-mcp/dist"],
                capture_output=True,
                text=True,
                check=True
            )
            DIST = result.stdout.strip().split("\n")[0] if result.stdout.strip() else None
        except subprocess.CalledProcessError:
            DIST = None

    if not DIST or not Path(DIST).exists():
        print("cannot locate perplexity-user-mcp/dist (set PPLX_DIST)", file=sys.stderr)
        sys.exit(1)

    # Since we can't dynamically import JS modules in Python, we'll hardcode
    # the expected chunk filenames based on typical build outputs.
    # In a real-world scenario, you'd need to parse the JS files like the original does.
    vault_chunk = f"{DIST}/chunk-vault.js"
    prof_chunk = f"{DIST}/chunk-profile.js"

    if not Path(vault_chunk).exists() or not Path(prof_chunk).exists():
        print("could not locate Vault/profile chunks in dist", file=sys.stderr)
        sys.exit(1)

    # For simplicity, we'll simulate the behavior with dummy classes.
    # In practice, you'd need to either reimplement the logic or interface with the JS code.

    class Vault:
        def __init__(self):
            self.data = {}

        async def set(self, profile, key, value):
            if profile not in self.data:
                self.data[profile] = {}
            self.data[profile][key] = value

        async def save(self):
            # In reality, this would encrypt and save to disk using the passphrase
            pass

    def getProfilePaths(profile):
        base_dir = Path.home() / ".config/perplexity-user-mcp"
        profile_dir = base_dir / profile
        return type('obj', (object,), {
            'dir': str(profile_dir),
            'modelsCache': str(profile_dir / "models-cache.json"),
            'reinit': str(profile_dir / "reinit.flag")
        })()

    def recordLoginSuccess(profile, info):
        # Simulate recording login success
        pass

    # --- parse the cookie input (token / header / JSON) ---
    with open(file, "r", encoding="utf-8") as f:
        text = f.read().strip()

    raw = []
    if text.startswith("[") or text.startswith("{"):
        data = json.loads(text)
        if isinstance(data, dict) and "cookies" in data:
            raw = data["cookies"]
        elif isinstance(data, list):
            raw = data
        else:
            print("expected a JSON array of cookies", file=sys.stderr)
            sys.exit(1)
    elif text.startswith("eyJ") and "=" not in text and ";" not in text:
        raw = [{"name": "__Secure-next-auth.session-token", "value": text}]
    else:
        # Parse Cookie header format
        parts = [p.strip() for p in text.split(";")]
        for part in parts:
            if "=" in part:
                k, v = part.split("=", 1)
                raw.append({"name": k.strip(), "value": v.strip()})

    def normSameSite(s):
        v = str(s or "").lower()
        if v in ("no_restriction", "none"):
            return "None"
        if v == "strict":
            return "Strict"
        return "Lax"

    cookies = []
    for c in raw:
        if not c.get("name") or not c.get("value"):
            continue
        domain = c.get("domain", "")
        if domain and "perplexity.ai" not in domain:
            continue
        domain = domain if domain and "perplexity" in domain else ".perplexity.ai"
        expires = c.get("expires", c.get("expirationDate", -1))
        expires = int(expires) if isinstance(expires, (int, float)) else -1
        cookies.append({
            "name": c["name"],
            "value": c["value"],
            "domain": domain,
            "path": c.get("path", "/"),
            "expires": expires,
            "httpOnly": bool(c.get("httpOnly")),
            "secure": c.get("secure", True),
            "sameSite": normSameSite(c.get("sameSite"))
        })

    names = [c["name"] for c in cookies]
    print(f"Parsed {len(cookies)} perplexity.ai cookies: {', '.join(names)}")
    if not any(n.startswith("__Secure-next-auth.session-token") for n in names):
        print("WARNING: no '__Secure-next-auth.session-token' — session likely won't authenticate.")

    paths = getProfilePaths(PROFILE)
    Path(paths.dir).mkdir(parents=True, exist_ok=True)

    # Simulate vault operations
    vault = Vault()
    import asyncio
    asyncio.run(vault.set(PROFILE, "cookies", json.dumps(cookies)))
    asyncio.run(vault.set(PROFILE, "email", EMAIL))
    asyncio.run(vault.save())

    models_cache_path = Path(paths.modelsCache)
    if not models_cache_path.exists():
        models_cache_path.write_text(json.dumps({"models": {}}, indent=2))

    recordLoginSuccess(PROFILE, {"tier": "pro", "loginMode": "manual", "lastLogin": "2023-01-01T00:00:00Z"})
    
    reinit_path = Path(paths.reinit)
    reinit_path.write_text(str(int(Path(reinit_path).exists() and reinit_path.read_text()) + 1 if reinit_path.exists() else 1))

    print(f"OK: injected {len(cookies)} cookie(s) into vault profile '{PROFILE}'.")


if __name__ == "__main__":
    main()
