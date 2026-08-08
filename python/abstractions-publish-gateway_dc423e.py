#!/usr/bin/env python3
# abstractions-publish-gateway.sh — portiert nach python
# Quelle: shell, Projects@clawhub:clawhub/Scripts/abstractions-publish-gateway.sh
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# abstractions-publish-gateway.sh
#
# Pusht den Stand von workspace/git/Abstraktionen/ auf den
# gateway{1,2}-abstractions-Branch.
#
# Exit-Codes:
#   0 = Erfolg (gepusht ODER nichts zu tun)
#   1 = Unerwarteter Branch
#   2 = Secret im Diff gefunden
#   3 = Git-Operation fehlgeschlagen
#   4 = Repo-Pfad nicht erreichbar oder kein Git-Repo

import os
import sys
import subprocess
import re
from datetime import datetime
from pathlib import Path

ABSTRACTIONS_REPO = "/home/openclaw/.openclaw/workspace/git/Abstraktionen"
LOG_DIR = "/home/openclaw/.openclaw/logs/abstractions-publish-gateway"
Path(LOG_DIR).mkdir(parents=True, exist_ok=True)
LOG_FILE = os.path.join(LOG_DIR, datetime.now().strftime("%Y-%m-%d") + ".log")

def log(msg):
    ts = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    log_message = f"[{ts}] {msg}"
    print(log_message)
    with open(LOG_FILE, "a") as f:
        f.write(log_message + "\n")

def run_command(cmd, cwd=None, check=True):
    try:
        result = subprocess.run(cmd, cwd=cwd, shell=True, capture_output=True, text=True, check=check)
        return result.stdout.strip(), result.stderr.strip(), result.returncode
    except subprocess.CalledProcessError as e:
        if check:
            raise
        return e.stdout.strip(), e.stderr.strip(), e.returncode

# --- Schritt 1: Repo erreichbar? ---
if not os.path.isdir(ABSTRACTIONS_REPO):
    log("STATUS=error CODE=4 REASON=repo-unreachable PATH=" + ABSTRACTIONS_REPO)
    sys.exit(4)

if not os.path.isdir(os.path.join(ABSTRACTIONS_REPO, ".git")):
    log("STATUS=error CODE=4 REASON=not-a-git-repo PATH=" + ABSTRACTIONS_REPO)
    sys.exit(4)

# --- Schritt 2: Branch ermitteln ---
try:
    branch, _, _ = run_command("git branch --show-current", cwd=ABSTRACTIONS_REPO)
except:
    log("STATUS=error CODE=3 REASON=git-branch-show-current-failed")
    sys.exit(3)

if branch not in ["gateway1-abstractions", "gateway2-abstractions"]:
    log(f"STATUS=error CODE=1 REASON=unexpected-branch BRANCH={branch}")
    sys.exit(1)

log(f"STATUS=info STEP=branch-detected BRANCH={branch}")

# --- Schritt 3: Hat sich was geändert? ---
try:
    status_output, _, _ = run_command("git status --porcelain", cwd=ABSTRACTIONS_REPO)
except:
    log("STATUS=error CODE=3 REASON=git-status-failed")
    sys.exit(3)

if not status_output:
    log(f"STATUS=skip REASON=no-changes BRANCH={branch}")
    sys.exit(0)

changed_count = len(status_output.splitlines())
log(f"STATUS=info STEP=changes-detected COUNT={changed_count} BRANCH={branch}")

# --- Schritt 4: Secret-Scan auf geänderte Dateien ---
SECRET_PATTERNS = r'sk-[A-Za-z0-9]{20,}|ghp_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,}|ntn_[A-Za-z0-9]{30,}|secret_[A-Za-z0-9]{30,}|tvly-[A-Za-z0-9-]{20,}|nvapi-[A-Za-z0-9]{30,}|tskey-[A-Za-z0-9-]{20,}|xoxb-[A-Za-z0-9-]{20,}|xapp-[A-Za-z0-9-]{20,}|AIza[A-Za-z0-9_-]{30,}'

secret_hits = []
for line in status_output.splitlines():
    file_path = line[3:].strip()
    full_path = os.path.join(ABSTRACTIONS_REPO, file_path)
    if os.path.isfile(full_path):
        try:
            with open(full_path, "r", encoding="utf-8", errors="ignore") as f:
                content = f.read()
                match = re.search(SECRET_PATTERNS, content)
                if match:
                    matched_text = match.group(0)[:10]
                    secret_hits.append(f"{file_path}[{matched_text}...]")
        except Exception:
            pass

if secret_hits:
    hits_str = " ".join(secret_hits)
    log(f"STATUS=error CODE=2 REASON=secrets-found HITS={hits_str}")
    sys.exit(2)

log("STATUS=info STEP=secret-scan-clean")

# --- Schritt 5: Stage + Commit ---
try:
    stdout, stderr, code = run_command("git add -A", cwd=ABSTRACTIONS_REPO, check=False)
    log_output = stdout + stderr
    if log_output:
        with open(LOG_FILE, "a") as f:
            f.write(log_output + "\n")
    if code != 0:
        log("STATUS=error CODE=3 REASON=git-add-failed")
        sys.exit(3)
except:
    log("STATUS=error CODE=3 REASON=git-add-failed")
    sys.exit(3)

commit_msg = f"auto: abstractions-sync {datetime.now().strftime('%Y-%m-%d %H:%M')}"
try:
    stdout, stderr, code = run_command(f"git commit -m \"{commit_msg}\"", cwd=ABSTRACTIONS_REPO, check=False)
    log_output = stdout + stderr
    if log_output:
        with open(LOG_FILE, "a") as f:
            f.write(log_output + "\n")
    if code != 0:
        try:
            status_check, _, _ = run_command("git status --porcelain", cwd=ABSTRACTIONS_REPO)
            if status_check.strip():
                log("STATUS=error CODE=3 REASON=git-commit-failed")
                sys.exit(3)
            else:
                log("STATUS=skip REASON=nothing-staged-after-add")
                sys.exit(0)
        except:
            log("STATUS=error CODE=3 REASON=git-commit-failed")
            sys.exit(3)
except:
    log("STATUS=error CODE=3 REASON=git-commit-failed")
    sys.exit(3)

try:
    commit_hash, _, _ = run_command("git log -1 --format=%h", cwd=ABSTRACTIONS_REPO)
except:
    log("STATUS=error CODE=3 REASON=git-log-failed")
    sys.exit(3)

log(f"STATUS=info STEP=commit-created HASH={commit_hash} MSG=\"{commit_msg}\"")

# --- Schritt 6: Push ---
try:
    stdout, stderr, code = run_command("git push", cwd=ABSTRACTIONS_REPO, check=False)
    log_output = stdout + stderr
    if log_output:
        with open(LOG_FILE, "a") as f:
            f.write(log_output + "\n")
    if code != 0:
        log(f"STATUS=error CODE=3 REASON=git-push-failed BRANCH={branch} HASH={commit_hash}")
        sys.exit(3)
except:
    log(f"STATUS=error CODE=3 REASON=git-push-failed BRANCH={branch} HASH={commit_hash}")
    sys.exit(3)

# --- Erfolg ---
log(f"STATUS=ok BRANCH={branch} COUNT={changed_count} HASH={commit_hash}")
print("")
print("=== SUMMARY ===")
print(f"Branch:  {branch}")
print(f"Files:   {changed_count}")
print(f"Commit:  {commit_hash}")
print("Status:  OK - gepusht nach origin/" + branch)
sys.exit(0)
