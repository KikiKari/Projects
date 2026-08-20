#!/usr/bin/env bash
# sync_clawhub_git.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:scripts/sync_clawhub_git.py
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Bidirektionale ClawHub ↔ Git Synchronisation

# Konfiguration
readonly CLAWHUB_DIR="/home/openclaw/.openclaw/workspace/skills"
readonly GIT_DIR="/home/openclaw/.openclaw/workspace/git/skills"
readonly BACKUP_DIR="/home/openclaw/.openclaw/workspace/backups/sync"
readonly LOG_FILE="/home/openclaw/.openclaw/workspace/logs/sync-agent.log"

# Erstelle Verzeichnisse
mkdir -p "$GIT_DIR" "$BACKUP_DIR" "$(dirname "$LOG_FILE")"

# Logging
log() {
    local message="$1"
    local level="${2:-INFO}"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local entry="[${timestamp}] [${level}] ${message}"
    echo "$entry"
    echo "$entry" >> "$LOG_FILE"
}

# Validierung
validate_skill() {
    local skill_dir="$1"
    if [[ ! -f "${skill_dir}/SKILL.md" ]]; then
        log "Validation failed: $(basename "$skill_dir") missing SKILL.md" "ERROR"
        return 1
    fi
    return 0
}

# Backup
create_backup() {
    local source="$1"
    local skill_name="$2"
    local timestamp
    timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_path="${BACKUP_DIR}/${skill_name}_${timestamp}"
    
    # Backup verzeichnis löschen falls es existiert
    if [[ -d "$backup_path" ]]; then
        if rm -rf "$backup_path"; then
            log "Removed existing backup: $backup_path"
        else
            log "Failed to remove existing backup $backup_path" "ERROR"
            return 1
        fi
    fi
    
    if cp -r "$source" "$backup_path"; then
        log "Backup created: $backup_path"
        return 0
    else
        log "Backup failed" "ERROR"
        return 1
    fi
}

# Hash-Vergleich
get_file_hash() {
    local file_path="$1"
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$file_path" | cut -d' ' -f1
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$file_path" | cut -d' ' -f1
    else
        log "No SHA256 tool found" "ERROR"
        exit 1
    fi
}

# Sync Richtung ClawHub → Git
sync_to_git() {
    local skill_name="$1"
    local dry_run="${2:-true}"
    local source="${CLAWHUB_DIR}/${skill_name}"
    local target="${GIT_DIR}/${skill_name}"
    
    if ! validate_skill "$source"; then
        return 1
    fi
    
    # Backup vor Änderungen (nur wenn target existiert)
    if [[ "$dry_run" == false ]] && [[ -d "$target" ]]; then
        create_backup "$target" "$skill_name" || return 1
    fi
    
    # Änderungen erkennen
    local changes=()
    while IFS= read -r -d '' file; do
        local rel_path="${file#$source/}"
        local src_file="$file"
        local tgt_file="${target}/${rel_path}"
        
        # Vergleich
        if [[ ! -f "$tgt_file" ]]; then
            changes+=("ADD ${rel_path}")
        elif [[ $(get_file_hash "$src_file") != $(get_file_hash "$tgt_file") ]]; then
            changes+=("UPDATE ${rel_path}")
        fi
    done < <(find "$source" -type f -print0)
    
    # Dry-Run Report
    if [[ "$dry_run" == true ]]; then
        log "DRY-RUN: ${skill_name} - ${#changes[@]} changes"
        for change in "${changes[@]}"; do
            log "  ${change}"
        done
        return 0
    fi
    
    # Echte Synchronisation
    log "SYNC: ${skill_name} - Applying ${#changes[@]} changes"
    if [[ -d "$target" ]]; then
        rsync -av --delete --exclude='.git' "$source/" "$target/"
    else
        mkdir -p "$target"
        rsync -av --exclude='.git' "$source/" "$target/"
    fi
    log "SYNC: ${skill_name} - Complete"
    return 0
}

# Sync Richtung Git → ClawHub
sync_to_clawhub() {
    local skill_name="$1"
    local dry_run="${2:-true}"
    local source="${GIT_DIR}/${skill_name}"
    local target="${CLAWHUB_DIR}/${skill_name}"
    
    if ! validate_skill "$source"; then
        return 1
    fi
    
    # Backup vor Änderungen (nur wenn target existiert)
    if [[ "$dry_run" == false ]] && [[ -d "$target" ]]; then
        create_backup "$target" "$skill_name" || return 1
    fi
    
    # Änderungen erkennen
    local changes=()
    while IFS= read -r -d '' file; do
        local rel_path="${file#$source/}"
        local src_file="$file"
        local tgt_file="${target}/${rel_path}"
        
        # Vergleich
        if [[ ! -f "$tgt_file" ]]; then
            changes+=("ADD ${rel_path}")
        elif [[ $(get_file_hash "$src_file") != $(get_file_hash "$tgt_file") ]]; then
            changes+=("UPDATE ${rel_path}")
        fi
    done < <(find "$source" -type f -print0)
    
    # Dry-Run Report
    if [[ "$dry_run" == true ]]; then
        log "DRY-RUN: ${skill_name} - ${#changes[@]} changes"
        for change in "${changes[@]}"; do
            log "  ${change}"
        done
        return 0
    fi
    
    # Echte Synchronisation
    log "SYNC: ${skill_name} - Applying ${#changes[@]} changes"
    if [[ -d "$target" ]]; then
        rsync -av --delete --exclude='.git' "$source/" "$target/"
    else
        mkdir -p "$target"
        rsync -av --exclude='.git' "$source/" "$target/"
    fi
    log "SYNC: ${skill_name} - Complete"
    return 0
}

# Hauptfunktion
main() {
    local skill=""
    local direction=""
    local dry_run=true
    local force=false
    
    # Argument Parsing
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skill)
                skill="$2"
                shift 2
                ;;
            --direction)
                direction="$2"
                shift 2
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            --force)
                force=true
                shift
                ;;
            *)
                echo "Unknown option: $1" >&2
                exit 1
                ;;
        esac
    done
    
    # Validierung der Parameter
    if [[ -z "$skill" ]] || [[ -z "$direction" ]]; then
        echo "Error: --skill and --direction are required" >&2
        exit 1
    fi
    
    if [[ "$direction" != "to-git" ]] && [[ "$direction" != "to-clawhub" ]]; then
        echo "Error: --direction must be either 'to-git' or 'to-clawhub'" >&2
        exit 1
    fi
    
    if [[ "$force" == true ]]; then
        dry_run=false
    fi
    
    log "Starting sync: $skill ($direction)"
    
    local success=1
    if [[ "$direction" == "to-git" ]]; then
        sync_to_git "$skill" "$dry_run"
        success=$?
    else
        sync_to_clawhub "$skill" "$dry_run"
        success=$?
    fi
    
    if [[ $success -ne 0 ]]; then
        log "Sync failed" "ERROR"
        exit 1
    fi
    
    log "Sync completed"
}

main "$@"
