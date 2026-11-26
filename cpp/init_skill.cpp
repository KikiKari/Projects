// abstraction-provenance: {"artifact_sha256": "99e492743e0f3de5cd2cbb0b5f41fa241eae735bd9de64261f943ae230bea8c3", "source_sha256": "bcd6b802c400a9e89319844c6c3d965855c8b0555e982eb72cd4accb7ee67e3e", "target_language": "cpp"}
// init_skill.py — portiert nach cpp
// Quelle: python, OpenClaw@gateway1:skills/skill-creator/scripts/init_skill.py
// auch in: OpenClaw@gateway2:skills/skill-creator/scripts/init_skill.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <string>
#include <vector>
#include <filesystem>
#include <fstream>
#include <regex>
#include <set>
#include <algorithm>
#include <cstdlib>

namespace fs = std::filesystem;

const size_t MAX_SKILL_NAME_LENGTH = 64;
const std::set<std::string> ALLOWED_RESOURCES = {"scripts", "references", "assets"};

const std::string SKILL_TEMPLATE = R"""(---
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
)""";

const std::string EXAMPLE_SCRIPT = R"""(#!/usr/bin/env python3
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
)""";

const std::string EXAMPLE_REFERENCE = R"""(# Reference Documentation for {skill_title}

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
)""";

const std::string EXAMPLE_ASSET = R"""(# Example Asset File

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
)""";

std::string normalize_skill_name(const std::string& skill_name) {
    std::string normalized = skill_name;
    
    // Trim leading/trailing whitespace
    normalized.erase(0, normalized.find_first_not_of(" \t\n\r\f\v"));
    normalized.erase(normalized.find_last_not_of(" \t\n\r\f\v") + 1);
    
    // Convert to lowercase
    std::transform(normalized.begin(), normalized.end(), normalized.begin(), ::tolower);
    
    // Replace non-alphanumeric characters with hyphens
    std::regex non_alnum("[^a-z0-9]+");
    normalized = std::regex_replace(normalized, non_alnum, "-");
    
    // Remove leading/trailing hyphens
    if (!normalized.empty()) {
        if (normalized.front() == '-') normalized.erase(0, 1);
        if (!normalized.empty() && normalized.back() == '-') normalized.pop_back();
    }
    
    // Replace multiple consecutive hyphens with single hyphen
    std::regex multiple_hyphens("-{2,}");
    normalized = std::regex_replace(normalized, multiple_hyphens, "-");
    
    return normalized;
}

std::string title_case_skill_name(const std::string& skill_name) {
    std::istringstream iss(skill_name);
    std::string word;
    std::string result;
    bool first = true;
    
    while (std::getline(iss, word, '-')) {
        if (!first) result += " ";
        if (!word.empty()) {
            word[0] = std::toupper(word[0]);
        }
        result += word;
        first = false;
    }
    
    return result;
}

std::vector<std::string> parse_resources(const std::string& raw_resources) {
    if (raw_resources.empty()) {
        return {};
    }
    
    std::vector<std::string> resources;
    std::istringstream iss(raw_resources);
    std::string resource;
    
    while (std::getline(iss, resource, ',')) {
        // Trim whitespace
        resource.erase(0, resource.find_first_not_of(" \t\n\r\f\v"));
        resource.erase(resource.find_last_not_of(" \t\n\r\f\v") + 1);
        
        if (!resource.empty()) {
            resources.push_back(resource);
        }
    }
    
    // Check for invalid resources
    std::set<std::string> invalid;
    for (const auto& resource : resources) {
        if (ALLOWED_RESOURCES.find(resource) == ALLOWED_RESOURCES.end()) {
            invalid.insert(resource);
        }
    }
    
    if (!invalid.empty()) {
        std::cerr << "[ERROR] Unknown resource type(s): ";
        bool first = true;
        for (const auto& item : invalid) {
            if (!first) std::cerr << ", ";
            std::cerr << item;
            first = false;
        }
        std::cerr << std::endl;
        
        std::cerr << "   Allowed: ";
        std::vector<std::string> allowed_sorted(ALLOWED_RESOURCES.begin(), ALLOWED_RESOURCES.end());
        std::sort(allowed_sorted.begin(), allowed_sorted.end());
        first = true;
        for (const auto& item : allowed_sorted) {
            if (!first) std::cerr << ", ";
            std::cerr << item;
            first = false;
        }
        std::cerr << std::endl;
        
        std::exit(1);
    }
    
    // Deduplicate while preserving order
    std::vector<std::string> deduped;
    std::set<std::string> seen;
    for (const auto& resource : resources) {
        if (seen.find(resource) == seen.end()) {
            deduped.push_back(resource);
            seen.insert(resource);
        }
    }
    
    return deduped;
}

void create_resource_dirs(const fs::path& skill_dir, const std::string& skill_name, 
                         const std::string& skill_title, const std::vector<std::string>& resources, 
                         bool include_examples) {
    for (const auto& resource : resources) {
        fs::path resource_dir = skill_dir / resource;
        fs::create_directories(resource_dir);
        
        if (resource == "scripts") {
            if (include_examples) {
                fs::path example_script = resource_dir / "example.py";
                std::ofstream file(example_script);
                if (file.is_open()) {
                    std::string content = EXAMPLE_SCRIPT;
                    size_t pos = content.find("{skill_name}");
                    while (pos != std::string::npos) {
                        content.replace(pos, 12, skill_name);
                        pos = content.find("{skill_name}", pos + skill_name.length());
                    }
                    file << content;
                    file.close();
                    
                    // Make executable (chmod 755)
                    fs::permissions(example_script, fs::perms::owner_all | fs::perms::group_read | 
                                      fs::perms::group_exec | fs::perms::others_read | fs::perms::others_exec);
                    std::cout << "[OK] Created scripts/example.py" << std::endl;
                }
            } else {
                std::cout << "[OK] Created scripts/" << std::endl;
            }
        } else if (resource == "references") {
            if (include_examples) {
                fs::path example_reference = resource_dir / "api_reference.md";
                std::ofstream file(example_reference);
                if (file.is_open()) {
                    std::string content = EXAMPLE_REFERENCE;
                    size_t pos = content.find("{skill_title}");
                    while (pos != std::string::npos) {
                        content.replace(pos, 13, skill_title);
                        pos = content.find("{skill_title}", pos + skill_title.length());
                    }
                    file << content;
                    file.close();
                    std::cout << "[OK] Created references/api_reference.md" << std::endl;
                }
            } else {
                std::cout << "[OK] Created references/" << std::endl;
            }
        } else if (resource == "assets") {
            if (include_examples) {
                fs::path example_asset = resource_dir / "example_asset.txt";
                std::ofstream file(example_asset);
                if (file.is_open()) {
                    file << EXAMPLE_ASSET;
                    file.close();
                    std::cout << "[OK] Created assets/example_asset.txt" << std::endl;
                }
            } else {
                std::cout << "[OK] Created assets/" << std::endl;
            }
        }
    }
}

fs::path init_skill(const std::string& skill_name, const std::string& path, 
                   const std::vector<std::string>& resources, bool include_examples) {
    // Determine skill directory path
    fs::path skill_dir = fs::absolute(path) / skill_name;
    
    // Check if directory already exists
    if (fs::exists(skill_dir)) {
        std::cerr << "[ERROR] Skill directory already exists: " << skill_dir << std::endl;
        return "";
    }
    
    // Create skill directory
    try {
        fs::create_directories(skill_dir);
        std::cout << "[OK] Created skill directory: " << skill_dir << std::endl;
    } catch (const std::exception& e) {
        std::cerr << "[ERROR] Error creating directory: " << e.what() << std::endl;
        return "";
    }
    
    // Create SKILL.md from template
    std::string skill_title = title_case_skill_name(skill_name);
    std::string skill_content = SKILL_TEMPLATE;
    
    // Replace placeholders
    size_t pos = skill_content.find("{skill_name}");
    while (pos != std::string::npos) {
        skill_content.replace(pos, 12, skill_name);
        pos = skill_content.find("{skill_name}", pos + skill_name.length());
    }
    
    pos = skill_content.find("{skill_title}");
    while (pos != std::string::npos) {
        skill_content.replace(pos, 13, skill_title);
        pos = skill_content.find("{skill_title}", pos + skill_title.length());
    }
    
    fs::path skill_md_path = skill_dir / "SKILL.md";
    try {
        std::ofstream file(skill_md_path);
        if (file.is_open()) {
            file << skill_content;
            file.close();
            std::cout << "[OK] Created SKILL.md" << std::endl;
        } else {
            std::cerr << "[ERROR] Could not create SKILL.md" << std::endl;
            return "";
        }
    } catch (const std::exception& e) {
        std::cerr << "[ERROR] Error creating SKILL.md: " << e.what() << std::endl;
        return "";
    }
    
    // Create resource directories if requested
    if (!resources.empty()) {
        try {
            create_resource_dirs(skill_dir, skill_name, skill_title, resources, include_examples);
        } catch (const std::exception& e) {
            std::cerr << "[ERROR] Error creating resource directories: " << e.what() << std::endl;
            return "";
        }
    }
    
    // Print next steps
    std::cout << "\n[OK] Skill '" << skill_name << "' initialized successfully at " << skill_dir << std::endl;
    std::cout << "\nNext steps:" << std::endl;
    std::cout << "1. Edit SKILL.md to complete the TODO items and update the description" << std::endl;
    if (!resources.empty()) {
        if (include_examples) {
            std::cout << "2. Customize or delete the example files in scripts/, references/, and assets/" << std::endl;
        } else {
            std::cout << "2. Add resources to scripts/, references/, and assets/ as needed" << std::endl;
        }
    } else {
        std::cout << "2. Create resource directories only if needed (scripts/, references/, assets/)" << std::endl;
    }
    std::cout << "3. Run the validator when ready to check the skill structure" << std::endl;
    
    return skill_dir;
}

int main(int argc, char* argv[]) {
    if (argc < 3) {
        std::cerr << "Usage: " << argv[0] << " <skill-name> --path <path> [--resources scripts,references,assets] [--examples]" << std::endl;
        std::exit(1);
    }
    
    std::string skill_name_arg = argv[1];
    std::string path = "./";
    std::string resources_arg = "";
    bool include_examples = false;
    
    for (int i = 2; i < argc; i++) {
        std::string arg = argv[i];
        if (arg == "--path" && i + 1 < argc) {
            path = argv[++i];
        } else if (arg == "--resources" && i + 1 < argc) {
            resources_arg = argv[++i];
        } else if (arg == "--examples") {
            include_examples = true;
        }
    }
    
    std::string skill_name = normalize_skill_name(skill_name_arg);
    if (skill_name.empty()) {
        std::cerr << "[ERROR] Skill name must include at least one letter or digit." << std::endl;
        std::exit(1);
    }
    if (skill_name.length() > MAX_SKILL_NAME_LENGTH) {
        std::cerr << "[ERROR] Skill name '" << skill_name << "' is too long (" 
                  << skill_name.length() << " characters). Maximum is " 
                  << MAX_SKILL_NAME_LENGTH << " characters." << std::endl;
        std::exit(1);
    }
    if (skill_name != skill_name_arg) {
        std::cout << "Note: Normalized skill name from '" << skill_name_arg 
                  << "' to '" << skill_name << "'." << std::endl;
    }
    
    std::vector<std::string> resources = parse_resources(resources_arg);
    if (include_examples && resources.empty()) {
        std::cerr << "[ERROR] --examples requires --resources to be set." << std::endl;
        std::exit(1);
    }
    
    std::cout << "Initializing skill: " << skill_name << std::endl;
    std::cout << "   Location: " << path << std::endl;
    if (!resources.empty()) {
        std::cout << "   Resources: ";
        bool first = true;
        for (const auto& res : resources) {
            if (!first) std::cout << ", ";
            std::cout << res;
            first = false;
        }
        std::cout << std::endl;
        if (include_examples) {
            std::cout << "   Examples: enabled" << std::endl;
        }
    } else {
        std::cout << "   Resources: none (create as needed)" << std::endl;
    }
    std::cout << std::endl;
    
    fs::path result = init_skill(skill_name, path, resources, include_examples);
    
    if (!result.empty()) {
        std::exit(0);
    } else {
        std::exit(1);
    }
}
