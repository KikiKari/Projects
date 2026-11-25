#!/bin/bash
# abstraction-provenance: {"artifact_sha256": "ec144c830237aef385877bee6775724d6cc947be2466423b152ff04c871c9684", "source_sha256": "5d90ebcd250a3cb80a0de664d94397af7ec03343d9d9fa64a28a9a11ad880754", "target_language": "shell"}
# check_conflicts.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:skills/sync-utils/scripts/check_conflicts.py
# auch in: OpenClaw@gateway2:skills/sync-utils/scripts/check_conflicts.py
# Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Check Conflicts - Erkennt Sync-Konflikte

# Import sync functions
SCRIPT_DIR="/home/openclaw/.openclaw/workspace/scripts"
SYNC_SCRIPT="$SCRIPT_DIR/sync_clawhub_git.sh"

# Lade Hilfsfunktionen
if [[ -f "$SYNC_SCRIPT" ]]; then
    source "$SYNC_SCRIPT"
else
    echo "Fehler: Sync-Skript nicht gefunden: $SYNC_SCRIPT" >&2
    exit 1
fi

CLAWHUB_DIR="/home/openclaw/.openclaw/workspace/skills"
GIT_DIR="/home/openclaw/.openclaw/workspace/git/skills"

# Temporäre Dateien für Hash-Berechnungen
TEMP_CLAWHUB_HASH="$(mktemp)"
TEMP_GIT_HASH="$(mktemp)"
trap 'rm -f "$TEMP_CLAWHUB_HASH" "$TEMP_GIT_HASH"' EXIT

check_conflicts() {
    local conflicts_found=0
    local conflict_skills=()
    
    # Prüfe ob beide Verzeichnisse existieren
    if [[ ! -d "$CLAWHUB_DIR" ]] || [[ ! -d "$GIT_DIR" ]]; then
        echo "Fehler: ClawHub- oder Git-Verzeichnis nicht gefunden" >&2
        return 1
    fi
    
    # Finde gemeinsame Skills
    local common_skills=()
    local clawhub_skills=()
    local git_skills=()
    
    while IFS= read -r skill; do
        clawhub_skills+=("$(basename "$skill")")
    done < <(find "$CLAWHUB_DIR" -maxdepth 1 -mindepth 1 -type d 2>/dev/null || true)
    
    while IFS= read -r skill; do
        git_skills+=("$(basename "$skill")")
    done < <(find "$GIT_DIR" -maxdepth 1 -mindepth 1 -type d 2>/dev/null || true)
    
    # Bestimme Schnittmenge
    for skill in "${clawhub_skills[@]}"; do
        for git_skill in "${git_skills[@]}"; do
            if [[ "$skill" == "$git_skill" ]]; then
                common_skills+=("$skill")
                break
            fi
        done
    done
    
    echo "Prüfe ${#common_skills[@]} Skills auf Konflikte..."
    echo
    
    # Prüfe jeden gemeinsamen Skill
    for skill in "${common_skills[@]}"; do
        local clawhub_path="$CLAWHUB_DIR/$skill"
        local git_path="$GIT_DIR/$skill"
        local skill_conflicts=()
        
        # Sammle Dateien (ohne .git Verzeichnisse)
        local clawhub_files=()
        local git_files=()
        
        while IFS= read -r file; do
            local rel_path="${file#$clawhub_path/}"
            if [[ "$rel_path" != *.git/* ]] && [[ "$rel_path" != .git ]]; then
                clawhub_files+=("$rel_path")
            fi
        done < <(find "$clawhub_path" -type f 2>/dev/null || true)
        
        while IFS= read -r file; do
            local rel_path="${file#$git_path/}"
            if [[ "$rel_path" != *.git/* ]] && [[ "$rel_path" != .git ]]; then
                git_files+=("$rel_path")
            fi
        done < <(find "$git_path" -type f 2>/dev/null || true)
        
        # Vergleiche gemeinsame Dateien
        for rel_path in "${clawhub_files[@]}"; do
            for git_rel_path in "${git_files[@]}"; do
                if [[ "$rel_path" == "$git_rel_path" ]]; then
                    local clawhub_file="$clawhub_path/$rel_path"
                    local git_file="$git_path/$rel_path"
                    
                    # Berechne Hashes
                    if get_file_hash "$clawhub_file" >"$TEMP_CLAWHUB_HASH" 2>/dev/null && \
                       get_file_hash "$git_file" >"$TEMP_GIT_HASH" 2>/dev/null; then
                        
                        local clawhub_hash
                        local git_hash
                        clawhub_hash=$(cat "$TEMP_CLAWHUB_HASH")
                        git_hash=$(cat "$TEMP_GIT_HASH")
                        
                        if [[ "$clawhub_hash" != "$git_hash" ]]; then
                            # Hole Modifikationszeiten
                            local clawhub_mtime
                            local git_mtime
                            clawhub_mtime=$(stat -c %Y "$clawhub_file" 2>/dev/null || echo "0")
                            git_mtime=$(stat -c %Y "$git_file" 2>/dev/null || echo "0")
                            
                            # Formatierung als lesbares Datum
                            local clawhub_date
                            local git_date
                            clawhub_date=$(date -d "@$clawhub_mtime" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "Unknown")
                            git_date=$(date -d "@$git_mtime" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "Unknown")
                            
                            local newer="git"
                            if (( clawhub_mtime > git_mtime )); then
                                newer="clawhub"
                            fi
                            
                            skill_conflicts+=("$rel_path|$clawhub_date|$git_date|$newer")
                        fi
                    fi
                    break
                fi
            done
        done
        
        # Speichere Konflikte für diesen Skill
        if [[ ${#skill_conflicts[@]} -gt 0 ]]; then
            conflict_skills+=("$skill|${skill_conflicts[*]}")
            conflicts_found=1
        fi
    done
    
    # Ausgabe der Ergebnisse
    if [[ $conflicts_found -eq 1 ]]; then
        echo "⚠️  KONFLIKTE GEFUNDEN:"
        echo "================================================================================"
        
        for conflict_entry in "${conflict_skills[@]}"; do
            IFS='|' read -ra parts <<< "$conflict_entry"
            local skill_name="${parts[0]}"
            local conflicts_list=("${parts[@]:1}")
            
            echo
            echo "📦 Skill: $skill_name"
            echo "----------------------------------------"
            
            for conflict in "${conflicts_list[@]}"; do
                IFS='|' read -ra conflict_parts <<< "$conflict"
                local file_path="${conflict_parts[0]}"
                local clawhub_mod="${conflict_parts[1]}"
                local git_mod="${conflict_parts[2]}"
                local newer_source="${conflict_parts[3]}"
                
                echo "  📄 $file_path"
                echo "     ClawHub: $clawhub_mod"
                echo "     Git:     $git_mod"
                echo "     Neuer:   ${newer_source^^}"
                echo
            done
        done
        
        echo "================================================================================"
        echo "Gesamt: ${#conflict_skills[@]} Skills mit Konflikten"
        echo
        echo "Nutze 'sync_utils/scripts/resolve_conflict.py' zum Auflösen."
        return 1
    else
        echo "✅ Keine Konflikte gefunden!"
        echo "Alle gemeinsamen Skills sind synchron."
        return 0
    fi
}

main() {
    check_conflicts
}

main "$@"
