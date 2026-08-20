#!/usr/bin/env bash
# test_quick_validate.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:skills/skill-creator/scripts/test_quick_validate.py
# auch in: OpenClaw@gateway2:skills/skill-creator/scripts/test_quick_validate.py
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

# Regression tests for quick skill validation.

set -euo pipefail

# Create a temporary directory for testing
temp_dir=$(mktemp -d -t test_quick_validate.XXXXXX)

# Clean up function
cleanup() {
    rm -rf "$temp_dir"
}
trap cleanup EXIT

# Function to simulate quick_validate.validate_skill behavior
validate_skill() {
    local skill_dir="$1"
    local skill_file="$skill_dir/SKILL.md"
    
    # Check if SKILL.md exists
    if [[ ! -f "$skill_file" ]]; then
        echo "false"
        echo "SKILL.md not found"
        return
    fi
    
    # Read the file content
    local content
    content=$(cat "$skill_file")
    
    # Count opening and closing frontmatter fences
    local open_fences=$(echo "$content" | grep -c "^---$" || true)
    
    # Must have at least 2 fences (opening and closing)
    if [[ $open_fences -lt 2 ]]; then
        echo "false"
        echo "Invalid frontmatter format"
        return
    fi
    
    # Extract frontmatter (everything between first two ---)
    local frontmatter
    frontmatter=$(echo "$content" | sed -n '1,/^---$/p' | head -n -1 | tail -n +2)
    
    # Check if required fields exist
    if ! echo "$frontmatter" | grep -q "^name:"; then
        echo "false"
        echo "Missing required field: name"
        return
    fi
    
    if ! echo "$frontmatter" | grep -q "^description:"; then
        echo "false"
        echo "Missing required field: description"
        return
    fi
    
    # If we got here, it's valid
    echo "true"
    echo "Valid skill"
}

# Test 1: Accepts CRLF frontmatter
test_accepts_crlf_frontmatter() {
    local skill_dir="$temp_dir/crlf-skill"
    mkdir -p "$skill_dir"
    
    cat > "$skill_dir/SKILL.md" << 'EOF'
---
name: crlf-skill
description: ok
---
# Skill
EOF
    
    # Convert LF to CRLF
    perl -pi -e 's/\n/\r\n/g' "$skill_dir/SKILL.md"
    
    local result
    result=$(validate_skill "$skill_dir")
    local valid=$(echo "$result" | head -n1)
    local message=$(echo "$result" | tail -n1)
    
    if [[ "$valid" != "true" ]]; then
        echo "FAIL: test_accepts_crlf_frontmatter - $message"
        exit 1
    fi
    echo "PASS: test_accepts_crlf_frontmatter"
}

# Test 2: Rejects missing frontmatter closing fence
test_rejects_missing_frontmatter_closing_fence() {
    local skill_dir="$temp_dir/bad-skill"
    mkdir -p "$skill_dir"
    
    cat > "$skill_dir/SKILL.md" << 'EOF'
---
name: bad-skill
description: missing end
# no closing fence
EOF
    
    local result
    result=$(validate_skill "$skill_dir")
    local valid=$(echo "$result" | head -n1)
    local message=$(echo "$result" | tail -n1)
    
    if [[ "$valid" != "false" ]] || [[ "$message" != "Invalid frontmatter format" ]]; then
        echo "FAIL: test_rejects_missing_frontmatter_closing_fence - Expected false with 'Invalid frontmatter format', got $valid with '$message'"
        exit 1
    fi
    echo "PASS: test_rejects_missing_frontmatter_closing_fence"
}

# Test 3: Fallback parser handles multiline frontmatter
test_fallback_parser_handles_multiline_frontmatter() {
    local skill_dir="$temp_dir/multiline-skill"
    mkdir -p "$skill_dir"
    
    cat > "$skill_dir/SKILL.md" << 'EOF'
---
name: multiline-skill
description: Works without pyyaml
allowed-tools:
  - gh
metadata: |
  {
    "owners": ["team-openclaw"]
  }
---
# Skill
EOF
    
    local result
    result=$(validate_skill "$skill_dir")
    local valid=$(echo "$result" | head -n1)
    local message=$(echo "$result" | tail -n1)
    
    if [[ "$valid" != "true" ]]; then
        echo "FAIL: test_fallback_parser_handles_multiline_frontmatter - $message"
        exit 1
    fi
    echo "PASS: test_fallback_parser_handles_multiline_frontmatter"
}

# Run all tests
test_accepts_crlf_frontmatter
test_rejects_missing_frontmatter_closing_fence
test_fallback_parser_handles_multiline_frontmatter

echo "All tests passed!"
