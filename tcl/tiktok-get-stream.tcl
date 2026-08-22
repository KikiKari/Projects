#!/usr/bin/env tclsh8.6
# tiktok-get-stream.js — portiert nach tcl
# Quelle: javascript, OpenClaw@gateway1:skills/tiktok-live/scripts/tiktok-get-stream.js
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

# TikTok Stream URL Extractor
# Führt zuerst den profilgebundenen Status-Checker aus.
# Nur bei bestätigtem Live-Status werden FLV-Netzwerk-URLs erfasst.
# Offline wird keine Stream-URL ausgegeben.

package require json
package require http
package require tls

# TLS-Support für HTTP aktivieren
http::register https 443 [list ::tls::socket -autoservername true]

# Hilfsfunktion zur Ausführung von externen Programmen
proc exec_with_timeout {cmd timeout} {
    set chan [open "|$cmd" r]
    fconfigure $chan -buffering none -blocking 0
    set data ""
    set start [clock milliseconds]
    
    while {[clock milliseconds] - $start < $timeout} {
        if {[eof $chan]} break
        if {[gets $chan line] >= 0} {
            append data "$line\n"
        } else {
            after 100
        }
    }
    
    catch {close $chan}
    return $data
}

# Busy Node Prüfung
proc rejectBusyNode {} {
    global env
    if {![info exists env(TIKTOK_MAX_LOAD_PER_CPU)]} return
    
    set limit [expr {$env(TIKTOK_MAX_LOAD_PER_CPU) + 0}]
    if {$limit <= 0} return
    
    # Anzahl CPUs ermitteln
    set cpuCount [llength [exec cat /proc/cpuinfo | grep "^processor" | wc -l]]
    if {$cpuCount == 0} {set cpuCount 1}
    
    # Load Average lesen
    set loadAvg [lindex [split [exec cat /proc/loadavg] " "] 0]
    set normalizedLoad [expr {$loadAvg / $cpuCount}]
    
    if {$normalizedLoad > $limit} {
        puts stderr "NODE_BUSY normalizedLoad=[format "%.2f" $normalizedLoad] limit=$limit"
        exit 75
    }
}

# Live Status prüfen
proc verifyLiveStatus {username} {
    set scriptDir [file dirname [info script]]
    set checkerPath [file join $scriptDir "tiktok-check-profile.js"]
    
    if {![file exists $checkerPath]} {
        return false
    }
    
    set cmd "node $checkerPath $username"
    set output [exec_with_timeout $cmd 60000]
    
    if {[string length $output] > 0} {
        if {[catch {::json::json2dict $output} result]} {
            return false
        }
        array set data $result
        if {[info exists data(isLive)] && $data(isLive) eq "true"} {
            return true
        }
    }
    return false
}

# Stream URL extrahieren
proc getStreamUrl {username} {
    # Zuerst Live Status prüfen
    if {![verifyLiveStatus $username]} {
        set response [dict create \
            username $username \
            isLive false \
            error "User is not currently live." \
            timestamp [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%SZ"]]
        puts stderr [::json::dict2json $response]
        return false
    }
    
    # Da Tcl keinen Headless-Browser wie Playwright hat, simulieren wir das Verhalten
    # durch direkte HTTP-Anfragen an die TikTok-API
    
    set flvUrls {}
    set userAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    
    # TikTok Live-Seite aufrufen
    set url "https://www.tiktok.com/@$username/live"
    
    if {[catch {
        set token [http::geturl $url -headers [list User-Agent $userAgent]]
        set status [http::status $token]
        set ncode [http::ncode $token]
        
        if {$status eq "ok" && $ncode == 200} {
            set html [http::data $token]
            
            # Suchen nach möglichen FLV-URLs im HTML
            set patterns {
                {(https?://[^"]*\.flv[^"]*)}
                {(https?://[^"]*pull-flv[^"]*)}
                {(https?://[^"]*/pull/[^"]*)}
            }
            
            foreach pattern $patterns {
                set matches [regexp -all -inline $pattern $html]
                foreach {- url} $matches {
                    lappend flvUrls [dict create \
                        url $url \
                        type "media" \
                        timestamp [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%SZ"]]
                }
            }
        }
        http::cleanup $token
    } error]} {
        set response [dict create \
            error true \
            message $error \
            timestamp [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%SZ"]]
        puts stderr [::json::dict2json $response]
        return false
    }
    
    if {[llength $flvUrls] > 0} {
        # URLs deduplizieren
        set uniqueUrls {}
        set seen {}
        foreach urlDict $flvUrls {
            set url [dict get $urlDict url]
            if {$url ni $seen} {
                lappend seen $url
                lappend uniqueUrls $urlDict
            }
        }
        
        # Nach Qualität sortieren
        proc getQuality {url} {
            set suffixRanks [list \
                [list "_origin." 600] \
                [list "_uhd_60." 550] \
                [list "_uhd." 540] \
                [list "_hd_60." 500] \
                [list "_hd." 450] \
                [list "_sd." 350] \
                [list "_ld." 250]]
                
            foreach {suffix rank} $suffixRanks {
                if {[string first $suffix $url] != -1} {
                    return $rank
                }
            }
            
            if {[regexp {(\d+)p} $url -> quality]} {
                return $quality
            }
            return 0
        }
        
        set sortedUrls [lsort -decreasing -command {getQuality [dict get $a url]} -command {getQuality [dict get $b url]} $uniqueUrls]
        
        set firstUrl [dict get [lindex $sortedUrls 0] url]
        set response [dict create \
            username $username \
            isLive true \
            streamCount [llength $sortedUrls] \
            streams $sortedUrls \
            vlcCommand "vlc \"$firstUrl\"" \
            timestamp [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%SZ"]]
            
        puts [::json::dict2json $response]
        return true
    } else {
        set response [dict create \
            username $username \
            isLive false \
            error "No stream URLs found - user may not be live" \
            timestamp [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%SZ"]]
        puts stderr [::json::dict2json $response]
        return false
    }
}

# Hauptprogramm
proc main {} {
    global argv
    
    if {[llength $argv] == 0} {
        puts stderr "Usage: tclsh tiktok-get-stream.tcl <username>"
        exit 1
    }
    
    set rawUsername [lindex $argv 0]
    set username [regsub {^@+} $rawUsername ""]
    
    if {$username eq ""} {
        puts stderr "Username must not be empty"
        exit 1
    }
    
    rejectBusyNode
    
    set success [getStreamUrl $username]
    if {$success} {
        exit 0
    } else {
        exit 1
    }
}

main
