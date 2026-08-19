#!/usr/bin/env python3
# sync-local.sh — portiert nach python
# Quelle: shell, Onboarding@main:scripts/sync-local.sh
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

# Python-Äquivalent zu sync-local.ps1 — inkrementeller Git-Sync für den Dev-Stack.
# Nutzung: scripts/sync-local.py [--branch <name>] [--interval <s>] [--once]

import argparse
import os
import sys
import time
import subprocess
from pathlib import Path
from datetime import datetime


def log(message):
    print(f"[{datetime.now().strftime('%H:%M:%S')}] {message}")


def run_command(cmd, cwd=None, check=True, capture_output=False):
    try:
        result = subprocess.run(
            cmd,
            cwd=cwd,
            check=check,
            capture_output=capture_output,
            text=True
        )
        return result.stdout.strip() if capture_output else None
    except subprocess.CalledProcessError as e:
        if not check:
            return e.stdout.strip() if capture_output else None
        log(f"WARNUNG: {' '.join(cmd)} fehlgeschlagen")
        return None


def compose(args, *compose_args):
    cmd = ["docker", "compose", "-f", args.compose_file] + list(compose_args)
    return run_command(cmd, check=False)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--branch", default="claude/onboarding-persistent-sandbox-vjfmcx")
    parser.add_argument("--interval", type=int, default=20)
    parser.add_argument("--once", action="store_true")
    parser.add_argument("--compose-file", default="docker-compose.dev.yml")

    args = parser.parse_args()

    # Wechsel ins Wurzelverzeichnis des Repos
    script_dir = Path(__file__).parent.parent.resolve()
    os.chdir(script_dir)

    # Prüfe aktuellen Branch
    current_branch = run_command(["git", "rev-parse", "--abbrev-ref", "HEAD"], capture_output=True)
    if current_branch != args.branch:
        log(f"Wechsle von '{current_branch}' auf '{args.branch}' …")
        run_command(["git", "fetch", "origin", args.branch])
        try:
            run_command(["git", "switch", args.branch], check=True)
        except subprocess.CalledProcessError:
            run_command(["git", "switch", "-c", args.branch, "--track", f"origin/{args.branch}"])

    log(f"Sync aktiv: origin/{args.branch} -> {os.getcwd()} "
        f"(Intervall {args.interval}s, Compose: {args.compose_file})")

    while True:
        # Fetch vom Remote
        fetch_result = run_command(
            ["git", "fetch", "origin", args.branch, "--quiet"],
            check=False
        )
        if fetch_result is None:
            log(f"Fetch fehlgeschlagen (Netzwerk?) — nächster Versuch in {args.interval}s")
        else:
            # Hole lokale und Remote-Revisions
            local_rev = run_command(["git", "rev-parse", "HEAD"], capture_output=True)
            remote_rev = run_command(["git", "rev-parse", f"origin/{args.branch}"], capture_output=True)

            if local_rev != remote_rev:
                # Prüfe, ob lokaler Stand Vorfahre des Remotes ist
                merge_base_result = run_command(
                    ["git", "merge-base", "--is-ancestor", local_rev, remote_rev],
                    check=False
                )

                if merge_base_result is None:
                    log("ACHTUNG: Lokaler Stand von origin/{} abgewichen — "
                        "kein automatischer Merge, bitte manuell auflösen.".format(args.branch))
                else:
                    # Hole geänderte Dateien
                    changed_files_raw = run_command(
                        ["git", "diff", "--name-only", f"{local_rev}..{remote_rev}"],
                        capture_output=True
                    )
                    changed_files = changed_files_raw.splitlines() if changed_files_raw else []

                    # Fast-forward Merge
                    run_command(["git", "merge", "--ff-only", remote_rev, "--quiet"])
                    log(f"Aktualisiert {local_rev[:7]} -> {remote_rev[:7]} ({len(changed_files)} Datei(en))")

                    needs_action = False

                    # Prüfe Änderungen an Compose-Datei
                    if args.compose_file in changed_files:
                        log("Compose-Datei geändert — erzeuge Dev-Stack neu …")
                        compose(args, "up", "-d")
                        needs_action = True

                    # Prüfe Änderungen am Backend
                    backend_files = {"Dockerfile", "requirements.txt"}
                    backend_changed = any(
                        f.startswith("backend/") and (
                            os.path.basename(f) in backend_files or
                            "requirements." in f
                        )
                        for f in changed_files
                    )
                    if backend_changed:
                        log("Backend-Dependencies/Dockerfile geändert — baue nur das Backend neu …")
                        compose(args, "up", "-d", "--build", "backend")
                        needs_action = True

                    # Prüfe Änderungen am Frontend
                    frontend_files = {"package.json", "package-lock.json"}
                    frontend_changed = any(
                        os.path.basename(f) in frontend_files
                        for f in changed_files
                    )
                    if frontend_changed:
                        log("Frontend-Dependencies geändert — starte Frontend neu "
                            "(npm install läuft im Container) …")
                        compose(args, "restart", "frontend")
                        needs_action = True

                    if not needs_action:
                        log("Nur Quellcode/Assets — Hot-Reload übernimmt, kein Build nötig.")

        if args.once:
            break
        time.sleep(args.interval)


if __name__ == "__main__":
    main()
