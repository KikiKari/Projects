#!/usr/bin/env tclsh
# abstraction-provenance: {"artifact_sha256": "44a3f8a9432322ce66b6fc0b60ffd6ad7a6d7a0246a7d15d95d41b84e5720341", "source_sha256": "eb21431dabeaafc82a1e3ccf24278616e46ed082eca1de4d328c758ee82ee2c7", "target_language": "tcl"}
# language_validator.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:skills/scripting-utils/scripts/language_validator.py
# auch in: OpenClaw@gateway2:skills/scripting-utils/scripts/language_validator.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# Multi-language script validator supporting 8+ languages.
# WebSearch integration for documentation lookup.

package require Tcl 8.6

# Define global variables for language configurations
array set LANGUAGES {
    bash {cmd bash args {-n} linter shellcheck}
    sh {cmd sh args {-n} linter shellcheck}
    python {cmd python3 args {-m py_compile} linter pylint}
    perl {cmd perl args {-c} linter perlcritic}
    raku {cmd raku args {-c} linter {}}
    powershell {cmd pwsh args {-Command Get-Command} linter {}}
    javascript {cmd node args {--check} linter eslint}
    tcl {cmd tclsh args {} linter {}}
}

# ValidationResult structure
proc create_validation_result {language valid errors warnings {doc_url ""}} {
    return [list \
        language $language \
        valid $valid \
        errors $errors \
        warnings $warnings \
        doc_url $doc_url]
}

# LanguageValidator class
oo::class create LanguageValidator {
    variable language config use_websearch
    
    constructor {lang websearch} {
        set language [string tolower $lang]
        set use_websearch $websearch
        
        if {![info exists ::LANGUAGES($language)]} {
            error "Unsupported language: $lang"
        }
        set config $::LANGUAGES($language)
    }
    
    method validate {script_path} {
        set errors {}
        set warnings {}
        
        # Syntax check
        set cmd [dict get $config cmd]
        set args [dict get $config args]
        set full_cmd [concat [list $cmd] $args [list $script_path]]
        
        if {[catch {exec {*}$full_cmd} output]} {
            lappend errors $output
        }
        
        # Linter check if available
        set linter [dict get $config linter]
        if {$linter ne ""} {
            set linter_warnings [my _run_linter $script_path $linter]
            lappend warnings {*}$linter_warnings
        }
        
        set valid [expr {[llength $errors] == 0}]
        set doc_url ""
        if {!$valid && $use_websearch} {
            set doc_url [my _fetch_docs]
        }
        
        return [create_validation_result $language $valid $errors $warnings $doc_url]
    }
    
    method _run_linter {script_path linter} {
        set warnings {}
        
        if {[catch {exec which $linter}]} {
            lappend warnings "Linter not installed: $linter"
            return $warnings
        }
        
        set result ""
        if {$linter eq "shellcheck"} {
            if {![catch {exec shellcheck -f gcc $script_path} result]} {
                if {$result ne ""} {
                    set warnings [split $result "\n"]
                }
            }
        } elseif {$linter eq "pylint"} {
            if {![catch {exec pylint --output-format=parseable $script_path} result]} {
                if {$result ne ""} {
                    set warnings [split $result "\n"]
                }
            }
        }
        
        return $warnings
    }
    
    method _fetch_docs {} {
        if {!$use_websearch} {
            return ""
        }
        
        # Return known good documentation URLs
        array set docs {
            powershell "https://docs.microsoft.com/powershell/"
            raku "https://docs.raku.org/"
            tcl "https://www.tcl.tk/"
        }
        
        if {[info exists docs($language)]} {
            return $docs($language)
        }
        return ""
    }
}

# Helper procedure to parse command line arguments
proc parse_args {} {
    global argc argv
    
    set options [dict create]
    set script ""
    set lang ""
    set no_websearch false
    
    for {set i 0} {$i < $argc} {incr i} {
        set arg [lindex $argv $i]
        switch -exact -- $arg {
            --lang {
                incr i
                set lang [lindex $argv $i]
            }
            --no-websearch {
                set no_websearch true
            }
            default {
                if {$script eq ""} {
                    set script $arg
                }
            }
        }
    }
    
    if {$script eq "" || $lang eq ""} {
        puts stderr "Usage: $::argv0 <script> --lang <language> \[options\]"
        puts stderr "Options:"
        puts stderr "  --no-websearch    Disable WebSearch"
        exit 1
    }
    
    dict set options script $script
    dict set options lang $lang
    dict set options no_websearch $no_websearch
    
    return $options
}

# Main procedure
proc main {} {
    set args [parse_args]
    set script_path [dict get $args script]
    set lang [dict get $args lang]
    set no_websearch [dict get $args no_websearch]
    
    set validator [LanguageValidator new $lang [expr {!$no_websearch}]]
    
    if {[catch {set result [$validator validate $script_path]} error]} {
        puts stderr "Error: $error"
        exit 1
    }
    
    set language [dict get $result language]
    set valid [dict get $result valid]
    set errors [dict get $result errors]
    set warnings [dict get $result warnings]
    set doc_url [dict get $result doc_url]
    
    puts "Language: $language"
    puts "Valid: $valid"
    
    if {[llength $errors] > 0} {
        puts "Errors: [llength $errors]"
        set count 0
        foreach err $errors {
            if {$count >= 5} break
            puts "  - $err"
            incr count
        }
    }
    
    if {[llength $warnings] > 0} {
        puts "Warnings: [llength $warnings]"
        set count 0
        foreach warn $warnings {
            if {$count >= 5} break
            puts "  - $warn"
            incr count
        }
    }
    
    if {$doc_url ne ""} {
        puts "Docs: $doc_url"
    }
    
    exit [expr {!$valid}]
}

# Run main if script is executed directly
if {[info script] eq $::argv0} {
    main
}
