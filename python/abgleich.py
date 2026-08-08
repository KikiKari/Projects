#!/usr/bin/env python3
# abgleich.sh — portiert nach python
# Quelle: shell, Projects@abstractions:abstractions/abgleich.sh
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# Haelt den Abstraktions-Bestand im Container aktuell.
#
# Alle zwoelf Stunden wird der oeffentliche Branch Projects@abstractions nach
# /home/openclaw/.openclaw/workspace/git/Abstraktionen geholt. Das Repository
# ist oeffentlich, es wird kein Token gebraucht — der Container liest nur.
#
# Erzeugt wird hier nichts: das Portieren laeuft in GitHub Actions, weil dort
# der Schluessel liegt und der Lauf auch dann stattfindet, wenn dieser Rechner
# aus ist. Ein Lauf von Hand ist trotzdem moeglich:
#
#   docker exec -e OPENROUTER_API_KEY=... abstractions-manager \
#       python abstractions/ABSTRACTIONS_MANAGER.py --anzahl 5

import os
import subprocess
import time
from datetime import datetime
from pathlib import Path

WURZEL = os.environ.get("ABSTRACTIONS_WORKSPACE", "/home/openclaw/.openclaw/workspace")
ZIEL = Path(WURZEL) / "git" / "Abstraktionen"
HERKUNFT = "https://github.com/KikiKari/Projects.git"
BRANCH = "abstractions"
TAKT = int(os.environ.get("ABGLEICH_TAKT", "43200"))  # zwoelf Stunden

def melde(*args):
    nachricht = " ".join(str(arg) for arg in args)
    print(f"{datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')} | abgleich | {nachricht}", flush=True)

def abgleichen():
    if not (ZIEL / ".git").exists():
        melde("Erstabgleich nach", ZIEL)
        ZIEL.mkdir(parents=True, exist_ok=True)
        subprocess.run(["git", "init", "-q", str(ZIEL)], check=True)
        subprocess.run(["git", "-C", str(ZIEL), "remote", "add", "herkunft", HERKUNFT], check=True)
    
    try:
        subprocess.run(["git", "-C", str(ZIEL), "fetch", "-q", "--depth", "1", "herkunft", BRANCH], 
                      check=True, stderr=subprocess.DEVNULL)
        subprocess.run(["git", "-C", str(ZIEL), "checkout", "-q", "-f", "-B", BRANCH, "FETCH_HEAD"], check=True)
        
        result = subprocess.run(["git", "-C", str(ZIEL), "rev-parse", "--short", "HEAD"], 
                              capture_output=True, text=True, check=True)
        stand = result.stdout.strip()
        
        anzahl = sum(1 for f in ZIEL.rglob("*") 
                    if f.is_file() and f.suffix in {".js", ".pl", ".ps1", ".py", ".sh", ".tcl"} 
                    and ".git" not in f.parts)
        melde("Stand", stand + ",", anzahl, "Erzeugnisse")
    except subprocess.CalledProcessError:
        melde("Abgleich fehlgeschlagen — vorheriger Stand bleibt bestehen")

melde("Start, Takt", TAKT, "s")
while True:
    abgleichen()
    time.sleep(TAKT)
