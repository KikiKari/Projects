#!/usr/bin/env tclsh8.6
# test_quick_validate.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:skills/skill-creator/scripts/test_quick_validate.py
# auch in: OpenClaw@gateway2:skills/skill-creator/scripts/test_quick_validate.py
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

# Regression tests for quick skill validation.

package require Tcl 8.6
package require tempfile
package require fileutil

namespace eval TestQuickValidate {
    variable temp_dir

    proc setUp {} {
        variable temp_dir
        set temp_dir [tempfile::mktemp -p "/tmp" "test_quick_validate_XXXXXX"]
        file mkdir $temp_dir
    }

    proc tearDown {} {
        variable temp_dir
        if {[file exists $temp_dir]} {
            file delete -force $temp_dir
        }
    }

    proc test_accepts_crlf_frontmatter {} {
        variable temp_dir
        set skill_dir [file join $temp_dir "crlf-skill"]
        file mkdir $skill_dir
        set content "---\r\nname: crlf-skill\r\ndescription: ok\r\n---\r\n# Skill\r\n"
        set fd [open [file join $skill_dir "SKILL.md"] w]
        fconfigure $fd -encoding utf-8
        puts -nonewline $fd $content
        close $fd

        lassign [quick_validate::validate_skill $skill_dir] valid message

        if { !$valid } {
            error "Expected valid skill, but got invalid: $message"
        }
    }

    proc test_rejects_missing_frontmatter_closing_fence {} {
        variable temp_dir
        set skill_dir [file join $temp_dir "bad-skill"]
        file mkdir $skill_dir
        set content "---\nname: bad-skill\ndescription: missing end\n# no closing fence\n"
        set fd [open [file join $skill_dir "SKILL.md"] w]
        puts -nonewline $fd $content
        close $fd

        lassign [quick_validate::validate_skill $skill_dir] valid message

        if { $valid } {
            error "Expected invalid skill due to missing closing fence"
        }
        if { $message ne "Invalid frontmatter format" } {
            error "Expected 'Invalid frontmatter format' message, but got: $message"
        }
    }

    proc test_fallback_parser_handles_multiline_frontmatter_without_pyyaml {} {
        variable temp_dir
        set skill_dir [file join $temp_dir "multiline-skill"]
        file mkdir $skill_dir
        set content "---\nname: multiline-skill\ndescription: Works without pyyaml\nallowed-tools:\n  - gh\nmetadata: |\n  {\n    \"owners\": \[\"team-openclaw\"\]\n  }\n---\n# Skill\n"
        set fd [open [file join $skill_dir "SKILL.md"] w]
        puts -nonewline $fd $content
        close $fd

        # Save original yaml state and disable it
        set previous_yaml [set ::quick_validate::yaml]
        set ::quick_validate::yaml ""

        set result [catch {
            set valid_message [quick_validate::validate_skill $skill_dir]
        } err]

        # Restore original yaml state
        set ::quick_validate::yaml $previous_yaml

        if { $result } {
            error "Unexpected error during validation: $err"
        }

        lassign $valid_message valid message
        if { !$valid } {
            error "Expected valid skill with fallback parser, but got invalid: $message"
        }
    }

    proc run_tests {} {
        setUp
        set failed 0

        foreach test_proc [info procs test_*] {
            if {[catch {$test_proc} error]} {
                puts "FAIL: $test_proc - $error"
                incr failed
            } else {
                puts "PASS: $test_proc"
            }
        }

        tearDown
        
        if {$failed > 0} {
            error "$failed test(s) failed"
        }
    }
}

# Load quick_validate module
source [file join [file dirname [info script]] "quick_validate.tcl"]

# Run tests
TestQuickValidate::run_tests
