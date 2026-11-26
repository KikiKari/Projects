#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "6c662c464703fbc14b46ca6757487f96dfa46272b93ce83a675e410e88f6dd3e", "source_sha256": "3fed8b6be2b9b8639b55bcaf18c09c0395ac005ab02c27f2dff26ca20b5d5825", "target_language": "ruby"}
# generate-wavespeed.mjs — portiert nach ruby
# Quelle: javascript, Onboarding@main:scripts/generate-wavespeed.mjs
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

require 'json'
require 'net/http'
require 'uri'
require 'base64'
require 'fileutils'

# Prüfe ob API-Key gesetzt ist
key = ENV['WAVESPEED_API_KEY']
raise "WAVESPEED_API_KEY fehlt." unless key

# Lade Job-Liste
jobs_file = File.join(__dir__, '..', 'media-production', 'wavespeed-jobs.json')
jobs = JSON.parse(File.read(jobs_file))

# Pfade definieren
raw_dir = File.join(__dir__, '..', 'media-production', 'raw')
public_dir = File.join(__dir__, '..', 'public', 'media')
result_url = File.join(__dir__, '..', 'media-production', 'wavespeed-results.json')

# Verzeichnisse erstellen
FileUtils.mkdir_p(raw_dir)
FileUtils.mkdir_p(public_dir)

# Log laden oder initialisieren
log = File.exist?(result_url) ? JSON.parse(File.read(result_url)) : []

# Jobs verarbeiten
jobs.each do |job|
  raw_path = File.join(raw_dir, "#{job['id']}.png")
  target_path = File.join(public_dir, "#{job['output']}.png")
  
  # Prüfe ob bereits generiert
  if File.exist?(raw_path)
    unless log.any? { |entry| entry['id'] == job['id'] }
      log_entry = {
        'id' => job['id'],
        'requestId' => 'completed-before-resume',
        'model' => 'google/nano-banana-2/edit',
        'resolution' => '4k',
        'plannedCostUsd' => 0.14,
        'output' => File.basename(target_path)
      }
      log << log_entry
      File.write(result_url, JSON.pretty_generate(log))
    end
    puts "Übersprungen: #{job['id']} ist bereits vorhanden."
    next
  end
  
  # Bilder laden
  images = job['images'].map do |image|
    if image.match(/^https?:|^data:/)
      image
    else
      file_path = File.join(__dir__, '..', image)
      bytes = File.binread(file_path)
      encoded = Base64.strict_encode64(bytes)
      "data:image/png;base64,#{encoded}"
    end
  end
  
  # Request vorbereiten
  uri = URI('https://api.wavespeed.ai/api/v3/google/nano-banana-2/edit')
  request = Net::HTTP::Post.new(uri)
  request['Authorization'] = "Bearer #{key}"
  request['Content-Type'] = 'application/json'
  
  body = {
    'prompt' => job['prompt'],
    'images' => images,
    'aspect_ratio' => job['aspectRatio'],
    'resolution' => '4k',
    'output_format' => 'png',
    'enable_web_search' => false,
    'enable_image_search' => false,
    'enable_sync_mode' => false,
    'enable_base64_output' => false
  }
  
  request.body = JSON.generate(body)
  
  # Request senden
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  response = http.request(request)
  
  unless response.code.to_i.between?(200, 299)
    detail = response.body
    raise "WaveSpeed submit fehlgeschlagen: #{response.code} #{detail}"
  end
  
  submitted = JSON.parse(response.body)
  request_id = submitted.dig('data', 'id') || submitted['id']
  
  # Result abfragen
  result = nil
  90.times do
    sleep(4)
    poll_uri = URI("https://api.wavespeed.ai/api/v3/predictions/#{request_id}/result")
    poll_request = Net::HTTP::Get.new(poll_uri)
    poll_request['Authorization'] = "Bearer #{key}"
    
    poll_http = Net::HTTP.new(poll_uri.host, poll_uri.port)
    poll_http.use_ssl = true
    poll_response = poll_http.request(poll_request)
    
    result = JSON.parse(poll_response.body)
    break if result.dig('data', 'status') == 'completed'
    raise "WaveSpeed job fehlgeschlagen: #{job['id']}" if result.dig('data', 'status') == 'failed'
  end
  
  # Output URL extrahieren
  url = result.dig('data', 'outputs', 0)
  raise "Kein Output für #{job['id']}" unless url
  
  # Bilddaten herunterladen
  image_uri = URI(url)
  image_http = Net::HTTP.new(image_uri.host, image_uri.port)
  image_http.use_ssl = true
  image_response = image_http.get(image_uri.path)
  bytes = image_response.body
  
  # Dateien schreiben
  File.binwrite(raw_path, bytes)
  File.binwrite(target_path, bytes)
  
  # Log aktualisieren
  log_entry = {
    'id' => job['id'],
    'requestId' => request_id,
    'model' => 'google/nano-banana-2/edit',
    'resolution' => '4k',
    'plannedCostUsd' => 0.14,
    'output' => File.basename(target_path)
  }
  log << log_entry
  File.write(result_url, JSON.pretty_generate(log))
  
  puts "Abgeschlossen: #{job['id']}"
end

# Finale Aktualisierung
File.write(result_url, JSON.pretty_generate(log))
total_cost = log.length * 0.14
puts "WaveSpeed abgeschlossen: #{log.length} Assets, geplante Basiskosten $#{"%.2f" % total_cost}."
