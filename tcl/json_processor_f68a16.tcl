#!/usr/bin/env tclsh8.6
# abstraction-provenance: {"artifact_sha256": "1a8b36cbcd5177bd636352f612c49c24a868ab88decc9536cd9a6b146c1065f9", "source_sha256": "f68a161573356fe83ce98ebe454cffaef6896f81d310cd932a9847500e671f9b", "target_language": "tcl"}
# json_processor.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:skills/json-utils/scripts/json_processor.py
# auch in: OpenClaw@gateway2:skills/json-utils/scripts/json_processor.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# JSON Processor mit Tcl 8.6
# Für robuste Verarbeitung von LLM-Outputs.

package require json
package require cmdline

# Globale Variablen
set HAS_JSON_REPAIR 0

# Error handling
proc throw {type message} {
    error "$type: $message"
}

proc catch_exception {type code} {
    upvar 1 result result
    if {[string match "*${type}*" $result]} {
        return 1
    }
    return 0
}

# JSON Repair Funktion (Fallback)
proc repair_json_string {raw_json} {
    global HAS_JSON_REPAIR
    
    # Entferne führende und abschließende Leerzeichen
    set cleaned [string trim $raw_json]
    
    # Entferne JavaScript-Kommentare
    regsub -all {//[^\n]*\n} $cleaned "\n" cleaned
    regsub -all {/\*.*?\*/} $cleaned "" cleaned
    
    # Entferne trailing commas vor ] oder }
    regsub -all {,(\s*[\}\]])} $cleaned {\1} cleaned
    
    return $cleaned
}

# Hauptfunktion zum Parsen von JSON
proc parse_json {raw_input {repair 1}} {
    set raw_input [string trim $raw_input]
    
    # Versuche zuerst direktes Parsing
    if {[catch {::json::json2dict $raw_input} result]} {
        # Extrahiere JSON aus Markdown-Code-Blöcken
        if {[regexp {```(?:json)?\s*(\{.*?\})\s*```}} $raw_input match extracted] || 
            [regexp {```\s*(\[.*?\])\s*```} $raw_input match extracted]} {
            if {[catch {::json::json2dict $extracted} result2]} {
                # Versuche Reparatur
                if {$repair} {
                    set repaired [repair_json_string $extracted]
                    if {[catch {::json::json2dict $repaired} result3]} {
                        throw "JSONProcessingError" "Could not parse JSON even after repair: $result3"
                    } else {
                        return $result3
                    }
                } else {
                    throw "JSONProcessingError" "Could not parse JSON"
                }
            } else {
                return $result2
            }
        } elseif {$repair} {
            # Versuche Reparatur
            set repaired [repair_json_string $raw_input]
            if {[catch {::json::json2dict $repaired} result4]} {
                throw "JSONProcessingError" "Could not parse JSON even after repair: $result4"
            } else {
                return $result4
            }
        } else {
            throw "JSONProcessingError" "Could not parse JSON"
        }
    } else {
        return $result
    }
}

# Sicheres JSON-Parsing mit Fallback
proc safe_json_loads {raw_input {default ""} {repair 1}} {
    if {[catch {parse_json $raw_input $repair} result]} {
        return $default
    } else {
        return $result
    }
}

# Extrahiere JSON aus Text
proc extract_json_from_text {text} {
    set results [list]
    
    # Pattern für JSON-Objekte und Arrays
    set patterns [list {\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}} {\[[^\[\]]*(?:\[[^\[\]*\][^\[\]]*)*\]}]
    
    foreach pattern $patterns {
        set matches [regexp -all -inline $pattern $text]
        foreach match $matches {
            if {[catch {parse_json $match 1} parsed]} {
                continue
            } else {
                lappend results $parsed
            }
        }
    }
    
    return $results
}

# CLI Interface
proc main {} {
    global argv argc
    
    set options {
        {file.f "Input is a file path"}
        {repair.r "Enable JSON repair" 1}
        {no-repair.R "Disable JSON repair"}
        {pretty.p "Pretty print output"}
    }
    
    set usage ": json_processor \[options\] input\n"
    append usage "Options:\n"
    
    if {[catch {cmdline::typedGetopt argv $options} opterr]} {
        puts stderr "Error: $opterr"
        exit 1
    }
    
    if {$argc < 1} {
        puts stderr "Error: Missing input argument"
        exit 1
    }
    
    set input [lindex $argv 0]
    set repair 1
    set pretty 0
    set file 0
    
    # Parse command line arguments manually since cmdline doesn't work as expected here
    for {set i 0} {$i < $argc} {incr i} {
        set arg [lindex $argv $i]
        switch -- $arg {
            "-f" - "--file" {
                set file 1
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
                if {![info exists input_val]} {
                    set input_val $arg
                }
            }
        }
    }
    
    if {![info exists input_val]} {
        puts stderr "Error: Missing input argument"
        exit 1
    }
    
    if {$file} {
        if {[catch {open $input_val r} fid]} {
            puts stderr "Error: Could not open file '$input_val': $fid"
            exit 1
        }
        set content [read $fid]
        close $fid
    } else {
        set content $input_val
    }
    
    if {[catch {parse_json $content $repair} result]} {
        puts stderr "Error: $result"
        exit 1
    } else {
        if {$pretty} {
            puts [dict pretty-print $result]
        } else {
            puts [::json::dict2json $result]
        }
    }
}

# Pretty print dict (Hilfsfunktion)
proc dict pretty-print {d {indent 0}} {
    set spaces [string repeat " " $indent]
    set result ""
    
    dict for {key value} $d {
        if {[dict exists $d $key]} {
            if {[llength $value] > 1 && [llength [lindex $value 0]] == 2} {
                # Nested dict
                append result "${spaces}${key}: \[\n"
                append result [dict pretty-print $value [expr {$indent + 2}]]
                append result "${spaces}\]\n"
            } elseif {[llength $value] > 1} {
                # List
                append result "${spaces}${key}: \["
                set first 1
                foreach item $value {
                    if {!$first} {
                        append result ", "
                    }
                    append result "$item"
                    set first 0
                }
                append result "\]\n"
            } else {
                # Simple value
                append result "${spaces}${key}: $value\n"
            }
        }
    }
    
    return $result
}

# Starte das Programm wenn diese Datei direkt ausgeführt wird
if {[info script] eq $argv0} {
    main
}
