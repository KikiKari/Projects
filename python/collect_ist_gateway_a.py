#!/usr/bin/env python3
# collect_ist_gateway_a.sh — portiert nach python
# Quelle: shell, OpenClaw@gateway1:scripts/collect_ist_gateway_a.sh
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

import os
import subprocess
import json
import socket
import platform
import urllib.request
from datetime import datetime
from pathlib import Path

def run_command(command, shell=False, default="(nicht ermittelt)"):
    try:
        if shell:
            result = subprocess.run(command, shell=True, capture_output=True, text=True, check=True)
        else:
            result = subprocess.run(command, capture_output=True, text=True, check=True)
        return result.stdout.strip()
    except (subprocess.CalledProcessError, Exception):
        return default

def get_hostname_info():
    try:
        fqdn = socket.getfqdn()
        if fqdn == socket.gethostname():
            fqdn = run_command(["hostname", "-f"], default=socket.gethostname())
    except:
        fqdn = run_command(["hostname", "-f"], default=socket.gethostname())
    return socket.gethostname(), fqdn

def get_public_ip():
    try:
        with urllib.request.urlopen('https://ifconfig.me', timeout=4) as response:
            return response.read().decode('utf-8').strip()
    except:
        return "(nicht ermittelt)"

def get_tailscale_ip():
    return run_command(["tailscale", "ip", "-4"], default="(nicht ermittelt)")

def get_os_info():
    try:
        with open('/etc/os-release', 'r') as f:
            for line in f:
                if line.startswith('PRETTY_NAME='):
                    return line.split('=', 1)[1].strip().strip('"')
    except:
        pass
    return "(nicht ermittelt)"

def get_ipv4_all():
    try:
        result = subprocess.run(["hostname", "-I"], capture_output=True, text=True)
        if result.returncode == 0:
            return ' '.join(result.stdout.strip().split())
        else:
            return "(nicht ermittelt)"
    except:
        return "(nicht ermittelt)"

def check_file_exists(filepath):
    return "vorhanden" if Path(filepath).exists() else "fehlt"

def write_ist_file(ist_file, data):
    with open(ist_file, 'w') as f:
        f.write("# IST-Zustand: Gateway A / Node 1\n\n")
        f.write(f"Stand (lokal): {data['now_local']}  \n")
        f.write(f"Stand (UTC): {data['now_utc']}\n\n")
        f.write("## 1) Identitaet & System\n\n")
        f.write("- Gateway: **A**\n")
        f.write("- Node: **1**\n")
        f.write(f"- Hostname (short): `{data['hostname_short']}`\n")
        f.write(f"- Hostname (FQDN): `{data['hostname_fqdn']}`\n")
        f.write(f"- Architektur: `{data['arch']}`\n")
        f.write(f"- Kernel: `{data['kernel']}`\n")
        f.write(f"- OS: `{data['os_pretty']}`\n")
        f.write(f"- IPv4 (lokal): `{data['ipv4_all']}`\n")
        f.write(f"- Public IPv4: `{data['public_ip']}`\n")
        f.write(f"- Tailscale IPv4: `{data['tailscale_ip']}`\n")
        f.write(f"- OpenClaw Version: `{data['openclaw_ver']}`\n")
        f.write(f"- Node.js Version: `{data['node_ver']}`\n\n")
        f.write("## 2) Arbeitsverzeichnisse\n\n")
        f.write(f"- Basis: `{data['base_dir']}`\n")
        f.write(f"- Funktionell VSCode: `{data['vscode_dir']}`\n")
        f.write(f"- Workspace Doku: `{data['out_dir']}`\n\n")
        f.write("## 3) Kernartefakte (Existenz)\n\n")
        f.write(f"- `{data['openclaw_json']}`: {data['openclaw_json_status']}\n")
        f.write(f"- `{data['env_dot']}`: {data['env_dot_status']}\n")
        f.write(f"- `{data['env_systemd']}`: {data['env_systemd_status']}\n")
        f.write(f"- `{data['base_dir']}/plugins/installs.json`: {data['installs_json_status']}\n")
        f.write(f"- `{data['base_dir']}/plugin-skills`: {data['plugin_skills_status']}\n")

def write_inv_file(inv_file, data):
    with open(inv_file, 'w') as f:
        f.write("# Artefakt-Inventar: Gateway A / Node 1\n\n")
        f.write(f"Stand: {data['now_local']}\n\n")
        f.write("## Top-Level in ~/.openclaw\n\n")
        f.write('```text\n')
        try:
            for item in Path(data['base_dir']).iterdir():
                f.write(f"{item.name}\n")
        except:
            pass
        f.write('```\n\n')
        f.write("## ~/.openclaw/.vscode\n\n")
        f.write('```text\n')
        vscode_path = Path(data['vscode_dir'])
        if vscode_path.exists():
            try:
                for item in vscode_path.iterdir():
                    mode = item.stat().st_mode
                    f.write(f"{'d' if item.is_dir() else '-'} {item.name}\n")
            except:
                f.write("(Zugriff nicht möglich)\n")
        else:
            f.write("(nicht vorhanden)\n")
        f.write('```\n\n')
        f.write("## plugin-skills/\n\n")
        f.write('```text\n')
        plugin_skills_path = Path(data['base_dir']) / "plugin-skills"
        if plugin_skills_path.exists():
            try:
                for item in plugin_skills_path.iterdir():
                    f.write(f"{item.name}\n")
            except:
                f.write("(Zugriff nicht möglich)\n")
        else:
            f.write("(nicht vorhanden)\n")
        f.write('```\n\n')
        f.write("## openclaw.json Backups\n\n")
        f.write('```text\n')
        try:
            backup_files = list(Path(data['base_dir']).glob("openclaw.json.bak*"))
            if backup_files:
                for backup in backup_files:
                    f.write(f"{backup.name}\n")
            else:
                f.write("(keine gefunden)\n")
        except:
            f.write("(keine gefunden)\n")
        f.write('```\n')

def write_cfg_file(cfg_file, data):
    with open(cfg_file, 'w') as f:
        f.write("# OpenClaw Config Snapshot: Gateway A / Node 1\n\n")
        f.write(f"Stand: {data['now_local']}\n\n")
        f.write("## Schluesselpositionen (grep)\n\n")
        f.write('```text\n')
        openclaw_json_path = Path(data['openclaw_json'])
        if openclaw_json_path.exists():
            try:
                with open(openclaw_json_path, 'r') as json_file:
                    lines = json_file.readlines()
                    for i, line in enumerate(lines, 1):
                        if any(key in line for key in ['"gateway"', '"session"', '"dmScope"', '"auth"', '"secrets"', '"tools"', '"plugins"', '"profile"', '"alsoAllow"', '"denyCommands"']):
                            f.write(f"{i}: {line}")
            except:
                f.write("(Fehler beim Lesen)\n")
        else:
            f.write("openclaw.json fehlt\n")
        f.write('```\n\n')
        f.write("## Ausschnitt gateway/session/auth\n\n")
        f.write('```json\n')
        if openclaw_json_path.exists():
            try:
                with open(openclaw_json_path, 'r') as json_file:
                    lines = json_file.readlines()
                    for line in lines[579:780]:
                        f.write(line)
            except:
                f.write('{ "error": "Fehler beim Lesen" }\n')
        else:
            f.write('{ "error": "openclaw.json fehlt" }\n')
        f.write('```\n')

def write_env_file(env_file, data):
    with open(env_file, 'w') as f:
        f.write("# ENV-Status: Gateway A / Node 1\n\n")
        f.write(f"Stand: {data['now_local']}\n\n")
        f.write("## Dateien\n\n")
        f.write('```text\n')
        try:
            env_dot_path = Path(data['env_dot'])
            env_systemd_path = Path(data['env_systemd'])
            if env_dot_path.exists():
                stat_info = env_dot_path.stat()
                f.write(f"-rwx------ 1 user group {stat_info.st_size} {datetime.fromtimestamp(stat_info.st_mtime):%b %d %H:%M} {env_dot_path}\n")
            if env_systemd_path.exists():
                stat_info = env_systemd_path.stat()
                f.write(f"-rwx------ 1 user group {stat_info.st_size} {datetime.fromtimestamp(stat_info.st_mtime):%b %d %H:%M} {env_systemd_path}\n")
        except:
            pass
        f.write('```\n\n')
        f.write("## .env (vollstaendig)\n\n")
        f.write('```dotenv\n')
        env_dot_path = Path(data['env_dot'])
        if env_dot_path.exists():
            try:
                with open(env_dot_path, 'r') as env_file_content:
                    f.write(env_file_content.read())
            except:
                f.write("# Fehler beim Lesen\n")
        else:
            f.write("# .env fehlt\n")
        f.write('```\n\n')
        f.write("## gateway.systemd.env (vollstaendig)\n\n")
        f.write('```dotenv\n')
        env_systemd_path = Path(data['env_systemd'])
        if env_systemd_path.exists():
            try:
                with open(env_systemd_path, 'r') as env_systemd_content:
                    f.write(env_systemd_content.read())
            except:
                f.write("# Fehler beim Lesen\n")
        else:
            f.write("# gateway.systemd.env fehlt\n")
        f.write('```\n')

def write_run_file(run_file, data):
    with open(run_file, 'w') as f:
        f.write("# Laufprotokoll Gateway A / Node 1\n\n")
        f.write(f"- Zeit (lokal): {data['now_local']}\n")
        f.write(f"- Zeit (UTC): {data['now_utc']}\n")
        f.write(f"- Script: {os.path.abspath(__file__)}\n\n")
        f.write("## Erzeugte Dateien\n\n")
        f.write(f"- {os.path.basename(data['ist_file'])}\n")
        f.write(f"- {os.path.basename(data['inv_file'])}\n")
        f.write(f"- {os.path.basename(data['cfg_file'])}\n")
        f.write(f"- {os.path.basename(data['env_file'])}\n")

def main():
    base_dir = os.path.expanduser("~/.openclaw")
    out_dir = os.path.join(base_dir, "workspace", "vscode")
    os.makedirs(out_dir, exist_ok=True)
    
    now_utc = datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")
    now_local = datetime.now().strftime("%Y-%m-%d %H:%M:%S %Z")
    ts = datetime.now().strftime("%Y%m%d-%H%M%S")
    
    ist_file = os.path.join(out_dir, "IST-ZUSTAND_GATEWAY-A_NODE1.md")
    inv_file = os.path.join(out_dir, "ARTEFAKT-INVENTAR_GATEWAY-A_NODE1.md")
    cfg_file = os.path.join(out_dir, "OPENCLAW-CONFIG-SNAPSHOT_GATEWAY-A_NODE1.md")
    env_file = os.path.join(out_dir, "ENV-STATUS_GATEWAY-A_NODE1.md")
    run_file = os.path.join(out_dir, f"RUN-{ts}.md")
    
    openclaw_json = os.path.join(base_dir, "openclaw.json")
    env_dot = os.path.join(base_dir, ".env")
    env_systemd = os.path.join(base_dir, "gateway.systemd.env")
    vscode_dir = os.path.join(base_dir, ".vscode")
    
    hostname_short, hostname_fqdn = get_hostname_info()
    arch = platform.machine()
    kernel = platform.release()
    os_pretty = get_os_info()
    ipv4_all = get_ipv4_all()
    public_ip = get_public_ip()
    tailscale_ip = get_tailscale_ip()
    openclaw_ver = run_command(["openclaw", "--version"], default="(nicht ermittelt)")
    node_ver = run_command(["node", "-v"], default="(nicht ermittelt)")
    
    data = {
        'now_utc': now_utc,
        'now_local': now_local,
        'hostname_short': hostname_short,
        'hostname_fqdn': hostname_fqdn,
        'arch': arch,
        'kernel': kernel,
        'os_pretty': os_pretty,
        'ipv4_all': ipv4_all,
        'public_ip': public_ip,
        'tailscale_ip': tailscale_ip,
        'openclaw_ver': openclaw_ver,
        'node_ver': node_ver,
        'base_dir': base_dir,
        'vscode_dir': vscode_dir,
        'out_dir': out_dir,
        'openclaw_json': openclaw_json,
        'env_dot': env_dot,
        'env_systemd': env_systemd,
        'ist_file': ist_file,
        'inv_file': inv_file,
        'cfg_file': cfg_file,
        'env_file': env_file
    }
    
    data['openclaw_json_status'] = check_file_exists(openclaw_json)
    data['env_dot_status'] = check_file_exists(env_dot)
    data['env_systemd_status'] = check_file_exists(env_systemd)
    data['installs_json_status'] = check_file_exists(os.path.join(base_dir, "plugins", "installs.json"))
    data['plugin_skills_status'] = "vorhanden" if os.path.isdir(os.path.join(base_dir, "plugin-skills")) else "fehlt"
    
    write_ist_file(ist_file, data)
    write_inv_file(inv_file, data)
    write_cfg_file(cfg_file, data)
    write_env_file(env_file, data)
    write_run_file(run_file, data)
    
    print("OK: IST-Zustand erfasst.")
    try:
        for item in Path(out_dir).iterdir():
            print(f"- {item.name}")
    except:
        pass

if __name__ == "__main__":
    main()
