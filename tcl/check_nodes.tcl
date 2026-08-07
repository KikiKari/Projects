#!/usr/bin/env tclsh8.6
# check_nodes.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:skills/multi-nodes-utils/scripts/check_nodes.py
# auch in: OpenClaw@gateway2:skills/multi-nodes-utils/scripts/check_nodes.py
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

# Node-Status Checker - Prüft Verfügbarkeit aller Nodes

# Node-Konfiguration (sollte aus config file geladen werden)
array set NODES {
    node1 {always_available true capacity medium priority 2 description "Gateway-Master"}
    node2 {always_available true capacity medium priority 3 description "Stable Worker"}
    node3 {always_available false capacity medium priority 4 description "Bald verfügbar (nach Reorganisation)"}
    node5 {always_available false capacity low priority 5 device "Redmi Note 11S" description "Mobile (bei Internet verfügbar)"}
    node7 {always_available true capacity high priority 1 description "Docker Hauptarbeitspferd (bald verfügbar)"}
}

proc check_node_status {node_id} {
    global NODES
    
    # Parse node config
    array set config {}
    foreach {key value} $NODES($node_id) {
        set config($key) $value
    }
    
    # Try to execute command
    if {[catch {
        set result [exec openclaw nodes status $node_id]
        set returncode 0
    } error]} {
        set result $error
        set returncode 1
    }
    
    # Check if online
    set is_online [expr {$returncode == 0 && ([string match -nocase "*online*" $result] || [string match -nocase "*active*" $result])}]
    
    # Return status dict
    return [dict create \
        id $node_id \
        online $is_online \
        available [expr {[info exists config(always_available)] ? [string is true $config(always_available)] : 0}] \
        response [string range [string trim $result] 0 99]
    ]
}

proc print_table {nodes_status} {
    global NODES
    
    puts "\n[string repeat = 90]"
    puts [format "%-8s %-12s %-12s %-10s %-10s %s" "Node" "Status" "Verfügbar" "Kapazität" "Priorität" "Gerät/Beschreibung"]
    puts [string repeat = 90]
    
    foreach status $nodes_status {
        set node_id [dict get $status id]
        array set config {}
        foreach {key value} $NODES($node_id) {
            set config($key) $value
        }
        
        set status_icon [expr {[dict get $status online] ? "🟢 Online" : "🔴 Offline"}]
        set avail_icon [expr {[dict get $status available] ? "✅ Immer" : "📱 Bedingt"}]
        set capacity [expr {[info exists config(capacity)] ? $config(capacity) : "unknown"}]
        set priority [expr {[info exists config(priority)] ? $config(priority) : "-"}]
        set device [expr {[info exists config(device)] ? $config(device) : [expr {[info exists config(description)] ? $config(description) : ""}]}]
        
        puts [format "%-8s %-12s %-12s %-10s %-10s %s" $node_id $status_icon $avail_icon $capacity $priority $device]
    }
    
    puts [string repeat = 90]
    puts "\nGeprüft am: [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]"
}

proc print_json {nodes_status} {
    global NODES
    
    set output "{\n  \"timestamp\": \"[clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%S"]\",\n  \"nodes\": {\n"
    
    set first_node 1
    foreach status $nodes_status {
        if {!$first_node} {
            append output ",\n"
        }
        set first_node 0
        
        set node_id [dict get $status id]
        append output "    \"$node_id\": {\n"
        append output "      \"status\": {\n"
        append output "        \"id\": \"$node_id\",\n"
        append output "        \"online\": [expr {[dict get $status online] ? "true" : "false"}],\n"
        append output "        \"available\": [expr {[dict get $status available] ? "true" : "false"}],\n"
        append output "        \"response\": \"[string map {"\"" "\\\""} [dict get $status response]]\"\n"
        append output "      },\n"
        append output "      \"config\": {\n"
        
        set first_config 1
        array set config {}
        foreach {key value} $NODES($node_id) {
            if {!$first_config} {
                append output ",\n"
            }
            set first_config 0
            append output "        \"$key\": \"[string map {"\"" "\\\""} $value]\""
        }
        append output "\n      }\n"
        append output "    }"
    }
    append output "\n  }\n}"
    
    puts $output
}

proc main {} {
    global argv NODES
    
    # Parse arguments
    set format "table"
    set save ""
    
    for {set i 0} {$i < [llength $argv]} {incr i} {
        set arg [lindex $argv $i]
        if {$arg eq "--format" || $arg eq "-f"} {
            incr i
            set format [lindex $argv $i]
        } elseif {$arg eq "--save" || $arg eq "-s"} {
            incr i
            set save [lindex $argv $i]
        }
    }
    
    puts "🔍 Prüfe Node-Status..."
    
    # Prüfe alle Nodes
    set nodes_status {}
    foreach node_id [lsort [array names NODES]] {
        puts -nonewline "  → $node_id... "
        flush stdout
        set status [check_node_status $node_id]
        lappend nodes_status $status
        puts [expr {[dict get $status online] ? "✓" : "✗"}]
    }
    
    # Ausgabe
    if {$format eq "table"} {
        print_table $nodes_status
    } else {
        print_json $nodes_status
    }
    
    # Speichern
    if {$save ne ""} {
        set output "{\n  \"timestamp\": \"[clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%S"]\",\n  \"nodes\": {\n"
        
        set first_node 1
        foreach status $nodes_status {
            if {!$first_node} {
                append output ",\n"
            }
            set first_node 0
            
            set node_id [dict get $status id]
            append output "    \"$node_id\": {\n"
            append output "      \"id\": \"$node_id\",\n"
            append output "      \"online\": [expr {[dict get $status online] ? "true" : "false"}],\n"
            append output "      \"available\": [expr {[dict get $status available] ? "true" : "false"}],\n"
            append output "      \"response\": \"[string map {"\"" "\\\""} [dict get $status response]]\"\n"
            append output "    }"
        }
        append output "\n  }\n}"
        
        set fh [open $save w]
        puts $fh $output
        close $fh
        puts "\n💾 Gespeichert: $save"
    }
    
    # Zusammenfassung
    set online_count 0
    foreach status $nodes_status {
        if {[dict get $status online]} {
            incr online_count
        }
    }
    puts "\n📊 Zusammenfassung: $online_count/[llength $nodes_status] Nodes online"
}

main
