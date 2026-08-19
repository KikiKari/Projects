#!/usr/bin/env tclsh8.6
# pplx-setup.sh — portiert nach tcl
# Quelle: shell, OpenClaw@main:scripts/pplx-tools/pplx-setup.sh
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

# One-time (idempotent): make sure the Perplexity VS Code extension daemon can
# find a Chromium. The daemon uses its OWN bundled patchright, which pins a
# specific chromium revision; install exactly that revision.

package require fileutil

# Find the latest extension patchright directory
set extpr ""
set extensions_dir [file join $env(HOME) ".vscode-remote" "extensions"]
if {[file exists $extensions_dir]} {
    set pattern [file join $extensions_dir "nskha.perplexity-vscode-*" "dist" "node_modules" "patchright"]
    set matches [glob -nocomplain -- $pattern]
    
    # Sort versions and get the latest
    if {[llength $matches] > 0} {
        set sorted_matches [lsort -dictionary $matches]
        set extpr [lindex $sorted_matches end]
    }
}

if {$extpr eq ""} {
    puts "\[setup\] extension patchright not found — is the Perplexity extension installed?"
    exit 0
}

# Get expected chromium path
set exp ""
if {[catch {
    set node_cmd "const {chromium}=require('[regsub -all {\\} $extpr {\\\\}}');console.log(chromium.executablePath())"
    set exp [exec node -e $node_cmd]
} result]} {
    set exp ""
}

# Check if executable already exists
if {$exp ne "" && [file executable $exp]} {
    puts "\[setup\] daemon browser already present: $exp"
    exit 0
}

puts "\[setup\] installing matching chromium for the extension daemon (expected: [expr {$exp eq "" ? "unknown" : $exp}])..."
exec node [file join $extpr "cli.js"] install chromium
puts "\[setup\] done."
