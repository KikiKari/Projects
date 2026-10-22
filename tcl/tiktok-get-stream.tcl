#!/usr/bin/env tclsh
# tiktok-get-stream.js — portiert nach tcl
# Quelle: javascript, OpenClaw@gateway2:skills/tiktok-live-mon/scripts/tiktok-get-stream.js
# Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

# Enhanced TikTok LIVE URL extractor.
#
# Order: Playwright response interception, streamlink, then yt-dlp. Every
# result is schema-normalized and must be an allowed HTTPS TikTok-CDN FLV
# URL. Fallbacks use fixed argument arrays, bounded output, timeouts, and
# process-group cleanup.
#
# Exit 0 = URL, 1 = offline/restricted/no URL, 2 = dependency/technical
# failure, 75 = overloaded before Playwright startup.

package require Tcl 8.6
package require http
package require json
package require fileutil

set FALLBACK_TIMEOUT_MS 45000
set FALLBACK_MAX_OUTPUT [expr {1024 * 1024}]

proc log {message} {
    puts stderr $message
}

proc runFallback {scriptPath args} {
    global FALLBACK_TIMEOUT_MS FALLBACK_MAX_OUTPUT
    
    set cmd [list bash $scriptPath {*}$args]
    set child [open "|$cmd" r+]
    fconfigure $child -buffering none
    
    set stdout ""
    set stderr ""
    set overflow false
    
    # Set up non-blocking read with timeout
    fconfigure $child -blocking 0
    set start_time [clock milliseconds]
    
    while {[expr {[clock milliseconds] - $start_time}] < $FALLBACK_TIMEOUT_MS} {
        if {[eof $child]} break
        
        if {[gets $child line] >= 0} {
            append stdout "$line\n"
            if {[string length $stdout] > $FALLBACK_MAX_OUTPUT} {
                set overflow true
                break
            }
        } elseif {[catch {flush $child}]} {
            break
        } else {
            after 100
        }
    }
    
    # Try to get any remaining stderr
    if {[info commands chan] ne ""} {
        # Tcl 8.6 has chan command
        if {[chan pending input $child] > 0} {
            set remaining [read $child]
            append stderr $remaining
        }
    }
    
    # Kill the process if still running
    if {[catch {exec kill [pid $child]]}]} {
        catch {exec kill -9 [pid $child]]
    }
    
    if {$overflow} {
        return [dict create code 2 stdout "" stderr "fallback output exceeded limit"]
    } elseif {[expr {[clock milliseconds] - $start_time}] >= $FALLBACK_TIMEOUT_MS} {
        return [dict create code 2 stdout $stdout stderr "[string trim $stderr]\nfallback timeout"]
    } else {
        set status [catch {close $child} result]
        set exit_code 2
        if {!$status} {
            set exit_code 0
        } elseif {[regexp {child exited with code (\d+)} $result match code]} {
            set exit_code $code
        }
        return [dict create code $exit_code stdout [string trim $stdout] stderr [string trim $stderr]]
    }
}

proc parseFallbackResult {method username execution} {
    foreach text [list [dict get $execution stdout] [dict get $execution stderr]] {
        if {$text eq ""} continue
        if {[catch {::json::json2dict $text} value]} continue
        if {[dict size $value] > 0} {
            return [normalizeExtractorResult $value $method $username]
        }
    }
    
    set code [dict get $execution code]
    set stderr [dict get $execution stderr]
    set message [expr {$stderr ne "" ? $stderr : "fallback exited $code"}]
    if {$code == 75} {
        set status "overloaded"
    } else {
        set status "technical_error"
    }
    
    return [normalizeExtractorResult \
        [dict create success false status $status method $method username $username message $message] \
        $method $username]
}

proc playwrightPreflight {} {
    # In Tcl we can't easily check Playwright installation
    # This would need to be implemented based on actual system setup
    return [dict create ok true executable "/usr/bin/chromium-browser"]
}

proc humanDelay {{min 2000} {max 4000}} {
    return [expr {int(rand() * ($max - $min + 1)) + $min}]
}

# Placeholder functions that would need full implementation
proc handlePopups {page} {
    # This would require a web automation library for Tcl
    # For now just return false to indicate no popups handled
    return false
}

proc checkRestrictions {page} {
    # Would check for restriction texts
    return [dict create restricted false reason ""]
}

proc isSuccessfulStreamResponse {status url} {
    # Check if response is a successful stream response
    return [expr {$status == 200 && [string match "*.flv*" $url]}]
}

proc normalizeExtractorResult {value method username} {
    # Normalize the extractor result format
    # This is a simplified version - full implementation needed
    return $value
}

proc normalizeUsername {username} {
    # Normalize the username
    return [string trim $username "@ "]
}

proc qualityKeyFromUrl {url} {
    # Extract quality key from URL
    # Simplified implementation
    if {[string match "*_origin.flv*" $url]} {
        return "original"
    } elseif {[string match "*_uhd_60.flv*" $url]} {
        return "1080p60"
    } elseif {[string match "*_hd_60.flv*" $url]} {
        return "720p60"
    } elseif {[string match "*_hd.flv*" $url]} {
        return "720p"
    } elseif {[string match "*_sd.flv*" $url]} {
        return "540p"
    } elseif {[string match "*_ld.flv*" $url]} {
        return "360p"
    } else {
        return "unknown"
    }
}

proc classifyFinalFailure {results} {
    # Classify final failure based on results
    foreach result $results {
        if {[dict exists $result status] && [dict get $result status] eq "restricted"} {
            return "restricted"
        }
    }
    return "technical_error"
}

proc exitCodeForResult {result} {
    # Determine exit code based on result
    if {[dict get $result success]} {
        return 0
    } elseif {[dict exists $result status]} {
        set status [dict get $result status]
        if {$status eq "offline" || $status eq "restricted"} {
            return 1
        } elseif {$status eq "overloaded"} {
            return 75
        }
    }
    return 2
}

proc enforceLoadLimit {method} {
    # Placeholder for load limiting
}

proc forcedOffline {method username} {
    # Placeholder for checking if forced offline
    return false
}

# Playwright-basierte FLV-Extraktion (stub implementation)
proc extractWithPlaywright {username qualityPreference} {
    log "Playwright not fully implemented in Tcl version"
    return [dict create success false method "playwright" status "technical_error" \
        error "Playwright implementation not available in Tcl"]
}

# Streamlink Fallback
proc tryStreamlink {username quality} {
    set scriptPath [file join [file dirname $::argv0] extraction-methods extract-tiktok-streamlink.sh]
    if {![file exists $scriptPath]} {
        return [dict create success false method "streamlink" status "technical_error" \
            error "Script $scriptPath not found"]
    }
    
    set execution [runFallback $scriptPath $username $quality --json]
    return [parseFallbackResult "streamlink" $username $execution]
}

# yt-dlp Fallback
proc tryYtDlp {username quality} {
    set scriptPath [file join [file dirname $::argv0] extraction-methods extract-tiktok-yt-dlp.sh]
    if {![file exists $scriptPath]} {
        return [dict create success false method "yt-dlp" status "technical_error" \
            error "Script $scriptPath not found"]
    }
    
    # Map quality to yt-dlp format
    array set qualityMap {
        original "hls-origin/hls-pull/hls-uhd_60/hls-hd_60/hls-hd/hls-sd/hls-ld/flv-origin/flv-hd/flv-ld"
        1080p60 "hls-uhd_60/hls-hd_60/hls-hd/hls-sd/hls-ld/flv-hd/flv-ld"
        720p60 "hls-hd_60/hls-hd/hls-sd/hls-ld/flv-hd/flv-ld"
        720p "hls-hd/hls-sd/hls-ld/flv-hd/flv-sd/flv-ld"
        540p "hls-sd/hls-ld/flv-sd/flv-ld"
        360p "hls-ld/flv-ld"
        auto "hls-origin/hls-hd/hls-sd/hls-ld/hls-pull/flv-origin/flv-hd/flv-ld"
    }
    
    if {![info exists qualityMap($quality)]} {
        set ytFormat $qualityMap(auto)
    } else {
        set ytFormat $qualityMap($quality)
    }
    
    set execution [runFallback $scriptPath $username $ytFormat --json]
    return [parseFallbackResult "yt-dlp" $username $execution]
}

# Hauptfunktion mit Fallback-Kette
proc getStreamUrl {username {qualityPreference "auto"}} {
    set timestamp [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%SZ"]
    
    # --- 1. Playwright ---
    log "\[1/3\] Trying Playwright for @$username..."
    set pwResult [extractWithPlaywright $username $qualityPreference]
    if {[dict get $pwResult success]} {
        dict set pwResult timestamp $timestamp
        return $pwResult
    }
    if {[dict exists $pwResult status] && ([dict get $pwResult status] eq "restricted" || 
                                          [dict get $pwResult status] eq "overloaded")} {
        return $pwResult
    }
    set reason [expr {[dict exists $pwResult reason] ? [dict get $pwResult reason] : 
                     ([dict exists $pwResult error] ? [dict get $pwResult error] : "failed")}]
    log "Playwright result: $reason"

    # --- 2. Streamlink (bounded fallback; output is normalized below) ---
    log "\[2/3\] Trying streamlink for @$username (quality: $qualityPreference)..."
    set slResult [tryStreamlink $username $qualityPreference]
    if {[dict get $slResult success]} {
        return $slResult
    }
    if {[dict exists $slResult status] && ([dict get $slResult status] eq "restricted" || 
                                           [dict get $slResult status] eq "overloaded")} {
        return $slResult
    }
    set slReason [expr {[dict exists $slResult message] ? [dict get $slResult message] : 
                        ([dict exists $slResult error] ? [dict get $slResult error] : "failed")}]
    log "Streamlink result: $slReason"

    # --- 3. yt-dlp (final bounded fallback; output is normalized below) ---
    log "\[3/3\] Trying yt-dlp for @$username..."
    set ytResult [tryYtDlp $username $qualityPreference]
    if {[dict get $ytResult success]} {
        return $ytResult
    }
    if {[dict exists $ytResult status] && ([dict get $ytResult status] eq "restricted" || 
                                           [dict get $ytResult status] eq "overloaded")} {
        return $ytResult
    }
    set ytReason [expr {[dict exists $ytResult message] ? [dict get $ytResult message] : 
                       ([dict exists $ytResult error] ? [dict get $ytResult error] : "failed")}]
    log "yt-dlp result: $ytReason"

    # --- Alle fehlgeschlagen ---
    set status [classifyFinalFailure [list $pwResult $slResult $ytResult]]
    return [dict create \
        success false \
        status $status \
        username $username \
        message "All extraction methods failed (Playwright, streamlink, yt-dlp)." \
        playwrightReason [expr {[dict exists $pwResult reason] ? [dict get $pwResult reason] : 
                               [dict exists $pwResult error] ? [dict get $pwResult error] : ""}] \
        streamlinkReason $slReason \
        ytdlpReason $ytReason \
        timestamp $timestamp]
}

# --- CLI ---
if {$argc < 1} {
    puts stderr "Usage: tclsh tiktok-get-stream.tcl <username> \[quality: original|1080p60|720p60|720p|540p|360p|auto\] \[--json\]"
    exit 1
}

set cliUsername ""
set argvList $argv

# Find username (first non-option argument)
foreach arg $argvList {
    if {![string match "--*" $arg]} {
        set cliUsername $arg
        break
    }
}

if {$cliUsername eq ""} {
    puts stderr "Error: No username provided"
    exit 64
}

# Normalize username
if {[catch {set cliUsername [normalizeUsername $cliUsername]} errorMsg]} {
    puts stderr $errorMsg
    exit 64
}

# Check load limits and offline status
enforceLoadLimit "playwright_streamlink_ytdlp"
if {[forcedOffline "playwright_streamlink_ytdlp" $cliUsername]} {
    exit 1
}

# Parse arguments
set cliQuality "auto"
set cliJson false
set foundUsername false

foreach arg $argvList {
    if {!$foundUsername && (![string match "--*" $arg])} {
        set foundUsername true
        continue
    } elseif {$foundUsername && (![string match "--*" $arg]) && $cliQuality eq "auto"} {
        set cliQuality $arg
    } elseif {$arg eq "--json"} {
        set cliJson true
    }
}

# Validate quality
set validQualities [list "original" "1080p60" "720p60" "720p" "540p" "360p" "auto"]
if {$cliQuality ni $validQualities} {
    puts stderr "Invalid quality; expected original, 1080p60, 720p60, 720p, 540p, 360p, or auto"
    exit 64
}

# Run main function
if {[catch {
    set result [getStreamUrl $cliUsername $cliQuality]
    if {$cliJson} {
        puts [::json::dict2json $result]
    } else {
        if {[dict get $result success]} {
            puts [dict get $result url]
        } else {
            puts stderr [dict get $result message]
        }
    }
    set exitCode [exitCodeForResult $result]
    exit $exitCode
} error]} {
    puts stderr "Unhandled error: $error"
    exit 2
}
