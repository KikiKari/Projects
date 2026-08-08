#!/usr/bin/env tclsh
# ABSTRACTIONS_MANAGER.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:ABSTRACTIONS_MANAGER.py
# auch in: OpenClaw@gateway1:skills/script-abstractions-manager/scripts/ABSTRACTIONS_MANAGER.py
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
#     zentralen .env bezogen. OPENCLAW_WORKSPACE muss gesetzt sein.

package require Tcl 8.6
package require json
package require fileutil

# ---------------------------------------------------------------------------
# Konfiguration
# ---------------------------------------------------------------------------

set WORKSPACE [expr {[info exists ::env(OPENCLAW_WORKSPACE)] ? $::env(OPENCLAW_WORKSPACE) : "/home/openclaw/.openclaw/workspace"}]
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

set AVAILABLE_MODELS {
    "openrouter/moonshotai/kimi-k2.5"
    "openrouter/openai/gpt-4o"
    "openrouter/anthropic/claude-3-5-sonnet-20241022"
    "openrouter/google/gemini-2.0-flash-001"
    "openrouter/nvidia/llama-3.3-nemotron-super-49b-v1"
    "openrouter/qwen/qwen-2.5-coder-32b-instruct"
}

array set TARGET_LANGUAGES {
    perl5 {ext .pl shebang "#!/usr/bin/env perl" header "use strict;\nuse warnings;\n" main_block "sub main {\n    # TODO: Implementiere {source_lang} Funktionalität in Perl 5\n}\n\nmain();\n"}
    perl6 {ext .raku shebang "#!/usr/bin/env raku" header "use v6;\n" main_block "sub MAIN() {\n    # TODO: Implementiere {source_lang} Funktionalität in Raku\n}\n"}
    javascript {ext .js shebang "#!/usr/bin/env node" header "'use strict';\n" main_block "function main() {\n    // TODO: Implementiere {source_lang} Funktionalität in JavaScript\n}\n\nmain();\n"}
    python {ext .py shebang "#!/usr/bin/env python3" header "" main_block "def main():\n    # TODO: Implementiere {source_lang} Funktionalität in Python\n    pass\n\n\nif __name__ == '__main__':\n    main()\n"}
    shell {ext .sh shebang "#!/bin/bash" header "set -euo pipefail\n" main_block "main() {\n    # TODO: Implementiere {source_lang} Funktionalität in Bash\n}\n\nmain \"\$@\"\n"}
    powershell {ext .ps1 shebang "#!/usr/bin/env pwsh" header "#Requires -Version 7\n" main_block "function Main {\n    # TODO: Implementiere {source_lang} Funktionalität in PowerShell\n}\n\nMain\n"}
    tcl {ext .tcl shebang "#!/usr/bin/env tclsh" header "package require Tcl 8.6\n" main_block "proc main {} {\n    # TODO: Implementiere {source_lang} Funktionalität in Tcl\n}\n\nmain\n"}
    ruby {ext .rb shebang "#!/usr/bin/env ruby" header "# frozen_string_literal: true\nrequire 'json'\nrequire 'fileutils'\n" main_block "def main\n  # TODO: Implementiere {source_lang} Funktionalität in Ruby\nend\n\nmain if __FILE__ == \$PROGRAM_NAME\n"}
    lua {ext .lua shebang "#!/usr/bin/env lua" header "" main_block "local function main()\n    -- TODO: Implementiere {source_lang} Funktionalität in Lua\nend\n\nmain()\n"}
    go {ext .go shebang "// +build ignore" header "package main\n\nimport \"fmt\"\n" main_block "func main() {\n    // TODO: Implementiere {source_lang} Funktionalität in Go\n    _ = fmt.Println\n}\n"}
}

# ---------------------------------------------------------------------------
# Logging-Setup (einmalig konfiguriert, nicht pro Aufruf geöffnet)
# ---------------------------------------------------------------------------

proc _setup_logger {} {
    global LOG_DIR
    file mkdir $LOG_DIR
    
    set log_level_name [expr {[info exists ::env(ABSTRACTIONS_LOG_LEVEL)] ? [string toupper $::env(ABSTRACTIONS_LOG_LEVEL)] : "INFO"}]
    set log_level [expr {$log_level_name eq "DEBUG" ? "debug" : $log_level_name eq "WARNING" ? "warning" : $log_level_name eq "ERROR" ? "error" : "info"}]
    
    # In Tcl verwenden wir einfach puts für Logging
    return $log_level
}

set logger [_setup_logger]

proc log_message {level message} {
    global logger
    set timestamp [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
    if {$level eq "debug" && $logger ne "debug"} {
        return
    }
    if {$level eq "info" && ($logger eq "warning" || $logger eq "error")} {
        return
    }
    if {$level eq "warning" && $logger eq "error"} {
        return
    }
    puts stderr "$timestamp | [string toupper $level] | $message"
}

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
    
    if {[catch {set fh [open $STATE_FILE r]} err]} {
        log_message error "State-File konnte nicht gelesen werden ($STATE_FILE): $err"
        return $default_state
    }
    
    if {[catch {set data [::json::json2dict [read $fh]]} err]} {
        log_message error "State-File konnte nicht geparst werden ($STATE_FILE): $err"
        close $fh
        return $default_state
    }
    
    close $fh
    return $data
}

proc save_state {state} {
    global STATE_FILE
    file mkdir [file dirname $STATE_FILE]
    
    set tmp_path [file join [file dirname $STATE_FILE] ".abstractions_state_[pid].tmp"]
    
    if {[catch {set fh [open $tmp_path w]} err]} {
        log_message error "State konnte nicht gespeichert werden: $err"
        return
    }
    
    puts $fh [::json::dict2json $state]
    close $fh
    
    if {[catch {file rename -force $tmp_path $STATE_FILE} err]} {
        log_message error "State konnte nicht gespeichert werden: $err"
        file delete $tmp_path
    } else {
        log_message debug "State atomar gespeichert: $STATE_FILE"
    }
}

# ---------------------------------------------------------------------------
# Node-Management
# ---------------------------------------------------------------------------

proc check_node_status {node_id} {
    global NODES
    if {[catch {set result [exec openclaw nodes status $node_id]} err]} {
        if {[string match "*not found*" $err]} {
            log_message warning "'openclaw'-Binary nicht gefunden — verwende always_available für $node_id"
        } else {
            log_message warning "OSError beim Status-Check von $node_id: $err — verwende always_available"
        }
        return [dict get $NODES($node_id) always_available]
    }
    
    set stdout_lower [string tolower $result]
    return [expr {[string first "online" $stdout_lower] != -1 || [string first "active" $stdout_lower] != -1}]
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

proc get_node_by_priority {job_weight} {
    set weight_to_preference(heavy) [list node7 node2 node1]
    set weight_to_preference(medium) [list node2 node1 node7]
    set weight_to_preference(light) [list node5 node1 node2]
    
    set preferred_order [expr {[info exists weight_to_preference($job_weight)] ? $weight_to_preference($job_weight) : [list node1 node2]}]
    
    foreach node_id $preferred_order {
        if {![info exists ::NODES($node_id)]} {
            continue
        }
        array set node_cfg $::NODES($node_id)
        if {![dict get $node_cfg always_available] && $job_weight ne "light"} {
            continue
        }
        if {[check_node_status $node_id]} {
            log_message debug "Node $node_id ausgewählt für $job_weight-Job"
            return $node_id
        }
    }
    
    log_message warning "Kein passender Node gefunden für Gewicht '$job_weight' — Fallback node1"
    return "node1"
}

# ---------------------------------------------------------------------------
# Script-Verarbeitung
# ---------------------------------------------------------------------------

proc find_scripts_in_dir {directory {exclude_patterns {node_modules .git __pycache__ dist build}}} {
    set scripts [list]
    
    if {![file exists $directory]} {
        log_message debug "Verzeichnis existiert nicht: $directory"
        return $scripts
    }
    
    foreach glob_pattern {*.py *.js *.sh *.pl *.rb} {
        foreach script_path [glob -nocomplain -directory $directory -types f $glob_pattern] {
            set exclude_found 0
            foreach pattern $exclude_patterns {
                if {[string match "*$pattern*" $script_path]} {
                    set exclude_found 1
                    break
                }
            }
            if {!$exclude_found} {
                lappend scripts $script_path
            }
        }
    }
    
    return $scripts
}

proc _build_stub_content {script_path target_lang source_lang template} {
    set today [clock format [clock seconds] -format "%Y-%m-%d"]
    
    set original_lines [list]
    if {[catch {set fh [open $script_path r]} err]} {
        log_message warning "Originaldatei konnte nicht gelesen werden: $err"
    } else {
        set content [read $fh]
        close $fh
        set original_lines [lrange [split $content "\n"] 0 14]
    }
    
    set comment_char [expr {$target_lang in {go javascript} ? "//" : "#"}]
    set original_preview ""
    foreach line $original_lines {
        append original_preview "$comment_char $line\n"
    }
    
    set main_block [string map [list {source_lang} $source_lang] [dict get $template main_block]]
    
    return [format "%s\n%s %s - %s Version\n%s Portiert von %s\n%s Original: %s\n%s Erstellt: %s\n\n%s\n%s Original-Code-Referenz:\n%s\n%s" \
        [dict get $template shebang] \
        $comment_char [file rootname [file tail $script_path]] [string totitle $target_lang] \
        $comment_char $source_lang \
        $comment_char $script_path \
        $comment_char $today \
        [dict get $template header] \
        $comment_char \
        $original_preview \
        $main_block]
}

proc create_abstraction {script_path target_lang} {
    global TARGET_LANGUAGES ABSTRACTIONS_REPO
    if {![info exists TARGET_LANGUAGES($target_lang)]} {
        log_message error "Unbekannte Zielsprache: $target_lang"
        return 0
    }
    
    array set template $TARGET_LANGUAGES($target_lang)
    
    set ext_map(py) Python
    set ext_map(js) JavaScript
    set ext_map(sh) Shell
    set ext_map(pl) Perl
    set ext_map(rb) Ruby
    
    set source_lang [expr {[info exists ext_map([file extension $script_path])] ? $ext_map([file extension $script_path]) : [string totitle [string trimleft [file extension $script_path] .]]}]
    
    set target_dir [file join $ABSTRACTIONS_REPO $target_lang]
    if {[catch {file mkdir $target_dir} err]} {
        log_message error "Zielverzeichnis konnte nicht erstellt werden ($target_dir): $err"
        return 0
    }
    
    set target_file [file join $target_dir [file rootname [file tail $script_path]][dict get $template ext]]
    if {[file exists $target_file]} {
        log_message debug "Bereits vorhanden, übersprungen: $target_file"
        return 0
    }
    
    set content [_build_stub_content $script_path $target_lang $source_lang [array get template]]
    
    set tmp_path [file join $target_dir ".stub_[pid][dict get $template ext]"]
    if {[catch {set fh [open $tmp_path w]} err]} {
        log_message error "Stub konnte nicht geschrieben werden ($target_file): $err"
        file delete $tmp_path
        return 0
    }
    
    puts $fh $content
    close $fh
    
    if {[catch {file rename -force $tmp_path $target_file} err]} {
        log_message error "Stub konnte nicht geschrieben werden ($target_file): $err"
        file delete $tmp_path
        return 0
    }
    
    log_message info "Erstellt: $target_file"
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
        log_message info "Dispatching [llength $scripts] Jobs an $node_id (lokaler Fallback aktiv)"
        foreach script_path $scripts {
            foreach lang $target_langs {
                if {[create_abstraction $script_path $lang]} {
                    incr created
                    log_message debug "Verarbeitet auf $node_id: [file tail $script_path] → $lang"
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
        [list skill-creator [file join $WORKSPACE "skills" "skill-creator" "scripts"]] \
        [list json-utils [file join $WORKSPACE "skills" "json-utils" "scripts"]] \
        [list scripting-utils [file join $WORKSPACE "skills" "scripting-utils" "scripts"]] \
        [list model-usage [file join $WORKSPACE "skills" "model-usage" "scripts"]] \
        [list tiktok-live [file join $WORKSPACE "skills" "tiktok-live" "scripts"]] \
    ]
    set target_langs [list perl5 javascript python shell tcl]
    set created 0
    set exclude [list node_modules .git test tests]
    
    foreach dir_info $target_dirs {
        lassign $dir_info skill_name scripts_dir
        set scripts [find_scripts_in_dir $scripts_dir $exclude]
        log_message info "$skill_name: [llength $scripts] Scripts gefunden"
        
        set count 0
        foreach script_path $scripts {
            if {$count >= 10} break
            set script_size [expr {[file exists $script_path] ? [file size $script_path] : 0}]
            set job_weight [get_job_weight $script_size [llength $target_langs]]
            set selected_node [get_node_by_priority $job_weight]
            log_message info "Verarbeite [file tail $script_path] ($job_weight) auf $selected_node"
            incr created [process_on_node $selected_node [list $script_path] $target_langs]
            incr count
        }
    }
    
    return $created
}

proc process_priority_medium {} {
    global WORKSPACE
    set target_dirs [list \
        [list workspace-scripts [file join $WORKSPACE "scripts"]] \
        [list db-maintainer [file join $WORKSPACE "skills" "db-maintainer" "scripts"]] \
        [list log-collector [file join $WORKSPACE "skills" "log-collector" "scripts"]] \
    ]
    set target_langs [list perl5 javascript powershell python]
    set created 0
    set exclude [list node_modules .git]
    
    foreach dir_info $target_dirs {
        lassign $dir_info dir_name scripts_dir
        set scripts [find_scripts_in_dir $scripts_dir $exclude]
        
        set count 0
        foreach script_path $scripts {
            if {$count >= 10} break
            set script_size [expr {[file exists $script_path] ? [file size $script_path] : 0}]
            set job_weight [get_job_weight $script_size [llength $target_langs]]
            set effective_weight [expr {$job_weight eq "heavy" ? "medium" : $job_weight}]
            set selected_node [get_node_by_priority $effective_weight]
            log_message info "Verarbeite [file tail $script_path] ($job_weight) auf $selected_node"
            incr created [process_on_node $selected_node [list $script_path] $target_langs]
            incr count
        }
    }
    
    return $created
}

# ---------------------------------------------------------------------------
# Git-Integration
# ---------------------------------------------------------------------------

proc git_commit {message} {
    global ABSTRACTIONS_REPO
    set repo_str $ABSTRACTIONS_REPO
    
    if {[catch {exec git -C $repo_str add .} err]} {
        log_message warning "Git-Befehl fehlgeschlagen: $err"
        return
    }
    
    if {[catch {exec git -C $repo_str commit -m $message} err]} {
        log_message warning "Git-Befehl fehlgeschlagen: $err"
        return
    }
    
    log_message info "Git commit erfolgreich: $message"
}

# ---------------------------------------------------------------------------
# Status-Report
# ---------------------------------------------------------------------------

proc create_status_report {state} {
    global ABSTRACTIONS_REPO TARGET_LANGUAGES AVAILABLE_MODELS NODES
    if {![file exists $ABSTRACTIONS_REPO]} {
        log_message warning "Abstractions-Repo existiert nicht: $ABSTRACTIONS_REPO"
        return
    }
    
    set lang_counts [dict create]
    foreach lang_dir [glob -nocomplain -directory $ABSTRACTIONS_REPO -types d *] {
        set lang_name [file tail $lang_dir]
        if {[info exists TARGET_LANGUAGES($lang_name)]} {
            set count 0
            foreach f [glob -nocomplain -directory $lang_dir -types f *] {
                incr count
            }
            dict set lang_counts $lang_name $count
        }
    }
    
    set report_file [file join $ABSTRACTIONS_REPO "STATUS.md"]
    if {[catch {set fh [open $report_file w]} err]} {
        log_message error "Status-Report konnte nicht geschrieben werden: $err"
        return
    }
    
    set timestamp [clock format [clock seconds] -format "%Y-%m-%d %H:%M"]
    puts $fh "# Script Abstractions - Status Report\n"
    puts $fh "**Letzte Aktualisierung:** $timestamp\n"
    puts $fh "- Aktuelle Priorität: [dict get $state current_priority]"
    puts $fh "- Verarbeitete Scripts: [dict size [dict get $state processed]]"
    puts $fh "- Abstraktionen gesamt: [dict get $state stats abstractions_created]\n"
    
    puts $fh "## Abstraktionen pro Sprache\n"
    foreach lang [lsort [dict keys $lang_counts]] {
        set count [dict get $lang_counts $lang]
        puts $fh "- $lang: $count"
    }
    
    puts $fh "\n## Verfügbare Modelle\n"
    set count 0
    foreach model $AVAILABLE_MODELS {
        if {$count >= 3} break
        puts $fh "- `$model`"
        incr count
    }
    puts $fh "- ... und [expr {[llength $AVAILABLE_MODELS] - 3}] weitere\n"
    
    puts $fh "## Multi-Node Support\n"
    puts $fh "| Node | Verfügbarkeit | Kapazität | Priorität | Gerät |"
    puts $fh "|------|---------------|-----------|-----------|-------|"
    foreach node_id [lsort [array names NODES]] {
        array set cfg $NODES($node_id)
        set avail [expr {[dict get $cfg always_available] ? "✅ Immer" : "📱 Bedingt"}]
        set device [expr {[info exists cfg(device)] ? $cfg(device) : "Server"}]
        puts $fh "| $node_id | $avail | $cfg(capacity) | $cfg(priority) | $device |"
    }
    
    puts $fh "\n### Job-Verteilung\n"
    puts $fh "- **Heavy Jobs** (>50 KB × Sprachen) → Node 7 (Docker, hohe Ressourcen)"
    puts $fh "- **Medium Jobs** → Node 2 (Stable), Node 1 (Primary)"
    puts $fh "- **Light Jobs** → Node 5 (Redmi Note 11S, wenn verfügbar)"
    
    close $fh
    log_message info "Status-Report erstellt: $report_file"
}

# ---------------------------------------------------------------------------
# Einstiegspunkt
# ---------------------------------------------------------------------------

proc main {} {
    log_message info "Script Abstractions Manager (Multi-Node) gestartet"
    
    set state [load_state]
    log_message info "State geladen: [dict size [dict get $state processed]] bereits verarbeitet"
    
    set current_priority [dict get $state current_priority]
    set created 0
    
    if {$current_priority eq "high"} {
        log_message info "Verarbeite HIGH-Priorität: Top 5 Skills"
        set created [process_priority_high]
        if {$created > 0} {
            git_commit "High priority: $created abstractions"
        }
        dict set state current_priority "medium"
    } elseif {$current_priority eq "medium"} {
        log_message info "Verarbeite MEDIUM-Priorität: Workspace Scripts"
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
            foreach f [glob -nocomplain -directory $lang_dir -types f *] {
                incr total_count
            }
        }
    }
    dict set state stats abstractions_created $total_count
    
    save_state $state
    create_status_report $state
    
    log_message info "Abgeschlossen. $created neue Abstraktionen erstellt."
}

if {[info script] eq $argv0} {
    main
}
