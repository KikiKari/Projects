#!/usr/bin/env tclsh8.6
# websearch-research.sh — portiert nach tcl
# Quelle: shell, OpenClaw@gateway2:scripts/websearch-research.sh
# Erzeugt: 2026-08-23 durch ABSTRACTIONS_MANAGER.py

# Web Search Script: Deep Research für Incidents
# Verwendung: ./websearch-research.tcl "Beschreibung des Problems"

package require http
package require json
package require tls

# TLS-Support aktivieren
http::register https 443 [list ::tls::socket]

# Hilfsfunktion zur URL-Kodierung
proc urlEncode {str} {
    return [string map {" " "%20" "!" "%21" "\"" "%22" "#" "%23" "\$" "%24" 
                        "%" "%25" "&" "%26" "'" "%27" "(" "%28" ")" "%29" 
                        "*" "%2A" "+" "%2B" "," "%2C" "/" "%2F" ":" "%3A" 
                        ";" "%3B" "<" "%3C" "=" "%3D" ">" "%3E" "?" "%3F" 
                        "@" "%40" "[" "%5B" "\\" "%5C" "]" "%5D" "^" "%5E" 
                        "`" "%60" "{" "%7B" "|" "%7C" "}" "%7D" "~" "%7E"} $str]
}

# Hauptvariablen setzen
set QUERY [lindex $argv 0]
set OUTPUT_DIR [expr {[llength $argv] > 1 ? [lindex $argv 1] : "./research"}]

if {$QUERY eq ""} {
    puts "Verwendung: [info script] \"Problem Beschreibung\" \[OUTPUT_DIR\]"
    exit 1
}

# Ausgabeverzeichnis erstellen
file mkdir $OUTPUT_DIR

# Zeitstempel für Dateiname generieren
set timestamp [clock format [clock seconds] -format "%Y%m%d_%H%M%S"]
set OUTPUT_FILE "${OUTPUT_DIR}/incident_${timestamp}.md"

# Basisdaten in Datei schreiben
set fh [open $OUTPUT_FILE w]
puts $fh "# Incident Research"
puts $fh "Datum: [clock format [clock seconds]]"
puts $fh "Query: $QUERY"
puts $fh ""
close $fh

# API-Key aus Umgebungsvariable holen
set OPENROUTER_API_KEY [expr {[info exists ::env(OPENROUTER_API_KEY)] ? $::env(OPENROUTER_API_KEY) : ""}]
if {$OPENROUTER_API_KEY eq ""} {
    error "OPENROUTER_API_KEY Umgebungsvariable muss gesetzt sein"
}

# Funktion zum HTTP-POST mit JSON-Daten
proc doPost {url headers jsonData} {
    set token [http::geturl $url -headers $headers -query $jsonData -type "application/json"]
    set response [http::data $token]
    http::cleanup $token
    return $response
}

# 1. EXA für schnelle Recherche
puts "## 1. Schnelle Recherche (EXA)"
set fh [open $OUTPUT_FILE a]
puts $fh "## 1. Schnelle Recherche (EXA)"

set exa_data [subst {{
    "model": "openai/gpt-5.4-mini",
    "messages": [{"role": "user", "content": "$QUERY"}],
    "plugins": [{"id": "web", "engine": "exa", "max_results": 5}]
}}]

set headers [dict create Authorization "Bearer $OPENROUTER_API_KEY" Content-Type "application/json"]
set response [doPost https://openrouter.ai/api/v1/chat/completions $headers $exa_data]

# Antwort parsen und in Datei schreiben
if {[catch {::json::json2dict $response} parsed]} {
    set content "Keine Ergebnisse"
} else {
    # Extrahiere content aus der verschachtelten Struktur
    if {[dict exists $parsed choices 0 message content]} {
        set content [dict get $parsed choices 0 message content]
    } else {
        set content "Keine Ergebnisse"
    }
}
puts $fh $content
puts $fh ""
puts $fh "---"
close $fh

# 2. Verifizierte Quellen (Perplexity)
puts "## 2. Verifizierte Fakten (Perplexity)"
set fh [open $OUTPUT_FILE a]
puts $fh "## 2. Verifizierte Fakten (Perplexity)"

set perplexity_data [subst {{
    "model": "perplexity/sonar:online",
    "messages": [{"role": "user", "content": "${QUERY} troubleshooting"}]
}}]

set response2 [doPost https://openrouter.ai/api/v1/chat/completions $headers $perplexity_data]

# Antwort parsen und in Datei schreiben
if {[catch {::json::json2dict $response2} parsed2]} {
    set content2 "Keine Ergebnisse"
} else {
    # Extrahiere content aus der verschachtelten Struktur
    if {[dict exists $parsed2 choices 0 message content]} {
        set content2 [dict get $parsed2 choices 0 message content]
    } else {
        set content2 "Keine Ergebnisse"
    }
}
puts $fh $content2
puts $fh ""
puts $fh "Gespeichert in: $OUTPUT_FILE"
close $fh

puts "Gespeichert in: $OUTPUT_FILE"
