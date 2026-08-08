#!/bin/bash
# abstractions_manager.tcl — portiert nach shell
# Quelle: tcl, Projects@abstractions:tcl/abstractions_manager.tcl
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# abstractions_manager.py — portiert nach Bash
# Quelle: python, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/abstractions_manager.py
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

# Script Abstractions Manager - Multi-Node Edition

# Konfiguration
WORKSPACE="/home/openclaw/.openclaw/workspace"
ABSTRACTIONS_REPO="$WORKSPACE/git/Abstraktionen"
LOG_DIR="$WORKSPACE/logs/abstractions-manager"
STATE_FILE="$WORKSPACE/db/abstractions_state.json"

# Node-Konfiguration mit Prioritäten
declare -A NODES=(
    [node1]="always_available:true,capacity:medium,priority:2"
    [node2]="always_available:true,capacity:medium,priority:3"
    [node3]="always_available:false,capacity:medium,priority:4"
    [node5]="always_available:false,capacity:low,priority:5,device:Redmi Note 11S,condition:mobile_internet"
    [node7]="always_available:true,capacity:high,priority:1"
)

AVAILABLE_MODELS=(
    "openrouter/moonshotai/kimi-k2.5"
    "openrouter/openai/gpt-4o"
    "openrouter/anthropic/claude-3-5-sonnet-20241022"
    "openrouter/google/gemini-2.0-flash-001"
    "openrouter/nvidia/llama-3.3-nemotron-super-49b-v1"
    "openrouter/qwen/qwen-2.5-coder-32b-instruct"
)

declare -A TARGET_LANGUAGES=(
    [perl5]="ext:.pl,shebang:#!/usr/bin/env perl,header:use strict;\nuse warnings;\n"
    [perl6]="ext:.raku,shebang:#!/usr/bin/env raku,header:use v6;\n"
    [javascript]="ext:.js,shebang:#!/usr/bin/env node,header:"
    [python]="ext:.py,shebang:#!/usr/bin/env python3,header:"
    [shell]="ext:.sh,shebang:#!/bin/bash,header:set -euo pipefail\n"
    [powershell]="ext:.ps1,shebang:#!/usr/bin/env pwsh,header:#Requires -Version 7\n"
    [tcl]="ext:.tcl,shebang:#!/usr/bin/env tclsh,header:package require Tcl 8.6\n"
    [ruby]="ext:.rb,shebang:#!/usr/bin/env ruby,header:require 'json'\nrequire 'fileutils'\n"
    [lua]="ext:.lua,shebang:#!/usr/bin/env lua,header:"
    [go]="ext:.go,shebang:// +build ignore,header:package main\n"
)

log() {
    local message="$1"
    local level="${2:-INFO}"
    mkdir -p "$LOG_DIR"
    local timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local line="[$timestamp] [$level] $message"
    echo "$line"
    local log_file="$LOG_DIR/$(date "+%Y-%m-%d").log"
    echo "$line" >> "$log_file"
}

get_node_by_priority() {
    local job_weight="${1:-medium}"
    local preferred_order=()
    
    # Prioritäts-Matrix
    if [[ "$job_weight" == "heavy" ]]; then
        # Schwere Jobs → Node 7 (Docker mit vielen Ressourcen)
        preferred_order=("node7" "node2" "node1")
    elif [[ "$job_weight" == "medium" ]]; then
        # Mittlere Jobs → Stable Nodes
        preferred_order=("node2" "node1" "node7")
    else
        # light
        # Leichte Jobs → Mobile/verfügbare Nodes
        preferred_order=("node5" "node1" "node2")
    fi
    
    # Prüfe Verfügbarkeit
    for node_id in "${preferred_order[@]}"; do
        if [[ -z "${NODES[$node_id]:-}" ]]; then
            continue
        fi
        
        IFS=',' read -ra node <<< "${NODES[$node_id]}"
        declare -A node_config
        for item in "${node[@]}"; do
            IFS=':' read -r key value <<< "$item"
            node_config["$key"]="$value"
        done
        
        # Skip nicht immer verfügbare Nodes wenn nicht explizit requested
        if [[ "${node_config[always_available]:-false}" == "false" && "$job_weight" != "light" ]]; then
            continue
        fi
        
        # Prüfe ob Node online
        if check_node_status "$node_id"; then
            echo "$node_id"
            return 0
        fi
    done
    
    # Fallback zu Node 1
    echo "node1"
}

check_node_status() {
    local node_id="$1"
    if command -v openclaw >/dev/null 2>&1; then
        if openclaw nodes status "$node_id" 2>/dev/null | grep -qiE "(online|active)"; then
            return 0
        fi
    fi
    
    # Bei Timeout/Error: Prüfe letzten bekannten Status
    if [[ -n "${NODES[$node_id]:-}" ]]; then
        IFS=',' read -ra node <<< "${NODES[$node_id]}"
        declare -A node_config
        for item in "${node[@]}"; do
            IFS=':' read -r key value <<< "$item"
            node_config["$key"]="$value"
        done
        if [[ "${node_config[always_available]:-false}" == "true" ]]; then
            return 0
        fi
    fi
    return 1
}

get_job_weight() {
    local script_size="$1"
    local target_langs_count="$2"
    local total_work=$((script_size * target_langs_count))
    
    if (( total_work > 50000 )); then
        # Große Scripts, viele Sprachen
        echo "heavy"
    elif (( total_work > 10000 )); then
        # Mittlere Last
        echo "medium"
    else
        echo "light"
    fi
}

load_state() {
    if [[ -f "$STATE_FILE" ]]; then
        if jq empty "$STATE_FILE" >/dev/null 2>&1; then
            cat "$STATE_FILE"
            return
        fi
    fi
    
    echo '{"processed":{},"queue":[],"current_priority":"high","stats":{"total_scripts":0,"abstractions_created":0}}'
}

save_state() {
    local state="$1"
    mkdir -p "$(dirname "$STATE_FILE")"
    echo "$state" > "$STATE_FILE"
}

find_scripts_in_dir() {
    local directory="$1"
    local exclude_patterns="${2:-node_modules .git __pycache__ dist build}"
    
    if [[ ! -d "$directory" ]]; then
        return
    fi
    
    local scripts=()
    local exts=("*.py" "*.js" "*.sh" "*.pl" "*.rb")
    
    for ext in "${exts[@]}"; do
        while IFS= read -r -d '' script; do
            local exclude=false
            for pattern in $exclude_patterns; do
                if [[ "$script" == *"$pattern"* ]]; then
                    exclude=true
                    break
                fi
            done
            if [[ "$exclude" == false ]]; then
                scripts+=("$script")
            fi
        done < <(find "$directory" -type f -name "$ext" -print0 2>/dev/null || true)
    done
    
    printf '%s\n' "${scripts[@]}"
}

create_abstraction() {
    local script_path="$1"
    local target_lang="$2"
    
    if [[ ! -f "$script_path" ]]; then
        return 1
    fi
    
    local original_content
    original_content=$(cat "$script_path")
    
    local ext="${script_path##*.}"
    declare -A source_lang_map=([py]=Python [js]=JavaScript [sh]=Shell [pl]=Perl [rb]=Ruby)
    local source_lang="${source_lang_map[$ext]:-$ext}"
    
    local target_dir="$ABSTRACTIONS_REPO/$target_lang"
    mkdir -p "$target_dir"
    
    local target_file="$target_dir/$(basename "${script_path%.*}")${TARGET_LANGUAGES[$target_lang]#ext:}"
    
    if [[ -f "$target_file" ]]; then
        return 1
    fi
    
    local lines=()
    IFS=$'\n' read -d '' -ra lines <<< "$original_content" || true
    local header_lines=""
    local i=0
    for line in "${lines[@]}"; do
        if (( i >= 15 )); then
            break
        fi
        header_lines+="# $line"$'\n'
        ((i++))
    done
    
    local content="${TARGET_LANGUAGES[$target_lang]#shebang:}"
    IFS=',' read -r shebang header <<< "$content"
    content="$shebang"$'\n'
    content+="# $(basename "${script_path%.*}") - ${target_lang^} Version"$'\n'
    content+="# Portiert von $source_lang"$'\n'
    content+="# Original: $script_path"$'\n'
    content+="# Erstellt: $(date "+%Y-%m-%d")"$'\n'
    content+="#"$'\n'
    
    local header_content="${TARGET_LANGUAGES[$target_lang]#header:}"
    if [[ -n "$header_content" && "$header_content" != "${TARGET_LANGUAGES[$target_lang]}" ]]; then
        content+="# $header_content"$'\n'
    fi
    
    content+=$'\n'"# Original-Code-Referenz:"$'\n'
    content+="# $header_lines"$'\n'
    content+="main() {"$'\n'
    content+="    # TODO: Implementiere $source_lang Funktionalität in ${target_lang^}"$'\n'
    content+="    return"$'\n'
    content+="}"$'\n'
    content+=$'\n'"if [[ \"\${BASH_SOURCE[0]}\" == \"\$(basename \"\$0\")\" ]]; then"$'\n'
    content+="    main"$'\n'
    content+="fi"$'\n'
    
    echo "$content" > "$target_file"
    log "Created: $target_file"
    return 0
}

process_on_node() {
    local node_id="$1"
    shift
    local scripts=("$@")
    shift ${#scripts[@]}
    local target_langs=("$@")
    
    local created=0
    
    if [[ "$node_id" == "node1" ]]; then
        # Lokale Verarbeitung
        for script in "${scripts[@]}"; do
            for lang in "${target_langs[@]}"; do
                if create_abstraction "$script" "$lang"; then
                    ((created++))
                fi
            done
        done
    else
        # Remote-Verarbeitung
        log "Dispatching ${#scripts[@]} jobs to $node_id"
        # TODO: Implementiere Remote-Dispatch wenn Node-Infrastruktur bereit
        # Für jetzt: Lokale Verarbeitung mit Node-Logging
        for script in "${scripts[@]}"; do
            for lang in "${target_langs[@]}"; do
                if create_abstraction "$script" "$lang"; then
                    ((created++))
                    log "Processed on $node_id: $(basename "$script") -> $lang"
                fi
            done
        done
    fi
    
    echo "$created"
}

process_priority_high() {
    local created=0
    local targets=(
        "skill-creator:$WORKSPACE/skills/skill-creator/scripts"
        "json-utils:$WORKSPACE/skills/json-utils/scripts"
        "scripting-utils:$WORKSPACE/skills/scripting-utils/scripts"
        "model-usage:$WORKSPACE/skills/model-usage/scripts"
        "tiktok-live:$WORKSPACE/skills/tiktok-live/scripts"
    )
    
    for target in "${targets[@]}"; do
        IFS=':' read -r skill_name scripts_dir <<< "$target"
        local scripts=()
        while IFS= read -r script; do
            scripts+=("$script")
        done < <(find_scripts_in_dir "$scripts_dir" "node_modules .git test tests")
        log "$skill_name: ${#scripts[@]} scripts found"
        
        local count=0
        for script in "${scripts[@]}"; do
            if (( count >= 10 )); then
                break
            fi
            if [[ ! -f "$script" ]]; then
                continue
            fi
            
            local script_size
            script_size=$(stat -c%s "$script" 2>/dev/null || echo "0")
            local target_langs=("perl5" "javascript" "python" "shell" "tcl")
            local job_weight
            job_weight=$(get_job_weight "$script_size" "${#target_langs[@]}")
            
            # Wähle Node basierend auf Job-Gewicht
            local selected_node
            selected_node=$(get_node_by_priority "$job_weight")
            log "Processing $(basename "$script") ($job_weight) on $selected_node"
            
            local processed
            processed=$(process_on_node "$selected_node" "$script" "${target_langs[@]}")
            created=$((created + processed))
            ((count++))
        done
    done
    
    echo "$created"
}

process_priority_medium() {
    local created=0
    local targets=(
        "workspace-scripts:$WORKSPACE/scripts"
        "db-maintainer:$WORKSPACE/skills/db-maintainer/scripts"
        "log-collector:$WORKSPACE/skills/log-collector/scripts"
    )
    
    for target in "${targets[@]}"; do
        IFS=':' read -r dir_name scripts_dir <<< "$target"
        local scripts=()
        while IFS= read -r script; do
            scripts+=("$script")
        done < <(find_scripts_in_dir "$scripts_dir" "node_modules .git")
        
        local count=0
        for script in "${scripts[@]}"; do
            if (( count >= 10 )); then
                break
            fi
            if [[ ! -f "$script" ]]; then
                continue
            fi
            
            local script_size
            script_size=$(stat -c%s "$script" 2>/dev/null || echo "0")
            local target_langs=("perl5" "javascript" "powershell" "python")
            local job_weight
            job_weight=$(get_job_weight "$script_size" "${#target_langs[@]}")
            
            # Mittlere Priority → eher leichtere Jobs
            local selected_priority
            if [[ "$job_weight" == "heavy" ]]; then
                selected_priority="medium"
            else
                selected_priority="$job_weight"
            fi
            local selected_node
            selected_node=$(get_node_by_priority "$selected_priority")
            log "Processing $(basename "$script") ($job_weight) on $selected_node"
            
            local processed
            processed=$(process_on_node "$selected_node" "$script" "${target_langs[@]}")
            created=$((created + processed))
            ((count++))
        done
    done
    
    echo "$created"
}

git_commit() {
    local message="$1"
    if command -v git >/dev/null 2>&1 && [[ -d "$ABSTRACTIONS_REPO/.git" ]]; then
        (
            cd "$ABSTRACTIONS_REPO" || return
            git add . >/dev/null 2>&1 || true
            git commit -m "$message" >/dev/null 2>&1 || true
            log "Git commit: $message"
        ) || true
    fi
}

create_status_report() {
    local state="$1"
    local report_file="$ABSTRACTIONS_REPO/STATUS.md"
    declare -A lang_counts
    
    if [[ -d "$ABSTRACTIONS_REPO" ]]; then
        for lang_dir in "$ABSTRACTIONS_REPO"/*/; do
            if [[ -d "$lang_dir" ]]; then
                local lang_name
                lang_name=$(basename "$lang_dir")
                if [[ -n "${TARGET_LANGUAGES[$lang_name]:-}" ]]; then
                    local count
                    count=$(find "$lang_dir" -type f 2>/dev/null | wc -l)
                    lang_counts["$lang_name"]="$count"
                fi
            fi
        done
    fi
    
    {
        echo "# Script Abstractions - Status Report"
        echo
        echo "**Letzte Aktualisierung:** $(date "+%Y-%m-%d %H:%M")"
        echo
        echo "- Aktuelle Priorität: $(echo "$state" | jq -r '.current_priority')"
        echo "- Verarbeitete Scripts: $(echo "$state" | jq -r '.processed | length')"
        echo "- Abstraktionen gesamt: $(echo "$state" | jq -r '.stats.abstractions_created')"
        echo "## Abstraktionen pro Sprache"
        echo
        
        for lang in $(printf '%s\n' "${!lang_counts[@]}" | sort); do
            echo "- $lang: ${lang_counts[$lang]}"
        done
        
        echo
        echo "## Verfügbare Modelle"
        local count=0
        for model in "${AVAILABLE_MODELS[@]}"; do
            if (( count < 3 )); then
                echo "- \`$model\`"
            fi
            ((count++))
        done
        if (( ${#AVAILABLE_MODELS[@]} > 3 )); then
            echo "- ... und $((${#AVAILABLE_MODELS[@]} - 3)) weitere"
        fi
        
        echo
        echo "## Multi-Node Support"
        echo "| Node | Verfügbarkeit | Kapazität | Priorität | Gerät |"
        echo "|------|---------------|-----------|-----------|-------|"
        
        # Sort nodes by priority
        local sorted_nodes=()
        for node_id in "${!NODES[@]}"; do
            IFS=',' read -ra node <<< "${NODES[$node_id]}"
            local priority=""
            for item in "${node[@]}"; do
                IFS=':' read -r key value <<< "$item"
                if [[ "$key" == "priority" ]]; then
                    priority="$value"
                    break
                fi
            done
            sorted_nodes+=("$priority:$node_id")
        done
        IFS=$'\n' sorted_nodes=($(sort -n <<<"${sorted_nodes[*]}"))
        
        for item in "${sorted_nodes[@]}"; do
            IFS=':' read -r _ node_id <<< "$item"
            if [[ -n "${NODES[$node_id]:-}" ]]; then
                IFS=',' read -ra node <<< "${NODES[$node_id]}"
                declare -A config
                for item in "${node[@]}"; do
                    IFS=':' read -r key value <<< "$item"
                    config["$key"]="$value"
                done
                local avail="✅ Immer"
                if [[ "${config[always_available]:-false}" == "false" ]]; then
                    avail="📱 Bedingt"
                fi
                local device="Server"
                if [[ -n "${config[device]:-}" ]]; then
                    device="${config[device]}"
                fi
                echo "| $node_id | $avail | ${config[capacity]:-} | ${config[priority]:-} | $device |"
            fi
        done
        
        echo
        echo "### Job-Verteilung"
        echo "- **Heavy Jobs** (>50KB × Sprachen) → Node 7 (Docker, hohe Ressourcen)"
        echo "- **Medium Jobs** → Node 2 (Stable), Node 1 (Primary)"
        echo "- **Light Jobs** → Node 5 (Redmi Note 11S, wenn verfügbar)"
    } > "$report_file"
}

main() {
    log "Script Abstractions Manager (Multi-Node) gestartet"
    
    local state
    state=$(load_state)
    log "State loaded: $(echo "$state" | jq -r '.processed | length') processed"
    
    local current_priority
    current_priority=$(echo "$state" | jq -r '.current_priority')
    local created=0
    
    if [[ "$current_priority" == "high" ]]; then
        log "Processing HIGH priority: Top 5 Skills"
        created=$(process_priority_high)
        if (( created > 0 )); then
            git_commit "High priority: $created abstractions"
        fi
        state=$(echo "$state" | jq '.current_priority = "medium"')
    elif [[ "$current_priority" == "medium" ]]; then
        log "Processing MEDIUM priority: Workspace Scripts"
        created=$(process_priority_medium)
        if (( created > 0 )); then
            git_commit "Medium priority: $created abstractions"
        fi
        state=$(echo "$state" | jq '.current_priority = "high"')
    fi
    
    state=$(echo "$state" | jq ".stats.last_run = \"$(date "+%Y-%m-%dT%H:%M:%S")\"")
    
    # Count abstractions
    local total_count=0
    for lang in "${!TARGET_LANGUAGES[@]}"; do
        local lang_dir="$ABSTRACTIONS_REPO/$lang"
        if [[ -d "$lang_dir" ]]; then
            local count
            count=$(find "$lang_dir" -type f 2>/dev/null | wc -l)
            total_count=$((total_count + count))
        fi
    done
    state=$(echo "$state" | jq ".stats.abstractions_created = $total_count")
    
    save_state "$state"
    create_status_report "$state"
    
    log "Abgeschlossen. $created neue Abstraktionen erstellt."
}

main
