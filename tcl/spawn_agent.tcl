#!/usr/bin/env tclsh8.6
# spawn_agent.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:skills/sub-agents-utils/scripts/spawn_agent.py
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

# Sub-Agent spawner - Einfache CLI für sessions_spawn

package require json
package require cmdline

# Globale Variablen
set MODELS {}

# Lade Modellkonfiguration
proc load_models {} {
    global MODELS
    set config_path [expr {[info exists ::env(OPENCLAW_CONFIG)] ? $::env(OPENCLAW_CONFIG) : "/home/openclaw/.openclaw/openclaw.json"}]
    
    if {![file exists $config_path]} {
        error "Modellkonfiguration kann nicht geladen werden: $config_path: Datei nicht gefunden"
    }
    
    set fp [open $config_path r]
    set content [read $fp]
    close $fp
    
    if {[catch {::json::json2dict $content} config]} {
        error "Modellkonfiguration kann nicht geladen werden: $config_path: Ungültiges JSON"
    }
    
    if {![dict exists $config agents defaults model]} {
        error "Modellkonfiguration kann nicht geladen werden: $config_path: Fehlende Struktur"
    }
    
    set model_config [dict get $config agents defaults model]
    set candidates [list]
    
    if {[dict exists $model_config primary]} {
        lappend candidates [dict get $model_config primary]
    }
    
    if {[dict exists $model_config fallbacks]} {
        set fallbacks [dict get $model_config fallbacks]
        if {[llength $fallbacks] > 0} {
            foreach fallback $fallbacks {
                lappend candidates $fallback
            }
        }
    }
    
    set models [list]
    foreach model $candidates {
        if {$model != "" && ![string match "anthropic/*" $model]} {
            lappend models $model
        }
    }
    
    # Entferne Duplikate unter Beibehaltung der Reihenfolge
    set unique_models [list]
    set seen [dict create]
    foreach model $models {
        if {![dict exists $seen $model]} {
            dict set seen $model 1
            lappend unique_models $model
        }
    }
    
    if {[llength $unique_models] == 0} {
        error "Keine allgemein verfügbaren Modelle in $config_path"
    }
    
    set MODELS $unique_models
    return $unique_models
}

# Hilfsfunktion zur Erstellung der Spawn-Konfiguration
proc get_spawn_config {args} {
    global MODELS
    array set params $args
    
    set config [dict create task $params(task)]
    
    if {[info exists params(label)] && $params(label) ne ""} {
        dict set config label $params(label)
    }
    
    if {[info exists params(model)] && $params(model) ne "" && [lsearch -exact $MODELS $params(model)] != -1} {
        dict set config model $params(model)
    }
    
    if {[info exists params(thinking)] && $params(thinking) ne ""} {
        dict set config thinking $params(thinking)
    }
    
    if {[info exists params(timeout)] && $params(timeout) ne "" && $params(timeout) > 0} {
        dict set config runTimeoutSeconds $params(timeout)
    }
    
    if {[info exists params(thread)] && $params(thread)} {
        dict set config thread true
        if {![info exists params(mode)] || $params(mode) eq "run"} {
            dict set config mode session
        } else {
            dict set config mode $params(mode)
        }
    } else {
        dict set config mode [expr {[info exists params(mode)] ? $params(mode) : "run"}]
    }
    
    return $config
}

# Gibt das equivalente Tool-Kommando aus
proc print_spawn_command {config} {
    puts "\n🛠️  Tool-Aufruf:"
    puts "=================================================="
    puts "sessions_spawn("
    
    dict for {key value} $config {
        if {[string is integer $value] || [string is boolean $value]} {
            puts "    $key=$value"
        } else {
            puts "    $key=\"$value\""
        }
    }
    
    puts ")"
    puts "=================================================="
}

# Gibt das equivalente Slash-Kommando aus
proc print_slash_command {config} {
    set task [expr {[dict exists $config task] ? [dict get $config task] : ""}]
    set label [expr {[dict exists $config label] ? [dict get $config label] : "agent"}]
    set model [expr {[dict exists $config model] ? [dict get $config model] : ""}]
    
    set cmd "/subagents spawn $label \"$task\""
    
    if {$model ne ""} {
        append cmd " --model $model"
    }
    
    if {[dict exists $config thinking]} {
        append cmd " --thinking [dict get $config thinking]"
    }
    
    puts "\n💬 Slash Command:"
    puts "=================================================="
    puts $cmd
    puts "=================================================="
}

# Hauptprogramm
proc main {} {
    global MODELS argv
    
    # Lade verfügbare Modelle
    set MODELS [load_models]
    
    # Kommandozeilenoptionen definieren
    set options {
        {task.arg "" "Aufgabenbeschreibung"}
        {label.arg "" "Optionaler Label"}
        {model.arg "" "KI-Modell"}
        {thinking.arg "" "Thinking Level (low|medium|high)"}
        {timeout.arg "900" "Timeout in Sekunden (default: 900)"}
        {thread "Thread-Binding aktivieren"}
        {mode.arg "run" "Run mode (run|session)"}
        {output.arg "tool" "Output format (tool|slash|json)"}
    }
    
    # Parse Kommandozeilenargumente
    if {[catch {array set opts [cmdline::getoptions argv $options]} result]} {
        puts stderr $result
        exit 1
    }
    
    # Validierung der erforderlichen Parameter
    if {$opts(task) eq ""} {
        puts stderr "Fehler: --task ist ein Pflichtfeld"
        exit 1
    }
    
    # Validierung des Modells
    if {$opts(model) ne "" && [lsearch -exact $MODELS $opts(model)] == -1} {
        puts stderr "Ungültiges Modell: $opts(model)"
        puts stderr "Verfügbare Modelle: [join $MODELS ", "]"
        exit 1
    }
    
    # Validierung von thinking
    if {$opts(thinking) ne "" && [lsearch -exact {low medium high} $opts(thinking)] == -1} {
        puts stderr "Ungültiger Wert für thinking: $opts(thinking). Erlaubt sind: low, medium, high"
        exit 1
    }
    
    # Validierung von mode
    if {$opts(mode) ne "" && [lsearch -exact {run session} $opts(mode)] == -1} {
        puts stderr "Ungültiger Wert für mode: $opts(mode). Erlaubt sind: run, session"
        exit 1
    }
    
    # Validierung von output
    if {$opts(output) ne "" && [lsearch -exact {tool slash json} $opts(output)] == -1} {
        puts stderr "Ungültiger Wert für output: $opts(output). Erlaubt sind: tool, slash, json"
        exit 1
    }
    
    # Erstelle Konfiguration
    set config_params [list \
        task $opts(task) \
        label $opts(label) \
        model $opts(model) \
        thinking $opts(thinking) \
        timeout $opts(timeout) \
        thread [expr {[info exists opts(thread)] ? 1 : 0}] \
        mode $opts(mode) \
    ]
    
    set config [get_spawn_config {*}$config_params]
    
    # Ausgabe der Konfiguration
    puts "✅ Sub-Agent Konfiguration:"
    puts [::json::write $config]
    
    # Formatabhängige Ausgabe
    switch $opts(output) {
        "tool" {
            print_spawn_command $config
        }
        "slash" {
            print_slash_command $config
        }
        "json" {
            puts "\n📄 JSON:"
            puts [::json::write $config]
            
            # Speichere als Datei
            set label [expr {[dict exists $config label] ? [dict get $config label] : "spawn"}]
            set output_file "/tmp/subagent_${label}.json"
            
            set fp [open $output_file w]
            puts $fp [::json::write $config]
            close $fp
            
            puts "💾 Gespeichert: $output_file"
        }
    }
}

# Starte das Hauptprogramm
if {[info script] eq $argv0} {
    main
}
