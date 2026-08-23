#!/usr/bin/env tclsh
# websearch-crawl.sh — portiert nach tcl
# Quelle: shell, OpenClaw@gateway1:scripts/websearch-crawl.sh
# auch in: OpenClaw@gateway2:scripts/websearch-crawl.sh
# Erzeugt: 2026-08-23 durch ABSTRACTIONS_MANAGER.py

# Web Search Script: Website Crawling mit Firecrawl
# Verwendung: tclsh websearch-crawl.tcl <URL> [OUTPUT_DIR]

package require http
package require json
package require fileutil

# Hilfsfunktion für JSON-Parsing
proc get_json_value {json key} {
    if {[dict exists $json $key]} {
        return [dict get $json $key]
    } else {
        return ""
    }
}

# Kommandozeilenargumente verarbeiten
if {$argc < 1} {
    puts "Verwendung: [info script] <URL> \[OUTPUT_DIR\]"
    exit 1
}

set WEBSITE_URL [lindex $argv 0]
set OUTPUT_DIR [expr {$argc > 1 ? [lindex $argv 1] : "./crawled"}]

# API-Key ermitteln
set FIRECRAWL_API_KEY $::env(FIRECRAWL_API_KEY)
if {![info exists FIRECRAWL_API_KEY] || $FIRECRAWL_API_KEY eq ""} {
    set configFile "$env(HOME)/.openclaw/openclaw.env"
    if {[file exists $configFile]} {
        set fd [open $configFile r]
        set content [read $fd]
        close $fd
        foreach line [split $content "\n"] {
            if {[string match "OPENROUTER*" $line]} {
                regexp {\"([^\"]*)\"} $line -> key
                set FIRECRAWL_API_KEY $key
                break
            }
        }
    }
}

if {$FIRECRAWL_API_KEY eq ""} {
    puts "Fehler: FIRECRAWL_API_KEY nicht gefunden"
    exit 1
}

# Ausgabeverzeichnis erstellen
file mkdir $OUTPUT_DIR
puts "Crawling $WEBSITE_URL..."

# HTTP-Header vorbereiten
set headers [list Authorization "Bearer $FIRECRAWL_API_KEY" Content-Type "application/json"]

# Crawl starten
set postData "{\n  \"url\": \"$WEBSITE_URL\",\n  \"limit\": 100,\n  \"scrapeOptions\": {\"formats\": \[\"markdown\"\]}\n}"

set token [http::geturl "https://api.firecrawl.dev/v1/crawl" -headers $headers -method POST -query $postData]
set response [http::data $token]
http::cleanup $token

# Antwort parsen
if {[catch {set crawlData [::json::json2dict $response]}]} {
    puts "Fehler beim Parsen der Antwort:"
    puts $response
    exit 1
}

set CRAWL_ID [get_json_value $crawlData "id"]
if {$CRAWL_ID eq ""} {
    puts "Fehler: Crawl konnte nicht gestartet werden"
    puts $response
    exit 1
}

puts "Crawl ID: $CRAWL_ID"

# Status prüfen
while {1} {
    set token [http::geturl "https://api.firecrawl.dev/v1/crawl/$CRAWL_ID" -headers $headers]
    set statusResponse [http::data $token]
    http::cleanup $token
    
    if {[catch {set statusData [::json::json2dict $statusResponse]}]} {
        puts "Fehler beim Parsen des Status:"
        puts $statusResponse
        exit 1
    }
    
    set STATUS [get_json_value $statusData "status"]
    if {$STATUS eq ""} {
        set STATUS "unknown"
    }
    
    puts "Status: $STATUS"
    
    if {$STATUS eq "completed"} {
        set timestamp [clock format [clock seconds] -format "%Y%m%d"]
        set outputFile "$OUTPUT_DIR/${timestamp}_crawl.json"
        set fd [open $outputFile w]
        puts $fd $statusResponse
        close $fd
        puts "Gespeichert in $OUTPUT_DIR"
        break
    } elseif {$STATUS eq "failed"} {
        puts "Crawl fehlgeschlagen"
        exit 1
    }
    
    # 5 Sekunden warten
    after 5000
}
