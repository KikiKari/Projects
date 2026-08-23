#!/usr/bin/env tclsh8.6
# wait-for-text.sh — portiert nach tcl
# Quelle: shell, OpenClaw@gateway1:skills/tmux/scripts/wait-for-text.sh
# auch in: OpenClaw@gateway2:skills/tmux/scripts/wait-for-text.sh
# Erzeugt: 2026-08-23 durch ABSTRACTIONS_MANAGER.py

proc usage {} {
    puts stderr {Usage: wait-for-text.sh -t target -p pattern \[options\]

Poll a tmux pane for text and exit when found.

Options:
  -t, --target    tmux target (session:window.pane), required
  -p, --pattern   regex pattern to look for, required
  -F, --fixed     treat pattern as a fixed string (grep -F)
  -T, --timeout   seconds to wait (integer, default: 15)
  -i, --interval  poll interval in seconds (default: 0.5)
  -l, --lines     number of history lines to inspect (integer, default: 1000)
  -h, --help      show this help}
}

# Parse command line arguments
set target ""
set pattern ""
set grep_flag "-regexp"
set timeout 15
set interval 0.5
set lines 1000

for {set i 0} {$i < $argc} {incr i} {
    set arg [lindex $argv $i]
    switch -exact -- $arg {
        -t - --target {
            incr i
            set target [lindex $argv $i]
        }
        -p - --pattern {
            incr i
            set pattern [lindex $argv $i]
        }
        -F - --fixed {
            set grep_flag "-exact"
        }
        -T - --timeout {
            incr i
            set timeout [lindex $argv $i]
        }
        -i - --interval {
            incr i
            set interval [lindex $argv $i]
        }
        -l - --lines {
            incr i
            set lines [lindex $argv $i]
        }
        -h - --help {
            usage
            exit 0
        }
        default {
            puts stderr "Unknown option: $arg"
            usage
            exit 1
        }
    }
}

if {$target eq "" || $pattern eq ""} {
    puts stderr "target and pattern are required"
    usage
    exit 1
}

# Validate numeric inputs
if {![string is integer -strict $timeout]} {
    puts stderr "timeout must be an integer number of seconds"
    exit 1
}

if {![string is integer -strict $lines]} {
    puts stderr "lines must be an integer"
    exit 1
}

# Check if tmux exists
if {[catch {exec which tmux}]} {
    puts stderr "tmux not found in PATH"
    exit 1
}

# Calculate deadline
set start_epoch [clock seconds]
set deadline [expr {$start_epoch + $timeout}]

while {true} {
    # Capture pane text
    if {[catch {exec tmux capture-pane -p -J -t $target -S -$lines} pane_text]} {
        set pane_text ""
    }

    # Check if pattern matches
    if {[regexp -- $pattern $pane_text]} {
        exit 0
    }

    set now [clock seconds]
    if {$now >= $deadline} {
        puts stderr "Timed out after ${timeout}s waiting for pattern: $pattern"
        puts stderr "Last ${lines} lines from $target:"
        puts stderr $pane_text
        exit 1
    }

    # Sleep for the specified interval
    after [expr {int($interval * 1000)}]
}
