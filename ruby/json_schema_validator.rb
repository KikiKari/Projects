#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "3ce704bcd0ca3d2c5768b9419d6df5815c85a74553b326380fb3b4222c421f03", "source_sha256": "f55ff3c9a1d0fb13ff0d5dd08f91e1c1a304c7d83f3d1bb93f165f2437d276b9", "target_language": "ruby"}
# json_schema_validator.py — portiert nach ruby
# Quelle: python, OpenClaw@gateway1:skills/json-utils/scripts/json_schema_validator.py
# auch in: OpenClaw@gateway2:skills/json-utils/scripts/json_schema_validator.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# frozen_string_literal: true

# JSON Schema Validator - Validiert JSON gegen JSON Schema Draft 7/2020-12.
# Erweitert Pydantic mit externen Schema-Dateien.

require 'json'
require 'pathname'

# JSON Schema validation library (optional)
begin
  require 'json-schema'
  HAS_JSONSCHEMA = true
rescue LoadError
  HAS_JSONSCHEMA = false
end

# Custom error classes
class JSONProcessingError < StandardError; end
class JSONValidationError < StandardError; end
class SchemaValidationError < JSONValidationError; end

# JSON processor module (simulated)
module JSONProcessor
  def self.parse_json(raw_input, repair: true)
    # In a real implementation, this would handle JSON parsing with repair options
    JSON.parse(raw_input)
  rescue JSON::ParserError => e
    raise JSONProcessingError, "Failed to parse JSON: #{e.message}"
  end
end

# Loads a JSON Schema from various sources
def load_schema(schema_source)
  # If it's already a Hash, return it
  return schema_source if schema_source.is_a?(Hash)

  schema_path = Pathname.new(schema_source)
  
  # If it's a file path that exists, read and parse it
  if schema_path.exist? && schema_path.file?
    begin
      return JSON.parse(schema_path.read)
    rescue JSON::ParserError => e
      raise SchemaValidationError, "Invalid JSON in schema file: #{e.message}"
    end
  end

  # Try to parse as JSON string
  begin
    JSON.parse(schema_source)
  rescue JSON::ParserError
    raise SchemaValidationError, "Schema not found or invalid: #{schema_source}"
  end
end

# Validates data against a JSON Schema
def validate_with_jsonschema(data, schema, draft: 'auto')
  unless HAS_JSONSCHEMA
    raise SchemaValidationError, 'json-schema gem not installed. Run: gem install json-schema'
  end

  schema_dict = load_schema(schema)

  # Validate the data against the schema
  errors = JSON::Validator.fully_validate(schema_dict, data, validate_schema: true)
  if errors.any?
    raise SchemaValidationError, "Schema validation failed: #{errors.join(', ')}"
  end

  true
rescue JSON::Schema::ValidationError => e
  raise SchemaValidationError, "Schema validation failed: #{e.message}"
end

# Parses, repairs and validates JSON against schema
def validate_and_convert(raw_input, schema, repair: true)
  data = JSONProcessor.parse_json(raw_input, repair: repair)
  validate_with_jsonschema(data, schema)
  data
end

# Helper class for creating JSON schemas
class SchemaBuilder
  # Creates an object schema
  def self.object(properties, required = nil)
    schema = {
      'type' => 'object',
      'properties' => properties
    }
    schema['required'] = required if required
    schema
  end

  # Creates a string schema
  def self.string(enum: nil, pattern: nil, min_length: nil)
    schema = { 'type' => 'string' }
    schema['enum'] = enum if enum
    schema['pattern'] = pattern if pattern
    schema['minLength'] = min_length unless min_length.nil?
    schema
  end

  # Creates an integer schema
  def self.integer(minimum: nil, maximum: nil)
    schema = { 'type' => 'integer' }
    schema['minimum'] = minimum unless minimum.nil?
    schema['maximum'] = maximum unless maximum.nil?
    schema
  end

  # Creates an array schema
  def self.array(items, min_items: nil)
    schema = { 'type' => 'array', 'items' => items }
    schema['minItems'] = min_items unless min_items.nil?
    schema
  end
end

# Main function
def main
  require 'optparse'

  options = {}
  options[:repair] = true

  parser = OptionParser.new do |opts|
    opts.banner = 'Usage: json_schema_validator.rb [options] INPUT'
    
    opts.on('-s', '--schema SCHEMA', 'Schema file') do |s|
      options[:schema] = s
    end
    
    opts.on('-f', '--file', 'Input is file') do
      options[:file] = true
    end
    
    opts.on('-r', '--[no-]repair', 'Attempt to repair JSON') do |r|
      options[:repair] = r
    end
    
    opts.on('-h', '--help', 'Show this message') do
      puts opts
      exit
    end
  end

  begin
    parser.parse!
    raise OptionParser::MissingArgument.new('--schema') if options[:schema].nil?
    raise OptionParser::InvalidArgument.new('INPUT') if ARGV.empty?
  rescue OptionParser::ParseError => e
    puts "Error: #{e.message}"
    puts parser
    exit 1
  end

  input_arg = ARGV.first

  # Load input (auto-detect file vs string)
  if options[:file] || (File.exist?(input_arg) && File.file?(input_arg))
    raw_input = File.read(input_arg)
  else
    raw_input = input_arg
  end

  begin
    result = validate_and_convert(raw_input, options[:schema], repair: options[:repair])
    puts JSON.pretty_generate(result)
    $stderr.puts "\n✓ Validation passed"
  rescue JSONProcessingError, SchemaValidationError => e
    $stderr.puts "✗ Validation failed: #{e.message}"
    exit 1
  end
end

# Only run main when script is executed directly
main if __FILE__ == $0
