#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "187c2d588b392249dac6229dcf678aa9c9847450586210cbd33068f8ec47117d", "source_sha256": "4112b3dbe78c8a495b73f6feaebe05ada553911d2e25f6bd1e2e4d704a6ac1b6", "target_language": "ruby"}
# generate-elevenlabs.mjs — portiert nach ruby
# Quelle: javascript, Onboarding@main:scripts/generate-elevenlabs.mjs
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

require 'net/http'
require 'uri'
require 'json'
require 'fileutils'

key = ENV['ELEVENLABS_API_KEY']
voice_id = ENV['ELEVENLABS_VOICE_ID'] || 'JBFqnCBsd6RMkjVDRZzb'

raise 'ELEVENLABS_API_KEY fehlt.' unless key

text = 'Neun Projekte. Zwei Plattformen. Ein Ort, an dem Ideen verbunden und weiterentwickelt werden.'

uri = URI("https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}?output_format=mp3_44100_128")

http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true

request = Net::HTTP::Post.new(uri)
request['xi-api-key'] = key
request['Content-Type'] = 'application/json'

request.body = JSON.dump({
  text: text,
  model_id: 'eleven_multilingual_v2',
  voice_settings: {
    stability: 0.58,
    similarity_boost: 0.72,
    style: 0.18,
    use_speaker_boost: true
  }
})

response = http.request(request)

raise "ElevenLabs fehlgeschlagen: #{response.code}" unless response.code == '200'

# Create directories
FileUtils.mkdir_p('../public/audio/')
FileUtils.mkdir_p('../media-production/')

# Write audio file
File.open('../public/audio/project-narration.mp3', 'wb') do |file|
  file.write(response.body)
end

# Write JSON result
result_data = {
  model: 'eleven_multilingual_v2',
  voiceId: voice_id,
  characters: text.length,
  text: text,
  output: 'public/audio/project-narration.mp3'
}

File.open('../media-production/elevenlabs-result.json', 'w') do |file|
  file.write(JSON.pretty_generate(result_data))
end

puts "ElevenLabs abgeschlossen: #{text.length} Zeichen."
