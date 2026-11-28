#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "0ad8b4bd118ebcf6bae83f4c0154e340612658c2bc0e68ceecf4700277a95f0b", "source_sha256": "fc2a08fec30e381e2f112d375f3c1136b4730cdaa58967167750a5dc9b65532d", "target_language": "ruby"}
# peak-limiter_4ced2c.css — portiert nach ruby
# Quelle: css, Projects@abstractions:css/peak-limiter_4ced2c.css
# Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

# Abstraction provenance: {"artifact_sha256": "c86160b4782bbdd4341a998965a2c305098b3c29f36c24b5c96324073afc4800", "source_sha256": "4ced2ca9b27b1be45a4172c7993a0693b54431a3a2703c30cb796b668ff34bc0", "target_language": "ruby"}
# peak-limiter.html — portiert nach ruby
# Quelle: html, Projects@vercel/install-and-configure-vercel-w-98sxlo:plugin-source/tests/peak-limiter.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

require 'optparse'

class CSSEmitter
  def initialize
    @rules = []
  end

  def add_rule(selector, properties)
    @rules << { selector: selector, properties: properties }
  end

  def to_css
    css_lines = []
    @rules.each do |rule|
      css_lines << "#{rule[:selector]} {"
      rule[:properties].each do |prop, value|
        css_lines << "  #{prop}: #{value};"
      end
      css_lines << "}"
      css_lines << ""
    end
    css_lines.join("\n")
  end
end

def generate_css
  emitter = CSSEmitter.new

  # body Regel
  emitter.add_rule("body", {
    "font" => "16px system-ui",
    "max-width" => "1000px",
    "margin" => "40px auto",
    "padding" => "20px"
  })

  # pre Regel
  emitter.add_rule("pre", {
    "white-space" => "pre-wrap"
  })

  # button Regel
  emitter.add_rule("button", {
    "padding" => "12px"
  })

  emitter.to_css
end

def main
  options = {}
  OptionParser.new do |opts|
    opts.banner = "Usage: #{$0} [options]"
    opts.on("-o", "--output FILE", "Ausgabedatei") do |file|
      options[:output] = file
    end
  end.parse!

  css_content = generate_css

  if options[:output]
    File.write(options[:output], css_content)
    puts "CSS wurde in #{options[:output]} geschrieben"
  else
    puts css_content
  end
end

main if __FILE__ == $0
