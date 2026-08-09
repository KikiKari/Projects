#!/usr/bin/env pwsh
# init_skill.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway1:skills/skill-creator/scripts/init_skill.py
# auch in: OpenClaw@gateway2:skills/skill-creator/scripts/init_skill.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
Skill Initializer - Creates a new skill from template

.DESCRIPTION
Creates a new skill directory with a SKILL.md template and optional resource directories.

.PARAMETER SkillName
Name of the skill (will be normalized to hyphen-case)

.PARAMETER Path
Output directory for the skill

.PARAMETER Resources
Comma-separated list of resource directories to create (scripts,references,assets)

.PARAMETER Examples
Create example files inside the selected resource directories

.EXAMPLE
init_skill.ps1 my-new-skill --path skills/public
init_skill.ps1 my-new-skill --path skills/public --resources scripts,references
init_skill.ps1 my-api-helper --path skills/private --resources scripts --examples
init_skill.ps1 custom-skill --path /custom/location
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$SkillName,
    
    [Parameter(Mandatory=$true)]
    [string]$Path,
    
    [string]$Resources = "",
    
    [switch]$Examples
)

# Constants
$MAX_SKILL_NAME_LENGTH = 64
$ALLOWED_RESOURCES = @("scripts", "references", "assets")

$SKILL_TEMPLATE = @'
---
name: {0}
description: [TODO: Complete and informative explanation of what the skill does and when to use it. Include WHEN to use this skill - specific scenarios, file types, or tasks that trigger it.]
---

# {1}

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
'@

$EXAMPLE_SCRIPT = @'
#!/usr/bin/env python3
"""
Example helper script for {0}

This is a placeholder script that can be executed directly.
Replace with actual implementation or delete if not needed.

Example real scripts from other skills:
- pdf/scripts/fill_fillable_fields.py - Fills PDF form fields
- pdf/scripts/convert_pdf_to_images.py - Converts PDF pages to images
"""

def main():
    print("This is an example script for {0}")
    # TODO: Add actual script logic here
    # This could be data processing, file conversion, API calls, etc.

if __name__ == "__main__":
    main()
'@

$EXAMPLE_REFERENCE = @'
# Reference Documentation for {0}

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
'@

$EXAMPLE_ASSET = @'
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
'@

function Normalize-SkillName {
    param([string]$SkillName)
    
    # Normalize a skill name to lowercase hyphen-case
    $normalized = $SkillName.Trim().ToLower()
    $normalized = $normalized -replace "[^a-z0-9]+", "-"
    $normalized = $normalized.Trim("-")
    $normalized = $normalized -replace "-{2,}", "-"
    return $normalized
}

function Convert-ToTitleCase {
    param([string]$SkillName)
    
    # Convert hyphenated skill name to Title Case for display
    return ($SkillName.Split("-") | ForEach-Object { $_.Substring(0,1).ToUpper() + $_.Substring(1) }) -join " "
}

function Parse-Resources {
    param([string]$RawResources)
    
    if ([string]::IsNullOrWhiteSpace($RawResources)) {
        return @()
    }
    
    $resources = $RawResources.Split(",").Trim() | Where-Object { $_ }
    $invalid = $resources | Where-Object { $ALLOWED_RESOURCES -notcontains $_ } | Sort-Object -Unique
    
    if ($invalid.Count -gt 0) {
        $allowed = ($ALLOWED_RESOURCES | Sort-Object) -join ", "
        Write-Error "Unknown resource type(s): $($invalid -join ", ")"
        Write-Error "   Allowed: $allowed"
        exit 1
    }
    
    # Deduplicate while preserving order
    $deduped = @()
    $seen = @{}
    foreach ($resource in $resources) {
        if (-not $seen.ContainsKey($resource)) {
            $deduped += $resource
            $seen[$resource] = $true
        }
    }
    
    return $deduped
}

function Create-ResourceDirs {
    param(
        [string]$SkillDir,
        [string]$SkillName,
        [string]$SkillTitle,
        [array]$Resources,
        [bool]$IncludeExamples
    )
    
    foreach ($resource in $Resources) {
        $resourceDir = Join-Path $SkillDir $resource
        if (-not (Test-Path $resourceDir)) {
            New-Item -ItemType Directory -Path $resourceDir | Out-Null
        }
        
        if ($resource -eq "scripts") {
            if ($IncludeExamples) {
                $exampleScript = Join-Path $resourceDir "example.py"
                $content = $EXAMPLE_SCRIPT -f $SkillName
                Set-Content -Path $exampleScript -Value $content -Encoding UTF8
                # Make executable on Unix-like systems
                if ($env:OS -ne "Windows_NT") {
                    chmod +x $exampleScript
                }
                Write-Host "[OK] Created scripts/example.py"
            } else {
                Write-Host "[OK] Created scripts/"
            }
        } elseif ($resource -eq "references") {
            if ($IncludeExamples) {
                $exampleReference = Join-Path $resourceDir "api_reference.md"
                $content = $EXAMPLE_REFERENCE -f $SkillTitle
                Set-Content -Path $exampleReference -Value $content -Encoding UTF8
                Write-Host "[OK] Created references/api_reference.md"
            } else {
                Write-Host "[OK] Created references/"
            }
        } elseif ($resource -eq "assets") {
            if ($IncludeExamples) {
                $exampleAsset = Join-Path $resourceDir "example_asset.txt"
                Set-Content -Path $exampleAsset -Value $EXAMPLE_ASSET -Encoding UTF8
                Write-Host "[OK] Created assets/example_asset.txt"
            } else {
                Write-Host "[OK] Created assets/"
            }
        }
    }
}

function Initialize-Skill {
    param(
        [string]$SkillName,
        [string]$Path,
        [array]$Resources,
        [bool]$IncludeExamples
    )
    
    # Determine skill directory path
    $skillDir = Join-Path (Resolve-Path $Path) $SkillName
    
    # Check if directory already exists
    if (Test-Path $skillDir) {
        Write-Error "Skill directory already exists: $skillDir"
        return $null
    }
    
    # Create skill directory
    try {
        New-Item -ItemType Directory -Path $skillDir -Force | Out-Null
        Write-Host "[OK] Created skill directory: $skillDir"
    } catch {
        Write-Error "Error creating directory: $_"
        return $null
    }
    
    # Create SKILL.md from template
    $skillTitle = Convert-ToTitleCase $SkillName
    $skillContent = $SKILL_TEMPLATE -f $SkillName, $skillTitle
    
    $skillMdPath = Join-Path $skillDir "SKILL.md"
    try {
        Set-Content -Path $skillMdPath -Value $skillContent -Encoding UTF8
        Write-Host "[OK] Created SKILL.md"
    } catch {
        Write-Error "Error creating SKILL.md: $_"
        return $null
    }
    
    # Create resource directories if requested
    if ($Resources.Count -gt 0) {
        try {
            Create-ResourceDirs -SkillDir $skillDir -SkillName $SkillName -SkillTitle $skillTitle -Resources $Resources -IncludeExamples $IncludeExamples
        } catch {
            Write-Error "Error creating resource directories: $_"
            return $null
        }
    }
    
    # Print next steps
    Write-Host ""
    Write-Host "[OK] Skill '$SkillName' initialized successfully at $skillDir"
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "1. Edit SKILL.md to complete the TODO items and update the description"
    if ($Resources.Count -gt 0) {
        if ($IncludeExamples) {
            Write-Host "2. Customize or delete the example files in scripts/, references/, and assets/"
        } else {
            Write-Host "2. Add resources to scripts/, references/, and assets/ as needed"
        }
    } else {
        Write-Host "2. Create resource directories only if needed (scripts/, references/, assets/)"
    }
    Write-Host "3. Run the validator when ready to check the skill structure"
    
    return $skillDir
}

# Main execution
try {
    $rawSkillName = $SkillName
    $skillName = Normalize-SkillName $rawSkillName
    
    if ([string]::IsNullOrWhiteSpace($skillName)) {
        Write-Error "Skill name must include at least one letter or digit."
        exit 1
    }
    
    if ($skillName.Length -gt $MAX_SKILL_NAME_LENGTH) {
        Write-Error "Skill name '$skillName' is too long ($($skillName.Length) characters). Maximum is $MAX_SKILL_NAME_LENGTH characters."
        exit 1
    }
    
    if ($skillName -ne $rawSkillName) {
        Write-Host "Note: Normalized skill name from '$rawSkillName' to '$skillName'."
    }
    
    $resources = Parse-Resources $Resources
    if ($Examples -and $resources.Count -eq 0) {
        Write-Error "--examples requires --resources to be set."
        exit 1
    }
    
    Write-Host "Initializing skill: $skillName"
    Write-Host "   Location: $Path"
    if ($resources.Count -gt 0) {
        Write-Host "   Resources: $($resources -join ", ")"
        if ($Examples) {
            Write-Host "   Examples: enabled"
        }
    } else {
        Write-Host "   Resources: none (create as needed)"
    }
    Write-Host ""
    
    $result = Initialize-Skill -SkillName $skillName -Path $Path -Resources $resources -IncludeExamples $Examples.IsPresent
    
    if ($null -eq $result) {
        exit 1
    } else {
        exit 0
    }
} catch {
    Write-Error "Unexpected error: $_"
    exit 1
}
