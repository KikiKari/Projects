#!/usr/bin/env tclsh
# find-sessions.sh — portiert nach tcl
# Quelle: shell, OpenClaw@gateway1:skills/tmux/scripts/find-sessions.sh
# auch in: OpenClaw@gateway2:skills/tmux/scripts/find-sessions.sh
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

proc usage {} {
    puts stderr {Usage: find-sessions.sh \[-L socket-name|-S socket-path|-A\] \[-q pattern\]

List tmux sessions on a socket \(default tmux socket if none provided\).

Options:
  -L, --socket       tmux socket name \(passed to tmux -L\)
  -S, --socket-path  tmux socket path \(passed to tmux -S\)
  -A, --all          scan all sockets under CLAWDBOT_TMUX_SOCKET_DIR
  -q, --query        case-insensitive substring to filter session names
  -h, --help         show this help}
}

proc list_sessions {label args} {
    set tmux_cmd [list tmux {*}$args]
    
    if {[catch {exec {*}$tmux_cmd list-sessions -F {#{session_name}\t#{session_attached}\t#{session_created_string}} 2>@1} sessions]} {
        puts stderr "No tmux server found on $label"
        return 1
    }
    
    global query
    if {$query ne ""} {
        # Filter sessions by query (case insensitive)
        set filtered_sessions {}
        foreach line [split $sessions \n] {
            if {$line eq ""} continue
            if {[string match -nocase *$query* $line]} {
                lappend filtered_sessions $line
            }
        }
        set sessions [join $filtered_sessions \n]
    }
    
    if {$sessions eq ""} {
        puts "No sessions found on $label"
        return 0
    }
    
    puts "Sessions on $label:"
    foreach line [split $sessions \n] {
        if {$line eq ""} continue
        lassign [split $line \t] name attached created
        set attached_label [expr {$attached == 1 ? "attached" : "detached"}]
        puts "  - $name \($attached_label, started $created\)"
    }
    return 0
}

# Parse environment variables
set socket_dir [expr {[info exists ::env(CLAWDBOT_TMUX_SOCKET_DIR)] ? $::env(CLAWDBOT_TMUX_SOCKET_DIR) : 
                     ([info exists ::env(TMPDIR)] ? $::env(TMPDIR) : "/tmp") + "/clawdbot-tmux-sockets"}]

# Initialize variables
set socket_name ""
set socket_path ""
set query ""
set scan_all false

# Parse command line arguments
for {set i 0} {$i < $argc} {incr i} {
    set arg [lindex $argv $i]
    switch -exact -- $arg {
        -L - --socket {
            incr i
            if {$i >= $argc} {
                puts stderr "Option $arg requires an argument"
                usage
                exit 1
            }
            set socket_name [lindex $argv $i]
        }
        -S - --socket-path {
            incr i
            if {$i >= $argc} {
                puts stderr "Option $arg requires an argument"
                usage
                exit 1
            }
            set socket_path [lindex $argv $i]
        }
        -A - --all {
            set scan_all true
        }
        -q - --query {
            incr i
            if {$i >= $argc} {
                puts stderr "Option $arg requires an argument"
                usage
                exit 1
            }
            set query [lindex $argv $i]
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

# Validate arguments
if {$scan_all && ($socket_name ne "" || $socket_path ne "")} {
    puts stderr "Cannot combine --all with -L or -S"
    exit 1
}

if {$socket_name ne "" && $socket_path ne ""} {
    puts stderr "Use either -L or -S, not both"
    exit 1
}

# Check if tmux exists
if {[catch {exec which tmux}]} {
    puts stderr "tmux not found in PATH"
    exit 1
}

if {$scan_all} {
    if {![file isdirectory $socket_dir]} {
        puts stderr "Socket directory not found: $socket_dir"
        exit 1
    }
    
    # Get all files in socket directory
    set sockets {}
    if {[catch {glob -nocomplain -dir $socket_dir *} files]} {
        set files {}
    }
    
    # Filter only socket files (Unix domain sockets)
    set sockets {}
    foreach file $files {
        if {[file type $file] eq "socket"} {
            lappend sockets $file
        }
    }
    
    if {[llength $sockets] == 0} {
        puts stderr "No sockets found under $socket_dir"
        exit 1
    }
    
    set exit_code 0
    foreach sock $sockets {
        if {[catch {list_sessions "socket path '$sock'" -S $sock} result]} {
            set exit_code 1
        }
    }
    exit $exit_code
}

set tmux_cmd [list tmux]
set socket_label "default socket"

if {$socket_name ne ""} {
    lappend tmux_cmd -L $socket_name
    set socket_label "socket name '$socket_name'"
} elseif {$socket_path ne ""} {
    lappend tmux_cmd -S $socket_path
    set socket_label "socket path '$socket_path'"
}

# Call list_sessions with remaining tmux arguments
set args [lrange $tmux_cmd 1 end]
if {[catch {list_sessions $socket_label {*}$args} result]} {
    exit 1
}
