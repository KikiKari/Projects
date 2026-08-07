#!/usr/bin/env bash
# check_conflicts.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:skills/sync-utils/scripts/check_conflicts.py
# auch in: OpenClaw@gateway2:skills/sync-utils/scripts/check_conflicts.py
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Check Conflicts - Erkennt Sync-Konflikte

CLAWHUB_DIR="/home/openclaw/.openclaw/workspace/skills"
GIT_DIR="/home/openclaw/.openclaw/workspace/git/skills"

# Function to calculate MD5 hash of a file
get_file_hash() {
    local file="$1"
    md5sum "$file" | cut -d' ' -f1
}

# Function to format timestamp
format_timestamp() {
    local timestamp="$1"
    date -d "@$timestamp" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date -r "$timestamp" '+%Y-%m-%d %H:%M:%S'
}

check_conflicts() {
    local conflicts=()
    local common_skills=()
    
    # Check if directories exist
    if [[ -d "$CLAWHUB_DIR" && -d "$GIT_DIR" ]]; then
        # Get skill names from both directories
        local clawhub_skills=()
        local git_skills=()
        
        while IFS= read -r dir; do
            [[ -n "$dir" ]] && clawhub_skills+=("$(basename "$dir")")
        done < <(find "$CLAWHUB_DIR" -maxdepth 1 -type d -not -path "$CLAWHUB_DIR" 2>/dev/null)
        
        while IFS= read -r dir; do
            [[ -n "$dir" ]] && git_skills+=("$(basename "$dir")")
        done < <(find "$GIT_DIR" -maxdepth 1 -type d -not -path "$GIT_DIR" 2>/dev/null)
        
        # Find common skills
        for skill in "${clawhub_skills[@]}"; do
            for git_skill in "${git_skills[@]}"; do
                if [[ "$skill" == "$git_skill" ]]; then
                    common_skills+=("$skill")
                    break
                fi
            done
        done
    fi
    
    echo "Prüfe ${#common_skills[@]} Skills auf Konflikte..."
    echo
    
    local skill_conflicts_output=""
    
    for skill in "${common_skills[@]}"; do
        local clawhub_path="$CLAWHUB_DIR/$skill"
        local git_path="$GIT_DIR/$skill"
        local skill_conflicts=()
        
        # Create temporary files for file listings
        local clawhub_files_list="$(mktemp)"
        local git_files_list="$(mktemp)"
        
        # Get all files in ClawHub (excluding .git)
        find "$clawhub_path" -type f -not -path "*/.git/*" | while read -r file; do
            rel_path="${file#$clawhub_path/}"
            echo "$rel_path|$file" >> "$clawhub_files_list"
        done
        
        # Get all files in Git (excluding .git)
        find "$git_path" -type f -not -path "*/.git/*" | while read -r file; do
            rel_path="${file#$git_path/}"
            echo "$rel_path|$file" >> "$git_files_list"
        done
        
        # Compare files
        while IFS='|' read -r rel_path clawhub_file; do
            # Check if file exists in git
            if grep -q "^$rel_path|" "$git_files_list" 2>/dev/null; then
                git_file=$(grep "^$rel_path|" "$git_files_list" | cut -d'|' -f2)
                
                # Compare file hashes
                if [[ "$(get_file_hash "$clawhub_file")" != "$(get_file_hash "$git_file")" ]]; then
                    local clawhub_mtime
                    local git_mtime
                    clawhub_mtime=$(stat -c %Y "$clawhub_file" 2>/dev/null || stat -f %m "$clawhub_file" 2>/dev/null)
                    git_mtime=$(stat -c %Y "$git_file" 2>/dev/null || stat -f %m "$git_file" 2>/dev/null)
                    
                    local clawhub_formatted
                    local git_formatted
                    clawhub_formatted=$(format_timestamp "$clawhub_mtime")
                    git_formatted=$(format_timestamp "$git_mtime")
                    
                    local newer
                    if (( clawhub_mtime > git_mtime )); then
                        newer="clawhub"
                    else
                        newer="git"
                    fi
                    
                    skill_conflicts+=("$rel_path|$clawhub_formatted|$git_formatted|$newer")
                fi
            fi
        done < "$clawhub_files_list"
        
        # Clean up temporary files
        rm -f "$clawhub_files_list" "$git_files_list"
        
        # If conflicts found for this skill
        if [[ ${#skill_conflicts[@]} -gt 0 ]]; then
            conflicts+=("$skill")
            skill_conflicts_output+="\n📦 Skill: $skill\n"
            skill_conflicts_output+="----------------------------------------\n"
            
            for conflict in "${skill_conflicts[@]}"; do
                IFS='|' read -r file clawhub_time git_time newer <<< "$conflict"
                skill_conflicts_output+="  📄 $file\n"
                skill_conflicts_output+="     ClawHub: $clawhub_time\n"
                skill_conflicts_output+="     Git:     $git_time\n"
                skill_conflicts_output+="     Neuer:   ${newer^^}\n"
                skill_conflicts_output+="\n"
            done
        fi
    done
    
    # Output results
    if [[ ${#conflicts[@]} -gt 0 ]]; then
        echo "⚠️  KONFLIKTE GEFUNDEN:"
        echo "================================================================================"
        printf "%b" "$skill_conflicts_output"
        echo "================================================================================"
        echo "Gesamt: ${#conflicts[@]} Skills mit Konflikten"
        echo
        echo "Nutze 'sync_utils/scripts/resolve_conflict.py' zum Auflösen."
    else
        echo "✅ Keine Konflikte gefunden!"
        echo "Alle gemeinsamen Skills sind synchron."
    fi
}

main() {
    check_conflicts
}

main "$@"
