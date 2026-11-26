#!/usr/bin/env tclsh
# abstraction-provenance: {"artifact_sha256": "e225fd84b1dfaf875d1e0ee54c0531970e602fd0e126e15d6ee7c88d89686a1d", "source_sha256": "4112b3dbe78c8a495b73f6feaebe05ada553911d2e25f6bd1e2e4d704a6ac1b6", "target_language": "tcl"}
# generate-elevenlabs.mjs — portiert nach tcl
# Quelle: javascript, Onboarding@main:scripts/generate-elevenlabs.mjs
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

package require http
package require json
package require fileutil

# Environment variables
set key [expr {[info exists ::env(ELEVENLABS_API_KEY)] ? $::env(ELEVENLABS_API_KEY) : ""}]
set voiceId [expr {[info exists ::env(ELEVENLABS_VOICE_ID)] ? $::env(ELEVENLABS_VOICE_ID) : "JBFqnCBsd6RMkjVDRZzb"}]

if {$key eq ""} {
    error "ELEVENLABS_API_KEY fehlt."
}

set text "Neun Projekte. Zwei Plattformen. Ein Ort, an dem Ideen verbunden und weiterentwickelt werden."

# Prepare request data
set url "https://api.elevenlabs.io/v1/text-to-speech/$voiceId?output_format=mp3_44100_128"

set postData [dict create \
    text $text \
    model_id "eleven_multilingual_v2" \
    voice_settings [dict create \
        stability 0.58 \
        similarity_boost 0.72 \
        style 0.18 \
        use_speaker_boost true \
    ] \
]

# Convert to JSON
set jsonData [::json::write object \
    text [dict get $postData text] \
    model_id [dict get $postData model_id] \
    voice_settings [::json::write object \
        stability [dict get $postData voice_settings stability] \
        similarity_boost [dict get $postData voice_settings similarity_boost] \
        style [dict get $postData voice_settings style] \
        use_speaker_boost [dict get $postData voice_settings use_speaker_boost] \
    ] \
]

# Configure HTTP request
http::register https 443 [list ::http::socket -ssl true]
set token [http::geturl $url -method POST \
    -headers [list \
        xi-api-key $key \
        Content-Type application/json \
    ] \
    -query $jsonData \
]

set status [http::status $token]
set code [http::ncode $token]

if {$status != "ok" || $code < 200 || $code >= 300} {
    set errorInfo [http::error $token]
    http::cleanup $token
    error "ElevenLabs fehlgeschlagen: $code - $errorInfo"
}

# Get response data
set response_data [http::data $token]
http::cleanup $token

# Create directories
file mkdir "../public/audio/"
file mkdir "../media-production/"

# Write audio file
set audioFile [open "../public/audio/project-narration.mp3" wb]
puts -nonewline $audioFile $response_data
close $audioFile

# Create result JSON
set resultDict [dict create \
    model "eleven_multilingual_v2" \
    voiceId $voiceId \
    characters [string length $text] \
    text $text \
    output "public/audio/project-narration.mp3" \
]

# Convert result to formatted JSON
set resultJson [::json::write object \
    model [dict get $resultDict model] \
    voiceId [dict get $resultDict voiceId] \
    characters [dict get $resultDict characters] \
    text [dict get $resultDict text] \
    output [dict get $resultDict output] \
]

# Pretty print with indentation
set formattedJson ""
set lines [split $resultJson "\n"]
set indentLevel 0
foreach line $lines {
    if {[string match "*}*" $line] && ![string match "*{*" $line]} {
        incr indentLevel -1
    }
    
    set indent ""
    for {set i 0} {$i < $indentLevel} {incr i} {
        append indent "  "
    }
    append formattedJson "$indent$line\n"
    
    if {[string match "*{*" $line] && ![string match "*}*" $line]} {
        incr indentLevel
    }
}

# Write result JSON file
set jsonFile [open "../media-production/elevenlabs-result.json" w]
puts $jsonFile $formattedJson
close $jsonFile

puts "ElevenLabs abgeschlossen: [string length $text] Zeichen."
