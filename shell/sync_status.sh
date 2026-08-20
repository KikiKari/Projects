#!/bin/bash
# sync_status.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:skills/sync-utils/scripts/sync_status.py
# auch in: OpenClaw@gateway2:skills/sync-utils/scripts/sync_status.py
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Sync Status - Zeigt Status aller Skills

CLAWHUB_DIR="/home/openclaw/.openclaw/workspace/skills"
GIT_DIR="/home/openclaw/.openclaw/workspace/git/skills"
STATE_FILE="/home/openclaw/.openclaw/workspace/db/sync_state.json"

# Funktion zur Berechnung des Hashes einer Datei (vereinfacht)
get_file_hash() {
    local file="$1"
    if [[ -f "$file" ]]; then
        md5sum "$file" | cut -d' ' -f1
    fi
}

# Prüft Status eines Skills
check_skill_status() {
    local skill_name="$1"
    local clawhub_path="${CLAWHUB_DIR}/${skill_name}"
    local git_path="${GIT_DIR}/${skill_name}"
    
    local in_clawhub="false"
    local in_git="false"
    local has_git_repo="false"
    local status="unknown"
    local clawhub_mtime=""
    local git_mtime=""
    
    # Existenz prüfen
    [[ -d "$clawhub_path" ]] && in_clawhub="true"
    [[ -d "$git_path" ]] && in_git="true"
    
    # Git Repo prüfen
    if [[ "$in_git" == "true" && -d "${git_path}/.git" ]]; then
        has_git_repo="true"
    fi
    
    # Status bestimmen
    if [[ "$in_clawhub" == "true" && "$in_git" == "false" ]]; then
        status="only_clawhub"
    elif [[ "$in_git" == "true" && "$in_clawhub" == "false" ]]; then
        status="only_git"
    elif [[ "$in_clawhub" == "true" && "$in_git" == "true" ]]; then
        # Timestamps vergleichen
        if [[ -d "$clawhub_path" && -d "$git_path" ]]; then
            # Neueste Datei in ClawHub finden (ausgenommen .git Verzeichnisse)
            local clawhub_latest=""
            local git_latest=""
            
            # Finde neueste Änderungszeit in ClawHub
            if command -v find >/dev/null 2>&1; then
                clawhub_latest=$(find "$clawhub_path" -type f -exec stat -c '%Y %n' {} + 2>/dev/null | sort -n | tail -1 | cut -d' ' -f1)
                # Finde neueste Änderungszeit in Git (ohne .git Verzeichnis)
                git_latest=$(find "$git_path" -type f -not -path "*/.git/*" -exec stat -c '%Y %n' {} + 2>/dev/null | sort -n | tail -1 | cut -d' ' -f1)
                
                if [[ -n "$clawhub_latest" && -n "$git_latest" ]]; then
                    # In lesbares Datumsformat umwandeln
                    clawhub_mtime=$(date -d "@${clawhub_latest}" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "")
                    git_mtime=$(date -d "@${git_latest}" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "")
                    
                    # Differenz prüfen (innerhalb von 60 Sekunden = synced)
                    local diff=$((clawhub_latest > git_latest ? clawhub_latest - git_latest : git_latest - clawhub_latest))
                    if [[ $diff -lt 60 ]]; then
                        status="synced"
                    elif [[ $clawhub_latest -gt $git_latest ]]; then
                        status="clawhub_newer"
                    else
                        status="git_newer"
                    fi
                else
                    status="error"
                fi
            else
                status="error"
            fi
        else
            status="error"
        fi
    fi
    
    # JSON-ähnliche Ausgabe erzeugen
    echo "{"
    echo "  \"name\": \"$skill_name\","
    echo "  \"in_clawhub\": $in_clawhub,"
    echo "  \"in_git\": $in_git,"
    echo "  \"has_git_repo\": $has_git_repo,"
    echo "  \"status\": \"$status\","
    echo "  \"last_modified\": {"
    if [[ -n "$clawhub_mtime" ]]; then
        echo "    \"clawhub\": \"$clawhub_mtime\""
    fi
    if [[ -n "$git_mtime" ]]; then
        if [[ -n "$clawhub_mtime" ]]; then
            echo "    ,"
        fi
        echo "    \"git\": \"$git_mtime\""
    fi
    echo "  }"
    echo "}"
}

# Hauptfunktion
main() {
    echo "================================================================================"
    echo "ClawHub ↔ Git Sync Status"
    echo "================================================================================"
    echo "Zeitpunkt: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    
    # Alle Skills finden
    declare -A all_skills
    
    if [[ -d "$CLAWHUB_DIR" ]]; then
        while IFS= read -r dir; do
            [[ -n "$dir" ]] && all_skills["$(basename "$dir")"]=1
        done < <(find "$CLAWHUB_DIR" -maxdepth 1 -mindepth 1 -type d -not -name ".*" 2>/dev/null || true)
    fi
    
    if [[ -d "$GIT_DIR" ]]; then
        while IFS= read -r dir; do
            [[ -n "$dir" ]] && all_skills["$(basename "$dir")"]=1
        done < <(find "$GIT_DIR" -maxdepth 1 -mindepth 1 -type d -not -name ".*" 2>/dev/null || true)
    fi
    
    # Status-Kategorien initialisieren
    declare -a synced=()
    declare -a clawhub_newer=()
    declare -a git_newer=()
    declare -a only_clawhub=()
    declare -a only_git=()
    declare -a error_states=()
    
    # Status für jeden Skill prüfen
    for skill in "${!all_skills[@]}"; do
        status_json=$(check_skill_status "$skill")
        status=$(echo "$status_json" | grep '"status"' | sed -E 's/.*"status": "([^"]+)".*/\1/')
        
        case "$status" in
            synced) synced+=("$status_json");;
            clawhub_newer) clawhub_newer+=("$status_json");;
            git_newer) git_newer+=("$status_json");;
            only_clawhub) only_clawhub+=("$status_json");;
            only_git) only_git+=("$status_json");;
            error) error_states+=("$status_json");;
        esac
    done
    
    # Ausgabe
    echo "📊 Gesamt: ${#all_skills[@]} Skills"
    echo ""
    
    # Synchronisiert
    if [[ ${#synced[@]} -gt 0 ]]; then
        echo "✅ Synchronisiert (${#synced[@]})"
        for item in "${synced[@]}"; do
            name=$(echo "$item" | grep '"name"' | sed -E 's/.*"name": "([^"]+)".*/\1/')
            echo "   - $name"
        done
        echo ""
    fi
    
    # ClawHub neuer
    if [[ ${#clawhub_newer[@]} -gt 0 ]]; then
        echo "🔄 ClawHub neuer (${#clawhub_newer[@]})"
        for item in "${clawhub_newer[@]}"; do
            name=$(echo "$item" | grep '"name"' | sed -E 's/.*"name": "([^"]+)".*/\1/')
            clawhub_time=$(echo "$item" | grep '"clawhub"' | sed -E 's/.*"clawhub": "([^"]+)".*/\1/')
            echo "   - $name (ClawHub: $clawhub_time)"
        done
        echo ""
    fi
    
    # Git neuer
    if [[ ${#git_newer[@]} -gt 0 ]]; then
        echo "🔄 Git neuer (${#git_newer[@]})"
        for item in "${git_newer[@]}"; do
            name=$(echo "$item" | grep '"name"' | sed -E 's/.*"name": "([^"]+)".*/\1/')
            git_time=$(echo "$item" | grep '"git"' | sed -E 's/.*"git": "([^"]+)".*/\1/')
            echo "   - $name (Git: $git_time)"
        done
        echo ""
    fi
    
    # Nur in ClawHub
    if [[ ${#only_clawhub[@]} -gt 0 ]]; then
        echo "📦 Nur in ClawHub (${#only_clawhub[@]})"
        for item in "${only_clawhub[@]}"; do
            name=$(echo "$item" | grep '"name"' | sed -E 's/.*"name": "([^"]+)".*/\1/')
            echo "   - $name"
        done
        echo ""
    fi
    
    # Nur in Git
    if [[ ${#only_git[@]} -gt 0 ]]; then
        echo "📁 Nur in Git (${#only_git[@]})"
        for item in "${only_git[@]}"; do
            name=$(echo "$item" | grep '"name"' | sed -E 's/.*"name": "([^"]+)".*/\1/')
            echo "   - $name"
        done
        echo ""
    fi
    
    # Fehler
    if [[ ${#error_states[@]} -gt 0 ]]; then
        echo "❌ Fehler (${#error_states[@]})"
        for item in "${error_states[@]}"; do
            name=$(echo "$item" | grep '"name"' | sed -E 's/.*"name": "([^"]+)".*/\1/')
            echo "   - $name"
        done
        echo ""
    fi
    
    # State-File Info
    if [[ -f "$STATE_FILE" ]]; then
        if command -v jq >/dev/null 2>&1; then
            last_run=$(jq -r '.last_sync | keys[]?' "$STATE_FILE" | tail -1)
            if [[ -n "$last_run" ]]; then
                echo "📅 Letzter automatischer Sync: $last_run"
            fi
        else
            # Fallback ohne jq
            last_run=$(grep -o '"[^"]*":[[:space:]]*{[^}]*}' "$STATE_FILE" | grep -o '"[^"]*"' | head -1 | tr -d '"')
            if [[ -n "$last_run" ]]; then
                echo "📅 Letzter automatischer Sync: $last_run"
            fi
        fi
    fi
    
    echo "================================================================================"
}

main "$@"
