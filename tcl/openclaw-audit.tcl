#!/usr/bin/env tclsh8.6
# openclaw-audit.sh — portiert nach tcl
# Quelle: shell, OpenClaw@gateway1:scripts/openclaw-audit.sh
# auch in: OpenClaw@gateway2:scripts/openclaw-audit.sh
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

# OpenClaw read-only audit/diagnostic sweep
# Output: openclaw-audit-YYYY-MM-DD.log im selben Verzeichnis wie dieses Script

package require Tcl 8.6

# Get script directory
set script_dir [file normalize [file dirname [info script]]]

# Get date stamp
set date_stamp [clock format [clock seconds] -format "%Y-%m-%d"]

# Set output file
set out [file join $script_dir "openclaw-audit-${date_stamp}.log"]

# OpenClaw command array
set oc [list openclaw --no-color]

# Function to get ISO 8601 formatted timestamp
proc get_iso_timestamp {} {
    return [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%S%z"]
}

# Function to get OpenClaw version
proc get_openclaw_version {} {
    if {[catch {exec openclaw --version} version]} {
        return "unknown"
    }
    return [string trim $version]
}

# Open output file for writing
set fd [open $out w]

# Write header information
puts $fd "================================================================"
puts $fd "OpenClaw audit run"
puts $fd "Started:  [get_iso_timestamp]"
puts $fd "Host:     [exec hostname]"
puts $fd "User:     [exec whoami]"
puts $fd "Version:  [get_openclaw_version]"
puts $fd "Output:   $out"
puts $fd "================================================================"

# Close file descriptor
close $fd

# Function to run command and append output to log
proc run_cmd {title args} {
    global out oc
    
    # Open file for appending
    set fd [open $out a]
    
    puts $fd ""
    puts $fd "----------------------------------------------------------------"
    puts $fd "### $title"
    puts $fd "### \$ [join $args " "]"
    puts $fd "### [get_iso_timestamp]"
    puts $fd "----------------------------------------------------------------"
    
    # Execute command and capture output
    if {[catch {exec {*}$args} output]} {
        puts $fd $output
        set rc 1
    } else {
        puts $fd $output
        set rc 0
    }
    
    puts $fd "\[exit: $rc\]"
    
    # Close file descriptor
    close $fd
}

# Run all audit commands
run_cmd "tasks audit --severity error" {*}$oc tasks audit --severity error
run_cmd "secrets audit" {*}$oc secrets audit
run_cmd "security audit" {*}$oc security audit
run_cmd "plugins doctor" {*}$oc plugins doctor
run_cmd "plugins deps" {*}$oc plugins deps
run_cmd "plugins registry" {*}$oc plugins registry
run_cmd "skills check" {*}$oc skills check
run_cmd "hooks check" {*}$oc hooks check
run_cmd "gateway status --deep" {*}$oc gateway status --deep
run_cmd "channels status --probe" {*}$oc channels status --probe
run_cmd "memory status --deep" {*}$oc memory status --deep
run_cmd "sessions --all-agents" {*}$oc sessions --all-agents
run_cmd "tasks list" {*}$oc tasks list
run_cmd "cron list" {*}$oc cron list

# Open file for appending final section
set fd [open $out a]

puts $fd ""
puts $fd "================================================================"
puts $fd "Audit complete: [get_iso_timestamp]"
puts $fd "================================================================"

# Close file descriptor
close $fd

# Print completion message
puts "Audit complete. Output: $out"
