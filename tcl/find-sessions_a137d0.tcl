#!/usr/bin/env tclsh
# abstraction-provenance: {"artifact_sha256": "e3eaf31e1396b4f586ad99a727fa68f620aeddab4da390f8ce85b98d2a35a45b", "source_sha256": "a137d03b3b37332439a1592831d60479ff86315c7e6d6ed7da0fb799db0f13f7", "target_language": "tcl"}
# find-sessions.sh — portiert nach tcl
# Quelle: shell, OpenClaw@gateway1:skills/tmux/scripts/find-sessions.sh
# auch in: OpenClaw@gateway2:skills/tmux/scripts/find-sessions.sh
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

proc usage {} {
    puts {Usage: find-sessions.tcl [-L socket-name|-S socket-path|-A] [-q pattern]

List tmux sessions on a socket (default tmux socket if none provided).

Options:
  -L, --socket       tmux socket name (passed to tmux -L)
  -S, --socket-path  tmux socket path (passed to tmux -S)
  -A, --all          scan all sockets under CLAWDBOT_TMUX_SOCKET_DIR
  -q, --query        case-insensitive substring to filter session names
  -h, --help         show this help}
}

proc list_sessions {label args} {
    global query
    
    set tmux_cmd [concat "tmux" $args]
    lappend tmux_cmd "list-sessions" "-F" "{#session_name}\\t{#session_attached}\\t{#session_created_string}"
    
    if {[catch {exec {*}$tmux_cmd 2>@1} sessions]} {
        puts stderr "No tmux server found on $label"
        return 1
    }
    
    if {$query ne ""} {
        set filtered_sessions ""
        foreach line [split $sessions \n] {
            if {$line eq ""} continue
            if {[string match -nocase "*$query*" $line]} {
                append filtered_sessions "$line\n"
            }
        }
        set sessions [string trim $filtered_sessions]
    }
    
    if {$sessions eq ""} {
        puts "No sessions found on $label"
        return 0
    }
    
    puts "Sessions on $label:"
    foreach line [split $sessions \n] {
        if {$line eq ""} continue
        foreach {name attached created} [split $line \t] break
        set attached_label [expr {$attached == 1 ? "attached" : "detached"}]
        puts "  - $name ($attached_label, started $created)"
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
        {-L} - {--socket} {
            incr i
            if {$i >= $argc} {
                puts stderr "Option $arg requires an argument"
                usage
                exit 1
            }
            set socket_name [lindex $argv $i]
        }
        {-S} - {--socket-path} {
            incr i
            if {$i >= $argc} {
                puts stderr "Option $arg requires an argument"
                usage
                exit 1
            }
            set socket_path [lindex $argv $i]
        }
        {-A} - {--all} {
            set scan_all true
        }
        {-q} - {--query} {
            incr i
            if {$i >= $argc} {
                puts stderr "Option $arg requires an argument"
                usage
                exit 1
            }
            set query [lindex $argv $i]
        }
        {-h} - {--help} {
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

# Check if tmux is available
if {[catch {exec which tmux}]} {
    puts stderr "tmux not found in PATH"
    exit 1
}

# Handle --all option
if {$scan_all} {
    if {![file isdirectory $socket_dir]} {
        puts stderr "Socket directory not found: $socket_dir"
        exit 1
    }
    
    set sockets [glob -nocomplain -tails -directory $socket_dir *]
    if {[llength $sockets] == 0} {
        puts stderr "No sockets found under $socket_dir"
        exit 1
    }
    
    set exit_code 0
    foreach sock $sockets {
        set sock_path [file join $socket_dir $sock]
        if {[file type $sock_path] eq "socket"} {
            if {[catch {list_sessions "socket path '$sock_path'" -S $sock_path} result]} {
                set exit_code 1
            }
        }
    }
    exit $exit_code
}

# Handle single socket
set tmux_cmd {}
set socket_label "default socket"

if {$socket_name ne ""} {
    lappend tmux_cmd -L $socket_name
    set socket_label "socket name '$socket_name'"
} elseif {$socket_path ne ""} {
    lappend tmux_cmd -S $socket_path
    set socket_label "socket path '$socket_path'"
}

eval list_sessions [list $socket_label] $tmux_cmd
