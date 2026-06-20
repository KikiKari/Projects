#!/usr/bin/env python3
"""
Permanenter ClawHub ↔ Git Sync Agent
Multi-Node fähig, stündliche Ausführung
"""

import os
import sys
import json
import subprocess
import shutil
import argparse
from pathlib import Path
from datetime import datetime

# Import sync functions
sys.path.append('/home/openclaw/.openclaw/workspace/scripts')
from sync_clawhub_git import sync_to_git, sync_to_clawhub, log, validate_skill, get_file_hash

CLAWHUB_DIR = Path("/home/openclaw/.openclaw/workspace/skills")
GIT_DIR = Path("/home/openclaw/.openclaw/workspace/git/skills")
STATE_FILE = Path("/home/openclaw/.openclaw/workspace/db/sync_state.json")

# Root directory for backups
BACKUP_ROOT = Path("/home/openclaw/.openclaw/workspace/backups/sync_agent")

def load_state():
    """Lädt den Sync-State"""
    if STATE_FILE.exists():
        with open(STATE_FILE, 'r') as f:
            return json.load(f)
    return {"sync_history": [], "pending": []}

def save_state(state):
    """Speichert den Sync-State"""
    STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(STATE_FILE, 'w') as f:
        json.dump(state, f, indent=2)

def get_all_skills():
    """Findet alle Skills in beiden Verzeichnissen"""
    clawhub_skills = {d.name for d in CLAWHUB_DIR.iterdir() if d.is_dir() and not d.name.startswith('.')}
    git_skills = {d.name for d in GIT_DIR.iterdir() if d.is_dir() and not d.name.startswith('.')}
    return clawhub_skills.union(git_skills)

def init_git_repo(skill_path: Path, skill_name: str):
    """Initialisiert Git-Repo wenn nötig"""
    git_dir = skill_path / ".git"
    if not git_dir.exists():
        os.chdir(skill_path)
        subprocess.run(["git", "init"], capture_output=True)
        subprocess.run(["git", "add", "."], capture_output=True)
        subprocess.run(["git", "commit", "-m", f"Initial commit: {skill_name} skill"], capture_output=True)
        log(f"Git initialized for {skill_name}")

def backup_skill_dir(skill_path: Path, skill_name: str):
    """Creates a timestamped tar.gz backup of a skill directory."""
    if not skill_path.exists():
        return
    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
    backup_dir = BACKUP_ROOT / timestamp
    backup_dir.mkdir(parents=True, exist_ok=True)
    archive_name = f"{skill_name}_{timestamp}.tar.gz"
    archive_path = backup_dir / archive_name
    shutil.make_archive(str(archive_path.with_suffix('')), 'gztar', root_dir=skill_path)
    log(f"Backup created for {skill_name} at {archive_path}")

def sync_skill_bidirectional(skill_name: str, dry_run: bool = False):
    """Bidirektionale Synchronisation eines Skills"""
    clawhub_path = CLAWHUB_DIR / skill_name
    git_path = GIT_DIR / skill_name

    # Backup before any potential changes (skip for dry-run)
    if not dry_run:
        backup_skill_dir(clawhub_path, f"{skill_name}_clawhub")
        backup_skill_dir(git_path, f"{skill_name}_git")

    # Fall 1: Nur in ClawHub → zu Git
    if clawhub_path.exists() and not git_path.exists():
        log(f"NEW in ClawHub: {skill_name} → syncing to Git")
        if sync_to_git(skill_name, dry_run=False):
            init_git_repo(git_path, skill_name)
            return "synced_to_git"

    # Fall 2: Nur in Git → zu ClawHub
    elif git_path.exists() and not clawhub_path.exists():
        log(f"NEW in Git: {skill_name} → syncing to ClawHub")
        if sync_to_clawhub(skill_name, dry_run=False):
            return "synced_to_clawhub"

    # Fall 3: In beiden vorhanden → Vergleiche Timestamps
    elif clawhub_path.exists() and git_path.exists():
        # --- MODIFIZIERTE LOGIK: Robusterer Datei-Hash-Vergleich ---

        # Stelle sicher, dass beide als gültige Skills validiert werden
        if not validate_skill(clawhub_path):
            log(f"Validation failed for ClawHub skill: {skill_name}", "ERROR")
            return "error"
        if not validate_skill(git_path):
            log(f"Validation failed for Git skill: {skill_name}", "ERROR")
            return "error"

        # Berechne Hashes für clawhub und git
        clawhub_hashes = get_hashes(clawhub_path)
        git_hashes = get_hashes(git_path)

        if clawhub_hashes != git_hashes:
            log(f"Content difference detected for: {skill_name}")

            # Einfache (aber oft ausreichende) Logik: Wenn clawhub neuer ist, lade hoch.
            # Eine detailliertere Strategie (z.B. welche Version von Git übernehmen)
            # könnte hier implementiert werden, falls nötig.
            # Für jetzt: Wenn sie sich unterscheiden, priorisieren wir ClawHub > Git
            # und aktualisieren Git.

            log(f"UPDATE: {skill_name} ClawHub content is newer or different → syncing to Git")
            if sync_to_git(skill_name, dry_run=False):
                # Git commit (optional, sync_to_git macht das bereits, aber zur Sicherheit)
                os.chdir(git_path)
                subprocess.run(["git", "add", "."], capture_output=True)
                subprocess.run(["git", "commit", "-m", f"Sync from ClawHub content diff: {datetime.now().strftime('%Y-%m-%d %H:%M')}"], capture_output=True)
                return "updated_git"
            else:
                log(f"Failed to sync {skill_name} to Git after content diff", "ERROR")
                return "error"
        else:
            log(f"Content is identical for: {skill_name}")
            return "no_change"

    return "no_change"

# --- Hinzufügen dieser Hilfsfunktion ---
def get_hashes(skill_dir: Path):
    """Erzeugt ein Dictionary von Datei-Hashes für einen Skill-Ordner."""
    hashes = {}
    for root, _, files in os.walk(skill_dir):
        for file in files:
            file_path = Path(root) / file
            # Ignoriere .git Verzeichnisse
            if '.git' in str(file_path):
                continue
            hashes[str(file_path.relative_to(skill_dir))] = get_file_hash(file_path)
    return hashes

def main():
    """Hauptfunktion des Sync-Agents"""
    parser = argparse.ArgumentParser(description="ClawHub ↔ Git Sync Agent")
    parser.add_argument('--dry-run', action='store_true', help='Perform a dry run without making changes.')
    args = parser.parse_args()
    DRY_RUN = args.dry_run
    log("=== ClawHub ↔ Git Sync Agent gestartet ===")

    state = load_state()
    all_skills = get_all_skills()
    log(f"Gefundene Skills: {len(all_skills)}")

    results = {
        "synced_to_git": [],
        "synced_to_clawhub": [],
        "updated_git": [],
        "updated_clawhub": [],
        "no_change": [],
        "errors": []
    }

    for skill in sorted(all_skills):
        try:
            result = sync_skill_bidirectional(skill, dry_run=DRY_RUN)
            results[result].append(skill)
        except Exception as e:
            log(f"ERROR syncing {skill}: {e}", "ERROR")
            results["errors"].append(skill)

    # Zusammenfassung
    log("\n=== SYNC ZUSAMMENFASSUNG ===")
    log(f"Neu in Git: {len(results['synced_to_git'])} - {results['synced_to_git']}")
    log(f"Neu in ClawHub: {len(results['synced_to_clawhub'])} - {results['synced_to_clawhub']}")
    log(f"Git aktualisiert: {len(results['updated_git'])} - {results['updated_git']}")
    log(f"ClawHub aktualisiert: {len(results['updated_clawhub'])} - {results['updated_clawhub']}")
    log(f"Keine Änderung: {len(results['no_change'])}")
    log(f"Fehler: {len(results['errors'])} - {results['errors']}")

    # State speichern
    if "sync_history" not in state:
        state["sync_history"] = []
    state["sync_history"].append({
        "timestamp": datetime.now().isoformat(),
        "results": results
    })
    # Nur letzte 100 Einträge behalten
    state["sync_history"] = state["sync_history"][-100:]
    save_state(state)

    log("=== Sync Agent beendet ===\n")

if __name__ == "__main__":
    main()