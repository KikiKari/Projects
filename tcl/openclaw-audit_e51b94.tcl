#!/usr/bin/env tclsh8.6
# abstraction-provenance: {"artifact_sha256": "3bb6c717445e5fefa9b61b526a3e58d73e586e61918aa3c97245f46d28be178c", "source_sha256": "e51b94641336291974fe14bf4bb7299a75ec7dcce49e1d413282c8043e9f09f1", "target_language": "tcl"}
# openclaw-audit.sh — portiert nach tcl
# Quelle: shell, OpenClaw@gateway1:scripts/openclaw-audit.sh
# auch in: OpenClaw@gateway2:scripts/openclaw-audit.sh
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# OpenClaw read-only audit/diagnostic sweep
# Output: openclaw-audit-YYYY-MM-DD.log im selben Verzeichnis wie dieses Script

package require Tcl 8.6

# Helper functions
proc getScriptDir {} {
    set scriptPath [info script]
    if {$scriptPath eq ""} {
        set scriptPath [file normalize [file join [pwd] [lindex $::argv0 0]]]
    }
    return [file dirname $scriptPath]
}

proc formatDate {format} {
    return [clock format [clock seconds] -format $format]
}

proc runCommand {cmd} {
    if {[catch {exec {*}$cmd} result options]} {
        set rc [dict get $options -errorcode]
        if {[llength $rc] > 0} {
            set rc [lindex $rc 0]
        } else {
            set rc 1
        }
        return [list $result $rc]
    } else {
        return [list $result 0]
    }
}

proc which {prog} {
    foreach dir [split $::env(PATH) :] {
        set fullPath [file join $dir $prog]
        if {[file executable $fullPath]} {
            return $fullPath
        }
    }
    return ""
}

# Main script
set SCRIPT_DIR [getScriptDir]
set DATE_STAMP [formatDate "%Y-%m-%d"]
set OUT [file join $SCRIPT_DIR "openclaw-audit-${DATE_STAMP}.log"]

set OC [list openclaw --no-color]

# Initialize log file
set fh [open $OUT w]
puts $fh "================================================================"
puts $fh "OpenClaw audit run"
puts $fh "Started:  [formatDate "%Y-%m-%dT%H:%M:%S"]"
puts $fh "Host:     [exec hostname]"
puts $fh "User:     [exec whoami]"
if {[which openclaw] ne ""} {
    if {[catch {exec openclaw --version} version]} {
        set version "unknown"
    }
} else {
    set version "openclaw not found"
}
puts $fh "Version:  $version"
puts $fh "Output:   $OUT"
puts $fh "================================================================"
close $fh

# Function to run commands and log output
proc run_cmd {title args} {
    global OUT OC
    set fh [open $OUT a]
    puts $fh ""
    puts $fh "----------------------------------------------------------------"
    puts $fh "### $title"
    puts $fh "### \$ [join $args " "]"
    puts $fh "### [formatDate "%Y-%m-%dT%H:%M:%S"]"
    puts $fh "----------------------------------------------------------------"
    
    if {[catch {exec {*}$args} result options]} {
        set rc [dict get $options -errorcode]
        if {[llength $rc] > 0} {
            set rc [lindex $rc 0]
        } else {
            set rc 1
        }
        puts $fh $result
    } else {
        set rc 0
        puts $fh $result
    }
    puts $fh "\[exit: $rc\]"
    close $fh
}

# Run all audit commands
run_cmd "tasks audit --severity error" {*}$OC tasks audit --severity error
run_cmd "secrets audit" {*}$OC secrets audit
run_cmd "security audit" {*}$OC security audit
run_cmd "plugins doctor" {*}$OC plugins doctor
run_cmd "plugins deps" {*}$OC plugins deps
run_cmd "plugins registry" {*}$OC plugins registry
run_cmd "skills check" {*}$OC skills check
run_cmd "hooks check" {*}$OC hooks check
run_cmd "gateway status --deep" {*}$OC gateway status --deep
run_cmd "channels status --probe" {*}$OC channels status --probe
run_cmd "memory status --deep" {*}$OC memory status --deep
run_cmd "sessions --all-agents" {*}$OC sessions --all-agents
run_cmd "tasks list" {*}$OC tasks list
run_cmd "cron list" {*}$OC cron list

# Finalize log
set fh [open $OUT a]
puts $fh ""
puts $fh "================================================================"
puts $fh "Audit complete: [formatDate "%Y-%m-%dT%H:%M:%S"]"
puts $fh "================================================================"
close $fh

puts "Audit complete. Output: $OUT"
