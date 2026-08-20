#!/usr/bin/env tclsh8.6
# test-contextualized-embeddings.sh — portiert nach tcl
# Quelle: shell, OpenClaw@gateway1:perplexity-pack/files/workspace/skills/perplexity-pro-search/scripts/test-contextualized-embeddings.sh
# auch in: OpenClaw@gateway1:perplexity-pack/files/skills/perplexity-pro-search/scripts/test-contextualized-embeddings.sh
# auch in: OpenClaw@gateway1:skills/perplexity-pro-search/scripts/test-contextualized-embeddings.sh
# auch in: OpenClaw@gateway2:skills/perplexity-pro-search/scripts/test-contextualized-embeddings.sh
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

package require http
package require json
package require json::write

# Set strict error handling
if {![info exists env(PERPLEXITY_API_KEY)] || $env(PERPLEXITY_API_KEY) eq ""} {
    puts stderr "PERPLEXITY_API_KEY is required"
    exit 1
}

set tmpdir [expr {[info exists env(TMPDIR)] ? $env(TMPDIR) : "/tmp"}]
set out [file join $tmpdir "perplexity-contextualized-embeddings-test.json"]

# Create JSON payload
set payload [json::write object \
    [list input [list [list \
        "OpenClaw can route web search through Perplexity." \
        "The Perplexity MCP server exposes search and reasoning tools." \
        "Contextualized embeddings improve document chunk retrieval." \
    ]]] \
    [list model "pplx-embed-context-v1-4b"] \
]

# Configure HTTP request
::http::register https 443 [list ::http::socket -headers {Authorization Content-Type}]

set headers [list \
    Authorization "Bearer $env(PERPLEXITY_API_KEY)" \
    Content-Type "application/json" \
]

# Perform HTTP request
set tok [::http::geturl "https://api.perplexity.ai/v1/contextualizedembeddings" \
    -headers $headers \
    -query $payload \
    -method POST \
]

# Get response code
set code [::http::status $tok]
set ncode [::http::ncode $tok]

# Save response to file
set fd [open $out w]
puts -nonewline $fd [::http::data $tok]
close $fd

::http::cleanup $tok

puts "contextualized_embeddings_http=$ncode"

# Process JSON response
set fd [open $out r]
set data [read $fd]
close $fd

# Parse JSON and extract information
if {[catch {json::json2dict $data} parsed]} {
    puts "{\"error\": \"Failed to parse JSON response\"}"
    exit 1
}

# Extract values with safe defaults
set keys [dict keys $parsed]
set model [expr {[dict exists $parsed model] ? [dict get $parsed model] : "null"}]

# Get document count
set document_count 0
if {[dict exists $parsed data]} {
    set data_list [dict get $parsed data]
    if {[llength $data_list] > 0 && [string is list $data_list]} {
        set document_count [llength $data_list]
    }
}

# Get first chunk count
set first_chunk_count 0
if {[dict exists $parsed data] && [llength [dict get $parsed data]] > 0} {
    set first_item [lindex [dict get $parsed data] 0]
    if {[dict exists $first_item data]} {
        set first_data [dict get $first_item data]
        if {[llength $first_data] > 0 && [string is list $first_data]} {
            set first_chunk_count [llength $first_data]
        }
    }
}

set error_val [expr {[dict exists $parsed error] ? [dict get $parsed error] : "null"}]

# Output result as JSON-like string
puts "\{"
puts "  \"keys\": \[[join $keys {, }]\],"
puts "  \"model\": [if {$model eq "null"} {puts -nonewline "null"} else {puts -nonewline "\"$model\""}],"
puts "  \"document_count\": $document_count,"
puts "  \"first_chunk_count\": $first_chunk_count,"
puts "  \"error\": [if {$error_val eq "null"} {puts -nonewline "null"} else {puts -nonewline "\"$error_val\""}]"
puts "\}"
