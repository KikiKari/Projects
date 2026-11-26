#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "b43fb54fd26b58fcd4f0eb360f7e0cca59d75b2b5c0a6058f579eb72d1cf12a3", "source_sha256": "40b902ee3739509c4b2ef72ed57b4d983e5b509f6e446d20ab14d630d9773322", "target_language": "ruby"}
# json_batch_processor.py — portiert nach ruby
# Quelle: python, OpenClaw@gateway1:skills/json-utils/scripts/json_batch_processor.py
# auch in: OpenClaw@gateway2:skills/json-utils/scripts/json_batch_processor.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# frozen_string_literal: true

# Batch JSON Processor - Verarbeitet mehrere JSON-Dateien oder JSON-Lines (NDJSON).

require 'json'
require 'pathname'
require 'optparse'
require 'thread'

# Custom exception class for JSON processing errors
class JSONProcessingError < StandardError; end

# Ergebnis einer Batch-Verarbeitung.
class BatchResult
  attr_accessor :index, :source, :success, :data, :error

  def initialize(index:, source:, success:, data: nil, error: nil)
    @index = index
    @source = source
    @success = success
    @data = data
    @error = error
  end

  def to_h
    {
      index: @index,
      source: @source,
      success: @success,
      data: @data,
      error: @error
    }
  end
end

# Reads JSON-Lines (NDJSON) file line by line
def read_jsonl(file_path)
  lines = []
  File.open(file_path, 'r:utf-8') do |f|
    f.each_line.with_index(1) do |line, line_num|
      line = line.strip
      next if line.empty?

      begin
        lines << JSON.parse(line)
      rescue JSON::ParserError => e
        lines << BatchResult.new(
          index: line_num,
          source: "#{file_path}:#{line_num}",
          success: false,
          error: "JSON decode error: #{e.message}"
        )
      end
    end
  end
  lines
end

# Processes a list of inputs in parallel
def process_batch(inputs, processor, max_workers: 4)
  results = []
  mutex = Mutex.new

  threads = []
  queue = Queue.new

  inputs.each_with_index { |inp, idx| queue << [inp, idx] }

  max_workers.times do
    threads << Thread.new do
      while !queue.empty?
        begin
          inp, idx = queue.pop(true)
        rescue ThreadError
          break
        end

        begin
          result = processor.call(inp, idx)
          mutex.synchronize { results << result }
        rescue => e
          mutex.synchronize do
            results << BatchResult.new(
              index: idx,
              source: inp.to_s,
              success: false,
              error: "Unexpected error: #{e.message}"
            )
          end
        end
      end
    end
  end

  threads.each(&:join)
  results.sort_by(&:index)
end

# Processes multiple JSON files in batch
def process_file_batch(file_paths, repair: true, validate_model: nil, max_workers: 4)
  processor = lambda do |path, idx|
    begin
      content = Pathname.new(path).read(encoding: 'utf-8')

      if validate_model
        data = parse_and_validate(content, validate_model, repair: repair)
      else
        data = parse_json(content, repair: repair)
      end

      BatchResult.new(
        index: idx,
        source: path.to_s,
        success: true,
        data: data
      )
    rescue JSONProcessingError => e
      BatchResult.new(
        index: idx,
        source: path.to_s,
        success: false,
        error: e.message
      )
    rescue => e
      BatchResult.new(
        index: idx,
        source: path.to_s,
        success: false,
        error: "#{e.class.name}: #{e.message}"
      )
    end
  end

  process_batch(file_paths, processor, max_workers: max_workers)
end

# Processes a JSON-Lines file
def process_jsonl_file(file_path, repair: true, validate_model: nil)
  results = []

  File.open(file_path, 'r:utf-8') do |f|
    f.each_line.with_index(1) do |line, line_num|
      line = line.strip
      next if line.empty?

      begin
        if validate_model
          data = parse_and_validate(line, validate_model, repair: repair)
        else
          data = parse_json(line, repair: repair)
        end

        results << BatchResult.new(
          index: line_num,
          source: "#{file_path}:#{line_num}",
          success: true,
          data: data
        )
      rescue JSONProcessingError => e
        results << BatchResult.new(
          index: line_num,
          source: "#{file_path}:#{line_num}",
          success: false,
          error: e.message
        )
      end
    end
  end

  results
end

# Writes BatchResult list as JSON-Lines
def write_jsonl(results, output_path, only_successful: true)
  File.open(output_path, 'w:utf-8') do |f|
    results.each do |result|
      next if only_successful && !result.success

      f.write(JSON.generate(result.to_h, ascii_only: false) + "\n")
    end
  end
end

# Parse JSON with optional repair functionality
def parse_json(content, repair: true)
  begin
    JSON.parse(content)
  rescue JSON::ParserError => e
    if repair
      # Simple repair attempt - remove trailing commas
      repaired = content.gsub(/,\s*(\]|\})/, '\\1')
      JSON.parse(repaired)
    else
      raise JSONProcessingError, "JSON parsing failed: #{e.message}"
    end
  end
end

# Parse and validate JSON using a model (stub implementation)
def parse_and_validate(content, model_class, repair: true)
  data = parse_json(content, repair: repair)
  # In a real implementation, this would use the model_class to validate data
  data
end

# Main function
def main
  options = {
    jsonl: false,
    repair: true,
    workers: 4,
    output: nil,
    summary: false
  }

  parser = OptionParser.new do |opts|
    opts.banner = "Usage: #{$0} [options] INPUTS..."
    opts.separator ""
    opts.separator "Batch JSON Processor"

    opts.on("--jsonl", "-l", "Treat inputs as JSON-Lines files") do
      options[:jsonl] = true
    end

    opts.on("--repair", "-r", "Enable JSON repair") do
      options[:repair] = true
    end

    opts.on("--workers WORKERS", "-w WORKERS", Integer, "Parallel workers") do |w|
      options[:workers] = w
    end

    opts.on("--output OUTPUT", "-o OUTPUT", "Output JSON-Lines file") do |o|
      options[:output] = o
    end

    opts.on("--summary", "-s", "Show summary only") do
      options[:summary] = true
    end

    opts.on("-h", "--help", "Show this message") do
      puts opts
      exit
    end
  end

  begin
    parser.parse!(ARGV)
  rescue OptionParser::InvalidOption => e
    puts e.message
    puts parser
    exit 1
  end

  if ARGV.empty?
    puts "Error: No input files specified"
    puts parser
    exit 1
  end

  all_results = []

  if options[:jsonl]
    # JSON-Lines Modus
    ARGV.each do |input_path|
      results = process_jsonl_file(Pathname.new(input_path), repair: options[:repair])
      all_results.concat(results)
    end
  else
    # Standard JSON Batch
    file_paths = ARGV.map { |p| Pathname.new(p) }
    all_results = process_file_batch(
      file_paths,
      repair: options[:repair],
      max_workers: options[:workers]
    )
  end

  # Ausgabe
  successful = all_results.count(&:success)
  failed = all_results.size - successful

  if options[:summary]
    puts "Processed: #{all_results.size}"
    puts "Successful: #{successful}"
    puts "Failed: #{failed}"
  else
    all_results.each do |result|
      if result.success
        puts JSON.generate(result.data, ascii_only: false)
      else
        $stderr.puts "ERROR [#{result.source}]: #{result.error}"
      end
    end
  end

  # Optional: JSONL Output
  if options[:output]
    write_jsonl(all_results, Pathname.new(options[:output]), only_successful: false)
    $stderr.puts "\nResults written to: #{options[:output]}"
  end

  # Exit code
  exit(failed == 0 ? 0 : 1)
end

if __FILE__ == $0
  main
end
