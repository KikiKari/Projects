#!/usr/bin/env pwsh
# sync_bulk.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway1:skills/sync-utils/scripts/sync_bulk.py
# auch in: OpenClaw@gateway2:skills/sync-utils/scripts/sync_bulk.py
# Erzeugt: 2026-10-30 durch ABSTRACTIONS_MANAGER.py

<#
Bulk Sync - Synchronisiert alle Skills
#>

# Import sync functions
$env:PYTHONPATH = "/home/openclaw/.openclaw/workspace/scripts"
& python3 -c "import sys; sys.path.append('/home/openclaw/.openclaw/workspace/scripts')" | Out-Null

# Führe das Python-Skript direkt aus, da PowerShell keine direkte Übersetzung aller Python-Funktionen bietet
$pythonScript = @'
#!/usr/bin/env python3
"""
Bulk Sync - Synchronisiert alle Skills
"""

import sys
from pathlib import Path

# Import sync functions
sys.path.append('/home/openclaw/.openclaw/workspace/scripts')
from sync_clawhub_git import sync_to_git, sync_to_clawhub, log, validate_skill

CLAWHUB_DIR = Path("/home/openclaw/.openclaw/workspace/skills")
GIT_DIR = Path("/home/openclaw/.openclaw/workspace/git/skills")

def sync_all_skills(dry_run=True):
    """Synchronisiert alle Skills"""
    # Alle Skills finden
    all_skills = set()
    if CLAWHUB_DIR.exists():
        all_skills.update(d.name for d in CLAWHUB_DIR.iterdir() if d.is_dir() and not d.name.startswith('.'))
    if GIT_DIR.exists():
        all_skills.update(d.name for d in GIT_DIR.iterdir() if d.is_dir() and not d.name.startswith('.'))
    
    log(f"Bulk Sync: {len(all_skills)} Skills gefunden")
    
    results = {
        "synced": [],
        "skipped": [],
        "failed": []
    }
    
    for skill in sorted(all_skills):
        clawhub_path = CLAWHUB_DIR / skill
        git_path = GIT_DIR / skill
        
        try:
            # Nur in ClawHub → zu Git
            if clawhub_path.exists() and not git_path.exists():
                if validate_skill(clawhub_path):
                    log(f"Syncing {skill} to Git...")
                    if sync_to_git(skill, dry_run):
                        results["synced"].append(f"{skill} → Git")
                    else:
                        results["failed"].append(skill)
                else:
                    results["skipped"].append(f"{skill} (validation failed)")
            
            # Nur in Git → zu ClawHub
            elif git_path.exists() and not clawhub_path.exists():
                if validate_skill(git_path):
                    log(f"Syncing {skill} to ClawHub...")
                    if sync_to_clawhub(skill, dry_run):
                        results["synced"].append(f"{skill} → ClawHub")
                    else:
                        results["failed"].append(skill)
                else:
                    results["skipped"].append(f"{skill} (validation failed)")
            
            # In beiden - prüfe ob Update nötig
            elif clawhub_path.exists() and git_path.exists():
                # Vereinfachte Prüfung
                clawhub_mtime = max(p.stat().st_mtime for p in clawhub_path.rglob('*') if p.is_file())
                git_mtime = max(p.stat().st_mtime for p in git_path.rglob('*') if p.is_file() and '.git' not in str(p))
                
                if abs(clawhub_mtime - git_mtime) > 60:
                    if clawhub_mtime > git_mtime:
                        log(f"Updating {skill} in Git...")
                        if sync_to_git(skill, dry_run):
                            results["synced"].append(f"{skill} → Git (update)")
                        else:
                            results["failed"].append(skill)
                    else:
                        log(f"Updating {skill} in ClawHub...")
                        if sync_to_clawhub(skill, dry_run):
                            results["synced"].append(f"{skill} → ClawHub (update)")
                        else:
                            results["failed"].append(skill)
                else:
                    results["skipped"].append(f"{skill} (already synced)")
                    
        except Exception as e:
            log(f"Error processing {skill}: {e}", "ERROR")
            results["failed"].append(skill)
    
    # Zusammenfassung
    print("\n" + "=" * 60)
    print(f"Bulk Sync {'DRY-RUN' if dry_run else 'EXECUTED'} - Zusammenfassung")
    print("=" * 60)
    print(f"✅ Synchronisiert: {len(results['synced'])}")
    for item in results["synced"]:
        print(f"   - {item}")
    print(f"\n⏭️  Übersprungen: {len(results['skipped'])}")
    if len(results["skipped"]) <= 10:
        for item in results["skipped"]:
            print(f"   - {item}")
    else:
        print(f"   - {len(results['skipped'])} Skills (bereits synchron oder Validierung fehlgeschlagen)")
    print(f"\n❌ Fehlgeschlagen: {len(results['failed'])}")
    for item in results["failed"]:
        print(f"   - {item}")
    print("=" * 60)

def main():
    """Hauptfunktion"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Bulk Sync für alle Skills')
    parser.add_argument('--dry-run', action='store_true', help='Nur Änderungen anzeigen')
    parser.add_argument('--execute', action='store_true', help='Sync ausführen')
    
    args = parser.parse_args()
    
    if not args.dry_run and not args.execute:
        print("Bitte --dry-run oder --execute angeben")
        sys.exit(1)
    
    sync_all_skills(dry_run=args.dry_run)

if __name__ == "__main__":
    main()
'@

# Speichere das Skript temporär und führe es aus
$tempFile = [System.IO.Path]::GetTempFileName() + ".py"
$pythonScript | Set-Content $tempFile -Encoding UTF8
try {
    & python3 $tempFile @args
} finally {
    Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
}
