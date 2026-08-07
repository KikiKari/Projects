#!/usr/bin/env bash
# check_nodes.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:skills/multi-nodes-utils/scripts/check_nodes.py
# auch in: OpenClaw@gateway2:skills/multi-nodes-utils/scripts/check_nodes.py
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Node-Status Checker - Prüft Verfügbarkeit aller Nodes

# Node-Konfiguration (sollte aus config file geladen werden)
declare -A NODES_DESC=(
    ["node1"]="Gateway-Master"
    ["node2"]="Stable Worker"
    ["node3"]="Bald verfügbar (nach Reorganisation)"
    ["node5"]="Mobile (bei Internet verfügbar)"
    ["node7"]="Docker Hauptarbeitspferd (bald verfügbar)"
)

declare -A NODES_CAPACITY=(
    ["node1"]="medium"
    ["node2"]="medium"
    ["node3"]="medium"
    ["node5"]="low"
    ["node7"]="high"
)

declare -A NODES_PRIORITY=(
    ["node1"]="2"
    ["node2"]="3"
    ["node3"]="4"
    ["node5"]="5"
    ["node7"]="1"
)

declare -A NODES_ALWAYS_AVAILABLE=(
    ["node1"]="true"
    ["node2"]="true"
    ["node3"]="false"
    ["node5"]="false"
    ["node7"]="true"
)

declare -A NODES_DEVICE=(
    ["node5"]="Redmi Note 11S"
)

# Funktion zum Prüfen des Status eines Nodes
check_node_status() {
    local node_id="$1"
    local response=""
    local is_online="false"
    
    # Versuche den Status abzurufen
    if response=$(timeout 5 openclaw nodes status "$node_id" 2>&1); then
        if [[ "$response" =~ [Oo][Nn][Ll][Ii][Nn][Ee] ]] || [[ "$response" =~ [Aa][Cc][Tt][Ii][Vv][Ee] ]]; then
            is_online="true"
        fi
    else
        if [[ "$?" == "124" ]]; then
            response="Timeout"
        else
            response="Error: Command failed"
        fi
    fi
    
    # Gib das Ergebnis als assoziatives Array zurück (serialisiert)
    echo "id:$node_id;online:$is_online;available:${NODES_ALWAYS_AVAILABLE[$node_id]:-false};response:${response:0:100}"
}

# Funktion zum Ausgeben der Tabelle
print_table() {
    local nodes_status=("$@")
    
    echo
    printf '%.0s=' {1..90}
    echo
    printf "%-8s %-12s %-12s %-10s %-10s %s\n" "Node" "Status" "Verfügbar" "Kapazität" "Priorität" "Gerät/Beschreibung"
    printf '%.0s=' {1..90}
    echo
    
    local status_entry
    for status_entry in "${nodes_status[@]}"; do
        # Parse status entry
        local id="" online="" available="" response=""
        IFS=';' read -ra parts <<< "$status_entry"
        for part in "${parts[@]}"; do
            case "$part" in
                id:*) id="${part#id:}" ;;
                online:*) online="${part#online:}" ;;
                available:*) available="${part#available:}" ;;
                response:*) response="${part#response:}" ;;
            esac
        done
        
        local status_icon=""
        if [[ "$online" == "true" ]]; then
            status_icon="🟢 Online"
        else
            status_icon="🔴 Offline"
        fi
        
        local avail_icon=""
        if [[ "$available" == "true" ]]; then
            avail_icon="✅ Immer"
        else
            avail_icon="📱 Bedingt"
        fi
        
        local capacity="${NODES_CAPACITY[$id]:-unknown}"
        local priority="${NODES_PRIORITY[$id]:--}"
        local device=""
        if [[ -n "${NODES_DEVICE[$id]:-}" ]]; then
            device="${NODES_DEVICE[$id]}"
        elif [[ -n "${NODES_DESC[$id]:-}" ]]; then
            device="${NODES_DESC[$id]}"
        fi
        
        printf "%-8s %-12s %-12s %-10s %-10s %s\n" "$id" "$status_icon" "$avail_icon" "$capacity" "$priority" "$device"
    done
    
    printf '%.0s=' {1..90}
    echo
    echo
    echo "Geprüft am: $(date '+%Y-%m-%d %H:%M:%S')"
}

# Funktion zum Ausgeben im JSON-Format
print_json() {
    local nodes_status=("$@")
    local timestamp
    timestamp=$(date --iso-8601=seconds)
    
    echo "{"
    echo "  \"timestamp\": \"$timestamp\","
    echo "  \"nodes\": {"
    
    local first_node=true
    local status_entry
    for status_entry in "${nodes_status[@]}"; do
        # Parse status entry
        local id="" online="" available="" response=""
        IFS=';' read -ra parts <<< "$status_entry"
        for part in "${parts[@]}"; do
            case "$part" in
                id:*) id="${part#id:}" ;;
                online:*) online="${part#online:}" ;;
                available:*) available="${part#available:}" ;;
                response:*) response="${part#response:}" ;;
            esac
        done
        
        if [[ "$first_node" != "true" ]]; then
            echo "    },"
        fi
        first_node=false
        
        echo "    \"$id\": {"
        echo "      \"status\": {"
        echo "        \"id\": \"$id\","
        echo "        \"online\": $online,"
        echo "        \"available\": $available,"
        echo "        \"response\": \"${response//\"/\\\"}\""
        echo "      },"
        echo "      \"config\": {"
        echo "        \"always_available\": ${NODES_ALWAYS_AVAILABLE[$id]:-false},"
        echo "        \"capacity\": \"${NODES_CAPACITY[$id]:-unknown}\","
        echo "        \"priority\": ${NODES_PRIORITY[$id]:--}"
        if [[ -n "${NODES_DEVICE[$id]:-}" ]]; then
            echo "        \"device\": \"${NODES_DEVICE[$id]}\""
        fi
        if [[ -n "${NODES_DESC[$id]:-}" ]]; then
            echo "        \"description\": \"${NODES_DESC[$id]}\""
        fi
        echo "      }"
    done
    
    if [[ ${#nodes_status[@]} -gt 0 ]]; then
        echo "    }"
    fi
    echo "  }"
    echo "}"
}

# Hauptfunktion
main() {
    local format="table"
    local save_file=""
    
    # Parameter parsen
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--format)
                format="$2"
                shift 2
                ;;
            -s|--save)
                save_file="$2"
                shift 2
                ;;
            *)
                echo "Unbekannter Parameter: $1" >&2
                exit 1
                ;;
        esac
    done
    
    echo "🔍 Prüfe Node-Status..."
    
    # Prüfe alle Nodes
    local nodes_status=()
    local sorted_nodes=($(printf '%s\n' "${!NODES_DESC[@]}" | sort))
    local node_id
    
    for node_id in "${sorted_nodes[@]}"; do
        echo -n "  → $node_id... "
        local status
        status=$(check_node_status "$node_id")
        nodes_status+=("$status")
        if [[ "$status" == *"online:true"* ]]; then
            echo "✓"
        else
            echo "✗"
        fi
    done
    
    # Ausgabe
    if [[ "$format" == "table" ]]; then
        print_table "${nodes_status[@]}"
    else
        print_json "${nodes_status[@]}"
    fi
    
    # Speichern
    if [[ -n "$save_file" ]]; then
        {
            echo "{"
            echo "  \"timestamp\": \"$(date --iso-8601=seconds)\","
            echo "  \"nodes\": {"
            
            local first=true
            local status_entry
            for status_entry in "${nodes_status[@]}"; do
                # Parse status entry
                local id="" online="" available="" response=""
                IFS=';' read -ra parts <<< "$status_entry"
                for part in "${parts[@]}"; do
                    case "$part" in
                        id:*) id="${part#id:}" ;;
                        online:*) online="${part#online:}" ;;
                        available:*) available="${part#available:}" ;;
                        response:*) response="${part#response:}" ;;
                    esac
                done
                
                if [[ "$first" != "true" ]]; then
                    echo "    },"
                fi
                first=false
                
                echo "    \"$id\": {"
                echo "      \"id\": \"$id\","
                echo "      \"online\": $online,"
                echo "      \"available\": $available,"
                echo "      \"response\": \"${response//\"/\\\"}\""
            done
            
            if [[ ${#nodes_status[@]} -gt 0 ]]; then
                echo "    }"
            fi
            echo "  }"
            echo "}"
        } > "$save_file"
        echo
        echo "💾 Gespeichert: $save_file"
    fi
    
    # Zusammenfassung
    local online_count=0
    local status_entry
    for status_entry in "${nodes_status[@]}"; do
        if [[ "$status_entry" == *"online:true"* ]]; then
            ((online_count++))
        fi
    done
    
    echo
    echo "📊 Zusammenfassung: $online_count/${#nodes_status[@]} Nodes online"
}

# Skript ausführen
main "$@"
