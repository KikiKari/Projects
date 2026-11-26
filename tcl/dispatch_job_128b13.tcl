#!/usr/bin/env tclsh8.6
# abstraction-provenance: {"artifact_sha256": "2fc4bd527d7ac7f0a4195bc56dc105b4359a26767ee498a26efd9cde688f018c", "source_sha256": "128b137e5c7d86f81ea7fdb61718540c70e4ed38de4430ae6a23a5739962c024", "target_language": "tcl"}
# dispatch_job.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway2:skills/multi-nodes-utils/scripts/dispatch_job.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# Job Dispatcher - Verteilt Jobs auf passende Nodes

# Node-Konfiguration
array set NODES {
    node1 {always_available true capacity medium priority 2}
    node2 {always_available true capacity medium priority 3}
    node3 {always_available false capacity medium priority 4}
    node5 {always_available false capacity low priority 5 device "Redmi Note 11S"}
    node7 {always_available true capacity high priority 1}
}

# Hilfsfunktionen für Dateioperationen
proc file_exists {path} {
    return [expr {[file exists $path] && ![catch {file size $path}]}]
}

proc file_size {path} {
    if {[file exists $path]} {
        if {[catch {file size $path} size]} {
            return 0
        }
        return $size
    }
    return 0
}

# JobDispatcher Klasse als Tcl-Namensraum
namespace eval JobDispatcher {
    variable nodes
    array set nodes [array get NODES]
    
    # Bewertet Job-Gewicht
    proc get_job_weight {script_path target_langs_count} {
        if {![file_exists $script_path]} {
            return "medium"
        }
        
        set script_size [file_size $script_path]
        set total_work [expr {$script_size * $target_langs_count}]
        
        if {$total_work > 50000} {
            # > 50KB
            return "heavy"
        } elseif {$total_work > 10000} {
            # > 10KB
            return "medium"
        } else {
            return "light"
        }
    }
    
    # Wählt besten Node basierend auf Job-Gewicht
    proc select_node {job_weight} {
        variable nodes
        
        if {$job_weight eq "heavy"} {
            # Schwere Jobs → Node 7 (Docker), dann Node 2, dann Node 1
            set preferred [list "node7" "node2" "node1"]
        } elseif {$job_weight eq "medium"} {
            # Mittlere Jobs → Stable Nodes
            set preferred [list "node2" "node1" "node7"]
        } else {
            # light - Leichte Jobs → Mobile/verfügbare Nodes
            set preferred [list "node5" "node1" "node2"]
        }
        
        # Prüfe Verfügbarkeit
        foreach node_id $preferred {
            if {[check_node_available $node_id]} {
                return $node_id
            }
        }
        
        # Fallback
        return "node1"
    }
    
    # Prüft ob Node erreichbar ist
    proc check_node_available {node_id} {
        variable nodes
        
        if {![info exists nodes($node_id)]} {
            return false
        }
        
        # Parse node config
        set node_config $nodes($node_id)
        array set node {}
        foreach {key value} $node_config {
            set node($key) $value
        }
        
        # Nicht immer-verfügbare Nodes nur wenn explizit requested
        if {![info exists node(always_available)] || !$node(always_available)} {
            # Für light-jobs prüfen wir ob online
            if {$node_id eq "node5"} {
                # Redmi
                return [_check_mobile_online]
            }
            return false
        }
        
        # Für immer-verfügbare Nodes: prüfe ob wirklich online
        if {[catch {exec openclaw nodes status $node_id} result]} {
            return $node(always_available)
        } else {
            return [expr {[llength [split $result "\n"]] > 0}]
        }
    }
    
    # Prüft ob Redmi (Node 5) Internet hat
    proc _check_mobile_online {} {
        if {[catch {exec openclaw nodes status node5} result]} {
            return false
        } else {
            return [string match "*online*" [string tolower $result]]
        }
    }
    
    # Dispatched Job und gibt Info zurück
    proc dispatch {job_script {target_langs "perl5"}} {
        set target_langs_list [split $target_langs ","]
        set weight [get_job_weight $job_script [llength $target_langs_list]]
        set selected_node [select_node $weight]
        
        return [dict create \
            job $job_script \
            weight $weight \
            selected_node $selected_node \
            target_langs $target_langs_list \
            status dispatched]
    }
}

# Argument Parser
proc parse_args {} {
    global argv argc
    
    set options [dict create]
    set i 0
    
    while {$i < $argc} {
        set arg [lindex $argv $i]
        incr i
        
        switch -exact -- $arg {
            "--job" - "-j" {
                if {$i < $argc} {
                    dict set options job [lindex $argv $i]
                    incr i
                } else {
                    error "Option $arg requires an argument"
                }
            }
            "--langs" - "-l" {
                if {$i < $argc} {
                    dict set options langs [lindex $argv $i]
                    incr i
                } else {
                    error "Option $arg requires an argument"
                }
            }
            "--weight" - "-w" {
                if {$i < $argc} {
                    set weight_val [lindex $argv $i]
                    if {$weight_val in {"light" "medium" "heavy"}} {
                        dict set options weight $weight_val
                        incr i
                    } else {
                        error "Invalid weight value: $weight_val (must be light, medium, or heavy)"
                    }
                } else {
                    error "Option $arg requires an argument"
                }
            }
            "--execute" - "-x" {
                dict set options execute true
            }
            "--help" - "-h" {
                dict set options help true
            }
            default {
                if {![info exists unknown_args]} {
                    set unknown_args [list]
                }
                lappend unknown_args $arg
            }
        }
    }
    
    if {[info exists unknown_args]} {
        puts stderr "Unknown arguments: $unknown_args"
    }
    
    return $options
}

# Hilfstext anzeigen
proc show_help {} {
    puts "Usage: dispatch_job.tcl \[OPTIONS\]"
    puts ""
    puts "Options:"
    puts "  -j, --job PATH       Path to job script (required)"
    puts "  -l, --langs LIST     Comma-separated target languages (default: perl5)"
    puts "  -w, --weight WEIGHT  Force job weight (light|medium|heavy)"
    puts "  -x, --execute        Actually execute on selected node"
    puts "  -h, --help           Show this help message"
}

# Hauptprogramm
proc main {} {
    if {[catch {set options [parse_args]} err]} {
        puts stderr "Error parsing arguments: $err"
        exit 1
    }
    
    if {[dict exists $options help]} {
        show_help
        return
    }
    
    # Prüfe ob Job angegeben wurde
    if {![dict exists $options job]} {
        puts stderr "❌ Job path is required (--job)"
        show_help
        exit 1
    }
    
    set job_path [dict get $options job]
    if {![file exists $job_path]} {
        puts stderr "❌ Job not found: $job_path"
        exit 1
    }
    
    # Standardwerte setzen
    if {![dict exists $options langs]} {
        dict set options langs "perl5"
    }
    
    set target_langs [dict get $options langs]
    set target_langs_list [split $target_langs ","]
    
    # Gewicht bestimmen
    if {[dict exists $options weight]} {
        set weight [dict get $options weight]
    } else {
        set weight [JobDispatcher::get_job_weight $job_path [llength $target_langs_list]]
    }
    
    # Node auswählen
    set selected_node [JobDispatcher::select_node $weight]
    
    # Ausgabe
    puts "📦 Job Dispatch Information"
    puts "=================================================="
    puts "Job: $job_path"
    puts "Size: [file_size $job_path] bytes"
    puts "Target langs: $target_langs"
    puts "Job weight: $weight"
    puts "Selected node: $selected_node"
    puts "=================================================="
    
    if {[dict exists $options execute]} {
        puts ""
        puts "🚀 Executing on $selected_node..."
        # TODO: Implement remote execution
        puts "(Remote execution not yet implemented)"
    } else {
        set script_name [info script]
        puts ""
        puts "💡 To execute: tclsh8.6 $script_name --job [dict get $options job] --execute"
    }
}

# Skript starten
if {[info script] eq $argv0} {
    main
}
