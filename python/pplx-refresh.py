#!/usr/bin/env python3
# pplx-refresh.sh — portiert nach python
# Quelle: shell, OpenClaw@main:scripts/pplx-tools/pplx-refresh.sh
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

# Refresh the codespace Perplexity session from a locally-exported cookie.
#
# Usage:
#   ./pplx-refresh.py [cookie-file]
#
# cookie-file defaults to ~/pplx-cookies.txt. Put your local browser's
# __Secure-next-auth.session-token value (raw), or the whole Cookie header,
# or a JSON cookie export, into that file first.
#
# Steps: ensure daemon browser -> read daemon passphrase -> inject into vault
#        -> trigger reinit -> verify authenticated.

import os
import sys
import json
import subprocess
import time
from pathlib import Path

def main():
    here = Path(__file__).parent.resolve()
    cfg = Path(os.environ.get("PERPLEXITY_CONFIG_DIR", Path.home() / ".perplexity-mcp"))
    profile = os.environ.get("PERPLEXITY_PROFILE", "codespace")
    cookie_file = Path(sys.argv[1]) if len(sys.argv) > 1 else Path.home() / "pplx-cookies.txt"

    if not cookie_file.exists() or cookie_file.stat().st_size == 0:
        print(f"✗ Cookie file empty/missing: {cookie_file}")
        print("  Export __Secure-next-auth.session-token from your local browser")
        print("  (DevTools → Application → Cookies → www.perplexity.ai) into that file.")
        sys.exit(1)

    # 1. ensure the extension daemon has a usable browser (idempotent)
    subprocess.run([here / "pplx-setup.sh"], check=True)

    # 2. daemon pid + vault passphrase (never guessed — read from the live daemon)
    lock = cfg / "daemon.lock"
    if not lock.exists():
        print(f"✗ no daemon.lock at {lock} — is the extension running?")
        sys.exit(1)

    with open(lock) as f:
        pid = json.load(f)["pid"]

    try:
        subprocess.check_output(["ps", "-p", str(pid)], stderr=subprocess.STDOUT)
    except subprocess.CalledProcessError:
        print(f"✗ daemon pid {pid} not running")
        sys.exit(1)

    with open(f"/proc/{pid}/environ", "rb") as f:
        env_vars = f.read().decode("utf-8", errors="replace").split("\x00")

    passphrase = None
    for var in env_vars:
        if var.startswith("PERPLEXITY_VAULT_PASSPHRASE="):
            passphrase = var.split("=", 1)[1]
            break

    if not passphrase:
        print("✗ no PERPLEXITY_VAULT_PASSPHRASE in daemon env")
        sys.exit(1)

    # 3. locate the perplexity-user-mcp dist (populate npx cache if needed)
    dist = None
    npx_dirs = Path.home() / ".npm/_npx"
    if npx_dirs.exists():
        for path in npx_dirs.rglob("*perplexity-user-mcp/dist"):
            if path.is_dir():
                dist = path
                break

    if not dist:
        try:
            subprocess.run(
                ["npx", "-y", "perplexity-user-mcp", "--version"],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                check=True
            )
        except subprocess.CalledProcessError:
            pass

        if npx_dirs.exists():
            for path in npx_dirs.rglob("*perplexity-user-mcp/dist"):
                if path.is_dir():
                    dist = path
                    break

    # 4. inject
    env = os.environ.copy()
    env.update({
        "PERPLEXITY_VAULT_PASSPHRASE": passphrase,
        "PERPLEXITY_CONFIG_DIR": str(cfg),
        "PERPLEXITY_PROFILE": profile,
        "PPLX_DIST": str(dist) if dist else ""
    })
    subprocess.run(
        ["node", str(here / "pplx-inject.mjs"), str(cookie_file)],
        check=True,
        env=env
    )

    # 5. trigger daemon reinit
    reinit_file = cfg / "profiles" / profile / ".reinit"
    reinit_file.parent.mkdir(parents=True, exist_ok=True)
    reinit_file.write_text(str(int(time.time())))
    print("→ reinit triggered, waiting for daemon...")

    # 6. verify
    stat_file = cfg / "profiles" / profile / "daemon-status.json"
    for _ in range(20):
        time.sleep(1.5)
        try:
            with open(stat_file) as f:
                status = json.load(f)
                auth = status.get("authenticated")
                tier = status.get("tier")
                if auth is True:
                    print(f"✅ authenticated — tier: {tier}")
                    return
        except (FileNotFoundError, json.JSONDecodeError, KeyError):
            continue

    print(f"⚠️  not authenticated yet. Check: tail -20 {cfg / 'daemon.log'}")
    sys.exit(1)

if __name__ == "__main__":
    main()
