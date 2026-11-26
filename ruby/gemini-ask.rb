#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "4126973528a95d89d785083e425e1ce856d01df3b699c52494bafb4670fc649f", "source_sha256": "9411ee01f75190a7b3bf9f276fc6bb624d2c943629885c1ddfc9f71a0039070e", "target_language": "ruby"}
# gemini-ask.js — portiert nach ruby
# Quelle: javascript, OpenClaw@gateway1:scripts/gemini-ask.js
# auch in: OpenClaw@gateway2:scripts/gemini-ask.js
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# frozen_string_literal: true

# gemini-ask.rb - CLI tool for Google Gemini API
# 
# Usage:
#   ruby gemini-ask.rb "Your question here"
#   echo "Your question" | ruby gemini-ask.rb
#   ruby gemini-ask.rb --file prompt.txt
#   ruby gemini-ask.rb --model gemini-pro "Your question"
# 
# Environment:
#   GEMINI_API_KEY - Required API key
#   GEMINI_MODEL   - Optional default model (default: gemini-pro)

require 'json'
require 'net/http'
require 'uri'
require 'openssl'

DEFAULT_MODEL = ENV['GEMINI_MODEL'] || 'gemini-pro'

def main
  # Check API key
  if !ENV['GEMINI_API_KEY']
    STDERR.puts 'Error: GEMINI_API_KEY environment variable is required'
    exit 1
  end

  # Parse arguments
  prompt = ''
  model_name = DEFAULT_MODEL
  args = ARGV.dup
  
  # Check for --model flag
  model_index = args.index { |a| a == '--model' || a == '-m' }
  if model_index && args[model_index + 1]
    model_name = args[model_index + 1]
    args.delete_at(model_index + 1)
    args.delete_at(model_index)
  end

  # Check for --system flag (system prompt)
  system_prompt = ''
  system_index = args.index { |a| a == '--system' || a == '-s' }
  if system_index && args[system_index + 1]
    system_prompt = args[system_index + 1]
    args.delete_at(system_index + 1)
    args.delete_at(system_index)
  end

  if args.include?('--file') || args.include?('-f')
    file_index = args.index { |a| a == '--file' || a == '-f' }
    file_path = args[file_index + 1]
    if !file_path
      STDERR.puts 'Error: No file specified'
      exit 1
    end
    prompt = File.read(file_path, encoding: 'UTF-8')
    # Remove --file and path from args
    args.delete_at(file_index + 1)
    args.delete_at(file_index)
  elsif args.length > 0
    prompt = args.join(' ')
  elsif !STDIN.tty?
    # Read from stdin
    prompt = STDIN.read
  end

  if prompt.strip.empty?
    STDERR.puts 'Error: No prompt provided'
    STDERR.puts 'Usage: gemini-ask "your question"'
    STDERR.puts '       gemini-ask --model gemini-pro "your question"'
    STDERR.puts '       echo "your question" | gemini-ask'
    exit 1
  end

  begin
    api_key = ENV['GEMINI_API_KEY']
    
    # Prepare generation config
    generation_config = {
      maxOutputTokens: 8192,
      temperature: 0.7,
      topP: 0.95,
    }.to_json

    if !system_prompt.empty?
      # Use chat with system prompt
      url = "https://generativelanguage.googleapis.com/v1beta/models/#{model_name}:generateContent?key=#{api_key}"
      
      body = {
        contents: [
          { role: 'user', parts: [{ text: system_prompt }] },
          { role: 'model', parts: [{ text: 'Understood. I will follow that instruction.' }] },
          { role: 'user', parts: [{ text: prompt }] }
        ],
        generationConfig: JSON.parse(generation_config)
      }.to_json
      
      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/json'
      request.body = body
      
      response = http.request(request)
      
      if response.code != '200'
        raise "API request failed with status #{response.code}: #{response.body}"
      end
      
      data = JSON.parse(response.body)
      text = data.dig('candidates', 0, 'content', 'parts', 0, 'text')
    else
      # Direct generation
      url = "https://generativelanguage.googleapis.com/v1beta/models/#{model_name}:generateContent?key=#{api_key}"
      
      body = {
        contents: [{ role: 'user', parts: [{ text: prompt }] }],
        generationConfig: JSON.parse(generation_config)
      }.to_json
      
      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/json'
      request.body = body
      
      response = http.request(request)
      
      if response.code != '200'
        raise "API request failed with status #{response.code}: #{response.body}"
      end
      
      data = JSON.parse(response.body)
      text = data.dig('candidates', 0, 'content', 'parts', 0, 'text')
    end
    
    puts text
  rescue StandardError => e
    STDERR.puts "Error: #{e.message}"
    if e.message.include?('API key')
      STDERR.puts 'Make sure GEMINI_API_KEY is set correctly'
    end
    exit 1
  end
end

main if __FILE__ == $0
