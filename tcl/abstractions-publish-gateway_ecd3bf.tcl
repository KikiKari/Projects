#!/usr/bin/env tclsh8.6
# abstractions-publish-gateway.py — portiert nach tcl
# Quelle: python, Projects@abstractions:python/abstractions-publish-gateway.py
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# abstractions-publish-gateway.sh — portiert nach python
# Quelle: shell, OpenClaw@gateway2:scripts/abstractions-publish-gateway.sh
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

# Workspace-visible wrapper for the gateway publish job.

proc main {} {
    # Define the path to the actual script
    set script_path "/home/openclaw/.openclaw/scripts/abstractions-publish-gateway.sh"
    
    # Check if the script exists
    if {![file exists $script_path]} {
        puts stderr "Error: Script not found at $script_path"
        exit 1
    }
    
    # Execute the script with all passed arguments
    set argv [lassign $::argv script_name]
    set cmd [concat [list exec $script_path] $argv]
    
    if {[catch {eval $cmd} result]} {
        puts stderr "Error executing script: $result"
        exit 1
    }
}

if {$::argv0 eq [info script]} {
    main
}
