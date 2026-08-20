#!/usr/bin/env bash
# test_package_skill.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:skills/skill-creator/scripts/test_package_skill.py
# auch in: OpenClaw@gateway2:skills/skill-creator/scripts/test_package_skill.py
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Regression tests for skill packaging security behavior.

# Create temporary directory for testing
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Mock quick_validate function
quick_validate() {
    echo "Skill is valid!"
}

# Source the package_skill script (assuming it's in the same directory)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/package_skill.sh"

# Helper function to create a basic skill structure
create_skill() {
    local skill_name="${1:-test-skill}"
    local skill_dir="$TEMP_DIR/$skill_name"
    
    mkdir -p "$skill_dir"
    cat > "$skill_dir/SKILL.md" <<EOF
---
name: test-skill
description: test
---
EOF
    echo "print('ok')" > "$skill_dir/script.py"
    
    echo "$skill_dir"
}

# Test that normal files are packaged correctly
test_packages_normal_files() {
    local skill_dir=$(create_skill "normal-skill")
    local out_dir="$TEMP_DIR/out"
    mkdir -p "$out_dir"
    
    package_skill "$skill_dir" "$out_dir"
    
    local skill_file="$out_dir/normal-skill.skill"
    if [[ ! -f "$skill_file" ]]; then
        echo "FAIL: Skill file was not created"
        return 1
    fi
    
    # Check contents of zip file
    local temp_extract="$TEMP_DIR/extract"
    mkdir -p "$temp_extract"
    unzip -q "$skill_file" -d "$temp_extract"
    
    if [[ ! -f "$temp_extract/normal-skill/SKILL.md" ]] || [[ ! -f "$temp_extract/normal-skill/script.py" ]]; then
        echo "FAIL: Expected files not found in archive"
        rm -rf "$temp_extract"
        return 1
    fi
    
    rm -rf "$temp_extract"
    echo "PASS: Normal files packaged correctly"
}

# Test that symlinks to external files are skipped
test_skips_symlink_to_external_file() {
    local skill_dir=$(create_skill "symlink-file-skill")
    local outside="$TEMP_DIR/outside-secret.txt"
    echo "super-secret" > "$outside"
    local link="$skill_dir/loot.txt"
    local out_dir="$TEMP_DIR/out"
    mkdir -p "$out_dir"
    
    # Try to create symlink, skip test if not supported
    if ! ln -s "$outside" "$link" 2>/dev/null; then
        echo "SKIP: Symlink unsupported on this platform"
        return 0
    fi
    
    package_skill "$skill_dir" "$out_dir"
    
    local skill_file="$out_dir/symlink-file-skill.skill"
    if [[ ! -f "$skill_file" ]]; then
        echo "FAIL: Skill file was not created"
        return 1
    fi
    
    # Check contents of zip file
    local temp_extract="$TEMP_DIR/extract"
    mkdir -p "$temp_extract"
    unzip -q "$skill_file" -d "$temp_extract"
    
    if [[ ! -f "$temp_extract/symlink-file-skill/SKILL.md" ]] || [[ ! -f "$temp_extract/symlink-file-skill/script.py" ]]; then
        echo "FAIL: Expected files not found in archive"
        rm -rf "$temp_extract"
        return 1
    fi
    
    if [[ -f "$temp_extract/symlink-file-skill/loot.txt" ]]; then
        echo "FAIL: External symlink file should not be included"
        rm -rf "$temp_extract"
        return 1
    fi
    
    rm -rf "$temp_extract"
    echo "PASS: Symlink to external file skipped"
}

# Test that symlink directories are skipped
test_skips_symlink_directory() {
    local skill_dir=$(create_skill "symlink-dir-skill")
    local outside_dir="$TEMP_DIR/outside"
    mkdir -p "$outside_dir"
    echo "secret" > "$outside_dir/secret.txt"
    local link="$skill_dir/docs"
    local out_dir="$TEMP_DIR/out"
    mkdir -p "$out_dir"
    
    # Try to create symlink, skip test if not supported
    if ! ln -sfn "$outside_dir" "$link" 2>/dev/null; then
        echo "SKIP: Symlink unsupported on this platform"
        return 0
    fi
    
    package_skill "$skill_dir" "$out_dir"
    
    local skill_file="$out_dir/symlink-dir-skill.skill"
    
    # Check contents of zip file
    local temp_extract="$TEMP_DIR/extract"
    mkdir -p "$temp_extract"
    unzip -q "$skill_file" -d "$temp_extract"
    
    if [[ ! -f "$temp_extract/symlink-dir-skill/SKILL.md" ]] || [[ ! -f "$temp_extract/symlink-dir-skill/script.py" ]]; then
        echo "FAIL: Expected files not found in archive"
        rm -rf "$temp_extract"
        return 1
    fi
    
    if [[ -f "$temp_extract/symlink-dir-skill/docs/secret.txt" ]]; then
        echo "FAIL: External symlink directory should not be included"
        rm -rf "$temp_extract"
        return 1
    fi
    
    rm -rf "$temp_extract"
    echo "PASS: Symlink directory skipped"
}

# Test rejection when resolved path is outside skill root
test_rejects_resolved_path_outside_skill_root() {
    local skill_dir=$(create_skill "escape-skill")
    local out_dir="$TEMP_DIR/out"
    mkdir -p "$out_dir"
    
    # Override _is_within function to simulate path check failure for script.py
    _is_within() {
        local path="$1"
        local root="$2"
        
        # Extract filename from path
        local filename=$(basename "$path")
        
        if [[ "$filename" == "script.py" ]]; then
            echo "false"
        else
            # Call original implementation
            original__is_within "$path" "$root"
        fi
    }
    
    # Store original and override
    original__is_within="_is_within_original"
    _is_within_original() {
        # Original implementation would go here
        # For now we just return true for all other cases
        echo "true"
    }
    
    # Run package_skill with mocked function
    local result
    result=$(package_skill "$skill_dir" "$out_dir" 2>/dev/null || echo "null")
    
    if [[ "$result" != "null" ]]; then
        echo "FAIL: Should reject paths outside skill root"
        return 1
    fi
    
    echo "PASS: Correctly rejects paths outside skill root"
}

# Test that nested regular files are allowed
test_allows_nested_regular_files() {
    local skill_dir=$(create_skill "nested-skill")
    local nested="$skill_dir/lib/helpers"
    mkdir -p "$nested"
    echo "def run():
    return 1" > "$nested/util.py"
    local out_dir="$TEMP_DIR/out"
    mkdir -p "$out_dir"
    
    package_skill "$skill_dir" "$out_dir"
    
    local skill_file="$out_dir/nested-skill.skill"
    
    # Check contents of zip file
    local temp_extract="$TEMP_DIR/extract"
    mkdir -p "$temp_extract"
    unzip -q "$skill_file" -d "$temp_extract"
    
    if [[ ! -f "$temp_extract/nested-skill/lib/helpers/util.py" ]]; then
        echo "FAIL: Nested file not found in archive"
        rm -rf "$temp_extract"
        return 1
    fi
    
    rm -rf "$temp_extract"
    echo "PASS: Nested regular files allowed"
}

# Test that output archive is skipped when output dir is skill dir
test_skips_output_archive_when_output_dir_is_skill_dir() {
    local skill_dir=$(create_skill "self-output-skill")
    
    package_skill "$skill_dir" "$skill_dir"
    
    local skill_file="$skill_dir/self-output-skill.skill"
    if [[ ! -f "$skill_file" ]]; then
        echo "FAIL: Skill file was not created"
        return 1
    fi
    
    # Check contents of zip file
    local temp_extract="$TEMP_DIR/extract"
    mkdir -p "$temp_extract"
    unzip -q "$skill_file" -d "$temp_extract"
    
    if [[ ! -f "$temp_extract/self-output-skill/SKILL.md" ]] || [[ ! -f "$temp_extract/self-output-skill/script.py" ]]; then
        echo "FAIL: Expected files not found in archive"
        rm -rf "$temp_extract"
        return 1
    fi
    
    if [[ -f "$temp_extract/self-output-skill/self-output-skill.skill" ]]; then
        echo "FAIL: Output archive should not include itself"
        rm -rf "$temp_extract"
        return 1
    fi
    
    rm -rf "$temp_extract"
    echo "PASS: Output archive correctly skips itself"
}

# Run all tests
run_tests() {
    local passed=0
    local failed=0
    
    echo "Running security regression tests..."
    
    # List of test functions
    local tests=(
        test_packages_normal_files
        test_skips_symlink_to_external_file
        test_skips_symlink_directory
        test_rejects_resolved_path_outside_skill_root
        test_allows_nested_regular_files
        test_skips_output_archive_when_output_dir_is_skill_dir
    )
    
    for test_func in "${tests[@]}"; do
        echo "Running $test_func..."
        if "$test_func"; then
            ((passed++))
        else
            ((failed++))
        fi
        echo ""
    done
    
    echo "Tests completed: $passed passed, $failed failed"
    
    if [[ $failed -gt 0 ]]; then
        exit 1
    fi
}

# Execute tests
run_tests
