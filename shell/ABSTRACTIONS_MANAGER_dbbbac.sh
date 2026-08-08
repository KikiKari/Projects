#!/bin/bash
# ABSTRACTIONS_MANAGER.py — portiert nach shell
# Quelle: python, OpenClaw@gateway2:abstraction-manager/ABSTRACTIONS_MANAGER.py
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Konfiguration
readonly WORKSPACE="${OPENCLAW_WORKSPACE:-/home/openclaw/.openclaw/workspace}"
readonly ABSTRACTIONS_REPO="${WORKSPACE}/git/Abstraktionen"
readonly LOG_DIR="${WORKSPACE}/logs/abstractions-manager"
readonly STATE_FILE="${WORKSPACE}/db/abstractions_state.json"

# Node-Konfiguration
declare -A NODES=(
    [node1]="always_available:true,capacity:medium,priority:2"
    [node2]="always_available:true,capacity:medium,priority:3"
    [node3]="always_available:false,capacity:medium,priority:4"
    [node5]="always_available:false,capacity:low,priority:5,device:Redmi Note 11S,condition:mobile_internet"
    [node7]="always_available:true,capacity:high,priority:1"
)

# Zielsprachen-Konfiguration
declare -A TARGET_LANGUAGES=(
    [perl5]="ext:.pl,shebang:#!/usr/bin/env perl,header:use strict;\nuse warnings;\n,main_block:sub main {\n    # TODO: Implementiere {source_lang} Funktionalität in Perl 5\n}\n\nmain();\n"
    [perl6]="ext:.raku,shebang:#!/usr/bin/env raku,header:use v6;\n,main_block:sub MAIN() {\n    # TODO: Implementiere {source_lang} Funktionalität in Raku\n}"
    [javascript]="ext:.js,shebang:#!/usr/bin/env node,header:'use strict';\n,main_block:function main() {\n    // TODO: Implementiere {source_lang} Funktionalität in JavaScript\n}\n\nmain();\n"
    [python]="ext:.py,shebang:#!/usr/bin/env python3,header:,main_block:def main():\n    # TODO: Implementiere {source_lang} Funktionalität in Python\n    pass\n\n\nif __name__ == '__main__':\n    main()\n"
    [shell]="ext:.sh,shebang:#!/bin/bash,header:set -euo pipefail\n,main_block:main() {\n    # TODO: Implementiere {source_lang} Funktionalität in Bash\n}\n\nmain \"\$@\"\n"
    [powershell]="ext:.ps1,shebang:#!/usr/bin/env pwsh,header:#Requires -Version 7\n,main_block:function Main {\n    # TODO: Implementiere {source_lang} Funktionalität in PowerShell\n}\n\nMain\n"
    [tcl]="ext:.tcl,shebang:#!/usr/bin/env tclsh,header:package require Tcl 8.6\n,main_block:proc main {} {\n    # TODO: Implementiere {source_lang} Funktionalität in Tcl\n}\n\nmain\n"
    [ruby]="ext:.rb,shebang:#!/usr/bin/env ruby,header:# frozen_string_literal: true\nrequire 'json'\nrequire 'fileutils'\n,main_block:def main\n  # TODO: Implementiere {source_lang} Funktionalität in Ruby\nend\n\nmain if __FILE__ == \$PROGRAM_NAME\n"
    [lua]="ext:.lua,shebang:#!/usr/bin/env lua,header:,main_block:local function main()\n    -- TODO: Implementiere {source_lang} Funktionalität in Lua\nend\n\nmain()\n"
    [go]="ext:.go,shebang:// +build ignore,header:package main\n\nimport \"fmt\"\n,main_block:func main() {\n    // TODO: Implementiere {source_lang} Funktionalität in Go\n    _ = fmt.Println\n}"
)

# Logging-Setup
setup_logger() {
    mkdir -p "$LOG_DIR"
    readonly LOG_FILE="${LOG_DIR}/$(date +%Y-%m-%d).log"
}

log() {
    local level="$1"
    shift
    local message="$*"
    echo "$(date '+%Y-%m-%d %H:%M:%S') | ${level} | ${FUNCNAME[1]}:${BASH_LINENO[0]} | ${message}" | tee -a "$LOG_FILE"
}

# State-Management
load_state() {
    if [[ -f "$STATE_FILE" ]]; then
        if jq empty "$STATE_FILE" 2>/dev/null; then
            cat "$STATE_FILE"
        else
            log "ERROR" "State-File konnte nicht geparst werden: $STATE_FILE"
            echo '{"processed":{},"queue":[],"current_priority":"high","stats":{"total_scripts":0,"abstractions_created":0}}'
        fi
    else
        echo '{"processed":{},"queue":[],"current_priority":"high","stats":{"total_scripts":0,"abstractions_created":0}}'
    fi
}

save_state() {
    local state="$1"
    mkdir -p "$(dirname "$STATE_FILE")"
    local tmp_file
    tmp_file=$(mktemp -p "$(dirname "$STATE_FILE")" .abstractions_state_XXXXXX.tmp)
    echo "$state" > "$tmp_file"
    mv "$tmp_file" "$STATE_FILE"
    log "DEBUG" "State atomar gespeichert: $STATE_FILE"
}

# Node-Management
check_node_status() {
    local node_id="$1"
    if command -v openclaw >/dev/null 2>&1; then
        if timeout 5 openclaw nodes status "$node_id" 2>/dev/null | grep -qiE "(online|active)"; then
            return 0
        else
            log "WARNING" "Timeout beim Status-Check von $node_id — verwende always_available"
            return 1
        fi
    else
        log "WARNING" "'openclaw'-Binary nicht gefunden — verwende always_available für $node_id"
        return 1
    fi
}

get_job_weight() {
    local script_size="$1"
    local target_langs_count="$2"
    local total_work=$((script_size * target_langs_count))
    if ((total_work > 50000)); then
        echo "heavy"
    elif ((total_work > 10000)); then
        echo "medium"
    else
        echo "light"
    fi
}

get_node_by_priority() {
    local job_weight="${1:-medium}"
    local preferred_order
    case "$job_weight" in
        heavy) preferred_order=("node7" "node2" "node1") ;;
        medium) preferred_order=("node2" "node1" "node7") ;;
        light) preferred_order=("node5" "node1" "node2") ;;
        *) preferred_order=("node1" "node2") ;;
    esac

    for node_id in "${preferred_order[@]}"; do
        if [[ -n "${NODES[$node_id]:-}" ]]; then
            local always_available
            always_available=$(echo "${NODES[$node_id]}" | grep -o "always_available:[^,]*" | cut -d: -f2)
            if [[ "$always_available" == "true" ]] || { [[ "$always_available" == "false" ]] && [[ "$job_weight" == "light" ]]; }; then
                if check_node_status "$node_id" || [[ "$always_available" == "true" ]]; then
                    log "DEBUG" "Node $node_id ausgewählt für ${job_weight}-Job"
                    echo "$node_id"
                    return
                fi
            fi
        fi
    done

    log "WARNING" "Kein passender Node gefunden für Gewicht '$job_weight' — Fallback node1"
    echo "node1"
}

# Script-Verarbeitung
find_scripts_in_dir() {
    local directory="$1"
    shift
    local exclude_patterns=("$@")
    
    if [[ ! -d "$directory" ]]; then
        log "DEBUG" "Verzeichnis existiert nicht: $directory"
        return
    fi

    local find_args=()
    for pattern in "${exclude_patterns[@]}"; do
        find_args+=(-not -path "*/${pattern}/*")
    done

    find "$directory" -type f \( -name "*.py" -o -name "*.js" -o -name "*.sh" -o -name "*.pl" -o -name "*.rb" \) "${find_args[@]}"
}

build_stub_content() {
    local script_path="$1"
    local target_lang="$2"
    local source_lang="$3"
    
    local template
    template="${TARGET_LANGUAGES[$target_lang]}"
    
    local shebang header main_block
    shebang=$(echo "$template" | grep -o "shebang:[^,]*" | cut -d: -f2-)
    header=$(echo "$template" | grep -o "header:[^,]*" | cut -d: -f2- | sed 's/\\n/\n/g')
    main_block=$(echo "$template" | grep -o "main_block:.*" | cut -d: -f2- | sed 's/\\n/\n/g' | sed "s/{source_lang}/$source_lang/g")
    
    local today
    today=$(date +%Y-%m-%d)
    
    local original_lines
    if [[ -r "$script_path" ]]; then
        original_lines=$(head -n 15 "$script_path" 2>/dev/null || echo "")
    else
        log "WARNING" "Originaldatei konnte nicht gelesen werden: $script_path"
        original_lines=""
    fi
    
    local comment_char
    if [[ "$target_lang" == "go" ]] || [[ "$target_lang" == "javascript" ]]; then
        comment_char="//"
    else
        comment_char="#"
    fi
    
    local original_preview=""
    if [[ -n "$original_lines" ]]; then
        while IFS= read -r line; do
            original_preview+="${comment_char} ${line}"$'\n'
        done <<< "$original_lines"
    fi
    
    cat <<EOF
${shebang}
${comment_char} $(basename "$script_path" .${script_path##*.}) - ${target_lang^} Version
${comment_char} Portiert von ${source_lang}
${comment_char} Original: ${script_path}
${comment_char} Erstellt: ${today}

${header}
${comment_char} Original-Code-Referenz:
${original_preview}
${main_block}
EOF
}

create_abstraction() {
    local script_path="$1"
    local target_lang="$2"
    
    if [[ -z "${TARGET_LANGUAGES[$target_lang]:-}" ]]; then
        log "ERROR" "Unbekannte Zielsprache: $target_lang"
        return 1
    fi
    
    local ext_map_py="Python"
    local ext_map_js="JavaScript"
    local ext_map_sh="Shell"
    local ext_map_pl="Perl"
    local ext_map_rb="Ruby"
    
    local source_lang
    case "${script_path##*.}" in
        py) source_lang="$ext_map_py" ;;
        js) source_lang="$ext_map_js" ;;
        sh) source_lang="$ext_map_sh" ;;
        pl) source_lang="$ext_map_pl" ;;
        rb) source_lang="$ext_map_rb" ;;
        *) source_lang="${script_path##*.}" ;;
    esac
    
    local template
    template="${TARGET_LANGUAGES[$target_lang]}"
    local ext
    ext=$(echo "$template" | grep -o "ext:[^,]*" | cut -d: -f2)
    
    local target_dir="${ABSTRACTIONS_REPO}/${target_lang}"
    mkdir -p "$target_dir"
    
    local target_file="${target_dir}/$(basename "$script_path" .${script_path##*.})${ext}"
    if [[ -f "$target_file" ]]; then
        log "DEBUG" "Bereits vorhanden, übersprungen: $target_file"
        return 1
    fi
    
    local content
    content=$(build_stub_content "$script_path" "$target_lang" "$source_lang")
    
    local tmp_file
    tmp_file=$(mktemp -p "$target_dir" .stub_XXXXXX"${ext}")
    echo "$content" > "$tmp_file"
    mv "$tmp_file" "$target_file"
    log "INFO" "Erstellt: $target_file"
    return 0
}

process_on_node() {
    local node_id="$1"
    shift
    local scripts=("$@")
    local target_langs=()
    while IFS= read -r line; do
        target_langs+=("$line")
    done < <(cat)
    
    local created=0
    for script_path in "${scripts[@]}"; do
        for lang in "${target_langs[@]}"; do
            if create_abstraction "$script_path" "$lang"; then
                ((created++))
            fi
        done
    done
    
    echo "$created"
}

# Prioritäts-Verarbeitung
process_priority_high() {
    local target_dirs=(
        "skill-creator:${WORKSPACE}/skills/skill-creator/scripts"
        "json-utils:${WORKSPACE}/skills/json-utils/scripts"
        "scripting-utils:${WORKSPACE}/skills/scripting-utils/scripts"
        "model-usage:${WORKSPACE}/skills/model-usage/scripts"
        "tiktok-live:${WORKSPACE}/skills/tiktok-live/scripts"
    )
    local target_langs=("perl5" "javascript" "python" "shell" "tcl")
    local created=0
    local exclude=("node_modules" ".git" "test" "tests")
    
    for dir_entry in "${target_dirs[@]}"; do
        local skill_name
        skill_name=$(echo "$dir_entry" | cut -d: -f1)
        local scripts_dir
        scripts_dir=$(echo "$dir_entry" | cut -d: -f2)
        
        local scripts=()
        while IFS= read -r line; do
            scripts+=("$line")
        done < <(find_scripts_in_dir "$scripts_dir" "${exclude[@]}" | head -n 10)
        
        log "INFO" "$skill_name: ${#scripts[@]} Scripts gefunden"
        
        for script_path in "${scripts[@]}"; do
            local script_size
            script_size=$(stat -c%s "$script_path" 2>/dev/null || echo "0")
            local job_weight
            job_weight=$(get_job_weight "$script_size" "${#target_langs[@]}")
            local selected_node
            selected_node=$(get_node_by_priority "$job_weight")
            log "INFO" "Verarbeite $(basename "$script_path") ($job_weight) auf $selected_node"
            
            local node_created
            node_created=$(process_on_node "$selected_node" "$script_path" <<<"${target_langs[*]}")
            ((created += node_created))
        done
    done
    
    echo "$created"
}

process_priority_medium() {
    local target_dirs=(
        "workspace-scripts:${WORKSPACE}/scripts"
        "db-maintainer:${WORKSPACE}/skills/db-maintainer/scripts"
        "log-collector:${WORKSPACE}/skills/log-collector/scripts"
    )
    local target_langs=("perl5" "javascript" "powershell" "python")
    local created=0
    local exclude=("node_modules" ".git")
    
    for dir_entry in "${target_dirs[@]}"; do
        local dir_name
        dir_name=$(echo "$dir_entry" | cut -d: -f1)
        local scripts_dir
        scripts_dir=$(echo "$dir_entry" | cut -d: -f2)
        
        local scripts=()
        while IFS= read -r line; do
            scripts+=("$line")
        done < <(find_scripts_in_dir "$scripts_dir" "${exclude[@]}")
        
        local count=0
        for script_path in "${scripts[@]}"; do
            if ((count >= 10)); then
                break
            fi
            
            local script_size
            script_size=$(stat -c%s "$script_path" 2>/dev/null || echo "0")
            local job_weight
            job_weight=$(get_job_weight "$script_size" "${#target_langs[@]}")
            local effective_weight="$job_weight"
            if [[ "$job_weight" == "heavy" ]]; then
                effective_weight="medium"
            fi
            local selected_node
            selected_node=$(get_node_by_priority "$effective_weight")
            log "INFO" "Verarbeite $(basename "$script_path") ($job_weight) auf $selected_node"
            
            local node_created
            node_created=$(process_on_node "$selected_node" "$script_path" <<<"${target_langs[*]}")
            ((created += node_created))
            ((count++))
        done
    done
    
    echo "$created"
}

# Git-Integration
git_commit() {
    local message="$1"
    local repo_str="$ABSTRACTIONS_REPO"
    
    if command -v git >/dev/null 2>&1; then
        if git -C "$repo_str" add . 2>/dev/null && git -C "$repo_str" commit -m "$message" 2>/dev/null; then
            log "INFO" "Git commit erfolgreich: $message"
        else
            log "WARNING" "Git-Befehl fehlgeschlagen"
        fi
    else
        log "ERROR" "'git'-Binary nicht gefunden — Commit übersprungen"
    fi
}

# Status-Report
create_status_report() {
    local state="$1"
    
    if [[ ! -d "$ABSTRACTIONS_REPO" ]]; then
        log "WARNING" "Abstractions-Repo existiert nicht: $ABSTRACTIONS_REPO"
        return
    fi
    
    local report_file="${ABSTRACTIONS_REPO}/STATUS.md"
    {
        echo "# Script Abstractions - Status Report"
        echo
        echo "**Letzte Aktualisierung:** $(date '+%Y-%m-%d %H:%M')"
        echo
        echo "- Aktuelle Priorität: $(echo "$state" | jq -r '.current_priority // "high"')"
        echo "- Verarbeitete Scripts: $(echo "$state" | jq -r '.processed | length')"
        echo "- Abstraktionen gesamt: $(echo "$state" | jq -r '.stats.abstractions_created // 0')"
        echo
        echo "## Abstraktionen pro Sprache"
        echo
        
        for lang in "${!TARGET_LANGUAGES[@]}"; do
            if [[ -d "${ABSTRACTIONS_REPO}/${lang}" ]]; then
                local count
                count=$(find "${ABSTRACTIONS_REPO}/${lang}" -type f | wc -l)
                echo "- ${lang}: ${count}"
            fi
        done
        
        echo
        echo "## Multi-Node Support"
        echo
        echo "| Node | Verfügbarkeit | Kapazität | Priorität | Gerät |"
        echo "|------|---------------|-----------|-----------|-------|"
        
        for node_id in "${!NODES[@]}"; do
            local node_config="${NODES[$node_id]}"
            local always_available
            always_available=$(echo "$node_config" | grep -o "always_available:[^,]*" | cut -d: -f2)
            local capacity
            capacity=$(echo "$node_config" | grep -o "capacity:[^,]*" | cut -d: -f2)
            local priority
            priority=$(echo "$node_config" | grep -o "priority:[^,]*" | cut -d: -f2)
            local device
            device=$(echo "$node_config" | grep -o "device:[^,]*" | cut -d: -f2 || echo "Server")
            
            local avail
            if [[ "$always_available" == "true" ]]; then
                avail="✅ Immer"
            else
                avail="📱 Bedingt"
            fi
            
            echo "| ${node_id} | ${avail} | ${capacity:-unknown} | ${priority:-} | ${device} |"
        done
        
        echo
        echo "### Job-Verteilung"
        echo
        echo "- **Heavy Jobs** (>50 KB × Sprachen) → Node 7 (Docker, hohe Ressourcen)"
        echo "- **Medium Jobs** → Node 2 (Stable), Node 1 (Primary)"
        echo "- **Light Jobs** → Node 5 (Redmi Note 11S, wenn verfügbar)"
    } > "$report_file"
    
    log "INFO" "Status-Report erstellt: $report_file"
}

# Einstiegspunkt
main() {
    setup_logger
    log "INFO" "Script Abstractions Manager (Multi-Node) gestartet"
    
    local state
    state=$(load_state)
    log "INFO" "State geladen: $(echo "$state" | jq -r '.processed | length') bereits verarbeitet"
    
    local current_priority
    current_priority=$(echo "$state" | jq -r '.current_priority // "high"')
    local created=0
    
    if [[ "$current_priority" == "high" ]]; then
        log "INFO" "Verarbeite HIGH-Priorität: Top 5 Skills"
        created=$(process_priority_high)
        if ((created > 0)); then
            git_commit "High priority: ${created} abstractions"
        fi
        state=$(echo "$state" | jq '.current_priority = "medium"')
    elif [[ "$current_priority" == "medium" ]]; then
        log "INFO" "Verarbeite MEDIUM-Priorität: Workspace Scripts"
        created=$(process_priority_medium)
        if ((created > 0)); then
            git_commit "Medium priority: ${created} abstractions"
        fi
        state=$(echo "$state" | jq '.current_priority = "high"')
    fi
    
    local abstractions_total=0
    for lang in "${!TARGET_LANGUAGES[@]}"; do
        if [[ -d "${ABSTRACTIONS_REPO}/${lang}" ]]; then
            local count
            count=$(find "${ABSTRACTIONS_REPO}/${lang}" -type f | wc -l)
            ((abstractions_total += count))
        fi
    done
    
    state=$(echo "$state" | jq ".stats.last_run = \"$(date -Iseconds)\" | .stats.abstractions_created = ${abstractions_total}")
    
    save_state "$state"
    create_status_report "$state"
    
    log "INFO" "Abgeschlossen. ${created} neue Abstraktionen erstellt."
}

main "$@"
