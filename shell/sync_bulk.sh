#!/bin/bash
# sync_bulk.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:skills/sync-utils/scripts/sync_bulk.py
# auch in: OpenClaw@gateway2:skills/sync-utils/scripts/sync_bulk.py
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Bulk Sync - Synchronisiert alle Skills

# Konfiguration
CLAWHUB_DIR="/home/openclaw/.openclaw/workspace/skills"
GIT_DIR="/home/openclaw/.openclaw/workspace/git/skills"
SCRIPTS_DIR="/home/openclaw/.openclaw/workspace/scripts"

# Lade externe Funktionen
source "$SCRIPTS_DIR/sync_clawhub_git.sh"

# Arrays für Ergebnisse
declare -a SYNCED=()
declare -a SKIPPED=()
declare -a FAILED=()

# Logging-Funktion
log() {
    local message="$1"
    local level="${2:-INFO}"
    echo "[$level] $message"
}

# Skill validieren
validate_skill() {
    local skill_path="$1"
    # Prüfe ob manifest.yaml existiert
    if [[ -f "$skill_path/manifest.yaml" ]]; then
        return 0
    else
        return 1
    fi
}

# Finde alle Skills in beiden Verzeichnissen
find_all_skills() {
    local skills=()
    
    # Skills aus ClawHub
    if [[ -d "$CLAWHUB_DIR" ]]; then
        while IFS= read -r dir; do
            if [[ -d "$dir" && "$(basename "$dir")" != .* ]]; then
                skills+=("$(basename "$dir")")
            fi
        done < <(find "$CLAWHUB_DIR" -maxdepth 1 -type d -not -path "*/.*")
    fi
    
    # Skills aus Git
    if [[ -d "$GIT_DIR" ]]; then
        while IFS= read -r dir; do
            if [[ -d "$dir" && "$(basename "$dir")" != .* ]]; then
                skills+=("$(basename "$dir")")
            fi
        done < <(find "$GIT_DIR" -maxdepth 1 -type d -not -path "*/.*")
    fi
    
    # Entferne Duplikate und sortiere
    printf '%s\n' "${skills[@]}" | sort -u
}

# Hole neuestes Änderungsdatum eines Verzeichnisses
get_latest_mtime() {
    local path="$1"
    find "$path" -type f -not -path "*/.git/*" -exec stat -c %Y {} \; 2>/dev/null | sort -n | tail -1
}

# Synchronisiere alle Skills
sync_all_skills() {
    local dry_run=$1
    local all_skills
    mapfile -t all_skills < <(find_all_skills)
    
    log "Bulk Sync: ${#all_skills[@]} Skills gefunden"
    
    for skill in "${all_skills[@]}"; do
        local clawhub_path="$CLAWHUB_DIR/$skill"
        local git_path="$GIT_DIR/$skill"
        
        # Fehlerbehandlung pro Skill
        if ! (
            # Nur in ClawHub → zu Git
            if [[ -d "$clawhub_path" ]] && [[ ! -d "$git_path" ]]; then
                if validate_skill "$clawhub_path"; then
                    log "Syncing $skill to Git..."
                    if sync_to_git "$skill" "$dry_run"; then
                        SYNCED+=("$skill → Git")
                    else
                        FAILED+=("$skill")
                    fi
                else
                    SKIPPED+=("$skill (validation failed)")
                fi
            
            # Nur in Git → zu ClawHub
            elif [[ -d "$git_path" ]] && [[ ! -d "$clawhub_path" ]]; then
                if validate_skill "$git_path"; then
                    log "Syncing $skill to ClawHub..."
                    if sync_to_clawhub "$skill" "$dry_run"; then
                        SYNCED+=("$skill → ClawHub")
                    else
                        FAILED+=("$skill")
                    fi
                else
                    SKIPPED+=("$skill (validation failed)")
                fi
            
            # In beiden - prüfe ob Update nötig
            elif [[ -d "$clawhub_path" ]] && [[ -d "$git_path" ]]; then
                local clawhub_mtime
                local git_mtime
                clawhub_mtime=$(get_latest_mtime "$clawhub_path")
                git_mtime=$(get_latest_mtime "$git_path")
                
                # Falls Differenz größer als 60 Sekunden
                if (( $(echo "$clawhub_mtime - $git_mtime" | bc -l) > 60 )) || \
                   (( $(echo "$git_mtime - $clawhub_mtime" | bc -l) > 60 )); then
                    
                    if (( $(echo "$clawhub_mtime > $git_mtime" | bc -l) )); then
                        log "Updating $skill in Git..."
                        if sync_to_git "$skill" "$dry_run"; then
                            SYNCED+=("$skill → Git (update)")
                        else
                            FAILED+=("$skill")
                        fi
                    else
                        log "Updating $skill in ClawHub..."
                        if sync_to_clawhub "$skill" "$dry_run"; then
                            SYNCED+=("$skill → ClawHub (update)")
                        else
                            FAILED+=("$skill")
                        fi
                    fi
                else
                    SKIPPED+=("$skill (already synced)")
                fi
            fi
        ); then
            log "Error processing $skill" "ERROR"
            FAILED+=("$skill")
        fi
    done
    
    # Zusammenfassung
    echo
    printf '=%.0s' {1..60}
    echo
    if [[ "$dry_run" == true ]]; then
        echo "Bulk Sync DRY-RUN - Zusammenfassung"
    else
        echo "Bulk Sync EXECUTED - Zusammenfassung"
    fi
    printf '=%.0s' {1..60}
    echo
    echo "✅ Synchronisiert: ${#SYNCED[@]}"
    for item in "${SYNCED[@]}"; do
        echo "   - $item"
    done
    
    echo -e "\n⏭️  Übersprungen: ${#SKIPPED[@]}"
    if [[ ${#SKIPPED[@]} -le 10 ]]; then
        for item in "${SKIPPED[@]}"; do
            echo "   - $item"
        done
    else
        echo "   - ${#SKIPPED[@]} Skills (bereits synchron oder Validierung fehlgeschlagen)"
    fi
    
    echo -e "\n❌ Fehlgeschlagen: ${#FAILED[@]}"
    for item in "${FAILED[@]}"; do
        echo "   - $item"
    done
    printf '=%.0s' {1..60}
    echo
}

# Hauptfunktion
main() {
    local dry_run=false
    local execute=false
    
    # Parameter parsen
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                dry_run=true
                shift
                ;;
            --execute)
                execute=true
                shift
                ;;
            *)
                echo "Unbekannter Parameter: $1"
                exit 1
                ;;
        esac
    done
    
    if [[ "$dry_run" == false && "$execute" == false ]]; then
        echo "Bitte --dry-run oder --execute angeben"
        exit 1
    fi
    
    sync_all_skills "$dry_run"
}

# Skript starten
main "$@"
