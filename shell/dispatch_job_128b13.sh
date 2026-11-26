#!/usr/bin/env bash
# abstraction-provenance: {"artifact_sha256": "87949692a61495c4726cef717146c204452315264c41dadc58000e89987f94a4", "source_sha256": "128b137e5c7d86f81ea7fdb61718540c70e4ed38de4430ae6a23a5739962c024", "target_language": "shell"}
# dispatch_job.py — portiert nach shell
# Quelle: python, OpenClaw@gateway2:skills/multi-nodes-utils/scripts/dispatch_job.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Node-Konfiguration
declare -A NODES_always_available
declare -A NODES_capacity
declare -A NODES_priority
declare -A NODES_device

NODES_always_available[node1]=1
NODES_capacity[node1]="medium"
NODES_priority[node1]=2

NODES_always_available[node2]=1
NODES_capacity[node2]="medium"
NODES_priority[node2]=3

NODES_always_available[node3]=0
NODES_capacity[node3]="medium"
NODES_priority[node3]=4

NODES_always_available[node5]=0
NODES_capacity[node5]="low"
NODES_priority[node5]=5
NODES_device[node5]="Redmi Note 11S"

NODES_always_available[node7]=1
NODES_capacity[node7]="high"
NODES_priority[node7]=1

# Globale Variablen für Argumente
JOB_SCRIPT=""
TARGET_LANGS="perl5"
FORCE_WEIGHT=""
EXECUTE=false

get_job_weight() {
    local script_path="$1"
    local target_langs_count="${2:-1}"
    
    # Bewertet Job-Gewicht
    if [[ ! -f "$script_path" ]]; then
        echo "medium"
        return
    fi
    
    local script_size
    script_size=$(stat -c%s "$script_path" 2>/dev/null || echo "0")
    local total_work=$((script_size * target_langs_count))
    
    if (( total_work > 50000 )); then  # > 50KB
        echo "heavy"
    elif (( total_work > 10000 )); then  # > 10KB
        echo "medium"
    else
        echo "light"
    fi
}

check_mobile_online() {
    # Prüft ob Redmi (Node 5) Internet hat
    if command -v openclaw >/dev/null 2>&1; then
        if timeout 5 openclaw nodes status node5 2>/dev/null | grep -qi "online"; then
            return 0
        fi
    fi
    return 1
}

check_node_available() {
    local node_id="$1"
    
    # Prüft ob Node erreichbar ist
    if [[ -z "${NODES_always_available[$node_id]:-}" ]]; then
        return 1
    fi
    
    local always_available=${NODES_always_available[$node_id]}
    
    # Nicht immer-verfügbare Nodes nur wenn explizit requested
    if [[ $always_available -eq 0 ]]; then
        # Für light-jobs prüfen wir ob online
        if [[ "$node_id" == "node5" ]]; then  # Redmi
            check_mobile_online
            return $?
        fi
        return 1
    fi
    
    # Für immer-verfügbare Nodes: prüfe ob wirklich online
    if command -v openclaw >/dev/null 2>&1; then
        if timeout 3 openclaw nodes status "$node_id" >/dev/null 2>&1; then
            return 0
        fi
    fi
    
    # Fallback zu always_available Flag
    return $((1 - always_available))
}

select_node() {
    local job_weight="$1"
    local selected_node=""
    
    # Wählt besten Node basierend auf Job-Gewicht
    local preferred_nodes=()
    
    if [[ "$job_weight" == "heavy" ]]; then
        # Schwere Jobs → Node 7 (Docker), dann Node 2, dann Node 1
        preferred_nodes=("node7" "node2" "node1")
    elif [[ "$job_weight" == "medium" ]]; then
        # Mittlere Jobs → Stable Nodes
        preferred_nodes=("node2" "node1" "node7")
    else  # light
        # Leichte Jobs → Mobile/verfügbare Nodes
        preferred_nodes=("node5" "node1" "node2")
    fi
    
    # Prüfe Verfügbarkeit
    for node_id in "${preferred_nodes[@]}"; do
        if check_node_available "$node_id"; then
            selected_node="$node_id"
            break
        fi
    done
    
    # Fallback
    if [[ -z "$selected_node" ]]; then
        selected_node="node1"
    fi
    
    echo "$selected_node"
}

print_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Dispatch job to optimal node

OPTIONS:
    -j, --job PATH       Path to job script (required)
    -l, --langs LIST     Comma-separated target languages (default: perl5)
    -w, --weight WEIGHT  Force job weight (light|medium|heavy)
    -x, --execute        Actually execute on selected node
    -h, --help           Show this help message

EOF
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -j|--job)
                JOB_SCRIPT="$2"
                shift 2
                ;;
            -l|--langs)
                TARGET_LANGS="$2"
                shift 2
                ;;
            -w|--weight)
                FORCE_WEIGHT="$2"
                shift 2
                ;;
            -x|--execute)
                EXECUTE=true
                shift
                ;;
            -h|--help)
                print_usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1" >&2
                print_usage
                exit 1
                ;;
        esac
    done
    
    if [[ -z "$JOB_SCRIPT" ]]; then
        echo "❌ Job script path is required" >&2
        print_usage
        exit 1
    fi
    
    if [[ ! -f "$JOB_SCRIPT" ]]; then
        echo "❌ Job not found: $JOB_SCRIPT" >&2
        exit 1
    fi
}

main() {
    parse_arguments "$@"
    
    # Bestimme Gewicht
    local weight
    if [[ -n "$FORCE_WEIGHT" ]]; then
        weight="$FORCE_WEIGHT"
    else
        # Zähle Ziel-Sprachen
        local lang_count
        IFS=',' read -ra LANG_ARRAY <<< "$TARGET_LANGS"
        lang_count=${#LANG_ARRAY[@]}
        weight=$(get_job_weight "$JOB_SCRIPT" "$lang_count")
    fi
    
    # Wähle Node
    local selected_node
    selected_node=$(select_node "$weight")
    
    # Ausgabe
    echo "📦 Job Dispatch Information"
    echo "=================================================="
    echo "Job: $JOB_SCRIPT"
    echo "Size: $(stat -c%s "$JOB_SCRIPT" 2>/dev/null || echo "0") bytes"
    echo "Target langs: $TARGET_LANGS"
    echo "Job weight: $weight"
    echo "Selected node: $selected_node"
    echo "=================================================="
    
    if [[ "$EXECUTE" == true ]]; then
        echo ""
        echo "🚀 Executing on $selected_node..."
        # TODO: Implement remote execution
        echo "(Remote execution not yet implemented)"
    else
        echo ""
        echo "💡 To execute: $0 --job $JOB_SCRIPT --execute"
    fi
}

main "$@"
