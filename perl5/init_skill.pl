#!/usr/bin/env perl
# init_skill.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:skills/skill-creator/scripts/init_skill.py
# auch in: OpenClaw@gateway2:skills/skill-creator/scripts/init_skill.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use Getopt::Long;
use File::Path qw(make_path);
use File::Spec;
use Cwd qw(abs_path);

my $MAX_SKILL_NAME_LENGTH = 64;
my %ALLOWED_RESOURCES = map { $_ => 1 } qw(scripts references assets);

my $SKILL_TEMPLATE = <<'END_TEMPLATE';
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
END_TEMPLATE

my $EXAMPLE_SCRIPT = <<'END_SCRIPT';
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
END_SCRIPT

my $EXAMPLE_REFERENCE = <<'END_REFERENCE';
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
END_REFERENCE

my $EXAMPLE_ASSET = <<'END_ASSET';
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
END_ASSET

sub normalize_skill_name {
    my ($skill_name) = @_;
    $skill_name =~ s/^\s+|\s+$//g;
    $skill_name = lc($skill_name);
    $skill_name =~ s/[^a-z0-9]+/-/g;
    $skill_name =~ s/^-+|-+$//g;
    $skill_name =~ s/-{2,}/-/g;
    return $skill_name;
}

sub title_case_skill_name {
    my ($skill_name) = @_;
    my @words = split /-/, $skill_name;
    @words = map { ucfirst $_ } @words;
    return join " ", @words;
}

sub parse_resources {
    my ($raw_resources) = @_;
    return [] unless $raw_resources;
    
    my @resources = grep { $_ ne "" } map { s/^\s+|\s+$//gr } split /,/, $raw_resources;
    my @invalid = grep { !$ALLOWED_RESOURCES{$_} } @resources;
    
    if (@invalid) {
        my $allowed = join ", ", sort keys %ALLOWED_RESOURCES;
        print "[ERROR] Unknown resource type(s): " . join(", ", @invalid) . "\n";
        print "   Allowed: $allowed\n";
        exit 1;
    }
    
    my (%seen, @deduped);
    for my $resource (@resources) {
        push @deduped, $resource unless $seen{$resource}++;
    }
    
    return \@deduped;
}

sub create_resource_dirs {
    my ($skill_dir, $skill_name, $skill_title, $resources, $include_examples) = @_;
    
    for my $resource (@$resources) {
        my $resource_dir = File::Spec->catdir($skill_dir, $resource);
        make_path($resource_dir) or die "Failed to create directory $resource_dir: $!";
        
        if ($resource eq "scripts") {
            if ($include_examples) {
                my $example_script = File::Spec->catfile($resource_dir, "example.py");
                open my $fh, ">", $example_script or die "Cannot write to $example_script: $!";
                print $fh $EXAMPLE_SCRIPT;
                close $fh;
                chmod 0755, $example_script or die "Cannot chmod $example_script: $!";
                print "[OK] Created scripts/example.py\n";
            } else {
                print "[OK] Created scripts/\n";
            }
        } elsif ($resource eq "references") {
            if ($include_examples) {
                my $example_reference = File::Spec->catfile($resource_dir, "api_reference.md");
                open my $fh, ">", $example_reference or die "Cannot write to $example_reference: $!";
                print $fh $EXAMPLE_REFERENCE;
                close $fh;
                print "[OK] Created references/api_reference.md\n";
            } else {
                print "[OK] Created references/\n";
            }
        } elsif ($resource eq "assets") {
            if ($include_examples) {
                my $example_asset = File::Spec->catfile($resource_dir, "example_asset.txt");
                open my $fh, ">", $example_asset or die "Cannot write to $example_asset: $!";
                print $fh $EXAMPLE_ASSET;
                close $fh;
                print "[OK] Created assets/example_asset.txt\n";
            } else {
                print "[OK] Created assets/\n";
            }
        }
    }
}

sub init_skill {
    my ($skill_name, $path, $resources, $include_examples) = @_;
    
    # Determine skill directory path
    my $skill_dir = File::Spec->catdir(abs_path($path), $skill_name);
    
    # Check if directory already exists
    if (-e $skill_dir) {
        print "[ERROR] Skill directory already exists: $skill_dir\n";
        return undef;
    }
    
    # Create skill directory
    eval {
        make_path($skill_dir);
        print "[OK] Created skill directory: $skill_dir\n";
    };
    if ($@) {
        print "[ERROR] Error creating directory: $@\n";
        return undef;
    }
    
    # Create SKILL.md from template
    my $skill_title = title_case_skill_name($skill_name);
    my $skill_content = $SKILL_TEMPLATE;
    $skill_content =~ s/\{skill_name\}/$skill_name/g;
    $skill_content =~ s/\{skill_title\}/$skill_title/g;
    
    my $skill_md_path = File::Spec->catfile($skill_dir, "SKILL.md");
    eval {
        open my $fh, ">", $skill_md_path or die "Cannot write to $skill_md_path: $!";
        print $fh $skill_content;
        close $fh;
        print "[OK] Created SKILL.md\n";
    };
    if ($@) {
        print "[ERROR] Error creating SKILL.md: $@\n";
        return undef;
    }
    
    # Create resource directories if requested
    if (@$resources) {
        eval {
            create_resource_dirs($skill_dir, $skill_name, $skill_title, $resources, $include_examples);
        };
        if ($@) {
            print "[ERROR] Error creating resource directories: $@\n";
            return undef;
        }
    }
    
    # Print next steps
    print "\n[OK] Skill '$skill_name' initialized successfully at $skill_dir\n";
    print "\nNext steps:\n";
    print "1. Edit SKILL.md to complete the TODO items and update the description\n";
    if (@$resources) {
        if ($include_examples) {
            print "2. Customize or delete the example files in scripts/, references/, and assets/\n";
        } else {
            print "2. Add resources to scripts/, references/, and assets/ as needed\n";
        }
    } else {
        print "2. Create resource directories only if needed (scripts/, references/, assets/)\n";
    }
    print "3. Run the validator when ready to check the skill structure\n";
    
    return $skill_dir;
}

sub main {
    my ($skill_name, $path, $resources, $examples);
    GetOptions(
        "path=s" => \$path,
        "resources=s" => \$resources,
        "examples" => \$examples,
    ) or die "Invalid options\n";
    
    @ARGV or die "Usage: $0 <skill-name> --path <path> [--resources scripts,references,assets] [--examples]\n";
    $skill_name = $ARGV[0];
    
    defined $path or die "Option --path is required\n";
    
    my $raw_skill_name = $skill_name;
    $skill_name = normalize_skill_name($skill_name);
    
    if (!$skill_name) {
        print "[ERROR] Skill name must include at least one letter or digit.\n";
        exit 1;
    }
    
    if (length($skill_name) > $MAX_SKILL_NAME_LENGTH) {
        print "[ERROR] Skill name '$skill_name' is too long (" . length($skill_name) . " characters). ";
        print "Maximum is $MAX_SKILL_NAME_LENGTH characters.\n";
        exit 1;
    }
    
    if ($skill_name ne $raw_skill_name) {
        print "Note: Normalized skill name from '$raw_skill_name' to '$skill_name'.\n";
    }
    
    my $parsed_resources = parse_resources($resources);
    
    if ($examples && !@$parsed_resources) {
        print "[ERROR] --examples requires --resources to be set.\n";
        exit 1;
    }
    
    print "Initializing skill: $skill_name\n";
    print "   Location: $path\n";
    
    if (@$parsed_resources) {
        print "   Resources: " . join(", ", @$parsed_resources) . "\n";
        if ($examples) {
            print "   Examples: enabled\n";
        }
    } else {
        print "   Resources: none (create as needed)\n";
    }
    print "\n";
    
    my $result = init_skill($skill_name, $path, $parsed_resources, $examples);
    
    exit($result ? 0 : 1);
}

main() unless caller;
