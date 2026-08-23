#!/usr/bin/env tclsh8.6
# websearch-research.sh — portiert nach tcl
# Quelle: shell, OpenClaw@gateway1:scripts/websearch-research.sh
# Erzeugt: 2026-08-23 durch ABSTRACTIONS_MANAGER.py

# Web Search Script: Deep Research für Incidents
# Verwendung: tclsh websearch-research.tcl "Beschreibung des Problems"

package require http
package require json
package require tls

# Hilfsfunktion zur URL-Kodierung
proc urlEncode {str} {
    return [string map {" " "%20" "\n" "%0A" "\"" "%22" "#" "%23" "%" "%25" 
                        "&" "%26" "+" "%2B" "/" "%2F" "?" "%3F" "\\" "%5C"} $str]
}

# Hauptvariablen setzen
set QUERY [lindex $argv 0]
set OUTPUT_DIR [expr {[llength $argv] > 1 ? [lindex $argv 1] : "./research"}]

if {$QUERY eq ""} {
    puts "Verwendung: [info script] \"Problem Beschreibung\" \[OUTPUT_DIR\]"
    exit 1
}

# TLS-Support aktivieren
http::register https 443 [list ::tls::socket]

# Ausgabeverzeichnis erstellen
file mkdir $OUTPUT_DIR

# Zeitstempel für Dateinamen generieren
set timestamp [clock format [clock seconds] -format "%Y%m%d_%H%M%S"]
set OUTPUT_FILE "${OUTPUT_DIR}/incident_${timestamp}.md"

# Basisdaten in die Ausgabedatei schreiben
set fh [open $OUTPUT_FILE w]
puts $fh "# Incident Research"
puts $fh "Datum: [clock format [clock seconds]]"
puts $fh "Query: $QUERY"
puts $fh ""
close $fh

# Funktion zum Hinzufügen von Inhalten zur Markdown-Datei
proc appendToFile {filename content} {
    set fh [open $filename a]
    puts $fh $content
    close $fh
}

# API-Key aus Umgebungsvariable holen
if {[info exists ::env(OPENROUTER_API_KEY)]} {
    set API_KEY $::env(OPENROUTER_API_KEY)
} else {
    puts stderr "Fehler: OPENROUTER_API_KEY Umgebungsvariable nicht gesetzt"
    exit 1
}

# 1. EXA für schnelle Recherche
appendToFile $OUTPUT_FILE "## 1. Schnelle Recherche (EXA)"
appendToFile $OUTPUT_FILE ""

set exa_data "{\"model\": \"openai/gpt-5.6-terra\", \"messages\": \[{\"role\": \"user\", \"content\": \"$QUERY\"}\], \"plugins\": \[{\"id\": \"web\", \"engine\": \"exa\", \"max_results\": 5}\]}"

set exa_token [http::geturl "https://openrouter.ai/api/v1/chat/completions" \
    -headers [list Authorization "Bearer $API_KEY" Content-Type "application/json"] \
    -query $exa_data \
    -method POST]

set exa_response ""
if {![catch {http::data $exa_token} exa_result]} {
    if {[info complete $exa_result]} {
        if {[dict exists $exa_result choices 0 message content]} {
            set exa_response [dict get $exa_result choices 0 message content]
        } else {
            set exa_response "Keine Ergebnisse"
        }
    } else {
        set exa_response "Keine Ergebnisse"
    }
} else {
    set exa_response "Keine Ergebnisse"
}

appendToFile $OUTPUT_FILE $exa_response
appendToFile $OUTPUT_FILE ""
appendToFile $OUTPUT_FILE "---"
appendToFile $OUTPUT_FILE ""

# 2. Verifizierte Quellen (Perplexity) falls verfügbar
appendToFile $OUTPUT_FILE "## 2. Verifizierte Fakten (Perplexity)"
appendToFile $OUTPUT_FILE ""

set perplexity_data "{\"model\": \"perplexity/sonar:online\", \"messages\": \[{\"role\": \"user\", \"content\": \"${QUERY} troubleshooting\"}\]}"

set perplexity_token [http::geturl "https://openrouter.ai/api/v1/chat/completions" \
    -headers [list Authorization "Bearer $API_KEY" Content-Type "application/json"] \
    -query $perplexity_data \
    -method POST]

set perplexity_response ""
if {![catch {http::data $perplexity_token} perplexity_result]} {
    if {[info complete $perplexity_result]} {
        if {[dict exists $perplexity_result choices 0 message content]} {
            set perplexity_response [dict get $perplexity_result choices 0 message content]
        } else {
            set perplexity_response "Keine Ergebnisse"
        }
    } else {
        set perplexity_response "Keine Ergebnisse"
    }
} else {
    set perplexity_response "Keine Ergebnisse"
}

appendToFile $OUTPUT_FILE $perplexity_response
appendToFile $OUTPUT_FILE ""
appendToFile $OUTPUT_FILE "Gespeichert in: $OUTPUT_FILE"

# HTTP-Token aufräumen
http::cleanup $exa_token
http::cleanup $perplexity_token
