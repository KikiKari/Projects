#!/usr/bin/env bash
# package_skill.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:skills/skill-creator/scripts/package_skill.py
# auch in: OpenClaw@gateway2:skills/skill-creator/scripts/package_skill.py
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Skill Packager - Creates a distributable .skill file of a skill folder
#
# Usage:
#     bash utils/package_skill.sh <path/to/skill-folder> [output-directory]
#
# Example:
#     bash utils/package_skill.sh skills/public/my-skill
#     bash utils/package_skill.sh skills/public/my-skill ./dist

# Function to check if a path is within another path
_is_within() {
    local path="$1"
    local root="$2"
    
    # Use realpath to resolve paths and check if path starts with root
    local real_path
    local real_root
    real_path=$(realpath "$path" 2>/dev/null) || return 1
    real_root=$(realpath "$root" 2>/dev/null) || return 1
    
    # Check if path is within root by seeing if root is a prefix
    case "$real_path/" in
        "$real_root/"*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Function to validate skill using external validator
validate_skill() {
    local skill_path="$1"
    
    # Try to run quick_validate.py if it exists
    if [[ -f "quick_validate.py" ]]; then
        python3 quick_validate.py "$skill_path" 2>&1
    elif [[ -f "utils/quick_validate.py" ]]; then
        python3 utils/quick_validate.py "$skill_path" 2>&1
    else
        echo "false:quick_validate.py not found"
    fi
}

# Main packaging function
package_skill() {
    local skill_path="$1"
    local output_dir="${2:-}"

    # Resolve the skill path
    if ! skill_path=$(realpath "$skill_path" 2>/dev/null) || [[ ! -e "$skill_path" ]]; then
        echo "[ERROR] Skill folder not found: $skill_path" >&2
        return 1
    fi

    if [[ ! -d "$skill_path" ]]; then
        echo "[ERROR] Path is not a directory: $skill_path" >&2
        return 1
    fi

    # Validate SKILL.md exists
    if [[ ! -f "$skill_path/SKILL.md" ]]; then
        echo "[ERROR] SKILL.md not found in $skill_path" >&2
        return 1
    fi

    # Run validation before packaging
    echo "Validating skill..."
    local validation_result
    validation_result=$(validate_skill "$skill_path")
    
    if [[ "${validation_result%%:*}" != "true" ]]; then
        echo "[ERROR] Validation failed: ${validation_result#*:}"
        echo "   Please fix the validation errors before packaging."
        return 1
    fi
    
    echo "[OK] ${validation_result#*:}"
    echo

    # Determine output location
    local skill_name
    skill_name=$(basename "$skill_path")
    
    local output_path
    if [[ -n "$output_dir" ]]; then
        mkdir -p "$output_dir"
        output_path=$(realpath "$output_dir")
    else
        output_path=$(pwd)
    fi

    local skill_filename="$output_path/${skill_name}.skill"

    # Create temporary directory for packaging
    local temp_dir
    temp_dir=$(mktemp -d)
    trap 'rm -rf "$temp_dir"' EXIT

    # Copy files to temporary directory, excluding unwanted directories
    local excluded_dirs=("*/.git/*" "*/.svn/*" "*/.hg/*" "*/__pycache__/*" "*/node_modules/*")
    local find_excludes=""
    for dir in "${excluded_dirs[@]}"; do
        find_excludes+=" -not -path \"$dir\""
    done

    # Find all files to include
    local files_to_copy=()
    while IFS= read -r -d '' file; do
        files_to_copy+=("$file")
    done < <(find "$skill_path" -type f -not -name "*.skill" $find_excludes -print0)

    # Process each file
    for file in "${files_to_copy[@]}"; do
        # Skip symlinks
        if [[ -L "$file" ]]; then
            echo "[WARN] Skipping symlink: $file"
            continue
        fi

        # Check if file is within skill root
        if ! _is_within "$file" "$skill_path"; then
            echo "[ERROR] File escapes skill root: $file" >&2
            return 1
        fi

        # Calculate relative path and create directory structure
        local rel_path
        rel_path=${file#$skill_path/}
        local dest_dir="$temp_dir/$skill_name"
        
        # Create directory structure
        mkdir -p "$(dirname "$dest_dir/$rel_path")"
        
        # Copy file
        cp "$file" "$dest_dir/$rel_path"
        echo "  Added: $skill_name/$rel_path"
    done

    # Create the .skill file (zip format)
    (
        cd "$temp_dir" || exit 1
        zip -r "$skill_filename" "$skill_name" >/dev/null
    )

    echo
    echo "[OK] Successfully packaged skill to: $skill_filename"
    echo "$skill_filename"
}

# Main function
main() {
    if [[ $# -lt 1 ]]; then
        echo "Usage: bash utils/package_skill.sh <path/to/skill-folder> [output-directory]"
        echo
        echo "Example:"
        echo "  bash utils/package_skill.sh skills/public/my-skill"
        echo "  bash utils/package_skill.sh skills/public/my-skill ./dist"
        exit 1
    fi

    local skill_path="$1"
    local output_dir=""
    if [[ $# -gt 1 ]]; then
        output_dir="$2"
    fi

    echo "Packaging skill: $skill_path"
    if [[ -n "$output_dir" ]]; then
        echo "   Output directory: $output_dir"
    fi
    echo

    if package_skill "$skill_path" "$output_dir"; then
        exit 0
    else
        exit 1
    fi
}

main "$@"
