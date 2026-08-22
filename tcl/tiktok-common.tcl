#!/usr/bin/env tclsh
# tiktok-common.js — portiert nach tcl
# Quelle: javascript, OpenClaw@gateway2:skills/tiktok-live/scripts/tiktok-common.js
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

# Shared TikTok LIVE safety contract: handle normalization, per-CPU load
# preflight, exact account LIVE selectors, strict HTTPS TikTok-CDN FLV
# validation, and normalized extractor statuses.

package require json

set DEFAULT_MAX_LOAD_PER_CPU 1.5
set USERNAME_PATTERN {^[A-Za-z0-9._]{1,24}$}
set FAILURE_STATUSES [dict create offline 1 restricted 1 overloaded 1 dependency_missing 1 technical_error 1]

proc normalizeUsername {raw} {
    set username [string trim [regsub {^@+} $raw ""]]
    if {![regexp $::USERNAME_PATTERN $username]} {
        error "Invalid TikTok username; expected 1-24 letters, digits, dots, or underscores"
    }
    return $username
}

proc loadState {{env ""}} {
    if {$env eq ""} {
        array set env [array get ::env]
    }
    
    set cpuCount [expr {[llength [exec uname -p]] > 0 ? [llength [exec uname -p]] : 1}]
    set cpuCount [expr {$cpuCount < 1 ? 1 : $cpuCount}]
    
    set observed 0
    set maximum $::DEFAULT_MAX_LOAD_PER_CPU
    
    if {[info exists env(TIKTOK_TEST_LOAD_PER_CPU)]} {
        set observed [expr {double($env(TIKTOK_TEST_LOAD_PER_CPU))}]
    } else {
        # Get load average (first value)
        if {[catch {exec uptime} result]} {
            set observed 0
        } else {
            # Extract load average from uptime output
            if {[regexp {load averages?: ([0-9.]+)} $result -> load_val]} {
                set observed [expr {double($load_val) / $cpuCount}]
            } else {
                set observed 0
            }
        }
    }
    
    if {[info exists env(TIKTOK_MAX_LOAD_PER_CPU)]} {
        set maximum [expr {double($env(TIKTOK_MAX_LOAD_PER_CPU))}]
    }
    
    if {![string is double $observed] || ![string is double $maximum] || $maximum <= 0} {
        error "Invalid TikTok load configuration"
    }
    
    set overloaded [expr {$observed > $maximum}]
    return [dict create overloaded $overloaded loadPerCpu $observed maximum $maximum]
}

proc enforceLoadLimit {method} {
    set state [loadState]
    if {![dict get $state overloaded]} {
        return $state
    }
    
    set result [dict create \
        status "overloaded" \
        method $method \
        loadPerCpu [format "%.3f" [dict get $state loadPerCpu]] \
        maximum [dict get $state maximum] \
        message "Host is overloaded; retry on another node or later"]
    
    puts stderr [::json::encode $result]
    exit 75
}

proc liveHrefSelectors {username} {
    set href "/@$username/live"
    return [list "a\[href=\"$href\"\]" "a\[href^=\"$href?\"\]"]
}

proc isAllowedStreamUrl {value} {
    if {[catch {set url [::uri::resolve "http://" $value]}]} {
        return 0
    }
    
    if {![info exists url]} {
        return 0
    }
    
    # Parse URL manually since uri package might not be available
    if {[regexp {^https://([^/]+)(.*)$} $value -> hostname path]} {
        set hostname [string tolower $hostname]
        set path [string tolower $path]
        
        if {[string match "*.flv*" $path] || [string match "*flv*" $path]} {
            if {[regexp {(^|\.)tiktokcdn(-[a-z0-9-]+)?\.com$} $hostname]} {
                return 1
            }
        }
    }
    return 0
}

proc isSuccessfulStreamResponse {status value} {
    if {![string is integer $status] || $status < 200 || $status >= 300} {
        return 0
    }
    return [isAllowedStreamUrl $value]
}

# Order matters: longer keys first so `_uhd_60` never matches as `hd_60`/`hd`.
set QUALITY_URL_PATTERN {_uhd_60|hd_60|origin|hd|sd|ld|ao}

proc qualityKeyFromUrl {value} {
    if {[regexp {^https?://[^/]+(.*)$} $value -> path]} {
        set path [string tolower $path]
        foreach pattern {uhd_60 hd_60 origin hd sd ld ao} {
            if {[regexp "_${pattern}\\.(?:flv|m3u8)" $path]} {
                return $pattern
            }
        }
    }
    return {}
}

proc normalizeExtractorResult {value method username} {
    set technicalError [dict create \
        success 0 \
        status "technical_error" \
        method $method \
        username $username \
        message "invalid extractor result"]
    
    if {![dict size $value] || [llength $value] % 2 != 0} {
        return $technicalError
    }
    
    if {[dict exists $value success] && [dict get $value success]} {
        if {[dict get $value status] ne "live" || ![isAllowedStreamUrl [dict get $value url]]} {
            return $technicalError
        }
        dict set value success 1
        dict set value status "live"
        return $value
    }
    
    if {![dict exists $value success] || [dict get $value success]} {
        return $technicalError
    }
    
    set result [dict create]
    foreach {key val} $value {
        dict set result $key $val
    }
    dict set result success 0
    if {[dict exists $value status] && [dict exists $::FAILURE_STATUSES [dict get $value status]]} {
        dict set result status [dict get $value status]
    } else {
        dict set result status "technical_error"
    }
    dict set result method [expr {[dict exists $value method] && [dict get $value method] ne "" ? [dict get $value method] : $method}]
    dict set result username [expr {[dict exists $value username] && [dict get $value username] ne "" ? [dict get $value username] : $username}]
    dict unset result url
    dict unset result streams
    dict unset result allUrls
    return $result
}

proc classifyFinalFailure {results} {
    set statuses [dict create]
    foreach result $results {
        if {[dict exists $result status] && [dict exists $::FAILURE_STATUSES [dict get $result status]]} {
            dict set statuses [dict get $result status] 1
        }
    }
    
    if {[dict exists $statuses overloaded]} {return "overloaded"}
    if {[dict exists $statuses restricted]} {return "restricted"}
    if {[dict exists $statuses technical_error]} {return "technical_error"}
    if {[dict exists $statuses offline]} {return "offline"}
    if {[dict exists $statuses dependency_missing]} {return "dependency_missing"}
    return "technical_error"
}

proc exitCodeForResult {result} {
    if {[dict exists $result success] && [dict get $result success] && [dict get $result status] eq "live"} {
        return 0
    }
    if {[dict exists $result status] && [dict get $result status] eq "overloaded"} {
        return 75
    }
    if {[dict exists $result status] && ([dict get $result status] in {"offline" "restricted"})} {
        return 1
    }
    return 2
}

proc classifyDirectLiveState {args} {
    array set params $args
    set username $params(username)
    set currentPath $params(currentPath)
    set title [expr {[info exists params(title)] ? $params(title) : ""}]
    set bodyText [expr {[info exists params(bodyText)] ? $params(bodyText) : ""}]
    set successfulStreamResponse [expr {[info exists params(successfulStreamResponse)] ? $params(successfulStreamResponse) : 0}]
    
    set expectedPath "/@$username/live"
    if {$currentPath ne $expectedPath} {
        return [dict create status "offline" reason "target live page redirected"]
    }
    if {$successfulStreamResponse} {
        return [dict create status "live" reason "successful TikTok CDN stream response"]
    }
    
    set normalizedBody [string tolower [regsub -all {\s+} $bodyText " "]]
    set normalizedTitle [string tolower $title]
    set accountLiveTitle [string match "*(@[string tolower $username]) is live*" $normalizedTitle]
    
    set endedMarkers {
        "live has ended"
        "das live ist beendet"
        "live wurde beendet"
        "dieses live ist beendet"
        "stream has ended"
    }
    foreach marker $endedMarkers {
        if {[string match "*$marker*" $normalizedBody]} {
            return [dict create status "offline" reason "target live page reports ended stream"]
        }
    }
    
    set restrictionMarkers {
        "dieses live enthält themen, die von einigen als unangenehm empfunden werden könnten"
        "melde dich an, um das beste aus deiner tiktok-erfahrung herauszuholen"
        "bei tiktok anmelden"
        "melde dich an für das volle live-erlebnis"
        "melde dich an für das vollständige erlebnis"
        "this live may contain content that could be uncomfortable"
        "log in to tiktok"
        "log in for the full live experience"
        "mature content"
        "age-restricted"
        "viewer discretion"
    }
    if {$accountLiveTitle} {
        foreach marker $restrictionMarkers {
            if {[string match "*$marker*" $normalizedBody]} {
                return [dict create status "restricted" reason "target live page requires authentication"]
            }
        }
        return [dict create status "restricted" reason "target is live but no accessible media response was available"]
    }
    return [dict create status "offline" reason "no account-specific live signal"]
}

proc forcedOffline {method username} {
    if {![info exists ::env(TIKTOK_TEST_OFFLINE)] || $::env(TIKTOK_TEST_OFFLINE) ne "1"} {
        return 0
    }
    
    set result [dict create \
        success 0 \
        status "offline" \
        method $method \
        username $username \
        message "forced offline test mode"]
    
    puts stderr [::json::encode $result]
    return 1
}
