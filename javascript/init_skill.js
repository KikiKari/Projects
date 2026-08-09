#!/usr/bin/env node
// init_skill.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway1:skills/skill-creator/scripts/init_skill.py
// auch in: OpenClaw@gateway2:skills/skill-creator/scripts/init_skill.py
// Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

/**
 * Skill Initializer - Creates a new skill from template
 *
 * Usage:
 *     init_skill.js <skill-name> --path <path> [--resources scripts,references,assets] [--examples]
 *
 * Examples:
 *     init_skill.js my-new-skill --path skills/public
 *     init_skill.js my-new-skill --path skills/public --resources scripts,references
 *     init_skill.js my-api-helper --path skills/private --resources scripts --examples
 *     init_skill.js custom-skill --path /custom/location
 */

const fs = require('fs');
const path = require('path');
const { program } = require('commander');

const MAX_SKILL_NAME_LENGTH = 64;
const ALLOWED_RESOURCES = new Set(["scripts", "references", "assets"]);

const SKILL_TEMPLATE = `---
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
- PDF skill: \`fill_fillable_fields.py\`, \`extract_form_field_info.py\` - utilities for PDF manipulation
- DOCX skill: \`document.py\`, \`utilities.py\` - Python modules for document processing

**Appropriate for:** Python scripts, shell scripts, or any executable code that performs automation, data processing, or specific operations.

**Note:** Scripts may be executed without loading into context, but can still be read by Codex for patching or environment adjustments.

### references/
Documentation and reference material intended to be loaded into context to inform Codex's process and thinking.

**Examples from other skills:**
- Product management: \`communication.md\`, \`context_building.md\` - detailed workflow guides
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
`;

const EXAMPLE_SCRIPT = `#!/usr/bin/env python3
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
`;

const EXAMPLE_REFERENCE = `# Reference Documentation for {skill_title}

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
`;

const EXAMPLE_ASSET = `# Example Asset File

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
`;


function normalizeSkillName(skillName) {
    /** Normalize a skill name to lowercase hyphen-case. */
    let normalized = skillName.trim().toLowerCase();
    normalized = normalized.replace(/[^a-z0-9]+/g, "-");
    normalized = normalized.replace(/^-+|-+$/g, "");
    normalized = normalized.replace(/-{2,}/g, "-");
    return normalized;
}

function titleCaseSkillName(skillName) {
    /** Convert hyphenated skill name to Title Case for display. */
    return skillName.split("-").map(word => word.charAt(0).toUpperCase() + word.slice(1)).join(" ");
}

function parseResources(rawResources) {
    if (!rawResources) {
        return [];
    }
    const resources = rawResources.split(",").map(item => item.trim()).filter(item => item);
    const invalid = [...new Set(resources.filter(item => !ALLOWED_RESOURCES.has(item)))].sort();
    if (invalid.length > 0) {
        const allowed = [...ALLOWED_RESOURCES].sort().join(", ");
        console.error(`[ERROR] Unknown resource type(s): ${invalid.join(", ")}`);
        console.error(`   Allowed: ${allowed}`);
        process.exit(1);
    }
    const deduped = [];
    const seen = new Set();
    for (const resource of resources) {
        if (!seen.has(resource)) {
            deduped.push(resource);
            seen.add(resource);
        }
    }
    return deduped;
}

function createResourceDirs(skillDir, skillName, skillTitle, resources, includeExamples) {
    for (const resource of resources) {
        const resourceDir = path.join(skillDir, resource);
        fs.mkdirSync(resourceDir, { recursive: true });
        if (resource === "scripts") {
            if (includeExamples) {
                const exampleScript = path.join(resourceDir, "example.py");
                fs.writeFileSync(exampleScript, EXAMPLE_SCRIPT.replace(/{skill_name}/g, skillName));
                fs.chmodSync(exampleScript, 0o755);
                console.log("[OK] Created scripts/example.py");
            } else {
                console.log("[OK] Created scripts/");
            }
        } else if (resource === "references") {
            if (includeExamples) {
                const exampleReference = path.join(resourceDir, "api_reference.md");
                fs.writeFileSync(exampleReference, EXAMPLE_REFERENCE.replace(/{skill_title}/g, skillTitle));
                console.log("[OK] Created references/api_reference.md");
            } else {
                console.log("[OK] Created references/");
            }
        } else if (resource === "assets") {
            if (includeExamples) {
                const exampleAsset = path.join(resourceDir, "example_asset.txt");
                fs.writeFileSync(exampleAsset, EXAMPLE_ASSET);
                console.log("[OK] Created assets/example_asset.txt");
            } else {
                console.log("[OK] Created assets/");
            }
        }
    }
}

function initSkill(skillName, pathArg, resources, includeExamples) {
    /**
     * Initialize a new skill directory with template SKILL.md.
     *
     * Args:
     *     skillName: Name of the skill
     *     path: Path where the skill directory should be created
     *     resources: Resource directories to create
     *     includeExamples: Whether to create example files in resource directories
     *
     * Returns:
     *     Path to created skill directory, or null if error
     */
    // Determine skill directory path
    const skillDir = path.resolve(pathArg, skillName);

    // Check if directory already exists
    if (fs.existsSync(skillDir)) {
        console.error(`[ERROR] Skill directory already exists: ${skillDir}`);
        return null;
    }

    // Create skill directory
    try {
        fs.mkdirSync(skillDir, { recursive: true });
        console.log(`[OK] Created skill directory: ${skillDir}`);
    } catch (e) {
        console.error(`[ERROR] Error creating directory: ${e.message}`);
        return null;
    }

    // Create SKILL.md from template
    const skillTitle = titleCaseSkillName(skillName);
    const skillContent = SKILL_TEMPLATE
        .replace(/{skill_name}/g, skillName)
        .replace(/{skill_title}/g, skillTitle);

    const skillMdPath = path.join(skillDir, "SKILL.md");
    try {
        fs.writeFileSync(skillMdPath, skillContent);
        console.log("[OK] Created SKILL.md");
    } catch (e) {
        console.error(`[ERROR] Error creating SKILL.md: ${e.message}`);
        return null;
    }

    // Create resource directories if requested
    if (resources.length > 0) {
        try {
            createResourceDirs(skillDir, skillName, skillTitle, resources, includeExamples);
        } catch (e) {
            console.error(`[ERROR] Error creating resource directories: ${e.message}`);
            return null;
        }
    }

    // Print next steps
    console.log(`\n[OK] Skill '${skillName}' initialized successfully at ${skillDir}`);
    console.log("\nNext steps:");
    console.log("1. Edit SKILL.md to complete the TODO items and update the description");
    if (resources.length > 0) {
        if (includeExamples) {
            console.log("2. Customize or delete the example files in scripts/, references/, and assets/");
        } else {
            console.log("2. Add resources to scripts/, references/, and assets/ as needed");
        }
    } else {
        console.log("2. Create resource directories only if needed (scripts/, references/, assets/)");
    }
    console.log("3. Run the validator when ready to check the skill structure");

    return skillDir;
}

program
    .description("Create a new skill directory with a SKILL.md template.")
    .argument("<skill-name>", "Skill name (normalized to hyphen-case)")
    .option("--path <path>", "Output directory for the skill", ".")
    .option("--resources <resources>", "Comma-separated list: scripts,references,assets", "")
    .option("--examples", "Create example files inside the selected resource directories")
    .action((skillName, options) => {
        const rawSkillName = skillName;
        const normalizedSkillName = normalizeSkillName(rawSkillName);
        if (!normalizedSkillName) {
            console.error("[ERROR] Skill name must include at least one letter or digit.");
            process.exit(1);
        }
        if (normalizedSkillName.length > MAX_SKILL_NAME_LENGTH) {
            console.error(
                `[ERROR] Skill name '${normalizedSkillName}' is too long (${normalizedSkillName.length} characters). ` +
                `Maximum is ${MAX_SKILL_NAME_LENGTH} characters.`
            );
            process.exit(1);
        }
        if (normalizedSkillName !== rawSkillName) {
            console.log(`Note: Normalized skill name from '${rawSkillName}' to '${normalizedSkillName}'.`);
        }

        const resources = parseResources(options.resources);
        if (options.examples && resources.length === 0) {
            console.error("[ERROR] --examples requires --resources to be set.");
            process.exit(1);
        }

        const pathArg = options.path;

        console.log(`Initializing skill: ${normalizedSkillName}`);
        console.log(`   Location: ${pathArg}`);
        if (resources.length > 0) {
            console.log(`   Resources: ${resources.join(", ")}`);
            if (options.examples) {
                console.log("   Examples: enabled");
            }
        } else {
            console.log("   Resources: none (create as needed)");
        }
        console.log();

        const result = initSkill(normalizedSkillName, pathArg, resources, options.examples);

        if (result) {
            process.exit(0);
        } else {
            process.exit(1);
        }
    });

program.parse();
