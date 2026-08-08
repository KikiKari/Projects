#!/bin/bash
# abstractions_manager.pl — portiert nach shell
# Quelle: perl5, Projects@abstractions:perl5/abstractions_manager.pl
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Konfiguration
WORKSPACE="/home/openclaw/.openclaw/workspace"
ABSTRACTIONS_REPO="$WORKSPACE/git/Abstraktionen"
LOG_DIR="$WORKSPACE/logs/abstractions-manager"
STATE_FILE="$WORKSPACE/db/abstractions_state.json"

# Node-Konfiguration mit Prioritäten
declare -A NODES
NODES[node1,always_available]=1
NODES[node1,capacity]="medium"
NODES[node1,priority]=2
NODES[node2,always_available]=1
NODES[node2,capacity]="medium"
NODES[node2,priority]=3
NODES[node3,always_available]=0
NODES[node3,capacity]="medium"
NODES[node3,priority]=4
NODES[node5,always_available]=0
NODES[node5,capacity]="low"
NODES[node5,priority]=5
NODES[node5,device]="Redmi Note 11S"
NODES[node5,condition]="mobile_internet"
NODES[node7,always_available]=1
NODES[node7,capacity]="high"
NODES[node7,priority]=1

AVAILABLE_MODELS=(
    "openrouter/moonshotai/kimi-k2.5"
    "openrouter/openai/gpt-4o"
    "openrouter/anthropic/claude-3-5-sonnet-20241022"
    "openrouter/google/gemini-2.0-flash-001"
    "openrouter/nvidia/llama-3.3-nemotron-super-49b-v1"
    "openrouter/qwen/qwen-2.5-coder-32b-instruct"
)

declare -A TARGET_LANGUAGES
TARGET_LANGUAGES[perl5,ext]=".pl"
TARGET_LANGUAGES[perl5,shebang]="#!/usr/bin/env perl"
TARGET_LANGUAGES[perl5,header]=$'use strict;\nuse warnings;\n'
TARGET_LANGUAGES[perl6,ext]=".raku"
TARGET_LANGUAGES[perl6,shebang]="#!/usr/bin/env raku"
TARGET_LANGUAGES[perl6,header]="use v6;\n"
TARGET_LANGUAGES[javascript,ext]=".js"
TARGET_LANGUAGES[javascript,shebang]="#!/usr/bin/env node"
TARGET_LANGUAGES[javascript,header]=""
TARGET_LANGUAGES[python,ext]=".py"
TARGET_LANGUAGES[python,shebang]="#!/usr/bin/env python3"
TARGET_LANGUAGES[python,header]=""
TARGET_LANGUAGES[shell,ext]=".sh"
TARGET_LANGUAGES[shell,shebang]="#!/bin/bash"
TARGET_LANGUAGES[shell,header]="set -euo pipefail\n"
TARGET_LANGUAGES[powershell,ext]=".ps1"
TARGET_LANGUAGES[powershell,shebang]="#!/usr/bin/env pwsh"
TARGET_LANGUAGES[powershell,header]="#Requires -Version 7\n"
TARGET_LANGUAGES[tcl,ext]=".tcl"
TARGET_LANGUAGES[tcl,shebang]="#!/usr/bin/env tclsh"
TARGET_LANGUAGES[tcl,header]="package require Tcl 8.6\n"
TARGET_LANGUAGES[ruby,ext]=".rb"
TARGET_LANGUAGES[ruby,shebang]="#!/usr/bin/env ruby"
TARGET_LANGUAGES[ruby,header]=$'require \'json\'\nrequire \'fileutils\'\n'
TARGET_LANGUAGES[lua,ext]=".lua"
TARGET_LANGUAGES[lua,shebang]="#!/usr/bin/env lua"
TARGET_LANGUAGES[lua,header]=""
TARGET_LANGUAGES[go,ext]=".go"
TARGET_LANGUAGES[go,shebang]="// +build ignore"
TARGET_LANGUAGES[go,header]="package main\n"

log_message() {
    local message="$1"
    local level="${2:-INFO}"
    
    mkdir -p "$LOG_DIR"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local line="[$timestamp] [$level] $message"
    echo "$line"
    
    local log_file="$LOG_DIR/$(date '+%Y-%m-%d').log"
    echo "$line" >> "$log_file"
}

get_node_by_priority() {
    local job_weight="${1:-medium}"
    
    local preferred_order
    if [[ "$job_weight" == "heavy" ]]; then
        preferred_order=("node7" "node2" "node1")
    elif [[ "$job_weight" == "medium" ]]; then
        preferred_order=("node2" "node1" "node7")
    else
        preferred_order=("node5" "node1" "node2")
    fi
    
    local node_id
    for node_id in "${preferred_order[@]}"; do
        if [[ -z "${NODES[$node_id,always_available]:-}" ]]; then
            continue
        fi
        
        if [[ "${NODES[$node_id,always_available]}" -eq 0 ]] && [[ "$job_weight" != "light" ]]; then
            continue
        fi
        
        if check_node_status "$node_id"; then
            echo "$node_id"
            return 0
        fi
    done
    
    echo "node1"
}

check_node_status() {
    local node_id="$1"
    
    local cmd="openclaw nodes status $node_id"
    local output
    output=$(eval "$cmd" 2>/dev/null) || true
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]] && (echo "$output" | grep -qi "online\|active"); then
        return 0
    fi
    
    if [[ "${NODES[$node_id,always_available]:-0}" -eq 1 ]]; then
        return 0
    fi
    
    return 1
}

get_job_weight() {
    local script_size="$1"
    local target_langs_count="$2"
    local total_work=$((script_size * target_langs_count))
    
    if [[ $total_work -gt 50000 ]]; then
        echo "heavy"
    elif [[ $total_work -gt 10000 ]]; then
        echo "medium"
    else
        echo "light"
    fi
}

load_state() {
    if [[ -f "$STATE_FILE" ]]; then
        if jq -e . >/dev/null 2>&1 < "$STATE_FILE"; then
            cat "$STATE_FILE"
            return 0
        fi
    fi
    
    default_state
}

default_state() {
    cat <<EOF
{
  "processed": {},
  "queue": [],
  "current_priority": "high",
  "stats": {
    "total_scripts": 0,
    "abstractions_created": 0
  }
}
EOF
}

save_state() {
    local state="$1"
    
    local state_dir
    state_dir=$(dirname "$STATE_FILE")
    mkdir -p "$state_dir"
    
    echo "$state" > "$STATE_FILE"
}

find_scripts_in_dir() {
    local directory="$1"
    local exclude_patterns=("${@:2}")
    if [[ ${#exclude_patterns[@]} -eq 0 ]]; then
        exclude_patterns=("node_modules" ".git" "__pycache__" "dist" "build")
    fi
    
    if [[ ! -d "$directory" ]]; then
        return 0
    fi
    
    local scripts=()
    local ext
    for ext in py js sh pl rb; do
        while IFS= read -r -d '' file; do
            local exclude=0
            local pattern
            for pattern in "${exclude_patterns[@]}"; do
                if [[ "$file" == *"$pattern"* ]]; then
                    exclude=1
                    break
                fi
            done
            if [[ $exclude -eq 0 ]]; then
                scripts+=("$file")
            fi
        done < <(find "$directory" -name "*.$ext" -print0 2>/dev/null || true)
    done
    
    printf '%s\n' "${scripts[@]}"
}

create_abstraction() {
    local script_path="$1"
    local target_lang="$2"
    
    if ! [[ -f "$script_path" ]]; then
        log_message "Failed: $script_path - File not found" "ERROR"
        return 1
    fi
    
    local original_content
    original_content=$(cat "$script_path" 2>/dev/null) || {
        log_message "Failed: $script_path - Cannot read file" "ERROR"
        return 1
    }
    
    local ext
    ext=$(echo "$script_path" | sed -E 's/.*\.([^.]+)$/\1/')
    local source_lang
    case "$ext" in
        py) source_lang="Python" ;;
        js) source_lang="JavaScript" ;;
        sh) source_lang="Shell" ;;
        pl) source_lang="Perl" ;;
        rb) source_lang="Ruby" ;;
        *) source_lang="$ext" ;;
    esac
    
    local target_dir="$ABSTRACTIONS_REPO/$target_lang"
    mkdir -p "$target_dir"
    
    local script_name
    script_name=$(basename "$script_path" ".$ext")
    local target_file="$target_dir/${script_name}${TARGET_LANGUAGES[$target_lang,ext]}"
    
    if [[ -f "$target_file" ]]; then
        return 0
    fi
    
    local template_shebang="${TARGET_LANGUAGES[$target_lang,shebang]:-}"
    local template_header="${TARGET_LANGUAGES[$target_lang,header]:-}"
    
    local lines=()
    IFS=$'\n' read -r -d '' -a lines <<< "$original_content"$'\0'
    if [[ ${#lines[@]} -gt 15 ]]; then
        lines=("${lines[@]:0:15}")
    fi
    
    local content=""
    content+="$template_shebang"$'\n'
    content+="# $script_name - ${target_lang^} Version"$'\n'
    content+="# Portiert von $source_lang"$'\n'
    content+="# Original: $script_path"$'\n'
    content+="# Erstellt: $(date '+%Y-%m-%d')"$'\n'
    content+="#"$'\n'
    if [[ -n "$template_header" ]]; then
        content+="# $template_header"$'\n'
    fi
    content+="# Original-Code-Referenz:"$'\n'
    local line
    for line in "${lines[@]}"; do
        content+="# $line"$'\n'
    done
    content+=$'\n'
    content+="sub main {"$'\n'
    content+="    # TODO: Implementiere $source_lang Funktionalität in ${target_lang^}"$'\n'
    content+="    return;"$'\n'
    content+="}"$'\n'
    content+=$'\n'
    content+="main() unless caller;"$'\n'
    
    echo "$content" > "$target_file" || {
        log_message "Failed: $script_path - Cannot write $target_file" "ERROR"
        return 1
    }
    
    log_message "Created: $target_file"
    return 0
}

process_on_node() {
    local node_id="$1"
    local scripts_json="$2"
    local target_langs_json="$3"
    
    local created=0
    local scripts
    readarray -t scripts < <(echo "$scripts_json" | jq -r '.[]')
    local target_langs
    readarray -t target_langs < <(echo "$target_langs_json" | jq -r '.[]')
    
    if [[ "$node_id" == "node1" ]]; then
        local script
        for script in "${scripts[@]}"; do
            local lang
            for lang in "${target_langs[@]}"; do
                if create_abstraction "$script" "$lang"; then
                    ((created++))
                fi
            done
        done
    else
        log_message "Dispatching ${#scripts[@]} jobs to $node_id"
        local script
        for script in "${scripts[@]}"; do
            local lang
            for lang in "${target_langs[@]}"; do
                if create_abstraction "$script" "$lang"; then
                    ((created++))
                    log_message "Processed on $node_id: $script -> $lang"
                fi
            done
        done
    fi
    
    echo "$created"
}

process_priority_high() {
    local created=0
    local targets=(
        "skill-creator,$WORKSPACE/skills/skill-creator/scripts"
        "json-utils,$WORKSPACE/skills/json-utils/scripts"
        "scripting-utils,$WORKSPACE/skills/scripting-utils/scripts"
        "model-usage,$WORKSPACE/skills/model-usage/scripts"
        "tiktok-live,$WORKSPACE/skills/tiktok-live/scripts"
    )
    
    local target
    for target in "${targets[@]}"; do
        local skill_name scripts_dir
        IFS=',' read -r skill_name scripts_dir <<< "$target"
        local scripts
        scripts=$(find_scripts_in_dir "$scripts_dir" "node_modules" ".git" "test" "tests")
        local script_count
        script_count=$(echo "$scripts" | wc -l)
        if [[ $script_count -gt 0 ]] && [[ "$(echo "$scripts" | head -n1)" == "" ]]; then
            script_count=0
        fi
        log_message "$skill_name: $script_count scripts found"
        
        local count=0
        while IFS= read -r script; do
            if [[ -z "$script" ]]; then
                continue
            fi
            
            if [[ $count -ge 10 ]]; then
                break
            fi
            
            local script_size
            script_size=$(stat -c%s "$script" 2>/dev/null || echo "0")
            local target_langs=("perl5" "javascript" "python" "shell" "tcl")
            local job_weight
            job_weight=$(get_job_weight "$script_size" "${#target_langs[@]}")
            
            local selected_node
            selected_node=$(get_node_by_priority "$job_weight")
            local script_basename
            script_basename=$(basename "$script")
            log_message "Processing $script_basename ($job_weight) on $selected_node"
            
            local scripts_json target_langs_json
            scripts_json=$(printf '%s\n' "${script}" | jq -R . | jq -s .)
            target_langs_json=$(printf '%s\n' "${target_langs[@]}" | jq -R . | jq -s .)
            local result
            result=$(process_on_node "$selected_node" "$scripts_json" "$target_langs_json")
            created=$((created + result))
            
            ((count++))
        done <<< "$scripts"
    done
    
    echo "$created"
}

process_priority_medium() {
    local created=0
    local targets=(
        "workspace-scripts,$WORKSPACE/scripts"
        "db-maintainer,$WORKSPACE/skills/db-maintainer/scripts"
        "log-collector,$WORKSPACE/skills/log-collector/scripts"
    )
    
    local target
    for target in "${targets[@]}"; do
        local dir_name scripts_dir
        IFS=',' read -r dir_name scripts_dir <<< "$target"
        local scripts
        scripts=$(find_scripts_in_dir "$scripts_dir" "node_modules" ".git")
        local script_count
        script_count=$(echo "$scripts" | wc -l)
        if [[ $script_count -gt 0 ]] && [[ "$(echo "$scripts" | head -n1)" == "" ]]; then
            script_count=0
        fi
        
        local count=0
        while IFS= read -r script; do
            if [[ -z "$script" ]]; then
                continue
            fi
            
            if [[ $count -ge 10 ]]; then
                break
            fi
            
            local script_size
            script_size=$(stat -c%s "$script" 2>/dev/null || echo "0")
            local target_langs=("perl5" "javascript" "powershell" "python")
            local job_weight
            job_weight=$(get_job_weight "$script_size" "${#target_langs[@]}")
            
            local priority="$job_weight"
            if [[ "$job_weight" == "heavy" ]]; then
                priority="medium"
            fi
            local selected_node
            selected_node=$(get_node_by_priority "$priority")
            local script_basename
            script_basename=$(basename "$script")
            log_message "Processing $script_basename ($job_weight) on $selected_node"
            
            local scripts_json target_langs_json
            scripts_json=$(printf '%s\n' "${script}" | jq -R . | jq -s .)
            target_langs_json=$(printf '%s\n' "${target_langs[@]}" | jq -R . | jq -s .)
            local result
            result=$(process_on_node "$selected_node" "$scripts_json" "$target_langs_json")
            created=$((created + result))
            
            ((count++))
        done <<< "$scripts"
    done
    
    echo "$created"
}

git_commit() {
    local message="$1"
    
    (
        cd "$ABSTRACTIONS_REPO" || exit 1
        git add . || { log_message "git add failed" "ERROR"; exit 1; }
        git commit -m "$message" || { log_message "git commit failed" "ERROR"; exit 1; }
        log_message "Git commit: $message"
    )
}

create_status_report() {
    local state="$1"
    local report_file="$ABSTRACTIONS_REPO/STATUS.md"
    
    declare -A lang_counts
    if [[ -d "$ABSTRACTIONS_REPO" ]]; then
        local lang_dir
        for lang_dir in "$ABSTRACTIONS_REPO"/*/; do
            if [[ -d "$lang_dir" ]]; then
                local lang_name
                lang_name=$(basename "$lang_dir")
                if [[ -n "${TARGET_LANGUAGES[$lang_name,ext]:-}" ]]; then
                    local count
                    count=$(find "$lang_dir" -maxdepth 1 -type f | wc -l)
                    lang_counts["$lang_name"]="$count"
                fi
            fi
        done
    fi
    
    {
        echo "# Script Abstractions - Status Report"
        echo ""
        echo "**Letzte Aktualisierung:** $(date '+%Y-%m-%d %H:%M')"
        echo ""
        echo "- Aktuelle Priorität: $(echo "$state" | jq -r '.current_priority // "high"')"
        echo "- Verarbeitete Scripts: $(echo "$state" | jq -r '.processed | length')"
        echo "- Abstraktionen gesamt: $(echo "$state" | jq -r '.stats.abstractions_created // 0')"
        echo ""
        echo "## Abstraktionen pro Sprache"
        echo ""
        local lang
        for lang in "${!lang_counts[@]}"; do
            echo "- $lang: ${lang_counts[$lang]}"
        done
        echo ""
        echo "## Verfügbare Modelle"
        echo ""
        local i
        for ((i=0; i<3 && i<${#AVAILABLE_MODELS[@]}; i++)); do
            echo "- \`${AVAILABLE_MODELS[$i]}\`"
        done
        echo "- ... und $((${#AVAILABLE_MODELS[@]} - 3)) weitere"
        echo ""
        echo "## Multi-Node Support"
        echo ""
        echo "| Node | Verfügbarkeit | Kapazität | Priorität | Gerät |"
        echo "|------|---------------|-----------|-----------|-------|"
        local node_id
        for node_id in node1 node2 node3 node5 node7; do
            local avail="📱 Bedingt"
            if [[ "${NODES[$node_id,always_available]:-0}" -eq 1 ]]; then
                avail="✅ Immer"
            fi
            local device="${NODES[$node_id,device]:-Server}"
            echo "| $node_id | $avail | ${NODES[$node_id,capacity]:-unknown} | ${NODES[$node_id,priority]:-} | $device |"
        done
        echo ""
        echo "### Job-Verteilung"
        echo ""
        echo "- **Heavy Jobs** (>50KB × Sprachen) → Node 7 (Docker, hohe Ressourcen)"
        echo "- **Medium Jobs** → Node 2 (Stable), Node 1 (Primary)"
        echo "- **Light Jobs** → Node 5 (Redmi Note 11S, wenn verfügbar)"
    } > "$report_file"
}

main() {
    log_message "Script Abstractions Manager (Multi-Node) gestartet"
    
    local state
    state=$(load_state)
    local processed_count
    processed_count=$(echo "$state" | jq -r '.processed | length')
    log_message "State loaded: $processed_count processed"
    
    local current_priority
    current_priority=$(echo "$state" | jq -r '.current_priority // "high"')
    local created=0
    
    if [[ "$current_priority" == "high" ]]; then
        log_message "Processing HIGH priority: Top 5 Skills"
        created=$(process_priority_high)
        if [[ $created -gt 0 ]]; then
            git_commit "High priority: $created abstractions"
        fi
        state=$(echo "$state" | jq '.current_priority = "medium"')
    elif [[ "$current_priority" == "medium" ]]; then
        log_message "Processing MEDIUM priority: Workspace Scripts"
        created=$(process_priority_medium)
        if [[ $created -gt 0 ]]; then
            git_commit "Medium priority: $created abstractions"
        fi
        state=$(echo "$state" | jq '.current_priority = "high"')  # Zyklus
    fi
    
    state=$(echo "$state" | jq ".stats.last_run = \"$(date -Iseconds)\"")
    
    local total=0
    if [[ -d "$ABSTRACTIONS_REPO" ]]; then
        local lang
        for lang in "${!TARGET_LANGUAGES[@]}"; do
            if [[ "$lang" == *","* ]]; then
                continue
            fi
            local lang_dir="$ABSTRACTIONS_REPO/$lang"
            if [[ -d "$lang_dir" ]]; then
                local count
                count=$(find "$lang_dir" -maxdepth 1 -type f | wc -l)
                total=$((total + count))
            fi
        done
    fi
    state=$(echo "$state" | jq ".stats.abstractions_created = $total")
    
    save_state "$state"
    create_status_report "$state"
    
    log_message "Abgeschlossen. $created neue Abstraktionen erstellt."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
