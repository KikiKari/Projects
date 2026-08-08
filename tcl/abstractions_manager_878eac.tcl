#!/usr/bin/env tclsh
# abstractions_manager.pl — portiert nach tcl
# Quelle: perl5, Projects@abstractions:perl5/abstractions_manager.pl
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# abstractions_manager.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/abstractions_manager.py
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

package require Tcl 8.6
package require json
package require fileutil
package require cmdline

# Konfiguration
set WORKSPACE "/home/openclaw/.openclaw/workspace"
set ABSTRACTIONS_REPO "$WORKSPACE/git/Abstraktionen"
set LOG_DIR "$WORKSPACE/logs/abstractions-manager"
set STATE_FILE "$WORKSPACE/db/abstractions_state.json"

# Node-Konfiguration mit Prioritäten
array set NODES {
    node1 {always_available 1 capacity medium priority 2}  # Gateway-Master
    node2 {always_available 1 capacity medium priority 3}  # Stable Worker
    node3 {always_available 0 capacity medium priority 4}  # Bald verfügbar
    node5 {always_available 0 capacity low priority 5 device "Redmi Note 11S" condition mobile_internet}
    node7 {always_available 1 capacity high priority 1}     # Docker Hauptarbeitspferd
}

set AVAILABLE_MODELS [list \
    "openrouter/moonshotai/kimi-k2.5" \
    "openrouter/openai/gpt-4o" \
    "openrouter/anthropic/claude-3-5-sonnet-20241022" \
    "openrouter/google/gemini-2.0-flash-001" \
    "openrouter/nvidia/llama-3.3-nemotron-super-49b-v1" \
    "openrouter/qwen/qwen-2.5-coder-32b-instruct" \
]

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

proc log_message {message {level INFO}} {
    global LOG_DIR
    
    if {![file exists $LOG_DIR]} {
        file mkdir $LOG_DIR
    }
    
    set timestamp [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
    set line "\[$timestamp\] \[$level\] $message\n"
    puts -nonewline $line
    
    set log_file "$LOG_DIR/[clock format [clock seconds] -format "%Y-%m-%d"].log"
    set fh [open $log_file a]
    puts -nonewline $fh $line
    close $fh
}

proc get_node_by_priority {job_weight} {
    global NODES
    
    if {$job_weight eq "heavy"} {
        set preferred_order [list node7 node2 node1]
    } elseif {$job_weight eq "medium"} {
        set preferred_order [list node2 node1 node7]
    } else {
        set preferred_order [list node5 node1 node2]
    }
    
    foreach node_id $preferred_order {
        if {![info exists NODES($node_id)]} {
            continue
        }
        
        array set node $NODES($node_id)
        if {!$node(always_available) && $job_weight ne "light"} {
            continue
        }
        
        if {[check_node_status $node_id]} {
            return $node_id
        }
    }
    
    return "node1"
}

proc check_node_status {node_id} {
    global NODES
    
    if {[catch {exec openclaw nodes status $node_id} output]} {
        set exit_code 1
    } else {
        set exit_code 0
    }
    
    if {$exit_code == 0 && ([string match -nocase *online* $output] || [string match -nocase *active* $output])} {
        return 1
    }
    
    array set node_config $NODES($node_id)
    return [expr {$node_config(always_available) ? 1 : 0}]
}

proc get_job_weight {script_size target_langs_count} {
    set total_work [expr {$script_size * $target_langs_count}]
    
    if {$total_work > 50000} {
        return "heavy"
    } elseif {$total_work > 10000} {
        return "medium"
    } else {
        return "light"
    }
}

proc load_state {} {
    global STATE_FILE
    
    if {[file exists $STATE_FILE]} {
        if {[catch {set fh [open $STATE_FILE r]}]} {
            return [default_state]
        }
        set json_text [read $fh]
        close $fh
        
        if {[catch {::json::json2dict $json_text} state]} {
            return [default_state]
        }
        return $state
    }
    
    return [default_state]
}

proc default_state {} {
    return {
        processed {}
        queue {}
        current_priority high
        stats {total_scripts 0 abstractions_created 0}
    }
}

proc save_state {state} {
    global STATE_FILE
    
    set state_dir [file dirname $STATE_FILE]
    if {![file exists $state_dir]} {
        file mkdir $state_dir
    }
    
    set fh [open $STATE_FILE w]
    puts -nonewline $fh [::json::dict2json $state]
    close $fh
}

proc find_scripts_in_dir {directory {exclude_patterns {node_modules .git __pycache__ dist build}}} {
    set scripts {}
    
    if {![file isdirectory $directory]} {
        return $scripts
    }
    
    set extensions [list *.py *.js *.sh *.pl *.rb]
    foreach ext $extensions {
        foreach file [glob -nocomplain -directory $directory -types f **/$ext] {
            set exclude 0
            foreach pattern $exclude_patterns {
                if {[string match *$pattern* $file]} {
                    set exclude 1
                    break
                }
            }
            if {!$exclude} {
                lappend scripts $file
            }
        }
    }
    
    return $scripts
}

proc create_abstraction {script_path target_lang} {
    global ABSTRACTIONS_REPO TARGET_LANGUAGES
    
    if {[catch {
        set fh [open $script_path r]
        set original_content [read $fh]
        close $fh
        
        set ext [file extension $script_path]
        set ext [string range $ext 1 end]
        array set source_lang_map {py Python js JavaScript sh Shell pl Perl rb Ruby}
        set source_lang $source_lang_map($ext)
        
        set target_dir "$ABSTRACTIONS_REPO/$target_lang"
        if {![file exists $target_dir]} {
            file mkdir $target_dir
        }
        
        set script_name [file rootname [file tail $script_path]]
        set target_file "$target_dir/${script_name}$TARGET_LANGUAGES($target_lang,ext)"
        
        if {[file exists $target_file]} {
            return 0
        }
        
        array set template $TARGET_LANGUAGES($target_lang)
        set lines [split $original_content \n]
        if {[llength $lines] > 15} {
            set lines [lrange $lines 0 14]
        }
        
        set content "$template(shebang)\n"
        append content "# $script_name - [string totitle $target_lang] Version\n"
        append content "# Portiert von $source_lang\n"
        append content "# Original: $script_path\n"
        append content "# Erstellt: [clock format [clock seconds] -format "%Y-%m-%d"]\n#\n"
        if {[info exists template(header)] && $template(header) ne ""} {
            append content "# $template(header)\n"
        }
        append content "# Original-Code-Referenz:\n"
        foreach line $lines {
            append content "# $line\n"
        }
        append content "\nproc main {} {\n"
        append content "    # TODO: Implementiere $source_lang Funktionalität in [string totitle $target_lang]\n"
        append content "    return\n"
        append content "}\n\n"
        append content "if {!\[info script\]} {\n"
        append content "    main\n"
        append content "}\n"
        
        set fh [open $target_file w]
        puts -nonewline $fh $content
        close $fh
        
        log_message "Created: $target_file"
        return 1
    } err]} {
        log_message "Failed: $script_path - $err" ERROR
        return 0
    }
}

proc process_on_node {node_id scripts target_langs} {
    set created 0
    
    if {$node_id eq "node1"} {
        foreach script $scripts {
            foreach lang $target_langs {
                if {[create_abstraction $script $lang]} {
                    incr created
                }
            }
        }
    } else {
        log_message "Dispatching [llength $scripts] jobs to $node_id"
        foreach script $scripts {
            foreach lang $target_langs {
                if {[create_abstraction $script $lang]} {
                    incr created
                    log_message "Processed on $node_id: $script -> $lang"
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
        [list skill-creator "$WORKSPACE/skills/skill-creator/scripts"] \
        [list json-utils "$WORKSPACE/skills/json-utils/scripts"] \
        [list scripting-utils "$WORKSPACE/skills/scripting-utils/scripts"] \
        [list model-usage "$WORKSPACE/skills/model-usage/scripts"] \
        [list tiktok-live "$WORKSPACE/skills/tiktok-live/scripts"] \
    ]
    
    foreach target $targets {
        lassign $target skill_name scripts_dir
        set scripts [find_scripts_in_dir $scripts_dir [list node_modules .git test tests]]
        log_message "$skill_name: [llength $scripts] scripts found"
        
        set count 0
        foreach script $scripts {
            if {$count >= 10} {
                break
            }
            set script_size [file size $script]
            set target_langs [list perl5 javascript python shell tcl]
            set job_weight [get_job_weight $script_size [llength $target_langs]]
            
            set selected_node [get_node_by_priority $job_weight]
            log_message "Processing [file tail $script] ($job_weight) on $selected_node"
            
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
        [list workspace-scripts "$WORKSPACE/scripts"] \
        [list db-maintainer "$WORKSPACE/skills/db-maintainer/scripts"] \
        [list log-collector "$WORKSPACE/skills/log-collector/scripts"] \
    ]
    
    foreach target $targets {
        lassign $target dir_name scripts_dir
        set scripts [find_scripts_in_dir $scripts_dir [list node_modules .git]]
        
        set count 0
        foreach script $scripts {
            if {$count >= 10} {
                break
            }
            set script_size [file size $script]
            set target_langs [list perl5 javascript powershell python]
            set job_weight [get_job_weight $script_size [llength $target_langs]]
            
            set priority $job_weight
            if {$job_weight eq "heavy"} {
                set priority medium
            }
            set selected_node [get_node_by_priority $priority]
            log_message "Processing [file tail $script] ($job_weight) on $selected_node"
            
            incr created [process_on_node $selected_node [list $script] $target_langs]
            incr count
        }
    }
    
    return $created
}

proc git_commit {message} {
    global ABSTRACTIONS_REPO
    
    if {[catch {
        set old_dir [pwd]
        cd $ABSTRACTIONS_REPO
        if {[catch {exec git add .}]} {
            error "git add failed"
        }
        if {[catch {exec git commit -m $message}]} {
            error "git commit failed"
        }
        cd $old_dir
        log_message "Git commit: $message"
    } err]} {
        log_message "Git commit failed: $err" ERROR
    }
}

proc create_status_report {state} {
    global ABSTRACTIONS_REPO TARGET_LANGUAGES AVAILABLE_MODELS
    
    set report_file "$ABSTRACTIONS_REPO/STATUS.md"
    
    array set lang_counts {}
    if {[file isdirectory $ABSTRACTIONS_REPO]} {
        foreach lang_dir [glob -nocomplain -directory $ABSTRACTIONS_REPO *] {
            if {[file tail $lang_dir] eq "." || [file tail $lang_dir] eq ".."} {
                continue
            }
            set full_path $lang_dir
            if {[file isdirectory $full_path] && [info exists TARGET_LANGUAGES([file tail $lang_dir])]} {
                set count 0
                foreach file [glob -nocomplain -directory $full_path *] {
                    if {[file tail $file] eq "." || [file tail $file] eq ".."} {
                        continue
                    }
                    if {[file isfile $file]} {
                        incr count
                    }
                }
                set lang_counts([file tail $lang_dir]) $count
            }
        }
    }
    
    set fh [open $report_file w]
    puts $fh "# Script Abstractions - Status Report"
    puts $fh ""
    puts $fh "**Letzte Aktualisierung:** [clock format [clock seconds] -format "%Y-%m-%d %H:%M"]"
    puts $fh ""
    puts $fh "- Aktuelle Priorität: [dict get $state current_priority]"
    puts $fh "- Verarbeitete Scripts: [llength [dict get $state processed]]"
    puts $fh "- Abstraktionen gesamt: [dict get $state stats abstractions_created]"
    puts $fh ""
    puts $fh "## Abstraktionen pro Sprache"
    puts $fh ""
    foreach lang [lsort [array names lang_counts]] {
        puts $fh "- $lang: $lang_counts($lang)"
    }
    puts $fh ""
    puts $fh "## Verfügbare Modelle"
    puts $fh ""
    for {set i 0} {$i < 3 && $i < [llength $AVAILABLE_MODELS]} {incr i} {
        puts $fh "- `[lindex $AVAILABLE_MODELS $i]`"
    }
    puts $fh "- ... und [expr {[llength $AVAILABLE_MODELS] - 3}] weitere"
    puts $fh ""
    puts $fh "## Multi-Node Support"
    puts $fh ""
    puts $fh "| Node | Verfügbarkeit | Kapazität | Priorität | Gerät |"
    puts $fh "|------|---------------|-----------|-----------|-------|"
    global NODES
    foreach node_id [lsort [array names NODES]] {
        array set config $NODES($node_id)
        set avail [expr {$config(always_available) ? "✅ Immer" : "📱 Bedingt"}]
        set device [expr {[info exists config(device)] ? $config(device) : "Server"}]
        puts $fh "| $node_id | $avail | $config(capacity) | $config(priority) | $device |"
    }
    puts $fh ""
    puts $fh "### Job-Verteilung"
    puts $fh ""
    puts $fh "- **Heavy Jobs** (>50KB × Sprachen) → Node 7 (Docker, hohe Ressourcen)"
    puts $fh "- **Medium Jobs** → Node 2 (Stable), Node 1 (Primary)"
    puts $fh "- **Light Jobs** → Node 5 (Redmi Note 11S, wenn verfügbar)"
    close $fh
}

proc main {} {
    log_message "Script Abstractions Manager (Multi-Node) gestartet"
    
    set state [load_state]
    log_message "State loaded: [llength [dict get $state processed]] processed"
    
    set current_priority [dict get $state current_priority]
    set created 0
    
    if {$current_priority eq "high"} {
        log_message "Processing HIGH priority: Top 5 Skills"
        set created [process_priority_high]
        if {$created > 0} {
            git_commit "High priority: $created abstractions"
        }
        dict set state current_priority medium
    } elseif {$current_priority eq "medium"} {
        log_message "Processing MEDIUM priority: Workspace Scripts"
        set created [process_priority_medium]
        if {$created > 0} {
            git_commit "Medium priority: $created abstractions"
        }
        dict set state current_priority high  # Zyklus
    }
    
    dict set state stats last_run [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%S"]
    
    set total 0
    if {[file isdirectory $ABSTRACTIONS_REPO]} {
        foreach lang [array names TARGET_LANGUAGES] {
            set lang_dir "$ABSTRACTIONS_REPO/$lang"
            if {[file isdirectory $lang_dir]} {
                foreach file [glob -nocomplain -directory $lang_dir *] {
                    if {[file tail $file] eq "." || [file tail $file] eq ".."} {
                        continue
                    }
                    if {[file isfile $file]} {
                        incr total
                    }
                }
            }
        }
    }
    dict set state stats abstractions_created $total
    
    save_state $state
    create_status_report $state
    
    log_message "Abgeschlossen. $created neue Abstraktionen erstellt."
}

if {[info script] eq $argv0} {
    main
}
