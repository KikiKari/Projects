#!/usr/bin/env tclsh
# json_batch_processor.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:skills/json-utils/scripts/json_batch_processor.py
# auch in: OpenClaw@gateway2:skills/json-utils/scripts/json_batch_processor.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

# Tcl 8.6 Port von json_batch_processor.py
# Batch JSON Processor - Verarbeitet mehrere JSON-Dateien oder JSON-Lines (NDJSON)

package require Tcl 8.6
package require json
package require cmdline

# Globale Variablen
set HAS_PYDANTIC 0
set JSON_PROCESSOR_LOADED 0

# Versuche json_processor.tcl zu laden
if {[catch {source json_processor.tcl}]} {
    puts stderr "Fehler: json_processor.tcl nicht gefunden"
    exit 1
} else {
    set JSON_PROCESSOR_LOADED 1
}

# BatchResult Klasse (als dict implementiert)
proc create_batch_result {index source success {data {}} {error {}}} {
    return [dict create \
        index $index \
        source $source \
        success $success \
        data $data \
        error $error]
}

proc batch_result_to_dict {result} {
    return $result
}

# Liest JSON-Lines (NDJSON) Datei Zeile für Zeile
proc read_jsonl {file_path} {
    set results {}
    if {[catch {open $file_path r} f]} {
        lappend results [create_batch_result 0 $file_path 0 {} "Cannot open file: $f"]
        return $results
    }
    
    set line_num 0
    while {[gets $f line] >= 0} {
        incr line_num
        set line [string trim $line]
        if {$line eq ""} continue
        
        if {[catch {::json::json2dict $line} parsed]} {
            lappend results [create_batch_result $line_num "$file_path:$line_num" 0 {} "JSON decode error: $parsed"]
        } else {
            lappend results $parsed
        }
    }
    close $f
    return $results
}

# Verarbeitet eine Liste von Inputs parallel (sequentiell in Tcl)
proc process_batch {inputs processor max_workers} {
    set results {}
    set idx 0
    
    foreach inp $inputs {
        if {[catch {eval $processor [list $inp $idx]} result]} {
            lappend results [create_batch_result $idx $inp 0 {} "Unexpected error: $result"]
        } else {
            lappend results $result
        }
        incr idx
    }
    
    # Sortiere nach Index
    set sorted_results {}
    foreach result [lsort -integer -index 0 [lmap r $results {list [dict get $r index] $r}]] {
        lappend sorted_results [lindex $result 1]
    }
    return $sorted_results
}

# Verarbeitet mehrere JSON-Dateien im Batch
proc process_file_batch {file_paths repair validate_model max_workers} {
    proc file_processor {path idx} {
        upvar repair repair
        upvar validate_model validate_model
        
        if {[catch {read_file_content $path} content]} {
            return [create_batch_result $idx $path 0 {} "Cannot read file: $content"]
        }
        
        if {$validate_model ne "" && $::HAS_PYDANTIC} {
            # In Tcl gibt es kein direktes Äquivalent zu Pydantic
            # Wir verwenden einfach die normale JSON-Verarbeitung
            if {[catch {parse_json $content $repair} data]} {
                return [create_batch_result $idx $path 0 {} [get_json_error $data]]
            }
        } else {
            if {[catch {parse_json $content $repair} data]} {
                return [create_batch_result $idx $path 0 {} [get_json_error $data]]
            }
        }
        
        return [create_batch_result $idx $path 1 $data]
    }
    
    return [process_batch $file_paths file_processor $max_workers]
}

# Verarbeitet eine JSON-Lines Datei
proc process_jsonl_file {file_path repair validate_model} {
    set results {}
    if {[catch {open $file_path r} f]} {
        lappend results [create_batch_result 0 $file_path 0 {} "Cannot open file: $f"]
        return $results
    }
    
    set line_num 0
    while {[gets $f line] >= 0} {
        incr line_num
        set line [string trim $line]
        if {$line eq ""} continue
        
        if {$validate_model ne "" && $::HAS_PYDANTIC} {
            # In Tcl gibt es kein direktes Äquivalent zu Pydantic
            if {[catch {parse_json $line $repair} data]} {
                lappend results [create_batch_result $line_num "$file_path:$line_num" 0 {} [get_json_error $data]]
            } else {
                lappend results [create_batch_result $line_num "$file_path:$line_num" 1 $data]
            }
        } else {
            if {[catch {parse_json $line $repair} data]} {
                lappend results [create_batch_result $line_num "$file_path:$line_num" 0 {} [get_json_error $data]]
            } else {
                lappend results [create_batch_result $line_num "$file_path:$line_num" 1 $data]
            }
        }
    }
    close $f
    return $results
}

# Hilfsfunktion zum Lesen von Dateiinhalten
proc read_file_content {path} {
    if {[catch {open $path r} f]} {
        error "Cannot open file: $f"
    }
    set content [read $f]
    close $f
    return $content
}

# Hilfsfunktion zum Extrahieren von JSON-Fehlermeldungen
proc get_json_error {error_msg} {
    return $error_msg
}

# Schreibt BatchResult-Liste als JSON-Lines
proc write_jsonl {results output_path only_successful} {
    if {[catch {open $output_path w} f]} {
        error "Cannot write to file: $f"
    }
    
    foreach result $results {
        if {$only_successful && ![dict get $result success]} {
            continue
        }
        puts $f [::json::dict2json $result]
    }
    close $f
}

# Hauptfunktion
proc main {argv} {
    # Standardargumente
    set jsonl_mode 0
    set repair 1
    set workers 4
    set output ""
    set summary 0
    set inputs {}
    
    # Argumente parsen
    set argdef {
        {jsonl.l "Treat inputs as JSON-Lines files"}
        {repair.r "Enable JSON repair"}
        {workers.w.arg "4" "Parallel workers"}
        {output.o.arg "" "Output JSON-Lines file"}
        {summary.s "Show summary only"}
        {inputs.arg "" "JSON files to process"}
    }
    
    if {[catch {cmdline::typedGetoptions argv $argdef} options]} {
        puts stderr "Fehler beim Parsen der Argumente: $options"
        exit 1
    }
    
    # Werte aus den Optionen extrahieren
    foreach {key value} $options {
        switch $key {
            jsonl { set jsonl_mode $value }
            repair { set repair $value }
            workers { set workers $value }
            output { set output $value }
            summary { set summary $value }
            inputs { set inputs $value }
        }
    }
    
    # Wenn keine Inputs angegeben wurden, verbleibende argv verwenden
    if {$inputs eq ""} {
        set inputs $argv
    } elseif {$argv ne ""} {
        # Kombiniere beide
        set inputs [concat $inputs $argv]
    }
    
    # Prüfen ob Inputs vorhanden sind
    if {[llength $inputs] == 0} {
        puts stderr "Keine Eingabedateien angegeben"
        exit 1
    }
    
    set all_results {}
    
    if {$jsonl_mode} {
        # JSON-Lines Modus
        foreach input_path $inputs {
            set results [process_jsonl_file $input_path $repair ""]
            set all_results [concat $all_results $results]
        }
    } else {
        # Standard JSON Batch
        set all_results [process_file_batch $inputs $repair "" $workers]
    }
    
    # Ausgabe
    set successful 0
    set failed 0
    
    foreach result $all_results {
        if {[dict get $result success]} {
            incr successful
        } else {
            incr failed
        }
    }
    
    if {$summary} {
        puts "Processed: [llength $all_results]"
        puts "Successful: $successful"
        puts "Failed: $failed"
    } else {
        foreach result $all_results {
            if {[dict get $result success]} {
                puts [::json::dict2json [dict get $result data]]
            } else {
                puts stderr "ERROR \[[dict get $result source]\]: [dict get $result error]"
            }
        }
    }
    
    # Optional: JSONL Output
    if {$output ne ""} {
        if {[catch {write_jsonl $all_results $output 0} write_error]} {
            puts stderr "Fehler beim Schreiben der Ausgabedatei: $write_error"
        } else {
            puts stderr "\nResults written to: $output"
        }
    }
    
    # Exit code
    if {$failed > 0} {
        exit 1
    } else {
        exit 0
    }
}

# Hilfsfunktion zum Konvertieren von dict zu JSON (vereinfacht)
proc dict_to_json {d} {
    set json "{"
    set first 1
    dict for {key value} $d {
        if {!$first} {
            append json ","
        }
        append json "\"$key\":"
        if {[string is double $value] || [string is integer $value]} {
            append json "$value"
        } elseif {$value eq "true" || $value eq "false" || $value eq "null"} {
            append json "$value"
        } else {
            append json "\"[string map {\" \\\"} $value]\""
        }
        set first 0
    }
    append json "}"
    return $json
}

# Programmstart
if {[info script] eq $argv0} {
    main $argv
}
