#!/usr/bin/env bash
# abstraction-provenance: {"artifact_sha256": "6aef1679aa471cc05e47ab3bf1e7012778334b724a0b0243c51b43aa6d5a0e08", "source_sha256": "d3ab9d6951153a42390fb59c1a50b0c901cf4c399dcb731b89865fdc293f3ac9", "target_language": "shell"}
# json_websearch.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:skills/scripting-utils/scripts/json_websearch.py
# auch in: OpenClaw@gateway2:skills/scripting-utils/scripts/json_websearch.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# JSON Utils + WebSearch integration.
# Fetch API schemas from web, validate real API responses, batch-validate endpoints.

# Add json-utils to path
JSON_UTILS_PATH="$(dirname "$(realpath "${BASH_SOURCE[0]}")")/../json-utils/scripts"
export PATH="$JSON_UTILS_PATH:$PATH"

# Check if required tools are available
JSON_UTILS_AVAILABLE=true
for tool in jq parse-json validate-json generate-schema; do
    if ! command -v "$tool" &>/dev/null; then
        JSON_UTILS_AVAILABLE=false
        break
    fi
done

if [ "$JSON_UTILS_AVAILABLE" = false ]; then
    echo "Warning: json-utils not found. Some features disabled."
fi

# WebSearchResult structure simulation using associative arrays
declare -A WEB_SEARCH_RESULT=(
    [query]=""
    [json_data]=""
    [validation_errors]=""
    [schema_matched]="false"
    [source_url]=""
)

# WebSearchJSON class simulation
WEBSEARCH_JSON_USE_REPAIR=true

# search_and_validate function
search_and_validate() {
    local query="$1"
    local schema_path="${2:-}"
    
    # Simulate web search result
    local mock_response='{
        "api": "'${query%% *}'",
        "version": "1.0",
        "endpoints": [
            {"path": "/items", "method": "GET"},
            {"path": "/items", "method": "POST"}
        ]
    }'
    
    local validation_errors=""
    local schema_matched="false"
    
    if [ "$JSON_UTILS_AVAILABLE" = true ] && [ -n "$schema_path" ]; then
        if validate-json <(echo "$mock_response") "$schema_path"; then
            schema_matched="true"
        else
            validation_errors=$(validate-json <(echo "$mock_response") "$schema_path" 2>&1 || true)
        fi
    fi
    
    # Output result as JSON
    cat <<EOF
{
  "query": "$query",
  "json_data": $(echo "$mock_response" | jq -c '.'),
  "validation_errors": [$(echo "$validation_errors" | jq -R . | jq -s 'map(select(length > 0)) | join(",")')],
  "schema_matched": $schema_matched,
  "source_url": "https://api.github.com/search?q=${query// /+}"
}
EOF
}

# validate_api_response function
validate_api_response() {
    local response_data="$1"
    local endpoint="$2"
    local expected_schema="${3:-}"
    
    if [ "$JSON_UTILS_AVAILABLE" = false ]; then
        echo "$response_data"
        return
    fi
    
    # Use json-utils parser with auto-repair
    local result
    if [ "$WEBSEARCH_JSON_USE_REPAIR" = true ]; then
        result=$(parse-json --repair <(echo "$response_data"))
    else
        result=$(parse-json <(echo "$response_data"))
    fi
    
    if [ -n "$expected_schema" ]; then
        if ! validate-json <(echo "$result") "$expected_schema"; then
            echo "Schema validation failed for $endpoint: $(validate-json <(echo "$result") "$expected_schema" 2>&1)" >&2
        fi
    fi
    
    echo "$result"
}

# batch_validate_endpoints function
batch_validate_endpoints() {
    local endpoints_json="$1"
    local responses_json="$2"
    local schema_path="${3:-}"
    
    local endpoints
    local responses
    readarray -t endpoints < <(echo "$endpoints_json" | jq -r '.[]')
    readarray -t responses < <(echo "$responses_json" | jq -r '.[]')
    
    local results="["
    local first=true
    
    for i in "${!endpoints[@]}"; do
        local endpoint="${endpoints[$i]}"
        local response="${responses[$i]:-}"
        
        if [ "$first" = true ]; then
            first=false
        else
            results="$results,"
        fi
        
        if validate_api_response "$response" "$endpoint" "$schema_path" >/dev/null 2>&1; then
            local validated_data
            validated_data=$(validate_api_response "$response" "$endpoint" "$schema_path")
            results="$results{
                \"query\": \"$endpoint\",
                \"json_data\": $(echo "$validated_data" | jq -c '.'),
                \"validation_errors\": [],
                \"schema_matched\": true,
                \"source_url\": \"$endpoint\"
            }"
        else
            local error_msg
            error_msg=$(validate_api_response "$response" "$endpoint" "$schema_path" 2>&1 || true)
            results="$results{
                \"query\": \"$endpoint\",
                \"json_data\": {},
                \"validation_errors\": [\"$error_msg\"],
                \"schema_matched\": false,
                \"source_url\": \"$endpoint\"
            }"
        fi
    done
    
    results="$results]"
    echo "$results"
}

# generate_api_schema function
generate_api_schema() {
    local sample_response="$1"
    local endpoint="$2"
    
    if [ "$JSON_UTILS_AVAILABLE" = false ]; then
        echo "{}"
        return
    fi
    
    local data
    data=$(parse-json <(echo "$sample_response"))
    
    # Generate schema using generate-schema tool
    local schema
    schema=$(generate-schema <(echo "$data"))
    
    # Add title to schema
    echo "$schema" | jq ". + {\"title\": \"$endpoint Response Schema\"}"
}

# Main function
main() {
    local search_query=""
    local validate_file=""
    local schema_file=""
    local generate_schema_file=""
    local endpoint=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --search)
                search_query="$2"
                shift 2
                ;;
            --validate-file)
                validate_file="$2"
                shift 2
                ;;
            --schema)
                schema_file="$2"
                shift 2
                ;;
            --generate-schema)
                generate_schema_file="$2"
                shift 2
                ;;
            --endpoint)
                endpoint="$2"
                shift 2
                ;;
            *)
                echo "Unknown option: $1" >&2
                exit 1
                ;;
        esac
    done
    
    if [ -n "$search_query" ]; then
        search_and_validate "$search_query" "$schema_file"
    elif [ -n "$generate_schema_file" ] && [ -n "$endpoint" ]; then
        local sample
        sample=$(cat "$generate_schema_file")
        generate_api_schema "$sample" "$endpoint"
    else
        echo "Invalid arguments. Use --help for usage information." >&2
        exit 1
    fi
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
