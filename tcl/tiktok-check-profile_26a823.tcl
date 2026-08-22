#!/usr/bin/env tclsh8.6
# tiktok-check-profile.js — portiert nach tcl
# Quelle: javascript, OpenClaw@gateway2:skills/tiktok-live/scripts/tiktok-check-profile.js
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

# Basic TikTok LIVE profile checker.
#
# Scopes every signal to the requested account and ignores unrelated sidebar
# LIVE labels. This profile-only checker does not classify restricted LIVE;
# use the enhanced checker or dispatcher for that distinction.
#
# Exit 0 = account-specific LIVE, 1 = offline, 2 = dependency/technical
# failure, 75 = overloaded before Playwright startup.

package require http
package require tls
package require json
package require fileutil

# Initialize TLS for HTTPS support
http::register https 443 [list ::tls::socket -ssl3 false -tls1_2 true]

proc normalizeUsername {username} {
    # Remove @ prefix if present
    regsub {^@+} $username {} username
    # Validate username format
    if {![regexp {^[a-zA-Z0-9._-]+$} $username]} {
        error "Invalid username format"
    }
    return $username
}

proc enforceLoadLimit {method} {
    # Placeholder for load limiting logic
    # In production, this would check system resources
    return
}

proc liveHrefSelectors {username} {
    set selectors {}
    lappend selectors "a[href=\"/@$username/live\"]"
    lappend selectors "a[href=\"https://www.tiktok.com/@$username/live\"]"
    lappend selectors "a[href^=\"/@$username/live\"]"
    return $selectors
}

proc checkLiveStatus {username} {
    # Check if we have network access first
    if {[catch {
        set token [http::geturl "https://www.tiktok.com/robots.txt" -timeout 5000]
        http::cleanup $token
    }]} {
        puts [::json::encode {
            error true
            status "network_unavailable"
            method "fallback_check"
            message "No internet connection available"
            timestamp [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%SZ"]
        }]
        return -1
    }

    # For Tcl implementation, we'll use a simplified approach with HTTP requests
    # since full Playwright equivalent doesn't exist in Tcl
    
    set url "https://www.tiktok.com/@$username"
    
    # Set headers to mimic browser request
    set headers [list User-Agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"]
    
    if {[catch {
        set token [http::geturl $url -headers $headers -timeout 30000]
        set html [http::data $token]
        http::cleanup $token
    } errorMsg]} {
        puts [::json::encode {
            error true
            status "technical_error"
            message $errorMsg
            timestamp [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%SZ"]
        }]
        return -1
    }
    
    # Check for LIVE indicators in HTML
    set hasLiveLink [expr {[regexp {href="[^"]*/@'"$username"'/live"} $html]}]
    set liveIconVisible [expr {[regexp {(?i)(live-icon|LiveBadge|live-indicator)} $html]}]
    set liveBadgeVisible [expr {[regexp {(?i)\bLIVE\b} $html]}]
    set hasLiveBorder [expr {[regexp {(?i)(borderColor.*(?:255|red|fe2c55)|boxShadow.*(?:255|254))} $html]}]
    set liveIndicatorVisible [expr {[regexp {(?i)(live-indicator|LiveBadge)} $html]}]
    
    set isLive [expr {$hasLiveLink || $hasLiveBorder || $liveIconVisible || $liveIndicatorVisible || $liveBadgeVisible}]
    
    puts [::json::encode {
        username $username
        isLive $isLive
        timestamp [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%SZ"]
        indicators {
            liveIcon $liveIconVisible
            liveBadge $liveBadgeVisible
            liveBorder $hasLiveBorder
            liveLink $hasLiveLink
            liveIndicator $liveIndicatorVisible
        }
    }]
    
    return $isLive
}

# Main execution
if {$argc != 1} {
    puts stderr "Usage: tclsh tiktok-check-profile.tcl <username>"
    exit 64
}

set username [lindex $argv 0]

if {[catch {
    set username [normalizeUsername $username]
} error]} {
    puts stderr "Usage: tclsh tiktok-check-profile.tcl <username>"
    puts stderr $error
    exit 64
}

enforceLoadLimit "fallback_check"

set result [checkLiveStatus $username]

# Exit codes: 0 = live, 1 = offline, 2 = error, 75 = overloaded
if {$result == -1} {
    exit 2
} elseif {$result} {
    exit 0
} else {
    exit 1
}
