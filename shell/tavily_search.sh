#!/bin/bash
# tavily_search.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:skills/tavily/scripts/tavily_search.py
# auch in: OpenClaw@gateway2:skills/tavily/scripts/tavily_search.py
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Tavily AI Search - Optimized search for LLMs and AI applications

show_help() {
    cat << EOF
Tavily AI Search - Optimized search for LLMs

Usage: $0 [OPTIONS] QUERY

Options:
    --api-key KEY           Tavily API key (or set TAVILY_API_KEY env var)
    --depth basic|advanced  Search depth: 'basic' (fast) or 'advanced' (comprehensive) [default: basic]
    --topic general|news    Search topic: 'general' or 'news' (current events) [default: general]
    --max-results NUM       Maximum number of results (1-10) [default: 5]
    --no-answer             Exclude AI-generated answer summary
    --raw-content           Include raw HTML content of sources
    --images                Include relevant images in results
    --include-domains DOMAINS  Space-separated list of domains to specifically include
    --exclude-domains DOMAINS  Space-separated list of domains to exclude
    --json                  Output raw JSON response
    --help                  Show this help message

Examples:
  # Basic search
  $0 "What is quantum computing?"
  
  # Advanced search with more results
  $0 "Climate change solutions" --depth advanced --max-results 10
  
  # News-focused search
  $0 "AI developments" --topic news
  
  # Domain filtering
  $0 "Python tutorials" --include-domains python.org --exclude-domains w3schools.com
  
  # Include images in results
  $0 "Eiffel Tower" --images
  
Environment Variables:
  TAVILY_API_KEY    Your Tavily API key (get one at https://tavily.com)
EOF
}

# Default values
API_KEY=""
SEARCH_DEPTH="basic"
TOPIC="general"
MAX_RESULTS=5
INCLUDE_ANSWER=true
INCLUDE_RAW_CONTENT=false
INCLUDE_IMAGES=false
INCLUDE_DOMAINS=()
EXCLUDE_DOMAINS=()
OUTPUT_JSON=false
QUERY=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --api-key)
            API_KEY="$2"
            shift 2
            ;;
        --depth)
            SEARCH_DEPTH="$2"
            shift 2
            ;;
        --topic)
            TOPIC="$2"
            shift 2
            ;;
        --max-results)
            MAX_RESULTS="$2"
            shift 2
            ;;
        --no-answer)
            INCLUDE_ANSWER=false
            shift
            ;;
        --raw-content)
            INCLUDE_RAW_CONTENT=true
            shift
            ;;
        --images)
            INCLUDE_IMAGES=true
            shift
            ;;
        --include-domains)
            shift
            while [[ $# -gt 0 && ! "$1" =~ ^-- ]]; do
                INCLUDE_DOMAINS+=("$1")
                shift
            done
            ;;
        --exclude-domains)
            shift
            while [[ $# -gt 0 && ! "$1" =~ ^-- ]]; do
                EXCLUDE_DOMAINS+=("$1")
                shift
            done
            ;;
        --json)
            OUTPUT_JSON=true
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        -*)
            echo "Unknown option: $1" >&2
            show_help >&2
            exit 1
            ;;
        *)
            QUERY="$1"
            shift
            ;;
    esac
done

# Check if query is provided
if [[ -z "$QUERY" ]]; then
    echo "Error: Search query is required" >&2
    show_help >&2
    exit 1
fi

# Get API key from argument or environment
if [[ -z "$API_KEY" ]]; then
    API_KEY="${TAVILY_API_KEY:-}"
fi

# Validate API key
if [[ -z "$API_KEY" ]]; then
    if [[ "$OUTPUT_JSON" == true ]]; then
        jq -n '{
            error: "Tavily API key required. Get one at https://tavily.com",
            setup_instructions: "Set TAVILY_API_KEY environment variable or pass --api-key"
        }'
    else
        echo "Error: Tavily API key required. Get one at https://tavily.com" >&2
        echo "" >&2
        echo "Setup: Set TAVILY_API_KEY environment variable or pass --api-key" >&2
        exit 1
    fi
    exit 1
fi

# Build JSON payload
build_payload() {
    local payload="{"
    payload+="\"query\":\"$QUERY\","
    payload+="\"search_depth\":\"$SEARCH_DEPTH\","
    payload+="\"topic\":\"$TOPIC\","
    payload+="\"max_results\":$MAX_RESULTS,"
    payload+="\"include_answer\":$INCLUDE_ANSWER,"
    payload+="\"include_raw_content\":$INCLUDE_RAW_CONTENT,"
    payload+="\"include_images\":$INCLUDE_IMAGES"
    
    # Add include_domains if provided
    if [[ ${#INCLUDE_DOMAINS[@]} -gt 0 ]]; then
        payload+=",\"include_domains\":["
        for i in "${!INCLUDE_DOMAINS[@]}"; do
            if [[ $i -gt 0 ]]; then
                payload+=","
            fi
            payload+="\"${INCLUDE_DOMAINS[$i]}\""
        done
        payload+="]"
    fi
    
    # Add exclude_domains if provided
    if [[ ${#EXCLUDE_DOMAINS[@]} -gt 0 ]]; then
        payload+=",\"exclude_domains\":["
        for i in "${!EXCLUDE_DOMAINS[@]}"; do
            if [[ $i -gt 0 ]]; then
                payload+=","
            fi
            payload+="\"${EXCLUDE_DOMAINS[$i]}\""
        done
        payload+="]"
    fi
    
    payload+="}"
    echo "$payload"
}

# Perform the search using curl
perform_search() {
    local payload
    payload=$(build_payload)
    
    local response
    response=$(curl -s -w "\n%{http_code}" \
        -X POST "https://api.tavily.com/search" \
        -H "Content-Type: application/json" \
        -d "$payload")
    
    local http_code
    http_code=$(echo "$response" | tail -n1)
    local body
    body=$(echo "$response" | head -n -1)
    
    # Check HTTP status code
    if [[ "$http_code" != "200" ]]; then
        if [[ "$OUTPUT_JSON" == true ]]; then
            jq -n --arg code "$http_code" --arg body "$body" '{
                error: ($code + ": " + $body),
                query: $ENV.QUERY
            }'
        else
            echo "Error: HTTP $http_code: $body" >&2
            exit 1
        fi
        exit 1
    fi
    
    echo "$body"
}

# Process and format the response
format_response() {
    local response="$1"
    
    if [[ "$OUTPUT_JSON" == true ]]; then
        echo "$response" | jq '{
            success: true,
            query: .query,
            answer: .answer,
            results: .results,
            images: .images,
            response_time: .response_time,
            usage: .usage
        }'
        return
    fi
    
    # Extract fields
    local query
    query=$(echo "$response" | jq -r '.query')
    local answer
    answer=$(echo "$response" | jq -r '.answer // empty')
    local response_time
    response_time=$(echo "$response" | jq -r '.response_time // "N/A"')
    local credits
    credits=$(echo "$response" | jq -r '.usage.credits // "N/A"')
    
    # Print header
    echo "Query: $query"
    echo "Response time: ${response_time}s"
    echo "Credits used: $credits"
    echo ""
    
    # Print answer if available
    if [[ -n "$answer" && "$answer" != "null" ]]; then
        echo "=== AI ANSWER ==="
        echo "$answer"
        echo ""
    fi
    
    # Print results
    local results_count
    results_count=$(echo "$response" | jq '.results | length')
    if [[ "$results_count" -gt 0 ]]; then
        echo "=== RESULTS ==="
        echo "$response" | jq -c '.results[]' | \
        jq -r 'to_entries[] | 
            "\n\(.key + 1). \(.value.title // "No title")\n   URL: \(.value.url // "N/A")\n   Score: \(.value.score // "N/A")" + 
            (if .value.content then 
                "\n   " + 
                (.value.content | if length > 200 then .[0:200] + "..." else . end)
             else "" end)'
    fi
    
    # Print images
    local images_count
    images_count=$(echo "$response" | jq '[.images[]] | length')
    if [[ "$images_count" -gt 0 ]]; then
        echo ""
        echo "=== IMAGES ($images_count) ==="
        echo "$response" | jq -r '.images[0:5][]' | sed 's/^/   /'
    fi
}

# Main execution
main() {
    # Check if jq is available
    if ! command -v jq &> /dev/null; then
        if [[ "$OUTPUT_JSON" == true ]]; then
            jq -n '{
                error: "jq is required but not installed",
                install_command: "Install jq using your package manager (apt, yum, brew, etc.)"
            }'
        else
            echo "Error: jq is required but not installed" >&2
            echo "" >&2
            echo "To install: Install jq using your package manager (apt, yum, brew, etc.)" >&2
            exit 1
        fi
        exit 1
    fi
    
    local response
    response=$(perform_search)
    
    # Check if response contains an error
    if echo "$response" | jq -e '.error' &> /dev/null; then
        if [[ "$OUTPUT_JSON" == true ]]; then
            echo "$response"
        else
            local error_msg
            error_msg=$(echo "$response" | jq -r '.error')
            echo "Error: $error_msg" >&2
            exit 1
        fi
        exit 1
    fi
    
    format_response "$response"
}

# Run main function
main
