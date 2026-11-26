<?php
// abstraction-provenance: {"artifact_sha256": "95ab2046e9f99afc35deda7a2e4969fd51addf5f01958b8092e2c267ec8c3834", "source_sha256": "bcd6b802c400a9e89319844c6c3d965855c8b0555e982eb72cd4accb7ee67e3e", "target_language": "php"}
// init_skill.py — portiert nach php
// Quelle: python, OpenClaw@gateway1:skills/skill-creator/scripts/init_skill.py
// auch in: OpenClaw@gateway2:skills/skill-creator/scripts/init_skill.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py
/**
 * Skill Initializer - Creates a new skill from template
 *
 * Usage:
 *     php init_skill.php <skill-name> --path <path> [--resources scripts,references,assets] [--examples]
 *
 * Examples:
 *     php init_skill.php my-new-skill --path skills/public
 *     php init_skill.php my-new-skill --path skills/public --resources scripts,references
 *     php init_skill.php my-api-helper --path skills/private --resources scripts --examples
 *     php init_skill.php custom-skill --path /custom/location
 */

const MAX_SKILL_NAME_LENGTH = 64;
const ALLOWED_RESOURCES = ["scripts", "references", "assets"];

$SKILL_TEMPLATE = <<<EOT
---
name: {skill_name}
description: [TODO: Complete and informative explanation of what the skill does and when to use it. Include WHEN to use this skill - specific scenarios, file types, or tasks that trigger it.]
---

# {skill_title}

## Overview

[TODO: 1-2 sentences explaining what this skill enables]

## Structuring This Skill

[TODO: Choose the structure that best fits this skill's purpose. Common patterns:

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

Delete this entire "Structuring This Skill" section when done - it's just guidance.]

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
Documentation and reference material intended to be loaded into context to inform Codex's process and thinking.

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
EOT;

$EXAMPLE_SCRIPT = <<<EOT
#!/usr/bin/env python3
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
EOT;

$EXAMPLE_REFERENCE = <<<EOT
# Reference Documentation for {skill_title}

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
- Content that's only needed for specific use cases

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
EOT;

$EXAMPLE_ASSET = <<<EOT
# Example Asset File

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
EOT;

function normalize_skill_name($skill_name) {
    // Normalize a skill name to lowercase hyphen-case.
    $normalized = trim(strtolower($skill_name));
    $normalized = preg_replace('/[^a-z0-9]+/', '-', $normalized);
    $normalized = trim($normalized, '-');
    $normalized = preg_replace('/-{2,}/', '-', $normalized);
    return $normalized;
}

function title_case_skill_name($skill_name) {
    // Convert hyphenated skill name to Title Case for display.
    return implode(' ', array_map('ucfirst', explode('-', $skill_name)));
}

function parse_resources($raw_resources) {
    if (!$raw_resources) {
        return [];
    }
    $resources = array_filter(array_map('trim', explode(',', $raw_resources)));
    $invalid = array_diff($resources, ALLOWED_RESOURCES);
    if (!empty($invalid)) {
        $allowed = implode(', ', ALLOWED_RESOURCES);
        echo "[ERROR] Unknown resource type(s): " . implode(', ', $invalid) . "\n";
        echo "   Allowed: $allowed\n";
        exit(1);
    }
    return array_unique($resources);
}

function create_resource_dirs($skill_dir, $skill_name, $skill_title, $resources, $include_examples) {
    global $EXAMPLE_SCRIPT, $EXAMPLE_REFERENCE, $EXAMPLE_ASSET;
    
    foreach ($resources as $resource) {
        $resource_dir = "$skill_dir/$resource";
        if (!is_dir($resource_dir)) {
            mkdir($resource_dir, 0755, true);
        }
        
        if ($resource === "scripts") {
            if ($include_examples) {
                $example_script = "$resource_dir/example.py";
                file_put_contents($example_script, str_replace('{skill_name}', $skill_name, $EXAMPLE_SCRIPT));
                chmod($example_script, 0755);
                echo "[OK] Created scripts/example.py\n";
            } else {
                echo "[OK] Created scripts/\n";
            }
        } elseif ($resource === "references") {
            if ($include_examples) {
                $example_reference = "$resource_dir/api_reference.md";
                file_put_contents($example_reference, str_replace('{skill_title}', $skill_title, $EXAMPLE_REFERENCE));
                echo "[OK] Created references/api_reference.md\n";
            } else {
                echo "[OK] Created references/\n";
            }
        } elseif ($resource === "assets") {
            if ($include_examples) {
                $example_asset = "$resource_dir/example_asset.txt";
                file_put_contents($example_asset, $EXAMPLE_ASSET);
                echo "[OK] Created assets/example_asset.txt\n";
            } else {
                echo "[OK] Created assets/\n";
            }
        }
    }
}

function init_skill($skill_name, $path, $resources, $include_examples) {
    /**
     * Initialize a new skill directory with template SKILL.md.
     *
     * @param string $skill_name Name of the skill
     * @param string $path Path where the skill directory should be created
     * @param array $resources Resource directories to create
     * @param bool $include_examples Whether to create example files in resource directories
     * @return string|null Path to created skill directory, or null if error
     */
    
    // Determine skill directory path
    $skill_dir = realpath($path) . DIRECTORY_SEPARATOR . $skill_name;

    // Check if directory already exists
    if (file_exists($skill_dir)) {
        echo "[ERROR] Skill directory already exists: $skill_dir\n";
        return null;
    }

    // Create skill directory
    try {
        mkdir($skill_dir, 0755, true);
        echo "[OK] Created skill directory: $skill_dir\n";
    } catch (Exception $e) {
        echo "[ERROR] Error creating directory: " . $e->getMessage() . "\n";
        return null;
    }

    // Create SKILL.md from template
    global $SKILL_TEMPLATE;
    $skill_title = title_case_skill_name($skill_name);
    $skill_content = str_replace(
        ['{skill_name}', '{skill_title}'],
        [$skill_name, $skill_title],
        $SKILL_TEMPLATE
    );

    $skill_md_path = "$skill_dir/SKILL.md";
    try {
        file_put_contents($skill_md_path, $skill_content);
        echo "[OK] Created SKILL.md\n";
    } catch (Exception $e) {
        echo "[ERROR] Error creating SKILL.md: " . $e->getMessage() . "\n";
        return null;
    }

    // Create resource directories if requested
    if (!empty($resources)) {
        try {
            create_resource_dirs($skill_dir, $skill_name, $skill_title, $resources, $include_examples);
        } catch (Exception $e) {
            echo "[ERROR] Error creating resource directories: " . $e->getMessage() . "\n";
            return null;
        }
    }

    // Print next steps
    echo "\n[OK] Skill '$skill_name' initialized successfully at $skill_dir\n";
    echo "\nNext steps:\n";
    echo "1. Edit SKILL.md to complete the TODO items and update the description\n";
    if (!empty($resources)) {
        if ($include_examples) {
            echo "2. Customize or delete the example files in scripts/, references/, and assets/\n";
        } else {
            echo "2. Add resources to scripts/, references/, and assets/ as needed\n";
        }
    } else {
        echo "2. Create resource directories only if needed (scripts/, references/, assets/)\n";
    }
    echo "3. Run the validator when ready to check the skill structure\n";

    return $skill_dir;
}

function main($argv) {
    if (count($argv) < 2) {
        echo "Usage: php init_skill.php <skill-name> --path <path> [--resources scripts,references,assets] [--examples]\n";
        exit(1);
    }

    $options = getopt("", ["path:", "resources::", "examples"]);
    $skill_name = $argv[1];
    
    if (!isset($options['path'])) {
        echo "[ERROR] --path is required\n";
        exit(1);
    }

    $raw_skill_name = $skill_name;
    $skill_name = normalize_skill_name($raw_skill_name);
    if (!$skill_name) {
        echo "[ERROR] Skill name must include at least one letter or digit.\n";
        exit(1);
    }
    if (strlen($skill_name) > MAX_SKILL_NAME_LENGTH) {
        echo "[ERROR] Skill name '$skill_name' is too long (" . strlen($skill_name) . " characters). ";
        echo "Maximum is " . MAX_SKILL_NAME_LENGTH . " characters.\n";
        exit(1);
    }
    if ($skill_name !== $raw_skill_name) {
        echo "Note: Normalized skill name from '$raw_skill_name' to '$skill_name'.\n";
    }

    $resources = parse_resources($options['resources'] ?? '');
    if (isset($options['examples']) && empty($resources)) {
        echo "[ERROR] --examples requires --resources to be set.\n";
        exit(1);
    }

    $path = $options['path'];

    echo "Initializing skill: $skill_name\n";
    echo "   Location: $path\n";
    if (!empty($resources)) {
        echo "   Resources: " . implode(',', $resources) . "\n";
        if (isset($options['examples'])) {
            echo "   Examples: enabled\n";
        }
    } else {
        echo "   Resources: none (create as needed)\n";
    }
    echo "\n";

    $result = init_skill($skill_name, $path, $resources, isset($options['examples']));

    if ($result) {
        exit(0);
    } else {
        exit(1);
    }
}

main($argv);
