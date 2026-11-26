#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "da004b8ca21a3a8b535d77701deadadd9e5c81a6485f141e90fbd4199339e6f1", "source_sha256": "eb21431dabeaafc82a1e3ccf24278616e46ed082eca1de4d328c758ee82ee2c7", "target_language": "ruby"}
# language_validator.py — portiert nach ruby
# Quelle: python, OpenClaw@gateway1:skills/scripting-utils/scripts/language_validator.py
# auch in: OpenClaw@gateway2:skills/scripting-utils/scripts/language_validator.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# Multi-language script validator supporting 8+ languages.
# WebSearch integration for documentation lookup.

require 'open3'
require 'timeout'
require 'optparse'

class ValidationResult
  attr_reader :language, :valid, :errors, :warnings, :doc_url

  def initialize(language:, valid:, errors:, warnings:, doc_url: nil)
    @language = language
    @valid = valid
    @errors = errors
    @warnings = warnings
    @doc_url = doc_url
  end
end

class LanguageValidator
  LANGUAGES = {
    "bash" => {"cmd" => "bash", "args" => ["-n"], "linter" => "shellcheck"},
    "sh" => {"cmd" => "sh", "args" => ["-n"], "linter" => "shellcheck"},
    "python" => {"cmd" => "python3", "args" => ["-m", "py_compile"], "linter" => "pylint"},
    "perl" => {"cmd" => "perl", "args" => ["-c"], "linter" => "perlcritic"},
    "raku" => {"cmd" => "raku", "args" => ["-c"], "linter" => nil},
    "powershell" => {"cmd" => "pwsh", "args" => ["-Command", "Get-Command"], "linter" => nil},
    "javascript" => {"cmd" => "node", "args" => ["--check"], "linter" => "eslint"},
    "tcl" => {"cmd" => "tclsh", "args" => [], "linter" => nil},
  }.freeze

  def initialize(language, use_websearch: true)
    @language = language.downcase
    @use_websearch = use_websearch
    @config = LANGUAGES[@language]
    raise ArgumentError, "Unsupported language: #{language}" unless @config
  end

  def validate(script_path)
    errors = []
    warnings = []

    # Syntax check
    begin
      cmd = [@config["cmd"], *@config["args"], script_path.to_s]
      stdout, stderr, status = Timeout.timeout(30) do
        Open3.capture3(*cmd)
      end
      
      if status.exitstatus != 0
        errors << stderr
      end
    rescue Timeout::Error
      errors << "Validation timeout"
    rescue Errno::ENOENT
      errors << "Command not found: #{@config['cmd']}"
      if @use_websearch
        doc_url = fetch_docs
        return ValidationResult.new(
          language: @language,
          valid: false,
          errors: errors,
          warnings: warnings,
          doc_url: doc_url
        )
      end
    end

    # Linter check if available
    if @config["linter"]
      linter_warnings = run_linter(script_path)
      warnings.concat(linter_warnings)
    end

    ValidationResult.new(
      language: @language,
      valid: errors.empty?,
      errors: errors,
      warnings: warnings
    )
  end

  private

  def run_linter(script_path)
    linter = @config["linter"]
    warnings = []

    begin
      case linter
      when "shellcheck"
        stdout, stderr, status = Open3.capture3("shellcheck", "-f", "gcc", script_path.to_s)
        if !stdout.empty?
          warnings.concat(stdout.strip.split("\n"))
        end
      when "pylint"
        stdout, stderr, status = Open3.capture3("pylint", "--output-format=parseable", script_path.to_s)
        if !stdout.empty?
          warnings.concat(stdout.strip.split("\n"))
        end
      end
    rescue Errno::ENOENT
      warnings << "Linter not installed: #{linter}"
    end

    warnings
  end

  def fetch_docs
    return nil unless @use_websearch

    # Return known good documentation URLs
    docs = {
      "powershell" => "https://docs.microsoft.com/powershell/",
      "raku" => "https://docs.raku.org/",
      "tcl" => "https://www.tcl.tk/",
    }
    docs[@language]
  end
end

def main
  options = {}
  options[:websearch] = true

  parser = OptionParser.new do |opts|
    opts.banner = "Usage: #{$0} [options] SCRIPT"
    
    opts.on("--lang LANGUAGE", "Language (bash/python/perl/etc.)") do |lang|
      options[:lang] = lang
    end
    
    opts.on("--no-websearch", "Disable WebSearch") do
      options[:websearch] = false
    end
    
    opts.on("-h", "--help", "Show this message") do
      puts opts
      exit
    end
  end

  begin
    parser.parse!
    if ARGV.empty?
      puts parser.help
      exit 1
    end
    
    script_path = File.expand_path(ARGV[0])
    raise ArgumentError, "Script file does not exist: #{script_path}" unless File.exist?(script_path)
    
    unless options[:lang]
      puts "Language is required (--lang)"
      puts parser.help
      exit 1
    end
  rescue => e
    puts "Error: #{e.message}"
    exit 1
  end

  validator = LanguageValidator.new(options[:lang], use_websearch: options[:websearch])
  result = validator.validate(script_path)

  puts "Language: #{result.language}"
  puts "Valid: #{result.valid}"
  
  if result.errors.any?
    puts "Errors: #{result.errors.length}"
    result.errors.first(5).each do |err|
      puts "  - #{err}"
    end
  end
  
  if result.warnings.any?
    puts "Warnings: #{result.warnings.length}"
    result.warnings.first(5).each do |warn|
      puts "  - #{warn}"
    end
  end
  
  if result.doc_url
    puts "Docs: #{result.doc_url}"
  end

  exit result.valid ? 0 : 1
end

if __FILE__ == $0
  main
end
