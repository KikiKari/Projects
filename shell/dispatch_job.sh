#!/usr/bin/env bash
# dispatch_job.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:skills/multi-nodes-utils/scripts/dispatch_job.py
# Erzeugt: 2026-11-16 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Job Dispatcher - Verteilt Jobs auf passende Nodes

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Node-Konfiguration
declare -A NODES=(
    [node1]="always_available:true,capacity:medium,priority:3,description:Gateway"
    [node2]="always_available:false,capacity:high,priority:1,description:ARM Server"
    [node3]="always_available:false,capacity:medium,priority:4,description:AMD Server"
    [node4]="always_available:false,capacity:low,priority:5,device:Redmi Note 11S"
    [node5]="always_available:false,capacity:high,priority:2,device:Lenovo"
    [node6]="always_available:false,device:Lenovo (Docker)"
)

declare -A NODE_NAMES=(
    [node2]="openclaw-node2 arm64-node v2202604104722449961 v2202604104722449961.taild25fea.ts.net 100.82.198.122"
    [node3]="openclaw-node3 openclaw-node3.taild25fea.ts.net 100.73.154.125"
    [node4]="openclaw-node4 redmi-note-11s redmi-note-11s.taild25fea.ts.net 100.94.134.39"
    [node5]="openclaw-node5 windows node (lenovo-7)"
    [node6]="openclaw-node6"
)

_job_weight_bytes() {
    local script_path="$1"
    local target_langs_count="$2"
    
    if [[ ! -f "$script_path" ]]; then
        echo 0
        return
    fi
    
    local size
    size=$(stat -c%s "$script_path" 2>/dev/null || stat -f%z "$script_path" 2>/dev/null)
    echo $((size * target_langs_count))
}

fetch_node_status() {
    local result
    if ! result=$(timeout 10 openclaw nodes status --json 2>/dev/null); then
        return 1
    fi
    
    # Create associative array for states
    declare -gA node_states=()
    
    # Parse JSON manually since we can't use jq
    local nodes_section
    nodes_section=$(echo "$result" | sed -n 's/.*"nodes":\[\(.*\)\].*/\1/p')
    
    # Extract each node entry
    local IFS=$'\n'
    local entries=($(echo "$nodes_section" | grep -o '{[^}]*}' 2>/dev/null || echo ""))
    
    for entry in "${entries[@]}"; do
        local display_name node_id remote_ip connected
        
        display_name=$(echo "$entry" | sed -n 's/.*"displayName":"\([^"]*\)".*/\1/p' | tr '[:upper:]' '[:lower:]')
        node_id=$(echo "$entry" | sed -n 's/.*"nodeId":"\([^"]*\)".*/\1/p' | tr '[:upper:]' '[:lower:]')
        remote_ip=$(echo "$entry" | sed -n 's/.*"remoteIp":"\([^"]*\)".*/\1/p' | tr '[:upper:]' '[:lower:]')
        connected=$(echo "$entry" | sed -n 's/.*"connected":\([^,}]*\).*/\1/p')
        
        # Check each node against its aliases
        for node in "${!NODE_NAMES[@]}"; do
            local aliases="${NODE_NAMES[$node]}"
            if [[ " $aliases " =~ " $display_name " ]] || 
               [[ " $aliases " =~ " $node_id " ]] || 
               [[ " $aliases " =~ " $remote_ip " ]]; then
                if [[ "$connected" == "true" ]]; then
                    node_states["$node"]=true
                fi
            fi
        done
    done
    
    # Gateway always available if we got this far
    node_states["node1"]=true
}

get_job_weight() {
    local script_path="$1"
    local target_langs_count="${2:-1}"
    
    if [[ ! -f "$script_path" ]]; then
        echo "medium"
        return
    fi
    
    local total_work
    total_work=$(_job_weight_bytes "$script_path" "$target_langs_count")
    
    if ((total_work > 50000)); then  # > 50KB
        echo "heavy"
    elif ((total_work > 10000)); then  # > 10KB
        echo "medium"
    else
        echo "light"
    fi
}

select_node() {
    local job_weight="$1"
    local preferred_nodes=()
    
    case "$job_weight" in
        heavy)
            preferred_nodes=("node1" "node2" "node5" "node6")
            ;;
        medium)
            preferred_nodes=("node1" "node2" "node3" "node6")
            ;;
        light)
            preferred_nodes=("node2" "node1" "node3" "node4")
            ;;
        *)
            echo "Unknown job weight: $job_weight" >&2
            return 1
            ;;
    esac
    
    # Fetch current node states
    if ! fetch_node_status; then
        echo "none"
        return 0
    fi
    
    # Find first available preferred node
    for node_id in "${preferred_nodes[@]}"; do
        if [[ "${node_states[$node_id]:-false}" == "true" ]]; then
            echo "$node_id"
            return 0
        fi
    done
    
    echo "none"
}

check_node_available() {
    local node_id="$1"
    
    if ! fetch_node_status; then
        return 1
    fi
    
    [[ "${node_states[$node_id]:-false}" == "true" ]]
}

check_mobile_online() {
    check_node_available "node4"
}

dispatch() {
    local job_script="$1"
    local target_langs_str="$2"
    local source_text="${3:-}"
    local source_language="${4:-}"
    local force_weight="${5:-}"
    
    # Convert comma-separated languages to array
    IFS=',' read -ra target_langs <<< "$target_langs_str"
    
    # Determine weight
    local weight
    if [[ -n "$force_weight" ]]; then
        weight="$force_weight"
    else
        weight=$(get_job_weight "$job_script" "${#target_langs[@]}")
    fi
    
    # Select node
    local selected_node
    selected_node=$(select_node "$weight")
    if [[ "$selected_node" == "none" ]]; then
        selected_node=""
    fi
    
    # Build translation jobs array
    local translation_jobs=()
    for lang in "${target_langs[@]}"; do
        local job_id
        job_id=$(uuidgen 2>/dev/null || echo "$(date +%s)_$RANDOM")
        
        local job_entry="{\"job_id\":\"$job_id\",\"source\":\"$job_script\",\"target_language\":\"$lang\",\"selected_node\":\"$selected_node\""
        
        if [[ -n "$source_text" ]]; then
            job_entry+=",\"source_text\":\"$source_text\""
        fi
        
        if [[ -n "$source_language" ]]; then
            job_entry+=",\"source_language\":\"$source_language\""
        fi
        
        job_entry+="}"
        translation_jobs+=("$job_entry")
    done
    
    # Build final result
    local status="unavailable"
    if [[ -n "$selected_node" ]]; then
        status="selected"
    fi
    
    echo "{"
    echo "  \"job\": \"$job_script\","
    echo "  \"weight\": \"$weight\","
    echo "  \"selected_node\": \"$selected_node\","
    echo "  \"target_langs\": [\"${target_langs[*]// /\",\"}\"],"
    echo "  \"translation_jobs\": ["
    
    local first=true
    for job in "${translation_jobs[@]}"; do
        if [[ "$first" == true ]]; then
            echo "    $job"
            first=false
        else
            echo "    ,$job"
        fi
    done
    
    echo "  ],"
    echo "  \"status\": \"$status\""
    echo "}"
}

dispatch_abstraction_job() {
    local job_script="$1"
    local target_langs="$2"
    dispatch "$job_script" "$target_langs"
}

main() {
    local job=""
    local langs="perl5"
    local weight=""
    local execute=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --job|-j)
                job="$2"
                shift 2
                ;;
            --langs|-l)
                langs="$2"
                shift 2
                ;;
            --weight|-w)
                weight="$2"
                shift 2
                ;;
            --execute|-x)
                execute=true
                shift
                ;;
            *)
                echo "Unknown option: $1" >&2
                return 1
                ;;
        esac
    done
    
    if [[ -z "$job" ]]; then
        echo "❌ Job path is required" >&2
        return 1
    fi
    
    if [[ ! -f "$job" ]]; then
        echo "❌ Job not found: $job" >&2
        return 1
    fi
    
    local size
    size=$(stat -c%s "$job" 2>/dev/null || stat -f%z "$job" 2>/dev/null)
    
    echo "📦 Job Dispatch Information"
    echo "=================================================="
    echo "Job: $job"
    echo "Size: $size bytes"
    echo "Target langs: $langs"
    
    local job_weight
    if [[ -n "$weight" ]]; then
        job_weight="$weight"
    else
        IFS=',' read -ra lang_array <<< "$langs"
        job_weight=$(get_job_weight "$job" "${#lang_array[@]}")
    fi
    
    echo "Job weight: $job_weight"
    
    local selected_node
    selected_node=$(select_node "$job_weight")
    if [[ "$selected_node" == "none" ]]; then
        selected_node="none"
    fi
    
    echo "Selected node: $selected_node"
    echo "=================================================="
    
    if [[ "$execute" == true ]]; then
        echo ""
        echo "Translation dispatch on $selected_node is not implemented." >&2
        return 1
    else
        echo ""
        echo "💡 To execute: $0 --job $job --execute"
    fi
    
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
