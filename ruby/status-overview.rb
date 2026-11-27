#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "291f7fecf0bceca1def39bff0c82bf3986effbb5fdaacc08b56ceb8ed6b68137", "source_sha256": "f95cba00197f4650dddde02431fe14a0ca1baea932052e66b16f5778582e944f", "target_language": "ruby"}
# status-overview.css — portiert nach ruby
# Quelle: css, Projects@TikTok-Live-Companion:plugin-source/browser-extension/status-overview.css
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

# Methode zur Erstellung des CSS-Inhalts
def generate_css_content
  css_rules = []

  # Allgemeine Styles
  css_rules << "* { box-sizing: border-box }"
  css_rules << "html, body { margin: 0; min-height: 100%; background: #101015; color: #fff; font: 14px system-ui, sans-serif }"
  css_rules << "body { display: flex; flex-direction: column; height: 100vh }"
  
  # Header Styles
  css_rules << "header { display: flex; gap: 1em; align-items: baseline; padding: 0 12px }"
  css_rules << "h1 { font-size: 17px; margin: 8px 0 }"
  css_rules << "header p { font-size: 12px; color: #bbb; margin: 0 }"
  
  # Main Grid Styles
  css_rules << "main { flex: 1; min-height: 0; display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); grid-template-rows: repeat(3, minmax(0, 1fr)); gap: 4px; padding: 0 }"
  
  # Tile Styles
  css_rules << ".tile { min-width: 0; min-height: 0; display: flex; flex-direction: column; background: #202026; border: 1px solid #393940 }"
  css_rules << ".tile h2 { font-size: 13px; margin: 3px 8px }"
  css_rules << ".tile video { min-height: 0; width: 100%; flex: 1; object-fit: contain; background: #000 }"
  css_rules << ".tile p { font-size: 11px; margin: 3px 8px; color: #ddd }"
  
  # Zusätzliche Klassen
  css_rules << "main.grid2 { grid-template-columns: repeat(2, minmax(0, 1fr)); grid-template-rows: repeat(2, minmax(0, 1fr)) }"
  css_rules << ".tile[hidden] { display: none }"

  css_rules.join("\n")
end

# Hauptmethode
def main
  # Prüfe ob ein Dateiname übergeben wurde
  if ARGV.empty?
    puts "Verwendung: #{$0} <dateiname>"
    exit 1
  end

  filename = ARGV[0]
  
  # Generiere den CSS-Inhalt
  css_content = generate_css_content
  
  # Schreibe den Inhalt in die angegebene Datei
  File.open(filename, 'w') do |file|
    file.write(css_content)
  end
  
  puts "CSS-Datei '#{filename}' erfolgreich erstellt."
end

# Programmstart
main if __FILE__ == $0
