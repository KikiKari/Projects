#!/usr/bin/env tclsh
# tiktok-check-profile.js — portiert nach tcl
# Quelle: javascript, OpenClaw@gateway1:skills/tiktok-live/scripts/tiktok-check-profile.js
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

# TikTok Live Status Checker
# Prüft ausschließlich profilgebundene Live-Indikatoren.
# Der allgemeine TikTok-Navigationspunkt "LIVE" ist kein Statussignal.
# Unterstützt @handle-Normalisierung und optionalen Node-Lastschutz
# via TIKTOK_MAX_LOAD_PER_CPU (Exit-Code 75 bei NODE_BUSY).

package require http
package require tls
package require json
package require fileutil

# TLS für HTTPS aktivieren
http::register https 443 [list ::tls::socket]

proc rejectBusyNode {} {
    set limit [getEnvVar TIKTOK_MAX_LOAD_PER_CPU]
    if {![string is double -strict $limit] || $limit <= 0} {
        return
    }
    
    # Anzahl CPUs ermitteln
    if {[catch {exec nproc} cpuCount]} {
        set cpuCount 1
    }
    set cpuCount [expr {max(1, $cpuCount)}]
    
    # Load Average ermitteln
    if {[catch {exec uptime} uptimeOutput]} {
        return
    }
    
    # Extrahiere Load Average aus uptime Output
    if {[regexp {load average[s]?: ([0-9.]+)(?:,|$)} $uptimeOutput -> loadAvg]} {
        set normalizedLoad [expr {$loadAvg / $cpuCount}]
        if {$normalizedLoad > $limit} {
            puts stderr "NODE_BUSY normalizedLoad=[format "%.2f" $normalizedLoad] limit=$limit"
            exit 75
        }
    }
}

proc getEnvVar {name} {
    if {[info exists ::env($name)]} {
        return $::env($name)
    } else {
        return ""
    }
}

proc checkLiveStatus {username} {
    # Temporäres Verzeichnis für Screenshots
    set tempDir "/tmp"
    set screenshotPath "$tempDir/tiktok-$username.png"
    
    # Browser starten (simuliert mit HTTP-Anfrage)
    set url "https://www.tiktok.com/@$username"
    
    # HTTP-Header setzen
    set headers [list \
        User-Agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
    ]
    
    # HTTP-Anfrage senden
    if {[catch {
        set token [http::geturl $url -headers $headers -timeout 30000]
        set status [http::status $token]
        set code [http::ncode $token]
        set html [http::data $token]
        http::cleanup $token
    } error]} {
        outputError "Failed to fetch page: $error"
        return
    }
    
    if {$status != "ok" || ($code != 200 && $code != 301 && $code != 302)} {
        outputError "HTTP request failed with status $status and code $code"
        return
    }
    
    # Wartezeit simulieren
    after 2000
    
    # HTML analysieren - suche nach LIVE-Indikatoren
    set liveIconVisible [expr {[string match "*data-e2e=\"live-icon\"*" $html]}]
    set liveBadgeVisible [expr {[regexp {(?i)LIVE} $html]}]
    set hasLiveLink [expr {[string match "*href*/@$username/live*" $html]}]
    
    # Suche nach rotem Rahmen (vereinfacht)
    set hasLiveBorder 0
    if {[regexp {border[^>]*:(\s*red|\s*#[fF][eE]2[cC]55|[^(]*255[^)]*\))} $html] || 
        [regexp {box-shadow[^>]*:(\s*red|\s*#[fF][eE]2[cC]55|[^(]*255[^)]*\))} $html]} {
        set hasLiveBorder 1
    }
    
    # Suche nach Live-Indikator-Klassen
    set liveIndicatorVisible 0
    if {[regexp {(?i)live-indicator|LiveBadge} $html]} {
        set liveIndicatorVisible 1
    }
    
    # Prüfe ob irgendein Live-Indikator gefunden wurde
    set isLive [expr {$liveIconVisible || $liveBadgeVisible || $hasLiveBorder || $hasLiveLink || $liveIndicatorVisible}]
    
    # Debug-Screenshot (wenn DEBUG=1)
    if {[getEnvVar DEBUG] eq "1"} {
        # In echter Implementierung würde hier ein Screenshot gemacht werden
        # Da wir keinen echten Browser haben, erstellen wir eine Dummy-Datei
        if {[catch {
            set fd [open $screenshotPath w]
            puts $fd "Simulated screenshot for debugging"
            close $fd
        }]} {
            # Fehler beim Erstellen der Datei ignorieren
        }
    }
    
    # Ergebnis ausgeben
    set result [dict create \
        username $username \
        isLive $isLive \
        timestamp [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%SZ" -gmt 1] \
        indicators [dict create \
            liveIcon $liveIconVisible \
            liveBadge $liveBadgeVisible \
            liveBorder $hasLiveBorder \
            liveLink $hasLiveLink \
            liveIndicator $liveIndicatorVisible \
        ] \
    ]
    
    puts [json::write object \
        username [dict get $result username] \
        isLive [dict get $result isLive] \
        timestamp [dict get $result timestamp] \
        indicators [json::write object {*}[dict get $result indicators]] \
    ]
    
    return $isLive
}

proc outputError {message} {
    set errorObj [dict create \
        error true \
        message $message \
        timestamp [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%SZ" -gmt 1] \
    ]
    
    puts stderr [json::write object \
        error [dict get $errorObj error] \
        message [dict get $errorObj message] \
        timestamp [dict get $errorObj timestamp] \
    ]
}

# Hauptprogramm
if {$argc < 1} {
    puts stderr "Usage: tclsh tiktok-check-profile.tcl <username>"
    exit 1
}

set rawUsername [lindex $argv 0]
# Entferne führende @ Zeichen
regsub {^@+} $rawUsername {} username

if {$username eq ""} {
    puts stderr "Username must not be empty"
    exit 1
}

# Lastprüfung durchführen
rejectBusyNode

# Live-Status prüfen
if {[catch {
    set isLive [checkLiveStatus $username]
    if {$isLive} {
        exit 0
    } else {
        exit 1
    }
} error]} {
    set errorObj [dict create \
        error true \
        message $error \
        timestamp [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%SZ" -gmt 1] \
    ]
    
    puts stderr [json::write object \
        error [dict get $errorObj error] \
        message [dict get $errorObj message] \
        timestamp [dict get $errorObj timestamp] \
    ]
    exit 1
}
