#!/usr/bin/env tclsh8.6
# abstraction-provenance: {"artifact_sha256": "eef3acb4b1d61fcc28b661ff808db6c62c21dc5493732f69b02d3f495235c827", "source_sha256": "40b902ee3739509c4b2ef72ed57b4d983e5b509f6e446d20ab14d630d9773322", "target_language": "tcl"}
# json_batch_processor.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:skills/json-utils/scripts/json_batch_processor.py
# auch in: OpenClaw@gateway2:skills/json-utils/scripts/json_batch_processor.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# Batch JSON Processor - Verarbeitet mehrere JSON-Dateien oder JSON-Lines (NDJSON).

package require Tcl 8.6
package require json
package require cmdline

# Globale Variablen
set HAS_PYDANTIC 0

# Hilfsfunktionen für JSON-Verarbeitung
proc parse_json {content repair} {
    # Vereinfachte JSON-Parsing-Funktion
    if {$repair} {
        # Entferne potenzielle Formatierungsfehler
        regsub -all {\s+} $content " " content
        regsub -all {,\s*}} $content "}" content
        regsub -all {,\s*\]} $content "]" content
    }
    
    if {[catch {::json::json2dict $content} result]} {
        error "JSON decode error: $result"
    }
    return $result
}

proc parse_and_validate {content model repair} {
    # Vereinfachte Validierung ohne Pydantic
    return [parse_json $content $repair]
}

# BatchResult-Klasse ersetzt durch Dictionary
proc create_BatchResult {index source success data error} {
    return [list \
        index $index \
        source $source \
        success $success \
        data $data \
        error $error]
}

proc BatchResult_to_dict {batch_result} {
    return $batch_result
}

# Liest JSON-Lines (NDJSON) Datei Zeile für Zeile
proc read_jsonl {file_path} {
    set results {}
    set fh [open $file_path r]
    set line_num 0
    
    while {[gets $fh line] >= 0} {
        incr line_num
        set line [string trim $line]
        if {$line eq ""} {
            continue
        }
        
        if {[catch {::json::json2dict $line} parsed]} {
            lappend results [create_BatchResult $line_num "$file_path:$line_num" 0 "" "JSON decode error: $parsed"]
        } else {
            lappend results [create_BatchResult $line_num "$file_path:$line_num" 1 $parsed ""]
        }
    }
    
    close $fh
    return $results
}

# Verarbeitet eine Liste von Inputs parallel (sequentiell in Tcl)
proc process_batch {inputs processor max_workers} {
    set results {}
    set idx 0
    
    foreach inp $inputs {
        if {[catch {eval $processor [list $inp $idx]} result]} {
            lappend results [create_BatchResult $idx $inp 0 "" "Unexpected error: $result"]
        } else {
            lappend results $result
        }
        incr idx
    }
    
    # Sortiere nach Index
    set sorted_results {}
    foreach result [lsort -integer -index 0 $results] {
        lappend sorted_results $result
    }
    
    return $sorted_results
}

# Verarbeitet mehrere JSON-Dateien im Batch
proc process_file_batch {file_paths repair validate_model max_workers} {
    proc file_processor {path idx} {
        upvar repair repair_val
        upvar validate_model model_val
        
        if {[catch {set fh [open $path r]} err]} {
            return [create_BatchResult $idx $path 0 "" "Cannot open file: $err"]
        }
        
        if {[catch {read $fh} content]} {
            close $fh
            return [create_BatchResult $idx $path 0 "" "Cannot read file: $content"]
        }
        close $fh
        
        if {[catch {
            if {$model_val ne "" && $::HAS_PYDANTIC} {
                set data [parse_and_validate $content $model_val $repair_val]
            } else {
                set data [parse_json $content $repair_val]
            }
            return [create_BatchResult $idx $path 1 $data ""]
        } result]} {
            return [create_BatchResult $idx $path 0 "" $result]
        }
    }
    
    return [process_batch $file_paths file_processor $max_workers]
}

# Verarbeitet eine JSON-Lines Datei
proc process_jsonl_file {file_path repair validate_model} {
    set results {}
    set fh [open $file_path r]
    set line_num 0
    
    while {[gets $fh line] >= 0} {
        incr line_num
        set line [string trim $line]
        if {$line eq ""} {
            continue
        }
        
        if {[catch {
            if {$validate_model ne "" && $::HAS_PYDANTIC} {
                set data [parse_and_validate $line $validate_model $repair]
            } else {
                set data [parse_json $line $repair]
            }
            return [create_BatchResult $line_num "$file_path:$line_num" 1 $data ""]
        } result]} {
            lappend results [create_BatchResult $line_num "$file_path:$line_num" 0 "" $result]
        } else {
            lappend results $result
        }
    }
    
    close $fh
    return $results
}

# Schreibt BatchResult-Liste als JSON-Lines
proc write_jsonl {results output_path only_successful} {
    set fh [open $output_path w]
    
    foreach result $results {
        array set r $result
        if {$only_successful && !$r(success)} {
            continue
        }
        
        puts $fh [::json::dict2json $result]
    }
    
    close $fh
}

# Hauptfunktion
proc main {} {
    # Kommandozeilenargumente parsen
    set options {
        {"jsonl" "-l" "Treat inputs as JSON-Lines files"}
        {"repair" "-r" "Enable JSON repair" 1}
        {"workers" "-w" "Parallel workers" 4}
        {"output" "-o" "Output JSON-Lines file" ""}
        {"summary" "-s" "Show summary only"}
    }
    
    set usage "Usage: $::argv0 \[options\] inputs...\noptions:"
    array set opts [cmdline::getoptions ::argv $options $usage]
    
    if {[llength $::argv] == 0} {
        puts stderr "Error: No input files specified"
        exit 1
    }
    
    set all_results {}
    
    if {$opts(jsonl)} {
        # JSON-Lines Modus
        foreach input_path $::argv {
            set results [process_jsonl_file $input_path $opts(repair) ""]
            foreach result $results {
                lappend all_results $result
            }
        }
    } else {
        # Standard JSON Batch
        set all_results [process_file_batch $::argv $opts(repair) "" $opts(workers)]
    }
    
    # Statistiken berechnen
    set successful 0
    set failed 0
    
    foreach result $all_results {
        array set r $result
        if {$r(success)} {
            incr successful
        } else {
            incr failed
        }
    }
    
    # Ausgabe
    if {$opts(summary)} {
        puts "Processed: [llength $all_results]"
        puts "Successful: $successful"
        puts "Failed: $failed"
    } else {
        foreach result $all_results {
            array set r $result
            if {$r(success)} {
                puts [::json::dict2json $r(data)]
            } else {
                puts stderr "ERROR \[$r(source)\]: $r(error)"
            }
        }
    }
    
    # Optional: JSONL Output
    if {$opts(output) ne ""} {
        write_jsonl $all_results $opts(output) 0
        puts stderr "\nResults written to: $opts(output)"
    }
    
    # Exit code
    if {$failed == 0} {
        exit 0
    } else {
        exit 1
    }
}

# Programmstart
if {[info script] eq $::argv0} {
    main
}
