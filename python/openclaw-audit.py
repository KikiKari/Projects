#!/usr/bin/env python3
# openclaw-audit.sh — portiert nach python
# Quelle: shell, OpenClaw@gateway1:scripts/openclaw-audit.sh
# auch in: OpenClaw@gateway2:scripts/openclaw-audit.sh
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

import subprocess
import datetime
import os
import sys

def get_script_dir():
    return os.path.dirname(os.path.abspath(__file__))

def run_command(cmd, title, out_file):
    try:
        # Write header to log
        out_file.write("\n")
        out_file.write("----------------------------------------------------------------\n")
        out_file.write(f"### {title}\n")
        out_file.write(f"### $ {' '.join(cmd)}\n")
        timestamp = datetime.datetime.now().isoformat()
        out_file.write(f"### {timestamp}\n")
        out_file.write("----------------------------------------------------------------\n")
        out_file.flush()
        
        # Run command and capture output
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        # Write command output
        if result.stdout:
            out_file.write(result.stdout)
        if result.stderr:
            out_file.write(result.stderr)
            
        # Write exit code
        out_file.write(f"[exit: {result.returncode}]\n")
        out_file.flush()
        
    except Exception as e:
        out_file.write(f"[error running command: {str(e)}]\n")

def get_openclaw_version():
    try:
        result = subprocess.run(['openclaw', '--version'], capture_output=True, text=True)
        return result.stdout.strip() if result.returncode == 0 else 'unknown'
    except:
        return 'unknown'

def main():
    script_dir = get_script_dir()
    date_stamp = datetime.datetime.now().strftime('%Y-%m-%d')
    out_path = os.path.join(script_dir, f'openclaw-audit-{date_stamp}.log')
    
    oc_cmd = ['openclaw', '--no-color']
    
    with open(out_path, 'w') as out_file:
        # Write header
        out_file.write("================================================================\n")
        out_file.write("OpenClaw audit run\n")
        out_file.write(f"Started:  {datetime.datetime.now().isoformat()}\n")
        out_file.write(f"Host:     {os.uname().nodename}\n")
        out_file.write(f"User:     {os.getlogin()}\n")
        out_file.write(f"Version:  {get_openclaw_version()}\n")
        out_file.write(f"Output:   {out_path}\n")
        out_file.write("================================================================\n")
        
        # Run all audit commands
        commands = [
            ("tasks audit --severity error", oc_cmd + ["tasks", "audit", "--severity", "error"]),
            ("secrets audit", oc_cmd + ["secrets", "audit"]),
            ("security audit", oc_cmd + ["security", "audit"]),
            ("plugins doctor", oc_cmd + ["plugins", "doctor"]),
            ("plugins deps", oc_cmd + ["plugins", "deps"]),
            ("plugins registry", oc_cmd + ["plugins", "registry"]),
            ("skills check", oc_cmd + ["skills", "check"]),
            ("hooks check", oc_cmd + ["hooks", "check"]),
            ("gateway status --deep", oc_cmd + ["gateway", "status", "--deep"]),
            ("channels status --probe", oc_cmd + ["channels", "status", "--probe"]),
            ("memory status --deep", oc_cmd + ["memory", "status", "--deep"]),
            ("sessions --all-agents", oc_cmd + ["sessions", "--all-agents"]),
            ("tasks list", oc_cmd + ["tasks", "list"]),
            ("cron list", oc_cmd + ["cron", "list"])
        ]
        
        for title, cmd in commands:
            run_command(cmd, title, out_file)
        
        # Write footer
        out_file.write("\n")
        out_file.write("================================================================\n")
        out_file.write(f"Audit complete: {datetime.datetime.now().isoformat()}\n")
        out_file.write("================================================================\n")
    
    print(f"Audit complete. Output: {out_path}")

if __name__ == "__main__":
    main()
