#!/usr/bin/env tclsh
# test-search.sh — portiert nach tcl
# Quelle: shell, OpenClaw@gateway1:perplexity-pack/files/workspace/skills/perplexity-pro-search/scripts/test-search.sh
# auch in: OpenClaw@gateway1:perplexity-pack/files/skills/perplexity-pro-search/scripts/test-search.sh
# auch in: OpenClaw@gateway1:skills/perplexity-pro-search/scripts/test-search.sh
# auch in: OpenClaw@gateway2:skills/perplexity-pro-search/scripts/test-search.sh
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

package require http
package require json
package require json::write

# Set HTTP timeout
http::config -useragent "tcl-perplexity-client"

# Check for required environment variable
if {![info exists ::env(PERPLEXITY_API_KEY)]} {
    puts stderr "PERPLEXITY_API_KEY is required"
    exit 1
}

# Get command line arguments
set query [lindex $argv 0]
if {$query eq ""} {
    set query "Perplexity API Platform"
}

# Set default values
set max_results [expr {[info exists ::env(PERPLEXITY_MAX_RESULTS)] ? $::env(PERPLEXITY_MAX_RESULTS) : 3}]
set max_tokens_per_page [expr {[info exists ::env(PERPLEXITY_MAX_TOKENS_PER_PAGE)] ? $::env(PERPLEXITY_MAX_TOKENS_PER_PAGE) : 256}]
set tmpdir [expr {[info exists ::env(TMPDIR)] ? $::env(TMPDIR) : "/tmp"}]
set out [file join $tmpdir "perplexity-search-test.json"]

# Create JSON payload
set payload [dict create \
    query $query \
    max_results $max_results \
    max_tokens_per_page $max_tokens_per_page]
set json_payload [json::write object {*}[dict map {key value} $payload {set key $value}]]

# Make HTTP request
set url https://api.perplexity.ai/search
set token [http::geturl $url \
    -method POST \
    -headers [list \
        Authorization "Bearer $::env(PERPLEXITY_API_KEY)" \
        Content-Type application/json \
    ] \
    -query $json_payload \
    -timeout 30000]

# Get response
set code [http::status $token]
set http_code [http::ncode $token]
set data [http::data $token]
http::cleanup $token

# Write response to file
set fh [open $out w]
puts $fh $data
close $fh

# Output HTTP status
puts "search_http=$http_code"

# Parse and process JSON response
if {[catch {set json_data [json::json2dict $data]}]} {
    puts "{keys: \[\], result_count: 0, first: null}"
} else {
    # Get all keys
    set keys [dict keys $json_data]
    
    # Try to get results count from .results or .data
    set results_list {}
    if {[dict exists $json_data results]} {
        set results_list [dict get $json_data results]
    } elseif {[dict exists $json_data data]} {
        set results_list [dict get $json_data data]
    }
    
    set result_count [llength $results_list]
    
    # Get first result
    set first_result null
    if {$result_count > 0} {
        set first_result [lindex $results_list 0]
    }
    
    # Output formatted result
    puts "{keys: \[[join $keys ", "]\], result_count: $result_count, first: $first_result}"
}
