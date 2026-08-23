#!/usr/bin/env tclsh8.6
# websearch-monitor.sh — portiert nach tcl
# Quelle: shell, OpenClaw@gateway1:scripts/websearch-monitor.sh
# auch in: OpenClaw@gateway2:scripts/websearch-monitor.sh
# Erzeugt: 2026-08-23 durch ABSTRACTIONS_MANAGER.py

# Web Search Script: Server-Monitoring mit Tavily
# Verwendung: ./websearch-monitor.tcl [TOPIC]

package require http
package require json

# Hilfsfunktion zur Prüfung, ob ein Kommando existiert
proc command_exists {cmd} {
    set result [auto_execok $cmd]
    return [expr {$result ne ""}]
}

# Hilfsfunktion zur Ausführung eines Kommandos
proc exec_cmd {args} {
    if {[catch {exec {*}$args} result]} {
        return ""
    }
    return $result
}

# Topic aus Kommandozeilenargument oder Standardwert
if {$argc > 0} {
    set TOPIC [lindex $argv 0]
} else {
    set TOPIC "Linux kernel security updates"
}

# Security-News prüfen
puts "Prüfe: $TOPIC"

# Versuche zuerst Tavily CLI
if {[command_exists "tvly"]} {
    if {[catch {
        set result [exec tvly search $TOPIC \
            --topic news \
            --time-range week \
            --max-results 5 \
            --include-answer advanced]
    } error]} {
        set result ""
    }
    
    if {$result ne ""} {
        # Parse JSON Antwort
        if {[catch {
            set json_data [::json::json2dict $result]
            if {[dict exists $json_data answer]} {
                set answer [dict get $json_data answer]
                if {$answer ne "" && $answer ne "null"} {
                    puts $answer
                } else {
                    puts "Keine Zusammenfassung verfügbar"
                }
            } else {
                puts "Keine Zusammenfassung verfügbar"
            }
        } error]} {
            puts "Keine Zusammenfassung verfügbar"
        }
    } else {
        puts "Keine Zusammenfassung verfügbar"
    }
} else {
    # Fallback zu einfacher Web-Suche
    set encoded_topic [string map {{" "} +} $TOPIC]
    set url "http://localhost:8888/search?q=${encoded_topic}&format=json"
    
    if {[catch {
        set token [http::geturl $url -timeout 5000]
        set status [http::status $token]
        if {$status eq "ok"} {
            set data [http::data $token]
            http::cleanup $token
            
            # Parse JSON Ergebnisse
            if {[catch {
                set json_data [::json::json2dict $data]
                if {[dict exists $json_data results]} {
                    set results [dict get $json_data results]
                    set count 0
                    foreach item $results {
                        if {$count >= 3} break
                        if {[dict exists $item title] && [dict exists $item url]} {
                            set title [dict get $item title]
                            set url [dict get $item url]
                            puts "$title\n$url"
                            incr count
                        }
                    }
                }
            } error]} {
                puts "SearXNG nicht verfügbar"
            }
        } else {
            http::cleanup $token
            puts "SearXNG nicht verfügbar"
        }
    } error]} {
        puts "SearXNG nicht verfügbar"
    }
}
