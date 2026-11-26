#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "ea9f3b8874c020cc382e779b4be9e3c29e877920081968db8d2c093df5abf3ed", "source_sha256": "748c0fc07a58caf07d4983d358cf0e1ce57c4e180b87ae617d598f53c61efcec", "target_language": "ruby"}
# dispatch_job.py — portiert nach ruby
# Quelle: python, OpenClaw@gateway1:skills/multi-nodes-utils/scripts/dispatch_job.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

require 'json'
require 'pathname'
require 'securerandom'
require 'open3'
require 'optparse'

# Arbeitsvolumen: Dateigröße × Anzahl der Zielsprachen.
def job_weight_bytes(script_path, target_langs_count)
  script_path.size * target_langs_count
end

# Node-Konfiguration
NODES = {
  "node1" => {"always_available" => true, "capacity" => "medium", "priority" => 3, "description" => "Gateway"},
  "node2" => {"always_available" => false, "capacity" => "high", "priority" => 1, "description" => "ARM Server"},
  "node3" => {"always_available" => false, "capacity" => "medium", "priority" => 4, "description" => "AMD Server"},
  "node4" => {"always_available" => false, "capacity" => "low", "priority" => 5, "device" => "Redmi Note 11S"},
  "node5" => {"always_available" => false, "capacity" => "high", "priority" => 2, "device" => "Lenovo"},
  "node6" => {"always_available" => false, "device" => "Lenovo (Docker)"},
}

NODE_NAMES = {
  "node2" => Set.new(["openclaw-node2", "arm64-node", "v2202604104722449961", "v2202604104722449961.taild25fea.ts.net", "100.82.198.122"]),
  "node3" => Set.new(["openclaw-node3", "openclaw-node3.taild25fea.ts.net", "100.73.154.125"]),
  "node4" => Set.new(["openclaw-node4", "redmi-note-11s", "redmi-note-11s.taild25fea.ts.net", "100.94.134.39"]),
  "node5" => Set.new(["openclaw-node5", "windows node (lenovo-7)"]),
  "node6" => Set.new(["openclaw-node6"]),
}

def fetch_node_status
  # Return mapped OpenClaw connection states; nil indicates lookup failure.
  begin
    stdout, stderr, status = Open3.capture3("openclaw", "nodes", "status", "--json", timeout: 10)
    
    unless status.success?
      return nil
    end
    
    payload = JSON.parse(stdout)
    
    unless payload.is_a?(Hash) && payload["nodes"].is_a?(Array)
      return nil
    end
    
    states = {}
    NODE_NAMES.each_key { |node| states[node] = false }
    
    payload["nodes"].each do |item|
      next unless item.is_a?(Hash)
      
      names = Set.new([
        item["displayName"].to_s.downcase,
        item["nodeId"].to_s.downcase,
        item["remoteIp"].to_s.downcase
      ])
      
      NODE_NAMES.each do |node, aliases|
        if !(names & aliases).empty? && item["connected"] == true
          states[node] = true
        end
      end
    end
    
    states["node1"] = true  # successful Gateway status request
    states
  rescue StandardError
    nil
  end
end

class JobDispatcher
  # Dispatches jobs to appropriate nodes based on weight
  
  def get_job_weight(script_path, target_langs_count = 1)
    # Bewertet Job-Gewicht
    return "medium" unless script_path.exist?
    
    total_work = job_weight_bytes(script_path, target_langs_count)
    
    if total_work > 50000  # > 50KB
      "heavy"
    elsif total_work > 10000  # > 10KB
      "medium"
    else
      "light"
    end
  end
  
  def select_node(job_weight)
    # Wählt besten Node basierend auf Job-Gewicht
    case job_weight
    when "heavy"
      preferred = ["node1", "node2", "node5", "node6"]
    when "medium"
      preferred = ["node1", "node2", "node3", "node6"]
    when "light"
      preferred = ["node2", "node1", "node3", "node4"]
    else
      raise ArgumentError, "Unknown job weight: #{job_weight}"
    end
    
    states = fetch_node_status()
    preferred.each do |node_id|
      if states && states[node_id]
        return node_id
      end
    end
    nil  # no verified reachable node
  end
  
  def check_node_available(node_id)
    # Use the live connection state rather than static availability.
    states = fetch_node_status()
    !!(states && states[node_id])
  end
  
  def execute_translation(job, transport)
    execute_translation_func(job, transport)
  end
  
  def check_mobile_online
    # Check Node4 (Redmi).
    check_node_available("node4")
  end
  
  def dispatch(job_script, target_langs = nil, source_text: nil, source_language: nil)
    # Dispatched Job und gibt Info zurück
    target_langs ||= ["perl5"]
    
    weight = get_job_weight(job_script, target_langs.length)
    selected_node = select_node(weight)
    translation_jobs = []
    
    target_langs.each do |language|
      job = {
        "job_id" => SecureRandom.uuid,
        "source" => job_script.to_s,
        "target_language" => language,
        "selected_node" => selected_node,
      }
      
      job["source_text"] = source_text if source_text
      job["source_language"] = source_language if source_language
      
      translation_jobs << job
    end
    
    {
      "job" => job_script.to_s,
      "weight" => weight,
      "selected_node" => selected_node,
      "target_langs" => target_langs,
      "translation_jobs" => translation_jobs,
      "status" => selected_node ? "selected" : "unavailable"
    }
  end
end

def execute_translation_func(job, transport)
  # Execute via a supplied transport and verify its result belongs to the job.
  if !job["selected_node"] || transport.nil?
    raise "no verified node or authorized translation transport"
  end
  
  response = transport.call(job)
  
  unless response.is_a?(Hash)
    raise "invalid transport response"
  end
  
  %w[job_id selected_node target_language].each do |key|
    if response[key] != job[key]
      raise "transport response does not match job"
    end
  end
  
  code = response["code"]
  if response["status"] != "ok" || !code.is_a?(String) || code.strip.empty?
    raise "translation did not complete with code"
  end
  
  code
end

def dispatch_abstraction_job(job_script, target_langs)
  # Erstellt eine Node-Auswahl und je (Skript, Sprache) einen Auftrag.
  dispatcher = JobDispatcher.new
  dispatcher.dispatch(job_script, target_langs)
end

def main
  options = {}
  OptionParser.new do |opts|
    opts.banner = "Usage: #{$0} [options]"
    
    opts.on("--job JOB", "-j", "Path to job script") do |job|
      options[:job] = job
    end
    
    opts.on("--langs LANGS", "-l", "Comma-separated target languages") do |langs|
      options[:langs] = langs
    end
    
    opts.on("--weight WEIGHT", "-w", %w[light medium heavy], "Force job weight") do |weight|
      options[:weight] = weight
    end
    
    opts.on("--execute", "-x", "Actually execute on selected node") do
      options[:execute] = true
    end
  end.parse!
  
  if !options[:job]
    puts "❌ Job argument is required"
    exit 1
  end
  
  job_path = Pathname.new(options[:job])
  unless job_path.exist?
    puts "❌ Job not found: #{job_path}"
    exit 1
  end
  
  dispatcher = JobDispatcher.new
  target_langs = options[:langs] ? options[:langs].split(",") : ["perl5"]
  
  # Determine weight
  weight = options[:weight] || dispatcher.get_job_weight(job_path, target_langs.length)
  
  # Select node
  selected_node = dispatcher.select_node(weight)
  
  # Output
  puts "📦 Job Dispatch Information"
  puts "=" * 50
  puts "Job: #{job_path}"
  puts "Size: #{job_path.size} bytes"
  puts "Target langs: #{target_langs.join(', ')}"
  puts "Job weight: #{weight}"
  puts "Selected node: #{selected_node}"
  puts "=" * 50
  
  if options[:execute]
    puts "\nTranslation dispatch on #{selected_node} is not implemented."
    exit 1
  else
    puts "\n💡 To execute: #{$0} --job #{options[:job]} --execute"
  end
  
  exit 0
end

if __FILE__ == $0
  main
end
