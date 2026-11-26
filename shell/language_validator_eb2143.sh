#!/usr/bin/env bash
# abstraction-provenance: {"artifact_sha256": "21cad4c0a0770ae0da6bc2abca17dd61e7008edf5cfc129c2e87ced3c1c3a016", "source_sha256": "eb21431dabeaafc82a1e3ccf24278616e46ed082eca1de4d328c758ee82ee2c7", "target_language": "shell"}
# language_validator.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:skills/scripting-utils/scripts/language_validator.py
# auch in: OpenClaw@gateway2:skills/scripting-utils/scripts/language_validator.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Multi-language script validator supporting 8+ languages.
# WebSearch integration for documentation lookup.

declare -A LANGUAGES_CMD
declare -A LANGUAGES_ARGS
declare -A LANGUAGES_LINTER

LANGUAGES_CMD[bash]="bash"
LANGUAGES_ARGS[bash]="-n"
LANGUAGES_LINTER[bash]="shellcheck"

LANGUAGES_CMD[sh]="sh"
LANGUAGES_ARGS[sh]="-n"
LANGUAGES_LINTER[sh]="shellcheck"

LANGUAGES_CMD[python]="python3"
LANGUAGES_ARGS[python]="-m py_compile"
LANGUAGES_LINTER[python]="pylint"

LANGUAGES_CMD[perl]="perl"
LANGUAGES_ARGS[perl]="-c"
LANGUAGES_LINTER[perl]="perlcritic"

LANGUAGES_CMD[raku]="raku"
LANGUAGES_ARGS[raku]="-c"
LANGUAGES_LINTER[raku]=""

LANGUAGES_CMD[powershell]="pwsh"
LANGUAGES_ARGS[powershell]="-Command Get-Command"
LANGUAGES_LINTER[powershell]=""

LANGUAGES_CMD[javascript]="node"
LANGUAGES_ARGS[javascript]="--check"
LANGUAGES_LINTER[javascript]="eslint"

LANGUAGES_CMD[tcl]="tclsh"
LANGUAGES_ARGS[tcl]=""
LANGUAGES_LINTER[tcl]=""

# Documentation URLs for WebSearch
declare -A DOCS_URLS
DOCS_URLS[powershell]="https://docs.microsoft.com/powershell/"
DOCS_URLS[raku]="https://docs.raku.org/"
DOCS_URLS[tcl]="https://www.tcl.tk/"

validate_script() {
    local language="$1"
    local script_path="$2"
    local use_websearch="${3:-true}"
    
    local errors=()
    local warnings=()
    local valid=true
    local doc_url=""
    
    # Check if language is supported
    if [[ -z "${LANGUAGES_CMD[$language]:-}" ]]; then
        echo "Error: Unsupported language: $language" >&2
        exit 1
    fi
    
    # Syntax check
    local cmd="${LANGUAGES_CMD[$language]}"
    local args="${LANGUAGES_ARGS[$language]}"
    
    # Run syntax validation with timeout
    local output
    local exit_code=0
    output=$(timeout 30s "$cmd" $args "$script_path" 2>&1) || exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        errors+=("$output")
        valid=false
    elif [[ $exit_code -eq 124 ]]; then
        errors+=("Validation timeout")
        valid=false
    elif ! command -v "$cmd" &>/dev/null; then
        errors+=("Command not found: $cmd")
        valid=false
        
        # Try to fetch documentation if WebSearch enabled
        if [[ "$use_websearch" == true ]] && [[ -n "${DOCS_URLS[$language]:-}" ]]; then
            doc_url="${DOCS_URLS[$language]}"
        fi
    fi
    
    # Linter check if available
    local linter="${LANGUAGES_LINTER[$language]:-}"
    if [[ -n "$linter" ]] && command -v "$linter" &>/dev/null; then
        case "$linter" in
            shellcheck)
                local linter_output
                linter_output=$(shellcheck -f gcc "$script_path" 2>&1) || true
                if [[ -n "$linter_output" ]]; then
                    IFS=$'\n' read -ra lines <<< "$linter_output"
                    for line in "${lines[@]}"; do
                        warnings+=("$line")
                    done
                fi
                ;;
            pylint)
                local linter_output
                linter_output=$(pylint --output-format=parseable "$script_path" 2>&1) || true
                if [[ -n "$linter_output" ]]; then
                    IFS=$'\n' read -ra lines <<< "$linter_output"
                    for line in "${lines[@]}"; do
                        warnings+=("$line")
                    done
                fi
                ;;
            eslint)
                local linter_output
                linter_output=$(eslint "$script_path" 2>&1) || true
                if [[ -n "$linter_output" ]]; then
                    IFS=$'\n' read -ra lines <<< "$linter_output"
                    for line in "${lines[@]}"; do
                        warnings+=("$line")
                    done
                fi
                ;;
        esac
    elif [[ -n "$linter" ]] && ! command -v "$linter" &>/dev/null; then
        warnings+=("Linter not installed: $linter")
    fi
    
    # Output results
    echo "Language: $language"
    echo "Valid: $valid"
    
    if [[ ${#errors[@]} -gt 0 ]]; then
        echo "Errors: ${#errors[@]}"
        local i=0
        for error in "${errors[@]}"; do
            if [[ $i -lt 5 ]]; then
                echo "  - $error"
                ((i++))
            fi
        done
    fi
    
    if [[ ${#warnings[@]} -gt 0 ]]; then
        echo "Warnings: ${#warnings[@]}"
        local i=0
        for warning in "${warnings[@]}"; do
            if [[ $i -lt 5 ]]; then
                echo "  - $warning"
                ((i++))
            fi
        done
    fi
    
    if [[ -n "$doc_url" ]]; then
        echo "Docs: $doc_url"
    fi
    
    if [[ "$valid" == false ]]; then
        exit 1
    fi
}

print_usage() {
    cat << EOF
Usage: $0 [OPTIONS] SCRIPT_FILE

Validate scripts in multiple languages

OPTIONS:
    --lang LANGUAGE     Language (bash/python/perl/etc.)
    --no-websearch      Disable WebSearch
    -h, --help          Show this help message

EOF
}

main() {
    local script_file=""
    local language=""
    local use_websearch=true
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --lang)
                language="$2"
                shift 2
                ;;
            --no-websearch)
                use_websearch=false
                shift
                ;;
            -h|--help)
                print_usage
                exit 0
                ;;
            -*)
                echo "Unknown option: $1" >&2
                print_usage
                exit 1
                ;;
            *)
                script_file="$1"
                shift
                ;;
        esac
    done
    
    if [[ -z "$script_file" ]]; then
        echo "Error: Script file is required" >&2
        print_usage
        exit 1
    fi
    
    if [[ -z "$language" ]]; then
        echo "Error: Language must be specified with --lang" >&2
        print_usage
        exit 1
    fi
    
    if [[ ! -f "$script_file" ]]; then
        echo "Error: File not found: $script_file" >&2
        exit 1
    fi
    
    validate_script "$language" "$script_file" "$use_websearch"
}

main "$@"
