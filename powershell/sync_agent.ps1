#!/usr/bin/env pwsh
# sync_agent.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway2:skills/clawhub-git-sync-agent/scripts/sync_agent.py
# Erzeugt: 2026-11-06 durch ABSTRACTIONS_MANAGER.py

<#
Permanenter ClawHub ↔ Git Sync Agent
Multi-Node fähig, stündliche Ausführung
#>

# Import sync functions
$scriptPath = "/home/openclaw/.openclaw/workspace/scripts"
$env:PYTHONPATH = $scriptPath
& python3 -c @"
import sys
sys.path.append('$scriptPath')
from sync_clawhub_git import sync_to_git, sync_to_clawhub, log, validate_skill, get_file_hash, iter_sync_files, RESERVED_SKILL_NAMES
import json

CLAWHUB_DIR = '/home/openclaw/.openclaw/workspace/skills'
GIT_DIR = '/home/openclaw/.openclaw/workspace/git/skills'
STATE_FILE = '/home/openclaw/.openclaw/workspace/db/sync_state.json'

def load_state():
    try:
        with open(STATE_FILE, 'r') as f:
            return json.load(f)
    except:
        return {'sync_history': [], 'pending': []}

def save_state(state):
    import os
    os.makedirs(os.path.dirname(STATE_FILE), exist_ok=True)
    with open(STATE_FILE, 'w') as f:
        json.dump(state, f, indent=2)

def get_all_skills():
    import os
    clawhub_skills = set()
    git_skills = set()
    
    if os.path.exists(CLAWHUB_DIR):
        for item in os.listdir(CLAWHUB_DIR):
            path = os.path.join(CLAWHUB_DIR, item)
            if os.path.isdir(path) and not item.startswith('.') and item not in RESERVED_SKILL_NAMES and os.path.exists(os.path.join(path, 'SKILL.md')):
                clawhub_skills.add(item)
                
    if os.path.exists(GIT_DIR):
        for item in os.listdir(GIT_DIR):
            path = os.path.join(GIT_DIR, item)
            if os.path.isdir(path) and not item.startswith('.') and item not in RESERVED_SKILL_NAMES and os.path.exists(os.path.join(path, 'SKILL.md')):
                git_skills.add(item)
                
    return clawhub_skills.union(git_skills)

def init_git_repo(skill_path, skill_name):
    import subprocess
    git_dir = os.path.join(skill_path, '.git')
    if not os.path.exists(git_dir):
        os.chdir(skill_path)
        subprocess.run(['git', 'init'], capture_output=True)
        subprocess.run(['git', 'add', '.'], capture_output=True)
        subprocess.run(['git', 'commit', '-m', f'Initial commit: {skill_name} skill'], capture_output=True)
        log(f'Git initialized for {skill_name}')

def get_hashes(skill_dir):
    hashes = {}
    for file_path, rel_path in iter_sync_files(skill_dir):
        hashes[str(rel_path)] = get_file_hash(file_path)
    return hashes

def preview_changes(source_dir, target_dir):
    changes = []
    for src_file, rel_path in iter_sync_files(source_dir):
        tgt_file = os.path.join(target_dir, str(rel_path))
        if not os.path.exists(tgt_file):
            changes.append(f'ADD {rel_path}')
        elif get_file_hash(src_file) != get_file_hash(tgt_file):
            changes.append(f'UPDATE {rel_path}')
    return changes

def newest_mtime(skill_dir):
    mtimes = []
    for file_path, _ in iter_sync_files(skill_dir):
        mtimes.append(os.path.getmtime(file_path))
    return max(mtimes) if mtimes else 0.0

def sync_skill_bidirectional(skill_name):
    clawhub_path = os.path.join(CLAWHUB_DIR, skill_name)
    git_path = os.path.join(GIT_DIR, skill_name)
    
    if os.path.exists(clawhub_path) and not os.path.exists(git_path):
        log(f'NEW in ClawHub: {skill_name} → syncing to Git')
        if sync_to_git(skill_name, dry_run=False):
            init_git_repo(git_path, skill_name)
            return 'synced_to_git'
            
    elif os.path.exists(git_path) and not os.path.exists(clawhub_path):
        log(f'NEW in Git: {skill_name} → syncing to ClawHub')
        if sync_to_clawhub(skill_name, dry_run=False):
            return 'synced_to_clawhub'
            
    elif os.path.exists(clawhub_path) and os.path.exists(git_path):
        if not validate_skill(clawhub_path):
            log(f'Validation failed for ClawHub skill: {skill_name}', 'ERROR')
            return 'error'
        if not validate_skill(git_path):
            log(f'Validation failed for Git skill: {skill_name}', 'ERROR')
            return 'error'

        clawhub_changes = preview_changes(clawhub_path, git_path)
        git_changes = preview_changes(git_path, clawhub_path)

        if not clawhub_changes and not git_changes:
            log(f'Content is identical for: {skill_name}')
            return 'no_change'

        if clawhub_changes and not git_changes:
            log(f'Content difference detected for: {skill_name}')
            log(f'UPDATE: {skill_name} ClawHub content is newer or different → syncing to Git')
            if sync_to_git(skill_name, dry_run=False):
                os.chdir(git_path)
                subprocess.run(['git', 'add', '.'], capture_output=True)
                subprocess.run(['git', 'commit', '-m', f'Sync from ClawHub content diff: {datetime.datetime.now().strftime(\"%Y-%m-%d %H:%M\")}'], capture_output=True)
                return 'updated_git'
            log(f'Failed to sync {skill_name} to Git after content diff', 'ERROR')
            return 'error'

        if git_changes and not clawhub_changes:
            log(f'Content difference detected for: {skill_name}')
            log(f'UPDATE: {skill_name} Git content is newer or different → syncing to ClawHub')
            if sync_to_clawhub(skill_name, dry_run=False):
                return 'updated_clawhub'
            log(f'Failed to sync {skill_name} to ClawHub after content diff', 'ERROR')
            return 'error'

        log(f'Content difference detected for: {skill_name}')
        if newest_mtime(clawhub_path) >= newest_mtime(git_path):
            log(f'UPDATE: {skill_name} ClawHub content is newer or different → syncing to Git')
            if sync_to_git(skill_name, dry_run=False):
                os.chdir(git_path)
                subprocess.run(['git', 'add', '.'], capture_output=True)
                subprocess.run(['git', 'commit', '-m', f'Sync from ClawHub content diff: {datetime.datetime.now().strftime(\"%Y-%m-%d %H:%M\")}'], capture_output=True)
                return 'updated_git'
        else:
            log(f'UPDATE: {skill_name} Git content is newer or different → syncing to ClawHub')
            if sync_to_clawhub(skill_name, dry_run=False):
                return 'updated_clawhub'

        log(f'Failed to resolve content diff for {skill_name}', 'ERROR')
        return 'error'
        
    return 'no_change'

def main():
    import datetime
    log('=== ClawHub ↔ Git Sync Agent gestartet ===')
    
    state = load_state()
    all_skills = get_all_skills()
    log(f'Gefundene Skills: {len(all_skills)}')
    
    log('--- Dry-Run Phase Start ---')
    for skill in sorted(all_skills):
        sync_to_git(skill, dry_run=True)
        sync_to_clawhub(skill, dry_run=True)
    log('--- Dry-Run Phase End ---')
    
    results = {
        'synced_to_git': [],
        'synced_to_clawhub': [],
        'updated_git': [],
        'updated_clawhub': [],
        'no_change': [],
        'errors': []
    }
    
    for skill in sorted(all_skills):
        try:
            result = sync_skill_bidirectional(skill)
            results[result].append(skill)
        except Exception as e:
            log(f'ERROR syncing {skill}: {e}', 'ERROR')
            results['errors'].append(skill)
    
    log('\n=== SYNC ZUSAMMENFASSUNG ===')
    log(f'Neu in Git: {len(results[\"synced_to_git\"])} - {results[\"synced_to_git\"]}')
    log(f'Neu in ClawHub: {len(results[\"synced_to_clawhub\"])} - {results[\"synced_to_clawhub\"]}')
    log(f'Git aktualisiert: {len(results[\"updated_git\"])} - {results[\"updated_git\"]}')
    log(f'ClawHub aktualisiert: {len(results[\"updated_clawhub\"])} - {results[\"updated_clawhub\"]}')
    log(f'Keine Änderung: {len(results[\"no_change\"])}')
    log(f'Fehler: {len(results[\"errors\"])} - {results[\"errors\"]}')
    
    if 'sync_history' not in state:
        state['sync_history'] = []
    state['sync_history'].append({
        'timestamp': datetime.datetime.now().isoformat(),
        'results': results
    })
    state['sync_history'] = state['sync_history'][-100:]
    save_state(state)
    
    log('=== Sync Agent beendet ===\n')

if __name__ == '__main__':
    main()
"@
