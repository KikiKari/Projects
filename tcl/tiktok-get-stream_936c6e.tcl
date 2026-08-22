#!/usr/bin/env tclsh8.6
# tiktok-get-stream.js — portiert nach tcl
# Quelle: javascript, OpenClaw@gateway2:skills/tiktok-live/scripts/tiktok-get-stream.js
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

# Basic TikTok LIVE URL extractor.
#
# Accepts only observed HTTPS TikTok-CDN .flv responses with HTTP 2xx.
# Success writes one naked URL to stdout. Offline/no URL exits 1, dependency
# or technical failure exits 2, and preflight overload exits 75.

package require http
package require tls
package require json
package require json::write

# Initialize TLS for HTTPS support
http::register https 443 [list ::tls::socket -servername tls]

# Load common functions from external file
source tiktok-common.tcl

# Check command line arguments
lassign $argv arg1 arg2
set username ""
set jsonOutput false

if {$arg1 eq "--json"} {
    set jsonOutput true
    set username [normalizeUsername $arg2]
} elseif {$arg2 eq "--json"} {
    set jsonOutput true
    set username [normalizeUsername $arg1]
} else {
    set username [normalizeUsername $arg1]
}

if {[catch {set username}]} {
    puts stderr "Usage: tclsh tiktok-get-stream.tcl <username>"
    puts stderr [getErrorInfo]
    exit 64
}

enforceLoadLimit "playwright_network_basic"
if {[forcedOffline "playwright_network_basic" $username]} {
    exit 1
}

proc getStreamUrl {username jsonOutput} {
    # In Tcl we can't use Playwright directly, so we'll simulate the behavior
    # using HTTP requests and HTML parsing
    
    set flvUrls {}
    set maxCollectedUrls 100
    
    # This is a simplified approach since we don't have Playwright in Tcl
    # We'll try to fetch the live page and extract stream URLs
    
    set url "https://www.tiktok.com/@$username/live"
    
    # Set up headers similar to what Playwright would use
    array set headers {
        User-Agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        Accept "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8"
        Accept-Language "en-US,en;q=0.5"
        Accept-Encoding "gzip, deflate, br"
        Connection "keep-alive"
        Upgrade-Insecure-Requests "1"
    }
    
    set token [http::geturl $url -headers [array get headers] -timeout 60000]
    
    set status [http::status $token]
    set code [http::ncode $token]
    
    if {$status eq "ok" && $code >= 200 && $code < 300} {
        set data [http::data $token]
        
        # Simple pattern matching for FLV URLs in the page content
        # This is a basic simulation of what Playwright would capture
        foreach {match} [regexp -all -inline {https?://[^"]*\.flv[^"\s]*} $data] {
            if {[llength $flvUrls] < $maxCollectedUrls && [isSuccessfulStreamResponse $code $match]} {
                lappend flvUrls [dict create \
                    url $match \
                    status $code \
                    timestamp [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%SZ"]]
            }
        }
        
        http::cleanup $token
        
        if {[llength $flvUrls] > 0} {
            # Deduplicate URLs
            set uniqueUrls {}
            set seen {}
            foreach item $flvUrls {
                set url [dict get $item url]
                if {![info exists seen($url)]} {
                    set seen($url) 1
                    lappend uniqueUrls $item
                }
            }
            
            # Sort by quality indicator
            set sortedUrls [lsort -command compareQuality -decreasing $uniqueUrls]
            
            set streams {}
            set count 0
            foreach item $sortedUrls {
                if {$count >= 10} break
                lappend streams [dict merge $item [dict create quality [qualityKeyFromUrl [dict get $item url]]]]
                incr count
            }
            
            set result [dict create \
                success true \
                status "live" \
                method "playwright_simulation" \
                username $username \
                isLive true \
                streamCount [llength $streams] \
                streams $streams \
                url [dict get [lindex $sortedUrls 0] url] \
                timestamp [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%SZ"]]
                
            if {$jsonOutput} {
                puts [::json::write object {*}$result]
            } else {
                puts [dict get $result url]
            }
            return 0
        } else {
            set errorResult [dict create \
                success false \
                status "offline" \
                method "playwright_simulation" \
                username $username \
                isLive false \
                error "No stream URLs found - user may not be live" \
                timestamp [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%SZ"]]
                
            puts stderr [::json::write object {*}$errorResult]
            return 1
        }
    } else {
        set errorMsg "Failed to fetch page: $status ($code)"
        if {[info exists token]} {
            set errorMsg "$errorMsg - [http::data $token]"
            http::cleanup $token
        }
        
        set errorResult [dict create \
            error true \
            status "technical_error" \
            method "playwright_simulation" \
            message $errorMsg \
            timestamp [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%SZ"]]
            
        puts stderr [::json::write object {*}$errorResult]
        return 2
    }
}

proc compareQuality {a b} {
    set qualityA [getQualityFromUrl [dict get $a url]]
    set qualityB [getQualityFromUrl [dict get $b url]]
    return [expr {$qualityA - $qualityB}]
}

proc getQualityFromUrl {url} {
    if {[regexp {(\d+)p} $url -> match]} {
        return $match
    }
    return 0
}

# Execute main function and exit with appropriate code
set exitCode [getStreamUrl $username $jsonOutput]
exit $exitCode
