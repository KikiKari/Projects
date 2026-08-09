#!/usr/bin/env python3
# collect_compare_bundle.sh — portiert nach python
# Quelle: shell, OpenClaw@gateway1:scripts/collect_compare_bundle.sh
# auch in: OpenClaw@gateway2:scripts/collect_compare_bundle.sh
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

import os
import sys
import shutil
import subprocess
from datetime import datetime
import getpass

def main():
    ROOT = "/home/openclaw/.openclaw"
    OUT_DIR = os.path.join(ROOT, "workspace", "vscode", "compare")
    TRANSFER_DIR = os.path.join(OUT_DIR, "transfer")
    MD_FILE = os.path.join(OUT_DIR, "local-gateway-config.md")
    TREE_FILE = os.path.join(OUT_DIR, "tree.txt")
    BACKUP_FILE = "/home/openclaw/openclaw-backup.tar.gz"
    
    NOW_LOCAL = datetime.now().strftime('%Y-%m-%d %H:%M:%S %Z')
    NOW_UTC = datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')
    
    try:
        HOST = subprocess.check_output(['hostname', '-f'], stderr=subprocess.STDOUT, text=True).strip()
    except subprocess.CalledProcessError:
        HOST = subprocess.check_output(['hostname'], text=True).strip()

    OPENCLAW_JSON = os.path.join(ROOT, "openclaw.json")
    EXEC_APPROVALS_JSON = os.path.join(ROOT, "exec-approvals.json")
    GATEWAY_SYSTEMD_ENV = os.path.join(ROOT, "gateway.systemd.env")
    DOT_ENV = os.path.join(ROOT, ".env")
    CONFIG_DIR = os.path.join(ROOT, ".config")
    AGENTS_DIR = os.path.join(ROOT, "agents")

    os.makedirs(OUT_DIR, exist_ok=True)
    os.makedirs(TRANSFER_DIR, exist_ok=True)

    if not shutil.which('tree'):
        print("Fehler: 'tree' ist nicht installiert.")
        sys.exit(1)

    def append_file_verbatim(label, path, lang="text"):
        with open(MD_FILE, "a") as f:
            f.write(f"\n## {label}\n\n")
            f.write(f"Pfad: `{path}`\n\n")
            f.write(f"```{lang}\n")
            if os.path.isfile(path):
                with open(path, "r") as file_content:
                    f.write(file_content.read())
            else:
                f.write(f"[FEHLT] {path}\n")
            f.write("\n```\n")

    def append_env_verbatim():
        with open(MD_FILE, "a") as f:
            f.write("\n## Umgebungsvariablen (env)\n\n")
            f.write("```text\n")
            for key, value in os.environ.items():
                f.write(f"{key}={value}\n")
            f.write("```\n")

    def append_dir_files_verbatim(section, directory):
        with open(MD_FILE, "a") as f:
            f.write(f"\n## {section}\n\n")
            if not os.path.isdir(directory):
                f.write(f"[FEHLT] {directory}\n")
                return
            f.write(f"Basisverzeichnis: `{directory}`\n")

        for root, dirs, files in os.walk(directory):
            dirs.sort()
            files.sort()
            for file in files:
                filepath = os.path.join(root, file)
                with open(MD_FILE, "a") as f:
                    f.write(f"\n### Datei: `{filepath}`\n\n")
                    f.write("```text\n")
                    try:
                        with open(filepath, "r") as content:
                            f.write(content.read())
                    except Exception as e:
                        f.write(f"[FEHLER] Kann Datei nicht lesen: {e}\n")
                    f.write("\n```\n")

    with open(MD_FILE, "w") as f:
        f.write(f"""# Lokaler Gateway-Konfigurationsstand

Generiert: {NOW_LOCAL}
UTC: {NOW_UTC}
Host: {HOST}

Diese Datei enthaelt den lokalen Stand mit unveraenderten Inhalten.
""")

    append_file_verbatim("openclaw.json", OPENCLAW_JSON, "json")
    append_file_verbatim("exec-approvals.json", EXEC_APPROVALS_JSON, "json")
    append_file_verbatim("gateway.systemd.env", GATEWAY_SYSTEMD_ENV, "dotenv")
    append_file_verbatim(".env", DOT_ENV, "dotenv")
    append_env_verbatim()
    append_dir_files_verbatim(".config (alle Dateien rekursiv)", CONFIG_DIR)
    append_dir_files_verbatim("agents (alle Dateien rekursiv)", AGENTS_DIR)

    with open(TREE_FILE, "w") as tree_file:
        subprocess.run(['tree', '-a', '-L', '6', ROOT], stdout=tree_file, check=True)

    subprocess.run(['openclaw', 'backup', 'create', '--output', BACKUP_FILE, '--verify'], check=True)
    shutil.copy(BACKUP_FILE, OUT_DIR)

    print("OK")
    print("Erzeugt:")
    print(f"- {MD_FILE}")
    print(f"- {TREE_FILE}")
    print(f"- {BACKUP_FILE}")
    print(f"- {TRANSFER_DIR} (leer)")

if __name__ == "__main__":
    main()
