#!/usr/bin/env tclsh
# dispatch_job.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:skills/multi-nodes-utils/scripts/dispatch_job.py
# Erzeugt: 2026-11-16 durch ABSTRACTIONS_MANAGER.py

# Job Dispatcher - Verteilt Jobs auf passende Nodes

package require json
package require uuid

# Hilfsfunktion zur Berechnung des Arbeitsvolumens
proc _job_weight_bytes {script_path target_langs_count} {
    # Arbeitsvolumen: Dateigröße × Anzahl der Zielsprachen
    if {[file exists $script_path]} {
        set size [file size $script_path]
        return [expr {$size * $target_langs_count}]
    }
    return 0
}

# Node-Konfiguration
array set NODES {
    node1 {always_available true capacity medium priority 3 description "Gateway"}
    node2 {always_available false capacity high priority 1 description "ARM Server"}
    node3 {always_available false capacity medium priority 4 description "AMD Server"}
    node4 {always_available false capacity low priority 5 device "Redmi Note 11S"}
    node5 {always_available false capacity high priority 2 device "Lenovo"}
    node6 {always_available false device "Lenovo (Docker)"}
}

# Node-Namen-Mapping
array set NODE_NAMES {
    node2 {openclaw-node2 arm64-node v2202604104722449961 v2202604104722449961.taild25fea.ts.net 100.82.198.122}
    node3 {openclaw-node3 openclaw-node3.taild25fea.ts.net 100.73.154.125}
    node4 {openclaw-node4 redmi-note-11s redmi-note-11s.taild25fea.ts.net 100.94.134.39}
    node5 {openclaw-node5 "windows node (lenovo-7)"}
    node6 {openclaw-node6}
}

proc fetch_node_status {} {
    # Return mapped OpenClaw connection states; empty array indicates lookup failure
    if [catch {exec openclaw nodes status --json} result] {
        return ""
    }
    
    if {[catch {::json::json2dict $result} payload]} {
        return ""
    }
    
    # Initialisiere alle Nodes als nicht verbunden
    array set states {}
    foreach node [array names ::NODE_NAMES] {
        set states($node) false
    }
    
    # Prüfe Verbindungsstatus
    if {[info exists payload(nodes)] && [llength $payload(nodes)] > 0} {
        foreach item $payload(nodes) {
            if {[dict size $item] > 0} {
                set names {}
                foreach key {displayName nodeId remoteIp} {
                    if {[dict exists $item $key]} {
                        lappend names [string tolower [dict get $item $key]]
                    }
                }
                
                foreach node [array names ::NODE_NAMES] {
                    foreach alias $::NODE_NAMES($node) {
                        if {$alias in $names && [dict exists $item connected] && [dict get $item connected]} {
                            set states($node) true
                        }
                    }
                }
            }
        }
    }
    
    # Gateway ist immer verfügbar wenn Statusabruf erfolgreich
    set states(node1) true
    
    # Konvertiere Array zu Dictionary für Rückgabe
    set result_dict {}
    foreach node [array names states] {
        dict set result_dict $node $states($node)
    }
    return $result_dict
}

proc get_job_weight {script_path target_langs_count} {
    # Bewertet Job-Gewicht
    if {![file exists $script_path]} {
        return "medium"
    }
    
    set total_work [_job_weight_bytes $script_path $target_langs_count]
    
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

proc select_node {job_weight} {
    # Wählt besten Node basierend auf Job-Gewicht
    switch $job_weight {
        heavy {
            set preferred [list node1 node2 node5 node6]
        }
        medium {
            set preferred [list node1 node2 node3 node6]
        }
        light {
            set preferred [list node2 node1 node3 node4]
        }
        default {
            error "Unknown job weight: $job_weight"
        }
    }
    
    set states [fetch_node_status]
    if {$states eq ""} {
        return ""
    }
    
    foreach node_id $preferred {
        if {[dict exists $states $node_id] && [dict get $states $node_id]} {
            return $node_id
        }
    }
    return "" ;# no verified reachable node
}

proc check_node_available {node_id} {
    # Use the live connection state rather than static availability
    set states [fetch_node_status]
    if {$states eq ""} {
        return false
    }
    if {[dict exists $states $node_id]} {
        return [dict get $states $node_id]
    }
    return false
}

proc execute_translation {job transport} {
    # Execute via a supplied transport and verify its result belongs to the job
    if {![dict exists $job selected_node] || $transport eq ""} {
        error "no verified node or authorized translation transport"
    }
    
    # In Tcl können wir Funktionen nicht direkt aufrufen wie in Python
    # Daher simulieren wir dies mit einem eval (vereinfachte Version)
    set response [$transport $job]
    
    if {[catch {::json::json2dict $response} response_dict]} {
        error "invalid transport response"
    }
    
    foreach key {job_id selected_node target_language} {
        if {![dict exists $response_dict $key] || [dict get $response_dict $key] ne [dict get $job $key]} {
            error "transport response does not match job"
        }
    }
    
    set code [dict get $response_dict code]
    if {[dict get $response_dict status] ne "ok" || $code eq "" || [string trim $code] eq ""} {
        error "translation did not complete with code"
    }
    return $code
}

proc _check_mobile_online {} {
    # Check Node4 (Redmi)
    return [check_node_available node4]
}

proc dispatch {job_script target_langs {source_text ""} {source_language ""}} {
    # Dispatched Job und gibt Info zurück
    if {$target_langs eq ""} {
        set target_langs [list perl5]
    }
    
    set weight [get_job_weight $job_script [llength $target_langs]]
    set selected_node [select_node $weight]
    
    set translation_jobs {}
    foreach language $target_langs {
        set job [dict create \
            job_id [::uuid::uuid generate] \
            source $job_script \
            target_language $language \
            selected_node $selected_node]
            
        if {$source_text ne ""} {
            dict set job source_text $source_text
        }
        if {$source_language ne ""} {
            dict set job source_language $source_language
        }
        lappend translation_jobs $job
    }
    
    return [dict create \
        job $job_script \
        weight $weight \
        selected_node $selected_node \
        target_langs $target_langs \
        translation_jobs $translation_jobs \
        status [expr {$selected_node ne "" ? "selected" : "unavailable"}]]
}

proc dispatch_abstraction_job {job_script target_langs} {
    # Erstellt eine Node-Auswahl und je (Skript, Sprache) einen Auftrag
    return [dispatch $job_script $target_langs]
}

proc main {} {
    global argv argc
    
    # Einfacher Argumentparser (da tcllib cmdline nicht standardmäßig verfügbar)
    set job_path ""
    set langs "perl5"
    set weight ""
    set execute false
    
    for {set i 0} {$i < $argc} {incr i} {
        set arg [lindex $argv $i]
        switch -exact -- $arg {
            --job -
            -j {
                incr i
                set job_path [lindex $argv $i]
            }
            --langs -
            -l {
                incr i
                set langs [lindex $argv $i]
            }
            --weight -
            -w {
                incr i
                set weight [lindex $argv $i]
            }
            --execute -
            -x {
                set execute true
            }
            --help -
            -h {
                puts "Usage: [info script] --job JOB_FILE \[--langs LANGS\] \[--weight (light|medium|heavy)\] \[--execute\]"
                return 0
            }
        }
    }
    
    if {$job_path eq ""} {
        puts stderr "❌ Job argument is required"
        return 1
    }
    
    if {![file exists $job_path]} {
        puts stderr "❌ Job not found: $job_path"
        return 1
    }
    
    set target_langs [split $langs ","]
    
    # Determine weight
    if {$weight eq ""} {
        set weight [get_job_weight $job_path [llength $target_langs]]
    }
    
    # Select node
    set selected_node [select_node $weight]
    
    # Output
    puts "📦 Job Dispatch Information"
    puts "=================================================="
    puts "Job: $job_path"
    puts "Size: [file size $job_path] bytes"
    puts "Target langs: [join $target_langs ", "]"
    puts "Job weight: $weight"
    puts "Selected node: $selected_node"
    puts "=================================================="
    
    if {$execute} {
        puts stderr "\nTranslation dispatch on $selected_node is not implemented."
        return 1
    } else {
        puts "\n💡 To execute: [info script] --job $job_path --execute"
    }
    return 0
}

# Wenn das Skript direkt ausgeführt wird
if {[info script] eq $argv0} {
    exit [main]
}
