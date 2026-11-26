#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "b5d1038e0f06e3703761622613bbdcc8af30c7023daba61a9bb28cf678b5573b", "source_sha256": "fecaa7522aec9008996f5664c745893f7fb7a2a4a3134a9f2855acde7f79596c", "target_language": "ruby"}
# extract-tiktok-streamlink.sh — portiert nach ruby
# Quelle: shell, OpenClaw@gateway2:skills/tiktok-live-mon/scripts/extraction-methods/extract-tiktok-streamlink.sh
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

require 'json'
require 'time'

# Bounded fallback used by the enhanced extractor. Output is normalized again
# by tiktok-get-stream.js; standalone success must remain URL-only unless
# --json is requested. Exit 75 means preflight overload.
def emit_json(*args)
  keys = %w[success method username url quality author title error timestamp status]
  payload = {}
  keys.zip(args) do |key, value|
    payload[key] = value unless value.nil? || value.empty?
  end
  payload['success'] = payload['success'].to_s.downcase == 'true' if payload.key?('success')
  puts JSON.generate(payload)
end

def fail_with_message(message, status, exit_code)
  emit_json('false', 'streamlink', @username, '', @quality, '', '', message, @timestamp, status)
  exit exit_code
end

@username = ARGV[0]&.gsub(/^@/, '') || ''
@quality = ARGV[1] || 'best'
@json_flag = ARGV[2] || ''
@timestamp = Time.now.utc.strftime('%Y-%m-%dT%H:%M:%SZ')

unless @username.match?(/^[A-Za-z0-9._]{1,24}$/)
  STDERR.puts 'Invalid TikTok username'
  exit 64
end

unless @quality.match?(/^(best|worst|original|1080p60|720p60|720p|540p|360p|auto)$/)
  STDERR.puts 'Invalid stream quality'
  exit 64
end

load_per_cpu = `ruby -e 'puts #{`cat /proc/loadavg`.split[0].to_f} / [1, #{`nproc`.to_i}].max'`.to_f
max_load = (ENV['TIKTOK_MAX_LOAD_PER_CPU'] || '1.5').to_f

if load_per_cpu > max_load
  emit_json('false', 'streamlink', @username, '', @quality, '', '', 'host overloaded', @timestamp, 'overloaded')
  exit 75
end

unless system('which streamlink > /dev/null 2>&1')
  emit_json('false', 'streamlink', @username, '', @quality, '', '', 'streamlink not installed', @timestamp, 'dependency_missing')
  exit 2
end

live_url = "https://www.tiktok.com/@#{@username}/live"
selector = case @quality
           when 'original' then 'origin,uhd_60,hd_60,hd,sd,ld,best,worst'
           when 'auto' then 'best,origin,uhd_60,hd_60,hd,sd,ld,worst'
           when '1080p60' then 'uhd_60,hd_60,hd,sd,ld,worst'
           when '720p60' then 'hd_60,hd,sd,ld,worst'
           when '720p' then 'hd,sd,ld,worst'
           when '540p' then 'sd,ld,worst'
           when '360p' then 'ld,worst'
           else @quality
           end

output = `streamlink --json "#{live_url}" "#{selector}" 2>/dev/null`
exit_code = $?.exitstatus

if exit_code != 0 || output.strip.empty?
  url = `streamlink --stream-url "#{live_url}" "#{selector}" 2>/dev/null`.strip
  if $?.exitstatus != 0 || url.empty?
    emit_json('false', 'streamlink', @username, '', @quality, '', '', 'streamlink failed or no stream found', @timestamp, 'offline')
    exit 1
  end
  if @json_flag == '--json'
    emit_json('true', 'streamlink', @username, url, @quality, '', '', '', @timestamp, 'live')
  else
    puts url
  end
  exit 0
end

begin
  data = JSON.parse(output)
  url = data['url'] || ''
  streams = data['streams'] || {}
  
  if url.empty? && streams.is_a?(Hash)
    %w[best worst].each do |key|
      if streams.key?(key) && streams[key].is_a?(Hash) && streams[key]['url']
        url = streams[key]['url']
        break
      end
    end
    
    streams.each do |key, value|
      if value.is_a?(Hash) && value['url']
        url = value['url']
        break
      end
    end
  end
  
  metadata = data['metadata'] || {}
  author = metadata['author'] || ''
  title = metadata['title'] || ''
  
  parsed_data = { 'url' => url, 'author' => author, 'title' => title }
rescue JSON::ParserError
  emit_json('false', 'streamlink', @username, '', @quality, '', '', 'invalid streamlink JSON', @timestamp, 'technical_error')
  exit 2
end

url = parsed_data['url']
author = parsed_data['author']
title = parsed_data['title']

if url.empty?
  emit_json('false', 'streamlink', @username, '', @quality, author, title, 'could not extract stream URL', @timestamp, 'offline')
  exit 1
end

if @json_flag == '--json'
  emit_json('true', 'streamlink', @username, url, @quality, author, title, '', @timestamp, 'live')
else
  puts url
end
