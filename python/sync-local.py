#!/usr/bin/env python3
# sync-local.ps1 — portiert nach python
# Quelle: powershell, Onboarding@main:scripts/sync-local.ps1
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

"""
.SYNOPSIS
  Hält den lokalen Dev-Stack (docker-compose.dev.yml) inkrementell mit GitHub synchron.

.DESCRIPTION
  Pollt origin/<Branch> und zieht neue Commits per Fast-Forward. Danach entscheidet
  der Diff, was nötig ist:
    - nur Quellcode geändert            -> nichts tun, Hot-Reload übernimmt
    - package.json / package-lock.json  -> Frontend-Container neu starten
                                           (Entrypoint installiert Dependencies nur
                                           bei geändertem Lockfile-Hash nach)
    - backend/Dockerfile, requirements* -> Backend-Image gezielt neu bauen
    - docker-compose.dev.yml            -> Dev-Stack neu erzeugen
  Es wird nie „blind" der ganze Branch neu gebaut.
"""

import argparse
import subprocess
import time
import os
import sys
from datetime import datetime
from pathlib import Path

def log(msg):
    print(f"[{datetime.now().strftime('%H:%M:%S')}] {msg}")

def run_command(cmd, cwd=None, capture_output=True, check=False):
    """Führt einen Shell-Befehl aus und gibt das Ergebnis zurück."""
    try:
        result = subprocess.run(
            cmd,
            cwd=cwd,
            capture_output=capture_output,
            text=True,
            check=check
        )
        return result
    except subprocess.CalledProcessError as e:
        if not check:
            return e
        raise

def invoke_compose(compose_args, compose_file, repo_root):
    """Führt docker compose mit den gegebenen Argumenten aus."""
    cmd = ["docker", "compose", "-f", compose_file] + compose_args
    result = run_command(cmd, cwd=repo_root, capture_output=False)
    if result.returncode != 0:
        log(f"WARNUNG: docker compose {' '.join(compose_args)} fehlgeschlagen (Exit {result.returncode})")

def main():
    parser = argparse.ArgumentParser(description="Synchronisiert den lokalen Dev-Stack mit GitHub")
    parser.add_argument("--branch", default="claude/onboarding-persistent-sandbox-vjfmcx", help="Zu verfolgender Branch")
    parser.add_argument("--interval-seconds", type=int, default=20, help="Intervall in Sekunden")
    parser.add_argument("--compose-file", default="docker-compose.dev.yml", help="Docker Compose Datei")
    parser.add_argument("--once", action="store_true", help="Nur ein Sync-Durchlauf")
    
    args = parser.parse_args()
    
    # Repo-Root bestimmen (Elternverzeichnis des Script-Verzeichnisses)
    repo_root = Path(__file__).parent.parent.absolute()
    os.chdir(repo_root)
    
    # Sicherstellen, dass der Ziel-Branch ausgecheckt ist
    result = run_command(["git", "rev-parse", "--abbrev-ref", "HEAD"])
    current = result.stdout.strip() if result.returncode == 0 else ""
    
    if current != args.branch:
        log(f"Wechsle von '{current}' auf '{args.branch}' …")
        run_command(["git", "fetch", "origin", args.branch])
        result = run_command(["git", "switch", args.branch], capture_output=False)
        
        if result.returncode != 0:
            result = run_command([
                "git", "switch", "-c", args.branch, "--track", f"origin/{args.branch}"
            ], capture_output=False)
            
            if result.returncode != 0:
                print(f"Fehler: Branch '{args.branch}' konnte nicht ausgecheckt werden.")
                sys.exit(1)
    
    log(f"Sync aktiv: origin/{args.branch} -> {repo_root} (Intervall {args.interval_seconds}s, Compose: {args.compose_file})")
    
    while True:
        result = run_command(["git", "fetch", "origin", args.branch, "--quiet"])
        
        if result.returncode != 0:
            log(f"Fetch fehlgeschlagen (Netzwerk?) — nächster Versuch in {args.interval_seconds}s")
        else:
            # Lokalen und Remote-Commit holen
            local_result = run_command(["git", "rev-parse", "HEAD"])
            remote_result = run_command(["git", "rev-parse", f"origin/{args.branch}"])
            
            if local_result.returncode == 0 and remote_result.returncode == 0:
                local = local_result.stdout.strip()
                remote = remote_result.stdout.strip()
                
                if local != remote:
                    # Prüfen ob lokaler Commit Vorfahre des Remotes ist
                    merge_base_result = run_command([
                        "git", "merge-base", "--is-ancestor", local, remote
                    ])
                    
                    if merge_base_result.returncode != 0:
                        log("ACHTUNG: Lokaler Stand ist von origin/{} abgewichen (lokale Commits?). "
                            "Kein automatischer Merge — bitte manuell auflösen.".format(args.branch))
                    else:
                        # Geänderte Dateien ermitteln
                        diff_result = run_command([
                            "git", "diff", "--name-only", f"{local}..{remote}"
                        ])
                        
                        changed_files = []
                        if diff_result.returncode == 0:
                            changed_files = diff_result.stdout.strip().split('\n') if diff_result.stdout.strip() else []
                        
                        # Fast-forward Merge durchführen
                        run_command(["git", "merge", "--ff-only", remote, "--quiet"])
                        log("Aktualisiert {} -> {} ({} Datei(en))".format(
                            local[:7], remote[:7], len(changed_files)
                        ))
                        
                        # Änderungen kategorisieren
                        frontend_deps = [f for f in changed_files if f in ["package.json", "package-lock.json"]]
                        backend_image = [f for f in changed_files if f.startswith("backend/") and 
                                       (f.endswith("Dockerfile") or "requirements" in f and f.endswith(".txt"))]
                        compose_changed = [f for f in changed_files if f == args.compose_file]
                        
                        # Aktionen basierend auf Änderungen ausführen
                        if compose_changed:
                            log("Compose-Datei geändert — erzeuge Dev-Stack neu …")
                            invoke_compose(["up", "-d"], args.compose_file, repo_root)
                        
                        if backend_image:
                            log("Backend-Dependencies/Dockerfile geändert — baue nur das Backend neu …")
                            invoke_compose(["up", "-d", "--build", "backend"], args.compose_file, repo_root)
                        
                        if frontend_deps:
                            log("Frontend-Dependencies geändert — starte Frontend neu (npm install läuft im Container) …")
                            invoke_compose(["restart", "frontend"], args.compose_file, repo_root)
                        
                        if not (compose_changed or backend_image or frontend_deps):
                            log("Nur Quellcode/Assets — Hot-Reload übernimmt, kein Build nötig.")
        
        if args.once:
            break
            
        time.sleep(args.interval_seconds)

if __name__ == "__main__":
    main()
