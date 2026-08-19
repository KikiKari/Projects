#!/usr/bin/env python3
# server-maintenance.sh — portiert nach python
# Quelle: shell, OpenClaw@gateway1:scripts/server-maintenance.sh
# auch in: OpenClaw@gateway2:scripts/server-maintenance.sh
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

import subprocess
import datetime
import os
import sys

# Server Maintenance Script
# RAM: 8GB, Uhr: Europe/Berlin

LOG_FILE = "/var/log/server-maintenance.log"
DATE = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
HOST = os.uname()[1]

# Farben für Terminal
RED = '\033[0;31m'
GREEN = '\033[0;32m'
YELLOW = '\033[1;33m'
NC = '\033[0m'

def log_message(message):
    """Log message to file and stdout"""
    print(message)
    with open(LOG_FILE, "a") as f:
        f.write(message + "\n")

log_message(f"[{DATE}] === Server Maintenance Check ===")

# 1. APT Update Check
log_message(f"[{DATE}] Checking for updates...")
try:
    result = subprocess.run(["apt", "update", "-qq"], capture_output=True, text=True)
    lines = result.stdout.split('\n')[-6:-1]
    for line in lines:
        if line.strip():
            log_message(line)
    
    result = subprocess.run(["apt", "list", "--upgradable"], capture_output=True, text=True)
    updates = len(result.stdout.split('\n')) - 1
    if updates > 1:
        log_message(f"[{DATE}] ⚠️ {updates} packages can be upgraded")
except Exception as e:
    log_message(f"[{DATE}] Error checking updates: {str(e)}")

# 2. RAM Check (8GB total)
log_message(f"[{DATE}] Checking RAM usage...")
RAM_TOTAL = 8192  # 8GB in MB
try:
    result = subprocess.run(["free", "-m"], capture_output=True, text=True)
    lines = result.stdout.split('\n')
    for line in lines:
        if line.startswith('Mem:'):
            parts = line.split()
            RAM_USED = int(parts[2])
            break
    
    RAM_PERCENT = (RAM_USED * 100) // RAM_TOTAL
    log_message(f"[{DATE}] RAM: {RAM_USED}MB / {RAM_TOTAL}MB ({RAM_PERCENT}%)")
    
    if RAM_PERCENT > 90:
        log_message(f"[{DATE}] 🔴 WARNING: RAM usage > 90%!")
    elif RAM_PERCENT > 80:
        log_message(f"[{DATE}] 🟡 WARNING: RAM usage > 80%")
except Exception as e:
    log_message(f"[{DATE}] Error checking RAM: {str(e)}")

# 3. Disk Space Check
log_message(f"[{DATE}] Checking disk space...")
try:
    result = subprocess.run(["df", "-h", "/"], capture_output=True, text=True)
    lines = result.stdout.strip().split('\n')
    if len(lines) > 1:
        disk_info = lines[1].split()
        if len(disk_info) >= 5:
            used = disk_info[2]
            total = disk_info[1]
            percent = disk_info[4]
            log_message(f"[{DATE}] Disk: {used} / {total} ({percent} used)")
            
            DISK_PERCENT = int(percent.replace('%', ''))
            if DISK_PERCENT > 90:
                log_message(f"[{DATE}] 🔴 WARNING: Disk > 90%!")
            elif DISK_PERCENT > 80:
                log_message(f"[{DATE}] 🟡 WARNING: Disk > 80%")
except Exception as e:
    log_message(f"[{DATE}] Error checking disk space: {str(e)}")

# 4. NTP Check
log_message(f"[{DATE}] Checking NTP sync...")
try:
    result = subprocess.run(["timedatectl", "status"], capture_output=True, text=True)
    if "NTP synchronized: yes" in result.stdout:
        log_message(f"[{DATE}] ✅ NTP synchronized")
    else:
        log_message(f"[{DATE}] ⚠️ NTP not synchronized")
except Exception as e:
    log_message(f"[{DATE}] Error checking NTP: {str(e)}")

# 5. OpenClaw Gateway Status
log_message(f"[{DATE}] Checking OpenClaw Gateway...")
try:
    result = subprocess.run(["systemctl", "is-active", "--quiet", "openclaw-gateway"])
    if result.returncode == 0:
        log_message(f"[{DATE}] ✅ OpenClaw Gateway running")
    else:
        log_message(f"[{DATE}] 🔴 OpenClaw Gateway NOT running!")
        subprocess.run(["systemctl", "restart", "openclaw-gateway"])
except Exception as e:
    log_message(f"[{DATE}] Error checking OpenClaw Gateway: {str(e)}")

# 6. Load Average
try:
    result = subprocess.run(["uptime"], capture_output=True, text=True)
    load_line = result.stdout.split("load average:")[1].strip()
    LOAD = load_line.split(',')[0].strip()
    log_message(f"[{DATE}] Load Average: {LOAD}")
except Exception as e:
    log_message(f"[{DATE}] Error checking load average: {str(e)}")

log_message(f"[{DATE}] === Maintenance Complete ===")
log_message("")
