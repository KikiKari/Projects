#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "33270ae0eaf143e0b1730ffdc244175960706cac7e59c2df2829d4cd84bc45e3", "source_sha256": "bcd6b802c400a9e89319844c6c3d965855c8b0555e982eb72cd4accb7ee67e3e", "target_language": "ruby"}
# init_skill.py — portiert nach ruby
# Quelle: python, OpenClaw@gateway1:skills/skill-creator/scripts/init_skill.py
# auch in: OpenClaw@gateway2:skills/skill-creator/scripts/init_skill.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# frozen_string_literal: true

# Skill Initializer - Creates a new skill from template
#
# Usage:
#     init_skill.rb <skill-name> --path <path> [--resources scripts,references,assets] [--examples]
#
# Examples:
#     init_skill.rb my-new-skill --path skills/public
#     init_skill.rb my-new-skill --path skills/public --resources scripts,references
#     init_skill.rb my-api-helper --path skills/private --resources scripts --examples
#     init_skill.rb custom-skill --path /custom/location

require 'optparse'
require 'fileutils'

MAX_SKILL_NAME_LENGTH = 64
ALLOWED_RESOURCES = %w[scripts references assets].freeze

SKILL_TEMPLATE = <<~TEMPLATE
  ---
  name: %{skill_name}
  description: [TODO: Complete and informative explanation of what the skill does and when to use it. Include WHEN to use this skill - specific scenarios, file types, or tasks that trigger it.]
  ---

  # %{skill_title}

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
TEMPLATE

EXAMPLE_SCRIPT = <<~SCRIPT
  #!/usr/bin/env python3
  """
  Example helper script for %{skill_name}

  This is a placeholder script that can be executed directly.
  Replace with actual implementation or delete if not needed.

  Example real scripts from other skills:
  - pdf/scripts/fill_fillable_fields.py - Fills PDF form fields
  - pdf/scripts/convert_pdf_to_images.py - Converts PDF pages to images
  """

  def main():
      print("This is an example script for %{skill_name}")
      # TODO: Add actual script logic here
      # This could be data processing, file conversion, API calls, etc.

  if __name__ == "__main__":
      main()
SCRIPT

EXAMPLE_REFERENCE = <<~REFERENCE
  # Reference Documentation for %{skill_title}

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
REFERENCE

EXAMPLE_ASSET = <<~ASSET
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
ASSET

def normalize_skill_name(skill_name)
  # Normalize a skill name to lowercase hyphen-case.
  normalized = skill_name.strip.downcase
  normalized = normalized.gsub(/[^a-z0-9]+/, '-')
  normalized = normalized.gsub(/^-+|-+$/, '')
  normalized = normalized.gsub(/-{2,}/, '-')
  normalized
end

def title_case_skill_name(skill_name)
  # Convert hyphenated skill name to Title Case for display.
  skill_name.split('-').map(&:capitalize).join(' ')
end

def parse_resources(raw_resources)
  return [] if raw_resources.nil? || raw_resources.empty?

  resources = raw_resources.split(',').map(&:strip).select { |r| !r.empty? }
  invalid = resources.select { |r| !ALLOWED_RESOURCES.include?(r) }.sort.uniq

  unless invalid.empty?
    allowed = ALLOWED_RESOURCES.sort.join(', ')
    puts "[ERROR] Unknown resource type(s): #{invalid.join(', ')}"
    puts "   Allowed: #{allowed}"
    exit(1)
  end

  resources.uniq
end

def create_resource_dirs(skill_dir, skill_name, skill_title, resources, include_examples)
  resources.each do |resource|
    resource_dir = File.join(skill_dir, resource)
    FileUtils.mkdir_p(resource_dir) unless Dir.exist?(resource_dir)

    case resource
    when 'scripts'
      if include_examples
        example_script = File.join(resource_dir, 'example.py')
        File.write(example_script, EXAMPLE_SCRIPT % { skill_name: skill_name })
        File.chmod(0o755, example_script)
        puts '[OK] Created scripts/example.py'
      else
        puts '[OK] Created scripts/'
      end
    when 'references'
      if include_examples
        example_reference = File.join(resource_dir, 'api_reference.md')
        File.write(example_reference, EXAMPLE_REFERENCE % { skill_title: skill_title })
        puts '[OK] Created references/api_reference.md'
      else
        puts '[OK] Created references/'
      end
    when 'assets'
      if include_examples
        example_asset = File.join(resource_dir, 'example_asset.txt')
        File.write(example_asset, EXAMPLE_ASSET)
        puts '[OK] Created assets/example_asset.txt'
      else
        puts '[OK] Created assets/'
      end
    end
  end
end

def init_skill(skill_name, path, resources, include_examples)
  # Initialize a new skill directory with template SKILL.md.
  #
  # Args:
  #     skill_name: Name of the skill
  #     path: Path where the skill directory should be created
  #     resources: Resource directories to create
  #     include_examples: Whether to create example files in resource directories
  #
  # Returns:
  #     Path to created skill directory, or nil if error

  # Determine skill directory path
  skill_dir = File.expand_path(File.join(path, skill_name))

  # Check if directory already exists
  if Dir.exist?(skill_dir)
    puts "[ERROR] Skill directory already exists: #{skill_dir}"
    return nil
  end

  # Create skill directory
  begin
    FileUtils.mkdir_p(skill_dir)
    puts "[OK] Created skill directory: #{skill_dir}"
  rescue => e
    puts "[ERROR] Error creating directory: #{e.message}"
    return nil
  end

  # Create SKILL.md from template
  skill_title = title_case_skill_name(skill_name)
  skill_content = SKILL_TEMPLATE % { skill_name: skill_name, skill_title: skill_title }

  skill_md_path = File.join(skill_dir, 'SKILL.md')
  begin
    File.write(skill_md_path, skill_content)
    puts '[OK] Created SKILL.md'
  rescue => e
    puts "[ERROR] Error creating SKILL.md: #{e.message}"
    return nil
  end

  # Create resource directories if requested
  if resources && !resources.empty?
    begin
      create_resource_dirs(skill_dir, skill_name, skill_title, resources, include_examples)
    rescue => e
      puts "[ERROR] Error creating resource directories: #{e.message}"
      return nil
    end
  end

  # Print next steps
  puts "\n[OK] Skill '#{skill_name}' initialized successfully at #{skill_dir}"
  puts "\nNext steps:"
  puts '1. Edit SKILL.md to complete the TODO items and update the description'
  if resources && !resources.empty?
    if include_examples
      puts '2. Customize or delete the example files in scripts/, references/, and assets/'
    else
      puts '2. Add resources to scripts/, references/, and assets/ as needed'
    end
  else
    puts '2. Create resource directories only if needed (scripts/, references/, assets/)'
  end
  puts '3. Run the validator when ready to check the skill structure'

  skill_dir
end

def main
  options = {}
  OptionParser.new do |opts|
    opts.banner = 'Usage: init_skill.rb [options] skill-name'

    opts.on('--path PATH', 'Output directory for the skill') do |path|
      options[:path] = path
    end

    opts.on('--resources RESOURCES', 'Comma-separated list: scripts,references,assets') do |resources|
      options[:resources] = resources
    end

    opts.on('--examples', 'Create example files inside the selected resource directories') do
      options[:examples] = true
    end

    opts.on('-h', '--help', 'Show this message') do
      puts opts
      exit
    end
  end.parse!

  if ARGV.length != 1
    puts 'Error: Please provide exactly one skill name.'
    exit(1)
  end

  raw_skill_name = ARGV[0]
  skill_name = normalize_skill_name(raw_skill_name)

  if skill_name.empty?
    puts '[ERROR] Skill name must include at least one letter or digit.'
    exit(1)
  end

  if skill_name.length > MAX_SKILL_NAME_LENGTH
    puts "[ERROR] Skill name '#{skill_name}' is too long (#{skill_name.length} characters). Maximum is #{MAX_SKILL_NAME_LENGTH} characters."
    exit(1)
  end

  if skill_name != raw_skill_name
    puts "Note: Normalized skill name from '#{raw_skill_name}' to '#{skill_name}'."
  end

  resources = parse_resources(options[:resources])
  
  if options[:examples] && (resources.nil? || resources.empty?)
    puts '[ERROR] --examples requires --resources to be set.'
    exit(1)
  end

  path = options[:path] || '.'

  puts "Initializing skill: #{skill_name}"
  puts "   Location: #{path}"
  if resources && !resources.empty?
    puts "   Resources: #{resources.join(', ')}"
    puts '   Examples: enabled' if options[:examples]
  else
    puts '   Resources: none (create as needed)'
  end
  puts

  result = init_skill(skill_name, path, resources, options[:examples])

  if result
    exit(0)
  else
    exit(1)
  end
end

main if __FILE__ == $0
