#!/usr/bin/env tclsh8.6
# gen_tree.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway2:scripts/gen_tree.py
# Erzeugt: 2026-08-23 durch ABSTRACTIONS_MANAGER.py

# Replicates `tree -a -L 6` output for /workspace into important/openclaw-tree.txt
# (used because the `tree` binary is unavailable in this sandbox).

set ROOT "/workspace"
set OUT "/workspace/important/openclaw-tree.txt"
set MAX_DEPTH 6

# Function to collect directory tree
proc collect {path {prefix ""} {depth 1}} {
    set lines {}
    
    # Try to get directory contents
    if {[catch {lsort [glob -nocomplain -directory $path *]} entries]} {
        return $lines
    }
    
    set total [llength $entries]
    set i 0
    
    foreach full_path $entries {
        # Get just the filename
        set name [file tail $full_path]
        
        set is_last [expr {$i == $total - 1}]
        
        # Unicode box drawing characters
        set connector ""
        if {$is_last} {
            set connector "\u2514\u2500\u2500 "
        } else {
            set connector "\u251c\u2500\u2500 "
        }
        
        lappend lines "${prefix}${connector}${name}"
        
        # Recurse into directories (but not symlinks) up to max depth
        if {$depth < $::MAX_DEPTH && [file isdirectory $full_path] && ![file type $full_path eq "link"]} {
            set next_prefix ""
            if {$is_last} {
                set next_prefix "${prefix}    "
            } else {
                set next_prefix "${prefix}\u2502   "
            }
            set sub_lines [collect $full_path $next_prefix [expr {$depth + 1}]]
            set lines [concat $lines $sub_lines]
        }
        
        incr i
    }
    
    return $lines
}

# Generate the tree content
set body [collect $ROOT]

# Create header with current timestamp
set timestamp [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%S"]
set header "# OpenClaw Workspace Tree\n"
append header "# Generiert: ${timestamp}\n"
append header "# Befehl: tree -a -L 6 ${ROOT} (emuliert via gen_tree.tcl)\n"
append header "# Diese Datei wird automatisch von db-maintainer aktualisiert\n\n"

# Build complete content
set content $header
append content ".\n"
foreach line $body {
    append content "${line}\n"
}

# Write to file
set f [open $OUT w]
puts -nonewline $f $content
close $f

# Print summary
set line_count [expr {[llength $body] + 1}]
set byte_count [string length $content]
puts "written ${OUT}: ${line_count} lines, ${byte_count} bytes"
