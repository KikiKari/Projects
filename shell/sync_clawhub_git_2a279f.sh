#!/bin/bash
# sync_clawhub_git.py — portiert nach shell
# Quelle: python, OpenClaw@gateway2:scripts/sync_clawhub_git.py
# auch in: Projects@clawhub:clawhub/Skills/sync_clawhub_git.py
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Bidirektionale ClawHub ↔ Git Synchronisation

# Konfiguration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(realpath "$SCRIPT_DIR/../")"
CLAWHUB_DIR="$WORKSPACE_ROOT/skills"
GIT_DIR="$WORKSPACE_ROOT/git/skills"
BACKUP_DIR="$WORKSPACE_ROOT/backups/sync"
LOG_FILE="$WORKSPACE_ROOT/logs/sync-agent.log"

# Erstelle Verzeichnisse
mkdir -p "$GIT_DIR" "$BACKUP_DIR" "$(dirname "$LOG_FILE")"

# Logging
log() {
    local message="$1"
    local level="${2:-INFO}"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local entry="[$timestamp] [$level] $message"
    echo "$entry"
    echo "$entry" >> "$LOG_FILE"
}

# Validierung
validate_skill() {
    local skill_dir="$1"
    local skill_name
    skill_name=$(basename "$skill_dir")
    
    case "$skill_name" in
        github-clones|skills|backups|.restore|git|Abstraktionen)
            log "Validation failed: $skill_name is reserved and must not be synced as a skill" "ERROR"
            return 1
            ;;
    esac
    
    if [[ ! -f "$skill_dir/SKILL.md" ]]; then
        log "Validation failed: $skill_name missing SKILL.md" "ERROR"
        return 1
    fi
    
    return 0
}

_is_ignored_path() {
    local path="$1"
    local IFS='/'
    read -ra PARTS <<< "$path"
    for part in "${PARTS[@]}"; do
        case "$part" in
            .git|.clawhub|node_modules|__pycache__|.pytest_cache|*.pyc)
                return 0
                ;;
        esac
    done
    return 1
}

_is_generated_duplicate_path() {
    local root="$1"
    local rel_path="$2"
    
    local IFS='/'
    read -ra PARTS <<< "$rel_path"
    
    if [[ ${#PARTS[@]} -eq 0 ]]; then
        return 1
    fi
    
    if [[ "${PARTS[0]}" == "$(basename "$root")" ]]; then
        return 0
    fi
    
    local i
    for ((i=1; i<${#PARTS[@]}; i++)); do
        if [[ "${PARTS[$i]}" == "${PARTS[$((i-1))]}" ]]; then
            return 0
        fi
    done
    
    return 1
}

iter_sync_files() {
    local root="$1"
    local current_root
    local rel_root
    local dir
    local file
    local file_path
    local rel_path
    
    while IFS= read -r -d '' current_root; do
        rel_root="${current_root#$root}"
        if [[ "$rel_root" == /* ]]; then
            rel_root="${rel_root#/}"
        fi
        
        if _is_ignored_path "$rel_root"; then
            continue
        fi
        
        while IFS= read -r -d '' file; do
            case "$file" in
                .git|.clawhub|node_modules|__pycache__|.pytest_cache|*.pyc)
                    continue
                    ;;
            esac
            
            file_path="$current_root/$file"
            rel_path="${file_path#$root}"
            if [[ "$rel_path" == /* ]]; then
                rel_path="${rel_path#/}"
            fi
            
            if _is_ignored_path "$rel_path"; then
                continue
            fi
            
            if _is_generated_duplicate_path "$root" "$rel_path"; then
                continue
            fi
            
            if [[ "$file" == "SKILL.md" ]] && [[ "$rel_path" != "SKILL.md" ]]; then
                continue
            fi
            
            if [[ -f "$file_path" ]]; then
                printf '%s\0%s\n' "$file_path" "$rel_path"
            fi
        done < <(find "$current_root" -maxdepth 1 -type f -print0 2>/dev/null || true)
    done < <(find "$root" -type d -print0 2>/dev/null || true)
}

reset_sync_target() {
    local target="$1"
    mkdir -p "$target"
    
    local item
    for item in "$target"/*; do
        [[ -e "$item" ]] || continue
        local basename_item
        basename_item=$(basename "$item")
        case "$basename_item" in
            .git|.clawhub|node_modules|__pycache__|.pytest_cache)
                continue
                ;;
        esac
        
        if [[ -d "$item" ]] && [[ ! -L "$item" ]]; then
            rm -rf "$item"
        elif [[ -f "$item" ]] || [[ -L "$item" ]]; then
            rm -f "$item"
        fi
    done
}

copy_sync_files() {
    local source="$1"
    local target="$2"
    
    reset_sync_target "$target"
    
    local file_info
    while IFS=$'\n' read -r file_info; do
        local src_file
        local rel_path
        src_file=$(echo "$file_info" | cut -d$'\0' -f1)
        rel_path=$(echo "$file_info" | cut -d$'\0' -f2)
        
        local dest_file="$target/$rel_path"
        mkdir -p "$(dirname "$dest_file")"
        cp -p "$src_file" "$dest_file"
    done < <(iter_sync_files "$source")
}

create_backup() {
    local source="$1"
    local skill_name="$2"
    local timestamp
    timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_path="$BACKUP_DIR/${skill_name}_$timestamp"
    
    if [[ -d "$backup_path" ]]; then
        rm -rf "$backup_path" || {
            log "Failed to remove existing backup $backup_path" "ERROR"
            return 1
        }
        log "Removed existing backup: $backup_path"
    fi
    
    mkdir -p "$backup_path" || {
        log "Failed to create backup directory $backup_path" "ERROR"
        return 1
    }
    
    local item
    for item in "$source"/*; do
        [[ -e "$item" ]] || continue
        local basename_item
        basename_item=$(basename "$item")
        case "$basename_item" in
            .git|.clawhub|node_modules|__pycache__|.pytest_cache|*.pyc)
                continue
                ;;
        esac
        
        if [[ -d "$item" ]]; then
            cp -rp "$item" "$backup_path/" || {
                log "Failed to copy directory $item to backup" "ERROR"
                return 1
            }
        elif [[ -f "$item" ]]; then
            cp -p "$item" "$backup_path/" || {
                log "Failed to copy file $item to backup" "ERROR"
                return 1
            }
        fi
    done
    
    log "Backup created: $backup_path"
    return 0
}

get_file_hash() {
    local file_path="$1"
    if [[ ! -f "$file_path" ]]; then
        echo ""
        return
    fi
    
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$file_path" | cut -d' ' -f1
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$file_path" | cut -d' ' -f1
    else
        log "No SHA256 utility found" "ERROR"
        echo ""
    fi
}

sync_to_git() {
    local skill_name="$1"
    local dry_run="${2:-true}"
    local source="$CLAWHUB_DIR/$skill_name"
    local target="$GIT_DIR/$skill_name"
    
    validate_skill "$source" || return 1
    
    if [[ "$dry_run" != "true" ]] && [[ -d "$target" ]]; then
        create_backup "$target" "$skill_name" || return 1
    fi
    
    local changes=()
    local file_info
    while IFS=$'\n' read -r file_info; do
        local src_file
        local rel_path
        src_file=$(echo "$file_info" | cut -d$'\0' -f1)
        rel_path=$(echo "$file_info" | cut -d$'\0' -f2)
        
        local tgt_file="$target/$rel_path"
        if [[ ! -e "$tgt_file" ]]; then
            changes+=("ADD $rel_path")
        else
            local src_hash
            local tgt_hash
            src_hash=$(get_file_hash "$src_file")
            tgt_hash=$(get_file_hash "$tgt_file")
            if [[ "$src_hash" != "$tgt_hash" ]]; then
                changes+=("UPDATE $rel_path")
            fi
        fi
    done < <(iter_sync_files "$source")
    
    if [[ "$dry_run" == "true" ]]; then
        log "DRY-RUN: $skill_name - ${#changes[@]} changes"
        local change
        for change in "${changes[@]}"; do
            log "  $change"
        done
        return 0
    fi
    
    log "SYNC: $skill_name - Applying ${#changes[@]} changes"
    copy_sync_files "$source" "$target"
    log "SYNC: $skill_name - Complete"
    return 0
}

sync_to_clawhub() {
    local skill_name="$1"
    local dry_run="${2:-true}"
    local source="$GIT_DIR/$skill_name"
    local target="$CLAWHUB_DIR/$skill_name"
    
    validate_skill "$source" || return 1
    
    if [[ "$dry_run" != "true" ]] && [[ -d "$target" ]]; then
        create_backup "$target" "$skill_name" || return 1
    fi
    
    local changes=()
    local file_info
    while IFS=$'\n' read -r file_info; do
        local src_file
        local rel_path
        src_file=$(echo "$file_info" | cut -d$'\0' -f1)
        rel_path=$(echo "$file_info" | cut -d$'\0' -f2)
        
        local tgt_file="$target/$rel_path"
        if [[ ! -e "$tgt_file" ]]; then
            changes+=("ADD $rel_path")
        else
            local src_hash
            local tgt_hash
            src_hash=$(get_file_hash "$src_file")
            tgt_hash=$(get_file_hash "$tgt_file")
            if [[ "$src_hash" != "$tgt_hash" ]]; then
                changes+=("UPDATE $rel_path")
            fi
        fi
    done < <(iter_sync_files "$source")
    
    if [[ "$dry_run" == "true" ]]; then
        log "DRY-RUN: $skill_name - ${#changes[@]} changes"
        local change
        for change in "${changes[@]}"; do
            log "  $change"
        done
        return 0
    fi
    
    log "SYNC: $skill_name - Applying ${#changes[@]} changes"
    copy_sync_files "$source" "$target"
    log "SYNC: $skill_name - Complete"
    return 0
}

main() {
    local skill=""
    local direction=""
    local dry_run=true
    local force=false
    
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
    
    if [[ -z "$skill" ]] || [[ -z "$direction" ]]; then
        echo "Error: --skill and --direction are required" >&2
        exit 1
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
