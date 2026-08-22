#!/usr/bin/env bash
# update_readme_stats.py — portiert nach shell
# Quelle: python, OpenClaw@main:scripts/update_readme_stats.py
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Fetch ClawHub stats and update README.md download counts and security status.

API_BASE="https://clawhub.ai/api/v1"
TOKEN="${CLAWHUB_TOKEN:-}"

# Declare associative arrays for skills
declare -A SKILLS=(
    ["Cluster Gateway"]="cluster-gateway"
    ["MCP Tool Utils"]="mcp-tool-utils"
    ["Reports Creator"]="reports-creator"
    ["Relay Node"]="relay-node"
    ["JSON Utils"]="json-utils"
    ["Log Collector"]="log-collector"
    ["TikTok Live Monitor"]="tiktok-live-monitor"
    ["Doc Scraper"]="doc-scraper"
    ["Workspace Database Manager"]="workspace-database-manager"
    ["Scripting Utils"]="scripting-utils"
)

fetch_skill() {
    local slug="$1"
    local url="${API_BASE}/skills/${slug}"
    local headers=("-H" "Accept: application/json")
    
    if [[ -n "$TOKEN" ]]; then
        headers+=("-H" "Authorization: Bearer ${TOKEN}")
    fi
    
    curl -s --fail-with-body -m 10 "${headers[@]}" "$url"
}

parse_skill() {
    local json_data="$1"
    
    # Extract fields using jq
    local downloads version mod_is_malware_blocked mod_exists
    
    downloads=$(echo "$json_data" | jq -r '.skill.stats.downloads // 0')
    version=$(echo "$json_data" | jq -r '.latestVersion.version // "1.0.0"')
    mod_exists=$(echo "$json_data" | jq -e '.moderation != null' >/dev/null && echo "true" || echo "false")
    
    if [[ "$mod_exists" == "false" ]]; then
        security="✅ Pass"
    else
        mod_is_malware_blocked=$(echo "$json_data" | jq -r '.moderation.isMalwareBlocked')
        if [[ "$mod_is_malware_blocked" == "true" ]]; then
            security="🚫 Blocked"
        else
            security="🔍 Review"
        fi
    fi
    
    # Ensure version starts with 'v'
    if [[ ! "$version" =~ ^v ]]; then
        version="v${version}"
    fi
    
    echo "$downloads|$version|$security"
}

main() {
    declare -A stats
    local errors=0
    local name slug data result
    
    for name in "${!SKILLS[@]}"; do
        slug="${SKILLS[$name]}"
        
        if data=$(fetch_skill "$slug" 2>/dev/null); then
            if result=$(parse_skill "$data" 2>/dev/null); then
                IFS='|' read -r downloads version security <<<"$result"
                stats["$slug"]="$downloads|$version|$security"
                echo "  OK  $slug: $downloads downloads, $version, $security"
            else
                echo "  ERR $slug: Failed to parse response" >&2
                ((errors++))
            fi
        else
            echo "  ERR $slug: Failed to fetch data" >&2
            ((errors++))
        fi
    done
    
    if [[ ${#stats[@]} -eq 0 ]]; then
        echo "No data fetched — aborting." >&2
        exit 1
    fi
    
    # Read README.md into variable
    local content
    content=$(cat README.md)
    
    # Update download counts
    for name in "${!SKILLS[@]}"; do
        slug="${SKILLS[$name]}"
        
        if [[ -n "${stats[$slug]:-}" ]]; then
            IFS='|' read -r downloads _ _ <<<"${stats[$slug]}"
            
            # Escape special regex characters in name
            local escaped_name
            escaped_name=$(printf '%s\n' "$name" | sed 's/[]\/$*.^|()+{}[]/\\&/g')
            
            # Pattern matches the line with the skill name and replaces the download count
            # The pattern looks for: | [Name](...)| ... | <digits> |
            # And replaces the digits with the new download count
            content=$(echo "$content" | perl -pe "s/(\\|\\s*\\[?$escaped_name\\]?[^|]*\\|[^|]*\\|)\\s*\\d+\\s*(\\|)/\$1 $downloads \$2/i")
            
            if grep -q "$name" README.md && ! grep -q "$downloads" <<<"$content"; then
                echo "  Updated: $name -> $downloads"
            fi
        fi
    done
    
    # Write updated content back to README.md
    echo "$content" > README.md
    
    echo "Done: ${#stats[@]} skills, $errors errors."
}

main "$@"
