#!/usr/bin/env tclsh8.6
# validate_tool_output.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:skills/json-utils/scripts/validate_tool_output.py
# auch in: OpenClaw@gateway2:skills/json-utils/scripts/validate_tool_output.py
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

# Validiert Tool-Outputs gegen ein JSON-Schema.
# Für OpenClaw Tool-Call-Validierung.

package require json
package require cmdline

# Globale Variablen für das Schema und Model
set schema_dict [dict create]
set model_fields [dict create]

# Hilfsfunktion zur Typkonvertierung
proc get_tcl_type {json_type} {
    switch $json_type {
        "integer" { return "integer" }
        "number" { return "double" }
        "boolean" { return "boolean" }
        "array" { return "list" }
        "object" { return "dict" }
        default { return "string" }
    }
}

# Erstellt ein dynamisches Validierungsmodell aus einem JSON-Schema
proc create_dynamic_model {schema} {
    global model_fields
    
    set model_fields [dict create]
    set properties [dict get $schema properties]
    
    dict for {field_name field_info} $properties {
        set field_type "string"
        set default_val ""
        set is_required 0
        set description ""
        
        if {[dict exists $field_info type]} {
            set json_type [dict get $field_info type]
            set field_type [get_tcl_type $json_type]
        }
        
        if {[dict exists $field_info description]} {
            set description [dict get $field_info description]
        }
        
        set required_fields {}
        if {[dict exists $schema required]} {
            set required_fields [dict get $schema required]
        }
        
        if {$field_name in $required_fields} {
            set is_required 1
        } else {
            if {[dict exists $field_info default]} {
                set default_val [dict get $field_info default]
            }
        }
        
        dict set model_fields $field_name [list \
            type $field_type \
            required $is_required \
            default $default_val \
            description $description]
    }
    
    return "DynamicToolOutput"
}

# Validiert Daten gegen das dynamische Modell
proc validate_data {data model_name} {
    global model_fields
    set result [dict create]
    set errors [list]
    
    # Wenn data ein JSON-String ist, parsen
    if {[string index $data 0] eq "\{" || [string index $data 0] eq "\["} {
        if {[catch {::json::json2dict $data} parsed_data]} {
            error "Invalid JSON: $parsed_data"
        }
    } else {
        set parsed_data $data
    }
    
    # Validierung gegen das Modell
    dict for {field_name field_def} $model_fields {
        set field_type [dict get $field_def type]
        set is_required [dict get $field_def required]
        set default_val [dict get $field_def default]
        
        set value ""
        set field_exists [dict exists $parsed_data $field_name]
        
        if {$field_exists} {
            set value [dict get $parsed_data $field_name]
        } elseif {$is_required} {
            lappend errors "Required field '$field_name' is missing"
            continue
        } else {
            set value $default_val
        }
        
        # Typvalidierung
        if {$value ne "" && $value ne $default_val} {
            switch $field_type {
                "integer" {
                    if {![string is integer $value]} {
                        lappend errors "Field '$field_name' must be integer, got '$value'"
                    }
                }
                "double" {
                    if {![string is double $value]} {
                        lappend errors "Field '$field_name' must be number, got '$value'"
                    }
                }
                "boolean" {
                    if {![string is boolean $value]} {
                        lappend errors "Field '$field_name' must be boolean, got '$value'"
                    }
                }
            }
        }
        
        dict set result $field_name $value
    }
    
    if {[llength $errors] > 0} {
        error [join $errors "; "]
    }
    
    return $result
}

# Hauptprogramm
proc main {} {
    global argv argc schema_dict
    
    # Kommandozeilenargumente parsen
    set options {
        {schema.arg "" "JSON schema file"}
        {file "Input is a file"}
        {repair "Repair mode (default true)"}
        {strict "Strict validation"}
        {help "Show help"}
    }
    
    set usage "Usage: $argv0 \[options\] json_input\n"
    append usage "Validate tool output against schema\n\n"
    append usage "Options:\n"
    
    if {[catch {cmdline::getoptions argv $options} opterr]} {
        puts stderr "Error parsing options: $opterr"
        exit 1
    }
    
    if {[info exists opt(help)] || $argc < 1} {
        puts -nonewline stderr $usage
        cmdline::usage $options
        exit 1
    }
    
    set json_input [lindex $argv 0]
    set schema_file [dict get $opt schema]
    set is_file [info exists opt(file)]
    set repair_mode [expr {[info exists opt(repair)] || 1}]
    set strict_mode [info exists opt(strict)]
    
    if {$schema_file eq ""} {
        puts stderr "Error: --schema option is required"
        exit 1
    }
    
    # Lade Schema
    if {[catch {open $schema_file r} schema_fd]} {
        puts stderr "Error loading schema: $schema_fd"
        exit 1
    }
    
    set schema_content [read $schema_fd]
    close $schema_fd
    
    if {[catch {::json::json2dict $schema_content} schema_dict]} {
        puts stderr "Error parsing schema JSON: $schema_dict"
        exit 1
    }
    
    # Lade Input
    set raw_input ""
    if {$is_file} {
        if {[catch {open $json_input r} input_fd]} {
            puts stderr "Error opening input file: $input_fd"
            exit 1
        }
        set raw_input [read $input_fd]
        close $input_fd
    } else {
        set raw_input $json_input
    }
    
    # Erstelle dynamisches Modell und validiere
    if {[catch {
        set model_name [create_dynamic_model $schema_dict]
        set result [validate_data $raw_input $model_name]
        
        # Ergebnis als JSON ausgeben
        puts [::json::dict2json $result]
    } validation_error]} {
        puts stderr "Validation error: $validation_error"
        exit 1
    }
}

# Skriptstart
if {!$tcl_interactive} {
    main
}
