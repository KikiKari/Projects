#!/usr/bin/env bash
# sync_agent.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:skills/clawhub-git-sync-agent/scripts/sync_agent.py
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Permanenter ClawHub ↔ Git Sync Agent
# Multi-Node fähig, stündliche Ausführung

# Konfiguration
readonly CLAWHUB_DIR="/home/openclaw/.openclaw/workspace/skills"
readonly GIT_DIR="/home/openclaw/.openclaw/workspace/git/skills"
readonly STATE_FILE="/home/openclaw/.openclaw/workspace/db/sync_state.json"
readonly BACKUP_ROOT="/home/openclaw/.openclaw/workspace/backups/sync_agent"
readonly SCRIPTS_DIR="/home/openclaw/.openclaw/workspace/scripts"

# Lade externe Funktionen
source "${SCRIPTS_DIR}/sync_clawhub_git.sh"

# Farben für Logging
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Globale Variablen
declare -A RESULTS
declare DRY_RUN=false

log() {
    local level="${2:-INFO}"
    local color=""
    
    case "$level" in
        ERROR) color="$RED" ;;
        WARN)  color="$YELLOW" ;;
        INFO)  color="$GREEN" ;;
        *)     color="" ;;
    esac
    
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') [$level] ${color}$1${NC}" >&2
}

load_state() {
    if [[ -f "$STATE_FILE" ]]; then
        cat "$STATE_FILE"
    else
        echo '{"sync_history":[],"pending":[]}'
    fi
}

save_state() {
    local state="$1"
    mkdir -p "$(dirname "$STATE_FILE")"
    echo "$state" > "$STATE_FILE"
}

get_all_skills() {
    local skills=()
    
    # Skills aus ClawHub
    while IFS= read -r dir; do
        if [[ -d "$dir" && ! "$(basename "$dir")" =~ ^[._] ]] && [[ -f "$dir/SKILL.md" ]]; then
            skills+=("$(basename "$dir")")
        fi
    done < <(find "$CLAWHUB_DIR" -mindepth 1 -maxdepth 1 -type d)
    
    # Skills aus Git
    while IFS= read -r dir; do
        if [[ -d "$dir" && ! "$(basename "$dir")" =~ ^[._] ]] && [[ -f "$dir/SKILL.md" ]]; then
            skills+=("$(basename "$dir")")
        fi
    done < <(find "$GIT_DIR" -mindepth 1 -maxdepth 1 -type d)
    
    # Entferne Duplikate und sortiere
    printf '%s\n' "${skills[@]}" | sort -u
}

init_git_repo() {
    local skill_path="$1"
    local skill_name="$2"
    local git_dir="${skill_path}/.git"
    
    if [[ ! -d "$git_dir" ]]; then
        (
            cd "$skill_path" || exit 1
            git init >/dev/null 2>&1
            git add . >/dev/null 2>&1
            git commit -m "Initial commit: ${skill_name} skill" >/dev/null 2>&1
        )
        log "Git initialized for $skill_name"
    fi
}

backup_skill_dir() {
    local skill_path="$1"
    local skill_name="$2"
    
    if [[ ! -d "$skill_path" ]]; then
        return
    fi
    
    local timestamp
    timestamp=$(date "+%Y%m%d%H%M%S")
    local backup_dir="${BACKUP_ROOT}/${timestamp}"
    mkdir -p "$backup_dir"
    local archive_name="${skill_name}_${timestamp}.tar.gz"
    local archive_path="${backup_dir}/${archive_name}"
    
    tar -czf "$archive_path" -C "$skill_path" . >/dev/null 2>&1
    log "Backup created for $skill_name at $archive_path"
}

get_hashes() {
    local skill_dir="$1"
    local temp_file
    temp_file=$(mktemp)
    
    find "$skill_dir" -type f ! -path "*/.git/*" -exec md5sum {} \; | \
        sed "s|${skill_dir}/||" | sort > "$temp_file"
    
    echo "$temp_file"
}

sync_skill_bidirectional() {
    local skill_name="$1"
    local clawhub_path="${CLAWHUB_DIR}/${skill_name}"
    local git_path="${GIT_DIR}/${skill_name}"
    
    # Fall 1: Nur in ClawHub → zu Git
    if [[ -d "$clawhub_path" ]] && [[ ! -d "$git_path" ]]; then
        log "NEW in ClawHub: $skill_name → syncing to Git"
        if [[ "$DRY_RUN" != true ]]; then
            backup_skill_dir "$clawhub_path" "${skill_name}_clawhub"
        fi
        if sync_to_git "$skill_name" "$DRY_RUN"; then
            if [[ "$DRY_RUN" != true ]]; then
                init_git_repo "$git_path" "$skill_name"
            fi
            echo "synced_to_git"
            return
        fi
        
    # Fall 2: Nur in Git → zu ClawHub
    elif [[ -d "$git_path" ]] && [[ ! -d "$clawhub_path" ]]; then
        log "NEW in Git: $skill_name → syncing to ClawHub"
        if [[ "$DRY_RUN" != true ]]; then
            backup_skill_dir "$git_path" "${skill_name}_git"
        fi
        if sync_to_clawhub "$skill_name" "$DRY_RUN"; then
            echo "synced_to_clawhub"
            return
        fi
        
    # Fall 3: In beiden vorhanden → Vergleiche Inhalte
    elif [[ -d "$clawhub_path" ]] && [[ -d "$git_path" ]]; then
        # Validierung
        if ! validate_skill "$clawhub_path"; then
            log "Validation failed for ClawHub skill: $skill_name" "ERROR"
            echo "error"
            return
        fi
        if ! validate_skill "$git_path"; then
            log "Validation failed for Git skill: $skill_name" "ERROR"
            echo "error"
            return
        fi
        
        # Hash-Berechnung
        local clawhub_hash_file git_hash_file
        clawhub_hash_file=$(get_hashes "$clawhub_path")
        git_hash_file=$(get_hashes "$git_path")
        
        if ! cmp -s "$clawhub_hash_file" "$git_hash_file"; then
            log "Content difference detected for: $skill_name"
            
            # Entscheide Richtung basierend auf Modifikationszeit
            local clawhub_mtime git_mtime direction
            clawhub_mtime=$(stat -c %Y "$clawhub_path")
            git_mtime=$(stat -c %Y "$git_path")
            
            if [[ $clawhub_mtime -ge $git_mtime ]]; then
                direction="to-git"
            else
                direction="to-clawhub"
            fi
            
            log "UPDATE: $skill_name → syncing $direction"
            
            if [[ "$DRY_RUN" != true ]]; then
                backup_skill_dir "$clawhub_path" "${skill_name}_clawhub"
                backup_skill_dir "$git_path" "${skill_name}_git"
            fi
            
            if [[ "$direction" == "to-git" ]]; then
                if sync_to_git "$skill_name" "$DRY_RUN"; then
                    if [[ "$DRY_RUN" != true ]]; then
                        (
                            cd "$git_path" || exit 1
                            git add . >/dev/null 2>&1
                            git commit -m "Sync from ClawHub content diff: $(date '+%Y-%m-%d %H:%M')" >/dev/null 2>&1
                        )
                    fi
                    echo "updated_git"
                    rm -f "$clawhub_hash_file" "$git_hash_file"
                    return
                fi
            else
                if sync_to_clawhub "$skill_name" "$DRY_RUN"; then
                    echo "updated_clawhub"
                    rm -f "$clawhub_hash_file" "$git_hash_file"
                    return
                fi
            fi
            
            log "Failed to sync $skill_name to Git after content diff" "ERROR"
            echo "error"
            rm -f "$clawhub_hash_file" "$git_hash_file"
            return
        else
            log "Content is identical for: $skill_name"
            echo "no_change"
            rm -f "$clawhub_hash_file" "$git_hash_file"
            return
        fi
        
        rm -f "$clawhub_hash_file" "$git_hash_file"
    fi
    
    echo "no_change"
}

main() {
    # Parse Argumente
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            *)
                echo "Unbekannte Option: $1" >&2
                exit 1
                ;;
        esac
    done
    
    log "=== ClawHub ↔ Git Sync Agent gestartet ==="
    
    # Initialisiere Ergebnis-Arrays
    RESULTS[synced_to_git]=""
    RESULTS[synced_to_clawhub]=""
    RESULTS[updated_git]=""
    RESULTS[updated_clawhub]=""
    RESULTS[no_change]=""
    RESULTS[errors]=""
    
    local state
    state=$(load_state)
    local all_skills
    mapfile -t all_skills < <(get_all_skills)
    log "Gefundene Skills: ${#all_skills[@]}"
    
    local skill result
    
    for skill in "${all_skills[@]}"; do
        if result=$(sync_skill_bidirectional "$skill"); then
            case "$result" in
                synced_to_git)     RESULTS[synced_to_git]+="$skill " ;;
                synced_to_clawhub) RESULTS[synced_to_clawhub]+="$skill " ;;
                updated_git)       RESULTS[updated_git]+="$skill " ;;
                updated_clawhub)   RESULTS[updated_clawhub]+="$skill " ;;
                no_change)         RESULTS[no_change]+="$skill " ;;
                error)             RESULTS[errors]+="$skill " ;;
                *)                 RESULTS[errors]+="$skill " ;;
            esac
        else
            log "ERROR syncing $skill: $result" "ERROR"
            RESULTS[errors]+="$skill "
        fi
    done
    
    # Zusammenfassung
    log "\n=== SYNC ZUSAMMENFASSUNG ==="
    log "Neu in Git: $(echo "${RESULTS[synced_to_git]}" | wc -w) - ${RESULTS[synced_to_git]}"
    log "Neu in ClawHub: $(echo "${RESULTS[synced_to_clawhub]}" | wc -w) - ${RESULTS[synced_to_clawhub]}"
    log "Git aktualisiert: $(echo "${RESULTS[updated_git]}" | wc -w) - ${RESULTS[updated_git]}"
    log "ClawHub aktualisiert: $(echo "${RESULTS[updated_clawhub]}" | wc -w) - ${RESULTS[updated_clawhub]}"
    log "Keine Änderung: $(echo "${RESULTS[no_change]}" | wc -w)"
    log "Fehler: $(echo "${RESULTS[errors]}" | wc -w) - ${RESULTS[errors]}"
    
    # Speichere State wenn kein Dry-Run
    if [[ "$DRY_RUN" != true ]]; then
        # Aktualisiere History (vereinfachte Implementierung)
        local new_entry
        new_entry=$(printf '{"timestamp":"%s","results":{"synced_to_git":[%s],"synced_to_clawhub":[%s],"updated_git":[%s],"updated_clawhub":[%s],"no_change":[%s],"errors":[%s]}}' \
            "$(date -Iseconds)" \
            "$(echo "${RESULTS[synced_to_git]}" | xargs -n1 | sed 's/.*/"&"/' | tr '\n' ',' | sed 's/,$//')" \
            "$(echo "${RESULTS[synced_to_clawhub]}" | xargs -n1 | sed 's/.*/"&"/' | tr '\n' ',' | sed 's/,$//')" \
            "$(echo "${RESULTS[updated_git]}" | xargs -n1 | sed 's/.*/"&"/' | tr '\n' ',' | sed 's/,$//')" \
            "$(echo "${RESULTS[updated_clawhub]}" | xargs -n1 | sed 's/.*/"&"/' | tr '\n' ',' | sed 's/,$//')" \
            "$(echo "${RESULTS[no_change]}" | xargs -n1 | sed 's/.*/"&"/' | tr '\n' ',' | sed 's/,$//')" \
            "$(echo "${RESULTS[errors]}" | xargs -n1 | sed 's/.*/"&"/' | tr '\n' ',' | sed 's/,$//')")
        
        # Füge neuen Eintrag hinzu und begrenze auf 100
        local updated_state
        updated_state=$(echo "$state" | jq --argjson entry "$new_entry" '
            .sync_history |= (. + [$entry] | .[-100:])
        ')
        save_state "$updated_state"
    fi
    
    log "=== Sync Agent beendet ==="
}

main "$@"
