#!/usr/bin/env bash
# init_skill.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:skills/skill-creator/scripts/init_skill.py
# auch in: OpenClaw@gateway2:skills/skill-creator/scripts/init_skill.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Skill Initializer - Creates a new skill from template

# Usage:
#     init_skill.sh <skill-name> --path <path> [--resources scripts,references,assets] [--examples]

# Examples:
#     init_skill.sh my-new-skill --path skills/public
#     init_skill.sh my-new-skill --path skills/public --resources scripts,references
#     init_skill.sh my-api-helper --path skills/private --resources scripts --examples
#     init_skill.sh custom-skill --path /custom/location

MAX_SKILL_NAME_LENGTH=64
ALLOWED_RESOURCES=("scripts" "references" "assets")

SKILL_TEMPLATE='---
name: {skill_name}
description: [TODO: Complete and informative explanation of what the skill does and when to use it. Include WHEN to use this skill - specific scenarios, file types, or tasks that trigger it.]
---

# {skill_title}

## Overview

[TODO: 1-2 sentences explaining what this skill enables]

## Structuring This Skill

[TODO: Choose the structure that best fits this skill''s purpose. Common patterns:

**1. Workflow-Based** (best for sequential processes)
- Works well when there are clear step-by-step procedures
- Example: DOCX skill with "Workflow Decision Tree" -> "Reading" -> "Creating" -> "Editing"
- Structure: ## Overview -> ## Workflow Decision Tree -> ## Step 1 -> ## Step 2...

**2. Task-Based** (best for tool collections)
- Works well when the skill offers different operations/capabilities
- Example: PDF skill with "Quick Start" -> "Merge PDFs" -> "Split PDFs" -> "Extract Text"
- Structure: ## Overview -> ## Quick Start -> ## Task Category 1 -> ## Task Category 2...

**3. Reference/Guidelines** (best for standards or specifications)
- Works well for brand guidelines, coding standards, or requirements
- Example: Brand styling with "Brand Guidelines" -> "Colors" -> "Typography" -> "Features"
- Structure: ## Overview -> ## Guidelines -> ## Specifications -> ## Usage...

**4. Capabilities-Based** (best for integrated systems)
- Works well when the skill provides multiple interrelated features
- Example: Product Management with "Core Capabilities" -> numbered capability list
- Structure: ## Overview -> ## Core Capabilities -> ### 1. Feature -> ### 2. Feature...

Patterns can be mixed and matched as needed. Most skills combine patterns (e.g., start with task-based, add workflow for complex operations).

Delete this entire "Structuring This Skill" section when done - it''s just guidance.]

## [TODO: Replace with the first main section based on chosen structure]

[TODO: Add content here. See examples in existing skills:
- Code samples for technical skills
- Decision trees for complex workflows
- Concrete examples with realistic user requests
- References to scripts/templates/references as needed]

## Resources (optional)

Create only the resource directories this skill actually needs. Delete this section if no resources are required.

### scripts/
Executable code (Python/Bash/etc.) that can be run directly to perform specific operations.

**Examples from other skills:**
- PDF skill: `fill_fillable_fields.py`, `extract_form_field_info.py` - utilities for PDF manipulation
- DOCX skill: `document.py`, `utilities.py` - Python modules for document processing

**Appropriate for:** Python scripts, shell scripts, or any executable code that performs automation, data processing, or specific operations.

**Note:** Scripts may be executed without loading into context, but can still be read by Codex for patching or environment adjustments.

### references/
Documentation and reference material intended to be loaded into context to inform Codex''s process and thinking.

**Examples from other skills:**
- Product management: `communication.md`, `context_building.md` - detailed workflow guides
- BigQuery: API reference documentation and query examples
- Finance: Schema documentation, company policies

**Appropriate for:** In-depth documentation, API references, database schemas, comprehensive guides, or any detailed information that Codex should reference while working.

### assets/
Files not intended to be loaded into context, but rather used within the output Codex produces.

**Examples from other skills:**
- Brand styling: PowerPoint template files (.pptx), logo files
- Frontend builder: HTML/React boilerplate project directories
- Typography: Font files (.ttf, .woff2)

**Appropriate for:** Templates, boilerplate code, document templates, images, icons, fonts, or any files meant to be copied or used in the final output.

---

**Not every skill requires all three types of resources.**
'

EXAMPLE_SCRIPT='#!/usr/bin/env python3
"""
Example helper script for {skill_name}

This is a placeholder script that can be executed directly.
Replace with actual implementation or delete if not needed.

Example real scripts from other skills:
- pdf/scripts/fill_fillable_fields.py - Fills PDF form fields
- pdf/scripts/convert_pdf_to_images.py - Converts PDF pages to images
"""

def main():
    print("This is an example script for {skill_name}")
    # TODO: Add actual script logic here
    # This could be data processing, file conversion, API calls, etc.

if __name__ == "__main__":
    main()
'

EXAMPLE_REFERENCE='# Reference Documentation for {skill_title}

This is a placeholder for detailed reference documentation.
Replace with actual reference content or delete if not needed.

Example real reference docs from other skills:
- product-management/references/communication.md - Comprehensive guide for status updates
- product-management/references/context_building.md - Deep-dive on gathering context
- bigquery/references/ - API references and query examples

## When Reference Docs Are Useful

Reference docs are ideal for:
- Comprehensive API documentation
- Detailed workflow guides
- Complex multi-step processes
- Information too lengthy for main SKILL.md
- Content that''s only needed for specific use cases

## Structure Suggestions

### API Reference Example
- Overview
- Authentication
- Endpoints with examples
- Error codes
- Rate limits

### Workflow Guide Example
- Prerequisites
- Step-by-step instructions
- Common patterns
- Troubleshooting
- Best practices
'

EXAMPLE_ASSET='# Example Asset File

This placeholder represents where asset files would be stored.
Replace with actual asset files (templates, images, fonts, etc.) or delete if not needed.

Asset files are NOT intended to be loaded into context, but rather used within
the output Codex produces.

Example asset files from other skills:
- Brand guidelines: logo.png, slides_template.pptx
- Frontend builder: hello-world/ directory with HTML/React boilerplate
- Typography: custom-font.ttf, font-family.woff2
- Data: sample_data.csv, test_dataset.json

## Common Asset Types

- Templates: .pptx, .docx, boilerplate directories
- Images: .png, .jpg, .svg, .gif
- Fonts: .ttf, .otf, .woff, .woff2
- Boilerplate code: Project directories, starter files
- Icons: .ico, .svg
- Data files: .csv, .json, .xml, .yaml

Note: This is a text placeholder. Actual assets can be any file type.
'


# Normalize a skill name to lowercase hyphen-case
normalize_skill_name() {
    local skill_name="$1"
    # Convert to lowercase
    local normalized=$(echo "$skill_name" | tr '[:upper:]' '[:lower:]')
    # Replace non-alphanumeric characters with hyphens
    normalized=$(echo "$normalized" | sed 's/[^a-z0-9]/-/g')
    # Remove leading/trailing hyphens
    normalized=$(echo "$normalized" | sed 's/^-//' | sed 's/-$//')
    # Replace multiple consecutive hyphens with single hyphen
    normalized=$(echo "$normalized" | sed 's/--*/-/g')
    echo "$normalized"
}

# Convert hyphenated skill name to Title Case for display
title_case_skill_name() {
    local skill_name="$1"
    local title=""
    IFS='-' read -ra WORDS <<< "$skill_name"
    for word in "${WORDS[@]}"; do
        if [ -n "$title" ]; then
            title="$title "
        fi
        # Capitalize first letter
        title="$title$(echo "${word:0:1}" | tr '[:lower:]' '[:upper:]')${word:1}"
    done
    echo "$title"
}

# Parse resources string and validate
parse_resources() {
    local raw_resources="$1"
    if [ -z "$raw_resources" ]; then
        echo ""
        return
    fi
    
    local resources=()
    IFS=',' read -ra ITEMS <<< "$raw_resources"
    for item in "${ITEMS[@]}"; do
        local trimmed=$(echo "$item" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        if [ -n "$trimmed" ]; then
            resources+=("$trimmed")
        fi
    done
    
    # Check for invalid resources
    local invalid=()
    for resource in "${resources[@]}"; do
        local found=false
        for allowed in "${ALLOWED_RESOURCES[@]}"; do
            if [ "$resource" = "$allowed" ]; then
                found=true
                break
            fi
        done
        if [ "$found" = false ]; then
            invalid+=("$resource")
        fi
    done
    
    if [ ${#invalid[@]} -gt 0 ]; then
        echo "[ERROR] Unknown resource type(s): ${invalid[*]}" >&2
        echo "   Allowed: ${ALLOWED_RESOURCES[*]}" >&2
        exit 1
    fi
    
    # Deduplicate resources
    local deduped=()
    local seen=()
    for resource in "${resources[@]}"; do
        local is_duplicate=false
        for s in "${seen[@]}"; do
            if [ "$s" = "$resource" ]; then
                is_duplicate=true
                break
            fi
        done
        if [ "$is_duplicate" = false ]; then
            deduped+=("$resource")
            seen+=("$resource")
        fi
    done
    
    # Output deduplicated resources
    local result=""
    for resource in "${deduped[@]}"; do
        if [ -n "$result" ]; then
            result="$result,$resource"
        else
            result="$resource"
        fi
    done
    echo "$result"
}

# Create resource directories
create_resource_dirs() {
    local skill_dir="$1"
    local skill_name="$2"
    local skill_title="$3"
    local resources="$4"
    local include_examples="$5"
    
    if [ -z "$resources" ]; then
        return
    fi
    
    IFS=',' read -ra RESOURCE_ARRAY <<< "$resources"
    for resource in "${RESOURCE_ARRAY[@]}"; do
        local resource_dir="$skill_dir/$resource"
        mkdir -p "$resource_dir"
        
        if [ "$resource" = "scripts" ]; then
            if [ "$include_examples" = "true" ]; then
                echo "$EXAMPLE_SCRIPT" | sed "s/{skill_name}/$skill_name/g" > "$resource_dir/example.py"
                chmod 755 "$resource_dir/example.py"
                echo "[OK] Created scripts/example.py"
            else
                echo "[OK] Created scripts/"
            fi
        elif [ "$resource" = "references" ]; then
            if [ "$include_examples" = "true" ]; then
                echo "$EXAMPLE_REFERENCE" | sed "s/{skill_title}/$skill_title/g" > "$resource_dir/api_reference.md"
                echo "[OK] Created references/api_reference.md"
            else
                echo "[OK] Created references/"
            fi
        elif [ "$resource" = "assets" ]; then
            if [ "$include_examples" = "true" ]; then
                echo "$EXAMPLE_ASSET" > "$resource_dir/example_asset.txt"
                echo "[OK] Created assets/example_asset.txt"
            else
                echo "[OK] Created assets/"
            fi
        fi
    done
}

# Initialize a new skill directory with template SKILL.md
init_skill() {
    local skill_name="$1"
    local path="$2"
    local resources="$3"
    local include_examples="$4"
    
    # Determine skill directory path
    local skill_dir
    skill_dir=$(realpath "$path")/"$skill_name"
    
    # Check if directory already exists
    if [ -d "$skill_dir" ]; then
        echo "[ERROR] Skill directory already exists: $skill_dir" >&2
        return 1
    fi
    
    # Create skill directory
    if ! mkdir -p "$skill_dir"; then
        echo "[ERROR] Error creating directory: $skill_dir" >&2
        return 1
    fi
    echo "[OK] Created skill directory: $skill_dir"
    
    # Create SKILL.md from template
    local skill_title
    skill_title=$(title_case_skill_name "$skill_name")
    local skill_content
    skill_content=$(echo "$SKILL_TEMPLATE" | sed "s/{skill_name}/$skill_name/g" | sed "s/{skill_title}/$skill_title/g")
    
    local skill_md_path="$skill_dir/SKILL.md"
    if ! echo "$skill_content" > "$skill_md_path"; then
        echo "[ERROR] Error creating SKILL.md" >&2
        return 1
    fi
    echo "[OK] Created SKILL.md"
    
    # Create resource directories if requested
    if [ -n "$resources" ]; then
        if ! create_resource_dirs "$skill_dir" "$skill_name" "$skill_title" "$resources" "$include_examples"; then
            echo "[ERROR] Error creating resource directories" >&2
            return 1
        fi
    fi
    
    # Print next steps
    echo
    echo "[OK] Skill '$skill_name' initialized successfully at $skill_dir"
    echo
    echo "Next steps:"
    echo "1. Edit SKILL.md to complete the TODO items and update the description"
    if [ -n "$resources" ]; then
        if [ "$include_examples" = "true" ]; then
            echo "2. Customize or delete the example files in scripts/, references/, and assets/"
        else
            echo "2. Add resources to scripts/, references/, and assets/ as needed"
        fi
    else
        echo "2. Create resource directories only if needed (scripts/, references/, assets/)"
    fi
    echo "3. Run the validator when ready to check the skill structure"
    
    return 0
}

# Main function
main() {
    local skill_name=""
    local path=""
    local resources=""
    local include_examples="false"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --path)
                path="$2"
                shift 2
                ;;
            --resources)
                resources="$2"
                shift 2
                ;;
            --examples)
                include_examples="true"
                shift
                ;;
            -*)
                echo "Unknown option: $1" >&2
                exit 1
                ;;
            *)
                if [ -z "$skill_name" ]; then
                    skill_name="$1"
                else
                    echo "Unexpected argument: $1" >&2
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Validate required arguments
    if [ -z "$skill_name" ]; then
        echo "Usage: $0 <skill-name> --path <path> [--resources scripts,references,assets] [--examples]" >&2
        exit 1
    fi
    
    if [ -z "$path" ]; then
        echo "[ERROR] --path is required" >&2
        exit 1
    fi
    
    # Normalize skill name
    local normalized_skill_name
    normalized_skill_name=$(normalize_skill_name "$skill_name")
    if [ -z "$normalized_skill_name" ]; then
        echo "[ERROR] Skill name must include at least one letter or digit." >&2
        exit 1
    fi
    
    if [ ${#normalized_skill_name} -gt $MAX_SKILL_NAME_LENGTH ]; then
        echo "[ERROR] Skill name '$normalized_skill_name' is too long (${#normalized_skill_name} characters). Maximum is $MAX_SKILL_NAME_LENGTH characters." >&2
        exit 1
    fi
    
    if [ "$normalized_skill_name" != "$skill_name" ]; then
        echo "Note: Normalized skill name from '$skill_name' to '$normalized_skill_name'."
    fi
    
    # Parse and validate resources
    local parsed_resources
    parsed_resources=$(parse_resources "$resources")
    
    if [ "$include_examples" = "true" ] && [ -z "$parsed_resources" ]; then
        echo "[ERROR] --examples requires --resources to be set." >&2
        exit 1
    fi
    
    # Print configuration
    echo "Initializing skill: $normalized_skill_name"
    echo "   Location: $path"
    if [ -n "$parsed_resources" ]; then
        echo "   Resources: $parsed_resources"
        if [ "$include_examples" = "true" ]; then
            echo "   Examples: enabled"
        fi
    else
        echo "   Resources: none (create as needed)"
    fi
    echo
    
    # Initialize the skill
    if init_skill "$normalized_skill_name" "$path" "$parsed_resources" "$include_examples"; then
        exit 0
    else
        exit 1
    fi
}

# Run main function with all arguments
main "$@"
