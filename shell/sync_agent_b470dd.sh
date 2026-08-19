#!/usr/bin/env bash
# sync_agent.py — portiert nach shell
# Quelle: python, OpenClaw@gateway2:skills/clawhub-git-sync-agent/scripts/sync_agent.py
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Permanenter ClawHub ↔ Git Sync Agent
# Multi-Node fähig, stündliche Ausführung

readonly CLAWHUB_DIR="/home/openclaw/.openclaw/workspace/skills"
readonly GIT_DIR="/home/openclaw/.openclaw/workspace/git/skills"
readonly STATE_FILE="/home/openclaw/.openclaw/workspace/db/sync_state.json"
readonly SCRIPTS_DIR="/home/openclaw/.openclaw/workspace/scripts"

# Lade externe Funktionen
source "${SCRIPTS_DIR}/sync_clawhub_git.sh"

# Globale Variablen für Ergebnisse
declare -a synced_to_git_arr=()
declare -a synced_to_clawhub_arr=()
declare -a updated_git_arr=()
declare -a updated_clawhub_arr=()
declare -a no_change_arr=()
declare -a errors_arr=()

load_state() {
    # Lädt den Sync-State
    if [[ -f "$STATE_FILE" ]]; then
        cat "$STATE_FILE"
    else
        echo '{"sync_history": [], "pending": []}'
    fi
}

save_state() {
    local state="$1"
    # Ensure the parent directory exists (handle symlink to existing directory)
    mkdir -p "$(dirname "$STATE_FILE")"
    echo "$state" > "$STATE_FILE"
}

get_all_skills() {
    # Findet alle Skills in beiden Verzeichnissen
    local clawhub_skills=()
    local git_skills=()
    local all_skills=()
    
    # Hole Skills aus ClawHub
    while IFS= read -r -d '' dir; do
        local skill_name
        skill_name=$(basename "$dir")
        if [[ ! "$skill_name" =~ ^\. ]] && [[ ! " ${RESERVED_SKILL_NAMES[*]} " =~ " $skill_name " ]] && [[ -f "$dir/SKILL.md" ]]; then
            clawhub_skills+=("$skill_name")
        fi
    done < <(find "$CLAWHUB_DIR" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null || true)
    
    # Hole Skills aus Git
    while IFS= read -r -d '' dir; do
        local skill_name
        skill_name=$(basename "$dir")
        if [[ ! "$skill_name" =~ ^\. ]] && [[ ! " ${RESERVED_SKILL_NAMES[*]} " =~ " $skill_name " ]] && [[ -f "$dir/SKILL.md" ]]; then
            git_skills+=("$skill_name")
        fi
    done < <(find "$GIT_DIR" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null || true)
    
    # Vereinige Arrays und entferne Duplikate
    local combined=("${clawhub_skills[@]}" "${git_skills[@]}")
    local unique=($(printf '%s\n' "${combined[@]}" | sort -u))
    printf '%s\n' "${unique[@]}"
}

init_git_repo() {
    local skill_path="$1"
    local skill_name="$2"
    # Initialisiert Git-Repo wenn nötig
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

sync_skill_bidirectional() {
    local skill_name="$1"
    local clawhub_path="${CLAWHUB_DIR}/${skill_name}"
    local git_path="${GIT_DIR}/${skill_name}"
    
    # Fall 1: Nur in ClawHub → zu Git
    if [[ -d "$clawhub_path" ]] && [[ ! -d "$git_path" ]]; then
        log "NEW in ClawHub: $skill_name → syncing to Git"
        if sync_to_git "$skill_name" false; then
            init_git_repo "$git_path" "$skill_name"
            echo "synced_to_git"
            return
        fi
    
    # Fall 2: Nur in Git → zu ClawHub
    elif [[ -d "$git_path" ]] && [[ ! -d "$clawhub_path" ]]; then
        log "NEW in Git: $skill_name → syncing to ClawHub"
        if sync_to_clawhub "$skill_name" false; then
            echo "synced_to_clawhub"
            return
        fi
    
    # Fall 3: In beiden vorhanden
    elif [[ -d "$clawhub_path" ]] && [[ -d "$git_path" ]]; then
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

        local clawhub_changes
        clawhub_changes=$(preview_changes "$clawhub_path" "$git_path")
        local git_changes
        git_changes=$(preview_changes "$git_path" "$clawhub_path")

        if [[ -z "$clawhub_changes" ]] && [[ -z "$git_changes" ]]; then
            log "Content is identical for: $skill_name"
            echo "no_change"
            return
        fi

        if [[ -n "$clawhub_changes" ]] && [[ -z "$git_changes" ]]; then
            log "Content difference detected for: $skill_name"
            log "UPDATE: $skill_name ClawHub content is newer or different → syncing to Git"
            if sync_to_git "$skill_name" false; then
                (
                    cd "$git_path" || exit 1
                    git add . >/dev/null 2>&1
                    git commit -m "Sync from ClawHub content diff: $(date '+%Y-%m-%d %H:%M')" >/dev/null 2>&1
                )
                echo "updated_git"
                return
            fi
            log "Failed to sync $skill_name to Git after content diff" "ERROR"
            echo "error"
            return
        fi

        if [[ -n "$git_changes" ]] && [[ -z "$clawhub_changes" ]]; then
            log "Content difference detected for: $skill_name"
            log "UPDATE: $skill_name Git content is newer or different → syncing to ClawHub"
            if sync_to_clawhub "$skill_name" false; then
                echo "updated_clawhub"
                return
            fi
            log "Failed to sync $skill_name to ClawHub after content diff" "ERROR"
            echo "error"
            return
        fi

        log "Content difference detected for: $skill_name"
        local clawhub_mtime
        clawhub_mtime=$(newest_mtime "$clawhub_path")
        local git_mtime
        git_mtime=$(newest_mtime "$git_path")

        if (( $(echo "$clawhub_mtime >= $git_mtime" | bc -l) )); then
            log "UPDATE: $skill_name ClawHub content is newer or different → syncing to Git"
            if sync_to_git "$skill_name" false; then
                (
                    cd "$git_path" || exit 1
                    git add . >/dev/null 2>&1
                    git commit -m "Sync from ClawHub content diff: $(date '+%Y-%m-%d %H:%M')" >/dev/null 2>&1
                )
                echo "updated_git"
                return
            fi
        else
            log "UPDATE: $skill_name Git content is newer or different → syncing to ClawHub"
            if sync_to_clawhub "$skill_name" false; then
                echo "updated_clawhub"
                return
            fi
        fi

        log "Failed to resolve content diff for $skill_name" "ERROR"
        echo "error"
        return
    fi
    
    echo "no_change"
}

get_hashes() {
    local skill_dir="$1"
    # Erzeugt ein Dictionary von Datei-Hashes für einen Skill-Ordner
    declare -A hashes
    while IFS= read -r -d '' file; do
        local rel_path
        rel_path="${file#$skill_dir/}"
        local hash
        hash=$(sha256sum "$file" | cut -d' ' -f1)
        hashes["$rel_path"]="$hash"
    done < <(find "$skill_dir" -type f \( -name "*.py" -o -name "*.md" -o -name "*.json" \) -print0 2>/dev/null || true)
    
    # Gebe Hashes als JSON-ähnlichen String aus
    for key in "${!hashes[@]}"; do
        echo "\"$key\":\"${hashes[$key]}\""
    done
}

preview_changes() {
    local source_dir="$1"
    local target_dir="$2"
    # Berechnet Sync-Änderungen in einer Richtung, ohne zu schreiben
    local changes=()
    
    while IFS= read -r -d '' src_file; do
        local rel_path
        rel_path="${src_file#$source_dir/}"
        local tgt_file="${target_dir}/${rel_path}"
        
        if [[ ! -f "$tgt_file" ]]; then
            changes+=("ADD $rel_path")
        else
            local src_hash
            local tgt_hash
            src_hash=$(sha256sum "$src_file" | cut -d' ' -f1)
            tgt_hash=$(sha256sum "$tgt_file" | cut -d' ' -f1)
            
            if [[ "$src_hash" != "$tgt_hash" ]]; then
                changes+=("UPDATE $rel_path")
            fi
        fi
    done < <(find "$source_dir" -type f \( -name "*.py" -o -name "*.md" -o -name "*.json" \) -print0 2>/dev/null || true)
    
    printf '%s\n' "${changes[@]}"
}

newest_mtime() {
    local skill_dir="$1"
    # Ermittelt die neueste mtime über alle relevanten Dateien
    local mtimes=()
    
    while IFS= read -r -d '' file; do
        mtimes+=($(stat -c %Y "$file"))
    done < <(find "$skill_dir" -type f \( -name "*.py" -o -name "*.md" -o -name "*.json" \) -print0 2>/dev/null || true)
    
    if [[ ${#mtimes[@]} -eq 0 ]]; then
        echo "0"
        return
    fi
    
    local max_time=${mtimes[0]}
    for time in "${mtimes[@]}"; do
        if (( time > max_time )); then
            max_time=$time
        fi
    done
    
    echo "$max_time"
}

main() {
    # Hauptfunktion des Sync-Agents mit Dry-Run Phase
    log "=== ClawHub ↔ Git Sync Agent gestartet ==="
    
    # Load previous state
    local state
    state=$(load_state)
    local all_skills
    mapfile -t all_skills < <(get_all_skills)
    log "Gefundene Skills: ${#all_skills[@]}"
    
    # Dry-Run Phase: only report changes, no actual modifications
    log "--- Dry-Run Phase Start ---"
    for skill in "${all_skills[@]}"; do
        # Perform dry-run sync in both directions to capture potential changes
        sync_to_git "$skill" true >/dev/null 2>&1 || true
        sync_to_clawhub "$skill" true >/dev/null 2>&1 || true
    done
    log "--- Dry-Run Phase End ---"
    
    # Actual Sync Phase
    for skill in "${all_skills[@]}"; do
        local result
        result=$(sync_skill_bidirectional "$skill" 2>&1) || {
            log "ERROR syncing $skill: $result" "ERROR"
            errors_arr+=("$skill")
            continue
        }
        
        case "$result" in
            "synced_to_git")
                synced_to_git_arr+=("$skill")
                ;;
            "synced_to_clawhub")
                synced_to_clawhub_arr+=("$skill")
                ;;
            "updated_git")
                updated_git_arr+=("$skill")
                ;;
            "updated_clawhub")
                updated_clawhub_arr+=("$skill")
                ;;
            "no_change")
                no_change_arr+=("$skill")
                ;;
            "error")
                errors_arr+=("$skill")
                ;;
        esac
    done
    
    # Zusammenfassung
    log "\n=== SYNC ZUSAMMENFASSUNG ==="
    log "Neu in Git: ${#synced_to_git_arr[@]} - ${synced_to_git_arr[*]}"
    log "Neu in ClawHub: ${#synced_to_clawhub_arr[@]} - ${synced_to_clawhub_arr[*]}"
    log "Git aktualisiert: ${#updated_git_arr[@]} - ${updated_git_arr[*]}"
    log "ClawHub aktualisiert: ${#updated_clawhub_arr[@]} - ${updated_clawhub_arr[*]}"
    log "Keine Änderung: ${#no_change_arr[@]}"
    log "Fehler: ${#errors_arr[@]} - ${errors_arr[*]}"
    
    # State speichern
    local timestamp
    timestamp=$(date -Iseconds)
    
    # Erstelle JSON für Ergebnisse
    local results_json="{"
    results_json+="\"synced_to_git\": [$(printf '"%s",' "${synced_to_git_arr[@]}" | sed 's/,$//')],"
    results_json+="\"synced_to_clawhub\": [$(printf '"%s",' "${synced_to_clawhub_arr[@]}" | sed 's/,$//')],"
    results_json+="\"updated_git\": [$(printf '"%s",' "${updated_git_arr[@]}" | sed 's/,$//')],"
    results_json+="\"updated_clawhub\": [$(printf '"%s",' "${updated_clawhub_arr[@]}" | sed 's/,$//')],"
    results_json+="\"no_change\": [$(printf '"%s",' "${no_change_arr[@]}" | sed 's/,$//')],"
    results_json+="\"errors\": [$(printf '"%s",' "${errors_arr[@]}" | sed 's/,$//')]"
    results_json+="}"
    
    # Aktualisiere State
    local new_entry="{\"timestamp\":\"$timestamp\",\"results\":$results_json}"
    
    # Begrenze auf letzte 100 Einträge
    local history_length
    history_length=$(echo "$state" | jq '.sync_history | length')
    local start_index=$((history_length > 99 ? history_length - 99 : 0))
    
    local updated_state
    updated_state=$(echo "$state" | jq --argjson entry "$new_entry" --argjson start "$start_index" '
        .sync_history |= (.[$start:] + [$entry]) |
        .sync_history |= .[-100:]
    ')
    
    save_state "$updated_state"
    
    log "=== Sync Agent beendet ==="
}

main "$@"
