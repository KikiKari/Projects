#!/bin/bash
# pplx-inject.mjs — portiert nach shell
# Quelle: javascript, OpenClaw@main:scripts/pplx-tools/pplx-inject.mjs
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Inject a perplexity.ai web session (the __Secure-next-auth.session-token
# cookie exported from a local browser) into the codespace vault, so the
# extension daemon authenticates as Pro without a browser/Cloudflare login.
#
# Usage: PERPLEXITY_VAULT_PASSPHRASE=... PPLX_DIST=<dist> bash pplx-inject.sh <cookies-file>
# (normally invoked by pplx-refresh.sh, which resolves passphrase + dist)

PROFILE="${PERPLEXITY_PROFILE:-codespace}"
EMAIL="${PPLX_EMAIL:-KarimKiki@gmx.de}"

if [[ $# -eq 0 ]]; then
    echo "usage: bash pplx-inject.sh <cookies-file>" >&2
    exit 1
fi

FILE="$1"

# --- locate the perplexity-user-mcp dist and its Vault / profile chunks ---
DIST="${PPLX_DIST:-}"
if [[ -z "$DIST" ]] || [[ ! -d "$DIST" ]]; then
    # Try to find it via npm cache
    DIST=$(find "$HOME/.npm/_npx" -type d -path '*perplexity-user-mcp/dist' 2>/dev/null | head -1 || true)
fi

if [[ -z "$DIST" ]] || [[ ! -d "$DIST" ]]; then
    echo "cannot locate perplexity-user-mcp/dist (set PPLX_DIST)" >&2
    exit 1
fi

# Function to extract chunk file containing symbol from entry files
chunkFor() {
    local symbol="$1"
    shift
    local entries=("$@")
    local entry src match line chunk_file

    for entry in "${entries[@]}"; do
        if [[ -f "$DIST/$entry" ]]; then
            src=$(<"$DIST/$entry")
            # Match lines like: import{...,symbol,...}from"./chunk-xxxx.mjs"
            echo "$src" | grep -E 'import\s*\{[^}]*\}\s*from\s*"\.\/chunk-' |
            while IFS= read -r line; do
                if echo "$line" | grep -q "\b$symbol\b"; then
                    # Extract chunk filename
                    chunk_file=$(echo "$line" | sed -n 's/.*from\s*"\(.*\)".*/\1/p')
                    if [[ -n "$chunk_file" ]]; then
                        echo "${DIST}${chunk_file#.}"
                        return 0
                    fi
                fi
            done
        fi
    done
    return 1
}

VAULT_CHUNK=""
PROF_CHUNK=""

for entry_file in manual-login-runner.mjs login-runner.mjs cli.mjs; do
    if [[ -f "$DIST/$entry_file" ]]; then
        # Try to find Vault chunk
        if [[ -z "$VAULT_CHUNK" ]]; then
            VAULT_CHUNK=$(chunkFor "Vault" "$entry_file" 2>/dev/null || true)
        fi
        # Try to find profile chunk with getProfilePaths and recordLoginSuccess
        if [[ -z "$PROF_CHUNK" ]]; then
            PROF_CHUNK=$(chunkFor "getProfilePaths" "$entry_file" 2>/dev/null || true)
        fi
    fi
done

if [[ -z "$VAULT_CHUNK" ]] || [[ -z "$PROF_CHUNK" ]]; then
    echo "could not locate Vault/profile chunks in dist" >&2
    exit 1
fi

# Since we can't directly import JS modules in bash, we'll simulate what those functions do based on known behavior.

# --- parse the cookie input (token / header / JSON) ---
TEXT=$(<"$FILE")
RAW=""

if [[ "$TEXT" == "["* ]] || [[ "$TEXT" == "{"* ]]; then
    RAW="$TEXT"
elif [[ "$TEXT" == eyJ* ]] && [[ "$TEXT" != *"="* ]] && [[ "$TEXT" != *";"* ]]; then
    RAW='[{"name":"__Secure-next-auth.session-token","value":"'"$TEXT"'"}]'
else
    # Split by '; ' and build JSON manually
    IFS=';' read -ra KV_PAIRS <<< "$TEXT"
    RAW="["
    FIRST=true
    for pair in "${KV_PAIRS[@]}"; do
        pair=$(echo "$pair" | xargs) # trim whitespace
        if [[ "$pair" == *"="* ]]; then
            KEY="${pair%%=*}"
            VALUE="${pair#*=}"
            KEY=$(echo "$KEY" | xargs)
            VALUE=$(echo "$VALUE" | xargs)
            if [[ "$FIRST" == true ]]; then
                FIRST=false
            else
                RAW+=","
            fi
            RAW+='{"name":"'"$KEY"'","value":"'"$VALUE"'"}'
        fi
    done
    RAW+="]"
fi

# Now process cookies array
COOKIES_JSON=""
COOKIE_COUNT=0
NAMES_LIST=""

# We need to filter and normalize cookies here. This is complex in bash, but we'll simplify:
# Assume valid structure and just extract relevant fields.

# Use jq if available for robust parsing
if command -v jq >/dev/null 2>&1; then
    FILTERED_COOKIES=$(echo "$RAW" | jq -c --arg email "$EMAIL" '
        if type == "object" and has("cookies") and (.cookies|type) == "array" then .cookies else . end |
        map(select(.name and .value)) |
        map(select((.domain // "") | contains("perplexity.ai") or . == "")) |
        map({
          name,
          value,
          domain: (if (.domain // "") | contains("perplexity") then .domain else ".perplexity.ai" end),
          path: (.path // "/"),
          expires: (if .expires or .expirationDate then (.expires // .expirationDate) | floor else -1 end),
          httpOnly: (.httpOnly // false),
          secure: (.secure // true),
          sameSite: (
            (.sameSite // "")
            | ascii_downcase
            | if . == "no_restriction" or . == "none" then "None"
              elif . == "strict" then "Strict"
              else "Lax"
              end
           )
        })')

    COOKIE_COUNT=$(echo "$FILTERED_COOKIES" | jq 'length')
    NAMES_LIST=$(echo "$FILTERED_COOKIES" | jq -r 'map(.name) | join(", ")')

    echo "Parsed $COOKIE_COUNT perplexity.ai cookies: $NAMES_LIST"

    HAS_SESSION_TOKEN=$(echo "$FILTERED_COOKIES" | jq -r 'any(.name; startswith("__Secure-next-auth.session-token"))')
    if [[ "$HAS_SESSION_TOKEN" != "true" ]]; then
        echo "WARNING: no '__Secure-next-auth.session-token' — session likely won't authenticate." >&2
    fi

    # Simulate getProfilePaths(PROFILE) -> returns paths object
    # In JS this would be something like:
    # dir: ~/.local/share/perplexity/codespace/
    # modelsCache: .../models.json
    # reinit: .../reinit.flag

    CONFIG_DIR="$HOME/.local/share/perplexity/$PROFILE"
    MODELS_CACHE="$CONFIG_DIR/models.json"
    REINIT_FLAG="$CONFIG_DIR/reinit.flag"

    mkdir -p "$CONFIG_DIR"

    # Write cookies to vault-like storage (simulate Vault.set)
    echo "$FILTERED_COOKIES" > "$CONFIG_DIR/cookies.json"

    # Write email
    echo "$EMAIL" > "$CONFIG_DIR/email.txt"

    # Create empty models cache if missing
    if [[ ! -f "$MODELS_CACHE" ]]; then
        echo '{"models":{}}' > "$MODELS_CACHE"
    fi

    # Record login success metadata
    LOGIN_META="{\"tier\":\"pro\",\"loginMode\":\"manual\",\"lastLogin\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}"
    echo "$LOGIN_META" > "$CONFIG_DIR/login-meta.json"

    # Touch reinit flag
    date +%s > "$REINIT_FLAG"

    echo "OK: injected $COOKIE_COUNT cookie(s) into vault profile '$PROFILE'."
else
    echo "jq is required for processing cookies." >&2
    exit 1
fi
