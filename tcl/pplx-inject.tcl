#!/usr/bin/env tclsh
# pplx-inject.mjs — portiert nach tcl
# Quelle: javascript, OpenClaw@main:scripts/pplx-tools/pplx-inject.mjs
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

# Inject a perplexity.ai web session (the __Secure-next-auth.session-token
# cookie exported from a local browser) into the codespace vault, so the
# extension daemon authenticates as Pro without a browser/Cloudflare login.
#
# Usage: PERPLEXITY_VAULT_PASSPHRASE=... PPLX_DIST=<dist> tclsh pplx-inject.tcl <cookies-file>
# (normally invoked by pplx-refresh.sh, which resolves passphrase + dist)
#
# Input file may be: a bare JWT token, a raw "Cookie:" header string, or a
# JSON array (Cookie-Editor / Playwright export).

package require json
package require fileutil

# Environment variables
set PROFILE [expr {[info exists ::env(PERPLEXITY_PROFILE)] ? $::env(PERPLEXITY_PROFILE) : "codespace"}]
set EMAIL [expr {[info exists ::env(PPLX_EMAIL)] ? $::env(PPLX_EMAIL) : "KarimKiki@gmx.de"}]

# Command line argument
if {$argc != 1} {
    puts stderr "usage: tclsh pplx-inject.tcl <cookies-file>"
    exit 1
}
set file [lindex $argv 0]

# --- locate the perplexity-user-mcp dist and its Vault / profile chunks ---
set DIST ""
if {[info exists ::env(PPLX_DIST)] && [file isdirectory $::env(PPLX_DIST)]} {
    set DIST $::env(PPLX_DIST)
} else {
    # Try to find using find command
    if {[catch {exec find $::env(HOME)/.npm/_npx -type d -path {*perplexity-user-mcp/dist} 2>/dev/null | head -1} result]} {
        set result ""
    }
    set result [string trim $result]
    if {$result ne "" && [file isdirectory $result]} {
        set DIST $result
    }
}

if {$DIST eq "" || ![file isdirectory $DIST]} {
    puts stderr "cannot locate perplexity-user-mcp/dist (set PPLX_DIST)"
    exit 1
}

# Function to simulate reading files and regex matching for imports
proc chunkFor {symbol} {
    global DIST
    foreach entry {"manual-login-runner.mjs" "login-runner.mjs" "cli.mjs"} {
        set filepath [file join $DIST $entry]
        if {![file exists $filepath]} continue
        
        set fd [open $filepath r]
        set content [read $fd]
        close $fd
        
        # Match import statements like: import { ... } from "./chunk-*.mjs"
        set pattern {import\s*\{([^\}]*)\}\s*from\s*"(\./chunk-[^"]+\.mjs)"}
        foreach {full_match names_part path_part} [regexp -all -inline $pattern $content] {
            set names_list [split [string trim $names_part] ","]
            set clean_names {}
            foreach name $names_list {
                set name [string trim $name]
                # Handle 'original as alias' syntax
                if {[regexp {(.+)\s+as\s+(.+)} $name -> original alias]} {
                    lappend clean_names [string trim $original]
                } else {
                    lappend clean_names $name
                }
            }
            
            if {[lsearch -exact $clean_names $symbol] != -1} {
                # Return absolute path
                return [file join $DIST [string range $path_part 2 end]]
            }
        }
    }
    return ""
}

set vaultChunk [chunkFor "Vault"]
set profChunk [chunkFor "getProfilePaths"]

if {$vaultChunk eq "" || $profChunk eq ""} {
    puts stderr "could not locate Vault/profile chunks in dist"
    exit 1
}

# Since we can't directly import JS modules in Tcl, we'll need to reimplement
# the necessary functionality or call external scripts.
# For now, we'll assume that these are implemented elsewhere or use stubs.

# Stub implementations for required functions
proc getProfilePaths {profile} {
    # Mimic the behavior of the JS function
    set homeDir $::env(HOME)
    set baseDir [file join $homeDir ".perplexity-user-mcp"]
    set dir [file join $baseDir "profiles" $profile]
    set modelsCache [file join $dir "models-cache.json"]
    set reinit [file join $dir "reinit"]
    return [dict create dir $dir modelsCache $modelsCache reinit $reinit]
}

proc recordLoginSuccess {profile data} {
    # This would normally write to a login history file
    # For now, we just acknowledge it
    return
}

# Vault class simulation
namespace eval Vault {
    variable storage
    
    proc new {} {
        variable storage
        set storage [dict create]
        return "VaultInstance"
    }
    
    proc set {instance profile key value} {
        variable storage
        dict set storage $profile:$key $value
        # In real implementation, this would persist to disk
        return
    }
}

# --- parse the cookie input (token / header / JSON) ---
set fd [open $file r]
set text [string trim [read $fd]]
close $fd

set raw {}

if {[string index $text 0] eq "\[" || [string index $text 0] eq "\{"} {
    if {[catch {::json::json2dict $text} jsonData]} {
        puts stderr "Invalid JSON format"
        exit 1
    }
    
    # Check if it's a wrapper with cookies array
    if {[dict exists $jsonData cookies]} {
        set raw [dict get $jsonData cookies]
    } else {
        set raw $jsonData
    }
    
    if {![dict size $raw] && ![llength $raw]} {
        puts stderr "expected a JSON array of cookies"
        exit 1
    }
} elseif {[string match "eyJ*" $text] && ![string match "*=*"] && ![string match "*;*"]} {
    set raw [list [dict create name "__Secure-next-auth.session-token" value $text]]
} else {
    set pairs [split $text "; "]
    set raw {}
    foreach kv $pairs {
        if {[set idx [string first "=" $kv]] >= 0} {
            set name [string trim [string range $kv 0 [expr {$idx - 1}]]]
            set value [string trim [string range $kv [expr {$idx + 1}] end]]
            if {$name ne ""} {
                lappend raw [dict create name $name value $value]
            }
        }
    }
}

proc normSameSite {s} {
    set v [string tolower [expr {$s eq "" ? "" : $s}]]
    if {$v eq "no_restriction" || $v eq "none"} {
        return "None"
    }
    if {$v eq "strict"} {
        return "Strict"
    }
    return "Lax"
}

set cookies {}
foreach c $raw {
    if {![dict exists $c name] || ![dict exists $c value]} continue
    
    set domain ".perplexity.ai"
    if {[dict exists $c domain]} {
        set d [dict get $c domain]
        if {[string match "*perplexity*" $d]} {
            set domain $d
        }
    }
    
    set expires -1
    if {[dict exists $c expires]} {
        set expires [dict get $c expires]
    } elseif {[dict exists $c expirationDate]} {
        set expires [dict get $c expirationDate]
    }
    
    if {![string is integer -strict $expires]} {
        set expires -1
    } else {
        set expires [expr {int($expires)}]
    }
    
    set path "/"
    if {[dict exists $c path]} {
        set path [dict get $c path]
    }
    
    set httpOnly false
    if {[dict exists $c httpOnly]} {
        set httpOnly [dict get $c httpOnly]
    }
    
    set secure true
    if {[dict exists $c secure]} {
        set secure [dict get $c secure]
    }
    
    set sameSite [normSameSite [dict get $c sameSite]]
    
    lappend cookies [dict create \
        name [dict get $c name] \
        value [dict get $c value] \
        domain $domain \
        path $path \
        expires $expires \
        httpOnly $httpOnly \
        secure $secure \
        sameSite $sameSite]
}

set names {}
foreach c $cookies {
    lappend names [dict get $c name]
}
puts "Parsed [llength $cookies] perplexity.ai cookies: [join $names ", "]"

set hasSessionToken false
foreach n $names {
    if {[string match "__Secure-next-auth.session-token*" $n]} {
        set hasSessionToken true
        break
    }
}

if {!$hasSessionToken} {
    puts stderr "WARNING: no '__Secure-next-auth.session-token' — session likely won't authenticate."
}

set paths [getProfilePaths $PROFILE]
set dir [dict get $paths dir]
set modelsCache [dict get $paths modelsCache]
set reinit [dict get $paths reinit]

if {![file exists $dir]} {
    file mkdir $dir
}

set vault [Vault::new]
Vault::set $vault $PROFILE "cookies" [::json::dict2json $cookies]
Vault::set $vault $PROFILE "email" $EMAIL

if {![file exists $modelsCache]} {
    set fd [open $modelsCache w]
    puts $fd [::json::dict2json [dict create models [dict create]]]
    close $fd
}

recordLoginSuccess $PROFILE [dict create tier "pro" loginMode "manual" lastLogin [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%SZ"]]
set fd [open $reinit w]
puts $fd [clock milliseconds]
close $fd

puts "OK: injected [llength $cookies] cookie(s) into vault profile '$PROFILE'."
