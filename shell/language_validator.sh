#!/usr/bin/env bash
# language_validator.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:skills/scripting-utils/scripts/language_validator.py
# auch in: OpenClaw@gateway2:skills/scripting-utils/scripts/language_validator.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Multi-language script validator supporting 8+ languages.
# WebSearch integration for documentation lookup.

# Associative arrays for language configurations
declare -A LANGUAGES_CMD
declare -A LANGUAGES_ARGS
declare -A LANGUAGES_LINTER
declare -A DOCS_URL

# Initialize language configurations
LANGUAGES_CMD=(
    [bash]="bash"
    [sh]="sh"
    [python]="python3"
    [perl]="perl"
    [raku]="raku"
    [powershell]="pwsh"
    [javascript]="node"
    [tcl]="tclsh"
)

LANGUAGES_ARGS=(
    [bash]="-n"
    [sh]="-n"
    [python]="-m py_compile"
    [perl]="-c"
    [raku]="-c"
    [powershell]="-Command Get-Command"
    [javascript]="--check"
    [tcl]=""
)

LANGUAGES_LINTER=(
    [bash]="shellcheck"
    [sh]="shellcheck"
    [python]="pylint"
    [perl]="perlcritic"
    [raku]=""
    [powershell]=""
    [javascript]="eslint"
    [tcl]=""
)

DOCS_URL=(
    [powershell]="https://docs.microsoft.com/powershell/"
    [raku]="https://docs.raku.org/"
    [tcl]="https://www.tcl.tk/"
)

# Global variables
LANGUAGE=""
USE_WEBSEARCH=true
SCRIPT_PATH=""

# ValidationResult structure simulation
VALIDATION_LANGUAGE=""
VALIDATION_VALID=false
VALIDATION_ERRORS=()
VALIDATION_WARNINGS=()
VALIDATION_DOC_URL=""

# Function to print usage
usage() {
    cat <<EOF
Usage: $0 [OPTIONS] SCRIPT
Validate scripts in multiple languages

Arguments:
  SCRIPT                    Path to script file

Options:
  --lang LANGUAGE           Language (bash/python/perl/etc.)
  --no-websearch            Disable WebSearch
  -h, --help                Show this help message
EOF
}

# Function to validate arguments
validate_args() {
    if [[ -z "${SCRIPT_PATH}" ]]; then
        echo "Error: Script path is required" >&2
        usage
        exit 1
    fi

    if [[ -z "${LANGUAGE}" ]]; then
        echo "Error: Language is required" >&2
        usage
        exit 1
    fi

    if [[ ! -f "${SCRIPT_PATH}" ]]; then
        echo "Error: Script file not found: ${SCRIPT_PATH}" >&2
        exit 1
    fi

    if [[ -z "${LANGUAGES_CMD[${LANGUAGE}]:-}" ]]; then
        echo "Error: Unsupported language: ${LANGUAGE}" >&2
        exit 1
    fi
}

# Function to run syntax check
run_syntax_check() {
    local cmd="${LANGUAGES_CMD[${LANGUAGE}]}"
    local args="${LANGUAGES_ARGS[${LANGUAGE}]}"
    local script_path="$1"
    
    # Split args into array
    read -ra ARG_ARRAY <<< "${args}"
    
    # Build command array
    local cmd_array=("${cmd}")
    if [[ ${#ARG_ARRAY[@]} -gt 0 && -n "${ARG_ARRAY[0]}" ]]; then
        cmd_array+=("${ARG_ARRAY[@]}")
    fi
    cmd_array+=("${script_path}")
    
    # Run command with timeout
    local output
    local return_code
    output=$(timeout 30 "${cmd_array[@]}" 2>&1) || {
        return_code=$?
        if [[ $return_code -eq 124 ]]; then
            VALIDATION_ERRORS+=("Validation timeout")
        else
            VALIDATION_ERRORS+=("${output}")
        fi
        return 1
    }
    
    return 0
}

# Function to run linter
run_linter() {
    local script_path="$1"
    local linter="${LANGUAGES_LINTER[${LANGUAGE}]:-}"
    
    if [[ -z "${linter}" ]]; then
        return 0
    fi
    
    local output
    local return_code
    
    case "${linter}" in
        shellcheck)
            if command -v shellcheck >/dev/null 2>&1; then
                output=$(shellcheck -f gcc "${script_path}" 2>&1) || {
                    return_code=$?
                    if [[ $return_code -ne 0 && -n "${output}" ]]; then
                        mapfile -t linter_lines <<< "${output}"
                        VALIDATION_WARNINGS+=("${linter_lines[@]}")
                    fi
                }
            else
                VALIDATION_WARNINGS+=("Linter not installed: ${linter}")
            fi
            ;;
        pylint)
            if command -v pylint >/dev/null 2>&1; then
                output=$(pylint --output-format=parseable "${script_path}" 2>&1) || {
                    return_code=$?
                    if [[ $return_code -ne 0 && -n "${output}" ]]; then
                        mapfile -t linter_lines <<< "${output}"
                        VALIDATION_WARNINGS+=("${linter_lines[@]}")
                    fi
                }
            else
                VALIDATION_WARNINGS+=("Linter not installed: ${linter}")
            fi
            ;;
        perlcritic)
            if command -v perlcritic >/dev/null 2>&1; then
                output=$(perlcritic "${script_path}" 2>&1) || {
                    return_code=$?
                    if [[ $return_code -ne 0 && -n "${output}" ]]; then
                        mapfile -t linter_lines <<< "${output}"
                        VALIDATION_WARNINGS+=("${linter_lines[@]}")
                    fi
                }
            else
                VALIDATION_WARNINGS+=("Linter not installed: ${linter}")
            fi
            ;;
        eslint)
            if command -v eslint >/dev/null 2>&1; then
                output=$(eslint "${script_path}" 2>&1) || {
                    return_code=$?
                    if [[ $return_code -ne 0 && -n "${output}" ]]; then
                        mapfile -t linter_lines <<< "${output}"
                        VALIDATION_WARNINGS+=("${linter_lines[@]}")
                    fi
                }
            else
                VALIDATION_WARNINGS+=("Linter not installed: ${linter}")
            fi
            ;;
    esac
}

# Function to fetch documentation URL
fetch_docs() {
    if [[ "${USE_WEBSEARCH}" != true ]]; then
        return
    fi
    
    if [[ -n "${DOCS_URL[${LANGUAGE}]:-}" ]]; then
        VALIDATION_DOC_URL="${DOCS_URL[${LANGUAGE}]}"
    fi
}

# Main validation function
validate() {
    local script_path="$1"
    
    # Initialize result
    VALIDATION_LANGUAGE="${LANGUAGE}"
    VALIDATION_VALID=true
    VALIDATION_ERRORS=()
    VALIDATION_WARNINGS=()
    VALIDATION_DOC_URL=""
    
    # Syntax check
    if ! run_syntax_check "${script_path}"; then
        VALIDATION_VALID=false
        # If command not found, try to fetch docs
        if [[ "${VALIDATION_ERRORS[*]}" == *"Command not found"* ]] || [[ "${VALIDATION_ERRORS[*]}" == *"command not found"* ]]; then
            fetch_docs
            return
        fi
    fi
    
    # Linter check if available
    run_linter "${script_path}"
    
    # Determine validity
    if [[ ${#VALIDATION_ERRORS[@]} -gt 0 ]]; then
        VALIDATION_VALID=false
    fi
}

# Function to print results
print_results() {
    echo "Language: ${VALIDATION_LANGUAGE}"
    echo "Valid: ${VALIDATION_VALID}"
    
    if [[ ${#VALIDATION_ERRORS[@]} -gt 0 ]]; then
        echo "Errors: ${#VALIDATION_ERRORS[@]}"
        local i=0
        for error in "${VALIDATION_ERRORS[@]}"; do
            if [[ $i -ge 5 ]]; then
                break
            fi
            echo "  - ${error}"
            ((i++))
        done
    fi
    
    if [[ ${#VALIDATION_WARNINGS[@]} -gt 0 ]]; then
        echo "Warnings: ${#VALIDATION_WARNINGS[@]}"
        local i=0
        for warning in "${VALIDATION_WARNINGS[@]}"; do
            if [[ $i -ge 5 ]]; then
                break
            fi
            echo "  - ${warning}"
            ((i++))
        done
    fi
    
    if [[ -n "${VALIDATION_DOC_URL}" ]]; then
        echo "Docs: ${VALIDATION_DOC_URL}"
    fi
}

# Main function
main() {
    # Parse arguments
    local args=()
    while [[ $# -gt 0 ]]; do
        case $1 in
            --lang)
                LANGUAGE="$2"
                shift 2
                ;;
            --no-websearch)
                USE_WEBSEARCH=false
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            -*)
                echo "Unknown option: $1" >&2
                usage
                exit 1
                ;;
            *)
                args+=("$1")
                shift
                ;;
        esac
    done
    
    # Set script path from remaining arguments
    if [[ ${#args[@]} -gt 0 ]]; then
        SCRIPT_PATH="${args[0]}"
    fi
    
    # Validate arguments
    validate_args
    
    # Run validation
    validate "${SCRIPT_PATH}"
    
    # Print results
    print_results
    
    # Exit with appropriate code
    if [[ "${VALIDATION_VALID}" == true ]]; then
        exit 0
    else
        exit 1
    fi
}

# Run main function
main "$@"
