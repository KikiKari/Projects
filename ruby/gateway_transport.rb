#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "ee06d52d4d1180393a9d447739b47124521492f9c4065be0926ec55ea0a0c2b4", "source_sha256": "12c3ea0e67b1e873ac253df6f3f06d5ed42b603005d56186c531d8a5b0d7f377", "target_language": "ruby"}
# gateway_transport.py — portiert nach ruby
# Quelle: python, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/gateway_transport.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# Gateway-authenticated transport with manager-owned attempt records.
#
# An attempt is saved before submission. If its outcome is uncertain, subsequent
# calls only query the same node and attempt; they do not submit it again.

require 'json'
require 'uri'
require 'net/http'
require 'securerandom'
require 'pathname'

class TransportUnresolved < RuntimeError
end

def gateway_token
  # Use the local Gateway credential without changing its configuration.
  token = ENV['OPENCLAW_GATEWAY_TOKEN']&.strip
  return token if token && !token.empty?
  
  config_path = ENV['OPENCLAW_CONFIG_PATH']
  path = if config_path
           Pathname.new(config_path)
         else
           Pathname.new(Dir.home) / '.openclaw/openclaw.json'
         end
  
  begin
    config = JSON.parse(path.read(encoding: 'utf-8'))
    token = config.dig('gateway', 'auth', 'token')
    return '' unless token.is_a?(String) && !token.start_with?('${')
    token.strip
  rescue StandardError
    ''
  end
end

class GatewayTransport
  def initialize(state, save, url, token, timeout: 3900, interval: 3, 
                 opener: nil, clock: -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) }, 
                 sleep: ->(seconds) { Kernel.sleep(seconds) })
    @parsed = URI.parse(url)
    raise ArgumentError, 'invalid Gateway URL' unless %w[http https].include?(@parsed.scheme) && @parsed.host
    
    if @parsed.scheme == 'http' && !['127.0.0.1', 'localhost', '::1'].include?(@parsed.host)
      raise ArgumentError, 'unencrypted Gateway must use loopback'
    end
    
    raise ArgumentError, 'Gateway token and positive timeouts required' if !token || token.strip.empty? || timeout <= 0 || interval <= 0
    
    @state = state
    @save = save
    @url = url
    @token = token.strip
    @timeout = timeout
    @interval = interval
    @opener = opener || method(:default_opener)
    @clock = clock
    @sleep = sleep
  end
  
  private
  
  def default_opener(request, timeout: nil)
    uri = URI(request.uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    http.open_timeout = timeout
    http.read_timeout = timeout
    response = http.request(request)
    
    # Create a wrapper that mimics Python's response object
    Class.new do
      def initialize(response)
        @response = response
      end
      
      def read(max_length)
        body = @response.body || ''
        raise 'response too large' if body.length > max_length
        body
      end
    end.new(response)
  end
  
  def _request(node, request_data, device_id = nil)
    payload = {
      'node' => node,
      'device_id' => device_id,
      'request' => request_data
    }.to_json.force_encoding('utf-8')
    
    uri = URI(@url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    
    req = Net::HTTP::Post.new(uri.path)
    req['Authorization'] = "Bearer #{@token}"
    req['Content-Type'] = 'application/json'
    req.body = payload
    
    timeout = (node == 'node4') ? 150 : 40
    result = @opener.call(req, timeout: timeout)
    raw = result.read(4_000_001)
    
    raise ArgumentError, 'response too large' if raw.length > 4_000_000
    
    data = JSON.parse(raw)
    raise ArgumentError, 'invalid gateway response' unless data.is_a?(Hash) && data.key?('result')
    
    if device_id && data['device_id'] != device_id
      raise ArgumentError, 'gateway device identity mismatch'
    end
    
    data['result']
  rescue StandardError => error
    raise TransportUnresolved, 'Gateway request failed', error
  end
  
  public
  
  def available
    result = _request('node1', { 'operation' => 'availability' })
    raise TransportUnresolved, 'invalid node availability' unless result.is_a?(Hash)
    result
  end
  
  def _release(original, entry)
    return if entry['released']
    
    begin
      result = _request(
        original['selected_node'],
        {
          'operation' => 'release',
          'job_id' => original['job_id'],
          'attempt_id' => original['attempt_id']
        },
        original['selected_device_id']
      )
    rescue TransportUnresolved
      return # Retry cleanup later; the result is durable in manager state.
    end
    
    if result.is_a?(Hash) && result['status'] == 'released' &&
       %w[job_id attempt_id selected_node target_language].all? { |key| result[key] == original[key] }
      
      entry['released'] = true
      @save.call(@state)
    end
  end
  
  def release_pending
    (@state['auftraege'] || {}).each_value do |entry|
      if entry.is_a?(Hash) && %w[completed rejected failed].include?(entry['status']) && entry['job'].is_a?(Hash)
        _release(entry['job'], entry)
      end
    end
  end
  
  def reject(job, reason)
    # Record a completed response rejected by validation, before retrying it.
    key = "#{job['source_sha256']}:#{job['target_language']}"
    entry = (@state['auftraege'] || {})[key]
    
    return unless entry.is_a?(Hash) && entry['status'] == 'completed'
    
    if (entry.dig('job', 'attempt_id') || '') != (job['attempt_id'] || '')
      raise TransportUnresolved, 'rejected attempt identity mismatch'
    end
    
    entry['status'] = 'rejected'
    entry['validation_error'] = reason.to_s[0, 500]
    @save.call(@state)
  end
  
  def call(job)
    raise ArgumentError, 'missing source identity' unless job['source_sha256'] && job['target_language'] && job['selected_device_id']
    
    key = "#{job['source_sha256']}:#{job['target_language']}"
    @state['auftraege'] ||= {}
    entries = @state['auftraege']
    entry = entries[key]
    
    if entry.is_a?(Hash) && entry['status'] == 'rejected'
      _release(entry['job'], entry)
      
      unless entry['released']
        raise TransportUnresolved, 'rejected attempt release is unresolved'
      end
      
      previous = entry
      original = job.merge('attempt_id' => SecureRandom.uuid)
      entry = {
        'job' => original,
        'status' => 'submitted',
        'previous_attempts' => (previous['previous_attempts'] || []) + [{
          'job_id' => previous.dig('job', 'job_id'),
          'attempt_id' => previous.dig('job', 'attempt_id'),
          'selected_node' => previous.dig('job', 'selected_node'),
          'validation_error' => previous['validation_error']
        }]
      }
      entries[key] = entry
      @save.call(@state)
      fresh = true
    else
      fresh = entry.nil?
    end
    
    if entry.nil?
      original = job.merge('attempt_id' => SecureRandom.uuid)
      entry = { 'job' => original, 'status' => 'submitted' }
      entries[key] = entry
      # If this write fails there must be no remote submission.
      @save.call(@state)
    end
    
    original = entry['job']
    # The dispatcher verifies the job object after transport returns.
    job.update(original)
    
    return entry['response'] if entry['response']
    
    if entry['status'] == 'failed'
      raise TransportUnresolved, 'attempt requires reconciliation'
    end
    
    status = nil
    
    if fresh
      begin
        status = _request(
          original['selected_node'],
          { 'operation' => 'execute', 'job' => original },
          original['selected_device_id']
        )
      rescue TransportUnresolved
        # The request may have been accepted. Query, never resend.
      end
    end
    
    deadline = @clock.call + @timeout
    
    loop do
      if status.nil?
        status = _request(
          original['selected_node'],
          {
            'operation' => 'status',
            'job_id' => original['job_id'],
            'attempt_id' => original['attempt_id']
          },
          original['selected_device_id']
        )
      end
      
      raise TransportUnresolved, 'attempt is not known by the node' unless status.is_a?(Hash)
      
      %w[job_id attempt_id selected_node target_language].each do |k|
        if status[k] != original[k]
          raise TransportUnresolved, 'status identity mismatch'
        end
      end
      
      state = status['status']
      
      if state == 'completed'
        response = status['response']
        
        if !response.is_a?(Hash) || response['status'] != 'ok' ||
           %w[job_id selected_node target_language].any? { |k| response[k] != original[k] } ||
           !response['code'].is_a?(String) || response['code'].strip.empty?
          
          raise TransportUnresolved, 'invalid translation result'
        end
        
        entry['response'] = response
        entry['status'] = 'completed'
        @save.call(@state)
        _release(original, entry)
        return response
      end
      
      if %w[failed unknown].include?(state)
        entry['status'] = state
        @save.call(@state)
        _release(original, entry) if state == 'failed'
        raise TransportUnresolved, 'attempt requires reconciliation'
      end
      
      if state != 'running' || @clock.call >= deadline
        raise TransportUnresolved, 'attempt is unresolved'
      end
      
      @sleep.call(@interval)
      status = nil
    end
  end
end
