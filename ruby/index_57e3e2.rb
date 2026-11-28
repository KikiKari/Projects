#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "6bfabba9b7c6157c81dfec1fae87d3165c85e790b2bd4981bf904bdb62024ad4", "source_sha256": "18d15a289b831c9da96c808e0cc1de4dae7bf3dfc35a804a239a992cd82cde89", "target_language": "ruby"}
# index_57e3e2.css — portiert nach ruby
# Quelle: css, Projects@abstractions:css/index_57e3e2.css
# Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

# abstraction-provenance: {"artifact_sha256": "a05439af4536c91ed01734c3151c3870ffe206fc2433d74fe3db29d4666579ca", "source_sha256": "57e3e28b7c96948ea289f7d9401b6d0bf990d118129de570394784d35e23cf4c", "target_language": "ruby"}
# index.html — portiert nach css
# Quelle: html, Projects@tagesstatus-live-public:tagesstatus-live-public/index.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

class CSSGenerator
  def initialize
    @rules = {}
  end

  def add_rule(selector, properties)
    @rules[selector] = properties
  end

  def generate_css
    css = []
    
    # Add comments at the beginning
    css << "/* abstraction-provenance: {\"artifact_sha256\": \"a05439af4536c91ed01734c3151c3870ffe206fc2433d74fe3db29d4666579ca\", \"source_sha256\": \"57e3e28b7c96948ea289f7d9401b6d0bf990d118129de570394784d35e23cf4c\", \"target_language\": \"css\"} */"
    css << "/* index.html — portiert nach css */"
    css << "/* Quelle: html, Projects@tagesstatus-live-public:tagesstatus-live-public/index.html */"
    css << "/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */"
    css << ""
    
    @rules.each do |selector, properties|
      css << "#{selector} {"
      properties.each do |property, value|
        css << "  #{property}: #{value};"
      end
      css << "}"
      css << ""
    end
    
    css.join("\n")
  end
end

def create_css
  css = CSSGenerator.new
  
  # Root rule
  css.add_rule(":root", {
    "color-scheme" => "light"
  })
  
  # Universal selector
  css.add_rule("*", {
    "box-sizing" => "border-box"
  })
  
  # Body rule
  css.add_rule("body", {
    "margin" => "0",
    "font-family" => "-apple-system, BlinkMacSystemFont, \"Segoe UI\", Roboto, Helvetica, Arial, sans-serif",
    "background" => "#f7f7f5",
    "color" => "#1d1c1a"
  })
  
  # Wrap rule
  css.add_rule(".wrap", {
    "max-width" => "880px",
    "margin" => "0 auto",
    "padding" => "20px 16px 60px"
  })
  
  # H1 rule
  css.add_rule("h1", {
    "font-size" => "22px",
    "margin" => "0 0 2px"
  })
  
  # Sub rule
  css.add_rule(".sub", {
    "color" => "#6b6a66",
    "font-size" => "13px",
    "margin-bottom" => "16px"
  })
  
  # Bar rule
  css.add_rule(".bar", {
    "display" => "flex",
    "gap" => "10px",
    "align-items" => "center",
    "margin-bottom" => "16px",
    "flex-wrap" => "wrap"
  })
  
  # Button rules
  css.add_rule("button", {
    "font-size" => "13px",
    "font-weight" => "600",
    "padding" => "7px 13px",
    "border" => "1px solid #d9d8d3",
    "border-radius" => "8px",
    "background" => "#fff",
    "cursor" => "pointer"
  })
  
  css.add_rule("button:hover", {
    "background" => "#f2f1ec"
  })
  
  css.add_rule("button.primary", {
    "background" => "#1d1c1a",
    "color" => "#fff",
    "border-color" => "#1d1c1a"
  })
  
  # Note rule
  css.add_rule(".note", {
    "background" => "#fffdf4",
    "border" => "1px solid #f0e9c8",
    "border-radius" => "10px",
    "padding" => "12px 14px",
    "font-size" => "13px",
    "color" => "#4a4734",
    "margin-bottom" => "16px",
    "line-height" => "1.5"
  })
  
  # Section rules
  css.add_rule(".section", {
    "background" => "#fff",
    "border" => "1px solid #e8e7e3",
    "border-radius" => "12px",
    "margin-bottom" => "14px",
    "overflow" => "hidden"
  })
  
  css.add_rule(".section > h2", {
    "font-size" => "15px",
    "margin" => "0",
    "padding" => "13px 16px",
    "border-bottom" => "1px solid #efeee9",
    "display" => "flex",
    "align-items" => "center",
    "gap" => "9px"
  })
  
  css.add_rule(".section > h2 .badge", {
    "margin-left" => "auto",
    "font-size" => "12px",
    "font-weight" => "600",
    "background" => "#efeee9",
    "color" => "#5a5852",
    "padding" => "2px 9px",
    "border-radius" => "20px"
  })
  
  # Body rule
  css.add_rule(".body", {
    "padding" => "8px 16px 14px",
    "font-size" => "14px"
  })
  
  # Muted rule
  css.add_rule(".muted", {
    "color" => "#8a8884"
  })
  
  # Err rule
  css.add_rule(".err", {
    "color" => "#c0392b"
  })
  
  # KV rules
  css.add_rule(".kv", {
    "display" => "flex",
    "justify-content" => "space-between",
    "padding" => "4px 0",
    "border-bottom" => "1px solid #f4f3ee"
  })
  
  css.add_rule(".kv:last-child", {
    "border" => "none"
  })
  
  css.add_rule(".kv .k", {
    "color" => "#6b6a66"
  })
  
  css.add_rule(".kv .v", {
    "font-weight" => "600"
  })
  
  # Link rules
  css.add_rule("a", {
    "color" => "#2b5cc4",
    "text-decoration" => "none"
  })
  
  css.add_rule("a:hover", {
    "text-decoration" => "underline"
  })
  
  # Modal rules
  css.add_rule(".modal", {
    "position" => "fixed",
    "inset" => "0",
    "background" => "rgba(0, 0, 0, .35)",
    "display" => "none",
    "align-items" => "flex-start",
    "justify-content" => "center",
    "padding" => "40px 16px",
    "overflow" => "auto"
  })
  
  css.add_rule(".modal.open", {
    "display" => "flex"
  })
  
  # Card rules
  css.add_rule(".card", {
    "background" => "#fff",
    "border-radius" => "14px",
    "max-width" => "560px",
    "width" => "100%",
    "padding" => "20px"
  })
  
  css.add_rule(".card h3", {
    "margin" => "0 0 4px",
    "font-size" => "17px"
  })
  
  css.add_rule(".card p.hint", {
    "margin" => "0 0 16px",
    "font-size" => "12px",
    "color" => "#8a8884"
  })
  
  # Field rules
  css.add_rule(".field", {
    "margin-bottom" => "12px"
  })
  
  css.add_rule(".field label", {
    "display" => "block",
    "font-size" => "12px",
    "font-weight" => "600",
    "color" => "#5a5852",
    "margin-bottom" => "3px"
  })
  
  css.add_rule(".field input", {
    "width" => "100%",
    "font-size" => "13px",
    "padding" => "7px 9px",
    "border" => "1px solid #d9d8d3",
    "border-radius" => "7px",
    "font-family" => "ui-monospace, Menlo, monospace"
  })
  
  css.add_rule(".field .desc", {
    "font-size" => "11px",
    "color" => "#a8a6a1",
    "margin-top" => "2px"
  })
  
  # Actions rule
  css.add_rule(".actions", {
    "display" => "flex",
    "gap" => "10px",
    "justify-content" => "flex-end",
    "margin-top" => "8px"
  })
  
  # Warn rule
  css.add_rule(".warn", {
    "background" => "#fdf3f3",
    "border" => "1px solid #f3d9d9",
    "color" => "#9a3b3b",
    "border-radius" => "8px",
    "padding" => "10px 12px",
    "font-size" => "12px",
    "margin-bottom" => "14px"
  })
  
  css.generate_css
end

# Main execution
if __FILE__ == $0
  if ARGV.length != 1
    puts "Usage: #{$0} <output_file>"
    exit 1
  end
  
  output_file = ARGV[0]
  
  File.open(output_file, 'w') do |file|
    file.write(create_css)
  end
  
  puts "CSS file generated successfully: #{output_file}"
end
