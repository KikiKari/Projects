// abstraction-provenance: {"artifact_sha256": "f0130b8c1dddc9b76271905d61c06a0a3696f75565b8e1498d26ff8341ad9afe", "source_sha256": "bcd6b802c400a9e89319844c6c3d965855c8b0555e982eb72cd4accb7ee67e3e", "target_language": "c"}
// init_skill.py — portiert nach c
// Quelle: python, OpenClaw@gateway1:skills/skill-creator/scripts/init_skill.py
// auch in: OpenClaw@gateway2:skills/skill-creator/scripts/init_skill.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>
#include <libgen.h>
#include <dirent.h>
#include <errno.h>

#define MAX_SKILL_NAME_LENGTH 64
#define MAX_PATH_LENGTH 1024

const char* ALLOWED_RESOURCES[] = {"scripts", "references", "assets"};
const int NUM_ALLOWED_RESOURCES = 3;

const char* SKILL_TEMPLATE = 
"---\n"
"name: %s\n"
"description: [TODO: Complete and informative explanation of what the skill does and when to use it. Include WHEN to use this skill - specific scenarios, file types, or tasks that trigger it.]\n"
"---\n"
"\n"
"# %s\n"
"\n"
"## Overview\n"
"\n"
"[TODO: 1-2 sentences explaining what this skill enables]\n"
"\n"
"## Structuring This Skill\n"
"\n"
"[TODO: Choose the structure that best fits this skill's purpose. Common patterns:\n"
"\n"
"**1. Workflow-Based** (best for sequential processes)\n"
"- Works well when there are clear step-by-step procedures\n"
"- Example: DOCX skill with \"Workflow Decision Tree\" -> \"Reading\" -> \"Creating\" -> \"Editing\"\n"
"- Structure: ## Overview -> ## Workflow Decision Tree -> ## Step 1 -> ## Step 2...\n"
"\n"
"**2. Task-Based** (best for tool collections)\n"
"- Works well when the skill offers different operations/capabilities\n"
"- Example: PDF skill with \"Quick Start\" -> \"Merge PDFs\" -> \"Split PDFs\" -> \"Extract Text\"\n"
"- Structure: ## Overview -> ## Quick Start -> ## Task Category 1 -> ## Task Category 2...\n"
"\n"
"**3. Reference/Guidelines** (best for standards or specifications)\n"
"- Works well for brand guidelines, coding standards, or requirements\n"
"- Example: Brand styling with \"Brand Guidelines\" -> \"Colors\" -> \"Typography\" -> \"Features\"\n"
"- Structure: ## Overview -> ## Guidelines -> ## Specifications -> ## Usage...\n"
"\n"
"**4. Capabilities-Based** (best for integrated systems)\n"
"- Works well when the skill provides multiple interrelated features\n"
"- Example: Product Management with \"Core Capabilities\" -> numbered capability list\n"
"- Structure: ## Overview -> ## Core Capabilities -> ### 1. Feature -> ### 2. Feature...\n"
"\n"
"Patterns can be mixed and matched as needed. Most skills combine patterns (e.g., start with task-based, add workflow for complex operations).\n"
"\n"
"Delete this entire \"Structuring This Skill\" section when done - it's just guidance.]\n"
"\n"
"## [TODO: Replace with the first main section based on chosen structure]\n"
"\n"
"[TODO: Add content here. See examples in existing skills:\n"
"- Code samples for technical skills\n"
"- Decision trees for complex workflows\n"
"- Concrete examples with realistic user requests\n"
"- References to scripts/templates/references as needed]\n"
"\n"
"## Resources (optional)\n"
"\n"
"Create only the resource directories this skill actually needs. Delete this section if no resources are required.\n"
"\n"
"### scripts/\n"
"Executable code (Python/Bash/etc.) that can be run directly to perform specific operations.\n"
"\n"
"**Examples from other skills:**\n"
"- PDF skill: `fill_fillable_fields.py`, `extract_form_field_info.py` - utilities for PDF manipulation\n"
"- DOCX skill: `document.py`, `utilities.py` - Python modules for document processing\n"
"\n"
"**Appropriate for:** Python scripts, shell scripts, or any executable code that performs automation, data processing, or specific operations.\n"
"\n"
"**Note:** Scripts may be executed without loading into context, but can still be read by Codex for patching or environment adjustments.\n"
"\n"
"### references/\n"
"Documentation and reference material intended to be loaded into context to inform Codex's process and thinking.\n"
"\n"
"**Examples from other skills:**\n"
"- Product management: `communication.md`, `context_building.md` - detailed workflow guides\n"
"- BigQuery: API reference documentation and query examples\n"
"- Finance: Schema documentation, company policies\n"
"\n"
"**Appropriate for:** In-depth documentation, API references, database schemas, comprehensive guides, or any detailed information that Codex should reference while working.\n"
"\n"
"### assets/\n"
"Files not intended to be loaded into context, but rather used within the output Codex produces.\n"
"\n"
"**Examples from other skills:**\n"
"- Brand styling: PowerPoint template files (.pptx), logo files\n"
"- Frontend builder: HTML/React boilerplate project directories\n"
"- Typography: Font files (.ttf, .woff2)\n"
"\n"
"**Appropriate for:** Templates, boilerplate code, document templates, images, icons, fonts, or any files meant to be copied or used in the final output.\n"
"\n"
"---\n"
"\n"
"**Not every skill requires all three types of resources.**\n";

const char* EXAMPLE_SCRIPT = 
"#!/usr/bin/env python3\n"
"\"\"\"\n"
"Example helper script for %s\n"
"\n"
"This is a placeholder script that can be executed directly.\n"
"Replace with actual implementation or delete if not needed.\n"
"\n"
"Example real scripts from other skills:\n"
"- pdf/scripts/fill_fillable_fields.py - Fills PDF form fields\n"
"- pdf/scripts/convert_pdf_to_images.py - Converts PDF pages to images\n"
"\"\"\"\n"
"\n"
"def main():\n"
"    print(\"This is an example script for %s\")\n"
"    # TODO: Add actual script logic here\n"
"    # This could be data processing, file conversion, API calls, etc.\n"
"\n"
"if __name__ == \"__main__\":\n"
"    main()\n";

const char* EXAMPLE_REFERENCE = 
"# Reference Documentation for %s\n"
"\n"
"This is a placeholder for detailed reference documentation.\n"
"Replace with actual reference content or delete if not needed.\n"
"\n"
"Example real reference docs from other skills:\n"
"- product-management/references/communication.md - Comprehensive guide for status updates\n"
"- product-management/references/context_building.md - Deep-dive on gathering context\n"
"- bigquery/references/ - API references and query examples\n"
"\n"
"## When Reference Docs Are Useful\n"
"\n"
"Reference docs are ideal for:\n"
"- Comprehensive API documentation\n"
"- Detailed workflow guides\n"
"- Complex multi-step processes\n"
"- Information too lengthy for main SKILL.md\n"
"- Content that's only needed for specific use cases\n"
"\n"
"## Structure Suggestions\n"
"\n"
"### API Reference Example\n"
"- Overview\n"
"- Authentication\n"
"- Endpoints with examples\n"
"- Error codes\n"
"- Rate limits\n"
"\n"
"### Workflow Guide Example\n"
"- Prerequisites\n"
"- Step-by-step instructions\n"
"- Common patterns\n"
"- Troubleshooting\n"
"- Best practices\n";

const char* EXAMPLE_ASSET = 
"# Example Asset File\n"
"\n"
"This placeholder represents where asset files would be stored.\n"
"Replace with actual asset files (templates, images, fonts, etc.) or delete if not needed.\n"
"\n"
"Asset files are NOT intended to be loaded into context, but rather used within\n"
"the output Codex produces.\n"
"\n"
"Example asset files from other skills:\n"
"- Brand guidelines: logo.png, slides_template.pptx\n"
"- Frontend builder: hello-world/ directory with HTML/React boilerplate\n"
"- Typography: custom-font.ttf, font-family.woff2\n"
"- Data: sample_data.csv, test_dataset.json\n"
"\n"
"## Common Asset Types\n"
"\n"
"- Templates: .pptx, .docx, boilerplate directories\n"
"- Images: .png, .jpg, .svg, .gif\n"
"- Fonts: .ttf, .otf, .woff, .woff2\n"
"- Boilerplate code: Project directories, starter files\n"
"- Icons: .ico, .svg\n"
"- Data files: .csv, .json, .xml, .yaml\n"
"\n"
"Note: This is a text placeholder. Actual assets can be any file type.\n";

// Function prototypes
char* normalize_skill_name(const char* skill_name);
char* title_case_skill_name(const char* skill_name);
int is_valid_resource(const char* resource);
void parse_resources(const char* raw_resources, char resources[][MAX_PATH_LENGTH], int* num_resources);
int create_resource_dirs(const char* skill_dir, const char* skill_name, const char* skill_title, char resources[][MAX_PATH_LENGTH], int num_resources, int include_examples);
int init_skill(const char* skill_name, const char* path, char resources[][MAX_PATH_LENGTH], int num_resources, int include_examples);
void print_usage(const char* program_name);

// Helper function to check if directory exists
int dir_exists(const char* path) {
    struct stat info;
    return (stat(path, &info) == 0 && S_ISDIR(info.st_mode));
}

// Helper function to create directory recursively
int mkdir_recursive(const char* path) {
    char tmp[MAX_PATH_LENGTH];
    char *p = NULL;
    size_t len;
    
    snprintf(tmp, sizeof(tmp), "%s", path);
    len = strlen(tmp);
    if (tmp[len - 1] == '/')
        tmp[len - 1] = 0;
    for (p = tmp + 1; *p; p++) {
        if (*p == '/') {
            *p = 0;
            if (mkdir(tmp, S_IRWXU) != 0 && errno != EEXIST) {
                return -1;
            }
            *p = '/';
        }
    }
    if (mkdir(tmp, S_IRWXU) != 0 && errno != EEXIST) {
        return -1;
    }
    return 0;
}

// Normalize skill name to lowercase hyphen-case
char* normalize_skill_name(const char* skill_name) {
    static char normalized[MAX_SKILL_NAME_LENGTH * 2];
    int i, j = 0;
    int prev_dash = 0;
    
    // Convert to lowercase and replace non-alphanumeric with dash
    for (i = 0; skill_name[i] != '\0' && j < MAX_SKILL_NAME_LENGTH * 2 - 2; i++) {
        char c = skill_name[i];
        if ((c >= 'a' && c <= 'z') || (c >= '0' && c <= '9')) {
            normalized[j++] = c;
            prev_dash = 0;
        } else if (c >= 'A' && c <= 'Z') {
            normalized[j++] = c + ('a' - 'A');
            prev_dash = 0;
        } else if (!prev_dash && j > 0) {
            normalized[j++] = '-';
            prev_dash = 1;
        }
    }
    normalized[j] = '\0';
    
    // Remove leading/trailing dashes
    while (j > 0 && normalized[j-1] == '-') {
        normalized[--j] = '\0';
    }
    
    i = 0;
    while (normalized[i] == '-' && normalized[i] != '\0') {
        i++;
    }
    
    if (i > 0) {
        memmove(normalized, normalized + i, j - i + 1);
    }
    
    return normalized;
}

// Convert hyphenated skill name to Title Case
char* title_case_skill_name(const char* skill_name) {
    static char title[MAX_SKILL_NAME_LENGTH * 2];
    int i, j = 0;
    int capitalize = 1;
    
    for (i = 0; skill_name[i] != '\0' && j < MAX_SKILL_NAME_LENGTH * 2 - 1; i++) {
        if (skill_name[i] == '-') {
            title[j++] = ' ';
            capitalize = 1;
        } else if (capitalize) {
            title[j++] = (skill_name[i] >= 'a' && skill_name[i] <= 'z') ? 
                         skill_name[i] - ('a' - 'A') : skill_name[i];
            capitalize = 0;
        } else {
            title[j++] = skill_name[i];
        }
    }
    title[j] = '\0';
    return title;
}

// Check if resource is valid
int is_valid_resource(const char* resource) {
    int i;
    for (i = 0; i < NUM_ALLOWED_RESOURCES; i++) {
        if (strcmp(resource, ALLOWED_RESOURCES[i]) == 0) {
            return 1;
        }
    }
    return 0;
}

// Parse comma-separated resources
void parse_resources(const char* raw_resources, char resources[][MAX_PATH_LENGTH], int* num_resources) {
    *num_resources = 0;
    if (!raw_resources || strlen(raw_resources) == 0) {
        return;
    }
    
    char* temp = strdup(raw_resources);
    char* token = strtok(temp, ",");
    int seen[NUM_ALLOWED_RESOURCES];
    int i;
    
    for (i = 0; i < NUM_ALLOWED_RESOURCES; i++) {
        seen[i] = 0;
    }
    
    while (token) {
        // Trim whitespace
        while (*token == ' ') token++;
        char* end = token + strlen(token) - 1;
        while (end > token && *end == ' ') end--;
        *(end + 1) = '\0';
        
        if (strlen(token) > 0) {
            if (!is_valid_resource(token)) {
                fprintf(stderr, "[ERROR] Unknown resource type(s): %s\n", token);
                fprintf(stderr, "   Allowed: scripts, references, assets\n");
                free(temp);
                exit(1);
            }
            
            // Check for duplicates
            int found = 0;
            for (i = 0; i < *num_resources; i++) {
                if (strcmp(resources[i], token) == 0) {
                    found = 1;
                    break;
                }
            }
            
            if (!found) {
                strncpy(resources[*num_resources], token, MAX_PATH_LENGTH - 1);
                resources[*num_resources][MAX_PATH_LENGTH - 1] = '\0';
                (*num_resources)++;
            }
        }
        token = strtok(NULL, ",");
    }
    
    free(temp);
}

// Create resource directories
int create_resource_dirs(const char* skill_dir, const char* skill_name, const char* skill_title, char resources[][MAX_PATH_LENGTH], int num_resources, int include_examples) {
    int i;
    char full_path[MAX_PATH_LENGTH];
    
    for (i = 0; i < num_resources; i++) {
        snprintf(full_path, sizeof(full_path), "%s/%s", skill_dir, resources[i]);
        
        if (mkdir(full_path, S_IRWXU) != 0 && errno != EEXIST) {
            fprintf(stderr, "[ERROR] Failed to create directory %s: %s\n", full_path, strerror(errno));
            return -1;
        }
        
        printf("[OK] Created %s/\n", resources[i]);
        
        if (include_examples) {
            char file_path[MAX_PATH_LENGTH];
            FILE* file;
            
            if (strcmp(resources[i], "scripts") == 0) {
                snprintf(file_path, sizeof(file_path), "%s/example.py", full_path);
                file = fopen(file_path, "w");
                if (file) {
                    fprintf(file, EXAMPLE_SCRIPT, skill_name, skill_name);
                    fclose(file);
                    chmod(file_path, 0755);
                    printf("[OK] Created scripts/example.py\n");
                } else {
                    fprintf(stderr, "[ERROR] Failed to create %s: %s\n", file_path, strerror(errno));
                    return -1;
                }
            } else if (strcmp(resources[i], "references") == 0) {
                snprintf(file_path, sizeof(file_path), "%s/api_reference.md", full_path);
                file = fopen(file_path, "w");
                if (file) {
                    fprintf(file, EXAMPLE_REFERENCE, skill_title);
                    fclose(file);
                    printf("[OK] Created references/api_reference.md\n");
                } else {
                    fprintf(stderr, "[ERROR] Failed to create %s: %s\n", file_path, strerror(errno));
                    return -1;
                }
            } else if (strcmp(resources[i], "assets") == 0) {
                snprintf(file_path, sizeof(file_path), "%s/example_asset.txt", full_path);
                file = fopen(file_path, "w");
                if (file) {
                    fputs(EXAMPLE_ASSET, file);
                    fclose(file);
                    printf("[OK] Created assets/example_asset.txt\n");
                } else {
                    fprintf(stderr, "[ERROR] Failed to create %s: %s\n", file_path, strerror(errno));
                    return -1;
                }
            }
        }
    }
    
    return 0;
}

// Initialize skill
int init_skill(const char* skill_name, const char* path, char resources[][MAX_PATH_LENGTH], int num_resources, int include_examples) {
    char skill_dir[MAX_PATH_LENGTH];
    char full_path[MAX_PATH_LENGTH];
    
    // Determine skill directory path
    snprintf(skill_dir, sizeof(skill_dir), "%s/%s", path, skill_name);
    
    // Check if directory already exists
    if (dir_exists(skill_dir)) {
        fprintf(stderr, "[ERROR] Skill directory already exists: %s\n", skill_dir);
        return -1;
    }
    
    // Create skill directory
    if (mkdir_recursive(skill_dir) != 0) {
        fprintf(stderr, "[ERROR] Error creating directory: %s\n", strerror(errno));
        return -1;
    }
    printf("[OK] Created skill directory: %s\n", skill_dir);
    
    // Create SKILL.md from template
    char* skill_title = title_case_skill_name(skill_name);
    char skill_content[MAX_PATH_LENGTH * 4];
    snprintf(skill_content, sizeof(skill_content), SKILL_TEMPLATE, skill_name, skill_title);
    
    snprintf(full_path, sizeof(full_path), "%s/SKILL.md", skill_dir);
    FILE* skill_file = fopen(full_path, "w");
    if (!skill_file) {
        fprintf(stderr, "[ERROR] Error creating SKILL.md: %s\n", strerror(errno));
        return -1;
    }
    fputs(skill_content, skill_file);
    fclose(skill_file);
    printf("[OK] Created SKILL.md\n");
    
    // Create resource directories if requested
    if (num_resources > 0) {
        if (create_resource_dirs(skill_dir, skill_name, skill_title, resources, num_resources, include_examples) != 0) {
            fprintf(stderr, "[ERROR] Error creating resource directories\n");
            return -1;
        }
    }
    
    // Print next steps
    printf("\n[OK] Skill '%s' initialized successfully at %s\n", skill_name, skill_dir);
    printf("\nNext steps:\n");
    printf("1. Edit SKILL.md to complete the TODO items and update the description\n");
    if (num_resources > 0) {
        if (include_examples) {
            printf("2. Customize or delete the example files in scripts/, references/, and assets/\n");
        } else {
            printf("2. Add resources to scripts/, references/, and assets/ as needed\n");
        }
    } else {
        printf("2. Create resource directories only if needed (scripts/, references/, assets/)\n");
    }
    printf("3. Run the validator when ready to check the skill structure\n");
    
    return 0;
}

// Print usage information
void print_usage(const char* program_name) {
    printf("Usage:\n");
    printf("    %s <skill-name> --path <path> [--resources scripts,references,assets] [--examples]\n", program_name);
    printf("\n");
    printf("Examples:\n");
    printf("    %s my-new-skill --path skills/public\n", program_name);
    printf("    %s my-new-skill --path skills/public --resources scripts,references\n", program_name);
    printf("    %s my-api-helper --path skills/private --resources scripts --examples\n", program_name);
    printf("    %s custom-skill --path /custom/location\n", program_name);
}

int main(int argc, char* argv[]) {
    if (argc < 2) {
        print_usage(argv[0]);
        return 1;
    }
    
    char* skill_name_arg = NULL;
    char* path = NULL;
    char* resources_arg = NULL;
    int include_examples = 0;
    
    // Parse command line arguments
    int i;
    for (i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--path") == 0) {
            if (i + 1 < argc) {
                path = argv[++i];
            } else {
                fprintf(stderr, "[ERROR] --path requires a value\n");
                return 1;
            }
        } else if (strcmp(argv[i], "--resources") == 0) {
            if (i + 1 < argc) {
                resources_arg = argv[++i];
            } else {
                fprintf(stderr, "[ERROR] --resources requires a value\n");
                return 1;
            }
        } else if (strcmp(argv[i], "--examples") == 0) {
            include_examples = 1;
        } else if (argv[i][0] != '-') {
            if (!skill_name_arg) {
                skill_name_arg = argv[i];
            } else {
                fprintf(stderr, "[ERROR] Unexpected argument: %s\n", argv[i]);
                return 1;
            }
        } else {
            fprintf(stderr, "[ERROR] Unknown option: %s\n", argv[i]);
            return 1;
        }
    }
    
    if (!skill_name_arg) {
        fprintf(stderr, "[ERROR] Missing skill name\n");
        return 1;
    }
    
    if (!path) {
        fprintf(stderr, "[ERROR] --path is required\n");
        return 1;
    }
    
    char* raw_skill_name = skill_name_arg;
    char* skill_name = normalize_skill_name(raw_skill_name);
    
    if (strlen(skill_name) == 0) {
        fprintf(stderr, "[ERROR] Skill name must include at least one letter or digit.\n");
        return 1;
    }
    
    if (strlen(skill_name) > MAX_SKILL_NAME_LENGTH) {
        fprintf(stderr, "[ERROR] Skill name '%s' is too long (%zu characters). Maximum is %d characters.\n", 
                skill_name, strlen(skill_name), MAX_SKILL_NAME_LENGTH);
        return 1;
    }
    
    if (strcmp(skill_name, raw_skill_name) != 0) {
        printf("Note: Normalized skill name from '%s' to '%s'.\n", raw_skill_name, skill_name);
    }
    
    char resources[3][MAX_PATH_LENGTH];
    int num_resources = 0;
    parse_resources(resources_arg, resources, &num_resources);
    
    if (include_examples && num_resources == 0) {
        fprintf(stderr, "[ERROR] --examples requires --resources to be set.\n");
        return 1;
    }
    
    printf("Initializing skill: %s\n", skill_name);
    printf("   Location: %s\n", path);
    if (num_resources > 0) {
        printf("   Resources: ");
        for (i = 0; i < num_resources; i++) {
            if (i > 0) printf(", ");
            printf("%s", resources[i]);
        }
        printf("\n");
        if (include_examples) {
            printf("   Examples: enabled\n");
        }
    } else {
        printf("   Resources: none (create as needed)\n");
    }
    printf("\n");
    
    int result = init_skill(skill_name, path, resources, num_resources, include_examples);
    
    return result == 0 ? 0 : 1;
}
