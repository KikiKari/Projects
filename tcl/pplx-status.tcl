#!/usr/bin/env tclsh8.6
# pplx-status.sh — portiert nach tcl
# Quelle: shell, OpenClaw@main:scripts/pplx-tools/pplx-status.sh
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

# Quick status of the codespace Perplexity daemon session.

package require json

# Get config directory and profile
set CFG [expr {[info exists ::env(PERPLEXITY_CONFIG_DIR)] ? $::env(PERPLEXITY_CONFIG_DIR) : "$::env(HOME)/.perplexity-mcp"}]
set PROFILE [expr {[info exists ::env(PERPLEXITY_PROFILE)] ? $::env(PERPLEXITY_PROFILE) : "codespace"}]
set STAT "$CFG/profiles/$PROFILE/daemon-status.json"

# Check if status file exists and display it
if {[file exists $STAT]} {
    set fp [open $STAT r]
    set content [read $fp]
    close $fp
    puts [::json::json2dict $content]
} else {
    puts "no daemon-status.json at $STAT"
}

puts "--- recent auth lines ---"

# Read log file and show recent authentication lines
set LOGFILE "$CFG/daemon.log"
if {[file exists $LOGFILE]} {
    set fp [open $LOGFILE r]
    set lines [split [read $fp] "\n"]
    close $fp
    
    # Filter lines matching the patterns
    set filtered_lines {}
    foreach line $lines {
        if {[regexp -nocase {(Authenticated as user|Account tier|Injected .* cookies|Reinit requested|not-logged-in)} $line]} {
            lappend filtered_lines $line
        }
    }
    
    # Show last 6 lines
    set start_idx [expr {[llength $filtered_lines] - 6}]
    if {$start_idx < 0} { set start_idx 0 }
    
    for {set i $start_idx} {$i < [llength $filtered_lines]} {incr i} {
        puts [lindex $filtered_lines $i]
    }
}
