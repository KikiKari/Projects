#!/usr/bin/env bash
# scrape_to_markdown.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:skills/web-markdown-scraper/scripts/scrape_to_markdown.py
# auch in: OpenClaw@gateway2:skills/web-markdown-scraper/scripts/scrape_to_markdown.py
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# SECURITY MANIFEST:
# Environment variables accessed: none
# External endpoints called: only URLs supplied by the user at runtime via --url / --url-file
# Local files read: --url-file path (if provided by user)
# Local files written: --output-dir/*.md, --output-dir/index.json (if --output-dir provided)
# Shell injection risk: none (no eval, no command substitution with untrusted input)

# Default values
urls=()
url_file=""
selector=""
js=false
wait_selector=""
preserve_links=false
body_width=0
timeout=30
output_dir="outputs"
automatch_domain=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --url)
            urls+=("$2")
            shift 2
            ;;
        --url-file)
            url_file="$2"
            shift 2
            ;;
        --selector)
            selector="$2"
            shift 2
            ;;
        --js)
            js=true
            shift
            ;;
        --wait-selector)
            wait_selector="$2"
            shift 2
            ;;
        --preserve-links)
            preserve_links=true
            shift
            ;;
        --body-width)
            body_width="$2"
            shift 2
            ;;
        --timeout)
            timeout="$2"
            shift 2
            ;;
        --output-dir)
            output_dir="$2"
            shift 2
            ;;
        --automatch-domain)
            automatch_domain="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

# Load URLs from file if provided
if [[ -n "$url_file" ]]; then
    while IFS= read -r line; do
        line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' ) # trim whitespace
        if [[ -n "$line" && ! "$line" =~ ^# ]]; then
            urls+=("$line")
        fi
    done < "$url_file"
fi

# Remove duplicates while preserving order
declare -A seen
clean_urls=()
for u in "${urls[@]}"; do
    if [[ -z "${seen[$u]+isset}" ]]; then
        clean_urls+=("$u")
        seen["$u"]=1
    fi
done
urls=("${clean_urls[@]}")

# Validate URLs
for u in "${urls[@]}"; do
    if ! echo "$u" | grep -qE '^https?://[^/]+'; then
        echo "{\"ok\":false,\"error\":\"Invalid URL: $u\"}"
        exit 1
    fi
done

# Check if any URLs were provided
if [[ ${#urls[@]} -eq 0 ]]; then
    echo "{\"ok\":false,\"error\":\"No URLs provided\"}"
    exit 1
fi

# Create output directory
mkdir -p "$output_dir"

# Initialize results array
results=()
success_count=0
failure_count=0

# Process each URL
for url in "${urls[@]}"; do
    # Initialize result item
    item="{\"url\":\"$url\",\"ok\":false,\"title\":\"\",\"status\":null,\"selector_used\":null,\"backend\":null,\"markdown\":\"\",\"preview\":\"\",\"output_markdown_file\":null,\"error\":null}"
    
    # Try to fetch page
    temp_html=$(mktemp)
    temp_md=$(mktemp)
    
    # Determine fetch method based on JS flag
    if [[ "$js" == true ]]; then
        # For JS-enabled fetching, we'd need a tool like pup or playwright-cli
        # This is a simplified version that doesn't fully replicate scrapling's JS capabilities
        if command -v pup >/dev/null 2>&1; then
            if [[ -n "$wait_selector" ]]; then
                # Wait for selector (simplified)
                curl -s -L --max-time "$timeout" "$url" | pup "body" > "$temp_html"
            else
                curl -s -L --max-time "$timeout" "$url" > "$temp_html"
            fi
            backend="curl+pup"
        else
            echo "{\"ok\":false,\"error\":\"JS mode requires 'pup' tool but it's not installed\"}"
            exit 1
        fi
    else
        # Standard HTTP fetch
        if ! curl -s -L --max-time "$timeout" "$url" > "$temp_html"; then
            item=$(echo "$item" | jq --arg error "Failed to fetch URL" '.error = $error')
            results+=("$item")
            ((failure_count++))
            rm -f "$temp_html" "$temp_md"
            continue
        fi
        backend="curl"
    fi
    
    # Extract main content using selector if provided
    selected_html=""
    selector_used=""
    
    if [[ -n "$selector" ]]; then
        if command -v pup >/dev/null 2>&1; then
            selected_html=$(cat "$temp_html" | pup "$selector" 2>/dev/null || echo "")
            if [[ -n "$selected_html" && ${#selected_html} -ge 120 ]]; then
                selector_used="$selector"
            fi
        fi
    fi
    
    # If no specific selector worked, try common selectors
    if [[ -z "$selected_html" ]]; then
        common_selectors=("article" "main" "[role='main']" ".post-content" ".entry-content" ".article-content" "body")
        for sel in "${common_selectors[@]}"; do
            if command -v pup >/dev/null 2>&1; then
                selected_html=$(cat "$temp_html" | pup "$sel" 2>/dev/null || echo "")
                if [[ -n "$selected_html" && ${#selected_html} -ge 120 ]]; then
                    selector_used="$sel"
                    break
                fi
            fi
        done
    fi
    
    # Fallback to full HTML if nothing else works
    if [[ -z "$selected_html" ]]; then
        selected_html=$(cat "$temp_html")
        selector_used=""
    fi
    
    # Extract title from HTML
    title=$(echo "$selected_html" | grep -iPo '<title[^>]*>\K.*?(?=</title>)' | sed 's/<[^>]*>//g' | tr -s ' ')
    if [[ -z "$title" ]]; then
        title=$(echo "$url" | sed -E 's|^https?://||' | cut -d'/' -f1)
    fi
    
    # Convert HTML to Markdown
    if command -v pandoc >/dev/null 2>&1; then
        # Use pandoc for better conversion
        if [[ "$preserve_links" == true ]]; then
            echo "$selected_html" | pandoc -f html -t markdown --wrap=none > "$temp_md"
        else
            echo "$selected_html" | pandoc -f html -t markdown --wrap=none --strip-links > "$temp_md"
        fi
    elif command -v html2text >/dev/null 2>&1; then
        # Fallback to html2text
        if [[ "$preserve_links" == true ]]; then
            echo "$selected_html" | html2text -width "$body_width" > "$temp_md"
        else
            echo "$selected_html" | html2text -width "$body_width" -links 0 > "$temp_md"
        fi
    else
        # Very basic fallback - just strip tags
        echo "$selected_html" | sed 's/<[^>]*>//g' > "$temp_md"
    fi
    
    # Clean up markdown
    markdown=$(cat "$temp_md" | sed '/^$/N;/^\n$/D' | head -c 100000) # Limit size
    
    # Generate filename
    domain=$(echo "$url" | sed -E 's|^https?://||' | cut -d'/' -f1)
    filename_safe_title=$(echo "$domain-$title" | sed -E 's/[^a-zA-Z0-9 _-]//g' | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-80)
    if [[ -z "$filename_safe_title" ]]; then
        filename_safe_title="page"
    fi
    filename="${filename_safe_title}.md"
    md_path="$output_dir/$filename"
    
    # Write markdown file
    echo "$markdown" > "$md_path"
    
    # Create preview (first 1200 chars)
    preview=$(echo "$markdown" | head -c 1200)
    
    # Update item with success data
    item=$(echo "{}" | jq -n \
        --arg url "$url" \
        --argjson ok true \
        --arg title "$title" \
        --argjson status null \
        --arg selector_used "$selector_used" \
        --arg backend "$backend" \
        --arg markdown "$markdown" \
        --arg preview "$preview" \
        --arg output_markdown_file "$md_path" \
        '{url: $url, ok: $ok, title: $title, status: $status, selector_used: $selector_used, backend: $backend, markdown: $markdown, preview: $preview, output_markdown_file: $output_markdown_file, error: null}')
    
    results+=("$item")
    ((success_count++))
    
    # Cleanup
    rm -f "$temp_html" "$temp_md"
done

# Build final JSON output
index_path="$output_dir/index.json"
payload=$(jq -n \
    --argjson ok $( [[ $success_count -gt 0 ]] && echo true || echo false ) \
    --argjson count ${#results[@]} \
    --argjson success_count $success_count \
    --argjson failure_count $failure_count \
    --arg output_index_file "$index_path" \
    --argjson results "[]" \
    '{ok: $ok, count: $count, success_count: $success_count, failure_count: $failure_count, output_index_file: $output_index_file, results: $results}')

# Add results to payload
for result in "${results[@]}"; do
    payload=$(echo "$payload" | jq --argjson result "$result" '.results += [$result]')
done

# Write index file
echo "$payload" | jq '.' > "$index_path"

# Output final JSON
echo "$payload" | jq -c '.'
