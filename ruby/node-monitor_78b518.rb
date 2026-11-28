#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "bace524f51608b7e576ea3d6fc96df1f7edb66115a4b6c62b1ed365d79ccccf6", "source_sha256": "78b518f6f68bf0f05a573239d113470b3f5a9440be7cff5f80bc8576462525c3", "target_language": "ruby"}
# node-monitor.css — portiert nach ruby
# Quelle: css, Projects@abstractions:css/node-monitor.css
# Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

# abstraction-provenance: {"artifact_sha256": "37bc702d7c4046193f78406172db9f9b81e5951260071773ee3519d55f802128", "source_sha256": "ed59efd19fa280b88488d50ce98f4213a84c5f833eacd98c7cb448f570c805fe", "target_language": "ruby"}
# node-monitor.html — portiert nach ruby
# Quelle: css, OpenClaw@main:examples/node-monitor.css
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

class CSSGenerator
  def initialize
    @variables = {
      '--bg' => '#0d1117',
      '--surface' => '#161b22',
      '--border' => '#30363d',
      '--text' => '#e6edf3',
      '--green' => '#3fb950',
      '--red' => '#f85149',
      '--accent' => '#58a6ff'
    }
  end

  def generate_css
    css = []
    
    # Root variables
    css << ":root {"
    @variables.each do |name, value|
      css << "  #{name}: #{value};"
    end
    css << "}"
    css << ""

    # Universal selector
    css << "* {"
    css << "  box-sizing: border-box;"
    css << "  margin: 0;"
    css << "  padding: 0;"
    css << "}"
    css << ""

    # Body styles
    css << "body {"
    css << "  background: var(--bg);"
    css << "  color: var(--text);"
    css << "  font-family: -apple-system, sans-serif;"
    css << "  padding: 1.5rem;"
    css << "}"
    css << ""

    # Heading styles
    css << "h1 {"
    css << "  color: var(--accent);"
    css << "  margin-bottom: 1rem;"
    css << "  font-size: 1.2rem;"
    css << "}"
    css << ""

    # Canvas styles
    css << "canvas {"
    css << "  display: block;"
    css << "  border: 1px solid var(--border);"
    css << "  border-radius: 8px;"
    css << "  background: var(--surface);"
    css << "}"
    css << ""

    # Log container styles
    css << "#log {"
    css << "  margin-top: 1rem;"
    css << "  height: 140px;"
    css << "  overflow-y: auto;"
    css << "  background: var(--surface);"
    css << "  border: 1px solid var(--border);"
    css << "  border-radius: 8px;"
    css << "  padding: .75rem;"
    css << "  font-size: .78rem;"
    css << "  font-family: monospace;"
    css << "  color: #8b949e;"
    css << "}"
    css << ""

    # Log error styles
    css << "#log .err {"
    css << "  color: var(--red);"
    css << "}"
    css << ""

    # Log ok styles
    css << "#log .ok {"
    css << "  color: var(--green);"
    css << "}"

    css.join("\n")
  end

  def write_to_file(filename)
    File.write(filename, generate_css)
  end
end

if __FILE__ == $0
  if ARGV.length != 1
    puts "Verwendung: #{$0} <ausgabedatei>"
    exit 1
  end

  generator = CSSGenerator.new
  generator.write_to_file(ARGV[0])
end
