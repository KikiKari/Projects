#!/usr/bin/env bash
# dispatch_job.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:skills/multi-nodes-utils/scripts/dispatch_job.py
# auch in: OpenClaw@gateway2:skills/multi-nodes-utils/scripts/dispatch_job.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Node-Konfiguration
declare -A NODES_node1=(["always_available"]="true" ["capacity"]="medium" ["priority"]="2")
declare -A NODES_node2=(["always_available"]="true" ["capacity"]="medium" ["priority"]="3")
declare -A NODES_node3=(["always_available"]="false" ["capacity"]="medium" ["priority"]="4")
declare -A NODES_node5=(["always_available"]="false" ["capacity"]="low" ["priority"]="5" ["device"]="Redmi Note 11S")
declare -A NODES_node7=(["always_available"]="true" ["capacity"]="high" ["priority"]="1")

# Funktion zur Bestimmung des Job-Gewichts
get_job_weight() {
    local script_path="$1"
    local target_langs_count="${2:-1}"
    
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

# Funktion zur Auswahl des besten Nodes basierend auf dem Job-Gewicht
select_node() {
    local job_weight="$1"
    local preferred_nodes=()
    
    case "$job_weight" in
        "heavy")
            # Schwere Jobs → Node 7 (Docker), dann Node 2, dann Node 1
            preferred_nodes=("node7" "node2" "node1")
            ;;
        "medium")
            # Mittlere Jobs → Stable Nodes
            preferred_nodes=("node2" "node1" "node7")
            ;;
        *)
            # Leichte Jobs → Mobile/verfügbare Nodes
            preferred_nodes=("node5" "node1" "node2")
            ;;
    esac
    
    # Prüfe Verfügbarkeit
    for node_id in "${preferred_nodes[@]}"; do
        if check_node_available "$node_id"; then
            echo "$node_id"
            return
        fi
    done
    
    # Fallback
    echo "node1"
}

# Funktion zur Prüfung, ob ein Node erreichbar ist
check_node_available() {
    local node_id="$1"
    
    # Prüfe, ob der Node existiert
    if ! declare -p "NODES_$node_id" &>/dev/null; then
        return 1
    fi
    
    # Lade Node-Konfiguration
    local node_var="NODES_$node_id"
    local always_available capacity priority device
    eval "always_available=\${${node_var}[always_available]:-false}"
    eval "capacity=\${${node_var}[capacity]:-}"
    eval "priority=\${${node_var}[priority]:-}"
    eval "device=\${${node_var}[device]:-}"
    
    # Nicht immer-verfügbare Nodes nur wenn explizit requested
    if [[ "$always_available" != "true" ]]; then
        # Für light-jobs prüfen wir ob online
        if [[ "$node_id" == "node5" ]]; then  # Redmi
            _check_mobile_online
            return $?
        fi
        return 1
    fi
    
    # Für immer-verfügbare Nodes: prüfe ob wirklich online
    if command -v openclaw >/dev/null 2>&1; then
        if timeout 3 openclaw nodes status "$node_id" >/dev/null 2>&1; then
            return 0
        else
            return 1
        fi
    else
        # Wenn openclaw nicht verfügbar ist, verwenden wir den always_available-Wert
        [[ "$always_available" == "true" ]]
        return $?
    fi
}

# Funktion zur Prüfung, ob das mobile Gerät (Node 5) online ist
_check_mobile_online() {
    if command -v openclaw >/dev/null 2>&1; then
        local result
        result=$(timeout 5 openclaw nodes status node5 2>/dev/null || echo "")
        if [[ $? -eq 0 ]] && [[ "$result" == *online* ]]; then
            return 0
        else
            return 1
        fi
    else
        return 1
    fi
}

# Hauptfunktion zur Job-Verteilung
dispatch() {
    local job_script="$1"
    local target_langs="$2"
    
    local weight
    weight=$(get_job_weight "$job_script" "$(echo "$target_langs" | tr ',' '\n' | wc -l)")
    local selected_node
    selected_node=$(select_node "$weight")
    
    # Ausgabe der Informationen
    echo "job:$job_script"
    echo "weight:$weight"
    echo "selected_node:$selected_node"
    echo "target_langs:$target_langs"
    echo "status:dispatched"
}

# Hauptprogramm
main() {
    local job=""
    local langs="perl5"
    local weight=""
    local execute=false
    
    # Argumente parsen
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
                echo "Unbekanntes Argument: $1" >&2
                exit 1
                ;;
        esac
    done
    
    # Prüfen, ob Job angegeben wurde
    if [[ -z "$job" ]]; then
        echo "❌ Job nicht angegeben" >&2
        exit 1
    fi
    
    # Prüfen, ob Job existiert
    if [[ ! -f "$job" ]]; then
        echo "❌ Job nicht gefunden: $job" >&2
        exit 1
    fi
    
    # Gewicht bestimmen
    if [[ -z "$weight" ]]; then
        weight=$(get_job_weight "$job" "$(echo "$langs" | tr ',' '\n' | wc -l)")
    fi
    
    # Node auswählen
    local selected_node
    selected_node=$(select_node "$weight")
    
    # Ausgabe der Informationen
    echo "📦 Job Dispatch Information"
    echo "=================================================="
    echo "Job: $job"
    local script_size
    script_size=$(stat -c%s "$job" 2>/dev/null || echo "0")
    echo "Size: $script_size bytes"
    echo "Target langs: $langs"
    echo "Job weight: $weight"
    echo "Selected node: $selected_node"
    echo "=================================================="
    
    if [[ "$execute" == true ]]; then
        echo ""
        echo "🚀 Executing on $selected_node..."
        # TODO: Implement remote execution
        echo "(Remote execution not yet implemented)"
    else
        echo ""
        echo "💡 To execute: $0 --job $job --execute"
    fi
}

# Skript ausführen
main "$@"
