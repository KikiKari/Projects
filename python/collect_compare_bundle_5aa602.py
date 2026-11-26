#!/usr/bin/env python3
# abstraction-provenance: {"artifact_sha256": "2ce3a6f398ac36e62f55362791ef87166cb3dac8eeeb2aa6bae1fdff36d33b41", "source_sha256": "5aa602a80e57cbc63f54485d4cd66e205c54bd9f32bc03434218ff9bd388b3ab", "target_language": "python"}
# collect_compare_bundle.sh — portiert nach python
# Quelle: shell, OpenClaw@gateway1:scripts/collect_compare_bundle.sh
# auch in: OpenClaw@gateway2:scripts/collect_compare_bundle.sh
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import os
import sys
import subprocess
import shutil
from datetime import datetime
import getpass

def run_command(cmd):
    try:
        result = subprocess.run(cmd, shell=True, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f"Fehler beim Ausführen von '{cmd}': {e.stderr}", file=sys.stderr)
        sys.exit(1)

def append_file_verbatim(md_file, label, path, lang="text"):
    with open(md_file, "a") as f:
        f.write("\n")
        f.write(f"## {label}\n")
        f.write("\n")
        f.write(f"Pfad: `{path}`\n")
        f.write("\n")
        f.write(f"```{lang}\n")
        if os.path.isfile(path):
            with open(path, "r") as file_content:
                f.write(file_content.read())
        else:
            f.write(f"[FEHLT] {path}\n")
        f.write("\n```\n")

def append_env_verbatim(md_file):
    with open(md_file, "a") as f:
        f.write("\n")
        f.write("## Umgebungsvariablen (env)\n")
        f.write("\n")
        f.write("```text\n")
        for key, value in sorted(os.environ.items()):
            f.write(f"{key}={value}\n")
        f.write("```\n")

def append_dir_files_verbatim(md_file, section, directory):
    with open(md_file, "a") as f:
        f.write("\n")
        f.write(f"## {section}\n")
        f.write("\n")
        if not os.path.isdir(directory):
            f.write(f"[FEHLT] {directory}\n")
            return
        f.write(f"Basisverzeichnis: `{directory}`\n")

    for root, _, files in sorted(os.walk(directory)):
        for file in sorted(files):
            filepath = os.path.join(root, file)
            with open(md_file, "a") as f:
                f.write("\n")
                f.write(f"### Datei: `{filepath}`\n")
                f.write("\n")
                f.write("```text\n")
                try:
                    with open(filepath, "r") as content_file:
                        f.write(content_file.read())
                except Exception as e:
                    f.write(f"[FEHLER BEIM LESEN] {e}\n")
                f.write("\n```\n")

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
        HOST = subprocess.check_output(["hostname", "-f"], stderr=subprocess.DEVNULL).decode().strip()
    except subprocess.CalledProcessError:
        HOST = subprocess.check_output(["hostname"]).decode().strip()

    OPENCLAW_JSON = os.path.join(ROOT, "openclaw.json")
    EXEC_APPROVALS_JSON = os.path.join(ROOT, "exec-approvals.json")
    GATEWAY_SYSTEMD_ENV = os.path.join(ROOT, "gateway.systemd.env")
    DOT_ENV = os.path.join(ROOT, ".env")
    CONFIG_DIR = os.path.join(ROOT, ".config")
    AGENTS_DIR = os.path.join(ROOT, "agents")

    os.makedirs(OUT_DIR, exist_ok=True)
    os.makedirs(TRANSFER_DIR, exist_ok=True)

    if not shutil.which("tree"):
        print("Fehler: 'tree' ist nicht installiert.")
        sys.exit(1)

    with open(MD_FILE, "w") as f:
        f.write("# Lokaler Gateway-Konfigurationsstand\n\n")
        f.write(f"Generiert: {NOW_LOCAL}\n")
        f.write(f"UTC: {NOW_UTC}\n")
        f.write(f"Host: {HOST}\n\n")
        f.write("Diese Datei enthaelt den lokalen Stand mit unveraenderten Inhalten.\n")

    append_file_verbatim(MD_FILE, "openclaw.json", OPENCLAW_JSON, "json")
    append_file_verbatim(MD_FILE, "exec-approvals.json", EXEC_APPROVALS_JSON, "json")
    append_file_verbatim(MD_FILE, "gateway.systemd.env", GATEWAY_SYSTEMD_ENV, "dotenv")
    append_file_verbatim(MD_FILE, ".env", DOT_ENV, "dotenv")
    append_env_verbatim(MD_FILE)
    append_dir_files_verbatim(MD_FILE, ".config (alle Dateien rekursiv)", CONFIG_DIR)
    append_dir_files_verbatim(MD_FILE, "agents (alle Dateien rekursiv)", AGENTS_DIR)

    with open(TREE_FILE, "w") as tree_f:
        subprocess.run(["tree", "-a", "-L", "6", ROOT], stdout=tree_f, check=True)

    subprocess.run(["openclaw", "backup", "create", "--output", BACKUP_FILE, "--verify"], check=True)
    shutil.copy(BACKUP_FILE, OUT_DIR)

    print("OK")
    print("Erzeugt:")
    print(f"- {MD_FILE}")
    print(f"- {TREE_FILE}")
    print(f"- {BACKUP_FILE}")
    print(f"- {TRANSFER_DIR} (leer)")

if __name__ == "__main__":
    main()
