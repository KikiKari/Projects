#!/usr/bin/env bash
# quick_validate.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:skills/skill-creator/scripts/quick_validate.py
# auch in: OpenClaw@gateway2:skills/skill-creator/scripts/quick_validate.py
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Quick validation script for skills - minimal version

MAX_SKILL_NAME_LENGTH=64

# Function to extract frontmatter from SKILL.md
_extract_frontmatter() {
    local content="$1"
    local lines
    IFS=$'\n' read -rd '' -a lines <<<"$content" || true
    if [[ ${#lines[@]} -eq 0 ]] || [[ "${lines[0]}" != "---" ]]; then
        echo ""
        return
    fi
    local i
    for ((i = 1; i < ${#lines[@]}; i++)); do
        if [[ "${lines[$i]}" == "---" ]]; then
            printf '%s\n' "${lines[@]:1:$((i - 1))}"
            return
        fi
    done
    echo ""
}

# Minimal fallback parser for frontmatter when yq is unavailable
_parse_simple_frontmatter() {
    local frontmatter_text="$1"
    local -A parsed
    local current_key=""
    local line stripped key value current_value

    while IFS= read -r line || [[ -n "$line" ]]; do
        stripped=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        if [[ -z "$stripped" ]] || [[ "$stripped" =~ ^#.* ]]; then
            continue
        fi

        if [[ "$line" =~ ^[[:space:]]+ ]]; then
            if [[ -z "$current_key" ]]; then
                echo "ERROR: Indentation without key"
                return 1
            fi
            current_value="${parsed[$current_key]}"
            if [[ -n "$current_value" ]]; then
                parsed["$current_key"]="${current_value}"$'\n'"${stripped}"
            else
                parsed["$current_key"]="${stripped}"
            fi
            continue
        fi

        if [[ "$stripped" != *:* ]]; then
            echo "ERROR: Invalid line format"
            return 1
        fi

        key=$(echo "$stripped" | cut -d':' -f1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        value=$(echo "$stripped" | cut -d':' -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

        if [[ -z "$key" ]]; then
            echo "ERROR: Empty key"
            return 1
        fi

        # Remove surrounding quotes if present
        if [[ ("${value:0:1}" == "\"" && "${value: -1}" == "\"") || ("${value:0:1}" == "'" && "${value: -1}" == "'") ]]; then
            value="${value:1:${#value}-2}"
        fi

        parsed["$key"]="$value"
        current_key="$key"
    done <<<"$frontmatter_text"

    # Output the parsed data in a format we can use
    for k in "${!parsed[@]}"; do
        echo "KEY:$k:VALUE:${parsed[$k]}"
    done
}

validate_skill() {
    local skill_path="$1"
    local skill_md="$skill_path/SKILL.md"

    if [[ ! -f "$skill_md" ]]; then
        echo "SKILL.md not found"
        return 1
    fi

    local content
    if ! content=$(cat "$skill_md"); then
        echo "Could not read SKILL.md: $?"
        return 1
    fi

    local frontmatter_text
    frontmatter_text=$(_extract_frontmatter "$content")
    if [[ -z "$frontmatter_text" ]]; then
        echo "Invalid frontmatter format"
        return 1
    fi

    local -A frontmatter
    local has_yq=false
    if command -v yq >/dev/null 2>&1; then
        has_yq=true
    fi

    if [[ "$has_yq" == true ]]; then
        local temp_file
        temp_file=$(mktemp)
        echo "$frontmatter_text" >"$temp_file"
        if ! yq . "$temp_file" >/dev/null 2>&1; then
            rm -f "$temp_file"
            echo "Invalid YAML in frontmatter: yq parse error"
            return 1
        fi
        # Read keys and values into associative array
        while IFS= read -r line; do
            if [[ "$line" == KEY:*:VALUE:* ]]; then
                local key="${line#KEY:}"
                key="${key%%:VALUE:*}"
                local val="${line##*:VALUE:}"
                frontmatter["$key"]="$val"
            fi
        done < <(yq -o=json '.' "$temp_file" | jq -r 'to_entries[] | "KEY:\(.key):VALUE:\(.value)"' 2>/dev/null || echo "")
        rm -f "$temp_file"
    else
        local parsed_lines
        parsed_lines=$(_parse_simple_frontmatter "$frontmatter_text")
        if [[ $? -ne 0 ]]; then
            echo "Invalid YAML in frontmatter: unsupported syntax without PyYAML installed"
            return 1
        fi
        while IFS= read -r line || [[ -n "$line" ]]; do
            if [[ "$line" == KEY:*:VALUE:* ]]; then
                local key="${line#KEY:}"
                key="${key%%:VALUE:*}"
                local val="${line##*:VALUE:}"
                frontmatter["$key"]="$val"
            fi
        done <<<"$parsed_lines"
    fi

    local allowed_properties=("name" "description" "license" "allowed-tools" "metadata")
    local unexpected_keys=()

    for key in "${!frontmatter[@]}"; do
        local found=false
        for prop in "${allowed_properties[@]}"; do
            if [[ "$key" == "$prop" ]]; then
                found=true
                break
            fi
        done
        if [[ "$found" == false ]]; then
            unexpected_keys+=("$key")
        fi
    done

    if [[ ${#unexpected_keys[@]} -gt 0 ]]; then
        IFS=',' read -ra sorted_unexpected <<<$(printf '%s\n' "${unexpected_keys[@]}" | sort)
        IFS=',' read -ra sorted_allowed <<<$(printf '%s\n' "${allowed_properties[@]}" | sort)
        local unexpected_str allowed_str
        printf -v unexpected_str '%s,' "${sorted_unexpected[@]}"
        printf -v allowed_str '%s,' "${sorted_allowed[@]}"
        unexpected_str=${unexpected_str%,}
        allowed_str=${allowed_str%,}
        echo "Unexpected key(s) in SKILL.md frontmatter: ${unexpected_str}. Allowed properties are: ${allowed_str}"
        return 1
    fi

    if [[ -z "${frontmatter[name]:-}" ]]; then
        echo "Missing 'name' in frontmatter"
        return 1
    fi

    if [[ -z "${frontmatter[description]:-}" ]]; then
        echo "Missing 'description' in frontmatter"
        return 1
    fi

    local name="${frontmatter[name]}"
    if [[ ! "$name" =~ ^[a-z0-9-]+$ ]]; then
        echo "Name '$name' should be hyphen-case (lowercase letters, digits, and hyphens only)"
        return 1
    fi

    if [[ "$name" == -* ]] || [[ "$name" == *- ]] || [[ "$name" == *--* ]]; then
        echo "Name '$name' cannot start/end with hyphen or contain consecutive hyphens"
        return 1
    fi

    if [[ ${#name} -gt $MAX_SKILL_NAME_LENGTH ]]; then
        echo "Name is too long (${#name} characters). Maximum is $MAX_SKILL_NAME_LENGTH characters."
        return 1
    fi

    local description="${frontmatter[description]}"
    if [[ "$description" == *"<"* ]] || [[ "$description" == *">"* ]]; then
        echo "Description cannot contain angle brackets (< or >)"
        return 1
    fi

    if [[ ${#description} -gt 1024 ]]; then
        echo "Description is too long (${#description} characters). Maximum is 1024 characters."
        return 1
    fi

    echo "Skill is valid!"
    return 0
}

main() {
    if [[ $# -ne 1 ]]; then
        echo "Usage: $0 <skill_directory>"
        exit 1
    fi

    if validate_skill "$1"; then
        exit 0
    else
        exit 1
    fi
}

main "$@"
