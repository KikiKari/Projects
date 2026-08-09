#!/usr/bin/env tclsh
# dispatch_job.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:skills/multi-nodes-utils/scripts/dispatch_job.py
# auch in: OpenClaw@gateway2:skills/multi-nodes-utils/scripts/dispatch_job.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

# Job Dispatcher - Verteilt Jobs auf passende Nodes

# Node-Konfiguration
array set NODES {
    node1 {always_available true capacity medium priority 2}
    node2 {always_available true capacity medium priority 3}
    node3 {always_available false capacity medium priority 4}
    node5 {always_available false capacity low priority 5 device {Redmi Note 11S}}
    node7 {always_available true capacity high priority 1}
}

# Hilfsfunktionen
proc file_size {path} {
    if {[catch {file size $path} size]} {
        return 0
    }
    return $size
}

proc file_exists {path} {
    return [file exists $path]
}

proc run_command {cmd timeout} {
    if {[catch {exec {*}$cmd} result]} {
        return [list 1 $result]
    }
    return [list 0 $result]
}

# JobDispatcher Klasse
namespace eval JobDispatcher {
    # Bewertet Job-Gewicht
    proc get_job_weight {script_path target_langs_count} {
        if {![file_exists $script_path]} {
            return "medium"
        }
        
        set script_size [file_size $script_path]
        set total_work [expr {$script_size * $target_langs_count}]
        
        if {$total_work > 50000} {  # > 50KB
            return "heavy"
        } elseif {$total_work > 10000} {  # > 10KB
            return "medium"
        } else {
            return "light"
        }
    }
    
    # Wählt besten Node basierend auf Job-Gewicht
    proc select_node {job_weight} {
        switch $job_weight {
            "heavy" {
                set preferred [list "node7" "node2" "node1"]
            }
            "medium" {
                set preferred [list "node2" "node1" "node7"]
            }
            default {  # light
                set preferred [list "node5" "node1" "node2"]
            }
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
        global NODES
        
        if {![info exists NODES($node_id)]} {
            return false
        }
        
        array set node $NODES($node_id)
        
        # Nicht immer-verfügbare Nodes nur wenn explizit requested
        if {![info exists node(always_available)] || !$node(always_available)} {
            # Für light-jobs prüfen wir ob online
            if {$node_id eq "node5"} {  # Redmi
                return [check_mobile_online]
            }
            return false
        }
        
        # Für immer-verfügbare Nodes: prüfe ob wirklich online
        if {[catch {exec openclaw nodes status $node_id} result]} {
            return $node(always_available)
        }
        
        return [expr {[lindex $result 0] == 0}]
    }
    
    # Prüft ob Redmi (Node 5) Internet hat
    proc check_mobile_online {} {
        if {[catch {exec openclaw nodes status node5} result]} {
            return false
        }
        
        set returncode [lindex $result 0]
        set output [lindex $result 1]
        
        return [expr {$returncode == 0 && [string match "*online*" [string tolower $output]]}]
    }
    
    # Dispatched Job und gibt Info zurück
    proc dispatch {job_script target_langs} {
        if {$target_langs eq ""} {
            set target_langs [list "perl5"]
        }
        
        set weight [get_job_weight $job_script [llength $target_langs]]
        set selected_node [select_node $weight]
        
        return [dict create \
            job $job_script \
            weight $weight \
            selected_node $selected_node \
            target_langs $target_langs \
            status "dispatched"]
    }
}

# Argument Parsing (vereinfacht)
proc parse_args {argv} {
    set args [dict create]
    set i 0
    while {$i < [llength $argv]} {
        set arg [lindex $argv $i]
        incr i
        
        switch -exact -- $arg {
            --job - -j {
                if {$i < [llength $argv]} {
                    dict set args job [lindex $argv $i]
                    incr i
                }
            }
            --langs - -l {
                if {$i < [llength $argv]} {
                    dict set args langs [lindex $argv $i]
                    incr i
                }
            }
            --weight - -w {
                if {$i < [llength $argv]} {
                    dict set args weight [lindex $argv $i]
                    incr i
                }
            }
            --execute - -x {
                dict set args execute true
            }
            default {
                # Ignoriere unbekannte Argumente
            }
        }
    }
    return $args
}

proc main {argv} {
    set args [parse_args $argv]
    
    # Standardwerte
    if {![dict exists $args job]} {
        puts "❌ Job argument required"
        exit 1
    }
    
    set job_path [dict get $args job]
    if {![file exists $job_path]} {
        puts "❌ Job not found: $job_path"
        exit 1
    }
    
    set target_langs "perl5"
    if {[dict exists $args langs]} {
        set target_langs [dict get $args langs]
    }
    set target_langs [split $target_langs ","]
    
    # Determine weight
    set weight ""
    if {[dict exists $args weight]} {
        set weight [dict get $args weight]
    } else {
        set weight [JobDispatcher::get_job_weight $job_path [llength $target_langs]]
    }
    
    # Select node
    set selected_node [JobDispatcher::select_node $weight]
    
    # Output
    puts "📦 Job Dispatch Information"
    puts [string repeat "=" 50]
    puts "Job: $job_path"
    puts "Size: [file_size $job_path] bytes"
    puts "Target langs: [join $target_langs ", "]"
    puts "Job weight: $weight"
    puts "Selected node: $selected_node"
    puts [string repeat "=" 50]
    
    if {[dict exists $args execute]} {
        puts "\n🚀 Executing on $selected_node..."
        # TODO: Implement remote execution
        puts "(Remote execution not yet implemented)"
    } else {
        set script_name [info script]
        puts "\n💡 To execute: tclsh $script_name --job $job_path --execute"
    }
}

# Starte das Programm
if {[info script] eq $argv0} {
    main $argv
}
