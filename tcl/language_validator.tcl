#!/usr/bin/env tclsh
# language_validator.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:skills/scripting-utils/scripts/language_validator.py
# auch in: OpenClaw@gateway2:skills/scripting-utils/scripts/language_validator.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

# Multi-language script validator supporting 8+ languages.
# WebSearch integration for documentation lookup.

package require Tcl 8.6

# ValidationResult class equivalent
proc create_validation_result {language valid errors warnings {doc_url ""}} {
    return [list \
        language $language \
        valid $valid \
        errors $errors \
        warnings $warnings \
        doc_url $doc_url]
}

# LanguageValidator class equivalent
namespace eval LanguageValidator {
    variable LANGUAGES
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
}

proc LanguageValidator.new {language use_websearch} {
    set lang [string tolower $language]
    if {![info exists ::LanguageValidator::LANGUAGES($lang)]} {
        error "Unsupported language: $language"
    }
    
    set config $::LanguageValidator::LANGUAGES($lang)
    return [list \
        language $lang \
        use_websearch $use_websearch \
        config $config]
}

proc LanguageValidator.validate {validator script_path} {
    upvar $validator v
    
    set errors [list]
    set warnings [list]
    
    # Syntax check
    set cmd [dict get $v(config) cmd]
    set args [dict get $v(config) args]
    
    if {[catch {
        set result [exec {*}[list $cmd] {*}$args $script_path]
    } error]} {
        if {[string match "*timeout*" $error]} {
            lappend errors "Validation timeout"
        } else {
            lappend errors $error
        }
    }
    
    # Linter check if available
    set linter [dict get $v(config) linter]
    if {$linter ne ""} {
        set linter_warnings [LanguageValidator._run_linter $v(config) $script_path]
        set warnings [concat $warnings $linter_warnings]
    }
    
    # If command not found and websearch enabled, fetch docs
    if {[llength $errors] > 0 && $v(use_websearch)} {
        set doc_url [LanguageValidator._fetch_docs $v(language)]
        return [create_validation_result $v(language) false $errors $warnings $doc_url]
    }
    
    return [create_validation_result $v(language) [expr {[llength $errors] == 0}] $errors $warnings]
}

proc LanguageValidator._run_linter {config script_path} {
    set linter [dict get $config linter]
    set warnings [list]
    
    if {[catch {
        switch $linter {
            shellcheck {
                set result [exec shellcheck -f gcc $script_path]
                if {$result ne ""} {
                    set warnings [split $result "\n"]
                }
            }
            pylint {
                set result [exec pylint --output-format=parseable $script_path]
                if {$result ne ""} {
                    set warnings [split $result "\n"]
                }
            }
        }
    } error]} {
        lappend warnings "Linter not installed: $linter"
    }
    
    return $warnings
}

proc LanguageValidator._fetch_docs {language} {
    # Return known good documentation URLs
    set docs [dict create \
        powershell "https://docs.microsoft.com/powershell/" \
        raku "https://docs.raku.org/" \
        tcl "https://www.tcl.tk/"]
    
    if {[dict exists $docs $language]} {
        return [dict get $docs $language]
    }
    return ""
}

proc main {argv} {
    # Simple argument parsing
    set script ""
    set lang ""
    set use_websearch 1
    
    for {set i 0} {$i < [llength $argv]} {incr i} {
        set arg [lindex $argv $i]
        switch $arg {
            --lang {
                incr i
                set lang [lindex $argv $i]
            }
            --no-websearch {
                set use_websearch 0
            }
            default {
                if {$script eq ""} {
                    set script $arg
                }
            }
        }
    }
    
    if {$script eq "" || $lang eq ""} {
        puts stderr "Usage: $::argv0 <script> --lang <language> \[--no-websearch\]"
        exit 1
    }
    
    if {![file exists $script]} {
        puts stderr "Script file not found: $script"
        exit 1
    }
    
    set validator [LanguageValidator.new $lang [expr {$use_websearch}]]
    set result [LanguageValidator.validate $validator $script]
    
    puts "Language: [dict get $result language]"
    puts "Valid: [dict get $result valid]"
    
    set errors [dict get $result errors]
    if {[llength $errors] > 0} {
        puts "Errors: [llength $errors]"
        set count 0
        foreach err $errors {
            if {$count >= 5} break
            puts "  - $err"
            incr count
        }
    }
    
    set warnings [dict get $result warnings]
    if {[llength $warnings] > 0} {
        puts "Warnings: [llength $warnings]"
        set count 0
        foreach warn $warnings {
            if {$count >= 5} break
            puts "  - $warn"
            incr count
        }
    }
    
    set doc_url [dict get $result doc_url]
    if {$doc_url ne ""} {
        puts "Docs: $doc_url"
    }
    
    if {[dict get $result valid]} {
        exit 0
    } else {
        exit 1
    }
}

# Entry point
if {$::argv0 eq [info script]} {
    main $::argv
}
