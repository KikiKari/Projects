#!/usr/bin/env tclsh
# json_schema_validator.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:skills/json-utils/scripts/json_schema_validator.py
# auch in: OpenClaw@gateway2:skills/json-utils/scripts/json_schema_validator.py
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

# JSON Schema Validator - Validiert JSON gegen JSON Schema Draft 7/2020-12.
# Erweitert Pydantic mit externen Schema-Dateien.

package require json
package require json::write

# Globale Variablen für Abhängigkeiten
set HAS_JSONSCHEMA 0

# Einfache JSON Schema Validierung ohne externe Bibliotheken
proc validate_instance {instance schema} {
    # Vereinfachte Implementierung - nur grundlegende Typen
    set instance_type [get_json_type $instance]
    set schema_type [dict get $schema type]
    
    if {$instance_type ne $schema_type} {
        error "Type mismatch: expected $schema_type, got $instance_type"
    }
    
    switch $schema_type {
        "object" {
            if {[dict exists $schema properties]} {
                set properties [dict get $schema properties]
                dict for {key value} $instance {
                    if {[dict exists $properties $key]} {
                        set prop_schema [dict get $properties $key]
                        if {![catch {validate_instance $value $prop_schema}]} {
                            continue
                        } else {
                            error "Property '$key': $_"
                        }
                    }
                }
            }
            if {[dict exists $schema required]} {
                set required [dict get $schema required]
                foreach req $required {
                    if {![dict exists $instance $req]} {
                        error "Required property '$req' missing"
                    }
                }
            }
        }
        "array" {
            if {[dict exists $schema items]} {
                set item_schema [dict get $schema items]
                foreach item $instance {
                    validate_instance $item $item_schema
                }
            }
        }
        "string" {
            if {[dict exists $schema enum]} {
                set enum_values [dict get $schema enum]
                if {$instance ni $enum_values} {
                    error "Value '$instance' not in enum [join $enum_values {, }]"
                }
            }
            if {[dict exists $schema pattern]} {
                set pattern [dict get $schema pattern]
                if {![regexp $pattern $instance]} {
                    error "Value '$instance' does not match pattern '$pattern'"
                }
            }
            if {[dict exists $schema minLength]} {
                set min_len [dict get $schema minLength]
                if {[string length $instance] < $min_len} {
                    error "String too short: minimum $min_len characters"
                }
            }
        }
        "integer" {
            if {![string is integer $instance]} {
                error "Not an integer: $instance"
            }
            if {[dict exists $schema minimum]} {
                set min_val [dict get $schema minimum]
                if {$instance < $min_val} {
                    error "Value too small: minimum $min_val"
                }
            }
            if {[dict exists $schema maximum]} {
                set max_val [dict get $schema maximum]
                if {$instance > $max_val} {
                    error "Value too large: maximum $max_val"
                }
            }
        }
    }
}

proc get_json_type {data} {
    if {[dict size $data] > 0 && [string index $data 0] eq "\{"} {
        return "object"
    } elseif {[llength $data] > 1 && [string index $data 0] eq "\["} {
        return "array"
    } elseif {[string is integer $data]} {
        return "integer"
    } elseif {[string is double $data]} {
        return "number"
    } elseif {$data eq "true" || $data eq "false"} {
        return "boolean"
    } elseif {$data eq "null"} {
        return "null"
    } else {
        return "string"
    }
}

proc load_schema {schema_source} {
    # Prüfe ob es ein Dictionary ist
    if {[string index $schema_source 0] eq "\{"} {
        if {[catch {::json::json2dict $schema_source} result]} {
            error "Invalid JSON in schema: $result"
        }
        return $result
    }
    
    # Prüfe ob es eine Datei ist
    if {[file exists $schema_source]} {
        if {[catch {read_file $schema_source} content]} {
            error "Cannot read schema file: $content"
        }
        if {[catch {::json::json2dict $content} result]} {
            error "Invalid JSON in schema file: $result"
        }
        return $result
    }
    
    # Versuche als JSON String zu parsen
    if {[catch {::json::json2dict $schema_source} result]} {
        error "Schema not found or invalid: $schema_source"
    }
    return $result
}

proc validate_with_jsonschema {data schema draft} {
    global HAS_JSONSCHEMA
    
    if {!$HAS_JSONSCHEMA} {
        error "jsonschema not installed"
    }
    
    if {[catch {load_schema $schema} schema_dict]} {
        error $schema_dict
    }
    
    if {[catch {validate_instance $data $schema_dict} result]} {
        error "Schema validation failed: $result"
    }
    
    return 1
}

proc parse_json {raw_input repair} {
    # Einfaches JSON Parsen
    if {[catch {::json::json2dict $raw_input} result]} {
        if {$repair} {
            # Versuche einfache Reparaturen
            set repaired [string map {"'" "\"" "\"" "\\\""} $raw_input]
            if {[catch {::json::json2dict $repaired} result]} {
                error "Cannot parse JSON: $result"
            }
            return $result
        } else {
            error "Cannot parse JSON: $result"
        }
    }
    return $result
}

proc validate_and_convert {raw_input schema repair} {
    if {[catch {parse_json $raw_input $repair} data]} {
        error $data
    }
    
    if {[catch {validate_with_jsonschema $data $schema "auto"} result]} {
        error $result
    }
    
    return $data
}

proc read_file {filename} {
    if {[catch {open $filename r} fh]} {
        error "Cannot open file $filename: $fh"
    }
    set content [read $fh]
    close $fh
    return $content
}

proc write_file {filename content} {
    if {[catch {open $filename w} fh]} {
        error "Cannot write file $filename: $fh"
    }
    puts $fh $content
    close $fh
}

proc SchemaBuilder_object {properties required} {
    set schema [dict create type object properties $properties]
    if {$required ne ""} {
        dict set schema required $required
    }
    return $schema
}

proc SchemaBuilder_string {{enum ""} {pattern ""} {min_length ""}} {
    set schema [dict create type string]
    if {$enum ne ""} {
        dict set schema enum $enum
    }
    if {$pattern ne ""} {
        dict set schema pattern $pattern
    }
    if {$min_length ne "" && $min_length ne "none"} {
        dict set schema minLength $min_length
    }
    return $schema
}

proc SchemaBuilder_integer {{minimum ""} {maximum ""}} {
    set schema [dict create type integer]
    if {$minimum ne "" && $minimum ne "none"} {
        dict set schema minimum $minimum
    }
    if {$maximum ne "" && $maximum ne "none"} {
        dict set schema maximum $maximum
    }
    return $schema
}

proc SchemaBuilder_array {items min_items} {
    set schema [dict create type array items $items]
    if {$min_items ne "" && $min_items ne "none"} {
        dict set schema minItems $min_items
    }
    return $schema
}

proc main {} {
    global argv argc
    
    set input ""
    set schema ""
    set is_file 0
    set repair 1
    
    # Einfacher Argparser
    set i 0
    while {$i < $argc} {
        set arg [lindex $argv $i]
        incr i
        
        switch $arg {
            "--schema" -
            "-s" {
                set schema [lindex $argv $i]
                incr i
            }
            "--file" -
            "-f" {
                set is_file 1
            }
            "--repair" -
            "-r" {
                set repair 1
            }
            default {
                if {$input eq ""} {
                    set input $arg
                }
            }
        }
    }
    
    if {$input eq ""} {
        puts stderr "No input provided"
        exit 1
    }
    
    if {$schema eq ""} {
        puts stderr "Schema required (--schema)"
        exit 1
    }
    
    # Lade Input (Auto-detect file vs string)
    set raw_input ""
    if {$is_file || ([file exists $input] && [file isfile $input])} {
        if {[catch {read_file $input} raw_input]} {
            puts stderr "Cannot read input file: $raw_input"
            exit 1
        }
    } else {
        set raw_input $input
    }
    
    if {[catch {validate_and_convert $raw_input $schema $repair} result]} {
        puts stderr "✗ Validation failed: $result"
        exit 1
    } else {
        puts [::json::write::write $result]
        puts stderr "\n✓ Validation passed"
    }
}

# Starte Hauptprogramm wenn direkt aufgerufen
if {[info script] eq $argv0} {
    main
}
