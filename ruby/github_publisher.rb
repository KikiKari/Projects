#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "a4521a78270d91e6cf900779f5edc65657cd1d62c159f2ae68751a0dc487c44d", "source_sha256": "dfe62418dcbef9ea8aa7f18ada4f57d0ef73593432b7c7cefd85ee87eee622b4", "target_language": "ruby"}
# github_publisher.py — portiert nach ruby
# Quelle: python, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/github_publisher.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

require 'base64'
require 'digest'
require 'json'
require 'net/http'
require 'open3'
require 'pathname'
require 'tempfile'
require 'uri'

LANGUAGES = %w[perl5 powershell perl6 tcl javascript ruby python lua shell go java c cpp php fsharp css].freeze

def synchronize_checkout(root, remote: 'https://github.com/KikiKari/OpenClaw.git', branch: 'gateway1-abstractions')
  # Reconcile a remote snapshot into the checkout without changing its Git history.
  root_path = Pathname.new(root).expand_path
  raise ArgumentError, 'Root path does not exist' unless root_path.directory?

  Dir.mktmpdir('abstractions-snapshot-') do |tmp|
    snapshot = Pathname.new(tmp) / 'repo'
    
    # Clone repository
    clone_cmd = [
      'git', 'clone', '--quiet', '--depth=1', '--single-branch',
      '--branch', branch, '--', remote, snapshot.to_s
    ]
    
    stdin, stdout, stderr, wait_thr = Open3.popen3(*clone_cmd)
    stdin.close
    stdout.close
    stderr.close
    
    unless wait_thr.value.success?
      raise RuntimeError, 'Failed to clone repository'
    end
    
    # Get revision
    revision = `git -C #{snapshot.to_s} rev-parse HEAD`.strip
    raise 'Failed to get revision' if $?.exitstatus != 0
    
    counts = {}
    
    LANGUAGES.sort.each do |language|
      source = snapshot / language
      target = root_path / language
      
      # Check for symlinks
      if source.symlink? || target.symlink?
        raise ArgumentError, 'Language directory is a symlink'
      end
      
      if source.exist? && !source.directory?
        raise ArgumentError, 'Invalid remote language directory'
      end
      
      target.mkpath unless target.exist?
      
      # Get known file hashes
      known = Set.new
      target.children.select(&:file?).reject(&:symlink?).each do |p|
        known.add(Digest::SHA256.file(p).hexdigest)
      end
      
      files = source.exist? ? source.children : []
      
      # Validate files
      if files.any? { |p| p.symlink? || !p.file? }
        raise ArgumentError, 'Invalid remote abstraction'
      end
      
      counts[language] = files.length
      
      files.each do |item|
        data = File.binread(item)
        digest = Digest::SHA256.hexdigest(data)
        
        next if known.include?(digest)
        
        destination = target / item.basename
        if destination.exist? || destination.symlink?
          destination = target / "#{item.basename('.*')}_pool_#{digest}#{item.extname}"
        end
        
        begin
          File.open(destination, 'wb') { |f| f.write(data) }
        rescue Errno::EEXIST
          if destination.symlink? || !destination.file? || File.binread(destination) != data
            raise ArgumentError, 'Local abstraction conflict'
          end
        end
        
        known.add(digest)
      end
    end
    
    return revision, counts
  end
end

def update_status_counts(path, revision, counts)
  text = File.read(path, encoding: 'UTF-8')
  
  rows = [
    '## Bestand',
    '',
    "GitHub-Stand: `#{revision}`",
    '',
    '| Zielsprache | Dateien |',
    '|---|---:|'
  ]
  
  LANGUAGES.sort.each do |language|
    rows << "| #{language} | #{counts[language]} |"
  end
  
  rows.concat([
    "| **gesamt** | **#{counts.values.sum}** |",
    '',
    ''
  ])
  
  updated = text.gsub(/(?m)^## Bestand\n.*?(?=^## Quellen\n)/) { rows.join("\n") }
  
  if text == updated
    raise ArgumentError, 'Status inventory section missing'
  end
  
  File.write(path, updated, encoding: 'UTF-8')
end

def queue_artifact(state, root, path)
  root_path = Pathname.new(root).expand_path
  path_obj = Pathname.new(path)
  
  if path_obj.symlink?
    raise ArgumentError, 'Artifact must not be a symlink'
  end
  
  resolved_path = path_obj.expand_path
  relative = resolved_path.relative_path_from(root_path)
  
  if relative.to_s != 'STATUS.md' && (relative.parts.empty? || !LANGUAGES.include?(relative.parts.first))
    raise ArgumentError, 'Artifact is outside a language directory'
  end
  
  state['ausstehende_veroeffentlichungen'] ||= {}
  data = File.binread(path)
  state['ausstehende_veroeffentlichungen'][relative.to_s] = Digest::SHA256.hexdigest(data)
end

def publish_pending(root, state, save_proc, token, opener: nil, sync: nil)
  pending = state['ausstehende_veroeffentlichungen'] || {}
  
  unless pending.is_a?(Hash)
    raise ArgumentError, 'Invalid publication queue'
  end
  
  return true if pending.empty? && sync.nil?
  
  return false if !token || token.strip.empty?
  
  root_path = Pathname.new(root).expand_path
  headers = {
    'Authorization' => "Bearer #{token.strip}",
    'Accept' => 'application/vnd.github+json',
    'X-GitHub-Api-Version' => '2022-11-28',
    'User-Agent' => 'abstractions-manager'
  }
  
  success = true
  entries = pending.sort_by { |k, _| k == 'STATUS.md' ? 0 : 1 }
  synced = false
  
  entries.each do |name, expected|
    begin
      path = root_path / name
      
      if path.symlink? || path.expand_path.relative_path_from(root_path).to_s != name
        raise ArgumentError, 'Invalid queued path'
      end
      
      data = File.binread(path)
      if Digest::SHA256.hexdigest(data) != expected
        raise ArgumentError, 'Queued artifact changed'
      end
      
      if name == 'STATUS.md' && sync
        if !success
          raise ArgumentError, 'Artifact publication incomplete'
        end
        
        revision, counts = sync.call(root_path)
        synced = true
        update_status_counts(path, revision, counts)
        data = File.binread(path)
        expected = Digest::SHA256.hexdigest(data)
        pending[name] = expected
        save_proc.call(state)
      end
      
      lookup = lambda do |remote_name|
        endpoint = "https://api.github.com/repos/KikiKari/OpenClaw/contents/#{URI.encode_www_form_component(remote_name)}"
        uri = URI("#{endpoint}?ref=gateway1-abstractions")
        
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        request = Net::HTTP::Get.new(uri)
        headers.each { |k, v| request[k] = v }
        
        begin
          response = http.request(request)
          [endpoint, JSON.parse(response.body)]
        rescue Net::HTTPError => e
          if e.response.code.to_i == 404
            [endpoint, nil]
          else
            raise
          end
        end
      end
      
      same = lambda do |existing|
        existing.is_a?(Hash) &&
          existing['encoding'] == 'base64' &&
          Base64.decode64(existing['content']) == data
      end
      
      endpoint, existing = lookup.call(name)
      
      if name == 'STATUS.md' && existing && !same.call(existing)
        sha = existing['sha'] if existing.is_a?(Hash)
        if !sha.is_a?(String) || sha.empty?
          raise ArgumentError, 'Missing remote status version'
        end
        
        body = {
          'message' => 'Update abstraction status',
          'branch' => 'gateway1-abstractions',
          'content' => Base64.encode64(data).delete("\n"),
          'sha' => sha
        }.to_json
        
        uri = URI(endpoint)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        request = Net::HTTP::Put.new(uri, headers)
        request.body = body
        
        response = http.request(request)
        JSON.parse(response.body)
      elsif existing && !same.call(existing)
        # Independent managers can derive different results for one
        # source. Preserve both without overwriting the remote file.
        candidate = Pathname.new(name)
        alternate = (candidate.dirname / "#{candidate.basename('.*').to_s}_#{expected[0..11]}#{candidate.extname}").to_s
        endpoint, existing = lookup.call(alternate)
        
        if existing && !same.call(existing)
          raise ArgumentError, 'Remote artifact conflict'
        end
      end
      
      if existing.nil?
        body = {
          'message' => 'Publish script abstraction',
          'branch' => 'gateway1-abstractions',
          'content' => Base64.encode64(data).delete("\n")
        }.to_json
        
        uri = URI(endpoint)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        request = Net::HTTP::Put.new(uri, headers)
        request.body = body
        
        response = http.request(request)
        JSON.parse(response.body)
      end
      
      pending.delete(name)
      save_proc.call(state)
    rescue StandardError => e
      success = false
    end
  end
  
  if sync && !synced
    begin
      sync.call(root_path)
    rescue StandardError
      success = false
    end
  end
  
  success
end
