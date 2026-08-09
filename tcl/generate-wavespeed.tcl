#!/usr/bin/env tclsh
# generate-wavespeed.mjs — portiert nach tcl
# Quelle: javascript, Onboarding@main:scripts/generate-wavespeed.mjs
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

package require http
package require json
package require base64
package require fileutil

# Prüfe, ob WAVESPEED_API_KEY gesetzt ist
if {![info exists ::env(WAVESPEED_API_KEY)]} {
    error "WAVESPEED_API_KEY fehlt."
}
set key $::env(WAVESPEED_API_KEY)

# Lese jobs.json
set jobsFile [file join [file dirname [file dirname [info script]]] media-production wavespeed-jobs.json]
set jobsData [::json::json2dict [::fileutil::cat $jobsFile]]
set jobs [dict get $jobsData ""]

# Pfade definieren
set rawDir [file join [file dirname [file dirname [info script]]] media-production raw]
set publicDir [file join [file dirname [file dirname [info script]]] public media]
file mkdir $rawDir
file mkdir $publicDir

# Lese oder initialisiere log-Datei
set resultUrl [file join [file dirname [file dirname [info script]]] media-production wavespeed-results.json]
if {[file exists $resultUrl]} {
    set logData [::json::json2dict [::fileutil::cat $resultUrl]]
} else {
    set logData [list]
}

# Hilfsfunktion zur Base64-Kodierung
proc encodeBase64 {filePath} {
    set fp [open $filePath rb]
    set data [read $fp]
    close $fp
    return [::base64::encode $data]
}

# Hilfsfunktion zur HTTP-Anfrage
proc fetchUrl {url args} {
    array set opts $args
    set token [::http::geturl $url {*}[array get opts]]
    set ncode [::http::ncode $token]
    set data [::http::data $token]
    ::http::cleanup $token
    return [list $ncode $data]
}

# Hilfsfunktion zur JSON-Kodierung (vereinfacht)
proc jsonEncode {data} {
    return [::json::dict2json $data]
}

# Hauptverarbeitung
foreach job $jobs {
    set jobId [dict get $job "id"]
    set rawPath [file join $rawDir "${jobId}.png"]
    set targetPath [file join $publicDir "[dict get $job "output"].png"]

    # Prüfe, ob bereits generiert
    if {[file exists $rawPath]} {
        set found 0
        foreach entry $logData {
            if {[dict get $entry "id"] eq $jobId} {
                set found 1
                break
            }
        }
        if {!$found} {
            lappend logData [dict create \
                id $jobId \
                requestId "completed-before-resume" \
                model "google/nano-banana-2/edit" \
                resolution "4k" \
                plannedCostUsd 0.14 \
                output [file tail $targetPath]]
            set fp [open $resultUrl w]
            puts $fp [::json::dict2json $logData]
            close $fp
        }
        puts "Übersprungen: $jobId ist bereits vorhanden."
        continue
    }

    # Lade Bilder
    set imagesList {}
    foreach image [dict get $job "images"] {
        if {[regexp {^https?:|^data:} $image]} {
            lappend imagesList $image
        } else {
            set imagePath [file join [file dirname [file dirname [info script]]] $image]
            set imageData [encodeBase64 $imagePath]
            lappend imagesList "data:image/png;base64,$imageData"
        }
    }

    # Sende Anfrage
    set submitUrl "https://api.wavespeed.ai/api/v3/google/nano-banana-2/edit"
    set submitData [dict create \
        prompt [dict get $job "prompt"] \
        images $imagesList \
        aspect_ratio [dict get $job "aspectRatio"] \
        resolution "4k" \
        output_format "png" \
        enable_web_search false \
        enable_image_search false \
        enable_sync_mode false \
        enable_base64_output false]
    set jsonData [jsonEncode $submitData]
    set headers [list Authorization "Bearer $key" Content-Type "application/json"]
    lassign [fetchUrl $submitUrl -headers $headers -method POST -query $jsonData] submitCode submitResponse

    if {$submitCode != 200} {
        error "WaveSpeed submit fehlgeschlagen: $submitCode $submitResponse"
    }

    set submitted [::json::json2dict $submitResponse]
    set requestId [dict get $submitted "data" "id"]
    if {$requestId eq ""} {
        set requestId [dict get $submitted "id"]
    }

    # Polling
    set result ""
    for {set attempt 0} {$attempt < 90} {incr attempt} {
        after 4000
        set pollUrl "https://api.wavespeed.ai/api/v3/predictions/${requestId}/result"
        set pollHeaders [list Authorization "Bearer $key"]
        lassign [fetchUrl $pollUrl -headers $pollHeaders] pollCode pollResponse
        set result [::json::json2dict $pollResponse]
        set status [dict get $result "data" "status"]
        if {$status eq "completed"} {
            break
        }
        if {$status eq "failed"} {
            error "WaveSpeed job fehlgeschlagen: $jobId"
        }
    }

    # Verarbeite Ergebnis
    set imageUrl [lindex [dict get $result "data" "outputs"] 0]
    if {$imageUrl eq ""} {
        error "Kein Output für $jobId"
    }

    # Lade Bild herunter
    lassign [fetchUrl $imageUrl] imageCode imageData
    if {$imageCode != 200} {
        error "Bild-Download fehlgeschlagen: $imageCode"
    }

    # Speichere Rohdaten und Ziel
    set fp [open $rawPath wb]
    puts -nonewline $fp $imageData
    close $fp

    set fp [open $targetPath wb]
    puts -nonewline $fp $imageData
    close $fp

    # Log-Eintrag hinzufügen
    lappend logData [dict create \
        id $jobId \
        requestId $requestId \
        model "google/nano-banana-2/edit" \
        resolution "4k" \
        plannedCostUsd 0.14 \
        output [file tail $targetPath]]

    set fp [open $resultUrl w]
    puts $fp [::json::dict2json $logData]
    close $fp

    puts "Abgeschlossen: $jobId"
}

# Abschlussmeldung
set fp [open $resultUrl w]
puts $fp [::json::dict2json $logData]
close $fp

set totalCost [expr {[llength $logData] * 0.14}]
puts [format "WaveSpeed abgeschlossen: %d Assets, geplante Basiskosten \$%.2f." [llength $logData] $totalCost]
