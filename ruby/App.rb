#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "2dfe0403ccb3b4d2f351b1c24bf7c1e0b8f7a6f0d48d19b541f3696b9a98038f", "source_sha256": "08fdd65a33a6ec90261b4ce48be82ca8338400da1b321dfc70a57bedabfa45aa", "target_language": "ruby"}
# App.css — portiert nach ruby
# Quelle: css, OpenClaw@main:src/App.css
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# CSS to Ruby translation of App.css
# Generates the complete CSS document structure using Ruby methods

class CSSGenerator
  def initialize
    @rules = []
  end

  def add_rule(selector, properties)
    @rules << { selector: selector, properties: properties }
  end

  def generate_css
    css = ""
    @rules.each do |rule|
      css += "#{rule[:selector]} {\n"
      rule[:properties].each do |prop, value|
        css += "  #{prop}: #{value};\n"
      end
      css += "}\n\n"
    end
    css.chomp
  end
end

def create_app_css
  css_gen = CSSGenerator.new

  # Root styles
  css_gen.add_rule(":root", {
    "color-scheme" => "dark",
    "font-family" => "Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, \"Segoe UI\", sans-serif",
    "background" => "#0b1020",
    "color" => "#eef2ff"
  })

  # Universal styles
  css_gen.add_rule("*", {
    "box-sizing" => "border-box"
  })

  # Body styles
  css_gen.add_rule("body", {
    "margin" => "0",
    "min-width" => "320px",
    "min-height" => "100vh",
    "background" => "radial-gradient(circle at 20% 20%, rgba(56, 189, 248, 0.22), transparent 30rem), radial-gradient(circle at 80% 10%, rgba(168, 85, 247, 0.2), transparent 28rem), linear-gradient(135deg, #050816 0%, #111827 55%, #172033 100%)"
  })

  # Page shell styles
  css_gen.add_rule(".page-shell", {
    "min-height" => "100vh",
    "display" => "grid",
    "place-items" => "center",
    "padding" => "2rem"
  })

  # Hero card styles
  css_gen.add_rule(".hero-card", {
    "width" => "min(100%, 56rem)",
    "padding" => "clamp(2rem, 6vw, 4.5rem)",
    "border" => "1px solid rgba(148, 163, 184, 0.28)",
    "border-radius" => "2rem",
    "background" => "rgba(15, 23, 42, 0.72)",
    "box-shadow" => "0 2rem 6rem rgba(0, 0, 0, 0.35)",
    "backdrop-filter" => "blur(18px)"
  })

  # Eyebrow styles
  css_gen.add_rule(".eyebrow", {
    "margin" => "0 0 1rem",
    "color" => "#67e8f9",
    "font-size" => "0.8rem",
    "font-weight" => "700",
    "letter-spacing" => "0.18em",
    "text-transform" => "uppercase"
  })

  # Heading styles
  css_gen.add_rule("h1", {
    "margin" => "0",
    "max-width" => "12ch",
    "font-size" => "clamp(2.75rem, 8vw, 6rem)",
    "line-height" => "0.95",
    "letter-spacing" => "-0.06em"
  })

  # Lead styles
  css_gen.add_rule(".lead", {
    "margin" => "1.5rem 0 0",
    "max-width" => "42rem",
    "color" => "#cbd5e1",
    "font-size" => "clamp(1.05rem, 2vw, 1.35rem)",
    "line-height" => "1.65"
  })

  # Link grid container
  css_gen.add_rule(".link-grid", {
    "display" => "grid",
    "gap" => "0.85rem",
    "margin-top" => "2rem"
  })

  # Link grid items
  css_gen.add_rule(".link-grid a", {
    "display" => "flex",
    "align-items" => "center",
    "justify-content" => "space-between",
    "gap" => "1rem",
    "padding" => "1rem 1.15rem",
    "border" => "1px solid rgba(148, 163, 184, 0.25)",
    "border-radius" => "1rem",
    "color" => "#f8fafc",
    "text-decoration" => "none",
    "background" => "rgba(255, 255, 255, 0.06)"
  })

  # Link hover/focus states
  css_gen.add_rule(".link-grid a:hover,\n.link-grid a:focus-visible", {
    "border-color" => "rgba(103, 232, 249, 0.75)",
    "outline" => "none",
    "background" => "rgba(103, 232, 249, 0.12)"
  })

  css_gen.generate_css
end

# Main execution
if ARGV.length != 1
  puts "Usage: #{$0} <output_file>"
  exit 1
end

output_file = ARGV[0]
File.write(output_file, create_app_css)
puts "CSS file generated: #{output_file}"
