#!/usr/bin/env python3
# abstraction-provenance: {"artifact_sha256": "a38e8bc3ccda6572d47fa72bb86a71cd1c601409b30c3b7f26c6f6a6dd741a22", "source_sha256": "da890cc26fb848b78b6a85373d6cfa4e08f6e7c2002921e1c0247960b8b361d7", "target_language": "python"}
# collect_ist_gateway_b.sh — portiert nach python
# Quelle: shell, OpenClaw@gateway2:scripts/collect_ist_gateway_b.sh
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import os
import subprocess
import json
import urllib.request
from datetime import datetime
from pathlib import Path

def run_command(cmd):
    """Helper to run shell commands and return output"""
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, check=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError:
        return ""

def get_hostname():
    """Get hostname information"""
    try:
        fqdn = subprocess.run(["hostname", "-f"], capture_output=True, text=True, check=True)
        return fqdn.stdout.strip(), run_command("hostname")
    except subprocess.CalledProcessError:
        hostname = run_command("hostname")
        return hostname, hostname

def main():
    # Setup paths and directories
    BASE_DIR = Path(os.environ["HOME"]) / ".openclaw"
    OUT_DIR = BASE_DIR / "workspace" / "vscode"
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    # Timestamps
    NOW_UTC = datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")
    NOW_LOCAL = datetime.now().strftime("%Y-%m-%d %H:%M:%S %Z")
    TS = datetime.now().strftime("%Y%m%d-%H%M%S")

    # Output files
    IST_FILE = OUT_DIR / "IST-ZUSTAND_GATEWAY-B_NODE7.md"
    INV_FILE = OUT_DIR / "ARTEFAKT-INVENTAR_GATEWAY-B_NODE7.md"
    CFG_FILE = OUT_DIR / "OPENCLAW-CONFIG-SNAPSHOT_GATEWAY-B_NODE7.md"
    ENV_FILE = OUT_DIR / "ENV-STATUS_GATEWAY-B_NODE7.md"
    RUN_FILE = OUT_DIR / f"RUN-{TS}.md"

    # File paths
    OPENCLAW_JSON = BASE_DIR / "openclaw.json"
    ENV_DOT = BASE_DIR / ".env"
    ENV_SYSTEMD = BASE_DIR / "gateway.systemd.env"
    VSCODE_DIR = BASE_DIR / ".vscode"
    PLUGINS_INSTALLS = BASE_DIR / "plugins" / "installs.json"
    PLUGIN_SKILLS = BASE_DIR / "plugin-skills"

    # System information
    HOSTNAME_FQDN, HOSTNAME_SHORT = get_hostname()
    ARCH = run_command("uname -m")
    KERNEL = run_command("uname -r")
    
    # OS information
    OS_PRETTY = ""
    try:
        with open("/etc/os-release", "r") as f:
            for line in f:
                if line.startswith("PRETTY_NAME="):
                    OS_PRETTY = line.split("=", 1)[1].strip().strip('"')
                    break
    except FileNotFoundError:
        pass

    IPV4_ALL = run_command("hostname -I").strip()
    
    # Network information
    try:
        PUBLIC_IP = urllib.request.urlopen("http://ifconfig.me", timeout=4).read().decode().strip()
    except:
        PUBLIC_IP = "(nicht ermittelt)"
        
    try:
        TAILSCALE_IP = run_command("tailscale ip -4").split("\n")[0]
        if not TAILSCALE_IP:
            TAILSCALE_IP = "(nicht ermittelt)"
    except:
        TAILSCALE_IP = "(nicht ermittelt)"

    # Software versions
    try:
        OPENCLAW_VER = run_command("openclaw --version")
        if not OPENCLAW_VER:
            OPENCLAW_VER = "(nicht ermittelt)"
    except:
        OPENCLAW_VER = "(nicht ermittelt)"

    try:
        NODE_VER = run_command("node -v")
        if not NODE_VER:
            NODE_VER = "(nicht ermittelt)"
    except:
        NODE_VER = "(nicht ermittelt)"

    # Create IST file
    with open(IST_FILE, "w") as f:
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

- `{OPENCLAW_JSON}`: {"vorhanden" if OPENCLAW_JSON.exists() else "fehlt"}
- `{ENV_DOT}`: {"vorhanden" if ENV_DOT.exists() else "fehlt"}
- `{ENV_SYSTEMD}`: {"vorhanden" if ENV_SYSTEMD.exists() else "fehlt"}
- `{PLUGINS_INSTALLS}`: {"vorhanden" if PLUGINS_INSTALLS.exists() else "fehlt"}
- `{PLUGIN_SKILLS}`: {"vorhanden" if PLUGIN_SKILLS.exists() else "fehlt"}

## 4) Hinweis

Diese Datei wird bei jedem Lauf neu geschrieben.
Zusätzlich wird ein Laufprotokoll als `RUN-*.md` erzeugt.
""")

    # Create inventory file
    with open(INV_FILE, "w") as f:
        f.write(f"""# Artefakt-Inventar: Gateway B / Node 7

Stand: {NOW_LOCAL}

## Top-Level in ~/.openclaw

```
""")
        try:
            for item in BASE_DIR.iterdir():
                f.write(f"{item.name}\n")
        except:
            pass
        f.write("""```

## ~/.openclaw/.vscode

```
""")
        if VSCODE_DIR.exists():
            try:
                result = subprocess.run(["ls", "-la", str(VSCODE_DIR)], capture_output=True, text=True, check=True)
                f.write(result.stdout)
            except:
                pass
        else:
            f.write("(nicht vorhanden)")
        f.write("""```

## plugin-skills/

```
""")
        if PLUGIN_SKILLS.exists():
            try:
                result = subprocess.run(["ls", "-1", str(PLUGIN_SKILLS)], capture_output=True, text=True, check=True)
                f.write(result.stdout)
            except:
                pass
        else:
            f.write("(nicht vorhanden)")
        f.write("""```

## openclaw.json Backups

```
""")
        try:
            backup_files = list(BASE_DIR.glob("openclaw.json.bak*"))
            if backup_files:
                for bf in backup_files:
                    f.write(f"{bf.name}\n")
            else:
                f.write("(keine gefunden)")
        except:
            f.write("(keine gefunden)")
        f.write("""```
""")

    # Create config snapshot
    with open(CFG_FILE, "w") as f:
        f.write(f"""# OpenClaw Config Snapshot: Gateway B / Node 7

Stand: {NOW_LOCAL}

## Schlüsselpositionen (grep)

```
""")
        if OPENCLAW_JSON.exists():
            try:
                result = subprocess.run([
                    "grep", "-nE", 
                    '"gateway"|\"session\"|\"dmScope\"|\"auth\"|\"secrets\"|\"tools\"|\"plugins\"|\"profile\"|\"alsoAllow\"|\"denyCommands\"', 
                    str(OPENCLAW_JSON)
                ], capture_output=True, text=True)
                if result.stdout:
                    f.write(result.stdout)
            except:
                pass
        else:
            f.write("openclaw.json fehlt")
        f.write("""```

## Ausschnitt gateway/session/auth (ungefiltert, betriebsnah)

```json
""")
        if OPENCLAW_JSON.exists():
            try:
                with open(OPENCLAW_JSON, "r") as json_file:
                    lines = json_file.readlines()
                    # Get lines 580-780 (0-indexed would be 579-779)
                    start_idx = max(0, min(579, len(lines)-1))
                    end_idx = min(779, len(lines))
                    for i in range(start_idx, end_idx):
                        if i < len(lines):
                            f.write(lines[i])
            except:
                f.write('{ "error": "Fehler beim Lesen" }\n')
        else:
            f.write('{ "error": "openclaw.json fehlt" }\n')
        f.write("""```
""")

    # Create env status file
    with open(ENV_FILE, "w") as f:
        f.write(f"""# ENV-Status: Gateway B / Node 7

Stand: {NOW_LOCAL}

## Dateien

```
""")
        try:
            result = subprocess.run(["ls", "-la", str(ENV_DOT), str(ENV_SYSTEMD)], capture_output=True, text=True)
            f.write(result.stdout)
        except:
            pass
        f.write("""```

## .env (vollständig, ungefiltert)

```dotenv
""")
        if ENV_DOT.exists():
            try:
                with open(ENV_DOT, "r") as env_file:
                    f.write(env_file.read())
            except:
                f.write("# Fehler beim Lesen")
        else:
            f.write("# .env fehlt")
        f.write("""```

## gateway.systemd.env (vollständig, ungefiltert)

```dotenv
""")
        if ENV_SYSTEMD.exists():
            try:
                with open(ENV_SYSTEMD, "r") as systemd_file:
                    f.write(systemd_file.read())
            except:
                f.write("# Fehler beim Lesen")
        else:
            f.write("# gateway.systemd.env fehlt")
        f.write("""```
""")

    # Create run file
    script_path = os.path.realpath(__file__)
    with open(RUN_FILE, "w") as f:
        f.write(f"""# Laufprotokoll Gateway B / Node 7

- Zeit (lokal): {NOW_LOCAL}
- Zeit (UTC): {NOW_UTC}
- Script: {script_path}

## Erzeugte Dateien

- {IST_FILE.name}
- {INV_FILE.name}
- {CFG_FILE.name}
- {ENV_FILE.name}

""")

    # Print completion message
    print("OK: IST-Zustand erfasst.")
    print(f"Ausgabeordner: {OUT_DIR}")
    print("Dateien:")
    
    try:
        for item in OUT_DIR.iterdir():
            print(f"- {item.name}")
    except:
        pass

if __name__ == "__main__":
    main()
