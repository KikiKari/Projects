#!/usr/bin/env python3
# collect_ist_gateway_b.sh — portiert nach python
# Quelle: shell, OpenClaw@gateway2:scripts/collect_ist_gateway_b.sh
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

import os
import sys
import subprocess
import json
import shutil
from datetime import datetime
from pathlib import Path
import urllib.request
import urllib.error

def run_command(command, shell=False, capture_output=True, text=True):
    """Helper function to run shell commands"""
    try:
        if shell:
            result = subprocess.run(command, shell=True, capture_output=capture_output, text=text)
        else:
            result = subprocess.run(command, capture_output=capture_output, text=text)
        return result.stdout.strip() if capture_output else ""
    except (subprocess.CalledProcessError, FileNotFoundError):
        return ""

def get_public_ip():
    """Get public IP address"""
    try:
        with urllib.request.urlopen('https://ifconfig.me', timeout=4) as response:
            return response.read().decode('utf-8').strip()
    except Exception:
        return "(nicht ermittelt)"

def get_tailscale_ip():
    """Get Tailscale IP address"""
    try:
        result = subprocess.run(['tailscale', 'ip', '-4'], capture_output=True, text=True, timeout=10)
        if result.returncode == 0:
            return result.stdout.strip().split('\n')[0]
        else:
            return "(nicht ermittelt)"
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return "(nicht ermittelt)"

def get_os_pretty_name():
    """Get OS pretty name from /etc/os-release"""
    try:
        with open('/etc/os-release', 'r') as f:
            for line in f:
                if line.startswith('PRETTY_NAME='):
                    return line.split('=', 1)[1].strip().strip('"')
    except FileNotFoundError:
        pass
    return ""

def check_file_exists(filepath):
    """Check if file exists and return appropriate string"""
    return "vorhanden" if os.path.exists(filepath) else "fehlt"

def main():
    # Set variables
    BASE_DIR = os.path.expanduser("~/.openclaw")
    OUT_DIR = os.path.join(BASE_DIR, "workspace/vscode")
    NOW_UTC = datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")
    NOW_LOCAL = datetime.now().strftime("%Y-%m-%d %H:%M:%S %Z")
    TS = datetime.now().strftime("%Y%m%d-%H%M%S")

    # Create output directory
    os.makedirs(OUT_DIR, exist_ok=True)

    # File paths
    IST_FILE = os.path.join(OUT_DIR, "IST-ZUSTAND_GATEWAY-B_NODE7.md")
    INV_FILE = os.path.join(OUT_DIR, "ARTEFAKT-INVENTAR_GATEWAY-B_NODE7.md")
    CFG_FILE = os.path.join(OUT_DIR, "OPENCLAW-CONFIG-SNAPSHOT_GATEWAY-B_NODE7.md")
    ENV_FILE = os.path.join(OUT_DIR, "ENV-STATUS_GATEWAY-B_NODE7.md")
    RUN_FILE = os.path.join(OUT_DIR, f"RUN-{TS}.md")

    OPENCLAW_JSON = os.path.join(BASE_DIR, "openclaw.json")
    ENV_DOT = os.path.join(BASE_DIR, ".env")
    ENV_SYSTEMD = os.path.join(BASE_DIR, "gateway.systemd.env")
    VSCODE_DIR = os.path.join(BASE_DIR, ".vscode")

    # System information
    HOSTNAME_FQDN = run_command(["hostname", "-f"]) or run_command(["hostname"])
    HOSTNAME_SHORT = run_command(["hostname"])
    ARCH = run_command(["uname", "-m"])
    KERNEL = run_command(["uname", "-r"])
    OS_PRETTY = get_os_pretty_name()
    IPV4_ALL = run_command(["hostname", "-I"]).strip()
    PUBLIC_IP = get_public_ip()
    TAILSCALE_IP = get_tailscale_ip()
    
    try:
        OPENCLAW_VER = run_command(["openclaw", "--version"])
    except FileNotFoundError:
        OPENCLAW_VER = "(nicht ermittelt)"
        
    try:
        NODE_VER = run_command(["node", "-v"])
    except FileNotFoundError:
        NODE_VER = "(nicht ermittelt)"

    # Fill in defaults if empty
    if not PUBLIC_IP:
        PUBLIC_IP = "(nicht ermittelt)"
    if not TAILSCALE_IP:
        TAILSCALE_IP = "(nicht ermittelt)"
    if not OPENCLAW_VER:
        OPENCLAW_VER = "(nicht ermittelt)"
    if not NODE_VER:
        NODE_VER = "(nicht ermittelt)"

    # Write IST file
    with open(IST_FILE, 'w') as f:
        f.write(f"""# IST-Zustand: Gateway B / Node 7

Stand (lokal): {NOW_LOCAL}  
Stand (UTC): {NOW_UTC}

## 1) Identität & System

- Gateway: **B**
- Node: **7**
- Hostname (short): `{HOSTNAME_SHORT}`
- Hostname (FQDN): `{HOSTNAME_FQDN}`
- Architektur: `{ARCH}`
- Kernel: `{KERNEL}`
- OS: `{OS_PRETTY}`
- IPv4 (lokal): `{IPV4_ALL}`
- Public IPv4: `{PUBLIC_IP}`
- Tailscale IPv4: `{TAILSCALE_IP}`
- OpenClaw Version: `{OPENCLAW_VER}`
- Node.js Version: `{NODE_VER}`

## 2) Arbeitsverzeichnisse

- Basis: `{BASE_DIR}`
- Funktionell VSCode: `{VSCODE_DIR}`
- Workspace Doku: `{OUT_DIR}`

## 3) Kernartefakte (Existenz)

- `{OPENCLAW_JSON}`: {check_file_exists(OPENCLAW_JSON)}
- `{ENV_DOT}`: {check_file_exists(ENV_DOT)}
- `{ENV_SYSTEMD}`: {check_file_exists(ENV_SYSTEMD)}
- `{os.path.join(BASE_DIR, "plugins/installs.json")}`: {check_file_exists(os.path.join(BASE_DIR, "plugins/installs.json"))}
- `{os.path.join(BASE_DIR, "plugin-skills")}`: {check_file_exists(os.path.join(BASE_DIR, "plugin-skills"))}

## 4) Hinweis

Diese Datei wird bei jedem Lauf neu geschrieben.
Zusätzlich wird ein Laufprotokoll als `RUN-*.md` erzeugt.
""")

    # Write inventory file
    with open(INV_FILE, 'w') as f:
        f.write(f"""# Artefakt-Inventar: Gateway B / Node 7

Stand: {NOW_LOCAL}

## Top-Level in ~/.openclaw

```
""")
        try:
            for item in sorted(os.listdir(BASE_DIR)):
                f.write(f"{item}\n")
        except FileNotFoundError:
            pass
        f.write("""```

## ~/.openclaw/.vscode

```
""")
        if os.path.exists(VSCODE_DIR):
            try:
                for item in sorted(os.listdir(VSCODE_DIR)):
                    item_path = os.path.join(VSCODE_DIR, item)
                    stat = os.stat(item_path)
                    f.write(f"{'d' if os.path.isdir(item_path) else '-'} {stat.st_size:>8} {item}\n")
            except FileNotFoundError:
                f.write("(nicht vorhanden)")
        else:
            f.write("(nicht vorhanden)")
        f.write("""```

## plugin-skills/

```
""")
        plugin_skills_dir = os.path.join(BASE_DIR, "plugin-skills")
        if os.path.exists(plugin_skills_dir):
            try:
                for item in sorted(os.listdir(plugin_skills_dir)):
                    f.write(f"{item}\n")
            except FileNotFoundError:
                f.write("(nicht vorhanden)")
        else:
            f.write("(nicht vorhanden)")
        f.write("""```

## openclaw.json Backups

```
""")
        try:
            backup_files = [f for f in os.listdir(BASE_DIR) if f.startswith("openclaw.json.bak")]
            if backup_files:
                for bf in sorted(backup_files):
                    f.write(f"{bf}\n")
            else:
                f.write("(keine gefunden)")
        except FileNotFoundError:
            f.write("(keine gefunden)")
        f.write("```\n")

    # Write config snapshot file
    with open(CFG_FILE, 'w') as f:
        f.write(f"""# OpenClaw Config Snapshot: Gateway B / Node 7

Stand: {NOW_LOCAL}

## Schlüsselpositionen (grep)

```
""")
        if os.path.exists(OPENCLAW_JSON):
            try:
                with open(OPENCLAW_JSON, 'r') as json_file:
                    lines = json_file.readlines()
                    for i, line in enumerate(lines, 1):
                        if any(key in line for key in ['"gateway"', '"session"', '"dmScope"', '"auth"', '"secrets"', '"tools"', '"plugins"', '"profile"', '"alsoAllow"', '"denyCommands"']):
                            f.write(f"{i}: {line}")
            except Exception:
                pass
        else:
            f.write("openclaw.json fehlt")
        f.write("""```

## Ausschnitt gateway/session/auth (ungefiltert, betriebsnah)

```json
""")
        if os.path.exists(OPENCLAW_JSON):
            try:
                with open(OPENCLAW_JSON, 'r') as json_file:
                    lines = json_file.readlines()
                    for line in lines[579:780]:  # 580-780 lines (0-indexed)
                        f.write(line)
            except Exception:
                f.write("{ \"error\": \"Fehler beim Lesen der Datei\" }\n")
        else:
            f.write("{ \"error\": \"openclaw.json fehlt\" }\n")
        f.write("```\n")

    # Write ENV status file
    with open(ENV_FILE, 'w') as f:
        f.write(f"""# ENV-Status: Gateway B / Node 7

Stand: {NOW_LOCAL}

## Dateien

```
""")
        env_files = [ENV_DOT, ENV_SYSTEMD]
        for ef in env_files:
            if os.path.exists(ef):
                stat = os.stat(ef)
                f.write(f"{'d' if os.path.isdir(ef) else '-'} {stat.st_size:>8} {ef}\n")
        f.write("""```

## .env (vollständig, ungefiltert)

```dotenv
""")
        if os.path.exists(ENV_DOT):
            try:
                with open(ENV_DOT, 'r') as env_file:
                    f.write(env_file.read())
            except Exception:
                f.write("# Fehler beim Lesen der Datei")
        else:
            f.write("# .env fehlt")
        f.write("""```

## gateway.systemd.env (vollständig, ungefiltert)

```dotenv
""")
        if os.path.exists(ENV_SYSTEMD):
            try:
                with open(ENV_SYSTEMD, 'r') as env_file:
                    f.write(env_file.read())
            except Exception:
                f.write("# Fehler beim Lesen der Datei")
        else:
            f.write("# gateway.systemd.env fehlt")
        f.write("```\n")

    # Write run file
    script_path = os.path.realpath(__file__)
    with open(RUN_FILE, 'w') as f:
        f.write(f"""# Laufprotokoll Gateway B / Node 7

- Zeit (lokal): {NOW_LOCAL}
- Zeit (UTC): {NOW_UTC}
- Script: {script_path}

## Erzeugte Dateien

- {os.path.basename(IST_FILE)}
- {os.path.basename(INV_FILE)}
- {os.path.basename(CFG_FILE)}
- {os.path.basename(ENV_FILE)}

""")

    # Print success message
    print("OK: IST-Zustand erfasst.")
    print(f"Ausgabeordner: {OUT_DIR}")
    print("Dateien:")
    try:
        for item in sorted(os.listdir(OUT_DIR)):
            print(f"- {item}")
    except FileNotFoundError:
        pass

if __name__ == "__main__":
    main()
