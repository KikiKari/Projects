#!/bin/bash
# abstraction-provenance: {"artifact_sha256": "4a4879f1f6fc00235b70d50b3be1402a842ecab2ce6377dfb9f1bc63866da426", "source_sha256": "12c3ea0e67b1e873ac253df6f3f06d5ed42b603005d56186c531d8a5b0d7f377", "target_language": "shell"}
# gateway_transport.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/gateway_transport.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Gateway-authenticated transport with manager-owned attempt records.
#
# An attempt is saved before submission. If its outcome is uncertain, subsequent
# calls only query the same node and attempt; they do not submit it again.

# Custom error codes
TRANSPORT_UNRESOLVED=99

# Function to exit with TransportUnresolved error
transport_unresolved() {
    echo "$1" >&2
    exit $TRANSPORT_UNRESOLVED
}

# Use the local Gateway credential without changing its configuration.
gateway_token() {
    local token="${OPENCLAW_GATEWAY_TOKEN:-}"
    if [[ -n "$token" ]]; then
        echo "$token"
        return
    fi
    
    local config_path="${OPENCLAW_CONFIG_PATH:-$HOME/.openclaw/openclaw.json}"
    if [[ ! -f "$config_path" ]]; then
        echo ""
        return
    fi
    
    # Extract token from JSON config
    token=$(jq -r '.gateway.auth.token // ""' "$config_path" 2>/dev/null || echo "")
    
    # Check if token starts with ${ (environment variable placeholder)
    if [[ "$token" == \$\{* ]]; then
        echo ""
        return
    fi
    
    echo "$token"
}

# Main GatewayTransport function
gateway_transport() {
    local state_file="$1"
    local url="$2"
    local token="$3"
    local timeout="${4:-3900}"
    local interval="${5:-3}"
    
    # Validate URL
    if [[ ! "$url" =~ ^https?://[^/]+ ]]; then
        echo "invalid Gateway URL" >&2
        return 1
    fi
    
    local scheme hostname
    scheme=$(echo "$url" | sed -E 's|^([^:]+)://.*|\1|')
    hostname=$(echo "$url" | sed -E 's|^[^:]+://([^/]+).*|\1|' | cut -d: -f1)
    
    if [[ "$scheme" == "http" ]] && [[ ! "$hostname" =~ ^(127\.0\.0\.1|localhost|::1)$ ]]; then
        echo "unencrypted Gateway must use loopback" >&2
        return 1
    fi
    
    if [[ -z "$token" ]] || [[ "$timeout" -le 0 ]] || [[ "$interval" -le 0 ]]; then
        echo "Gateway token and positive timeouts required" >&2
        return 1
    fi
    
    # Export variables for internal functions
    export GATEWAY_URL="$url"
    export GATEWAY_TOKEN="$token"
    export STATE_FILE="$state_file"
    export TIMEOUT="$timeout"
    export INTERVAL="$interval"
}

# Internal function to make requests
_request() {
    local node="$1"
    local request="$2"
    local device_id="${3:-null}"
    
    # Create payload
    local payload
    if [[ "$device_id" == "null" ]]; then
        payload=$(jq -n --arg node "$node" --argjson request "$request" '{node: $node, request: $request}')
    else
        payload=$(jq -n --arg node "$node" --arg device_id "$device_id" --argjson request "$request" '{node: $node, device_id: $device_id, request: $request}')
    fi
    
    # Determine timeout
    local req_timeout=40
    if [[ "$node" == "node4" ]]; then
        req_timeout=150
    fi
    
    # Make request
    local response_file
    response_file=$(mktemp)
    trap "rm -f '$response_file'" EXIT
    
    if ! curl -s -H "Authorization: Bearer $GATEWAY_TOKEN" \
              -H "Content-Type: application/json" \
              -d "$payload" \
              --max-time "$req_timeout" \
              "$GATEWAY_URL" > "$response_file"; then
        transport_unresolved "Gateway request failed"
    fi
    
    # Check response size (approximate limit)
    if [[ $(wc -c < "$response_file") -gt 4000000 ]]; then
        rm -f "$response_file"
        transport_unresolved "response too large"
    fi
    
    # Validate response structure
    if ! jq -e 'type == "object" and has("result")' "$response_file" >/dev/null 2>&1; then
        rm -f "$response_file"
        transport_unresolved "invalid gateway response"
    fi
    
    # Check device_id if provided
    if [[ "$device_id" != "null" ]]; then
        local response_device_id
        response_device_id=$(jq -r '.device_id // empty' "$response_file")
        if [[ "$response_device_id" != "$device_id" ]]; then
            rm -f "$response_file"
            transport_unresolved "gateway device identity mismatch"
        fi
    fi
    
    # Output result
    jq -c '.result' "$response_file"
    rm -f "$response_file"
}

available() {
    local result
    result=$(_request "node1" '{"operation": "availability"}')
    
    if ! jq -e 'type == "object"' <<< "$result" >/dev/null 2>&1; then
        transport_unresolved "invalid node availability"
    fi
    
    echo "$result"
}

_release() {
    local original_json="$1"
    local entry_json="$2"
    
    # Check if already released
    if jq -e '.released // false' <<< "$entry_json" >/dev/null 2>&1; then
        return
    fi
    
    # Extract values from original
    local selected_node selected_device_id job_id attempt_id target_language
    selected_node=$(jq -r '.selected_node' <<< "$original_json")
    selected_device_id=$(jq -r '.selected_device_id' <<< "$original_json")
    job_id=$(jq -r '.job_id' <<< "$original_json")
    attempt_id=$(jq -r '.attempt_id' <<< "$original_json")
    target_language=$(jq -r '.target_language' <<< "$original_json")
    
    # Try to release
    local result
    if ! result=$(_request "$selected_node" "{\"operation\": \"release\", \"job_id\": \"$job_id\", \"attempt_id\": \"$attempt_id\"}" "$selected_device_id" 2>/dev/null); then
        return  # Retry cleanup later
    fi
    
    # Check release result
    local status
    status=$(jq -r '.status // ""' <<< "$result")
    
    if [[ "$status" == "released" ]]; then
        local match=true
        
        # Check all required fields match
        if [[ "$(jq -r ".job_id // \"\"" <<< "$result")" != "$job_id" ]]; then
            match=false
        fi
        if [[ "$(jq -r ".attempt_id // \"\"" <<< "$result")" != "$attempt_id" ]]; then
            match=false
        fi
        if [[ "$(jq -r ".selected_node // \"\"" <<< "$result")" != "$selected_node" ]]; then
            match=false
        fi
        if [[ "$(jq -r ".target_language // \"\"" <<< "$result")" != "$target_language" ]]; then
            match=false
        fi
        
        if [[ "$match" == true ]]; then
            # Update entry to mark as released
            local temp_file
            temp_file=$(mktemp)
            trap "rm -f '$temp_file'" EXIT
            
            jq "(.auftraege[] | select(.job.attempt_id == \"$attempt_id\")).released = true" "$STATE_FILE" > "$temp_file"
            mv "$temp_file" "$STATE_FILE"
        fi
    fi
}

release_pending() {
    # Load state
    if [[ ! -f "$STATE_FILE" ]]; then
        return
    fi
    
    # Process each entry
    local keys
    keys=$(jq -r '.auftraege | keys[]' "$STATE_FILE" 2>/dev/null || echo "")
    
    while IFS= read -r key; do
        [[ -n "$key" ]] || continue
        
        local entry_status entry_job
        entry_status=$(jq -r ".auftraege[\"$key\"].status // \"\"" "$STATE_FILE" 2>/dev/null)
        entry_job=$(jq -r ".auftraege[\"$key\"].job // {}" "$STATE_FILE" 2>/dev/null)
        
        if [[ "$entry_status" =~ ^(completed|rejected|failed)$ ]] && [[ -n "$entry_job" ]] && [[ "$entry_job" != "{}" ]]; then
            local original_json entry_json
            original_json=$(jq -r ".auftraege[\"$key\"].job" "$STATE_FILE")
            entry_json=$(jq -r ".auftraege[\"$key\"]" "$STATE_FILE")
            _release "$original_json" "$entry_json"
        fi
    done <<< "$keys"
}

reject() {
    local job_json="$1"
    local reason="$2"
    
    # Extract key components
    local source_sha256 target_language attempt_id
    source_sha256=$(jq -r '.source_sha256 // ""' <<< "$job_json")
    target_language=$(jq -r '.target_language // ""' <<< "$job_json")
    attempt_id=$(jq -r '.attempt_id // ""' <<< "$job_json")
    
    if [[ -z "$source_sha256" ]] || [[ -z "$target_language" ]]; then
        return
    fi
    
    local key="${source_sha256}:${target_language}"
    
    # Check existing entry
    local entry_status entry_attempt_id
    entry_status=$(jq -r ".auftraege[\"$key\"].status // \"\"" "$STATE_FILE" 2>/dev/null)
    entry_attempt_id=$(jq -r ".auftraege[\"$key\"].job.attempt_id // \"\"" "$STATE_FILE" 2>/dev/null)
    
    if [[ "$entry_status" != "completed" ]]; then
        return
    fi
    
    if [[ "$entry_attempt_id" != "$attempt_id" ]]; then
        transport_unresolved "rejected attempt identity mismatch"
    fi
    
    # Update entry
    local temp_file
    temp_file=$(mktemp)
    trap "rm -f '$temp_file'" EXIT
    
    jq "(.auftraege[\"$key\"].status = \"rejected\") | (.auftraege[\"$key\"].validation_error = \"$(echo "$reason" | cut -c1-500)\")" "$STATE_FILE" > "$temp_file"
    mv "$temp_file" "$STATE_FILE"
}

# Main transport function
transport_call() {
    local job_json="$1"
    
    # Extract required fields
    local source_sha256 target_language selected_device_id
    source_sha256=$(jq -r '.source_sha256 // ""' <<< "$job_json")
    target_language=$(jq -r '.target_language // ""' <<< "$job_json")
    selected_device_id=$(jq -r '.selected_device_id // ""' <<< "$job_json")
    
    if [[ -z "$source_sha256" ]] || [[ -z "$target_language" ]] || [[ -z "$selected_device_id" ]]; then
        echo "missing source identity" >&2
        return 1
    fi
    
    local key="${source_sha256}:${target_language}"
    
    # Ensure auftraege exists in state
    if ! jq -e '.auftraege' "$STATE_FILE" >/dev/null 2>&1; then
        local temp_file
        temp_file=$(mktemp)
        trap "rm -f '$temp_file'" EXIT
        jq '.auftraege = {}' "$STATE_FILE" > "$temp_file"
        mv "$temp_file" "$STATE_FILE"
    fi
    
    # Get entry
    local entry_json
    entry_json=$(jq -r ".auftraege[\"$key\"] // null" "$STATE_FILE" 2>/dev/null)
    
    local fresh=false
    if [[ "$entry_json" == "null" ]]; then
        fresh=true
    elif jq -e 'type == "object" and .status == "rejected"' <<< "$entry_json" >/dev/null 2>&1; then
        # Handle rejected case
        local previous_json entry_json_copy
        previous_json="$entry_json"
        entry_json_copy="$entry_json"
        
        _release "$(jq -r '.job' <<< "$entry_json")" "$entry_json"
        
        # Check if released
        local released
        released=$(jq -r '.released // false' <<< "$entry_json_copy")
        if [[ "$released" != "true" ]]; then
            transport_unresolved "rejected attempt release is unresolved"
        fi
        
        # Create new attempt
        local new_attempt_id
        new_attempt_id=$(uuidgen)
        
        local original_json
        original_json=$(jq --arg attempt_id "$new_attempt_id" '. + {attempt_id: $attempt_id}' <<< "$job_json")
        
        local previous_attempts_json
        previous_attempts_json=$(jq -r '.previous_attempts // []' <<< "$previous_json")
        
        local new_previous_entry
        new_previous_entry=$(jq -n --argjson prev "$(jq -r '.job' <<< "$previous_json")" --argjson prev_err "$(jq -r '.validation_error // ""' <<< "$previous_json")" '{
            job_id: $prev.job_id,
            attempt_id: $prev.attempt_id,
            selected_node: $prev.selected_node,
            validation_error: $prev_err
        }')
        
        previous_attempts_json=$(echo "[$new_previous_entry]" | jq -c '.')
        
        local temp_file
        temp_file=$(mktemp)
        trap "rm -f '$temp_file'" EXIT
        
        jq "(.auftraege[\"$key\"] = {job: $original_json, status: \"submitted\", previous_attempts: $previous_attempts_json})" "$STATE_FILE" > "$temp_file"
        mv "$temp_file" "$STATE_FILE"
        
        fresh=true
    fi
    
    # Load entry again after potential updates
    entry_json=$(jq -r ".auftraege[\"$key\"] // null" "$STATE_FILE" 2>/dev/null)
    
    if [[ "$entry_json" == "null" ]]; then
        # Create new entry
        local new_attempt_id
        new_attempt_id=$(uuidgen)
        
        local original_json
        original_json=$(jq --arg attempt_id "$new_attempt_id" '. + {attempt_id: $attempt_id}' <<< "$job_json")
        
        local temp_file
        temp_file=$(mktemp)
        trap "rm -f '$temp_file'" EXIT
        
        jq "(.auftraege[\"$key\"] = {job: $original_json, status: \"submitted\"})" "$STATE_FILE" > "$temp_file"
        mv "$temp_file" "$STATE_FILE"
        
        entry_json="{\"job\": $(jq -c ".auftraege[\"$key\"].job" "$STATE_FILE"), \"status\": \"submitted\"}"
    fi
    
    # Get original job
    local original_json
    original_json=$(jq -r '.job' <<< "$entry_json")
    
    # Update job with original values
    local updated_job
    updated_job=$(jq -s --argjson orig "$original_json" '.[0] * $orig' <<< "$job_json")
    echo "$updated_job" > /tmp/job_update_$$_temp
    mv /tmp/job_update_$$_temp "$STATE_FILE.tmp"
    # Note: In bash we can't easily update the passed job_json parameter
    
    # Check if response exists
    local response
    response=$(jq -r '.response // null' <<< "$entry_json")
    
    if [[ "$response" != "null" ]]; then
        _release "$original_json" "$entry_json"
        echo "$response"
        return
    fi
    
    # Check if failed
    local status
    status=$(jq -r '.status // ""' <<< "$entry_json")
    
    if [[ "$status" == "failed" ]]; then
        transport_unresolved "attempt requires reconciliation"
    fi
    
    # Process submission
    local status_result=""
    
    if [[ "$fresh" == true ]]; then
        # Try initial execution
        local selected_node selected_device_id_val
        selected_node=$(jq -r '.selected_node' <<< "$original_json")
        selected_device_id_val=$(jq -r '.selected_device_id' <<< "$original_json")
        
        if ! status_result=$(_request "$selected_node" "{\"operation\": \"execute\", \"job\": $(echo "$original_json" | jq -c '.')}" "$selected_device_id_val" 2>/dev/null); then
            status_result=""  # Will query instead
        fi
    fi
    
    # Set deadline
    local deadline start_time
    start_time=$(date +%s)
    deadline=$((start_time + TIMEOUT))
    
    # Polling loop
    while true; do
        if [[ -z "$status_result" ]]; then
            # Query status
            local job_id attempt_id selected_node_val target_language_val
            job_id=$(jq -r '.job_id' <<< "$original_json")
            attempt_id=$(jq -r '.attempt_id' <<< "$original_json")
            selected_node_val=$(jq -r '.selected_node' <<< "$original_json")
            target_language_val=$(jq -r '.target_language' <<< "$original_json")
            
            status_result=$(_request "$selected_node_val" "{\"operation\": \"status\", \"job_id\": \"$job_id\", \"attempt_id\": \"$attempt_id\"}" "$(jq -r '.selected_device_id' <<< "$original_json")")
        fi
        
        # Validate status structure
        if ! jq -e 'type == "object"' <<< "$status_result" >/dev/null 2>&1; then
            transport_unresolved "attempt is not known by the node"
        fi
        
        # Check identity match
        if [[ "$(jq -r ".job_id // \"\"" <<< "$status_result")" != "$(jq -r ".job_id" <<< "$original_json")" ]] ||
           [[ "$(jq -r ".attempt_id // \"\"" <<< "$status_result")" != "$(jq -r ".attempt_id" <<< "$original_json")" ]] ||
           [[ "$(jq -r ".selected_node // \"\"" <<< "$status_result")" != "$(jq -r ".selected_node" <<< "$original_json")" ]] ||
           [[ "$(jq -r ".target_language // \"\"" <<< "$status_result")" != "$(jq -r ".target_language" <<< "$original_json")" ]]; then
            transport_unresolved "status identity mismatch"
        fi
        
        local state
        state=$(jq -r '.status // ""' <<< "$status_result")
        
        if [[ "$state" == "completed" ]]; then
            local response_result
            response_result=$(jq -r '.response // null' <<< "$status_result")
            
            # Validate response
            if [[ "$(jq -r 'type // ""' <<< "$response_result")" != "object" ]] ||
               [[ "$(jq -r '.status // ""' <<< "$response_result")" != "ok" ]] ||
               [[ "$(jq -r ".job_id // \"\"" <<< "$response_result")" != "$(jq -r ".job_id" <<< "$original_json")" ]] ||
               [[ "$(jq -r ".selected_node // \"\"" <<< "$response_result")" != "$(jq -r ".selected_node" <<< "$original_json")" ]] ||
               [[ "$(jq -r ".target_language // \"\"" <<< "$response_result")" != "$(jq -r ".target_language" <<< "$original_json")" ]] ||
               [[ -z "$(jq -r '.code // ""' <<< "$response_result")" ]]; then
                transport_unresolved "invalid translation result"
            fi
            
            # Save response
            local temp_file
            temp_file=$(mktemp)
            trap "rm -f '$temp_file'" EXIT
            
            jq "(.auftraege[\"$key\"].response = $response_result) | (.auftraege[\"$key\"].status = \"completed\")" "$STATE_FILE" > "$temp_file"
            mv "$temp_file" "$STATE_FILE"
            
            _release "$original_json" "$entry_json"
            echo "$response_result"
            return
        fi
        
        if [[ "$state" == "failed" ]] || [[ "$state" == "unknown" ]]; then
            local temp_file
            temp_file=$(mktemp)
            trap "rm -f '$temp_file'" EXIT
            
            jq "(.auftraege[\"$key\"].status = \"$state\")" "$STATE_FILE" > "$temp_file"
            mv "$temp_file" "$STATE_FILE"
            
            if [[ "$state" == "failed" ]]; then
                _release "$original_json" "$entry_json"
            fi
            
            transport_unresolved "attempt requires reconciliation"
        fi
        
        if [[ "$state" != "running" ]]; then
            transport_unresolved "attempt is unresolved"
        fi
        
        # Check timeout
        local current_time
        current_time=$(date +%s)
        if [[ $current_time -ge $deadline ]]; then
            transport_unresolved "attempt is unresolved"
        fi
        
        # Sleep and reset for next iteration
        sleep "$INTERVAL"
        status_result=""
    done
}
