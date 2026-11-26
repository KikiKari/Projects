#!/bin/bash
# abstraction-provenance: {"artifact_sha256": "ab6f7a652a0981e0f2a967a939310f4e061dfb6a28f0cec0db7f4dd266754e1c", "source_sha256": "5a841c728d9c1585b5c3191e88fdd38cf887a0d51560ce803b8c0172412bef3d", "target_language": "shell"}
# check_nodes.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:skills/multi-nodes-utils/scripts/check_nodes.py
# auch in: OpenClaw@gateway2:skills/multi-nodes-utils/scripts/check_nodes.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Node-Status Checker - Prüft Verfügbarkeit aller Nodes

# Node-Konfiguration (sollte aus config file geladen werden)
declare -A NODES
NODES=(
    [node1]="always_available:true,capacity:medium,priority:2,description:Gateway-Master"
    [node2]="always_available:true,capacity:medium,priority:3,description:Stable Worker"
    [node3]="always_available:false,capacity:medium,priority:4,description:Bald verfügbar (nach Reorganisation)"
    [node5]="always_available:false,capacity:low,priority:5,device:Redmi Note 11S,description:Mobile (bei Internet verfügbar)"
    [node7]="always_available:true,capacity:high,priority:1,description:Docker Hauptarbeitspferd (bald verfügbar)"
)

# Funktion zum Parsen der Konfigurationsstrings
parse_config() {
    local node_id="$1"
    local config="${NODES[$node_id]}"
    
    # Standardwerte setzen
    always_available="false"
    capacity="unknown"
    priority="-"
    device=""
    description=""
    
    # Config parsen
    IFS=',' read -ra CONFIG_ITEMS <<< "$config"
    for item in "${CONFIG_ITEMS[@]}"; do
        IFS=':' read -r key value <<< "$item"
        case "$key" in
            "always_available") always_available="$value" ;;
            "capacity") capacity="$value" ;;
            "priority") priority="$value" ;;
            "device") device="$value" ;;
            "description") description="$value" ;;
        esac
    done
}

check_node_status() {
    local node_id="$1"
    local is_online="false"
    local response=""
    
    # Versuche den Node-Status zu prüfen
    if timeout 5 openclaw nodes status "$node_id" >/dev/null 2>&1; then
        local stdout
        stdout=$(timeout 5 openclaw nodes status "$node_id" 2>/dev/null | head -c 100)
        if [[ "$stdout" =~ [Oo][Nn][Ll][Ii][Nn][Ee] ]] || [[ "$stdout" =~ [Aa][Cc][Tt][Ii][Vv][Ee] ]]; then
            is_online="true"
        fi
        response="${stdout:-No response}"
    else
        response="Timeout"
    fi
    
    echo "$is_online|$response"
}

print_table() {
    local nodes_status_ref="$1"
    
    echo
    printf "%0.s=" {1..90}
    echo
    printf "%-8s %-12s %-12s %-10s %-10s %s\n" "Node" "Status" "Verfügbar" "Kapazität" "Priorität" "Gerät/Beschreibung"
    printf "%0.s=" {1..90}
    echo
    
    # Nodes sortieren
    local sorted_nodes=($(printf '%s\n' "${!NODES[@]}" | sort))
    
    for node_id in "${sorted_nodes[@]}"; do
        parse_config "$node_id"
        
        # Status aus Array holen
        local status_line=""
        IFS='|' read -ra STATUS_DATA <<< "${nodes_status[$node_id]}"
        local is_online="${STATUS_DATA[0]:-false}"
        local response="${STATUS_DATA[1]:-}"
        
        local status_icon="🔴 Offline"
        [[ "$is_online" == "true" ]] && status_icon="🟢 Online"
        
        local avail_icon="📱 Bedingt"
        [[ "$always_available" == "true" ]] && avail_icon="✅ Immer"
        
        local display_device="${device:-$description}"
        
        printf "%-8s %-12s %-12s %-10s %-10s %s\n" "$node_id" "$status_icon" "$avail_icon" "$capacity" "$priority" "$display_device"
    done
    
    printf "%0.s=" {1..90}
    echo
    echo
    echo "Geprüft am: $(date '+%Y-%m-%d %H:%M:%S')"
}

print_json() {
    local nodes_status_ref="$1"
    local timestamp
    timestamp=$(date -Iseconds)
    
    echo "{"
    echo "  \"timestamp\": \"$timestamp\","
    echo "  \"nodes\": {"
    
    # Nodes sortieren
    local sorted_nodes=($(printf '%s\n' "${!NODES[@]}" | sort))
    local first_node=true
    
    for node_id in "${sorted_nodes[@]}"; do
        [[ "$first_node" == false ]] && echo ","
        first_node=false
        
        parse_config "$node_id"
        
        # Status aus Array holen
        local status_line=""
        IFS='|' read -ra STATUS_DATA <<< "${nodes_status[$node_id]}"
        local is_online="${STATUS_DATA[0]:-false}"
        local response="${STATUS_DATA[1]:-}"
        
        echo "    \"$node_id\": {"
        echo "      \"status\": {"
        echo "        \"id\": \"$node_id\","
        echo "        \"online\": $([[ "$is_online" == "true" ]] && echo "true" || echo "false"),"
        echo "        \"available\": $([[ "$always_available" == "true" ]] && echo "true" || echo "false"),"
        echo "        \"response\": \"$(echo "$response" | sed 's/"/\\"/g')\""
        echo "      },"
        echo "      \"config\": {"
        
        # Config ausgeben
        local first_item=true
        IFS=',' read -ra CONFIG_ITEMS <<< "${NODES[$node_id]}"
        for item in "${CONFIG_ITEMS[@]}"; do
            IFS=':' read -r key value <<< "$item"
            [[ "$first_item" == false ]] && echo ","
            first_item=false
            echo -n "        \"$key\": "
            if [[ "$value" =~ ^[0-9]+$ ]]; then
                echo -n "$value"
            else
                echo -n "\"$value\""
            fi
        done
        echo
        echo "      }"
        echo -n "    }"
    done
    
    echo
    echo "  }"
    echo "}"
}

save_to_file() {
    local nodes_status_ref="$1"
    local filename="$2"
    local timestamp
    timestamp=$(date -Iseconds)
    
    {
        echo "{"
        echo "  \"timestamp\": \"$timestamp\","
        echo "  \"nodes\": {"
        
        # Nodes sortieren
        local sorted_nodes=($(printf '%s\n' "${!NODES[@]}" | sort))
        local first_node=true
        
        for node_id in "${sorted_nodes[@]}"; do
            [[ "$first_node" == false ]] && echo ","
            first_node=false
            
            # Status aus Array holen
            local status_line=""
            IFS='|' read -ra STATUS_DATA <<< "${nodes_status[$node_id]}"
            local is_online="${STATUS_DATA[0]:-false}"
            local response="${STATUS_DATA[1]:-}"
            
            echo "    \"$node_id\": {"
            echo "      \"id\": \"$node_id\","
            echo "      \"online\": $([[ "$is_online" == "true" ]] && echo "true" || echo "false"),"
            echo "      \"available\": $([[ "$always_available" == "true" ]] && echo "true" || echo "false"),"
            echo "      \"response\": \"$(echo "$response" | sed 's/"/\\"/g')\""
            echo -n "    }"
        done
        
        echo
        echo "  }"
        echo "}"
    } > "$filename"
    
    echo
    echo "💾 Gespeichert: $filename"
}

main() {
    local format="table"
    local save_file=""
    
    # Kommandozeilenargumente parsen
    while [[ $# -gt 0 ]]; do
        case $1 in
            --format|-f)
                format="$2"
                shift 2
                ;;
            --save|-s)
                save_file="$2"
                shift 2
                ;;
            *)
                echo "Unbekanntes Argument: $1" >&2
                exit 1
                ;;
        esac
    done
    
    echo "🔍 Prüfe Node-Status..."
    
    # Alle Nodes prüfen
    declare -A nodes_status
    local online_count=0
    
    # Nodes sortieren
    local sorted_nodes=($(printf '%s\n' "${!NODES[@]}" | sort))
    
    for node_id in "${sorted_nodes[@]}"; do
        echo -n "  → $node_id... "
        local result
        result=$(check_node_status "$node_id")
        nodes_status["$node_id"]="$result"
        
        IFS='|' read -ra STATUS_DATA <<< "$result"
        local is_online="${STATUS_DATA[0]:-false}"
        
        if [[ "$is_online" == "true" ]]; then
            echo "✓"
            ((online_count++))
        else
            echo "✗"
        fi
    done
    
    # Ausgabe
    if [[ "$format" == "table" ]]; then
        print_table "nodes_status"
    else
        print_json "nodes_status"
    fi
    
    # In Datei speichern wenn gewünscht
    if [[ -n "$save_file" ]]; then
        save_to_file "nodes_status" "$save_file"
    fi
    
    # Zusammenfassung
    echo
    echo "📊 Zusammenfassung: $online_count/${#NODES[@]} Nodes online"
}

main "$@"
