#!/bin/bash
# abstraction-provenance: {"artifact_sha256": "62c273952e246062239c92b17ebb83c8b4600b5806b84446334f8e7faeae1c74", "source_sha256": "748c0fc07a58caf07d4983d358cf0e1ce57c4e180b87ae617d598f53c61efcec", "target_language": "shell"}
# dispatch_job.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:skills/multi-nodes-utils/scripts/dispatch_job.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Job Dispatcher - Verteilt Jobs auf passende Nodes

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
    [node2]="openclaw-node2,arm64-node,v2202604104722449961,v2202604104722449961.taild25fea.ts.net,100.82.198.122"
    [node3]="openclaw-node3,openclaw-node3.taild25fea.ts.net,100.73.154.125"
    [node4]="openclaw-node4,redmi-note-11s,redmi-note-11s.taild25fea.ts.net,100.94.134.39"
    [node5]="openclaw-node5,windows node (lenovo-7)"
    [node6]="openclaw-node6"
)

# Arbeitsvolumen: Dateigröße × Anzahl der Zielsprachen
_job_weight_bytes() {
    local script_path="$1"
    local target_langs_count="$2"
    
    if [[ ! -f "$script_path" ]]; then
        echo 0
        return
    fi
    
    local size
    size=$(stat -c%s "$script_path" 2>/dev/null || echo 0)
    echo $((size * target_langs_count))
}

fetch_node_status() {
    # Return mapped OpenClaw connection states; emtpy indicates lookup failure
    local result
    if ! result=$(timeout 10 openclaw nodes status --json 2>/dev/null); then
        return 1
    fi
    
    # Create temporary file for jq processing
    local temp_file
    temp_file=$(mktemp)
    echo "$result" > "$temp_file"
    
    # Validate JSON structure
    if ! jq -e '.nodes | type == "array"' "$temp_file" >/dev/null 2>&1; then
        rm -f "$temp_file"
        return 1
    fi
    
    # Process each node
    declare -A states
    for node in "${!NODE_NAMES[@]}"; do
        states[$node]=false
    done
    
    # Check connectivity for each node
    local nodes_count
    nodes_count=$(jq -r '.nodes | length' "$temp_file")
    
    for ((i=0; i<nodes_count; i++)); do
        local connected
        connected=$(jq -r ".nodes[$i].connected" "$temp_file" 2>/dev/null)
        
        if [[ "$connected" == "true" ]]; then
            local display_name node_id remote_ip
            display_name=$(jq -r ".nodes[$i].displayName // empty" "$temp_file" 2>/dev/null || echo "")
            node_id=$(jq -r ".nodes[$i].nodeId // empty" "$temp_file" 2>/dev/null || echo "")
            remote_ip=$(jq -r ".nodes[$i].remoteIp // empty" "$temp_file" 2>/dev/null || echo "")
            
            # Create search terms
            local search_terms=("$display_name" "$node_id" "$remote_ip")
            
            # Check each node's aliases
            for node in "${!NODE_NAMES[@]}"; do
                local aliases="${NODE_NAMES[$node]}"
                
                for term in "${search_terms[@]}"; do
                    if [[ -n "$term" ]] && [[ ",$aliases," == *",$term,"* ]]; then
                        states[$node]=true
                        break
                    fi
                done
            done
        fi
    done
    
    # Gateway always available if we got this far
    states[node1]=true
    
    # Output results
    for node in "${!states[@]}"; do
        echo "$node:${states[$node]}"
    done
    
    rm -f "$temp_file"
    return 0
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
    
    # Get node statuses
    local status_output
    if ! status_output=$(fetch_node_status 2>/dev/null); then
        echo "none"
        return 0
    fi
    
    # Parse statuses into associative array
    declare -A states
    while IFS=: read -r node state; do
        states["$node"]="$state"
    done <<< "$status_output"
    
    # Find first available preferred node
    for node_id in "${preferred_nodes[@]}"; do
        if [[ "${states[$node_id]:-false}" == "true" ]]; then
            echo "$node_id"
            return 0
        fi
    done
    
    echo "none"
}

check_node_available() {
    local node_id="$1"
    
    # Get node statuses
    local status_output
    if ! status_output=$(fetch_node_status 2>/dev/null); then
        return 1
    fi
    
    # Parse statuses and check specific node
    while IFS=: read -r node state; do
        if [[ "$node" == "$node_id" ]] && [[ "$state" == "true" ]]; then
            return 0
        fi
    done <<< "$status_output"
    
    return 1
}

_check_mobile_online() {
    check_node_available "node4"
}

dispatch() {
    local job_script="$1"
    local target_langs_str="${2:-perl5}"
    local source_text="${3:-}"
    local source_language="${4:-}"
    
    # Convert comma-separated languages to array
    IFS=',' read -ra target_langs <<< "$target_langs_str"
    
    # Get job weight
    local weight
    weight=$(get_job_weight "$job_script" "${#target_langs[@]}")
    
    # Select node
    local selected_node
    selected_node=$(select_node "$weight")
    if [[ "$selected_node" == "none" ]]; then
        selected_node=""
    fi
    
    # Generate UUID function
    generate_uuid() {
        local uuid
        if command -v uuidgen >/dev/null 2>&1; then
            uuid=$(uuidgen)
        else
            # Fallback UUID generation
            local chars="0123456789abcdef"
            uuid=""
            for ((i=0; i<32; i++)); do
                uuid+="${chars:$((RANDOM % 16)):1}"
                if [[ $i == 7 || $i == 11 || $i == 15 || $i == 19 ]]; then
                    uuid+="-"
                fi
            done
        fi
        echo "$uuid"
    }
    
    # Build translation jobs array
    local translation_jobs=()
    for language in "${target_langs[@]}"; do
        local job_id
        job_id=$(generate_uuid)
        
        local job="{\"job_id\":\"$job_id\","
        job+="\"source\":\"$job_script\","
        job+="\"target_language\":\"$language\","
        if [[ -n "$selected_node" ]]; then
            job+="\"selected_node\":\"$selected_node\""
        else
            job+="\"selected_node\":null"
        fi
        
        if [[ -n "$source_text" ]]; then
            job+=",\"source_text\":\"$source_text\""
        fi
        
        if [[ -n "$source_language" ]]; then
            job+=",\"source_language\":\"$source_language\""
        fi
        
        job+="}"
        translation_jobs+=("$job")
    done
    
    # Build final result
    local result="{\"job\":\"$job_script\","
    result+="\"weight\":\"$weight\","
    if [[ -n "$selected_node" ]]; then
        result+="\"selected_node\":\"$selected_node\","
    else
        result+="\"selected_node\":null,"
    fi
    result+="\"target_langs\":["
    
    local first=true
    for lang in "${target_langs[@]}"; do
        if [[ "$first" == true ]]; then
            result+="\"$lang\""
            first=false
        else
            result+=",\"$lang\""
        fi
    done
    
    result+="],\"translation_jobs\":["
    
    first=true
    for job in "${translation_jobs[@]}"; do
        if [[ "$first" == true ]]; then
            result+="$job"
            first=false
        else
            result+=",$job"
        fi
    done
    
    result+="],"
    if [[ -n "$selected_node" ]]; then
        result+="\"status\":\"selected\"}"
    else
        result+="\"status\":\"unavailable\"}"
    fi
    
    echo "$result"
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
    
    # Parse arguments
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
    
    # Determine weight
    if [[ -n "$weight" ]]; then
        local job_weight="$weight"
    else
        local job_weight
        job_weight=$(get_job_weight "$job" "$(echo "$langs" | tr ',' '\n' | wc -l)")
    fi
    
    # Select node
    local selected_node
    selected_node=$(select_node "$job_weight")
    if [[ "$selected_node" == "none" ]]; then
        selected_node=""
    fi
    
    # Output information
    echo "📦 Job Dispatch Information"
    echo "=================================================="
    echo "Job: $job"
    echo "Size: $(stat -c%s "$job" 2>/dev/null || echo 0) bytes"
    echo "Target langs: $langs"
    echo "Job weight: $job_weight"
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

# Execute main if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
