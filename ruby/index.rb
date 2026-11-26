#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "2fc71b8fb90887e24e14203abc79bd276f5fd0783633301370a8f456de81e72f", "source_sha256": "daf22c296c801d3d533083361cc59fbdc22e5bfe528aa4bad1973b54cc5448a4", "target_language": "ruby"}
# index.css — portiert nach ruby
# Quelle: css, OpenClaw@main:src/index.css
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# Ruby-Skript zur Erstellung der CSS-Datei index.css
# Dieses Skript erzeugt dynamisch die CSS-Regeln und speichert sie in einer Datei

def generate_css_content
  css_rules = []
  
  # Body Regel
  body_rule = {
    selector: "body",
    properties: {
      "margin" => "0",
      "font-family" => "-apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen', 'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue', sans-serif",
      "-webkit-font-smoothing" => "antialiased",
      "-moz-osx-font-smoothing" => "grayscale"
    }
  }
  css_rules << body_rule
  
  # Code Regel
  code_rule = {
    selector: "code",
    properties: {
      "font-family" => "source-code-pro, Menlo, Monaco, Consolas, 'Courier New', monospace"
    }
  }
  css_rules << code_rule
  
  # CSS-Inhalt generieren
  css_content = ""
  css_rules.each do |rule|
    css_content += "#{rule[:selector]} {\n"
    rule[:properties].each do |property, value|
      css_content += "  #{property}: #{value};\n"
    end
    css_content += "}\n\n"
  end
  
  css_content.strip + "\n"
end

def write_css_to_file(filename)
  css_content = generate_css_content
  File.write(filename, css_content)
  puts "CSS erfolgreich in #{filename} geschrieben"
end

# Hauptprogramm
if __FILE__ == $0
  # Standarddateiname falls kein Parameter angegeben
  output_file = ARGV[0] || "index.css"
  write_css_to_file(output_file)
end
