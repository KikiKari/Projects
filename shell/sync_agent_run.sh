#!/usr/bin/env bash
# sync_agent_run.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:scripts/sync_agent_run.py
# auch in: OpenClaw@gateway2:scripts/sync_agent_run.py
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# ClawHub ↔ Git Sync Agent - Produktionslauf

# shellcheck source=/dev/null
source /home/openclaw/.openclaw/workspace/scripts/sync_clawhub_git.sh

CLAWHUB_DIR="/home/openclaw/.openclaw/workspace/skills"
GIT_DIR="/home/openclaw/.openclaw/workspace/git/skills"
STATE_FILE="/home/openclaw/.openclaw/workspace/db/sync_state.json"

log() {
    echo "$*" >&2
}

file_mtime() {
    local dir="$1"
    local latest=0
    local file_time
    while IFS= read -r -d '' file; do
        file_time=$(stat -c %Y "$file" 2>/dev/null || echo 0)
        if [[ $file_time -gt $latest ]]; then
            latest=$file_time
        fi
    done < <(find "$dir" -type f -not -path "*/.git/*" -print0 2>/dev/null || true)
    echo "$latest"
}

log "======================================================================"
log "CLAWHUB ↔ GIT SYNC AGENT - PRODUKTIONS-LAUF"
log "Zeitstempel: $(date --iso-8601=seconds)"
log "======================================================================"

# Hole Skill-Verzeichnisse
mapfile -t clawhub_skills < <(find "$CLAWHUB_DIR" -mindepth 1 -maxdepth 1 -type d -not -name ".*" -exec basename {} \; 2>/dev/null || true)
mapfile -t git_skills < <(find "$GIT_DIR" -mindepth 1 -maxdepth 1 -type d -not -name ".*" -exec basename {} \; 2>/dev/null || true)

# Initialisiere Ergebnis-Arrays
declare -a synced_to_git=()
declare -a synced_to_clawhub=()
declare -a up_to_date=()
declare -a errors=()

# Konvertiere Arrays zu assoziativen Arrays für schnelleren Zugriff
declare -A clawhub_map=()
declare -A git_map=()
for skill in "${clawhub_skills[@]}"; do
    clawhub_map["$skill"]=1
done
for skill in "${git_skills[@]}"; do
    git_map["$skill"]=1
done

# 1. NEU in ClawHub → zu Git syncen
log ""
log "[PHASE 1] ClawHub → Git Synchronisation"
log "----------------------------------------"

# Finde neue Skills in ClawHub
declare -a new_in_clawhub=()
for skill in "${clawhub_skills[@]}"; do
    if [[ -z ${git_map[$skill]+_} ]]; then
        new_in_clawhub+=("$skill")
    fi
done
IFS=$'\n' new_in_clawhub=($(sort <<<"${new_in_clawhub[*]}"))
unset IFS

for skill in "${new_in_clawhub[@]}"; do
    if validate_skill "$CLAWHUB_DIR/$skill"; then
        log "→ Synchronisiere $skill zu Git..."
        if sync_to_git "$skill" "false"; then
            # Git init
            cd "$GIT_DIR/$skill" || { log "✗ ERROR: Konnte nicht ins Git-Verzeichnis wechseln: $skill" "ERROR"; errors+=("$skill (cd failed)"); continue; }
            git init -q 2>/dev/null || true
            git add . -f 2>/dev/null || true
            dt=$(date +"%Y-%m-%d %H:%M")
            git commit -m "Initial: $skill" -q 2>/dev/null || true
            synced_to_git+=("$skill")
            log "  ✓ $skill synchronisiert & Git initialisiert"
        else
            errors+=("$skill (sync failed)")
        fi
    else
        errors+=("$skill (invalid)")
    fi
done

# 2. In beiden - prüfe Änderungen
log ""
log "[PHASE 2] Prüfe existierende Skills auf Änderungen"
log "----------------------------------------"

# Finde gemeinsame Skills
declare -a in_both=()
for skill in "${clawhub_skills[@]}"; do
    if [[ -n ${git_map[$skill]+_} ]]; then
        in_both+=("$skill")
    fi
done
IFS=$'\n' in_both=($(sort <<<"${in_both[*]}"))
unset IFS

for skill in "${in_both[@]}"; do
    c_mtime=$(file_mtime "$CLAWHUB_DIR/$skill")
    g_mtime=$(file_mtime "$GIT_DIR/$skill")
    diff=$((c_mtime - g_mtime))

    if [[ ${diff#-} -gt 60 ]]; then
        if [[ $diff -gt 0 ]]; then
            log "→ $skill: ClawHub neuer (+$diff s) → sync zu Git"
            if sync_to_git "$skill" "false"; then
                cd "$GIT_DIR/$skill" || { log "✗ ERROR: Konnte nicht ins Git-Verzeichnis wechseln: $skill" "ERROR"; errors+=("$skill (cd failed)"); continue; }
                git add . -f 2>/dev/null || true
                dt=$(date +"%Y-%m-%d %H:%M")
                git commit -m "Sync from ClawHub: $dt" -q 2>/dev/null || true
                synced_to_git+=("$skill")
            else
                errors+=("$skill (update failed)")
            fi
        else
            log "→ $skill: Git neuer (+${diff#-} s) → sync zu ClawHub"
            if sync_to_clawhub "$skill" "false"; then
                synced_to_clawhub+=("$skill")
            else
                errors+=("$skill (update failed)")
            fi
        fi
    else
        up_to_date+=("$skill")
    fi
done

# ZUSAMMENFASSUNG
log ""
log "======================================================================"
log "SYNCHRONISATION ABGESCHLOSSEN"
log "======================================================================"
log "Zu Git synchronisiert:     ${#synced_to_git[@]}"
if [[ ${#synced_to_git[@]} -gt 0 ]]; then
    log "  $(IFS=", "; echo "${synced_to_git[*]}")"
fi
log "Zu ClawHub synchronisiert: ${#synced_to_clawhub[@]}"
if [[ ${#synced_to_clawhub[@]} -gt 0 ]]; then
    log "  $(IFS=", "; echo "${synced_to_clawhub[*]}")"
fi
log "Bereits aktuell:           ${#up_to_date[@]}"
log "Fehler:                    ${#errors[@]}"
if [[ ${#errors[@]} -gt 0 ]]; then
    log "  $(IFS=", "; echo "${errors[*]}")"
fi
log "======================================================================"

# Speichere State
mkdir -p "$(dirname "$STATE_FILE")"

# Erstelle JSON manuell
{
    echo "{"
    echo "  \"last_run\": \"$(date --iso-8601=seconds)\","
    echo "  \"results\": {"
    echo "    \"synced_to_git\": ["
    for i in "${!synced_to_git[@]}"; do
        if [[ $i -gt 0 ]]; then echo ","; fi
        echo "      \"${synced_to_git[i]}\""
    done
    echo "    ],"
    echo "    \"synced_to_clawhub\": ["
    for i in "${!synced_to_clawhub[@]}"; do
        if [[ $i -gt 0 ]]; then echo ","; fi
        echo "      \"${synced_to_clawhub[i]}\""
    done
    echo "    ],"
    echo "    \"up_to_date\": ["
    for i in "${!up_to_date[@]}"; do
        if [[ $i -gt 0 ]]; then echo ","; fi
        echo "      \"${up_to_date[i]}\""
    done
    echo "    ],"
    echo "    \"errors\": ["
    for i in "${!errors[@]}"; do
        if [[ $i -gt 0 ]]; then echo ","; fi
        echo "      \"${errors[i]}\""
    done
    echo "    ]"
    echo "  }"
    echo "}"
} > "$STATE_FILE"

log "State gespeichert: $STATE_FILE"
