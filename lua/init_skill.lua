#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "f231c7b389ac7518212f187660e2a46e14d276711729a7a4ce3cdfc06056a46c", "source_sha256": "bcd6b802c400a9e89319844c6c3d965855c8b0555e982eb72cd4accb7ee67e3e", "target_language": "lua"}
-- init_skill.py — portiert nach lua
-- Quelle: python, OpenClaw@gateway1:skills/skill-creator/scripts/init_skill.py
-- auch in: OpenClaw@gateway2:skills/skill-creator/scripts/init_skill.py
-- Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

--[[
Skill Initializer - Creates a new skill from template

Usage:
    init_skill.lua <skill-name> --path <path> [--resources scripts,references,assets] [--examples]

Examples:
    init_skill.lua my-new-skill --path skills/public
    init_skill.lua my-new-skill --path skills/public --resources scripts,references
    init_skill.lua my-api-helper --path skills/private --resources scripts --examples
    init_skill.lua custom-skill --path /custom/location
]]

local argparse = require "argparse"
local lfs = require "lfs"

local MAX_SKILL_NAME_LENGTH = 64
local ALLOWED_RESOURCES = {scripts = true, references = true, assets = true}

local SKILL_TEMPLATE = [[---
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
]]

local EXAMPLE_SCRIPT = [[#!/usr/bin/env python3
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
]]

local EXAMPLE_REFERENCE = [[# Reference Documentation for {skill_title}

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
]]

local EXAMPLE_ASSET = [[# Example Asset File

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
]]


-- Normalize a skill name to lowercase hyphen-case
local function normalize_skill_name(skill_name)
    local normalized = string.gsub(skill_name, "^%s+", "")  -- trim leading whitespace
    normalized = string.gsub(normalized, "%s+$", "")         -- trim trailing whitespace
    normalized = string.lower(normalized)
    normalized = string.gsub(normalized, "[^a-z0-9]+", "-")   -- replace non-alphanumeric with -
    normalized = string.gsub(normalized, "^-+", "")          -- remove leading -
    normalized = string.gsub(normalized, "-+$", "")          -- remove trailing -
    normalized = string.gsub(normalized, "-+", "-")          -- collapse multiple -
    return normalized
end

-- Convert hyphenated skill name to Title Case for display
local function title_case_skill_name(skill_name)
    local words = {}
    for word in string.gmatch(skill_name, "[^-]+") do
        table.insert(words, string.upper(string.sub(word, 1, 1)) .. string.sub(word, 2))
    end
    return table.concat(words, " ")
end

-- Parse comma-separated resources string
local function parse_resources(raw_resources)
    if not raw_resources or raw_resources == "" then
        return {}
    end
    
    local resources = {}
    local seen = {}
    
    for resource in string.gmatch(raw_resources, "[^,%s]+") do
        local trimmed = string.gsub(resource, "^%s+", "")
        trimmed = string.gsub(trimmed, "%s+$", "")
        if trimmed ~= "" then
            if not ALLOWED_RESOURCES[trimmed] then
                print("[ERROR] Unknown resource type: " .. trimmed)
                local allowed_list = {}
                for k, _ in pairs(ALLOWED_RESOURCES) do
                    table.insert(allowed_list, k)
                end
                table.sort(allowed_list)
                print("   Allowed: " .. table.concat(allowed_list, ", "))
                os.exit(1)
            end
            
            if not seen[trimmed] then
                table.insert(resources, trimmed)
                seen[trimmed] = true
            end
        end
    end
    
    return resources
end

-- Create resource directories with optional examples
local function create_resource_dirs(skill_dir, skill_name, skill_title, resources, include_examples)
    for _, resource in ipairs(resources) do
        local resource_dir = skill_dir .. "/" .. resource
        
        -- Create directory
        local success, err = lfs.mkdir(resource_dir)
        if not success and err ~= "File exists" then
            error("Failed to create directory " .. resource_dir .. ": " .. err)
        end
        
        if resource == "scripts" then
            if include_examples then
                local example_script_path = resource_dir .. "/example.py"
                local f = io.open(example_script_path, "w")
                if f then
                    f:write(string.gsub(EXAMPLE_SCRIPT, "{skill_name}", skill_name))
                    f:close()
                    os.execute("chmod +x " .. example_script_path)
                    print("[OK] Created scripts/example.py")
                else
                    error("Failed to create " .. example_script_path)
                end
            else
                print("[OK] Created scripts/")
            end
        elseif resource == "references" then
            if include_examples then
                local example_reference_path = resource_dir .. "/api_reference.md"
                local f = io.open(example_reference_path, "w")
                if f then
                    f:write(string.gsub(EXAMPLE_REFERENCE, "{skill_title}", skill_title))
                    f:close()
                    print("[OK] Created references/api_reference.md")
                else
                    error("Failed to create " .. example_reference_path)
                end
            else
                print("[OK] Created references/")
            end
        elseif resource == "assets" then
            if include_examples then
                local example_asset_path = resource_dir .. "/example_asset.txt"
                local f = io.open(example_asset_path, "w")
                if f then
                    f:write(EXAMPLE_ASSET)
                    f:close()
                    print("[OK] Created assets/example_asset.txt")
                else
                    error("Failed to create " .. example_asset_path)
                end
            else
                print("[OK] Created assets/")
            end
        end
    end
end

-- Initialize a new skill directory with template SKILL.md
local function init_skill(skill_name, path, resources, include_examples)
    -- Determine skill directory path
    local skill_dir = path .. "/" .. skill_name
    
    -- Check if directory already exists
    local attr = lfs.attributes(skill_dir)
    if attr and attr.mode == "directory" then
        print("[ERROR] Skill directory already exists: " .. skill_dir)
        return nil
    end
    
    -- Create skill directory
    local success, err = lfs.mkdir(skill_dir)
    if not success then
        print("[ERROR] Error creating directory: " .. err)
        return nil
    end
    print("[OK] Created skill directory: " .. skill_dir)
    
    -- Create SKILL.md from template
    local skill_title = title_case_skill_name(skill_name)
    local skill_content = string.gsub(SKILL_TEMPLATE, "{skill_name}", skill_name)
    skill_content = string.gsub(skill_content, "{skill_title}", skill_title)
    
    local skill_md_path = skill_dir .. "/SKILL.md"
    local f = io.open(skill_md_path, "w")
    if not f then
        print("[ERROR] Error creating SKILL.md: failed to open file")
        return nil
    end
    f:write(skill_content)
    f:close()
    print("[OK] Created SKILL.md")
    
    -- Create resource directories if requested
    if #resources > 0 then
        local success, err = pcall(create_resource_dirs, skill_dir, skill_name, skill_title, resources, include_examples)
        if not success then
            print("[ERROR] Error creating resource directories: " .. err)
            return nil
        end
    end
    
    -- Print next steps
    print("\n[OK] Skill '" .. skill_name .. "' initialized successfully at " .. skill_dir)
    print("\nNext steps:")
    print("1. Edit SKILL.md to complete the TODO items and update the description")
    if #resources > 0 then
        if include_examples then
            print("2. Customize or delete the example files in scripts/, references/, and assets/")
        else
            print("2. Add resources to scripts/, references/, and assets/ as needed")
        end
    else
        print("2. Create resource directories only if needed (scripts/, references/, assets/)")
    end
    print("3. Run the validator when ready to check the skill structure")
    
    return skill_dir
end

-- Main function
local function main()
    local parser = argparse.ArgumentParser()
    parser:add_argument("skill_name", "Skill name (normalized to hyphen-case)")
    parser:add_argument("--path", {required=true, help="Output directory for the skill"})
    parser:add_argument("--resources", {default="", help="Comma-separated list: scripts,references,assets"})
    parser:add_argument("--examples", {action="store_true", help="Create example files inside the selected resource directories"})
    
    local args = parser:parse()
    
    local raw_skill_name = args.skill_name
    local skill_name = normalize_skill_name(raw_skill_name)
    
    if skill_name == "" then
        print("[ERROR] Skill name must include at least one letter or digit.")
        os.exit(1)
    end
    
    if #skill_name > MAX_SKILL_NAME_LENGTH then
        print("[ERROR] Skill name '" .. skill_name .. "' is too long (" .. #skill_name .. " characters). Maximum is " .. MAX_SKILL_NAME_LENGTH .. " characters.")
        os.exit(1)
    end
    
    if skill_name ~= raw_skill_name then
        print("Note: Normalized skill name from '" .. raw_skill_name .. "' to '" .. skill_name .. "'.")
    end
    
    local resources = parse_resources(args.resources)
    
    if args.examples and #resources == 0 then
        print("[ERROR] --examples requires --resources to be set.")
        os.exit(1)
    end
    
    local path = args.path
    
    print("Initializing skill: " .. skill_name)
    print("   Location: " .. path)
    if #resources > 0 then
        print("   Resources: " .. table.concat(resources, ", "))
        if args.examples then
            print("   Examples: enabled")
        end
    else
        print("   Resources: none (create as needed)")
    end
    print()
    
    local result = init_skill(skill_name, path, resources, args.examples)
    
    if result then
        os.exit(0)
    else
        os.exit(1)
    end
end

main()
