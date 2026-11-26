#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "37a3d3c6e7e54d47863640821bd36808488a6e49242b66436ed16bdc48906e76", "source_sha256": "b00f64d55d344bbcc351ae7ade12137f0d9293b556aa0881ede43bef5bcb778b", "target_language": "ruby"}
# extract-tiktok-yt-dlp.sh — portiert nach ruby
# Quelle: shell, OpenClaw@gateway2:skills/tiktok-live-mon/scripts/extraction-methods/extract-tiktok-yt-dlp.sh
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# Bounded fallback used by the enhanced extractor. Temporary files are cleaned
# on every exit and output is normalized again by tiktok-get-stream.js.
# Standalone overload exits 75 before yt-dlp starts.

require 'json'
require 'tempfile'
require 'open3'
require 'securerandom'

def emit_json(success, method, username, url, format, error, timestamp, status)
  payload = {
    'success' => success,
    'method' => method,
    'username' => username,
    'url' => url,
    'format' => format,
    'error' => error,
    'timestamp' => timestamp,
    'status' => status
  }.reject { |_, v| v.nil? || v.empty? }
  
  payload['success'] = payload['success'].to_s.downcase == 'true' if payload.key?('success')
  puts JSON.generate(payload)
end

def run_python(code, *args)
  stdin, stdout, stderr, wait_thr = Open3.popen3('python3', '-c', code, *args)
  result = stdout.read.strip
  error = stderr.read
  status = wait_thr.value
  [result, error, status]
end

username = ARGV[0]&.gsub('@', '') || ''
format = ARGV[1] || 'best'
json_flag = ARGV[2] || ''
timestamp = Time.now.utc.strftime('%Y-%m-%dT%H:%M:%SZ')

tmp_dir = Dir.mktmpdir('tiktok-yt-dlp-')
at_exit { FileUtils.rm_rf(tmp_dir) }

unless username.match?(/^[A-Za-z0-9._]{1,24}$/)
  STDERR.puts "Invalid TikTok username"
  exit 64
end

valid_formats = [
  'hls-origin/hls-pull/hls-uhd_60/hls-hd_60/hls-hd/hls-sd/hls-ld/flv-origin/flv-hd/flv-ld',
  'hls-uhd_60/hls-hd_60/hls-hd/hls-sd/hls-ld/flv-hd/flv-ld',
  'hls-hd_60/hls-hd/hls-sd/hls-ld/flv-hd/flv-ld',
  'hls-hd/hls-sd/hls-ld/flv-hd/flv-sd/flv-ld',
  'hls-sd/hls-ld/flv-sd/flv-ld',
  'hls-ld/flv-ld',
  'hls-origin/hls-hd/hls-sd/hls-ld/hls-pull/flv-origin/flv-hd/flv-ld'
]

unless valid_formats.include?(format)
  STDERR.puts "Invalid yt-dlp format"
  exit 64
end

load_per_cpu_result, _, _ = run_python('import os; print(os.getloadavg()[0] / max(1, os.cpu_count() or 1))')
load_per_cpu = load_per_cpu_result.to_f
max_load = ENV['TIKTOK_MAX_LOAD_PER_CPU']&.to_f || 1.5

if load_per_cpu > max_load
  emit_json(false, 'yt-dlp', username, '', format, 'host overloaded', timestamp, 'overloaded')
  STDERR.puts JSON.generate({
    'success' => false,
    'method' => 'yt-dlp',
    'username' => username,
    'url' => '',
    'format' => format,
    'error' => 'host overloaded',
    'timestamp' => timestamp,
    'status' => 'overloaded'
  })
  exit 75
end

unless system('command -v yt-dlp >/dev/null 2>&1')
  emit_json(false, 'yt-dlp', username, '', format, 'yt-dlp not installed', timestamp, 'dependency_missing')
  STDERR.puts JSON.generate({
    'success' => false,
    'method' => 'yt-dlp',
    'username' => username,
    'url' => '',
    'format' => format,
    'error' => 'yt-dlp not installed',
    'timestamp' => timestamp,
    'status' => 'dependency_missing'
  })
  exit 2
end

live_url = "https://www.tiktok.com/@#{username}/live"
stdout_file = File.join(tmp_dir, 'stdout.json')
stderr_file = File.join(tmp_dir, 'stderr.log')

exit_code = system("yt-dlp --no-warnings --dump-single-json --skip-download --format \"#{format}\" \"#{live_url}\" >\"#{stdout_file}\" 2>\"#{stderr_file}\"")

unless exit_code
  status = 'technical_error'
  code = 2
  
  if File.exist?(stderr_file)
    stderr_content = File.read(stderr_file)
    if stderr_content.match?(/not currently live|No live cdn found|not available|private video/i)
      status = 'offline'
      code = 1
    end
    
    error_message = stderr_content[0, 1000]
    emit_json(false, 'yt-dlp', username, '', format, error_message, timestamp, status)
    STDERR.puts JSON.generate({
      'success' => false,
      'method' => 'yt-dlp',
      'username' => username,
      'url' => '',
      'format' => format,
      'error' => error_message,
      'timestamp' => timestamp,
      'status' => status
    })
  end
  exit code
end

url = ''
if File.exist?(stdout_file)
  json_data = File.read(stdout_file)
  data = JSON.parse(json_data)
  
  candidates = []
  candidates << data['url'] if data['url'].is_a?(String)
  
  if data['formats'].is_a?(Array)
    data['formats'].each do |item|
      if item.is_a?(Hash) && item['url'].is_a?(String)
        candidates << item['url']
      end
    end
  end
  
  candidates.each do |value|
    low = value.downcase
    if value.start_with?('https://') && (low.include?('.m3u8') || low.include?('.flv')) && !low.include?('only_audio=1')
      url = value
      break
    end
  end
end

if url.empty?
  emit_json(false, 'yt-dlp', username, '', format, 'could not extract HTTPS video URL', timestamp, 'offline')
  STDERR.puts JSON.generate({
    'success' => false,
    'method' => 'yt-dlp',
    'username' => username,
    'url' => '',
    'format' => format,
    'error' => 'could not extract HTTPS video URL',
    'timestamp' => timestamp,
    'status' => 'offline'
  })
  exit 1
end

if json_flag == '--json'
  emit_json(true, 'yt-dlp', username, url, format, '', timestamp, 'live')
else
  puts url
end
