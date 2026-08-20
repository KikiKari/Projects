#!/usr/bin/env tclsh
# test-embeddings.sh — portiert nach tcl
# Quelle: shell, OpenClaw@gateway1:perplexity-pack/files/workspace/skills/perplexity-pro-search/scripts/test-embeddings.sh
# auch in: OpenClaw@gateway1:perplexity-pack/files/skills/perplexity-pro-search/scripts/test-embeddings.sh
# auch in: OpenClaw@gateway1:skills/perplexity-pro-search/scripts/test-embeddings.sh
# auch in: OpenClaw@gateway2:skills/perplexity-pro-search/scripts/test-embeddings.sh
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

# Set strict error handling
if {![info exists env(PERPLEXITY_API_KEY)] || $env(PERPLEXITY_API_KEY) eq ""} {
    puts stderr "PERPLEXITY_API_KEY is required"
    exit 1
}

# Set output file path
set out [expr {[info exists env(TMPDIR)] ? $env(TMPDIR) : "/tmp"}/perplexity-embeddings-test.json]

# Create JSON payload
set payload "{\n  \"input\": [\n    \"Scientists explore the universe driven by curiosity.\",\n    \"Curiosity compels us to seek explanations, not just observations.\",\n    \"Historical discoveries began with curious questions.\",\n    \"The pursuit of knowledge distinguishes human curiosity from mere stimulus response.\",\n    \"Philosophy examines the nature of curiosity.\"\n  ],\n  \"model\": \"pplx-embed-v1-4b\"\n}"

# Make HTTP request using curl
if {[catch {exec curl -sS -o $out -w "%{http_code}" \
    -X POST "https://api.perplexity.ai/v1/embeddings" \
    -H "Authorization: Bearer $env(PERPLEXITY_API_KEY)" \
    -H "Content-Type: application/json" \
    -d $payload} code]} {
    puts stderr "curl failed: $code"
    exit 1
}

puts "embeddings_http=$code"

# Process JSON response
if {[catch {exec jq {keys: keys, model:(.model // null), item_count:((.data // []) | length), first_dim:(((.data // [])[0].embedding // []) | length), error:(.error // null)} $out} result]} {
    puts stderr "jq processing failed: $result"
    exit 1
}

puts $result
