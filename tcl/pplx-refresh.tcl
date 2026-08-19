#!/usr/bin/env tclsh8.6
# pplx-refresh.sh — portiert nach tcl
# Quelle: shell, OpenClaw@main:scripts/pplx-tools/pplx-refresh.sh
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

# Refresh the codespace Perplexity session from a locally-exported cookie.
#
# Usage:
#   ./pplx-refresh.sh [cookie-file]
#
# cookie-file defaults to ~/pplx-cookies.txt. Put your local browser's
# __Secure-next-auth.session-token value (raw), or the whole Cookie header,
# or a JSON cookie export, into that file first.
#
# Steps: ensure daemon browser -> read daemon passphrase -> inject into vault
#        -> trigger reinit -> verify authenticated.

package require json

# Get script directory
set HERE [file dirname [info script]]
set CFG [expr {[info exists ::env(PERPLEXITY_CONFIG_DIR)] ? $::env(PERPLEXITY_CONFIG_DIR) : "$::env(HOME)/.perplexity-mcp"}]
set PROFILE [expr {[info exists ::env(PERPLEXITY_PROFILE)] ? $::env(PERPLEXITY_PROFILE) : "codespace"}]

# Handle command line argument
if {$argc > 0} {
    set COOKIE_FILE [lindex $argv 0]
} else {
    set COOKIE_FILE "$::env(HOME)/pplx-cookies.txt"
}

if {![file exists $COOKIE_FILE] || [file size $COOKIE_FILE] == 0} {
    puts "✗ Cookie file empty/missing: $COOKIE_FILE"
    puts "  Export __Secure-next-auth.session-token from your local browser"
    puts "  (DevTools → Application → Cookies → www.perplexity.ai) into that file."
    exit 1
}

# 1. ensure the extension daemon has a usable browser (idempotent)
exec bash "$HERE/pplx-setup.sh"

# 2. daemon pid + vault passphrase (never guessed — read from the live daemon)
set LOCK "$CFG/daemon.lock"
if {![file exists $LOCK]} {
    puts "✗ no daemon.lock at $LOCK — is the extension running?"
    exit 1
}

# Read lock file and extract PID
set fd [open $LOCK r]
set lock_data [read $fd]
close $fd
dict with json::decode $lock_data
set PID [dict get $lock_data pid]

# Check if process is running
if {[catch {exec ps -p $PID -o pid=} result]} {
    puts "✗ daemon pid $PID not running"
    exit 1
}

# Extract passphrase from environment
set PASS ""
if {[file readable "/proc/$PID/environ"]} {
    set fd [open "/proc/$PID/environ" r]
    set environ_data [read $fd]
    close $fd
    
    # Split by null bytes and search for our variable
    foreach entry [split $environ_data "\0"] {
        if {[string match "PERPLEXITY_VAULT_PASSPHRASE=*" $entry]} {
            set PASS [string range $entry 29 end]
            break
        }
    }
}

if {$PASS eq ""} {
    puts "✗ no PERPLEXITY_VAULT_PASSPHRASE in daemon env"
    exit 1
}

# 3. locate the perplexity-user-mcp dist (populate npx cache if needed)
set DIST ""
set npx_dir "$::env(HOME)/.npm/_npx"
if {[file exists $npx_dir]} {
    # Search for perplexity-user-mcp/dist directories
    set cmd "find {$npx_dir} -type d -path *perplexity-user-mcp/dist 2>/dev/null | head -1"
    if {[catch {exec /bin/sh -c $cmd} dist_result] == 0 && $dist_result ne ""} {
        set DIST $dist_result
    }
}

if {$DIST eq ""} {
    # Try to populate npx cache
    catch {exec npx -y perplexity-user-mcp --version}
    
    # Search again
    set cmd "find {$npx_dir} -type d -path *perplexity-user-mcp/dist 2>/dev/null | head -1"
    if {[catch {exec /bin/sh -c $cmd} dist_result] == 0 && $dist_result ne ""} {
        set DIST $dist_result
    }
}

# 4. inject
set env(PERPLEXITY_VAULT_PASSPHRASE) $PASS
set env(PERPLEXITY_CONFIG_DIR) $CFG
set env(PERPLEXITY_PROFILE) $PROFILE
set env(PPLX_DIST) $DIST

if {[catch {exec node "$HERE/pplx-inject.mjs" $COOKIE_FILE} result]} {
    puts stderr $result
    exit 1
}

# 5. trigger daemon reinit
set REINIT_FILE "$CFG/profiles/$PROFILE/.reinit"
set fd [open $REINIT_FILE w]
puts $fd [clock seconds]
close $fd
puts "→ reinit triggered, waiting for daemon..."

# 6. verify
set STAT "$CFG/profiles/$PROFILE/daemon-status.json"
set authenticated false
for {set i 1} {$i <= 20} {incr i} {
    after 1500  ;# Sleep 1.5 seconds
    
    set AUTH ""
    set TIER ""
    
    if {[file exists $STAT]} {
        if {[catch {set fd [open $STAT r]}] == 0} {
            if {[catch {set stat_data [read $fd]}] == 0} {
                close $fd
                
                if {[catch {dict with json::decode $stat_data}] == 0} {
                    if {[dict exists $stat_data authenticated]} {
                        set AUTH [dict get $stat_data authenticated]
                    }
                    if {[dict exists $stat_data tier]} {
                        set TIER [dict get $stat_data tier]
                    }
                }
            } else {
                close $fd
            }
        }
    }
    
    if {$AUTH eq "true" || $AUTH eq "True"} {
        puts "✅ authenticated — tier: $TIER"
        exit 0
    }
}

puts "⚠️  not authenticated yet. Check: tail -20 $CFG/daemon.log"
exit 1
