#!/usr/bin/env tclsh8.6
# json_processor.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:skills/json-utils/scripts/json_processor.py
# auch in: OpenClaw@gateway2:skills/json-utils/scripts/json_processor.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

# JSON Processor mit Tcl 8.6
# Für robuste Verarbeitung von LLM-Outputs.

package require json
package require fileutil

# Globale Variablen
set HAS_JSON_REPAIR 0

# Exception Handling
proc throw {type message} {
    error "$type: $message"
}

proc catch_exception {type script} {
    if {[catch {uplevel $script} result]} {
        if {[string match "$type:*" $result]} {
            return $result
        } else {
            error $result
        }
    }
    return $result
}

# JSON Reparatur (Fallback ohne externe Bibliothek)
proc repair_json_string {raw_json} {
    global HAS_JSON_REPAIR
    
    # Entferne führende und nachfolgende Leerzeichen
    set cleaned [string trim $raw_json]
    
    # Entferne JavaScript-Kommentare
    regsub -all {//[^\n]*\n} $cleaned "\n" cleaned
    regsub -all {/\*.*?\*/} $cleaned "" cleaned
    
    # Entferne trailing commas vor ] oder }
    regsub -all {,(\s*[\}\]])} $cleaned {\1} cleaned
    
    return $cleaned
}

# Parst JSON-String mit optionaler automatischer Reparatur
proc parse_json {raw_input {repair 1}} {
    set raw_input [string trim $raw_input]
    
    # Versuche zuerst direktes Parsing
    if {[catch {::json::json2dict $raw_input} result]} {
        # Extrahiere JSON aus Markdown-Code-Blöcken
        if {[string match "*```*" $raw_input]} {
            # Suche nach JSON in ```json ... ``` oder ``` ... ```
            set patterns [list {```json\s*(.*?)\s*```} {```\s*(\{.*?\})\s*```} {```\s*(\[.*?\])\s*```}]
            foreach pattern $patterns {
                if {[regexp -nocase $pattern $raw_input match extracted]} {
                    if {![catch {::json::json2dict $extracted} result]} {
                        return $result
                    }
                }
            }
        }
        
        # Versuche Reparatur
        if {$repair} {
            set repaired [repair_json_string $raw_input]
            if {[catch {::json::json2dict $repaired} result]} {
                throw "JSONProcessingError" "Could not parse JSON even after repair: $result"
            }
            return $result
        }
        
        throw "JSONProcessingError" "Could not parse JSON"
    }
    
    return $result
}

# Sicheres JSON-Parsing mit Fallback auf Default-Wert
proc safe_json_loads {raw_input {default ""} {repair 1}} {
    if {[catch {parse_json $raw_input $repair} result]} {
        return $default
    }
    return $result
}

# Extrahiert alle JSON-Objekte aus einem Text
proc extract_json_from_text {text} {
    set results [list]
    
    # Pattern für JSON-Objekte und Arrays
    set patterns [list {\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}} {\[[^\[\]]*(?:\[[^\[\]*\][^\[\]]*)*\]}]
    
    foreach pattern $patterns {
        set matches [regexp -all -inline $pattern $text]
        foreach match $matches {
            if {![catch {parse_json $match 1} parsed]} {
                lappend results $parsed
            }
        }
    }
    
    return $results
}

# CLI-Interface
proc main {} {
    global argv argc
    
    if {$argc == 0} {
        puts stderr "Usage: $argv0 <input> \[options\]"
        puts stderr "Options:"
        puts stderr "  -f, --file       Input is a file path"
        puts stderr "  -r, --repair     Enable JSON repair (default)"
        puts stderr "  --no-repair      Disable JSON repair"
        puts stderr "  -p, --pretty     Pretty print output"
        exit 1
    }
    
    set input [lindex $argv 0]
    set is_file 0
    set repair 1
    set pretty 0
    
    # Parse arguments
    for {set i 1} {$i < $argc} {incr i} {
        set arg [lindex $argv $i]
        switch $arg {
            "-f" - "--file" {
                set is_file 1
            }
            "-r" - "--repair" {
                set repair 1
            }
            "--no-repair" {
                set repair 0
            }
            "-p" - "--pretty" {
                set pretty 1
            }
            default {
                puts stderr "Unknown option: $arg"
                exit 1
            }
        }
    }
    
    # Lese Inhalt
    if {$is_file} {
        if {[catch {::fileutil::cat $input} content]} {
            puts stderr "Error reading file: $content"
            exit 1
        }
    } else {
        set content $input
    }
    
    # Parse JSON
    if {[catch {parse_json $content $repair} result]} {
        puts stderr "Error: $result"
        exit 1
    }
    
    # Ausgabe
    if {$pretty} {
        puts [::json::dict2json -pretty $result]
    } else {
        puts [::json::dict2json $result]
    }
}

# Hauptprogramm ausführen, wenn direkt aufgerufen
if {[info script] eq $argv0} {
    main
}
