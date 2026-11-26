#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "4e84bb5dfc00546f928e9663c622251fab99b1db45519291b17dd0c307082560", "source_sha256": "f68a161573356fe83ce98ebe454cffaef6896f81d310cd932a9847500e671f9b", "target_language": "ruby"}
# json_processor.py — portiert nach ruby
# Quelle: python, OpenClaw@gateway1:skills/json-utils/scripts/json_processor.py
# auch in: OpenClaw@gateway2:skills/json-utils/scripts/json_processor.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# frozen_string_literal: true

# JSON Processor mit Pydantic Validation und JSON-Repair.
# Für robuste Verarbeitung von LLM-Outputs.

require 'json'
require 'optparse'

# Custom exception classes
class JSONProcessingError < StandardError
  # Base exception for JSON processing errors
end

class JSONValidationError < JSONProcessingError
  # Raised when JSON validation fails
end

class JSONRepairError < JSONProcessingError
  # Raised when JSON repair fails
end

# Repariert häufige JSON-Fehler aus LLM-Outputs.
# 
# Behebt:
# - Trailing commas
# - Einzelne statt doppelte Quotes
# - JavaScript-Style Kommentare
# - Unescaped Zeilenumbrüche in Strings
def repair_json_string(raw_json)
  # Fallback: Manuelle Reparaturen
  cleaned = raw_json.strip
  
  # Entferne JavaScript-Kommentare
  cleaned = cleaned.gsub(%r{//.*?\n}, "\n")
  cleaned = cleaned.gsub(%r{/\*.*?\*/}m, '')
  
  # Entferne trailing commas vor ] oder }
  cleaned = cleaned.gsub(/,(\s*[}\]])/, '\1')
  
  cleaned
rescue => e
  raise JSONRepairError, "JSON repair failed: #{e.message}"
end

# Parst JSON-String mit optionaler automatischer Reparatur.
# 
# Args:
#     raw_input: Der zu parsende JSON-String
#     repair: Ob JSON-Reparatur versucht werden soll (default: True)
# 
# Returns:
#     Geparstes Ruby-Objekt
# 
# Raises:
#     JSONProcessingError: Wenn Parsing fehlschlägt
def parse_json(raw_input, repair: true)
  raw_input = raw_input.strip
  
  # Versuche zuerst direktes Parsing
  begin
    return JSON.parse(raw_input)
  rescue JSON::ParserError
    nil
  end
  
  # Extrahiere JSON aus Markdown-Code-Blöcken
  if raw_input.include?('```')
    # Suche nach JSON in ```json ... ``` oder ``` ... ```
    patterns = [
      /```json\s*(.*?)\s*```/m,
      /```\s*(\{.*?\})\s*```/m,
      /```\s*(\[.*?\])\s*```/m
    ]
    
    patterns.each do |pattern|
      raw_input.scan(pattern) do |match|
        match_array = match.is_a?(Array) ? match : [match]
        match_array.each do |m|
          begin
            return JSON.parse(m)
          rescue JSON::ParserError
            next
          end
        end
      end
    end
  end
  
  # Versuche Reparatur
  if repair
    begin
      repaired = repair_json_string(raw_input)
      return JSON.parse(repaired)
    rescue JSON::ParserError, JSONRepairError => e
      raise JSONProcessingError, "Could not parse JSON even after repair: #{e.message}"
    end
  end
  
  raise JSONProcessingError, "Could not parse JSON"
end

# Sicheres JSON-Parsing mit Fallback auf Default-Wert.
# 
# Args:
#     raw_input: Der zu parsende JSON-String
#     default: Rückgabewert bei Fehlschlag (default: nil)
#     repair: Ob Reparatur versucht werden soll
# 
# Returns:
#     Geparstes Objekt oder Default-Wert
def safe_json_loads(raw_input, default: nil, repair: true)
  parse_json(raw_input, repair: repair)
rescue JSONProcessingError
  default
end

# Extrahiert alle JSON-Objekte aus einem Text.
# 
# Args:
#     text: Text, der JSON-Objekte enthalten könnte
# 
# Returns:
#     Liste aller gefundenen und geparsten JSON-Objekte
def extract_json_from_text(text)
  results = []
  
  # Pattern für JSON-Objekte und Arrays
  patterns = [
    /\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}/,  # Objekte
    /\[[^\[\]]*(?:\[[^\[\]]*\][^\[\]]*)*\]/  # Arrays
  ]
  
  patterns.each do |pattern|
    text.scan(pattern) do |match|
      begin
        parsed = parse_json(match, repair: true)
        results << parsed
      rescue JSONProcessingError
        next
      end
    end
  end
  
  results
end

if __FILE__ == $0
  # CLI-Interface
  options = {
    repair: true,
    pretty: false,
    file: false
  }
  
  parser = OptionParser.new do |opts|
    opts.banner = "Usage: #{$0} [options] INPUT"
    opts.separator ""
    opts.separator "JSON Processor with repair"
    opts.separator ""
    opts.separator "Options:"
    
    opts.on("-f", "--file", "Input is a file path") do
      options[:file] = true
    end
    
    opts.on("-r", "--[no-]repair", "Enable/disable JSON repair (default: enabled)") do |v|
      options[:repair] = v
    end
    
    opts.on("-p", "--pretty", "Pretty print output") do
      options[:pretty] = true
    end
    
    opts.on("-h", "--help", "Show this message") do
      puts opts
      exit
    end
  end
  
  begin
    parser.parse!
    raise OptionParser::MissingArgument.new("INPUT") if ARGV.empty?
    
    input = ARGV[0]
    
    content = if options[:file]
                File.read(input)
              else
                input
              end
    
    result = parse_json(content, repair: options[:repair])
    
    if options[:pretty]
      puts JSON.pretty_generate(result)
    else
      puts JSON.generate(result)
    end
    
  rescue JSONProcessingError => e
    STDERR.puts "Error: #{e.message}"
    exit 1
  rescue => e
    STDERR.puts "Unexpected error: #{e.message}"
    exit 1
  end
end
