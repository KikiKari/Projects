#!/usr/bin/env tclsh
# background.js — portiert nach tcl
# Quelle: javascript, Projects@Telegram-Monitor:plugin/extension/background.js
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# Hintergrunddienst: prüft im Turnus und meldet den Livegang.
# Läuft ohne offenen Tab — der Browser weckt den Dienst über einen Alarm.

# Da Tcl kein direktes Equivalent zu WebExtensions hat, simulieren wir
# die Funktionalität mit einem selbstständig laufenden Skript, das sich
# regelmäßig selbst aufruft.

package require http
package require json
package require fileutil

set ALARM "ttc-check"
set apiBase "http://127.0.0.1:8765"
set configFile [file join $env(HOME) ".tiktok-companion-config.json"]
set stateFile [file join $env(HOME) ".tiktok-companion-state.json"]

proc readConfig {} {
    global configFile
    if {[file exists $configFile]} {
        set fp [open $configFile r]
        set data [read $fp]
        close $fp
        if {[catch {::json::json2dict $data} result]} {
            return [dict create user "" minutes 2 notify true lastLive false]
        }
        set cfg $result
        set user [dict get $cfg user]
        set minutes [dict get $cfg minutes]
        if {$minutes eq ""} { set minutes 2 }
        set notify [dict get $cfg notify]
        if {$notify eq ""} { set notify true }
        set lastLive [dict get $cfg lastLive]
        if {$lastLive eq ""} { set lastLive false }
        return [dict create user $user minutes $minutes notify $notify lastLive $lastLive]
    } else {
        return [dict create user "" minutes 2 notify true lastLive false]
    }
}

proc writeConfig {cfg} {
    global configFile
    set fp [open $configFile w]
    puts $fp [::json::dict2json $cfg]
    close $fp
}

proc readState {} {
    global stateFile
    if {[file exists $stateFile]} {
        set fp [open $stateFile r]
        set data [read $fp]
        close $fp
        if {[catch {::json::json2dict $data} result]} {
            return [dict create]
        }
        return $result
    } else {
        return [dict create]
    }
}

proc writeState {state} {
    global stateFile
    set fp [open $stateFile w]
    puts $fp [::json::dict2json $state]
    close $fp
}

proc fetchStatus {user} {
    global apiBase
    set url "$apiBase/status?user=$user"
    if {[catch {http::geturl $url} token]} {
        return ""
    }
    set status [http::status $token]
    set code [http::ncode $token]
    set body [http::data $token]
    http::cleanup $token
    
    if {$status eq "ok" && $code == 200} {
        if {[catch {::json::json2dict $body} result]} {
            return ""
        }
        return $result
    }
    return ""
}

proc showNotification {title message} {
    # Versuche verschiedene Benachrichtigungssysteme
    if {[catch {exec notify-send $title $message}]} {
        if {[catch {exec osascript -e "display notification \"$message\" with title \"$title\""}]} {
            puts stderr "Benachrichtigung: $title - $message"
        }
    }
}

proc openBrowser {url} {
    # Öffne URL im Standardbrowser
    if {[catch {exec xdg-open $url}]} {
        if {[catch {exec open $url}]} {
            if {[catch {exec start $url}]} {
                puts "Öffne im Browser: $url"
            }
        }
    }
}

proc check {} {
    set cfg [readConfig]
    set user [dict get $cfg user]
    if {$user eq ""} return
    
    set notify [dict get $cfg notify]
    set lastLive [dict get $cfg lastLive]
    
    set st [fetchStatus $user]
    if {$st eq "" || ![dict exists $st live]} return
    
    set isLive [dict get $st live]
    if {$isLive} {
        set isLiveBool true
    } else {
        set isLiveBool false
    }
    
    # Aktualisiere Status
    set newCfg [dict replace $cfg lastLive $isLiveBool]
    writeConfig $newCfg
    
    set state [readState]
    set newState [dict replace $state lastState $st]
    writeState $newState
    
    # Badge-Anzeige in der Konsole
    if {$isLiveBool} {
        puts -nonewline "\[LIVE\] @$user"
    } else {
        puts -nonewline "\[OFFLINE\] @$user"
    }
    flush stdout
    
    # Benachrichtigung bei Statuswechsel zu LIVE
    if {$isLiveBool && !$lastLive && $notify} {
        set title "@$user ist live"
        set msg "Die Sendung läuft."
        if {[dict exists $st title] && [dict get $st title] ne ""} {
            set msg [dict get $st title]
        }
        showNotification $title $msg
    }
}

proc scheduleAndCheck {} {
    set cfg [readConfig]
    set minutes [dict get $cfg minutes]
    
    # Führe sofortige Prüfung durch
    check
    
    # Plane nächsten Check ein, wenn minutes > 0
    if {$minutes > 0} {
        set delay [expr {max(1, $minutes) * 60}]
        after [expr {$delay * 1000}] scheduleAndCheck
    }
}

proc handleCommand {cmd} {
    switch $cmd {
        "check" {
            check
        }
        "reschedule" {
            scheduleAndCheck
            puts "Rescheduled checks"
        }
        "open-live" {
            set cfg [readConfig]
            set user [dict get $cfg user]
            if {$user ne ""} {
                openBrowser "https://www.tiktok.com/@$user/live"
            }
        }
        default {
            puts "Unknown command: $cmd"
        }
    }
}

# Hauptprogramm
if {$argc > 0} {
    handleCommand [lindex $argv 0]
} else {
    # Starte den Hintergrundservice
    puts "TikTok Companion Background Service gestartet..."
    scheduleAndCheck
    vwait forever
}
