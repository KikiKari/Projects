// abstraction-provenance: {"artifact_sha256": "5582206822be0479619e4fed301cef039827301a316d66839203498e7a89856d", "source_sha256": "bcd6b802c400a9e89319844c6c3d965855c8b0555e982eb72cd4accb7ee67e3e", "target_language": "java"}
// init_skill.py — portiert nach java
// Quelle: python, OpenClaw@gateway1:skills/skill-creator/scripts/init_skill.py
// auch in: OpenClaw@gateway2:skills/skill-creator/scripts/init_skill.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import java.io.*;
import java.nio.file.*;
import java.util.*;
import java.util.regex.Pattern;

public class InitSkill {
    private static final int MAX_SKILL_NAME_LENGTH = 64;
    private static final Set<String> ALLOWED_RESOURCES = new HashSet<>(Arrays.asList("scripts", "references", "assets"));

    private static final String SKILL_TEMPLATE = """
---
name: %s
description: [TODO: Complete and informative explanation of what the skill does and when to use it. Include WHEN to use this skill - specific scenarios, file types, or tasks that trigger it.]
---

# %s

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
""";

    private static final String EXAMPLE_SCRIPT = """
#!/usr/bin/env python3
\"\"\"
Example helper script for %s

This is a placeholder script that can be executed directly.
Replace with actual implementation or delete if not needed.

Example real scripts from other skills:
- pdf/scripts/fill_fillable_fields.py - Fills PDF form fields
- pdf/scripts/convert_pdf_to_images.py - Converts PDF pages to images
\"\"\"

def main():
    print("This is an example script for %s")
    # TODO: Add actual script logic here
    # This could be data processing, file conversion, API calls, etc.

if __name__ == "__main__":
    main()
""";

    private static final String EXAMPLE_REFERENCE = """
# Reference Documentation for %s

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
""";

    private static final String EXAMPLE_ASSET = """
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
""";

    public static void main(String[] args) {
        if (args.length < 2) {
            System.err.println("Usage: java InitSkill <skill-name> --path <path> [--resources scripts,references,assets] [--examples]");
            System.exit(1);
        }

        String skillNameArg = args[0];
        String path = null;
        String resourcesStr = "";
        boolean includeExamples = false;

        for (int i = 1; i < args.length; i++) {
            switch (args[i]) {
                case "--path":
                    if (i + 1 < args.length) {
                        path = args[++i];
                    } else {
                        System.err.println("[ERROR] --path requires a value");
                        System.exit(1);
                    }
                    break;
                case "--resources":
                    if (i + 1 < args.length) {
                        resourcesStr = args[++i];
                    } else {
                        System.err.println("[ERROR] --resources requires a value");
                        System.exit(1);
                    }
                    break;
                case "--examples":
                    includeExamples = true;
                    break;
                default:
                    if (!args[i].startsWith("--")) {
                        // Ignore positional arguments after the first one
                    } else {
                        System.err.println("[ERROR] Unknown argument: " + args[i]);
                        System.exit(1);
                    }
            }
        }

        if (path == null) {
            System.err.println("[ERROR] --path is required");
            System.exit(1);
        }

        String skillName = normalizeSkillName(skillNameArg);
        if (skillName.isEmpty()) {
            System.err.println("[ERROR] Skill name must include at least one letter or digit.");
            System.exit(1);
        }
        if (skillName.length() > MAX_SKILL_NAME_LENGTH) {
            System.err.printf("[ERROR] Skill name '%s' is too long (%d characters). Maximum is %d characters.%n",
                    skillName, skillName.length(), MAX_SKILL_NAME_LENGTH);
            System.exit(1);
        }
        if (!skillName.equals(skillNameArg)) {
            System.out.printf("Note: Normalized skill name from '%s' to '%s'.%n", skillNameArg, skillName);
        }

        List<String> resources = parseResources(resourcesStr);
        if (includeExamples && resources.isEmpty()) {
            System.err.println("[ERROR] --examples requires --resources to be set.");
            System.exit(1);
        }

        System.out.println("Initializing skill: " + skillName);
        System.out.println("   Location: " + path);
        if (!resources.isEmpty()) {
            System.out.println("   Resources: " + String.join(",", resources));
            if (includeExamples) {
                System.out.println("   Examples: enabled");
            }
        } else {
            System.out.println("   Resources: none (create as needed)");
        }
        System.out.println();

        Path result = initSkill(skillName, path, resources, includeExamples);

        if (result != null) {
            System.exit(0);
        } else {
            System.exit(1);
        }
    }

    private static String normalizeSkillName(String skillName) {
        String normalized = skillName.trim().toLowerCase();
        normalized = normalized.replaceAll("[^a-z0-9]+", "-");
        normalized = normalized.replaceAll("^-+|-+$", "");
        normalized = normalized.replaceAll("-{2,}", "-");
        return normalized;
    }

    private static String titleCaseSkillName(String skillName) {
        String[] words = skillName.split("-");
        StringBuilder result = new StringBuilder();
        for (String word : words) {
            if (!word.isEmpty()) {
                result.append(Character.toUpperCase(word.charAt(0)))
                      .append(word.substring(1))
                      .append(" ");
            }
        }
        return result.toString().trim();
    }

    private static List<String> parseResources(String rawResources) {
        if (rawResources == null || rawResources.isEmpty()) {
            return new ArrayList<>();
        }
        
        String[] parts = rawResources.split(",");
        List<String> resources = new ArrayList<>();
        Set<String> seen = new HashSet<>();
        List<String> invalid = new ArrayList<>();
        
        for (String part : parts) {
            String resource = part.trim();
            if (!resource.isEmpty()) {
                if (!ALLOWED_RESOURCES.contains(resource)) {
                    invalid.add(resource);
                } else if (!seen.contains(resource)) {
                    resources.add(resource);
                    seen.add(resource);
                }
            }
        }
        
        if (!invalid.isEmpty()) {
            Collections.sort(invalid);
            System.err.println("[ERROR] Unknown resource type(s): " + String.join(", ", invalid));
            System.err.println("   Allowed: " + String.join(",", new ArrayList<>(ALLOWED_RESOURCES)));
            System.exit(1);
        }
        
        return resources;
    }

    private static void createResourceDirs(Path skillDir, String skillName, String skillTitle, 
                                          List<String> resources, boolean includeExamples) throws IOException {
        for (String resource : resources) {
            Path resourceDir = skillDir.resolve(resource);
            Files.createDirectories(resourceDir);
            
            switch (resource) {
                case "scripts":
                    if (includeExamples) {
                        Path exampleScript = resourceDir.resolve("example.py");
                        String scriptContent = String.format(EXAMPLE_SCRIPT, skillName, skillName);
                        Files.write(exampleScript, scriptContent.getBytes());
                        exampleScript.toFile().setExecutable(true);
                        System.out.println("[OK] Created scripts/example.py");
                    } else {
                        System.out.println("[OK] Created scripts/");
                    }
                    break;
                    
                case "references":
                    if (includeExamples) {
                        Path exampleReference = resourceDir.resolve("api_reference.md");
                        String refContent = String.format(EXAMPLE_REFERENCE, skillTitle);
                        Files.write(exampleReference, refContent.getBytes());
                        System.out.println("[OK] Created references/api_reference.md");
                    } else {
                        System.out.println("[OK] Created references/");
                    }
                    break;
                    
                case "assets":
                    if (includeExamples) {
                        Path exampleAsset = resourceDir.resolve("example_asset.txt");
                        Files.write(exampleAsset, EXAMPLE_ASSET.getBytes());
                        System.out.println("[OK] Created assets/example_asset.txt");
                    } else {
                        System.out.println("[OK] Created assets/");
                    }
                    break;
            }
        }
    }

    private static Path initSkill(String skillName, String path, List<String> resources, boolean includeExamples) {
        Path skillDir = Paths.get(path).toAbsolutePath().resolve(skillName);
        
        if (Files.exists(skillDir)) {
            System.err.println("[ERROR] Skill directory already exists: " + skillDir);
            return null;
        }
        
        try {
            Files.createDirectories(skillDir);
            System.out.println("[OK] Created skill directory: " + skillDir);
        } catch (IOException e) {
            System.err.println("[ERROR] Error creating directory: " + e.getMessage());
            return null;
        }
        
        String skillTitle = titleCaseSkillName(skillName);
        String skillContent = String.format(SKILL_TEMPLATE, skillName, skillTitle);
        
        Path skillMdPath = skillDir.resolve("SKILL.md");
        try {
            Files.write(skillMdPath, skillContent.getBytes());
            System.out.println("[OK] Created SKILL.md");
        } catch (IOException e) {
            System.err.println("[ERROR] Error creating SKILL.md: " + e.getMessage());
            return null;
        }
        
        if (!resources.isEmpty()) {
            try {
                createResourceDirs(skillDir, skillName, skillTitle, resources, includeExamples);
            } catch (IOException e) {
                System.err.println("[ERROR] Error creating resource directories: " + e.getMessage());
                return null;
            }
        }
        
        System.out.println("\n[OK] Skill '" + skillName + "' initialized successfully at " + skillDir);
        System.out.println("\nNext steps:");
        System.out.println("1. Edit SKILL.md to complete the TODO items and update the description");
        if (!resources.isEmpty()) {
            if (includeExamples) {
                System.out.println("2. Customize or delete the example files in scripts/, references/, and assets/");
            } else {
                System.out.println("2. Add resources to scripts/, references/, and assets/ as needed");
            }
        } else {
            System.out.println("2. Create resource directories only if needed (scripts/, references/, assets/)");
        }
        System.out.println("3. Run the validator when ready to check the skill structure");
        
        return skillDir;
    }
}
