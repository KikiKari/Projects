// abstraction-provenance: {"artifact_sha256": "2998d74947f57ec64d06deda95b3d3fce3587af8ee2fe65831aecb41d88b6cb9", "source_sha256": "bcd6b802c400a9e89319844c6c3d965855c8b0555e982eb72cd4accb7ee67e3e", "target_language": "fsharp"}
// init_skill.py — portiert nach fsharp
// Quelle: python, OpenClaw@gateway1:skills/skill-creator/scripts/init_skill.py
// auch in: OpenClaw@gateway2:skills/skill-creator/scripts/init_skill.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

module InitSkill

open System
open System.IO
open System.Text.RegularExpressions
open System.Collections.Generic

let MAX_SKILL_NAME_LENGTH = 64
let ALLOWED_RESOURCES = set ["scripts"; "references"; "assets"]

let SKILL_TEMPLATE = """---
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
"""

let EXAMPLE_SCRIPT = """#!/usr/bin/env python3
""""""
Example helper script for {0}

This is a placeholder script that can be executed directly.
Replace with actual implementation or delete if not needed.

Example real scripts from other skills:
- pdf/scripts/fill_fillable_fields.py - Fills PDF form fields
- pdf/scripts/convert_pdf_to_images.py - Converts PDF pages to images
""""""


def main():
    print("This is an example script for {0}")
    # TODO: Add actual script logic here
    # This could be data processing, file conversion, API calls, etc.

if __name__ == "__main__":
    main()
"""

let EXAMPLE_REFERENCE = """# Reference Documentation for {0}

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
"""

let EXAMPLE_ASSET = """# Example Asset File

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
"""

let normalizeSkillName (skillName: string) =
    let normalized = skillName.Trim().ToLower()
    let normalized = Regex.Replace(normalized, "[^a-z0-9]+", "-")
    let normalized = normalized.Trim('-')
    Regex.Replace(normalized, "-{2,}", "-")

let titleCaseSkillName (skillName: string) =
    skillName.Split('-')
    |> Array.map (fun word -> 
        if word.Length > 0 then
            Char.ToUpper(word.[0]).ToString() + (if word.Length > 1 then word.Substring(1) else "")
        else
            word)
    |> String.concat " "

let parseResources (rawResources: string) =
    if String.IsNullOrEmpty(rawResources) then
        []
    else
        let resources = rawResources.Split([|','|], StringSplitOptions.RemoveEmptyEntries)
                      |> Array.map (fun s -> s.Trim())
                      |> Array.filter (fun s -> not (String.IsNullOrEmpty(s)))
        
        let invalid = resources |> Array.filter (fun r -> not (ALLOWED_RESOURCES.Contains(r))) |> Set.ofArray
        if not (Set.isEmpty invalid) then
            let allowed = ALLOWED_RESOURCES |> Set.toArray |> Array.sort |> String.concat ", "
            printfn "[ERROR] Unknown resource type(s): %s" (invalid |> Set.toArray |> String.concat ", ")
            printfn "   Allowed: %s" allowed
            exit 1
        
        // Remove duplicates while preserving order
        let seen = HashSet<string>()
        let deduped = ResizeArray<string>()
        for resource in resources do
            if seen.Add(resource) then
                deduped.Add(resource)
        deduped |> List.ofSeq

let createResourceDirs (skillDir: DirectoryInfo) (skillName: string) (skillTitle: string) (resources: string list) (includeExamples: bool) =
    for resource in resources do
        let resourceDir = DirectoryInfo(Path.Combine(skillDir.FullName, resource))
        if not resourceDir.Exists then
            resourceDir.Create()
        
        match resource with
        | "scripts" ->
            if includeExamples then
                let exampleScript = FileInfo(Path.Combine(resourceDir.FullName, "example.py"))
                File.WriteAllText(exampleScript.FullName, sprintf EXAMPLE_SCRIPT skillName)
                exampleScript.UnixFileMode <- UnixFileMode.UserRead ||| UnixFileMode.UserWrite ||| UnixFileMode.UserExecute |||
                                            UnixFileMode.GroupRead ||| UnixFileMode.GroupExecute |||
                                            UnixFileMode.OtherRead ||| UnixFileMode.OtherExecute
                printfn "[OK] Created scripts/example.py"
            else
                printfn "[OK] Created scripts/"
        | "references" ->
            if includeExamples then
                let exampleReference = FileInfo(Path.Combine(resourceDir.FullName, "api_reference.md"))
                File.WriteAllText(exampleReference.FullName, sprintf EXAMPLE_REFERENCE skillTitle)
                printfn "[OK] Created references/api_reference.md"
            else
                printfn "[OK] Created references/"
        | "assets" ->
            if includeExamples then
                let exampleAsset = FileInfo(Path.Combine(resourceDir.FullName, "example_asset.txt"))
                File.WriteAllText(exampleAsset.FullName, EXAMPLE_ASSET)
                printfn "[OK] Created assets/example_asset.txt"
            else
                printfn "[OK] Created assets/"
        | _ -> ()

let initSkill (skillName: string) (path: string) (resources: string list) (includeExamples: bool) =
    let skillDirPath = Path.Combine(path, skillName)
    let skillDir = DirectoryInfo(skillDirPath)
    
    if skillDir.Exists then
        printfn "[ERROR] Skill directory already exists: %s" skillDir.FullName
        None
    else
        try
            skillDir.Create()
            printfn "[OK] Created skill directory: %s" skillDir.FullName
            
            let skillTitle = titleCaseSkillName skillName
            let skillContent = sprintf SKILL_TEMPLATE skillName skillTitle
            
            let skillMdPath = Path.Combine(skillDir.FullName, "SKILL.md")
            File.WriteAllText(skillMdPath, skillContent)
            printfn "[OK] Created SKILL.md"
            
            if resources.Length > 0 then
                createResourceDirs skillDir skillName skillTitle resources includeExamples
            
            printfn "\n[OK] Skill '%s' initialized successfully at %s" skillName skillDir.FullName
            printfn "\nNext steps:"
            printfn "1. Edit SKILL.md to complete the TODO items and update the description"
            if resources.Length > 0 then
                if includeExamples then
                    printfn "2. Customize or delete the example files in scripts/, references/, and assets/"
                else
                    printfn "2. Add resources to scripts/, references/, and assets/ as needed"
            else
                printfn "2. Create resource directories only if needed (scripts/, references/, assets/)"
            printfn "3. Run the validator when ready to check the skill structure"
            
            Some(skillDir.FullName)
        with
        | ex ->
            printfn "[ERROR] Error creating skill: %s" ex.Message
            None

[<EntryPoint>]
let main argv =
    let mutable skillName = ""
    let mutable path = ""
    let mutable resources = ""
    let mutable examples = false
    
    let rec parseArgs args index =
        if index >= args.Length then ()
        else
            match args.[index] with
            | arg when arg.StartsWith("--") ->
                match arg with
                | "--path" when index + 1 < args.Length ->
                    path <- args.[index + 1]
                    parseArgs args (index + 2)
                | "--resources" when index + 1 < args.Length ->
                    resources <- args.[index + 1]
                    parseArgs args (index + 2)
                | "--examples" ->
                    examples <- true
                    parseArgs args (index + 1)
                | _ ->
                    printfn "Unknown option: %s" arg
                    exit 1
            | arg when not arg.StartsWith("-") && skillName = "" ->
                skillName <- arg
                parseArgs args (index + 1)
            | arg ->
                printfn "Unexpected argument: %s" arg
                exit 1
    
    parseArgs argv 0
    
    if skillName = "" then
        printfn "Error: skill-name is required"
        exit 1
    
    if path = "" then
        printfn "Error: --path is required"
        exit 1
    
    let normalizedSkillName = normalizeSkillName skillName
    
    if String.IsNullOrEmpty(normalizedSkillName) then
        printfn "[ERROR] Skill name must include at least one letter or digit."
        exit 1
    
    if normalizedSkillName.Length > MAX_SKILL_NAME_LENGTH then
        printfn "[ERROR] Skill name '%s' is too long (%d characters). Maximum is %d characters." 
            normalizedSkillName normalizedSkillName.Length MAX_SKILL_NAME_LENGTH
        exit 1
    
    if normalizedSkillName <> skillName then
        printfn "Note: Normalized skill name from '%s' to '%s'." skillName normalizedSkillName
    
    let parsedResources = parseResources resources
    
    if examples && parsedResources.IsEmpty then
        printfn "[ERROR] --examples requires --resources to be set."
        exit 1
    
    printfn "Initializing skill: %s" normalizedSkillName
    printfn "   Location: %s" path
    if parsedResources.IsEmpty then
        printfn "   Resources: none (create as needed)"
    else
        printfn "   Resources: %s" (String.concat ", " parsedResources)
        if examples then
            printfn "   Examples: enabled"
    printfn ""
    
    let result = initSkill normalizedSkillName path parsedResources examples
    
    match result with
    | Some(_) -> 0
    | None -> 1
