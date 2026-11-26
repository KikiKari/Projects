#!/usr/bin/env tclsh
# abstraction-provenance: {"artifact_sha256": "3294087aa65c9a5712cf86e3e05cd85e73380769e5f30634f8198ad8b5406d9a", "source_sha256": "3fed8b6be2b9b8639b55bcaf18c09c0395ac005ab02c27f2dff26ca20b5d5825", "target_language": "tcl"}
# generate-wavespeed.mjs — portiert nach tcl
# Quelle: javascript, Onboarding@main:scripts/generate-wavespeed.mjs
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

package require http
package require json
package require fileutil
package require base64

# Hilfsfunktion zur URL-Kodierung
proc urlencode {str} {
    set map {" " "%20" "!" "%21" "\"" "%22" "#" "%23" "\$" "%24" "&" "%26" "'" "%27" "(" "%28" ")" "%29" "*" "%2A" "+" "%2B" "," "%2C" "/" "%2F" ":" "%3A" ";" "%3B" "<" "%3C" "=" "%3D" ">" "%3E" "?" "%3F" "@" "%40" "[" "%5B" "\\" "%5C" "]" "%5D" "^" "%5E" "`" "%60" "{" "%7B" "|" "%7C" "}" "%7D" "~" "%7E"}
    foreach {char code} $map {
        regsub -all $char $str $code str
    }
    return $str
}

# Prüfe auf API-Key
if {![info exists ::env(WAVESPEED_API_KEY)] || $::env(WAVESPEED_API_KEY) eq ""} {
    error "WAVESPEED_API_KEY fehlt."
}
set key $::env(WAVESPEED_API_KEY)

# Pfade festlegen
set script_dir [file dirname [info script]]
set media_production_dir [file join $script_dir ".." "media-production"]
set raw_dir [file normalize [file join $media_production_dir "raw"]]
set public_dir [file normalize [file join $script_dir ".." "public" "media"]]
set jobs_file [file normalize [file join $media_production_dir "wavespeed-jobs.json"]]
set results_file [file normalize [file join $media_production_dir "wavespeed-results.json"]]

# Verzeichnisse erstellen
file mkdir $raw_dir
file mkdir $public_dir

# Jobs laden
if {[catch {open $jobs_file r} f]} {
    error "Kann $jobs_file nicht öffnen: $f"
}
set jobs_data [read $f]
close $f
set jobs [json::json2dict $jobs_data]

# Log laden oder initialisieren
set log {}
if {[file exists $results_file]} {
    if {[catch {open $results_file r} f]} {
        error "Kann $results_file nicht öffnen: $f"
    }
    set log_data [read $f]
    close $f
    set log [json::json2dict $log_data]
} else {
    set log {}
}

# HTTP-Token für Authentifizierung
proc setup_http_token {} {
    variable token
    if {[info exists token]} {
        http::reset $token
    }
    set token [http::geturl https://api.wavespeed.ai/api/v3/google/nano-banana-2/edit -headers [list Authorization "Bearer $::key"]]
    return $token
}

# Funktion zum Lesen einer Datei als Base64
proc read_file_as_base64 {filepath} {
    if {[catch {open $filepath rb} f]} {
        error "Kann $filepath nicht öffnen: $f"
    }
    set data [read $f]
    close $f
    return [base64::encode $data]
}

# Funktion zum Herunterladen einer URL in eine Datei
proc download_url_to_file {url filepath} {
    set tok [http::geturl $url]
    set ncode [http::ncode $tok]
    if {$ncode != 200} {
        http::cleanup $tok
        error "Download fehlgeschlagen: $ncode"
    }
    set data [http::data $tok]
    http::cleanup $tok]
    if {[catch {open $filepath wb} f]} {
        error "Kann $filepath nicht schreiben: $f"
    }
    puts -nonewline $f $data
    close $f
}

# Hauptverarbeitungsschleife
foreach job_dict $jobs {
    array set job $job_dict
    set job_id $job(id)
    set output_name $job(output)
    set raw_path [file join $raw_dir "${job_id}.png"]
    set target_path [file join $public_dir "${output_name}.png"]

    # Prüfen, ob bereits generiert
    if {[file exists $raw_path]} {
        set found 0
        foreach entry $log {
            array set e $entry
            if {[info exists e(id)] && $e(id) eq $job_id} {
                set found 1
                break
            }
        }
        if {!$found} {
            lappend log [dict create id $job_id requestId "completed-before-resume" model "google/nano-banana-2/edit" resolution "4k" plannedCostUsd 0.14 output [file tail $target_path]]
            set fp [open $results_file w]
            puts $fp [json::dict2json $log]
            close $fp
        }
        puts "Übersprungen: $job_id ist bereits vorhanden."
        continue
    }

    # Bilder vorbereiten
    set images_list {}
    foreach img_path $job(images) {
        if {[regexp {^(https?|data):} $img_path]} {
            lappend images_list $img_path
        } else {
            set full_img_path [file normalize [file join $script_dir ".." $img_path]]
            if {![file exists $full_img_path]} {
                error "Bilddatei nicht gefunden: $full_img_path"
            }
            set b64_data [read_file_as_base64 $full_img_path]
            lappend images_list "data:image/png;base64,$b64_data"
        }
    }

    # Anfrage an WaveSpeed senden
    set post_data [json::dict2json [dict create \
        prompt $job(prompt) \
        images $images_list \
        aspect_ratio $job(aspectRatio) \
        resolution "4k" \
        output_format "png" \
        enable_web_search false \
        enable_image_search false \
        enable_sync_mode false \
        enable_base64_output false]]

    set tok [http::geturl https://api.wavespeed.ai/api/v3/google/nano-banana-2/edit \
        -method POST \
        -headers [list Authorization "Bearer $key" Content-Type "application/json"] \
        -query $post_data]

    set ncode [http::ncode $tok]
    if {$ncode != 200} {
        set err_msg [http::data $tok]
        http::cleanup $tok
        error "WaveSpeed submit fehlgeschlagen: $ncode $err_msg"
    }

    set response_json [http::data $tok]
    http::cleanup $tok
    set submitted [json::json2dict $response_json]
    set request_id [dict get $submitted data id]

    # Polling für Ergebnis
    set result ""
    for {set attempt 0} {$attempt < 90} {incr attempt} {
        after 4000
        set poll_tok [http::geturl https://api.wavespeed.ai/api/v3/predictions/$request_id/result \
            -headers [list Authorization "Bearer $key"]]
        set poll_ncode [http::ncode $poll_tok]
        if {$poll_ncode != 200} {
            set poll_err [http::data $poll_tok]
            http::cleanup $poll_tok
            error "Polling fehlgeschlagen: $poll_ncode $poll_err"
        }
        set poll_data [http::data $poll_tok]
        http::cleanup $poll_tok
        set result [json::json2dict $poll_data]
        if {[dict get $result data status] eq "completed"} {
            break
        }
        if {[dict get $result data status] eq "failed"} {
            error "WaveSpeed job fehlgeschlagen: $job_id"
        }
    }

    # Bild herunterladen und speichern
    set output_url [lindex [dict get $result data outputs] 0]
    if {$output_url eq ""} {
        error "Kein Output für $job_id"
    }

    download_url_to_file $output_url $raw_path
    file copy -force $raw_path $target_path

    lappend log [dict create id $job_id requestId $request_id model "google/nano-banana-2/edit" resolution "4k" plannedCostUsd 0.14 output [file tail $target_path]]
    
    set fp [open $results_file w]
    puts $fp [json::dict2json $log]
    close $fp
    
    puts "Abgeschlossen: $job_id"
}

# Abschlussmeldung
set fp [open $results_file w]
puts $fp [json::dict2json $log]
close $fp

set count [llength $log]
set cost [expr {$count * 0.14}]
puts "WaveSpeed abgeschlossen: $count Assets, geplante Basiskosten \$[format "%.2f" $cost]."
