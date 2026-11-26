#!/usr/bin/env tclsh8.6
# abstraction-provenance: {"artifact_sha256": "83241dfd26c2164900fef75d2507899fbe6e291c5088f4501ce56f220713caf3", "source_sha256": "0a55a33f11db266892b50c887fd8d01783f387e3072c8c5b9ed86ca6788a8c52", "target_language": "tcl"}
# gen_tree.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway2:scripts/gen_tree.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# Replicates `tree -a -L 6` output for /workspace into important/openclaw-tree.txt
# (used because the `tree` binary is unavailable in this sandbox).

set ROOT "/workspace"
set OUT "/workspace/important/openclaw-tree.txt"
set MAX_DEPTH 6

# Procedure to collect directory tree
proc collect {path {prefix ""} {depth 1}} {
    global MAX_DEPTH
    set lines {}
    
    if {$depth > $MAX_DEPTH} {
        return $lines
    }
    
    # Get directory entries
    if {[catch {glob -nocomplain -dir $path *} entries]} {
        return $lines
    }
    
    # Sort entries
    set entries [lsort $entries]
    set total [llength $entries]
    
    for {set i 0} {$i < $total} {incr i} {
        set full [lindex $entries $i]
        set name [file tail $full]
        
        set is_last [expr {$i == $total - 1}]
        set connector [expr {$is_last ? "\u2514\u2500\u2500 " : "\u251c\u2500\u2500 "}]
        
        lappend lines "${prefix}${connector}${name}"
        
        # Recurse into directories
        if {$depth < $MAX_DEPTH && [file isdirectory $full] && ![file islink $full]} {
            set next_prefix "${prefix}[expr {$is_last ? {    } : {\u2502   }}]"
            set sublines [collect $full $next_prefix [expr {$depth + 1}]]
            set lines [concat $lines $sublines]
        }
    }
    
    return $lines
}

# Generate content
set body [collect $ROOT]
set timestamp [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%S"]
set header "# OpenClaw Workspace Tree\n# Generiert: $timestamp\n# Befehl: tree -a -L 6 $ROOT (emuliert via gen_tree.tcl)\n# Diese Datei wird automatisch von db-maintainer aktualisiert\n\n"
set content "${header}.\n[join $body \n]\n"

# Write to file
set f [open $OUT w]
puts -nonewline $f $content
close $f

# Output info
set line_count [expr {[llength $body] + 1}]
set byte_count [string length $content]
puts "written $OUT: $line_count lines, $byte_count bytes"
