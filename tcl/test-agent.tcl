#!/usr/bin/env tclsh
# test-agent.sh — portiert nach tcl
# Quelle: shell, OpenClaw@gateway1:perplexity-pack/files/workspace/skills/perplexity-pro-search/scripts/test-agent.sh
# auch in: OpenClaw@gateway1:perplexity-pack/files/skills/perplexity-pro-search/scripts/test-agent.sh
# auch in: OpenClaw@gateway1:skills/perplexity-pro-search/scripts/test-agent.sh
# auch in: OpenClaw@gateway2:skills/perplexity-pro-search/scripts/test-agent.sh
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

package require http
package require json
package require tls

# Set HTTP to use TLS
http::register https 443 [list ::tls::socket]

# Check for required environment variable
if {![info exists env(PERPLEXITY_API_KEY)] || $env(PERPLEXITY_API_KEY) eq ""} {
    puts stderr "PERPLEXITY_API_KEY is required"
    exit 1
}

# Get command line argument or default prompt
if {$argc > 0} {
    set prompt [lindex $argv 0]
} else {
    set prompt "Compare recent open-source LLMs in terms of performance, licensing, and practical use."
}

# Determine temporary directory and output file
if {[info exists env(TMPDIR)] && $env(TMPDIR) ne ""} {
    set tmpdir $env(TMPDIR)
} else {
    if {$::tcl_platform(platform) eq "windows"} {
        set tmpdir $env(TEMP)
    } else {
        set tmpdir "/tmp"
    }
}
set out [file join $tmpdir "perplexity-agent-test.json"]

# Create JSON payload
set input $prompt
set json_payload [json::write object \
    preset "fast-search" \
    input $input]

# Prepare HTTP request
set url "https://api.perplexity.ai/v1/agent"
set headers [list \
    "Authorization" "Bearer $env(PERPLEXITY_API_KEY)" \
    "Content-Type" "application/json"]

# Perform HTTP POST request
set token [http::geturl $url -headers $headers -query $json_payload -method POST]
set code [http::status $token]
set http_code [http::ncode $token]

# Save response to file
set fp [open $out w]
puts -nonewline $fp [http::data $token]
close $fp

# Clean up
http::cleanup $token

# Output HTTP status
puts "agent_http=$http_code"

# Process and output JSON response
set fp [open $out r]
set json_data [read $fp]
close $fp

# Parse JSON and extract required fields
if {[catch {set parsed_json [json::json2dict $json_data]}]} {
    # If parsing fails, create empty dict
    set parsed_json [dict create]
}

# Extract fields with fallback to null (empty string in Tcl)
set keys_list [dict keys $parsed_json]
set id [expr {[dict exists $parsed_json id] ? [dict get $parsed_json id] : ""}]
set status [expr {[dict exists $parsed_json status] ? [dict get $parsed_json status] : ""}]
set error [expr {[dict exists $parsed_json error] ? [dict get $parsed_json error] : ""}]

# Count output array length
if {[dict exists $parsed_json output] && [llength [dict get $parsed_json output]] > 0} {
    set output_count [llength [dict get $parsed_json output]]
} else {
    set output_count 0
}

# Output result as JSON-like structure
puts "{keys: [list $keys_list], id: [expr {$id eq "" ? "null" : \"$id\"}], status: [expr {$status eq "" ? "null" : \"$status\"}], output_count: $output_count, error: [expr {$error eq "" ? "null" : \"$error\"}]}"
