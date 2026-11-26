#!/usr/bin/env python3
# abstraction-provenance: {"artifact_sha256": "2b6de0a63c00207cb8ae24c95b245bf2c1e4648728f245d4829a8054a3f5487c", "source_sha256": "e51b94641336291974fe14bf4bb7299a75ec7dcce49e1d413282c8043e9f09f1", "target_language": "python"}
# openclaw-audit.sh — portiert nach python
# Quelle: shell, OpenClaw@gateway1:scripts/openclaw-audit.sh
# auch in: OpenClaw@gateway2:scripts/openclaw-audit.sh
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# OpenClaw read-only audit/diagnostic sweep
# Output: openclaw-audit-YYYY-MM-DD.log im selben Verzeichnis wie dieses Script
import os
import sys
import subprocess
from datetime import datetime
from pathlib import Path

def get_script_dir():
    return Path(__file__).parent.resolve()

def get_date_stamp():
    return datetime.now().strftime('%Y-%m-%d')

def get_out_file(script_dir, date_stamp):
    return script_dir / f'openclaw-audit-{date_stamp}.log'

def write_header(out_file):
    with out_file.open('w') as f:
        f.write("================================================================\n")
        f.write("OpenClaw audit run\n")
        f.write(f"Started:  {datetime.now().isoformat()}\n")
        f.write(f"Host:     {os.uname().nodename}\n")
        f.write(f"User:     {os.getlogin()}\n")
        
        try:
            version = subprocess.run(['openclaw', '--version'], capture_output=True, text=True)
            version_str = version.stdout.strip() if version.returncode == 0 else 'unknown'
        except FileNotFoundError:
            version_str = 'unknown'
        f.write(f"Version:  {version_str}\n")
        f.write(f"Output:   {out_file}\n")
        f.write("================================================================\n")

def run_cmd(title, cmd, out_file):
    with out_file.open('a') as f:
        f.write("\n")
        f.write("----------------------------------------------------------------\n")
        f.write(f"### {title}\n")
        f.write(f"### $ {' '.join(cmd)}\n")
        f.write(f"### {datetime.now().isoformat()}\n")
        f.write("----------------------------------------------------------------\n")
        
        try:
            result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
            f.write(result.stdout)
            f.write(f"[exit: {result.returncode}]\n")
        except Exception as e:
            f.write(f"[error: {str(e)}]\n")

def main():
    script_dir = get_script_dir()
    date_stamp = get_date_stamp()
    out_file = get_out_file(script_dir, date_stamp)
    
    oc = ['openclaw', '--no-color']
    
    write_header(out_file)
    
    commands = [
        ("tasks audit --severity error", oc + ["tasks", "audit", "--severity", "error"]),
        ("secrets audit", oc + ["secrets", "audit"]),
        ("security audit", oc + ["security", "audit"]),
        ("plugins doctor", oc + ["plugins", "doctor"]),
        ("plugins deps", oc + ["plugins", "deps"]),
        ("plugins registry", oc + ["plugins", "registry"]),
        ("skills check", oc + ["skills", "check"]),
        ("hooks check", oc + ["hooks", "check"]),
        ("gateway status --deep", oc + ["gateway", "status", "--deep"]),
        ("channels status --probe", oc + ["channels", "status", "--probe"]),
        ("memory status --deep", oc + ["memory", "status", "--deep"]),
        ("sessions --all-agents", oc + ["sessions", "--all-agents"]),
        ("tasks list", oc + ["tasks", "list"]),
        ("cron list", oc + ["cron", "list"])
    ]
    
    for title, cmd in commands:
        run_cmd(title, cmd, out_file)
    
    with out_file.open('a') as f:
        f.write("\n")
        f.write("================================================================\n")
        f.write(f"Audit complete: {datetime.now().isoformat()}\n")
        f.write("================================================================\n")
    
    print(f"Audit complete. Output: {out_file}")

if __name__ == "__main__":
    main()
