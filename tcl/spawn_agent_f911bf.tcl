#!/usr/bin/env tclsh8.6
# spawn_agent.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway2:skills/sub-agents-utils/scripts/spawn_agent.py
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

# Sub-Agent spawner - Einfache CLI für sessions_spawn

package require json

# WORKSPACE wird hier nicht benötigt da Tcl anders mit Pfaden umgeht

# Da Tcl keine direkte Entsprechung zu Python-Paketen hat, 
# müssen wir annehmen dass die benötigten Funktionen bereits geladen sind
# oder im gleichen Verzeichnis liegen

# Verfügbare Modelle - in Tcl müssten diese z.B. aus einer Config kommen
set MODELS [list]

# Versuche Modelle zu laden (angepasst an Tcl)
# Da Tcl keine Exceptions im gleichen Sinne wie Python hat,
# verwenden wir einen einfachen Ansatz zur Fehlerbehandlung

proc configured_models {} {
    # Dummy-Implementierung - in echtem Code würde dies aus einer Config kommen
    return [list "openrouter/anthropic/claude-haiku-4.5" "openai/gpt-4" "mistral/mistral-large"]
}

proc ModelConfigError {msg} {
    # Tcl-Fehler simulieren
    error "Modellkonfiguration kann nicht geladen werden: $msg"
}

# Lade verfügbare Modelle
if {[catch {set MODELS [configured_models]} result]} {
    puts stderr $result
    exit 1
}

# Hilfsfunktion zur Konvertierung von Dict zu JSON-ähnlichem String
proc dict_to_pretty_string {dict_val} {
    set lines [list]
    dict for {key value} $dict_val {
        if {[string is integer $value] || [string is boolean $value]} {
            lappend lines "    $key=$value"
        } else {
            lappend lines "    $key=\"$value\""
        }
    }
    return [join $lines "\n"]
}

# Hilfsfunktion zum Speichern von Dict als JSON
proc save_dict_as_json {dict_val filename} {
    set json_str [::json::write object {*}[dict flatten $dict_val]]
    set fh [open $filename w]
    puts $fh $json_str
    close $fh
}

# Hauptklasse als Tcl-Namespace simuliert
namespace eval SubAgentSpawner {
    # Erstellt Konfiguration für sessions_spawn
    proc get_spawn_config {args} {
        array set opts {
            task ""
            label ""
            model ""
            thinking ""
            timeout ""
            thread false
            mode "run"
        }
        
        # Parse arguments
        foreach {key value} $args {
            set opt_key [string trimleft $key "-"]
            if {[info exists opts($opt_key)]} {
                set opts($opt_key) $value
            }
        }
        
        set config [dict create task $opts(task)]
        
        if {$opts(label) ne ""} {
            dict set config label $opts(label)
        }
        if {$opts(model) in $::MODELS} {
            dict set config model $opts(model)
        }
        if {$opts(thinking) ne ""} {
            dict set config thinking $opts(thinking)
        }
        if {$opts(timeout) ne "" && $opts(timeout) != 0} {
            dict set config runTimeoutSeconds $opts(timeout)
        }
        if {$opts(thread)} {
            dict set config thread true
            if {$opts(mode) eq "run"} {
                dict set config mode "session"
            }
        } else {
            dict set config mode $opts(mode)
        }
        
        return $config
    }
    
    # Gibt das equivalente Tool-Kommando aus
    proc print_spawn_command {config} {
        puts "\n🛠️  Tool-Aufruf:"
        puts "=================================================="
        puts "sessions_spawn("
        puts [dict_to_pretty_string $config]
        puts ")"
        puts "=================================================="
    }
    
    # Gibt das equivalente Slash-Kommando aus
    proc print_slash_command {config} {
        set task [dict get $config task]
        set label "agent"
        if {[dict exists $config label]} {
            set label [dict get $config label]
        }
        set model ""
        if {[dict exists $config model]} {
            set model [dict get $config model]
        }
        
        set cmd "/subagents spawn $label \"$task\""
        if {$model ne ""} {
            append cmd " --model $model"
        }
        if {[dict exists $config thinking] && [dict get $config thinking] ne ""} {
            append cmd " --thinking [dict get $config thinking]"
        }
        
        puts "\n💬 Slash Command:"
        puts "=================================================="
        puts $cmd
        puts "=================================================="
    }
}

# Hauptprogramm
proc main {} {
    global argc argv MODELS
    
    # Argumente parsen
    set options [list]
    set task ""
    set label ""
    set model ""
    set thinking ""
    set timeout 900
    set thread false
    set mode "run"
    set output "tool"
    
    # Manuelle Argumentverarbeitung da Tcl kein argparse hat
    for {set i 0} {$i < $argc} {incr i} {
        set arg [lindex $argv $i]
        switch -exact -- $arg {
            "--task" - "-t" {
                incr i
                set task [lindex $argv $i]
            }
            "--label" - "-l" {
                incr i
                set label [lindex $argv $i]
            }
            "--model" - "-m" {
                incr i
                set model [lindex $argv $i]
            }
            "--thinking" {
                incr i
                set thinking [lindex $argv $i]
            }
            "--timeout" {
                incr i
                set timeout [lindex $argv $i]
            }
            "--thread" {
                set thread true
            }
            "--mode" {
                incr i
                set mode [lindex $argv $i]
            }
            "--output" - "-o" {
                incr i
                set output [lindex $argv $i]
            }
            "--help" - "-h" {
                puts "usage: spawn_agent.tcl \[-h\] --task TASK \[--label LABEL\]"
                puts "                        \[--model MODEL\] \[--thinking {low,medium,high}\]"
                puts "                        \[--timeout TIMEOUT\] \[--thread\]"
                puts "                        \[--mode {run,session}\] \[--output {tool,slash,json}\]"
                puts ""
                puts "Sub-Agent Spawn Helper"
                puts ""
                puts "optionale Argumente:"
                puts "  -h, --help            Diese Hilfe anzeigen und beenden"
                puts "  --task TASK, -t TASK  Aufgabenbeschreibung"
                puts "  --label LABEL, -l LABEL"
                puts "                        Optionaler Label"
                puts "  --model MODEL, -m MODEL"
                puts "                        KI-Modell"
                puts "  --thinking {low,medium,high}"
                puts "                        Thinking Level"
                puts "  --timeout TIMEOUT     Timeout in Sekunden (default: 900)"
                puts "  --thread              Thread-Binding aktivieren"
                puts "  --mode {run,session}  Run mode"
                puts "  --output {tool,slash,json}, -o {tool,slash,json}"
                puts "                        Output format"
                puts ""
                puts "Beispiele:"
                puts "  spawn_agent.tcl -t \"Analyze logs\" "
                puts "  spawn_agent.tcl -t \"Code review\" -m openrouter/anthropic/claude-haiku-4.5 --timeout 1800"
                puts "  spawn_agent.tcl -t \"Batch process\" -l \"batch-worker\" --thread"
                return
            }
        }
    }
    
    # Validierung
    if {$task eq ""} {
        puts stderr "Fehler: --task ist erforderlich"
        exit 1
    }
    
    # Model validieren
    if {$model ne "" && $model ni $MODELS} {
        puts stderr "Fehler: Ungültiges Modell '$model'. Gültige Optionen: [join $MODELS ", "]"
        exit 1
    }
    
    # Thinking-Level validieren
    if {$thinking ne "" && $thinking ni {"low" "medium" "high"}} {
        puts stderr "Fehler: Ungültiges Thinking-Level '$thinking'. Gültige Optionen: low, medium, high"
        exit 1
    }
    
    # Mode validieren
    if {$mode ni {"run" "session"}} {
        puts stderr "Fehler: Ungültiger Mode '$mode'. Gültige Optionen: run, session"
        exit 1
    }
    
    # Output validieren
    if {$output ni {"tool" "slash" "json"}} {
        puts stderr "Fehler: Ungültiger Output '$output'. Gültige Optionen: tool, slash, json"
        exit 1
    }
    
    # Konfiguration erstellen
    set config [SubAgentSpawner::get_spawn_config \
        -task $task \
        -label $label \
        -model $model \
        -thinking $thinking \
        -timeout $timeout \
        -thread $thread \
        -mode $mode]
    
    puts "✅ Sub-Agent Konfiguration:"
    puts [::json::write object {*}[dict flatten $config]]
    
    switch -exact -- $output {
        "tool" {
            SubAgentSpawner::print_spawn_command $config
        }
        "slash" {
            SubAgentSpawner::print_slash_command $config
        }
        "json" {
            puts "\n📄 JSON:"
            set json_output [::json::write object {*}[dict flatten $config]]
            puts $json_output
            
            # Speichere als Datei
            set label_for_filename "spawn"
            if {[dict exists $config label]} {
                set label_for_filename [dict get $config label]
            }
            set output_file "/tmp/subagent_$label_for_filename.json"
            save_dict_as_json $config $output_file
            puts "💾 Gespeichert: $output_file"
        }
    }
}

# Starte Hauptprogramm wenn dieses Skript direkt ausgeführt wird
if {[info script] eq $argv0} {
    main
}
