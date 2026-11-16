#!/bin/bash
# github_publisher.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/github_publisher.py
# Erzeugt: 2026-11-16 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Publish queued, provenance-checked artifacts without staging unrelated files.

queue_artifact() {
    local state_file="$1"
    local root="$2"
    local path="$3"

    # Resolve paths
    root=$(realpath "$root")
    abs_path=$(realpath "$path")

    # Check if path is a symlink
    if [[ -L "$path" ]]; then
        echo "artifact must not be a symlink" >&2
        return 1
    fi

    # Get relative path
    local relative
    relative=$(realpath --relative-to="$root" "$abs_path" 2>/dev/null) || {
        echo "failed to compute relative path" >&2
        return 1
    }

    # Check if inside language directories
    local first_part
    first_part=$(echo "$relative" | cut -d'/' -f1)
    case "$first_part" in
        perl5|powershell|perl6|tcl|javascript|ruby|python|lua|shell|go)
            ;;
        *)
            echo "artifact is outside a language directory" >&2
            return 1
            ;;
    esac

    # Compute SHA256 hash
    local sha256
    sha256=$(sha256sum "$path" | awk '{print $1}')

    # Update state JSON
    jq --arg rel "$relative" --arg hash "$sha256" \
       '.ausstehende_veroeffentlichungen[$rel] = $hash' \
       "$state_file" > tmp.json && mv tmp.json "$state_file"
}

publish_pending() {
    local root="$1"
    local state_file="$2"
    local save_cmd="$3"
    local token="$4"

    # Check token
    if [[ -z "${token:-}" ]] || [[ "${token// /}" == "" ]]; then
        return 1
    fi

    root=$(realpath "$root")

    # Read pending publications
    local pending
    pending=$(jq -r 'if .ausstehende_veroeffentlichungen | type == "object" then .ausstehende_veroeffentlichungen else {} end' "$state_file")

    # Check if empty
    if [[ "$(echo "$pending" | jq length)" -eq 0 ]]; then
        return 0
    fi

    local success=0

    # Process each entry
    echo "$pending" | jq -r 'to_entries[] | "\(.key):\(.value)"' | while IFS=: read -r name expected; do
        (
            set +e
            # Re-check path safety
            local full_path="$root/$name"
            if [[ -L "$full_path" ]]; then
                echo "invalid queued path" >&2
                exit 1
            fi

            local resolved
            resolved=$(realpath "$full_path" 2>/dev/null) || {
                echo "invalid queued path" >&2
                exit 1
            }

            local computed_rel
            computed_rel=$(realpath --relative-to="$root" "$resolved" 2>/dev/null) || {
                echo "invalid queued path" >&2
                exit 1
            }

            if [[ "$computed_rel" != "$name" ]]; then
                echo "invalid queued path" >&2
                exit 1
            fi

            # Check hash
            local current_hash
            current_hash=$(sha256sum "$full_path" | awk '{print $1}')
            if [[ "$current_hash" != "$expected" ]]; then
                echo "queued artifact changed" >&2
                exit 1
            fi

            # Function to lookup remote content
            lookup() {
                local remote_name="$1"
                local encoded
                encoded=$(printf '%s' "$remote_name" | jq -sRr @uri)
                local url="https://api.github.com/repos/KikiKari/OpenClaw/contents/$encoded?ref=gateway1-abstractions"
                curl -s -H "Authorization: Bearer $token" \
                     -H "Accept: application/vnd.github+json" \
                     -H "X-GitHub-Api-Version: 2022-11-28" \
                     -H "User-Agent: abstractions-manager" \
                     -w "%{http_code}" \
                     "$url" 2>/tmp/curl_response_body.txt > /tmp/curl_response_code.txt
                local code
                code=$(cat /tmp/curl_response_code.txt)
                if [[ "$code" == "404" ]]; then
                    echo "null"
                elif [[ "$code" == "200" ]]; then
                    cat /tmp/curl_response_body.txt
                else
                    cat /tmp/curl_response_body.txt >&2
                    exit 1
                fi
            }

            # Compare function
            same() {
                local content="$1"
                if [[ "$content" == "null" ]]; then
                    return 1
                fi
                local encoding
                encoding=$(echo "$content" | jq -r '.encoding // empty')
                if [[ "$encoding" != "base64" ]]; then
                    return 1
                fi
                local remote_data
                remote_data=$(echo "$content" | jq -r '.content // empty')
                local decoded
                decoded=$(echo "$remote_data" | base64 -d)
                local original
                original=$(cat "$full_path")
                if [[ "$decoded" == "$original" ]]; then
                    return 0
                else
                    return 1
                fi
            }

            # Lookup original name
            local existing_content
            existing_content=$(lookup "$name")
            local conflict=false

            if [[ "$existing_content" != "null" ]] && ! same "$existing_content"; then
                # Conflict resolution
                local candidate_stem candidate_suffix alternate_name
                candidate_stem=$(basename "$name" | sed 's/\.[^.]*$//' )
                candidate_suffix=$(basename "$name" | sed 's/.*\././')
                local short_expected="${expected:0:12}"
                alternate_name="$(dirname "$name")/${candidate_stem}_${short_expected}${candidate_suffix}"

                existing_content=$(lookup "$alternate_name")
                if [[ "$existing_content" != "null" ]] && ! same "$existing_content"; then
                    echo "remote artifact conflict" >&2
                    exit 1
                fi
                name="$alternate_name"
            fi

            # Upload if needed
            if [[ "$existing_content" == "null" ]]; then
                local b64data
                b64data=$(base64 -w0 < "$full_path")
                local body
                body=$(jq -n --arg msg "Publish script abstraction" --arg branch "gateway1-abstractions" --arg cnt "$b64data" \
                         '{message: $msg, branch: $branch, content: $cnt}')

                local encoded_name
                encoded_name=$(printf '%s' "$name" | jq -sRr @uri)
                local upload_url="https://api.github.com/repos/KikiKari/OpenClaw/contents/$encoded_name"

                curl -s -X PUT \
                     -H "Authorization: Bearer $token" \
                     -H "Accept: application/vnd.github+json" \
                     -H "X-GitHub-Api-Version: 2022-11-28" \
                     -H "User-Agent: abstractions-manager" \
                     -d "$body" \
                     "$upload_url" >/dev/null
            fi

            # Remove from queue
            jq --arg rel "$name" 'del(.ausstehende_veroeffentlichungen[$rel])' "$state_file" > tmp.json && mv tmp.json "$state_file"
            eval "$save_cmd"
        ) || {
            success=1
        }
    done

    return $success
}
