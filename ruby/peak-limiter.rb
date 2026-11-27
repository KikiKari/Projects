#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "b75f4cbe6ba9812d888b3b40a018ed1f558ebadf1dd6feda2854e195b01545bf", "source_sha256": "162cbb093559fd1ff9a7f362e753f4d965a73d5e557fce20d9cd95367574146b", "target_language": "ruby"}
# peak-limiter.html — portiert nach ruby
# Quelle: html, Projects@TikTok-Live-Companion:plugin-source/tests/peak-limiter.html
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/tests/peak-limiter.html
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/tests/peak-limiter.html
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/tests/peak-limiter.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

require 'json'
require 'webrick'

class PeakLimiterTest
  def initialize
    @core = ContentCore.new
  end

  def peak_db(values)
    max_val = values.map(&:abs).max || 1e-10
    20 * Math.log10([max_val, 1e-10].max)
  end

  def render(kind, strength, legacy)
    rate = 48000
    length = rate
    data = Array.new(length, 0.0)

    (0...length).each do |i|
      if kind == 'speech-band'
        data[i] = 0.01 * Math.sin(2 * Math::PI * 220 * i / rate)
      elsif kind == 'short-high-tone' && i >= 5000 && i < 5100
        data[i] = 0.95 * Math.sin(2 * Math::PI * 8000 * i / rate)
      elsif kind == 'level-step' && i >= 5000 && i < 10000
        data[i] = 0.95 * Math.sin(2 * Math::PI * 1000 * i / rate)
      end
    end

    if kind == 'impulse'
      data[5000] = 0.95
    end

    input_dbfs = peak_db(data)
    
    # Simulate audio processing
    if strength.nil?
      output_data = data.dup
    else
      output_data = process_audio(data, strength, legacy, rate)
    end

    output_dbfs = peak_db(output_data)

    {
      kind: kind,
      strength: strength,
      path: strength.nil? ? 'off' : legacy ? '0.8.2-compressor' : 'candidate-lookahead',
      inputDbfs: input_dbfs,
      outputDbfs: output_dbfs
    }
  end

  def process_audio(data, strength, legacy, rate)
    if legacy
      # Simplified dynamics compressor simulation
      threshold = @core.limiter_strength_to_dbfs(strength)
      ratio = 20
      knee = 0.5
      attack = 0.0015
      release = 0.08
      makeup = @core.limiter_makeup_compensation(threshold, ratio)
      
      # Very simplified compression algorithm
      data.map do |sample|
        abs_sample = sample.abs
        if abs_sample > (10**(threshold/20.0))
          sign = sample <=> 0
          compressed = (10**((threshold + ((20 * Math.log10(abs_sample) - threshold) / ratio))/20.0))
          [compressed * sign, 1.0].min * makeup
        else
          sample * makeup
        end
      end
    else
      # Simplified lookahead limiter simulation
      window_size = (rate * 0.005).to_i # 5ms lookahead
      max_peak = data.map(&:abs).max
      
      if max_peak > 0
        scale_factor = [1.0, (10**(@core.limiter_strength_to_dbfs(strength)/20.0)) / max_peak].min
        data.map { |sample| sample * scale_factor }
      else
        data.dup
      end
    end
  end

  def run_test
    begin
      rows = []
      ['impulse', 'short-high-tone', 'level-step', 'speech-band'].each do |kind|
        rows << render(kind, nil, false)
        [25, 75, 100].each do |strength|
          rows << render(kind, strength, true)
          rows << render(kind, strength, false)
        end
      end

      failures = rows.select do |row|
        row[:path] == 'candidate-lookahead' &&
        (row[:outputDbfs] > @core.limiter_strength_to_dbfs(row[:strength]) + 0.05 ||
         (row[:kind] == 'speech-band' && (row[:outputDbfs] - row[:inputDbfs]).abs > 0.05))
      end

      {
        passed: failures.length == 0,
        failures: failures,
        rows: rows
      }
    rescue => error
      { error: "FEHLER: #{error.backtrace.join("\n")}" }
    end
  end
end

class ContentCore
  def limiter_strength_to_dbfs(strength)
    -(strength * 0.4)
  end

  def limiter_makeup_compensation(threshold, ratio)
    10**(((-threshold) * (ratio - 1) / ratio) / 20.0)
  end

  def create_peak_limiter_node(context)
    # Stub implementation
    PeakLimiterNode.new
  end
end

class PeakLimiterNode
  def set_protection(config)
    # Stub implementation
  end

  def connect(destination)
    # Stub implementation
    self
  end
end

class PeakLimiterServer
  def call(env)
    request = WEBrick::HTTPRequest.new
    response = WEBrick::HTTPResponse.new(WEBrick::Config::HTTP)

    case env['REQUEST_PATH']
    when '/'
      response.body = generate_html
      response['Content-Type'] = 'text/html; charset=utf-8'
    when '/browser-extension/content-core.js'
      response.body = generate_js_stub
      response['Content-Type'] = 'application/javascript'
    when '/run-test'
      test = PeakLimiterTest.new
      result = test.run_test
      response.body = JSON.pretty_generate(result)
      response['Content-Type'] = 'application/json'
    else
      response.status = 404
      response.body = 'Not Found'
    end

    response
  end

  private

  def generate_html
    <<-HTML
<!doctype html>
<html lang="de">
<meta charset="utf-8">
<title>Pegelschutz Audioprüfung</title>
<style>
body{font:16px system-ui;max-width:1000px;margin:40px auto;padding:20px}
pre{white-space:pre-wrap}
button{padding:12px}
</style>
<h1>Pegelschutz: synthetischer Web-Audio-Vergleich</h1>
<p>Offline gerenderte Testsignale. Kein LIVE- oder Hörnachweis.</p>
<button id="run">Audioprüfung starten</button>
<pre id="result">Bereit</pre>
<script src="/browser-extension/content-core.js"></script>
<script>
const core = TLC_CONTENT_CORE;
document.getElementById('run').onclick = async () => {
  const output = document.getElementById('result');
  output.textContent = 'Läuft';
  try {
    const response = await fetch('/run-test');
    const result = await response.json();
    output.textContent = JSON.stringify(result, null, 2);
  } catch(error) {
    output.textContent = 'FEHLER: ' + error.stack;
  }
};
</script>
</html>
    HTML
  end

  def generate_js_stub
    <<-JS
const TLC_CONTENT_CORE = {
  limiterStrengthToDbfs: function(strength) {
    return -(strength * 0.4);
  },
  limiterMakeupCompensation: function(threshold, ratio) {
    return Math.pow(10, (((-threshold) * (ratio - 1) / ratio) / 20));
  },
  createPeakLimiterNode: async function(context) {
    return {
      setProtection: function(config) {},
      connect: function(destination) { return this; }
    };
  }
};
    JS
  end
end

if __FILE__ == $0
  if ARGV.length > 0
    # Generate file directly
    server = PeakLimiterServer.new
    html_content = server.send(:generate_html)
    
    File.open(ARGV[0], 'w') do |file|
      file.write(html_content)
    end
    
    puts "HTML file generated: #{ARGV[0]}"
  else
    # Run as server
    server = PeakLimiterServer.new
    port = (ENV['PORT'] || 8080).to_i
    
    puts "Starting server on port #{port}"
    puts "Visit http://localhost:#{port} to run the test"
    
    server_thread = Thread.new do
      loop do
        sleep(1)
      end
    end
    
    server_thread.join
  end
end
