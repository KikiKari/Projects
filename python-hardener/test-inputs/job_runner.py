#!/usr/bin/env python3
import os
import json
import subprocess
from pathlib import Path
from datetime import datetime

WORKSPACE = Path("/home/runner/workspace")
STATE_FILE = WORKSPACE / "job_state.json"
LOG_DIR = WORKSPACE / "logs"
GIT_REPO = WORKSPACE / "output-repo"

def log(msg, level="INFO"):
    LOG_DIR.mkdir(exist_ok=True)
    logfile = LOG_DIR / f"{datetime.now().strftime('%Y-%m-%d')}.log"
    line = f"[{datetime.now()}] [{level}] {msg}"
    print(line)
    with open(logfile, 'a') as f:
        f.write(line + '\n')

def load_state():
    if STATE_FILE.exists():
        try:
            return json.load(open(STATE_FILE))
        except:
            pass
    return {"jobs": [], "last_run": None}

def save_state(state):
    with open(STATE_FILE, 'w') as f:
        json.dump(state, f, indent=2)

def run_job(cmd, job_name):
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        log(f"Job {job_name} finished: {result.returncode}")
        return result.returncode == 0
    except:
        log(f"Job {job_name} failed", "ERROR")
        return False

def commit_results(message):
    try:
        os.chdir(GIT_REPO)
        subprocess.run(["git", "add", "."], check=True)
        subprocess.run(["git", "commit", "-m", message], check=True)
        log("Committed: " + message)
    except:
        pass

def main():
    log("Runner started")
    state = load_state()
    jobs = [
        ("build", "make build"),
        ("test",  "make test"),
        ("lint",  "flake8 ."),
    ]
    success = 0
    for name, cmd in jobs:
        if run_job(cmd, name):
            success += 1
    commit_results(f"Run: {success}/{len(jobs)} jobs passed")
    state["last_run"] = datetime.now().isoformat()
    save_state(state)
    log(f"Done. {success}/{len(jobs)} passed")

if __name__ == "__main__":
    main()
