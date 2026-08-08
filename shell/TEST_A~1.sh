#!/bin/bash
# TEST_A~1.PY — portiert nach shell
# Quelle: python, OpenClaw@gateway1:abstraction-manager/TEST_A~1.PY
# auch in: Projects@abstractions:abstractions/test_abstractions_manager.py
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# test_abstractions_manager.sh — Unit-Tests für den Abstractions Manager.
#
# Testet alle kritischen Sicherheits- und Kernfunktionen:
#     - Path-Traversal-Schutz (validate_source_file_path)
#     - Shell-Injection-Prävention (validate_task_description)
#     - Modell-Allowlist (validate_ai_model_name)
#     - Zielsprachen-Validierung (validate_target_language)
#     - Timeout-Validierung (validate_timeout_seconds)
#     - JSON-Serialisierung (create_abstraction.py Hilfsfunktionen)
#     - File-Change-Detection (Hash-basiert)
#     - Atomisches State-File-Schreiben
#
# Ausführen:
#     bash test_abstractions_manager.sh
#
# Author: OpenClaw Team
# Version: 1.0.0

# Sicherstellen dass lokale Module importierbar sind
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PYTHONPATH="${SCRIPT_DIR}:${PYTHONPATH:-}"

# Importiere benötigte Funktionen und Klassen aus Python-Modulen
source "${SCRIPT_DIR}/exceptions.sh"
source "${SCRIPT_DIR}/validators.sh"
source "${SCRIPT_DIR}/create_abstraction.sh"

# ===========================================================================
# Fixtures
# ===========================================================================

temp_workspace() {
    local tmp_path="$1"
    local workspace="${tmp_path}/workspace"
    local scripts_dir="${workspace}/skills/scripts"
    mkdir -p "${scripts_dir}"
    echo "${workspace}"
}

valid_python_script() {
    local temp_workspace="$1"
    local scripts_dir="${temp_workspace}/skills/scripts"
    local script="${scripts_dir}/db_maintainer.py"
    echo "# Test-Script" > "${script}"
    echo "print('hello world')" >> "${script}"
    echo "${script}"
}

state_file_path() {
    local tmp_path="$1"
    echo "${tmp_path}/db/abstractions_state.json"
}

# ===========================================================================
# Tests: Path-Traversal-Schutz
# ===========================================================================

test_valid_path_within_allowed_directory_is_accepted() {
    local valid_python_script="$1"
    local temp_workspace="$2"
    export OPENCLAW_WORKSPACE="${temp_workspace}"
    
    # Modul neu importieren damit Env-Variable wirkt
    source "${SCRIPT_DIR}/validators.sh"
    
    local result
    result=$(validate_source_file_path "${valid_python_script}")
    [[ "${result}" == "$(realpath "${valid_python_script}")" ]]
}

test_nonexistent_file_raises_file_not_found_error() {
    local nonexistent_path="/absolutely/nonexistent/path/script.py"
    if validate_source_file_path "${nonexistent_path}" 2>/dev/null; then
        return 1
    else
        return 0
    fi
}

test_directory_instead_of_file_raises_validation_error() {
    local tmp_path="$1"
    if validate_source_file_path "${tmp_path}" 2>/dev/null; then
        return 1
    else
        return 0
    fi
}

test_path_outside_workspace_raises_validation_error() {
    local traversal_attempt="$1"
    export OPENCLAW_WORKSPACE="/home/openclaw/.openclaw/workspace"
    
    # Datei existiert möglicherweise nicht — dann FileNotFoundError
    # Wenn sie existiert und außerhalb liegt — ValidationError
    if validate_source_file_path "${traversal_attempt}" 2>/dev/null; then
        return 1
    else
        return 0
    fi
}

# ===========================================================================
# Tests: Shell-Injection-Prävention
# ===========================================================================

test_valid_task_descriptions_are_accepted() {
    local valid_task="$1"
    local result
    result=$(validate_task_description "${valid_task}")
    [[ "${result}" == "${valid_task}" ]]
}

test_shell_metacharacters_are_rejected() {
    local malicious_input="$1"
    if validate_task_description "${malicious_input}" 2>/dev/null; then
        return 1
    else
        return 0
    fi
}

test_empty_task_raises_validation_error() {
    if validate_task_description "" 2>/dev/null; then
        return 1
    else
        return 0
    fi
}

test_whitespace_only_task_raises_validation_error() {
    if validate_task_description "   " 2>/dev/null; then
        return 1
    else
        return 0
    fi
}

test_task_at_maximum_length_is_accepted() {
    local max_length_task
    max_length_task=$(printf 'a%.0s' {1..500})
    local result
    result=$(validate_task_description "${max_length_task}")
    [[ ${#result} -eq 500 ]]
}

test_task_exceeding_maximum_length_raises_validation_error() {
    local too_long_task
    too_long_task=$(printf 'a%.0s' {1..501})
    if validate_task_description "${too_long_task}" 2>/dev/null; then
        return 1
    else
        return 0
    fi
}

# ===========================================================================
# Tests: Modell-Allowlist
# ===========================================================================

test_all_allowed_models_are_accepted() {
    local valid_model="$1"
    local result
    result=$(validate_ai_model_name "${valid_model}")
    [[ "${result}" == "${valid_model}" ]]
}

test_unknown_models_are_rejected() {
    local invalid_model="$1"
    if validate_ai_model_name "${invalid_model}" 2>/dev/null; then
        return 1
    else
        return 0
    fi
}

# ===========================================================================
# Tests: Zielsprachen-Validierung
# ===========================================================================

test_all_supported_languages_are_accepted() {
    local valid_language="$1"
    local result
    result=$(validate_target_language "${valid_language}")
    [[ "${result}" == "${valid_language,,}" ]]
}

test_language_is_normalized_to_lowercase() {
    local result
    result=$(validate_target_language "JavaScript")
    [[ "${result}" == "javascript" ]]
}

test_unsupported_language_raises_validation_error() {
    if validate_target_language "cobol" 2>/dev/null; then
        return 1
    else
        return 0
    fi
}

test_language_with_injection_attempt_raises_validation_error() {
    if validate_target_language "perl5; rm -rf /" 2>/dev/null; then
        return 1
    else
        return 0
    fi
}

# ===========================================================================
# Tests: Timeout-Validierung
# ===========================================================================

test_valid_timeouts_are_accepted() {
    local valid_timeout="$1"
    local result
    result=$(validate_timeout_seconds "${valid_timeout}")
    [[ "${result}" == "${valid_timeout}" ]]
}

test_out_of_range_timeouts_raise_validation_error() {
    local invalid_timeout="$1"
    if validate_timeout_seconds "${invalid_timeout}" 2>/dev/null; then
        return 1
    else
        return 0
    fi
}

test_float_timeout_raises_validation_error() {
    if validate_timeout_seconds "1800.5" 2>/dev/null; then
        return 1
    else
        return 0
    fi
}

# ===========================================================================
# Tests: API-Schlüssel-Validierung
# ===========================================================================

test_valid_api_key_is_returned() {
    local fake_key="$1"
    export ANTHROPIC_API_KEY="${fake_key}"
    local result
    result=$(load_and_validate_api_key "ANTHROPIC")
    [[ "${result}" == "${fake_key}" ]]
}

test_missing_api_key_raises_api_key_error() {
    unset ANTHROPIC_API_KEY 2>/dev/null || true
    if load_and_validate_api_key "ANTHROPIC" 2>/dev/null; then
        return 1
    else
        return 0
    fi
}

test_too_short_api_key_raises_api_key_error() {
    export ANTHROPIC_API_KEY="short"
    if load_and_validate_api_key "ANTHROPIC" 2>/dev/null; then
        return 1
    else
        return 0
    fi
}

# ===========================================================================
# Tests: File-Change-Detection
# ===========================================================================

test_unchanged_file_is_not_detected_as_changed() {
    local tmp_path="$1"
    local test_file="${tmp_path}/script.py"
    echo "print('hello')" > "${test_file}"
    
    local current_hash
    current_hash=$(compute_file_sha256 "${test_file}")
    local hash_cache="{\"${test_file}\": \"${current_hash}\"}"
    
    ! has_source_file_changed "${test_file}" "${hash_cache}"
}

test_modified_file_is_detected_as_changed() {
    local tmp_path="$1"
    local test_file="${tmp_path}/script.py"
    echo "print('hello')" > "${test_file}"
    local old_hash
    old_hash=$(compute_file_sha256 "${test_file}")
    
    local hash_cache="{\"${test_file}\": \"${old_hash}\"}"
    echo "print('changed!')" > "${test_file}"
    
    has_source_file_changed "${test_file}" "${hash_cache}"
}

test_new_file_without_cached_hash_is_detected_as_changed() {
    local tmp_path="$1"
    local test_file="${tmp_path}/new_script.py"
    echo "print('new')" > "${test_file}"
    local empty_cache="{}"
    
    has_source_file_changed "${test_file}" "${empty_cache}"
}

test_different_files_produce_different_hashes() {
    local tmp_path="$1"
    local file_a="${tmp_path}/a.py"
    local file_b="${tmp_path}/b.py"
    echo "content A" > "${file_a}"
    echo "content B" > "${file_b}"
    
    local hash_a
    local hash_b
    hash_a=$(compute_file_sha256 "${file_a}")
    hash_b=$(compute_file_sha256 "${file_b}")
    
    [[ "${hash_a}" != "${hash_b}" ]]
}

test_identical_content_produces_identical_hash() {
    local tmp_path="$1"
    local file_a="${tmp_path}/a.py"
    local file_b="${tmp_path}/b.py"
    local identical_content="identical content"
    echo "${identical_content}" > "${file_a}"
    echo "${identical_content}" > "${file_b}"
    
    local hash_a
    local hash_b
    hash_a=$(compute_file_sha256 "${file_a}")
    hash_b=$(compute_file_sha256 "${file_b}")
    
    [[ "${hash_a}" == "${hash_b}" ]]
}

# ===========================================================================
# Tests: Atomisches State-File
# ===========================================================================

test_state_is_saved_and_loaded_correctly() {
    local state_file_path="$1"
    local test_state='{"file_hashes": {"script.py": "abc123"}, "last_run": "2026-05-26T10:00:00"}'
    
    save_abstraction_state_atomically "${state_file_path}" "${test_state}"
    local loaded_state
    loaded_state=$(load_abstraction_state "${state_file_path}")
    
    [[ "${loaded_state}" == "${test_state}" ]]
}

test_nonexistent_state_file_returns_empty_dict() {
    local tmp_path="$1"
    local nonexistent_path="${tmp_path}/nonexistent/state.json"
    local result
    result=$(load_abstraction_state "${nonexistent_path}")
    [[ "${result}" == "{}" ]]
}

test_atomic_write_creates_parent_directories() {
    local tmp_path="$1"
    local deep_path="${tmp_path}/a/b/c/state.json"
    save_abstraction_state_atomically "${deep_path}" '{"key": "value"}'
    [[ -f "${deep_path}" ]]
}

test_atomic_write_leaves_no_temp_file_on_success() {
    local tmp_path="$1"
    local state_path="${tmp_path}/state.json"
    save_abstraction_state_atomically "${state_path}" '{"data": 1}'
    
    local temp_files
    temp_files=$(find "${tmp_path}" -name "*.tmp" 2>/dev/null || true)
    [[ -z "${temp_files}" ]]
}

test_invalid_json_in_state_file_raises_state_file_error() {
    local tmp_path="$1"
    local corrupted_state="${tmp_path}/state.json"
    echo "{ invalid json !!!" > "${corrupted_state}"
    
    if load_abstraction_state "${corrupted_state}" 2>/dev/null; then
        return 1
    else
        return 0
    fi
}

# ===========================================================================
# Tests: Sprachzuordnung
# ===========================================================================

test_all_supported_languages_have_file_extensions() {
    local language
    for language in "${ALLOWED_TARGET_LANGUAGES[@]}"; do
        if [[ ! -v LANGUAGE_FILE_EXTENSIONS["${language}"] ]]; then
            echo "Fehlende Extension für Sprache: ${language}" >&2
            return 1
        fi
    done
}

test_correct_file_extension_per_language() {
    local language="$1"
    local expected_ext="$2"
    [[ "${LANGUAGE_FILE_EXTENSIONS["${language}"]}" == "${expected_ext}" ]]
}

# ===========================================================================
# Main Test Runner
# ===========================================================================

main() {
    local tmp_dir
    tmp_dir=$(mktemp -d)
    trap 'rm -rf "${tmp_dir}"' EXIT
    
    echo "Running tests..."
    
    # Run Path-Traversal-Schutz tests
    local workspace
    workspace=$(temp_workspace "${tmp_dir}")
    local script
    script=$(valid_python_script "${workspace}")
    
    test_valid_path_within_allowed_directory_is_accepted "${script}" "${workspace}" || echo "FAILED: test_valid_path_within_allowed_directory_is_accepted"
    test_nonexistent_file_raises_file_not_found_error || echo "FAILED: test_nonexistent_file_raises_file_not_found_error"
    test_directory_instead_of_file_raises_validation_error "${tmp_dir}" || echo "FAILED: test_directory_instead_of_file_raises_validation_error"
    test_path_outside_workspace_raises_validation_error "/etc/passwd" || echo "FAILED: test_path_outside_workspace_raises_validation_error"
    
    # Run Shell-Injection-Prävention tests
    test_valid_task_descriptions_are_accepted "Port db_maintainer.py to Go" || echo "FAILED: test_valid_task_descriptions_are_accepted"
    test_shell_metacharacters_are_rejected "; rm -rf /" || echo "FAILED: test_shell_metacharacters_are_rejected"
    test_empty_task_raises_validation_error || echo "FAILED: test_empty_task_raises_validation_error"
    test_whitespace_only_task_raises_validation_error || echo "FAILED: test_whitespace_only_task_raises_validation_error"
    test_task_at_maximum_length_is_accepted || echo "FAILED: test_task_at_maximum_length_is_accepted"
    test_task_exceeding_maximum_length_raises_validation_error || echo "FAILED: test_task_exceeding_maximum_length_raises_validation_error"
    
    # Run Modell-Allowlist tests
    test_all_allowed_models_are_accepted "openrouter/claude-3-5-sonnet-20241022" || echo "FAILED: test_all_allowed_models_are_accepted"
    test_unknown_models_are_rejected "gpt-4" || echo "FAILED: test_unknown_models_are_rejected"
    
    # Run Zielsprachen-Validierung tests
    test_all_supported_languages_are_accepted "javascript" || echo "FAILED: test_all_supported_languages_are_accepted"
    test_language_is_normalized_to_lowercase || echo "FAILED: test_language_is_normalized_to_lowercase"
    test_unsupported_language_raises_validation_error || echo "FAILED: test_unsupported_language_raises_validation_error"
    test_language_with_injection_attempt_raises_validation_error || echo "FAILED: test_language_with_injection_attempt_raises_validation_error"
    
    # Run Timeout-Validierung tests
    test_valid_timeouts_are_accepted "1800" || echo "FAILED: test_valid_timeouts_are_accepted"
    test_out_of_range_timeouts_raise_validation_error "0" || echo "FAILED: test_out_of_range_timeouts_raise_validation_error"
    test_float_timeout_raises_validation_error || echo "FAILED: test_float_timeout_raises_validation_error"
    
    # Run API-Schlüssel-Validierung tests
    test_valid_api_key_is_returned "sk-ant-api03-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" || echo "FAILED: test_valid_api_key_is_returned"
    test_missing_api_key_raises_api_key_error || echo "FAILED: test_missing_api_key_raises_api_key_error"
    test_too_short_api_key_raises_api_key_error || echo "FAILED: test_too_short_api_key_raises_api_key_error"
    
    # Run File-Change-Detection tests
    test_unchanged_file_is_not_detected_as_changed "${tmp_dir}" || echo "FAILED: test_unchanged_file_is_not_detected_as_changed"
    test_modified_file_is_detected_as_changed "${tmp_dir}" || echo "FAILED: test_modified_file_is_detected_as_changed"
    test_new_file_without_cached_hash_is_detected_as_changed "${tmp_dir}" || echo "FAILED: test_new_file_without_cached_hash_is_detected_as_changed"
    test_different_files_produce_different_hashes "${tmp_dir}" || echo "FAILED: test_different_files_produce_different_hashes"
    test_identical_content_produces_identical_hash "${tmp_dir}" || echo "FAILED: test_identical_content_produces_identical_hash"
    
    # Run Atomisches State-File tests
    local state_path
    state_path=$(state_file_path "${tmp_dir}")
    test_state_is_saved_and_loaded_correctly "${state_path}" || echo "FAILED: test_state_is_saved_and_loaded_correctly"
    test_nonexistent_state_file_returns_empty_dict "${tmp_dir}" || echo "FAILED: test_nonexistent_state_file_returns_empty_dict"
    test_atomic_write_creates_parent_directories "${tmp_dir}" || echo "FAILED: test_atomic_write_creates_parent_directories"
    test_atomic_write_leaves_no_temp_file_on_success "${tmp_dir}" || echo "FAILED: test_atomic_write_leaves_no_temp_file_on_success"
    test_invalid_json_in_state_file_raises_state_file_error "${tmp_dir}" || echo "FAILED: test_invalid_json_in_state_file_raises_state_file_error"
    
    # Run Sprachzuordnung tests
    test_all_supported_languages_have_file_extensions || echo "FAILED: test_all_supported_languages_have_file_extensions"
    test_correct_file_extension_per_language "perl5" ".pl" || echo "FAILED: test_correct_file_extension_per_language perl5"
    test_correct_file_extension_per_language "javascript" ".js" || echo "FAILED: test_correct_file_extension_per_language javascript"
    
    echo "Tests completed."
}

main "$@"
