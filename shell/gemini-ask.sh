#!/usr/bin/env bash
# gemini-ask.js — portiert nach shell
# Quelle: javascript, OpenClaw@gateway1:scripts/gemini-ask.js
# auch in: OpenClaw@gateway2:scripts/gemini-ask.js
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

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

# Check for --model flag
for i in "${!args[@]}"; do
  if [[ "${args[i]}" == "--model" || "${args[i]}" == "-m" ]]; then
    if [[ $((i + 1)) -lt ${#args[@]} ]]; then
      modelName="${args[i+1]}"
      unset 'args[i]'
      unset 'args[i+1]'
      break
    fi
  fi
done

# Check for --system flag
for i in "${!args[@]}"; do
  if [[ "${args[i]}" == "--system" || "${args[i]}" == "-s" ]]; then
    if [[ $((i + 1)) -lt ${#args[@]} ]]; then
      systemPrompt="${args[i+1]}"
      unset 'args[i]'
      unset 'args[i+1]'
      break
    fi
  fi
done

# Re-index args array
args=("${args[@]}")

if [[ " ${args[*]} " =~ " --file " ]] || [[ " ${args[*]} " =~ " -f " ]]; then
  fileIndex=-1
  for i in "${!args[@]}"; do
    if [[ "${args[i]}" == "--file" || "${args[i]}" == "-f" ]]; then
      fileIndex=$i
      break
    fi
  done

  if [[ $fileIndex -eq -1 ]] || [[ $((fileIndex + 1)) -ge ${#args[@]} ]]; then
    echo "Error: No file specified" >&2
    exit 1
  fi

  filePath="${args[fileIndex+1]}"
  if [[ ! -f "$filePath" ]]; then
    echo "Error: File not found: $filePath" >&2
    exit 1
  fi

  prompt=$(cat "$filePath")
  # Remove --file and path from args
  unset 'args[fileIndex]'
  unset 'args[fileIndex+1]'
  args=("${args[@]}")
elif [[ ${#args[@]} -gt 0 ]]; then
  prompt="${args[*]}"
elif [[ ! -t 0 ]]; then
  # Read from stdin
  prompt=$(cat)
fi

if [[ -z "${prompt// }" ]]; then
  echo "Error: No prompt provided" >&2
  echo "Usage: gemini-ask \"your question\"" >&2
  echo "       gemini-ask --model gemini-pro \"your question\"" >&2
  echo "       echo \"your question\" | gemini-ask" >&2
  exit 1
fi

# Prepare generation config
maxOutputTokens=8192
temperature=0.7
topP=0.95

# Build JSON payload
if [[ -n "$systemPrompt" ]]; then
  # Use chat with system prompt
  jsonData=$(jq -n \
    --arg model "$modelName" \
    --arg prompt "$prompt" \
    --arg systemPrompt "$systemPrompt" \
    --argjson maxTokens "$maxOutputTokens" \
    --argjson temp "$temperature" \
    --argjson topP "$topP" \
    '{
      model: $model,
      messages: [
        {role: "system", content: $systemPrompt},
        {role: "user", content: $prompt}
      ],
      generationConfig: {
        maxOutputTokens: $maxTokens,
        temperature: $temp,
        topP: $topP
      }
    }')
else
  # Direct generation
  jsonData=$(jq -n \
    --arg model "$modelName" \
    --arg prompt "$prompt" \
    --argjson maxTokens "$maxOutputTokens" \
    --argjson temp "$temperature" \
    --argjson topP "$topP" \
    '{
      model: $model,
      prompt: $prompt,
      generationConfig: {
        maxOutputTokens: $maxTokens,
        temperature: $temp,
        topP: $topP
      }
    }')
fi

# Make API request
response=$(curl -s -w "\n%{http_code}" \
  -H "Content-Type: application/json" \
  -H "x-goog-api-key: $GEMINI_API_KEY" \
  -d "$jsonData" \
  "https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent")

# Extract response body and HTTP status code
httpCode="${response##*$'\n'}"
responseBody="${response%$'\n'*}"

# Check HTTP status
if [[ "$httpCode" -ne 200 ]]; then
  echo "Error: HTTP $httpCode" >&2
  echo "$responseBody" >&2
  if echo "$responseBody" | grep -q "API_KEY"; then
    echo "Make sure GEMINI_API_KEY is set correctly" >&2
  fi
  exit 1
fi

# Extract and print the response text
echo "$responseBody" | jq -r '.candidates[0].content.parts[0].text'
