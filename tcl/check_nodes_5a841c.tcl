#!/usr/bin/env tclsh
# abstraction-provenance: {"artifact_sha256": "224c993867c10feaa92492dd7bbdd8b1c1af654ea3316f82f62134f8bac78a65", "source_sha256": "5a841c728d9c1585b5c3191e88fdd38cf887a0d51560ce803b8c0172412bef3d", "target_language": "tcl"}
# check_nodes.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:skills/multi-nodes-utils/scripts/check_nodes.py
# auch in: OpenClaw@gateway2:skills/multi-nodes-utils/scripts/check_nodes.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# Node-Status Checker - Prüft Verfügbarkeit aller Nodes

package require json
package require cmdline

# Node-Konfiguration (sollte aus config file geladen werden)
array set NODES {
    node1 {always_available true capacity medium priority 2 description "Gateway-Master"}
    node2 {always_available true capacity medium priority 3 description "Stable Worker"}
    node3 {always_available false capacity medium priority 4 description "Bald verfügbar (nach Reorganisation)"}
    node5 {always_available false capacity low priority 5 device "Redmi Note 11S" description "Mobile (bei Internet verfügbar)"}
    node7 {always_available true capacity high priority 1 description "Docker Hauptarbeitspferd (bald verfügbar)"}
}

proc check_node_status {node_id} {
    # Prüft Status eines einzelnen Nodes
    global NODES
    
    if {[catch {
        set cmd [list exec openclaw nodes status $node_id]
        set result [eval $cmd]
        set is_online [expr {[llength $result] > 0 && ([string match "*online*" [string tolower $result]] || [string match "*active*" [string tolower $result]])}]
        return [dict create \
            id $node_id \
            online $is_online \
            available [dict get $NODES($node_id) always_available] \
            response [string range $result 0 99]]
    } error]} {
        if {[string match "*timeout*" $error]} {
            return [dict create \
                id $node_id \
                online false \
                available [dict get $NODES($node_id) always_available] \
                response "Timeout"]
        } else {
            return [dict create \
                id $node_id \
                online false \
                available [dict get $NODES($node_id) always_available] \
                response "Error: $error"]
        }
    }
}

proc print_table {nodes_status} {
    # Gibt Node-Status als Tabelle aus
    puts "\n[string repeat = 90]"
    puts [format "%-8s %-12s %-12s %-10s %-10s %s" "Node" "Status" "Verfügbar" "Kapazität" "Priorität" "Gerät/Beschreibung"]
    puts [string repeat = 90]
    
    foreach status $nodes_status {
        set node_id [dict get $status id]
        array set config {}
        array set config $::NODES($node_id)
        
        set status_icon [expr {[dict get $status online] ? "🟢 Online" : "🔴 Offline"}]
        set avail_icon [expr {[dict get $status available] ? "✅ Immer" : "📱 Bedingt"}]
        set capacity [expr {[info exists config(capacity)] ? $config(capacity) : "unknown"}]
        set priority [expr {[info exists config(priority)] ? $config(priority) : "-"}]
        set device [expr {[info exists config(device)] ? $config(device) : ([info exists config(description)] ? $config(description) : "")}]
        
        puts [format "%-8s %-12s %-12s %-10s %-10s %s" $node_id $status_icon $avail_icon $capacity $priority $device]
    }
    
    puts [string repeat = 90]
    puts ""
    puts "Geprüft am: [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S}]"
}

proc print_json {nodes_status} {
    # Gibt Node-Status als JSON aus
    set output [dict create]
    dict set output timestamp [clock format [clock seconds] -format {%Y-%m-%dT%H:%M:%S}]
    dict set output nodes [dict create]
    
    foreach status $nodes_status {
        set node_id [dict get $status id]
        dict set output nodes $node_id [dict create status $status config $::NODES($node_id)]
    }
    
    puts [::json::write $output]
}

proc main {} {
    # Parse command line arguments
    set options {
        {format.arg "table" "Output format (table|json)"}
        {save.arg "" "Save to file"}
    }
    
    if {[catch {array set opts [cmdline::typedGetoptions argv $options]} error]} {
        puts stderr "Fehler beim Parsen der Argumente: $error"
        exit 1
    }
    
    puts "🔍 Prüfe Node-Status..."
    
    # Prüfe alle Nodes
    set nodes_status {}
    set sorted_nodes [lsort [array names ::NODES]]
    
    foreach node_id $sorted_nodes {
        puts -nonewline "  → $node_id... "
        flush stdout
        set status [check_node_status $node_id]
        lappend nodes_status $status
        puts [expr {[dict get $status online] ? "✓" : "✗"}]
    }
    
    # Ausgabe
    if {$opts(format) eq "table"} {
        print_table $nodes_status
    } else {
        print_json $nodes_status
    }
    
    # Speichern
    if {$opts(save) ne ""} {
        set output [dict create]
        dict set output timestamp [clock format [clock seconds] -format {%Y-%m-%dT%H:%M:%S}]
        dict set output nodes [dict create]
        
        foreach status $nodes_status {
            dict set output nodes [dict get $status id] $status
        }
        
        set f [open $opts(save) w]
        puts $f [::json::write $output]
        close $f
        puts "\n💾 Gespeichert: $opts(save)"
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

# Run main procedure
main
