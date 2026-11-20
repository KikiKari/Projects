#!/bin/bash
# gateway_transport.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/gateway_transport.py
# Erzeugt: 2026-11-20 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Gateway-authenticated transport with manager-owned attempt records.
#
# An attempt is saved before submission. If its outcome is uncertain, subsequent
# calls only query the same node and attempt; they do not submit it again.

# Exception handling: simulate Python exceptions using exit codes and messages
die() {
    echo "$*" >&2
    exit 1
}

# TransportUnresolved exception simulation
transport_unresolved() {
    echo "TransportUnresolved: $*" >&2
    exit 2
}

# Get gateway token from environment or config file
gateway_token() {
    local token=""
    
    if [[ -n "${OPENCLAW_GATEWAY_TOKEN:-}" ]]; then
        token="${OPENCLAW_GATEWAY_TOKEN}"
    else
        local config_path="${HOME}/.openclaw/openclaw.json"
        if [[ -n "${OPENCLAW_CONFIG_PATH:-}" ]]; then
            config_path="${OPENCLAW_CONFIG_PATH}"
        fi
        
        if [[ -f "$config_path" ]]; then
            # Extract token from JSON (simplified - assumes simple structure)
            token=$(jq -r '.gateway.auth.token // ""' "$config_path" 2>/dev/null || echo "")
        fi
    fi
    
    # Strip whitespace and check for placeholder patterns
    token=$(echo "$token" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' )
    if [[ "$token" =~ ^\$\{.*\}$ ]]; then
        token=""
    fi
    
    echo "$token"
}

# Validate URL format
validate_url() {
    local url="$1"
    
    if ! echo "$url" | grep -qE '^https?://'; then
        die "invalid Gateway URL"
    fi
    
    local scheme=$(echo "$url" | sed -E 's#^([a-z]+)://.*#\1#')
    local hostname=$(echo "$url" | sed -E 's#^[a-z]+://([^/]*)/?.*#\1#' | cut -d: -f1)
    
    if [[ "$scheme" == "http" ]] && [[ ! "$hostname" =~ ^(127\.0\.0\.1|localhost|::1)$ ]]; then
        die "unencrypted Gateway must use loopback"
    fi
}

# Make HTTP request to gateway
_request() {
    local url="$1"
    local token="$2"
    local node="$3"
    local request_json="$4"
    local device_id="${5:-}"
    
    local payload
    if [[ -n "$device_id" ]]; then
        payload=$(jq -n --arg node "$node" --arg device_id "$device_id" --argjson request "$request_json" \
            '{node: $node, device_id: $device_id, request: $request}')
    else
        payload=$(jq -n --arg node "$node" --argjson request "$request_json" \
            '{node: $node, request: $request}')
    fi
    
    local timeout=40
    if [[ "$node" == "node4" ]]; then
        timeout=150
    fi
    
    local response_file
    response_file=$(mktemp)
    trap 'rm -f "$response_file"' EXIT
    
    local http_code
    http_code=$(curl -s -w "%{http_code}" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        --data-raw "$payload" \
        --max-time "$timeout" \
        "$url" -o "$response_file")
    
    if [[ "$http_code" -ne 200 ]]; then
        transport_unresolved "Gateway request failed"
    fi
    
    # Check response size limit (approximate)
    local size
    size=$(wc -c < "$response_file")
    if [[ $size -gt 4000000 ]]; then
        die "response too large"
    fi
    
    # Parse and validate response
    local result
    result=$(jq -r 'if type == "object" and has("result") then .result else empty end' "$response_file" 2>/dev/null)
    if [[ -z "$result" || "$result" == "null" ]]; then
        die "invalid gateway response"
    fi
    
    if [[ -n "$device_id" ]]; then
        local response_device_id
        response_device_id=$(jq -r '.device_id // ""' "$response_file")
        if [[ "$response_device_id" != "$device_id" ]]; then
            die "gateway device identity mismatch"
        fi
    fi
    
    echo "$result"
}

# Check node availability
available() {
    local url="$1"
    local token="$2"
    
    local request='{"operation": "availability"}'
    local result
    result=$(_request "$url" "$token" "node1" "$request")
    
    # Validate result is a dictionary-like structure
    if ! echo "$result" | jq -e 'type == "object"' >/dev/null 2>&1; then
        transport_unresolved "invalid node availability"
    fi
    
    echo "$result"
}

# Release a job attempt
_release() {
    local state_file="$1"
    local key="$2"
    local selected_node="$3"
    local job_id="$4"
    local attempt_id="$5"
    local selected_device_id="$6"
    local target_language="$7"
    local url="$8"
    local token="$9"
    
    # Check if already released
    local released
    released=$(jq -r ".auftraege[\"$key\"].released // false" "$state_file")
    if [[ "$released" == "true" ]]; then
        return
    fi
    
    local request
    request=$(jq -n --arg job_id "$job_id" --arg attempt_id "$attempt_id" \
        '{operation: "release", job_id: $job_id, attempt_id: $attempt_id}')
    
    local result
    if ! result=$(_request "$url" "$token" "$selected_node" "$request" "$selected_device_id" 2>/dev/null); then
        return  # Retry cleanup later
    fi
    
    local status
    status=$(echo "$result" | jq -r '.status // ""')
    
    if [[ "$status" == "released" ]]; then
        local match=true
        for field in job_id attempt_id selected_node target_language; do
            local expected_value actual_value
            expected_value=$(eval echo \$$field)
            actual_value=$(echo "$result" | jq -r ".${field} // \"\"")
            if [[ "$actual_value" != "$expected_value" ]]; then
                match=false
                break
            fi
        done
        
        if [[ "$match" == "true" ]]; then
            jq ".auftraege[\"$key\"].released = true" "$state_file" > "${state_file}.tmp" && mv "${state_file}.tmp" "$state_file"
        fi
    fi
}

# Release pending jobs
release_pending() {
    local state_file="$1"
    local url="$2"
    local token="$3"
    
    local keys
    keys=$(jq -r '.auftraege | keys[]' "$state_file" 2>/dev/null || echo "")
    
    while IFS= read -r key; do
        [[ -z "$key" ]] && continue
        
        local status
        status=$(jq -r ".auftraege[\"$key\"].status // \"\"" "$state_file")
        
        if [[ "$status" =~ ^(completed|rejected|failed)$ ]]; then
            local job_obj
            job_obj=$(jq -r ".auftraege[\"$key\"].job // null" "$state_file")
            if [[ "$job_obj" != "null" ]]; then
                local selected_node job_id attempt_id selected_device_id target_language
                selected_node=$(echo "$job_obj" | jq -r '.selected_node // ""')
                job_id=$(echo "$job_obj" | jq -r '.job_id // ""')
                attempt_id=$(echo "$job_obj" | jq -r '.attempt_id // ""')
                selected_device_id=$(echo "$job_obj" | jq -r '.selected_device_id // ""')
                target_language=$(echo "$job_obj" | jq -r '.target_language // ""')
                
                _release "$state_file" "$key" "$selected_node" "$job_id" "$attempt_id" \
                    "$selected_device_id" "$target_language" "$url" "$token"
            fi
        fi
    done <<< "$keys"
}

# Reject a job with validation error
reject() {
    local state_file="$1"
    local job_json="$2"
    local reason="$3"
    
    local source_sha256 target_language
    source_sha256=$(echo "$job_json" | jq -r '.source_sha256 // ""')
    target_language=$(echo "$job_json" | jq -r '.target_language // ""')
    
    local key="${source_sha256}:${target_language}"
    
    local status
    status=$(jq -r ".auftraege[\"$key\"].status // \"\"" "$state_file")
    
    if [[ "$status" != "completed" ]]; then
        return
    fi
    
    local current_attempt_id entry_attempt_id
    current_attempt_id=$(echo "$job_json" | jq -r '.attempt_id // ""')
    entry_attempt_id=$(jq -r ".auftraege[\"$key\"].job.attempt_id // \"\"" "$state_file")
    
    if [[ "$entry_attempt_id" != "$current_attempt_id" ]]; then
        transport_unresolved "rejected attempt identity mismatch"
    fi
    
    # Truncate reason to 500 characters
    reason=${reason:0:500}
    
    jq ".auftraege[\"$key\"].status = \"rejected\" | .auftraege[\"$key\"].validation_error = \"$reason\"" \
        "$state_file" > "${state_file}.tmp" && mv "${state_file}.tmp" "$state_file"
}

# Main transport function
gateway_transport() {
    local state_file="$1"
    local url="$2"
    local token="$3"
    local job_json="$4"
    local timeout="${5:-3900}"
    local interval="${6:-3}"
    
    # Validate inputs
    validate_url "$url"
    
    if [[ -z "$token" ]] || [[ $timeout -le 0 ]] || [[ $interval -le 0 ]]; then
        die "Gateway token and positive timeouts required"
    fi
    
    local source_sha256 target_language selected_device_id
    source_sha256=$(echo "$job_json" | jq -r '.source_sha256 // ""')
    target_language=$(echo "$job_json" | jq -r '.target_language // ""')
    selected_device_id=$(echo "$job_json" | jq -r '.selected_device_id // ""')
    
    if [[ -z "$source_sha256" ]] || [[ -z "$target_language" ]] || [[ -z "$selected_device_id" ]]; then
        die "missing source identity"
    fi
    
    local key="${source_sha256}:${target_language}"
    
    # Initialize auftraege if needed
    if ! jq -e '.auftraege' "$state_file" >/dev/null 2>&1; then
        jq '.auftraege = {}' "$state_file" > "${state_file}.tmp" && mv "${state_file}.tmp" "$state_file"
    fi
    
    local entry_status
    entry_status=$(jq -r ".auftraege[\"$key\"].status // \"\"" "$state_file")
    
    local fresh=false
    local original_job=""
    
    if [[ "$entry_status" == "rejected" ]]; then
        local selected_node job_id attempt_id selected_device_id target_language
        selected_node=$(jq -r ".auftraege[\"$key\"].job.selected_node // \"\"" "$state_file")
        job_id=$(jq -r ".auftraege[\"$key\"].job.job_id // \"\"" "$state_file")
        attempt_id=$(jq -r ".auftraege[\"$key\"].job.attempt_id // \"\"" "$state_file")
        selected_device_id=$(jq -r ".auftraege[\"$key\"].job.selected_device_id // \"\"" "$state_file")
        target_language=$(jq -r ".auftraege[\"$key\"].job.target_language // \"\"" "$state_file")
        
        _release "$state_file" "$key" "$selected_node" "$job_id" "$attempt_id" \
            "$selected_device_id" "$target_language" "$url" "$token"
        
        local released
        released=$(jq -r ".auftraege[\"$key\"].released // false" "$state_file")
        if [[ "$released" != "true" ]]; then
            transport_unresolved "rejected attempt release is unresolved"
        fi
        
        local previous_entry
        previous_entry=$(jq -rc ".auftraege[\"$key\"]" "$state_file")
        
        # Generate new attempt ID
        local new_attempt_id
        new_attempt_id=$(uuidgen)
        
        # Create new job with updated attempt_id
        original_job=$(echo "$job_json" | jq --arg id "$new_attempt_id" '. + {attempt_id: $id}')
        
        local prev_attempts_json
        prev_attempts_json=$(jq -r ".auftraege[\"$key\"].previous_attempts // []" "$state_file")
        
        local new_attempt_record
        new_attempt_record=$(jq -n --arg job_id "$(echo "$previous_entry" | jq -r '.job.job_id // ""')" \
            --arg attempt_id "$(echo "$previous_entry" | jq -r '.job.attempt_id // ""')" \
            --arg selected_node "$(echo "$previous_entry" | jq -r '.job.selected_node // ""')" \
            --arg validation_error "$(echo "$previous_entry" | jq -r '.validation_error // ""')" \
            '{job_id: $job_id, attempt_id: $attempt_id, selected_node: $selected_node, validation_error: $validation_error}')
        
        local updated_prev_attempts
        updated_prev_attempts=$(echo "$prev_attempts_json" | jq --argjson new_rec "$new_attempt_record" '. + [$new_rec]')
        
        local new_entry
        new_entry=$(jq -n --argjson job "$original_job" --argjson prev_attempts "$updated_prev_attempts" \
            '{job: $job, status: "submitted", previous_attempts: $prev_attempts}')
        
        jq ".auftraege[\"$key\"] = $new_entry" "$state_file" > "${state_file}.tmp" && mv "${state_file}.tmp" "$state_file"
        fresh=true
    else
        if jq -e ".auftraege[\"$key\"]" "$state_file" >/dev/null 2>&1; then
            original_job=$(jq -rc ".auftraege[\"$key\"].job" "$state_file")
        else
            fresh=true
        fi
    fi
    
    if [[ -z "$original_job" ]]; then
        local new_attempt_id
        new_attempt_id=$(uuidgen)
        original_job=$(echo "$job_json" | jq --arg id "$new_attempt_id" '. + {attempt_id: $id}')
        
        local new_entry
        new_entry=$(jq -n --argjson job "$original_job" '{job: $job, status: "submitted"}')
        jq ".auftraege[\"$key\"] = $new_entry" "$state_file" > "${state_file}.tmp" && mv "${state_file}.tmp" "$state_file"
    fi
    
    # Update job with original values
    local updated_job
    updated_job=$(echo "$job_json" | jq --argjson orig "$original_job" '. + $orig')
    echo "$updated_job" > "/tmp/job_updated_$$.json"
    
    # Check if response exists
    local response
    response=$(jq -r ".auftraege[\"$key\"].response // \"null\"" "$state_file")
    if [[ "$response" != "null" ]]; then
        local selected_node job_id attempt_id selected_device_id target_language
        selected_node=$(echo "$original_job" | jq -r '.selected_node // ""')
        job_id=$(echo "$original_job" | jq -r '.job_id // ""')
        attempt_id=$(echo "$original_job" | jq -r '.attempt_id // ""')
        selected_device_id=$(echo "$original_job" | jq -r '.selected_device_id // ""')
        target_language=$(echo "$original_job" | jq -r '.target_language // ""')
        
        _release "$state_file" "$key" "$selected_node" "$job_id" "$attempt_id" \
            "$selected_device_id" "$target_language" "$url" "$token"
        jq -r ".auftraege[\"$key\"].response" "$state_file"
        return
    fi
    
    local entry_status
    entry_status=$(jq -r ".auftraege[\"$key\"].status // \"\"" "$state_file")
    if [[ "$entry_status" =~ ^(failed|unknown)$ ]]; then
        transport_unresolved "attempt requires reconciliation"
    fi
    
    local status=""
    
    if [[ "$fresh" == "true" ]]; then
        local request
        request=$(jq -n --argjson job "$original_job" '{operation: "execute", job: $job}')
        local selected_node selected_device_id
        selected_node=$(echo "$original_job" | jq -r '.selected_node // ""')
        selected_device_id=$(echo "$original_job" | jq -r '.selected_device_id // ""')
        
        if ! status=$(_request "$url" "$token" "$selected_node" "$request" "$selected_device_id" 2>/dev/null); then
            :  # The request may have been accepted. Query, never resend.
        fi
    fi
    
    local deadline
    deadline=$(($(date +%s) + timeout))
    
    while true; do
        if [[ -z "$status" ]]; then
            local job_id attempt_id selected_node
            job_id=$(echo "$original_job" | jq -r '.job_id // ""')
            attempt_id=$(echo "$original_job" | jq -r '.attempt_id // ""')
            selected_node=$(echo "$original_job" | jq -r '.selected_node // ""')
            selected_device_id=$(echo "$original_job" | jq -r '.selected_device_id // ""')
            
            local request
            request=$(jq -n --arg job_id "$job_id" --arg attempt_id "$attempt_id" \
                '{operation: "status", job_id: $job_id, attempt_id: $attempt_id}')
            
            status=$(_request "$url" "$token" "$selected_node" "$request" "$selected_device_id")
        fi
        
        # Validate status is an object
        if ! echo "$status" | jq -e 'type == "object"' >/dev/null 2>&1; then
            transport_unresolved "attempt is not known by the node"
        fi
        
        # Check identity fields
        local job_id attempt_id selected_node target_language
        job_id=$(echo "$original_job" | jq -r '.job_id // ""')
        attempt_id=$(echo "$original_job" | jq -r '.attempt_id // ""')
        selected_node=$(echo "$original_job" | jq -r '.selected_node // ""')
        target_language=$(echo "$original_job" | jq -r '.target_language // ""')
        
        local status_job_id status_attempt_id status_selected_node status_target_language
        status_job_id=$(echo "$status" | jq -r '.job_id // ""')
        status_attempt_id=$(echo "$status" | jq -r '.attempt_id // ""')
        status_selected_node=$(echo "$status" | jq -r '.selected_node // ""')
        status_target_language=$(echo "$status" | jq -r '.target_language // ""')
        
        if [[ "$status_job_id" != "$job_id" ]] || [[ "$status_attempt_id" != "$attempt_id" ]] || 
           [[ "$status_selected_node" != "$selected_node" ]] || [[ "$status_target_language" != "$target_language" ]]; then
            transport_unresolved "status identity mismatch"
        fi
        
        local state
        state=$(echo "$status" | jq -r '.status // ""')
        
        if [[ "$state" == "completed" ]]; then
            local response
            response=$(echo "$status" | jq -r '.response // null')
            
            if [[ "$response" == "null" ]]; then
                transport_unresolved "invalid translation result"
            fi
            
            local response_status
            response_status=$(echo "$response" | jq -r '.status // ""')
            
            if [[ "$response_status" != "ok" ]]; then
                transport_unresolved "invalid translation result"
            fi
            
            # Check response identity fields
            local resp_job_id resp_selected_node resp_target_language resp_code
            resp_job_id=$(echo "$response" | jq -r '.job_id // ""')
            resp_selected_node=$(echo "$response" | jq -r '.selected_node // ""')
            resp_target_language=$(echo "$response" | jq -r '.target_language // ""')
            resp_code=$(echo "$response" | jq -r '.code // ""')
            
            if [[ "$resp_job_id" != "$job_id" ]] || [[ "$resp_selected_node" != "$selected_node" ]] || 
               [[ "$resp_target_language" != "$target_language" ]] || [[ -z "$resp_code" ]] || 
               [[ $(echo "$resp_code" | wc -l) -eq 0 ]]; then
                transport_unresolved "invalid translation result"
            fi
            
            jq ".auftraege[\"$key\"].response = $response | .auftraege[\"$key\"].status = \"completed\"" \
                "$state_file" > "${state_file}.tmp" && mv "${state_file}.tmp" "$state_file"
            
            local selected_node job_id attempt_id selected_device_id target_language
            selected_node=$(echo "$original_job" | jq -r '.selected_node // ""')
            job_id=$(echo "$original_job" | jq -r '.job_id // ""')
            attempt_id=$(echo "$original_job" | jq -r '.attempt_id // ""')
            selected_device_id=$(echo "$original_job" | jq -r '.selected_device_id // ""')
            target_language=$(echo "$original_job" | jq -r '.target_language // ""')
            
            _release "$state_file" "$key" "$selected_node" "$job_id" "$attempt_id" \
                "$selected_device_id" "$target_language" "$url" "$token"
            
            echo "$response"
            return
        fi
        
        if [[ "$state" =~ ^(failed|unknown)$ ]]; then
            jq ".auftraege[\"$key\"].status = \"$state\"" "$state_file" > "${state_file}.tmp" && mv "${state_file}.tmp" "$state_file"
            
            if [[ "$state" == "failed" ]]; then
                local selected_node job_id attempt_id selected_device_id target_language
                selected_node=$(echo "$original_job" | jq -r '.selected_node // ""')
                job_id=$(echo "$original_job" | jq -r '.job_id // ""')
                attempt_id=$(echo "$original_job" | jq -r '.attempt_id // ""')
                selected_device_id=$(echo "$original_job" | jq -r '.selected_device_id // ""')
                target_language=$(echo "$original_job" | jq -r '.target_language // ""')
                
                _release "$state_file" "$key" "$selected_node" "$job_id" "$attempt_id" \
                    "$selected_device_id" "$target_language" "$url" "$token"
            fi
            
            transport_unresolved "attempt requires reconciliation"
        fi
        
        if [[ "$state" != "running" ]] || [[ $(date +%s) -ge $deadline ]]; then
            transport_unresolved "attempt is unresolved"
        fi
        
        sleep "$interval"
        status=""
    done
}
