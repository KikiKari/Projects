#!/usr/bin/env tclsh
# ABSTRACTIONS_MANAGER.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway2:abstraction-manager/ABSTRACTIONS_MANAGER.py
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# Script Abstractions Manager - Multi-Node Edition
#
# Portiert OpenClaw-Scripts automatisch in Zielsprachen und verwaltet
# den Verarbeitungsstatus über ein JSON-State-File. Läuft per Cron (alle 6h).
#
# Verwendung:
#     tclsh ABSTRACTIONS_MANAGER.tcl
#
# Konfiguration:
#     Alle Pfade und Einstellungen werden über Umgebungsvariablen aus der
#     Der Workspace-Pfad ist hardcoded: /home/openclaw/.openclaw/workspace

package require Tcl 8.6
package require json
package require fileutil

# ---------------------------------------------------------------------------
# Konfiguration
# ---------------------------------------------------------------------------

set WORKSPACE [file normalize "/home/openclaw/.openclaw/workspace"]
set ABSTRACTIONS_REPO [file join $WORKSPACE "git" "Abstraktionen"]
set LOG_DIR [file join $WORKSPACE "logs" "abstractions-manager"]
set STATE_FILE [file join $WORKSPACE "db" "abstractions_state.json"]

array set NODES {
    node1 {always_available true capacity medium priority 2}
    node2 {always_available true capacity medium priority 3}
    node3 {always_available false capacity medium priority 4}
    node5 {always_available false capacity low priority 5 device "Redmi Note 11S" condition mobile_internet}
    node7 {always_available true capacity high priority 1}
}

# Globale Variablen für Logging
set LOG_LEVEL INFO
set logger_initialized 0

# Verfügbare Modelle - hier simuliert, da Tcl keine direkte Entsprechung zu Python-Modulen hat
set AVAILABLE_MODELS [list "gpt-4" "claude-3" "llama-3"]

# Zielsprachen-Konfiguration
array set TARGET_LANGUAGES {
    perl5 {ext .pl shebang "#!/usr/bin/env perl" header "use strict;\nuse warnings;\n" main_block "sub main {\n    # TODO: Implementiere {source_lang} Funktionalität in Perl 5\n}\n\nmain();\n"}
    perl6 {ext .raku shebang "#!/usr/bin/env raku" header "use v6;\n" main_block "sub MAIN() {\n    # TODO: Implementiere {source_lang} Funktionalität in Raku\n}\n"}
    javascript {ext .js shebang "#!/usr/bin/env node" header "'use strict';\n" main_block "function main() {\n    // TODO: Implementiere {source_lang} Funktionalität in JavaScript\n}\n\nmain();\n"}
    python {ext .py shebang "#!/usr/bin/env python3" header "" main_block "def main():\n    # TODO: Implementiere {source_lang} Funktionalität in Python\n    pass\n\n\nif __name__ == '__main__':\n    main()\n"}
    shell {ext .sh shebang "#!/bin/bash" header "set -euo pipefail\n" main_block "main() {\n    # TODO: Implementiere {source_lang} Funktionalität in Bash\n}\n\nmain \"$@\"\n"}
    powershell {ext .ps1 shebang "#!/usr/bin/env pwsh" header "#Requires -Version 7\n" main_block "function Main {\n    # TODO: Implementiere {source_lang} Funktionalität in PowerShell\n}\n\nMain\n"}
    tcl {ext .tcl shebang "#!/usr/bin/env tclsh" header "package require Tcl 8.6\n" main_block "proc main {} {\n    # TODO: Implementiere {source_lang} Funktionalität in Tcl\n}\n\nmain\n"}
    ruby {ext .rb shebang "#!/usr/bin/env ruby" header "# frozen_string_literal: true\nrequire 'json'\nrequire 'fileutils'\n" main_block "def main\n  # TODO: Implementiere {source_lang} Funktionalität in Ruby\nend\n\nmain if __FILE__ == \$PROGRAM_NAME\n"}
    lua {ext .lua shebang "#!/usr/bin/env lua" header "" main_block "local function main()\n    -- TODO: Implementiere {source_lang} Funktionalität in Lua\nend\n\nmain()\n"}
    go {ext .go shebang "// +build ignore" header "package main\n\nimport \"fmt\"\n" main_block "func main() {\n    // TODO: Implementiere {source_lang} Funktionalität in Go\n    _ = fmt.Println\n}\n"}
}

# ---------------------------------------------------------------------------
# Logging-Setup
# ---------------------------------------------------------------------------

proc setup_logger {} {
    global LOG_DIR LOG_LEVEL logger_initialized
    
    if {$logger_initialized} {
        return
    }
    
    file mkdir $LOG_DIR
    set logger_initialized 1
}

proc log_message {level message} {
    global LOG_LEVEL
    
    set levels [list DEBUG INFO WARNING ERROR CRITICAL]
    set level_index [lsearch $levels $level]
    set current_level_index [lsearch $levels $LOG_LEVEL]
    
    if {$level_index >= $current_level_index} {
        set timestamp [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
        puts "$timestamp | $level | [info level 1]: $message"
    }
}

proc log_debug {message} { log_message "DEBUG" $message }
proc log_info {message} { log_message "INFO" $message }
proc log_warning {message} { log_message "WARNING" $message }
proc log_error {message} { log_message "ERROR" $message }

# ---------------------------------------------------------------------------
# State-Management
# ---------------------------------------------------------------------------

proc load_state {} {
    global STATE_FILE
    
    set default_state [dict create \
        processed [dict create] \
        queue [list] \
        current_priority "high" \
        stats [dict create total_scripts 0 abstractions_created 0]
    ]
    
    if {![file exists $STATE_FILE]} {
        return $default_state
    }
    
    if {[catch {set fh [open $STATE_FILE r]}]} {
        log_error "State-File konnte nicht gelesen werden ($STATE_FILE): $fh"
        return $default_state
    }
    
    if {[catch {set content [read $fh]}]} {
        close $fh
        log_error "State-File konnte nicht gelesen werden ($STATE_FILE): $content"
        return $default_state
    }
    
    close $fh
    
    if {[catch {set state [::json::json2dict $content]}]} {
        log_error "State-File konnte nicht geparst werden ($STATE_FILE): $state"
        return $default_state
    }
    
    return $state
}

proc save_state {state} {
    global STATE_FILE
    
    file mkdir [file dirname $STATE_FILE]
    
    set tmp_path [file join [file dirname $STATE_FILE] ".abstractions_state_[pid].tmp"]
    
    if {[catch {set fh [open $tmp_path w]}]} {
        log_error "State konnte nicht gespeichert werden: $fh"
        return
    }
    
    puts $fh [::json::dict2json $state]
    close $fh
    
    if {[catch {file rename -force $tmp_path $STATE_FILE}]} {
        log_error "State konnte nicht gespeichert werden: $tmp_path -> $STATE_FILE"
        file delete $tmp_path
    } else {
        log_debug "State atomar gespeichert: $STATE_FILE"
    }
}

# ---------------------------------------------------------------------------
# Node-Management
# ---------------------------------------------------------------------------

proc check_node_status {node_id} {
    global NODES
    
    if {[catch {set result [exec openclaw nodes status $node_id]} error]} {
        if {[string match "*not found*" $error]} {
            log_warning "'openclaw'-Binary nicht gefunden — verwende always_available für $node_id"
        } else {
            log_warning "OSError beim Status-Check von $node_id: $error — verwende always_available"
        }
        return [dict get $NODES($node_id) always_available]
    }
    
    set stdout_lower [string tolower $result]
    if {[string match "*online*" $stdout_lower] || [string match "*active*" $stdout_lower]} {
        return 1
    }
    
    return 0
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

proc get_node_by_priority {{job_weight "medium"}} {
    global NODES
    
    switch $job_weight {
        "heavy" {
            set preferred_order [list "node7" "node2" "node1"]
        }
        "medium" {
            set preferred_order [list "node2" "node1" "node7"]
        }
        "light" {
            set preferred_order [list "node5" "node1" "node2"]
        }
        default {
            set preferred_order [list "node1" "node2"]
        }
    }
    
    foreach node_id $preferred_order {
        if {![info exists NODES($node_id)]} {
            continue
        }
        
        array set node_cfg $NODES($node_id)
        if {![dict get $node_cfg always_available] && $job_weight != "light"} {
            continue
        }
        
        if {[check_node_status $node_id]} {
            log_debug "Node $node_id ausgewählt für $job_weight-Job"
            return $node_id
        }
    }
    
    log_warning "Kein passender Node gefunden für Gewicht '$job_weight' — Fallback node1"
    return "node1"
}

# ---------------------------------------------------------------------------
# Script-Verarbeitung
# ---------------------------------------------------------------------------

proc find_scripts_in_dir {directory {exclude_patterns [list "node_modules" ".git" "__pycache__" "dist" "build"]}} {
    set scripts [list]
    
    if {![file exists $directory]} {
        log_debug "Verzeichnis existiert nicht: $directory"
        return $scripts
    }
    
    foreach glob_pattern [list "*.py" "*.js" "*.sh" "*.pl" "*.rb"] {
        foreach script_path [glob -nocomplain -dir $directory -types f $glob_pattern] {
            set exclude 0
            foreach pattern $exclude_patterns {
                if {[string match "*$pattern*" $script_path]} {
                    set exclude 1
                    break
                }
            }
            if {!$exclude} {
                lappend scripts $script_path
            }
        }
    }
    
    return $scripts
}

proc build_stub_content {script_path target_lang source_lang template} {
    set today [clock format [clock seconds] -format "%Y-%m-%d"]
    
    set original_lines [list]
    if {[catch {set fh [open $script_path r]}]} {
        log_warning "Originaldatei konnte nicht gelesen werden: $fh"
    } else {
        set content [read $fh]
        close $fh
        set original_lines [lrange [split $content "\n"] 0 14]
    }
    
    set comment_char "#"
    if {$target_lang in [list "go" "javascript"]} {
        set comment_char "//"
    }
    
    set original_preview ""
    foreach line $original_lines {
        append original_preview "$comment_char $line\n"
    }
    
    set main_block [format [dict get $template main_block] $source_lang]
    
    set content ""
    append content "[dict get $template shebang]\n"
    append content "$comment_char [file rootname [file tail $script_path]] - [string totitle $target_lang] Version\n"
    append content "$comment_char Portiert von $source_lang\n"
    append content "$comment_char Original: $script_path\n"
    append content "$comment_char Erstellt: $today\n\n"
    append content "[dict get $template header]\n"
    append content "$comment_char Original-Code-Referenz:\n"
    append content "$original_preview\n"
    append content "$main_block"
    
    return $content
}

proc create_abstraction {script_path target_lang} {
    global ABSTRACTIONS_REPO TARGET_LANGUAGES
    
    if {![info exists TARGET_LANGUAGES($target_lang)]} {
        log_error "Unbekannte Zielsprache: $target_lang"
        return 0
    }
    
    array set template $TARGET_LANGUAGES($target_lang)
    
    array set ext_map {
        py Python
        js JavaScript
        sh Shell
        pl Perl
        rb Ruby
    }
    
    set ext [string range [file extension $script_path] 1 end]
    if {[info exists ext_map($ext)]} {
        set source_lang $ext_map($ext)
    } else {
        set source_lang [string totitle $ext]
    }
    
    set target_dir [file join $ABSTRACTIONS_REPO $target_lang]
    if {[catch {file mkdir $target_dir} error]} {
        log_error "Zielverzeichnis konnte nicht erstellt werden ($target_dir): $error"
        return 0
    }
    
    set target_file [file join $target_dir "[file rootname [file tail $script_path]][dict get $template ext]"]
    if {[file exists $target_file]} {
        log_debug "Bereits vorhanden, übersprungen: $target_file"
        return 0
    }
    
    set content [build_stub_content $script_path $target_lang $source_lang [array get template]]
    
    set tmp_path [file join $target_dir ".stub_[pid][dict get $template ext]"]
    if {[catch {set fh [open $tmp_path w]} error]} {
        log_error "Stub konnte nicht geschrieben werden ($target_file): $error"
        return 0
    }
    
    puts -nonewline $fh $content
    close $fh
    
    if {[catch {file rename -force $tmp_path $target_file} error]} {
        log_error "Stub konnte nicht geschrieben werden ($target_file): $error"
        file delete $tmp_path
        return 0
    }
    
    log_info "Erstellt: $target_file"
    return 1
}

proc process_on_node {node_id scripts target_langs} {
    set created 0
    
    if {$node_id eq "node1"} {
        foreach script_path $scripts {
            foreach lang $target_langs {
                if {[create_abstraction $script_path $lang]} {
                    incr created
                }
            }
        }
    } else {
        log_info "Dispatching [llength $scripts] Jobs an $node_id (lokaler Fallback aktiv)"
        foreach script_path $scripts {
            foreach lang $target_langs {
                if {[create_abstraction $script_path $lang]} {
                    incr created
                    log_debug "Verarbeitet auf $node_id: [file tail $script_path] → $lang"
                }
            }
        }
    }
    
    return $created
}

# ---------------------------------------------------------------------------
# Prioritäts-Verarbeitung
# ---------------------------------------------------------------------------

proc process_priority_high {} {
    global WORKSPACE
    
    set target_dirs [list \
        [list "skill-creator"   [file join $WORKSPACE "skills" "skill-creator"   "scripts"]] \
        [list "json-utils"      [file join $WORKSPACE "skills" "json-utils"       "scripts"]] \
        [list "scripting-utils" [file join $WORKSPACE "skills" "scripting-utils"  "scripts"]] \
        [list "model-usage"     [file join $WORKSPACE "skills" "model-usage"      "scripts"]] \
        [list "tiktok-live"     [file join $WORKSPACE "skills" "tiktok-live"      "scripts"]] \
    ]
    
    set target_langs [list "perl5" "javascript" "python" "shell" "tcl"]
    set created 0
    set exclude [list "node_modules" ".git" "test" "tests"]
    
    foreach dir_info $target_dirs {
        lassign $dir_info skill_name scripts_dir
        set scripts [find_scripts_in_dir $scripts_dir -exclude_patterns $exclude]
        log_info "$skill_name: [llength $scripts] Scripts gefunden"
        
        set count 0
        foreach script_path $scripts {
            if {$count >= 10} break
            incr count
            
            set script_size 0
            if {[file exists $script_path]} {
                set script_size [file size $script_path]
            }
            
            set job_weight [get_job_weight $script_size [llength $target_langs]]
            set selected_node [get_node_by_priority $job_weight]
            log_info "Verarbeite [file tail $script_path] ($job_weight) auf $selected_node"
            incr created [process_on_node $selected_node [list $script_path] $target_langs]
        }
    }
    
    return $created
}

proc process_priority_medium {} {
    global WORKSPACE
    
    set target_dirs [list \
        [list "workspace-scripts" [file join $WORKSPACE "scripts"]] \
        [list "db-maintainer"     [file join $WORKSPACE "skills" "db-maintainer"  "scripts"]] \
        [list "log-collector"     [file join $WORKSPACE "skills" "log-collector"   "scripts"]] \
    ]
    
    set target_langs [list "perl5" "javascript" "powershell" "python"]
    set created 0
    set exclude [list "node_modules" ".git"]
    
    foreach dir_info $target_dirs {
        lassign $dir_info dir_name scripts_dir
        set scripts [find_scripts_in_dir $scripts_dir -exclude_patterns $exclude]
        
        set count 0
        foreach script_path $scripts {
            if {$count >= 10} break
            incr count
            
            set script_size 0
            if {[file exists $script_path]} {
                set script_size [file size $script_path]
            }
            
            set job_weight [get_job_weight $script_size [llength $target_langs]]
            set effective_weight $job_weight
            if {$job_weight eq "heavy"} {
                set effective_weight "medium"
            }
            
            set selected_node [get_node_by_priority $effective_weight]
            log_info "Verarbeite [file tail $script_path] ($job_weight) auf $selected_node"
            incr created [process_on_node $selected_node [list $script_path] $target_langs]
        }
    }
    
    return $created
}

# ---------------------------------------------------------------------------
# Git-Integration
# ---------------------------------------------------------------------------

proc git_commit {message} {
    global ABSTRACTIONS_REPO
    
    if {![file exists $ABSTRACTIONS_REPO]} {
        log_warning "Abstractions-Repo existiert nicht: $ABSTRACTIONS_REPO"
        return
    }
    
    if {[catch {exec git -C $ABSTRACTIONS_REPO add .} error]} {
        if {[string match "*not found*" $error]} {
            log_error "'git'-Binary nicht gefunden — Commit übersprungen"
        } else {
            log_warning "Git-Befehl fehlgeschlagen (add): $error"
        }
        return
    }
    
    if {[catch {exec git -C $ABSTRACTIONS_REPO commit -m $message} error]} {
        if {[string match "*not found*" $error]} {
            log_error "'git'-Binary nicht gefunden — Commit übersprungen"
        } else {
            log_warning "Git-Befehl fehlgeschlagen (commit): $error"
        }
        return
    }
    
    log_info "Git commit erfolgreich: $message"
}

# ---------------------------------------------------------------------------
# Status-Report
# ---------------------------------------------------------------------------

proc create_status_report {state} {
    global ABSTRACTIONS_REPO TARGET_LANGUAGES AVAILABLE_MODELS NODES
    
    if {![file exists $ABSTRACTIONS_REPO]} {
        log_warning "Abstractions-Repo existiert nicht: $ABSTRACTIONS_REPO"
        return
    }
    
    array set lang_counts {}
    foreach lang_dir [glob -nocomplain -dir $ABSTRACTIONS_REPO -type d *] {
        set lang_name [file tail $lang_dir]
        if {[info exists TARGET_LANGUAGES($lang_name)]} {
            set count 0
            foreach f [glob -nocomplain -dir $lang_dir -type f *] {
                incr count
            }
            set lang_counts($lang_name) $count
        }
    }
    
    set report_file [file join $ABSTRACTIONS_REPO "STATUS.md"]
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
    
    set count 0
    foreach model $AVAILABLE_MODELS {
        if {$count >= 3} break
        puts $fh "- `$model`"
        incr count
    }
    puts $fh "- ... und [expr {[llength $AVAILABLE_MODELS] - 3}] weitere"
    
    puts $fh ""
    puts $fh "## Multi-Node Support"
    puts $fh ""
    puts $fh "| Node | Verfügbarkeit | Kapazität | Priorität | Gerät |"
    puts $fh "|------|---------------|-----------|-----------|-------|"
    
    foreach node_id [lsort [array names NODES]] {
        array set cfg $NODES($node_id)
        set avail "✅ Immer"
        if {![dict get $cfg always_available]} {
            set avail "📱 Bedingt"
        }
        set device "Server"
        if {[dict exists $cfg device]} {
            set device [dict get $cfg device]
        }
        puts $fh "| $node_id | $avail | [dict get $cfg capacity] | [dict get $cfg priority] | $device |"
    }
    
    puts $fh ""
    puts $fh "### Job-Verteilung"
    puts $fh ""
    puts $fh "- **Heavy Jobs** (>50 KB × Sprachen) → Node 7 (Docker, hohe Ressourcen)"
    puts $fh "- **Medium Jobs** → Node 2 (Stable), Node 1 (Primary)"
    puts $fh "- **Light Jobs** → Node 5 (Redmi Note 11S, wenn verfügbar)"
    
    close $fh
    log_info "Status-Report erstellt: $report_file"
}

# ---------------------------------------------------------------------------
# Einstiegspunkt
# ---------------------------------------------------------------------------

proc main {} {
    setup_logger
    log_info "Script Abstractions Manager (Multi-Node) gestartet"
    
    set state [load_state]
    log_info "State geladen: [llength [dict get $state processed]] bereits verarbeitet"
    
    set current_priority [dict get $state current_priority]
    set created 0
    
    if {$current_priority eq "high"} {
        log_info "Verarbeite HIGH-Priorität: Top 5 Skills"
        set created [process_priority_high]
        if {$created > 0} {
            git_commit "High priority: $created abstractions"
        }
        dict set state current_priority "medium"
    } elseif {$current_priority eq "medium"} {
        log_info "Verarbeite MEDIUM-Priorität: Workspace Scripts"
        set created [process_priority_medium]
        if {$created > 0} {
            git_commit "Medium priority: $created abstractions"
        }
        dict set state current_priority "high"
    }
    
    dict set state stats last_run [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%S"]
    
    set total_count 0
    foreach lang [array names ::TARGET_LANGUAGES] {
        set lang_dir [file join $::ABSTRACTIONS_REPO $lang]
        if {[file exists $lang_dir]} {
            foreach f [glob -nocomplain -dir $lang_dir -type f *] {
                incr total_count
            }
        }
    }
    dict set state stats abstractions_created $total_count
    
    save_state $state
    create_status_report $state
    
    log_info "Abgeschlossen. $created neue Abstraktionen erstellt."
}

# Programmstart
if {[info script] eq $argv0} {
    main
}
