#!/usr/bin/env tclsh
# abstractions_manager.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/abstractions_manager.py
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

# Script Abstractions Manager - Multi-Node Edition

package require Tcl 8.6
package require json
package require fileutil

# Konfiguration
set WORKSPACE "/home/openclaw/.openclaw/workspace"
set ABSTRACTIONS_REPO [file join $WORKSPACE "git" "Abstraktionen"]
set LOG_DIR [file join $WORKSPACE "logs" "abstractions-manager"]
set STATE_FILE [file join $WORKSPACE "db" "abstractions_state.json"]

# Node-Konfiguration mit Prioritäten
array set NODES {
    node1 {always_available true capacity medium priority 2}
    node2 {always_available true capacity medium priority 3}
    node3 {always_available false capacity medium priority 4}
    node5 {always_available false capacity low priority 5 device "Redmi Note 11S" condition mobile_internet}
    node7 {always_available true capacity high priority 1}
}

set AVAILABLE_MODELS {
    "openrouter/moonshotai/kimi-k2.5"
    "openrouter/openai/gpt-4o"
    "openrouter/anthropic/claude-3-5-sonnet-20241022"
    "openrouter/google/gemini-2.0-flash-001"
    "openrouter/nvidia/llama-3.3-nemotron-super-49b-v1"
    "openrouter/qwen/qwen-2.5-coder-32b-instruct"
}

array set TARGET_LANGUAGES {
    perl5 {ext .pl shebang "#!/usr/bin/env perl" header "use strict;\nuse warnings;\n"}
    perl6 {ext .raku shebang "#!/usr/bin/env raku" header "use v6;\n"}
    javascript {ext .js shebang "#!/usr/bin/env node" header ""}
    python {ext .py shebang "#!/usr/bin/env python3" header ""}
    shell {ext .sh shebang "#!/bin/bash" header "set -euo pipefail\n"}
    powershell {ext .ps1 shebang "#!/usr/bin/env pwsh" header "#Requires -Version 7\n"}
    tcl {ext .tcl shebang "#!/usr/bin/env tclsh" header "package require Tcl 8.6\n"}
    ruby {ext .rb shebang "#!/usr/bin/env ruby" header "require 'json'\nrequire 'fileutils'\n"}
    lua {ext .lua shebang "#!/usr/bin/env lua" header ""}
    go {ext .go shebang "// +build ignore" header "package main\n"}
}

proc log {message {level "INFO"}} {
    global LOG_DIR
    file mkdir $LOG_DIR
    set timestamp [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
    set line "\[[clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]\] \[$level\] $message"
    puts $line
    set log_file [file join $LOG_DIR "[clock format [clock seconds] -format "%Y-%m-%d"].log"]
    set f [open $log_file a]
    puts $f $line
    close $f
}

proc get_node_by_priority {{job_weight "medium"}} {
    global NODES
    
    # Prioritäts-Matrix
    if {$job_weight eq "heavy"} {
        # Schwere Jobs → Node 7 (Docker mit vielen Ressourcen)
        set preferred_order [list "node7" "node2" "node1"]
    } elseif {$job_weight eq "medium"} {
        # Mittlere Jobs → Stable Nodes
        set preferred_order [list "node2" "node1" "node7"]
    } else {
        # light
        # Leichte Jobs → Mobile/verfügbare Nodes
        set preferred_order [list "node5" "node1" "node2"]
    }
    
    # Prüfe Verfügbarkeit
    foreach node_id $preferred_order {
        if {![info exists NODES($node_id)]} {
            continue
        }
        
        array set node $NODES($node_id)
        
        # Skip nicht immer verfügbare Nodes wenn nicht explizit requested
        if {![info exists node(always_available)] || ($node(always_available) eq "false" && $job_weight ne "light")} {
            continue
        }
        
        # Prüfe ob Node online
        if {[check_node_status $node_id]} {
            return $node_id
        }
    }
    
    # Fallback zu Node 1
    return "node1"
}

proc check_node_status {node_id} {
    global NODES
    if {[catch {exec openclaw nodes status $node_id} result]} {
        # Bei Timeout/Error: Prüfe letzten bekannten Status
        if {[info exists NODES($node_id)]} {
            array set node $NODES($node_id)
            if {[info exists node(always_available)]} {
                return $node(always_available)
            }
        }
        return false
    } else {
        return [expr {[string match "*online*" [string tolower $result]] || [string match "*active*" [string tolower $result]]}]
    }
}

proc get_job_weight {script_size target_langs_count} {
    set total_work [expr {$script_size * $target_langs_count}]
    
    if {$total_work > 50000} {
        # Große Scripts, viele Sprachen
        return "heavy"
    } elseif {$total_work > 10000} {
        # Mittlere Last
        return "medium"
    } else {
        return "light"
    }
}

proc load_state {} {
    global STATE_FILE
    if {[file exists $STATE_FILE]} {
        if {[catch {set f [open $STATE_FILE r]}]} {
            # ignore error
        } else {
            set content [read $f]
            close $f
            if {[catch {set state [::json::json2dict $content]}]} {
                # ignore error
            } else {
                return $state
            }
        }
    }
    
    return [dict create processed [dict create] queue [list] current_priority "high" stats [dict create total_scripts 0 abstractions_created 0]]
}

proc save_state {state} {
    global STATE_FILE
    file mkdir [file dirname $STATE_FILE]
    set f [open $STATE_FILE w]
    puts $f [::json::dict2json $state]
    close $f
}

proc find_scripts_in_dir {directory {exclude_patterns ""}} {
    if {$exclude_patterns eq ""} {
        set exclude_patterns [list "node_modules" ".git" "__pycache__" "dist" "build"]
    }
    
    set scripts [list]
    if {[file exists $directory]} {
        foreach ext [list "*.py" "*.js" "*.sh" "*.pl" "*.rb"] {
            foreach script [glob -nocomplain -dir $directory -types f $ext] {
                set exclude false
                foreach pattern $exclude_patterns {
                    if {[string match "*$pattern*" $script]} {
                        set exclude true
                        break
                    }
                }
                if {!$exclude} {
                    lappend scripts $script
                }
            }
        }
    }
    return $scripts
}

proc create_abstraction {script_path target_lang} {
    global ABSTRACTIONS_REPO TARGET_LANGUAGES
    
    if {[catch {set f [open $script_path r]}]} {
        return false
    }
    set original_content [read $f]
    close $f
    
    set ext [string range [file extension $script_path] 1 end]
    array set source_lang_map {py Python js JavaScript sh Shell pl Perl rb Ruby}
    if {[info exists source_lang_map($ext)]} {
        set source_lang $source_lang_map($ext)
    } else {
        set source_lang $ext
    }
    
    set target_dir [file join $ABSTRACTIONS_REPO $target_lang]
    file mkdir $target_dir
    
    set target_file [file join $target_dir "[file rootname [file tail $script_path]]$TARGET_LANGUAGES($target_lang,ext)"]
    
    if {[file exists $target_file]} {
        return false
    }
    
    set lines [split $original_content "\n"]
    set lines [lrange $lines 0 14]
    set header_lines ""
    foreach line $lines {
        append header_lines "# $line\n"
    }
    
    set content "$TARGET_LANGUAGES($target_lang,shebang)\n# [file rootname [file tail $script_path]] - [string totitle $target_lang] Version\n# Portiert von $source_lang\n# Original: $script_path\n# Erstellt: [clock format [clock seconds] -format "%Y-%m-%d"]\n#\n"
    
    if {[info exists TARGET_LANGUAGES($target_lang,header)] && $TARGET_LANGUAGES($target_lang,header) ne ""} {
        append content "# $TARGET_LANGUAGES($target_lang,header)\n"
    }
    
    append content "\n# Original-Code-Referenz:\n# $header_lines\nproc main {} {\n    # TODO: Implementiere $source_lang Funktionalität in [string totitle $target_lang]\n    return\n}\n\nif {\"\[info script\]\" eq \"\[file normalize \$argv0\]\"} {\n    main\n}\n"
    
    if {[catch {set f [open $target_file w]}]} {
        return false
    }
    puts $f $content
    close $f
    
    log "Created: $target_file"
    return true
}

proc process_on_node {node_id scripts target_langs} {
    set created 0
    
    if {$node_id eq "node1"} {
        # Lokale Verarbeitung
        foreach script $scripts {
            foreach lang $target_langs {
                if {[create_abstraction $script $lang]} {
                    incr created
                }
            }
        }
    } else {
        # Remote-Verarbeitung
        log "Dispatching [llength $scripts] jobs to $node_id"
        # TODO: Implementiere Remote-Dispatch wenn Node-Infrastruktur bereit
        # Für jetzt: Lokale Verarbeitung mit Node-Logging
        foreach script $scripts {
            foreach lang $target_langs {
                if {[create_abstraction $script $lang]} {
                    incr created
                    log "Processed on $node_id: [file tail $script] -> $lang"
                }
            }
        }
    }
    
    return $created
}

proc process_priority_high {} {
    global WORKSPACE
    set created 0
    set targets [list \
        [list "skill-creator" [file join $WORKSPACE "skills" "skill-creator" "scripts"]] \
        [list "json-utils" [file join $WORKSPACE "skills" "json-utils" "scripts"]] \
        [list "scripting-utils" [file join $WORKSPACE "skills" "scripting-utils" "scripts"]] \
        [list "model-usage" [file join $WORKSPACE "skills" "model-usage" "scripts"]] \
        [list "tiktok-live" [file join $WORKSPACE "skills" "tiktok-live" "scripts"]] \
    ]
    
    foreach target $targets {
        lassign $target skill_name scripts_dir
        set scripts [find_scripts_in_dir $scripts_dir [list "node_modules" ".git" "test" "tests"]]
        log "$skill_name: [llength $scripts] scripts found"
        
        set count 0
        foreach script $scripts {
            if {$count >= 10} break
            if {![file exists $script]} continue
            
            set script_size [file size $script]
            set target_langs [list "perl5" "javascript" "python" "shell" "tcl"]
            set job_weight [get_job_weight $script_size [llength $target_langs]]
            
            # Wähle Node basierend auf Job-Gewicht
            set selected_node [get_node_by_priority $job_weight]
            log "Processing [file tail $script] ($job_weight) on $selected_node"
            
            incr created [process_on_node $selected_node [list $script] $target_langs]
            incr count
        }
    }
    
    return $created
}

proc process_priority_medium {} {
    global WORKSPACE
    set created 0
    set targets [list \
        [list "workspace-scripts" [file join $WORKSPACE "scripts"]] \
        [list "db-maintainer" [file join $WORKSPACE "skills" "db-maintainer" "scripts"]] \
        [list "log-collector" [file join $WORKSPACE "skills" "log-collector" "scripts"]] \
    ]
    
    foreach target $targets {
        lassign $target dir_name scripts_dir
        set scripts [find_scripts_in_dir $scripts_dir [list "node_modules" ".git"]]
        
        set count 0
        foreach script $scripts {
            if {$count >= 10} break
            if {![file exists $script]} continue
            
            set script_size [file size $script]
            set target_langs [list "perl5" "javascript" "powershell" "python"]
            set job_weight [get_job_weight $script_size [llength $target_langs]]
            
            # Mittlere Priority → eher leichtere Jobs
            set selected_priority "medium"
            if {$job_weight eq "heavy"} {
                set selected_priority "medium"
            } else {
                set selected_priority $job_weight
            }
            set selected_node [get_node_by_priority $selected_priority]
            log "Processing [file tail $script] ($job_weight) on $selected_node"
            
            incr created [process_on_node $selected_node [list $script] $target_langs]
            incr count
        }
    }
    
    return $created
}

proc git_commit {message} {
    global ABSTRACTIONS_REPO
    if {[catch {
        cd $ABSTRACTIONS_REPO
        exec git add .
        exec git commit -m $message
        log "Git commit: $message"
    }]} {
        # ignore error
    }
}

proc create_status_report {state} {
    global ABSTRACTIONS_REPO TARGET_LANGUAGES AVAILABLE_MODELS NODES
    set report_file [file join $ABSTRACTIONS_REPO "STATUS.md"]
    set lang_counts [dict create]
    
    if {[file exists $ABSTRACTIONS_REPO]} {
        foreach lang_dir [glob -nocomplain -dir $ABSTRACTIONS_REPO -types d *] {
            set lang_name [file tail $lang_dir]
            if {[info exists TARGET_LANGUAGES($lang_name)]} {
                set count 0
                foreach f [glob -nocomplain -dir $lang_dir -types f *] {
                    incr count
                }
                dict set lang_counts $lang_name $count
            }
        }
    }
    
    set f [open $report_file w]
    puts $f "# Script Abstractions - Status Report\n"
    puts $f "**Letzte Aktualisierung:** [clock format [clock seconds] -format "%Y-%m-%d %H:%M"]\n"
    puts $f "- Aktuelle Priorität: [dict get $state current_priority]\n"
    puts $f "- Verarbeitete Scripts: [llength [dict get $state processed]]\n"
    puts $f "- Abstraktionen gesamt: [dict get $state stats abstractions_created]\n"
    puts $f "## Abstraktionen pro Sprache\n"
    
    foreach lang [lsort [dict keys $lang_counts]] {
        set count [dict get $lang_counts $lang]
        puts $f "- $lang: $count"
    }
    
    puts $f "\n## Verfügbare Modelle\n"
    set count 0
    foreach model $AVAILABLE_MODELS {
        if {$count < 3} {
            puts $f "- `$model`"
        }
        incr count
    }
    if {[llength $AVAILABLE_MODELS] > 3} {
        puts $f "- ... und [expr {[llength $AVAILABLE_MODELS] - 3}] weitere"
    }
    
    puts $f "\n## Multi-Node Support\n"
    puts $f "| Node | Verfügbarkeit | Kapazität | Priorität | Gerät |"
    puts $f "|------|---------------|-----------|-----------|-------|"
    
    # Sort nodes by priority
    set sorted_nodes [lsort -integer -index 1 [dict for {node_id config} [array get NODES] {
        list [dict get $config priority] $node_id
    }]]
    
    foreach item $sorted_nodes {
        set node_id [lindex $item 1]
        if {[info exists NODES($node_id)]} {
            array set config $NODES($node_id)
            set avail "✅ Immer"
            if {![info exists config(always_available)] || $config(always_available) eq "false"} {
                set avail "📱 Bedingt"
            }
            set device "Server"
            if {[info exists config(device)]} {
                set device $config(device)
            }
            puts $f "| $node_id | $avail | $config(capacity) | $config(priority) | $device |"
        }
    }
    
    puts $f "\n### Job-Verteilung\n"
    puts $f "- **Heavy Jobs** (>50KB × Sprachen) → Node 7 (Docker, hohe Ressourcen)"
    puts $f "- **Medium Jobs** → Node 2 (Stable), Node 1 (Primary)"
    puts $f "- **Light Jobs** → Node 5 (Redmi Note 11S, wenn verfügbar)"
    close $f
}

proc main {} {
    log "Script Abstractions Manager (Multi-Node) gestartet"
    
    set state [load_state]
    log "State loaded: [llength [dict get $state processed]] processed"
    
    set current_priority [dict get $state current_priority]
    set created 0
    
    if {$current_priority eq "high"} {
        log "Processing HIGH priority: Top 5 Skills"
        set created [process_priority_high]
        if {$created > 0} {
            git_commit "High priority: $created abstractions"
        }
        dict set state current_priority "medium"
    } elseif {$current_priority eq "medium"} {
        log "Processing MEDIUM priority: Workspace Scripts"
        set created [process_priority_medium]
        if {$created > 0} {
            git_commit "Medium priority: $created abstractions"
        }
        dict set state current_priority "high"
    }
    
    dict set state stats last_run [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%S"]
    
    # Count abstractions
    set total_count 0
    foreach lang [array names TARGET_LANGUAGES] {
        set lang_dir [file join $ABSTRACTIONS_REPO $lang]
        if {[file exists $lang_dir]} {
            foreach f [glob -nocomplain -dir $lang_dir -types f *] {
                incr total_count
            }
        }
    }
    dict set state stats abstractions_created $total_count
    
    save_state $state
    create_status_report $state
    
    log "Abgeschlossen. $created neue Abstraktionen erstellt."
}

main
