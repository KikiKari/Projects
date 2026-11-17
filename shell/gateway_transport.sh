#!/bin/bash
# gateway_transport.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/gateway_transport.py
# Erzeugt: 2026-11-17 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Gateway-authenticated transport with manager-owned attempt records.
#
# An attempt is saved before submission. If its outcome is uncertain, subsequent
# calls only query the same node and attempt; they do not submit it again.

# Simulating Python exceptions using exit codes and messages
TRANSPORT_UNRESOLVED=1

log_error() {
    echo "ERROR: $*" >&2
}

die() {
    log_error "$@"
    exit "$TRANSPORT_UNRESOLVED"
}

# Function to get gateway token
gateway_token() {
    local token="${OPENCLAW_GATEWAY_TOKEN:-}"
    if [[ -n "${token}" ]]; then
        echo "${token}"
        return
    fi

    local config_path="${OPENCLAW_CONFIG_PATH:-${HOME}/.openclaw/openclaw.json}"
    if [[ ! -f "${config_path}" ]]; then
        echo ""
        return
    fi

    # Extract token from JSON (basic parsing)
    local extracted_token
    extracted_token=$(jq -r '.gateway.auth.token // ""' "${config_path}" 2>/dev/null || echo "")
    
    if [[ "${extracted_token}" =~ ^\$\{.*\}$ ]] || [[ -z "${extracted_token}" ]]; then
        echo ""
    else
        echo "${extracted_token}"
    fi
}

# Class-like structure using functions and global variables
# Global variables for GatewayTransport state
GT_STATE_FILE=""
GT_SAVE_CALLBACK=""
GT_URL=""
GT_TOKEN=""
GT_TIMEOUT=3900
GT_INTERVAL=3

# Initialize GatewayTransport
init_gateway_transport() {
    local state_file="$1"
    local save_callback="$2"
    local url="$3"
    local token="$4"
    local timeout="${5:-3900}"
    local interval="${6:-3}"

    GT_STATE_FILE="${state_file}"
    GT_SAVE_CALLBACK="${save_callback}"
    GT_URL="${url}"
    GT_TOKEN="${token}"
    GT_TIMEOUT="${timeout}"
    GT_INTERVAL="${interval}"

    # Validate URL
    if ! [[ "${url}" =~ ^https?://[^/]+ ]]; then
        die "invalid Gateway URL"
    fi
    
    local scheme hostname
    scheme=$(echo "${url}" | cut -d':' -f1)
    hostname=$(echo "${url}" | sed -E 's#https?://([^:/]+).*#\1#')

    if [[ "${scheme}" == "http" ]] && ! [[ "${hostname}" =~ ^(127\.0\.0\.1|localhost|\[::1\])$ ]]; then
        die "unencrypted Gateway must use loopback"
    fi

    if [[ -z "${token}" ]] || [[ "${timeout}" -le 0 ]] || [[ "${interval}" -le 0 ]]; then
        die "Gateway token and positive timeouts required"
    fi
}

# Make HTTP request to gateway
_request() {
    local node="$1"
    local request_json="$2"
    local device_id="${3:-null}"

    # Create payload
    local payload
    payload=$(jq -n --arg node "${node}" --arg device_id "${device_id}" --argjson request "${request_json}" \
        '{node: $node, device_id: $device_id, request: $request}')

    # Set timeout based on node
    local request_timeout=40
    if [[ "${node}" == "node4" ]]; then
        request_timeout=150
    fi

    # Send request
    local response_file response_status
    response_file=$(mktemp)
    response_status=$(curl -s -w "%{http_code}" -o "${response_file}" \
        -H "Authorization: Bearer ${GT_TOKEN}" \
        -H "Content-Type: application/json" \
        -X POST \
        --max-time "${request_timeout}" \
        -d "${payload}" \
        "${GT_URL}")

    # Check HTTP status code
    if [[ "${response_status}" -ne 200 ]]; then
        rm -f "${response_file}"
        die "Gateway request failed with HTTP status ${response_status}"
    fi

    # Check response size (approximate limit)
    local response_size
    response_size=$(wc -c < "${response_file}")
    if [[ "${response_size}" -gt 4000001 ]]; then
        rm -f "${response_file}"
        die "response too large"
    fi

    # Parse response
    local result_data device_id_check
    result_data=$(jq -r '.result' "${response_file}" 2>/dev/null || echo "null")
    device_id_check=$(jq -r '.device_id' "${response_file}" 2>/dev/null || echo "null")

    # Validate response format
    if [[ "$(jq 'type' <<<"${result_data}")" == "null" ]]; then
        rm -f "${response_file}"
        die "invalid gateway response"
    fi

    # Check device ID match if provided
    if [[ "${device_id}" != "null" ]] && [[ "${device_id_check}" != "${device_id}" ]]; then
        rm -f "${response_file}"
        die "gateway device identity mismatch"
    fi

    cat "${response_file}"
    rm -f "${response_file}"
}

# Check node availability
available() {
    local response
    response=$(_request "node1" '{"operation": "availability"}')
    local result_type
    result_type=$(jq 'type' <<<"${response}" 2>/dev/null || echo "null")
    
    if [[ "${result_type}" != "object" ]]; then
        die "invalid node availability"
    fi
    
    echo "${response}"
}

# Release a job
_release() {
    local original_ref="$1"
    local entry_ref="$2"
    
    # Check if already released
    if jq -e ".${entry_ref}.released" "${GT_STATE_FILE}" >/dev/null 2>&1; then
        return
    fi
    
    # Get job details
    local selected_node job_id attempt_id selected_device_id target_language
    selected_node=$(jq -r ".${original_ref}.selected_node" "${GT_STATE_FILE}")
    job_id=$(jq -r ".${original_ref}.job_id" "${GT_STATE_FILE}")
    attempt_id=$(jq -r ".${original_ref}.attempt_id" "${GT_STATE_FILE}")
    selected_device_id=$(jq -r ".${original_ref}.selected_device_id" "${GT_STATE_FILE}")
    target_language=$(jq -r ".${original_ref}.target_language" "${GT_STATE_FILE}")
    
    # Try to release
    local release_result
    release_result=$(_request "${selected_node}" "{\"operation\": \"release\", \"job_id\": \"${job_id}\", \"attempt_id\": \"${attempt_id}\"}" "${selected_device_id}" 2>/dev/null) || {
        return  # Retry cleanup later
    }
    
    # Check release status
    local status release_job_id release_attempt_id release_selected_node release_target_language
    status=$(jq -r '.status' <<<"${release_result}")
    release_job_id=$(jq -r '.job_id' <<<"${release_result}")
    release_attempt_id=$(jq -r '.attempt_id' <<<"${release_result}")
    release_selected_node=$(jq -r '.selected_node' <<<"${release_result}")
    release_target_language=$(jq -r '.target_language' <<<"${release_result}")
    
    if [[ "${status}" == "released" ]] && 
       [[ "${release_job_id}" == "${job_id}" ]] && 
       [[ "${release_attempt_id}" == "${attempt_id}" ]] && 
       [[ "${release_selected_node}" == "${selected_node}" ]] && 
       [[ "${release_target_language}" == "${target_language}" ]]; then
        # Update state to mark as released
        jq ".${entry_ref}.released = true" "${GT_STATE_FILE}" > "${GT_STATE_FILE}.tmp" && mv "${GT_STATE_FILE}.tmp" "${GT_STATE_FILE}"
        ${GT_SAVE_CALLBACK} "${GT_STATE_FILE}"
    fi
}

# Release pending jobs
release_pending() {
    # Iterate through all entries in auftraege
    local keys
    keys=$(jq -r '.auftraege | keys[]' "${GT_STATE_FILE}" 2>/dev/null || echo "")
    
    while IFS= read -r key; do
        [[ -n "${key}" ]] || continue
        
        local status selected_device_id job_exists
        status=$(jq -r ".auftraege.\"${key}\".status" "${GT_STATE_FILE}" 2>/dev/null || echo "null")
        selected_device_id=$(jq -r ".auftraege.\"${key}\".job.selected_device_id" "${GT_STATE_FILE}" 2>/dev/null || echo "null")
        job_exists=$(jq -r ".auftraege.\"${key}\".job | type" "${GT_STATE_FILE}" 2>/dev/null || echo "null")
        
        if [[ "${status}" =~ ^(completed|failed|unknown)$ ]] && [[ "${job_exists}" == "object" ]]; then
            _release ".auftraege.\"${key}\".job" ".auftraege.\"${key}\""
        fi
    done <<<"${keys}"
}

# Main transport function
transport_call() {
    local job_ref="$1"
    
    # Validate job has required fields
    local source_sha256 target_language selected_device_id
    source_sha256=$(jq -r ".${job_ref}.source_sha256" "${GT_STATE_FILE}" 2>/dev/null || echo "null")
    target_language=$(jq -r ".${job_ref}.target_language" "${GT_STATE_FILE}" 2>/dev/null || echo "null")
    selected_device_id=$(jq -r ".${job_ref}.selected_device_id" "${GT_STATE_FILE}" 2>/dev/null || echo "null")
    
    if [[ "${source_sha256}" == "null" ]] || [[ "${target_language}" == "null" ]] || [[ "${selected_device_id}" == "null" ]]; then
        die "missing source identity"
    fi
    
    local key="${source_sha256}:${target_language}"
    local entry_path=".auftraege.\"${key}\""
    
    # Check if entry exists
    local entry_exists
    entry_exists=$(jq "${entry_path} | type" "${GT_STATE_FILE}" 2>/dev/null || echo "null")
    
    local fresh=false
    if [[ "${entry_exists}" == "null" ]]; then
        fresh=true
        # Create new attempt
        local attempt_id
        attempt_id=$(uuidgen)
        
        # Update job with attempt_id
        jq ".${job_ref}.attempt_id = \"${attempt_id}\"" "${GT_STATE_FILE}" > "${GT_STATE_FILE}.tmp" && mv "${GT_STATE_FILE}.tmp" "${GT_STATE_FILE}"
        
        # Create entry
        jq "${entry_path} = {\"job\": .${job_ref}, \"status\": \"submitted\"}" "${GT_STATE_FILE}" > "${GT_STATE_FILE}.tmp" && mv "${GT_STATE_FILE}.tmp" "${GT_STATE_FILE}"
        
        # Save state
        ${GT_SAVE_CALLBACK} "${GT_STATE_FILE}"
    fi
    
    # Get original job data
    local original_path="${entry_path}.job"
    
    # Copy job data back to input
    jq ".${job_ref} = ${original_path}" "${GT_STATE_FILE}" > "${GT_STATE_FILE}.tmp" && mv "${GT_STATE_FILE}.tmp" "${GT_STATE_FILE}"
    
    # Check if we have a cached response
    local response_exists
    response_exists=$(jq "${entry_path}.response | type" "${GT_STATE_FILE}" 2>/dev/null || echo "null")
    if [[ "${response_exists}" != "null" ]]; then
        _release "${original_path}" "${entry_path}"
        jq -r "${entry_path}.response" "${GT_STATE_FILE}"
        return
    fi
    
    # Check if status indicates failure requiring reconciliation
    local current_status
    current_status=$(jq -r "${entry_path}.status" "${GT_STATE_FILE}" 2>/dev/null || echo "null")
    if [[ "${current_status}" =~ ^(failed|unknown)$ ]]; then
        die "attempt requires reconciliation"
    fi
    
    local status="null"
    if [[ "${fresh}" == true ]]; then
        # Submit new job
        local selected_node execute_payload
        selected_node=$(jq -r "${original_path}.selected_node" "${GT_STATE_FILE}")
        selected_device_id=$(jq -r "${original_path}.selected_device_id" "${GT_STATE_FILE}")
        execute_payload=$(jq -r "${original_path}" "${GT_STATE_FILE}")
        
        status=$(_request "${selected_node}" "{\"operation\": \"execute\", \"job\": ${execute_payload}}" "${selected_device_id}" 2>/dev/null) || {
            status="null"  # Request may have been accepted, proceed to query
        }
    fi
    
    # Set deadline
    local start_time deadline
    start_time=$(date +%s)
    deadline=$((start_time + GT_TIMEOUT))
    
    # Poll until completion or timeout
    while true; do
        if [[ "${status}" == "null" ]]; then
            # Query status
            local selected_node job_id attempt_id selected_device_id
            selected_node=$(jq -r "${original_path}.selected_node" "${GT_STATE_FILE}")
            job_id=$(jq -r "${original_path}.job_id" "${GT_STATE_FILE}")
            attempt_id=$(jq -r "${original_path}.attempt_id" "${GT_STATE_FILE}")
            selected_device_id=$(jq -r "${original_path}.selected_device_id" "${GT_STATE_FILE}")
            
            status=$(_request "${selected_node}" "{\"operation\": \"status\", \"job_id\": \"${job_id}\", \"attempt_id\": \"${attempt_id}\"}" "${selected_device_id}")
        fi
        
        # Validate status response
        local status_type
        status_type=$(jq 'type' <<<"${status}" 2>/dev/null || echo "null")
        if [[ "${status_type}" != "object" ]]; then
            die "attempt is not known by the node"
        fi
        
        # Check identity match
        local job_id_check selected_node_check attempt_id_check target_language_check
        job_id_check=$(jq -r '.job_id' <<<"${status}")
        selected_node_check=$(jq -r '.selected_node' <<<"${status}")
        attempt_id_check=$(jq -r '.attempt_id' <<<"${status}")
        target_language_check=$(jq -r '.target_language' <<<"${status}")
        
        local original_job_id original_selected_node original_attempt_id original_target_language
        original_job_id=$(jq -r "${original_path}.job_id" "${GT_STATE_FILE}")
        original_selected_node=$(jq -r "${original_path}.selected_node" "${GT_STATE_FILE}")
        original_attempt_id=$(jq -r "${original_path}.attempt_id" "${GT_STATE_FILE}")
        original_target_language=$(jq -r "${original_path}.target_language" "${GT_STATE_FILE}")
        
        if [[ "${job_id_check}" != "${original_job_id}" ]] || 
           [[ "${selected_node_check}" != "${original_selected_node}" ]] || 
           [[ "${attempt_id_check}" != "${original_attempt_id}" ]] || 
           [[ "${target_language_check}" != "${original_target_language}" ]]; then
            die "status identity mismatch"
        fi
        
        # Handle different statuses
        local state
        state=$(jq -r '.status' <<<"${status}")
        
        case "${state}" in
            "completed")
                local response
                response=$(jq -r '.response' <<<"${status}")
                
                # Validate response
                local response_status response_job_id response_selected_node response_target_language response_code
                response_status=$(jq -r '.status' <<<"${response}" 2>/dev/null || echo "null")
                response_job_id=$(jq -r '.job_id' <<<"${response}" 2>/dev/null || echo "null")
                response_selected_node=$(jq -r '.selected_node' <<<"${response}" 2>/dev/null || echo "null")
                response_target_language=$(jq -r '.target_language' <<<"${response}" 2>/dev/null || echo "null")
                response_code=$(jq -r '.code' <<<"${response}" 2>/dev/null || echo "null")
                
                if [[ "${response_status}" != "ok" ]] || 
                   [[ "${response_job_id}" != "${original_job_id}" ]] || 
                   [[ "${response_selected_node}" != "${original_selected_node}" ]] || 
                   [[ "${response_target_language}" != "${original_target_language}" ]] || 
                   [[ "${response_code}" == "null" ]] || 
                   [[ -z "$(echo "${response_code}" | tr -d ' \t\n\r')" ]]; then
                    die "invalid translation result"
                fi
                
                # Save successful response
                jq "${entry_path}.response = ${response} | ${entry_path}.status = \"completed\"" "${GT_STATE_FILE}" > "${GT_STATE_FILE}.tmp" && mv "${GT_STATE_FILE}.tmp" "${GT_STATE_FILE}"
                ${GT_SAVE_CALLBACK} "${GT_STATE_FILE}"
                _release "${original_path}" "${entry_path}"
                echo "${response}"
                return
                ;;
                
            "failed"|"unknown")
                jq "${entry_path}.status = \"${state}\"" "${GT_STATE_FILE}" > "${GT_STATE_FILE}.tmp" && mv "${GT_STATE_FILE}.tmp" "${GT_STATE_FILE}"
                ${GT_SAVE_CALLBACK} "${GT_STATE_FILE}"
                _release "${original_path}" "${entry_path}"
                die "attempt requires reconciliation"
                ;;
                
            "running")
                # Check timeout
                local current_time
                current_time=$(date +%s)
                if [[ "${current_time}" -ge "${deadline}" ]]; then
                    die "attempt is unresolved"
                fi
                
                # Sleep and continue polling
                sleep "${GT_INTERVAL}"
                status="null"
                ;;
                
            *)
                die "attempt is unresolved"
                ;;
        esac
    done
}
