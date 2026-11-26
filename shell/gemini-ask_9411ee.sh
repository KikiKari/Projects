#!/usr/bin/env bash
# abstraction-provenance: {"artifact_sha256": "1367fbd8ab81bd0cc515c647e7642967d0ffa5b516f3af687cc11f0a9fc46a8f", "source_sha256": "9411ee01f75190a7b3bf9f276fc6bb624d2c943629885c1ddfc9f71a0039070e", "target_language": "shell"}
# gemini-ask.js — portiert nach shell
# Quelle: javascript, OpenClaw@gateway1:scripts/gemini-ask.js
# auch in: OpenClaw@gateway2:scripts/gemini-ask.js
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# gemini-ask.sh - CLI tool for Google Gemini API
# 
# Usage:
#   gemini-ask.sh "Your question here"
#   echo "Your question" | gemini-ask.sh
#   gemini-ask.sh --file prompt.txt
#   gemini-ask.sh --model gemini-pro "Your question"
# 
# Environment:
#   GEMINI_API_KEY - Required API key
#   GEMINI_MODEL   - Optional default model (default: gemini-pro)

DEFAULT_MODEL="${GEMINI_MODEL:-gemini-pro}"

# Function to show usage
show_usage() {
    cat >&2 <<EOF
Error: No prompt provided
Usage: gemini-ask "your question"
       gemini-ask --model gemini-pro "your question"
       echo "your question" | gemini-ask
EOF
}

# Check API key
if [[ -z "${GEMINI_API_KEY:-}" ]]; then
    echo "Error: GEMINI_API_KEY environment variable is required" >&2
    exit 1
fi

# Parse arguments
prompt=""
modelName="$DEFAULT_MODEL"
systemPrompt=""
args=("$@")

# Process arguments
new_args=()
i=0
while [[ $i -lt ${#args[@]} ]]; do
    arg="${args[$i]}"
    case "$arg" in
        --model|-m)
            if [[ $((i + 1)) -lt ${#args[@]} ]]; then
                modelName="${args[$((i + 1))]}"
                i=$((i + 2))
            else
                echo "Error: --model requires an argument" >&2
                exit 1
            fi
            ;;
        --system|-s)
            if [[ $((i + 1)) -lt ${#args[@]} ]]; then
                systemPrompt="${args[$((i + 1))]}"
                i=$((i + 2))
            else
                echo "Error: --system requires an argument" >&2
                exit 1
            fi
            ;;
        --file|-f)
            if [[ $((i + 1)) -lt ${#args[@]} ]]; then
                filePath="${args[$((i + 1))]}"
                if [[ ! -r "$filePath" ]]; then
                    echo "Error: File '$filePath' not found or not readable" >&2
                    exit 1
                fi
                prompt=$(cat "$filePath")
                i=$((i + 2))
            else
                echo "Error: --file requires a file path" >&2
                exit 1
            fi
            ;;
        *)
            new_args+=("$arg")
            i=$((i + 1))
            ;;
    esac
done

# If no prompt yet, check remaining args or stdin
if [[ -z "$prompt" ]]; then
    if [[ ${#new_args[@]} -gt 0 ]]; then
        prompt="${new_args[*]}"
    elif [[ ! -t 0 ]]; then
        prompt=$(cat)
    fi
fi

# Validate prompt
if [[ -z "${prompt// /}" ]]; then
    show_usage
    exit 1
fi

# Prepare temporary files
temp_dir=$(mktemp -d)
trap 'rm -rf "$temp_dir"' EXIT
request_file="$temp_dir/request.json"
response_file="$temp_dir/response.json"

# Prepare the request body
if [[ -n "$systemPrompt" ]]; then
    # With system prompt, we simulate it by prepending to user message
    full_prompt="System instruction: $systemPrompt

User query: $prompt"
else
    full_prompt="$prompt"
fi

# Create JSON payload
cat > "$request_file" <<EOF
{
  "contents": [{
    "role": "user",
    "parts": [{"text": "$full_prompt"}]
  }],
  "generationConfig": {
    "maxOutputTokens": 8192,
    "temperature": 0.7,
    "topP": 0.95
  }
}
EOF

# Make API call using curl
api_url="https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$GEMINI_API_KEY"

http_status=$(curl -s -w "%{http_code}" -X POST \
    -H "Content-Type: application/json" \
    -d "@$request_file" \
    "$api_url" -o "$response_file")

# Check HTTP status
if [[ "$http_status" -ge 400 ]]; then
    echo "Error: HTTP $http_status" >&2
    if [[ -f "$response_file" ]]; then
        jq -r '.error.message // "Unknown error"' "$response_file" >&2
    fi
    if grep -q "API_KEY" "$response_file" 2>/dev/null; then
        echo "Make sure GEMINI_API_KEY is set correctly" >&2
    fi
    exit 1
fi

# Extract and print response text
jq -r '.candidates[0].content.parts[0].text // "No response generated."' "$response_file"
