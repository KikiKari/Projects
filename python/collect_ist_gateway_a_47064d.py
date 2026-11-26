#!/usr/bin/env python3
# abstraction-provenance: {"artifact_sha256": "accfa65a3cf0847dc4c5b63866a53add460d49bf8693f803f33eb87a2672337c", "source_sha256": "47064dbc7b32c01d57d42222f8cc3ac7caf9c8d82b98029dc5fc6ecb0d32f2c9", "target_language": "python"}
# collect_ist_gateway_a.sh — portiert nach python
# Quelle: shell, OpenClaw@gateway1:scripts/collect_ist_gateway_a.sh
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import os
import subprocess
import json
import urllib.request
from datetime import datetime
import socket

def run_command(command, shell=False):
    try:
        result = subprocess.run(command, shell=shell, capture_output=True, text=True, check=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError:
        return None
    except Exception:
        return None

def get_public_ip():
    try:
        with urllib.request.urlopen('http://ifconfig.me', timeout=4) as response:
            return response.read().decode().strip()
    except Exception:
        return None

def get_tailscale_ip():
    try:
        result = subprocess.run(['tailscale', 'ip', '-4'], capture_output=True, text=True, check=True)
        return result.stdout.strip().split('\n')[0]
    except Exception:
        return None

def main():
    # Environment variables
    HOME = os.environ.get('HOME', '')
    BASE_DIR = f"{HOME}/.openclaw"
    OUT_DIR = f"{BASE_DIR}/workspace/vscode"
    
    # Create output directory
    os.makedirs(OUT_DIR, exist_ok=True)
    
    # Timestamps
    NOW_UTC = datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")
    NOW_LOCAL = datetime.now().strftime("%Y-%m-%d %H:%M:%S %Z")
    TS = datetime.now().strftime("%Y%m%d-%H%M%S")
    
    # File paths
    IST_FILE = f"{OUT_DIR}/IST-ZUSTAND_GATEWAY-A_NODE1.md"
    INV_FILE = f"{OUT_DIR}/ARTEFAKT-INVENTAR_GATEWAY-A_NODE1.md"
    CFG_FILE = f"{OUT_DIR}/OPENCLAW-CONFIG-SNAPSHOT_GATEWAY-A_NODE1.md"
    ENV_FILE = f"{OUT_DIR}/ENV-STATUS_GATEWAY-A_NODE1.md"
    RUN_FILE = f"{OUT_DIR}/RUN-{TS}.md"
    
    OPENCLAW_JSON = f"{BASE_DIR}/openclaw.json"
    ENV_DOT = f"{BASE_DIR}/.env"
    ENV_SYSTEMD = f"{BASE_DIR}/gateway.systemd.env"
    VSCODE_DIR = f"{BASE_DIR}/.vscode"
    
    # System information
    HOSTNAME_FQDN = run_command(['hostname', '-f']) or socket.gethostname()
    HOSTNAME_SHORT = socket.gethostname()
    ARCH = run_command(['uname', '-m'])
    KERNEL = run_command(['uname', '-r'])
    
    OS_PRETTY = ""
    try:
        with open('/etc/os-release', 'r') as f:
            for line in f:
                if line.startswith('PRETTY_NAME='):
                    OS_PRETTY = line.split('=', 1)[1].strip().strip('"')
                    break
    except FileNotFoundError:
        pass
    
    IPV4_ALL = run_command(['hostname', '-I'])
    PUBLIC_IP = get_public_ip()
    TAILSCALE_IP = get_tailscale_ip()
    OPENCLAW_VER = run_command(['openclaw', '--version'])
    NODE_VER = run_command(['node', '-v'])
    
    # Handle empty values
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
        f.write(f"""# IST-Zustand: Gateway A / Node 1

Stand (lokal): {NOW_LOCAL}  
Stand (UTC): {NOW_UTC}

## 1) Identitaet & System

- Gateway: **A**
- Node: **1**
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

- `{OPENCLAW_JSON}`: {"vorhanden" if os.path.isfile(OPENCLAW_JSON) else "fehlt"}
- `{ENV_DOT}`: {"vorhanden" if os.path.isfile(ENV_DOT) else "fehlt"}
- `{ENV_SYSTEMD}`: {"vorhanden" if os.path.isfile(ENV_SYSTEMD) else "fehlt"}
- `{BASE_DIR}/plugins/installs.json`: {"vorhanden" if os.path.isfile(f"{BASE_DIR}/plugins/installs.json") else "fehlt"}
- `{BASE_DIR}/plugin-skills`: {"vorhanden" if os.path.isdir(f"{BASE_DIR}/plugin-skills") else "fehlt"}
""")
    
    # Write inventory file
    with open(INV_FILE, 'w') as f:
        f.write(f"""# Artefakt-Inventar: Gateway A / Node 1

Stand: {NOW_LOCAL}

## Top-Level in ~/.openclaw

```text
""")
        try:
            for item in sorted(os.listdir(BASE_DIR)):
                f.write(f"{item}\n")
        except Exception:
            pass
        f.write("""```

## ~/.openclaw/.vscode

```text
""")
        if os.path.isdir(VSCODE_DIR):
            try:
                for item in sorted(os.listdir(VSCODE_DIR)):
                    item_path = os.path.join(VSCODE_DIR, item)
                    stat_info = os.stat(item_path)
                    mode = stat_info.st_mode
                    is_dir = 'd' if os.path.isdir(item_path) else '-'
                    f.write(f"{is_dir} {item}\n")
            except Exception:
                f.write("(Fehler beim Lesen)\n")
        else:
            f.write("(nicht vorhanden)\n")
        f.write("""```

## plugin-skills/

```text
""")
        plugin_skills_dir = f"{BASE_DIR}/plugin-skills"
        if os.path.isdir(plugin_skills_dir):
            try:
                for item in sorted(os.listdir(plugin_skills_dir)):
                    f.write(f"{item}\n")
            except Exception:
                f.write("(Fehler beim Lesen)\n")
        else:
            f.write("(nicht vorhanden)\n")
        f.write("""```

## openclaw.json Backups

```text
""")
        try:
            backup_files = [f for f in os.listdir(BASE_DIR) if f.startswith('openclaw.json.bak')]
            if backup_files:
                for bf in sorted(backup_files):
                    f.write(f"{bf}\n")
            else:
                f.write("(keine gefunden)\n")
        except Exception:
            f.write("(keine gefunden)\n")
        f.write("```\n")
    
    # Write config snapshot file
    with open(CFG_FILE, 'w') as f:
        f.write(f"""# OpenClaw Config Snapshot: Gateway A / Node 1

Stand: {NOW_LOCAL}

## Schluesselpositionen (grep)

```text
""")
        if os.path.isfile(OPENCLAW_JSON):
            try:
                with open(OPENCLAW_JSON, 'r') as json_file:
                    lines = json_file.readlines()
                    for i, line in enumerate(lines, 1):
                        if any(key in line for key in ['"gateway"', '"session"', '"dmScope"', '"auth"', '"secrets"', '"tools"', '"plugins"', '"profile"', '"alsoAllow"', '"denyCommands"']):
                            f.write(f"{i}: {line}")
            except Exception:
                pass
        else:
            f.write("openclaw.json fehlt\n")
        f.write("""```

## Ausschnitt gateway/session/auth

```json
""")
        if os.path.isfile(OPENCLAW_JSON):
            try:
                with open(OPENCLAW_JSON, 'r') as json_file:
                    lines = json_file.readlines()
                    # Get lines 580-780 (using 0-based indexing)
                    start_line = max(0, 580-1)
                    end_line = min(len(lines), 780)
                    for i in range(start_line, end_line):
                        if i < len(lines):
                            f.write(lines[i])
            except Exception:
                f.write('{{ "error": "Fehler beim Lesen" }}\n')
        else:
            f.write('{{ "error": "openclaw.json fehlt" }}\n')
        f.write("```\n")
    
    # Write env status file
    with open(ENV_FILE, 'w') as f:
        f.write(f"""# ENV-Status: Gateway A / Node 1

Stand: {NOW_LOCAL}

## Dateien

```text
""")
        env_files = [ENV_DOT, ENV_SYSTEMD]
        for env_file in env_files:
            if os.path.exists(env_file):
                try:
                    stat_info = os.stat(env_file)
                    mode = stat_info.st_mode
                    is_dir = 'd' if os.path.isdir(env_file) else '-'
                    f.write(f"{is_dir} {os.path.basename(env_file)}\n")
                except Exception:
                    pass
        f.write("""```

## .env (vollstaendig)

```dotenv
""")
        if os.path.isfile(ENV_DOT):
            try:
                with open(ENV_DOT, 'r') as env_file:
                    f.write(env_file.read())
            except Exception:
                f.write("# Fehler beim Lesen\n")
        else:
            f.write("# .env fehlt\n")
        f.write("""```

## gateway.systemd.env (vollstaendig)

```dotenv
""")
        if os.path.isfile(ENV_SYSTEMD):
            try:
                with open(ENV_SYSTEMD, 'r') as env_file:
                    f.write(env_file.read())
            except Exception:
                f.write("# Fehler beim Lesen\n")
        else:
            f.write("# gateway.systemd.env fehlt\n")
        f.write("```\n")
    
    # Write run file
    script_path = os.path.realpath(__file__)
    with open(RUN_FILE, 'w') as f:
        f.write(f"""# Laufprotokoll Gateway A / Node 1

- Zeit (lokal): {NOW_LOCAL}
- Zeit (UTC): {NOW_UTC}
- Script: {script_path}

## Erzeugte Dateien

- {os.path.basename(IST_FILE)}
- {os.path.basename(INV_FILE)}
- {os.path.basename(CFG_FILE)}
- {os.path.basename(ENV_FILE)}
""")
    
    print("OK: IST-Zustand erfasst.")
    try:
        for item in sorted(os.listdir(OUT_DIR)):
            print(f"- {item}")
    except Exception:
        pass

if __name__ == "__main__":
    main()
