#!/usr/bin/env tclsh
# generate-elevenlabs.mjs — portiert nach tcl
# Quelle: javascript, Onboarding@main:scripts/generate-elevenlabs.mjs
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

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

# API request
set url "https://api.elevenlabs.io/v1/text-to-speech/${voiceId}?output_format=mp3_44100_128"

set postData [::json::write object \
    text $text \
    model_id "eleven_multilingual_v2" \
    voice_settings [::json::write object \
        stability 0.58 \
        similarity_boost 0.72 \
        style 0.18 \
        use_speaker_boost true \
    ] \
]

set headers [list \
    "xi-api-key: $key" \
    "Content-Type: application/json" \
]

# Configure HTTP request
http::register https 443 [list ::tls::socket -tls1 1]
set token [http::geturl $url -method POST -headers $headers -query $postData]
set status [http::status $token]
set code [http::ncode $token]

if {$status ne "ok" || $code < 200 || $code >= 300} {
    set errorInfo [http::data $token]
    http::cleanup $token
    error "ElevenLabs fehlgeschlagen: $code - $errorInfo"
}

# Get response data
set response_data [http::data $token]
http::cleanup $token

# Create directories
file mkdir ../public/audio/
file mkdir ../media-production/

# Write audio file
set audioFile [open "../public/audio/project-narration.mp3" wb]
puts -nonewline $audioFile $response_data
close $audioFile

# Write JSON result file
set resultData [::json::write object \
    model "eleven_multilingual_v2" \
    voiceId $voiceId \
    characters [string length $text] \
    text $text \
    output "public/audio/project-narration.mp3" \
]

set jsonFile [open "../media-production/elevenlabs-result.json" w]
puts $jsonFile [::json::prettyprint $resultData]
close $jsonFile

puts "ElevenLabs abgeschlossen: [string length $text] Zeichen."
