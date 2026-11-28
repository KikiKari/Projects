#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "ce2539a5e75c9203134c6c5642e6a0b69edda7f3e3a92ac2597ce900ce1f4d63", "source_sha256": "638dc60323e7b18098ef0f5b3cef4b90dd9bb4ffeca2fdedb49c5b2aebbe59c3", "target_language": "ruby"}
# popup.css — portiert nach ruby
# Quelle: css, Projects@abstractions:css/popup.css
# Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

# abstraction-provenance: {"artifact_sha256": "9a98ca6b7904c136087b8d4d69db570323e127c17f3231983fad5ab0ede46fb9", "source_sha256": "460df65e46318ad1986c44053aeaeda0d4be58e1787c4233154a42f92badec94", "target_language": "ruby"}
# popup.html — portiert nach ruby
# Quelle: html, Projects@Telegram-Monitor:plugin/extension/popup.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

class PopupCSSGenerator
  def initialize
    @css_content = ""
  end

  def generate_css
    add_comment("abstraction-provenance: {\"artifact_sha256\": \"9a98ca6b7904c136087b8d4d69db570323e127c17f3231983fad5ab0ede46fb9\", \"source_sha256\": \"460df65e46318ad1986c44053aeaeda0d4be58e1787c4233154a42f92badec94\", \"target_language\": \"css\"}")
    add_comment("popup.html — portiert nach css")
    add_comment("Quelle: html, Projects@Telegram-Monitor:plugin/extension/popup.html")
    add_comment("Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py")
    
    add_rule(":root") do
      add_property("--bg", "#0f1115")
      add_property("--card", "#171a21")
      add_property("--line", "#262b36")
      add_property("--text", "#f2f4f8")
      add_property("--muted", "#9aa3b2")
      add_property("--accent", "#fe2c55")
      add_property("--ok", "#22c55e")
      add_property("color-scheme", "dark")
    end
    
    add_media_query("(prefers-color-scheme: light)") do
      add_rule(":root") do
        add_property("--bg", "#fff")
        add_property("--card", "#f6f7f9")
        add_property("--line", "#e3e6ea")
        add_property("--text", "#16191d")
        add_property("--muted", "#6b7280")
      end
    end
    
    add_rule("*") do
      add_property("box-sizing", "border-box")
    end
    
    add_rule("body") do
      add_property("margin", "0")
      add_property("width", "420px")
      add_property("max-height", "600px")
      add_property("overflow", "auto")
      add_property("background", "var(--bg)")
      add_property("color", "var(--text)")
      add_property("font", "14px/1.45 -apple-system, BlinkMacSystemFont, \"Segoe UI\", Roboto, sans-serif")
    end
    
    add_rule(".wrap") do
      add_property("padding", "12px")
    end
    
    add_rule("header") do
      add_property("display", "flex")
      add_property("gap", "8px")
      add_property("align-items", "center")
      add_property("margin-bottom", "10px")
    end
    
    add_rule("h1") do
      add_property("font-size", "14px")
      add_property("margin", "0")
      add_property("font-weight", "650")
      add_property("flex", "1")
    end
    
    add_rule(".badge") do
      add_property("font-size", "11px")
      add_property("font-weight", "700")
      add_property("padding", "3px 9px")
      add_property("border-radius", "99px")
      add_property("background", "#2a2f3a")
      add_property("color", "var(--muted)")
      add_property("display", "inline-flex")
      add_property("align-items", "center")
      add_property("gap", "5px")
    end
    
    add_rule(".badge.live") do
      add_property("background", "var(--accent)")
      add_property("color", "#fff")
    end
    
    add_rule(".badge .dot") do
      add_property("width", "6px")
      add_property("height", "6px")
      add_property("border-radius", "50%")
      add_property("background", "currentColor")
    end
    
    add_rule(".badge.live .dot") do
      add_property("animation", "pulse 1.6s infinite")
    end
    
    add_keyframes("pulse") do
      add_keyframe("0%, 100%") do
        add_property("opacity", "1")
      end
      add_keyframe("50%") do
        add_property("opacity", ".25")
      end
    end
    
    add_rule(".row") do
      add_property("display", "flex")
      add_property("gap", "6px")
      add_property("flex-wrap", "wrap")
      add_property("align-items", "center")
      add_property("margin-bottom", "8px")
    end
    
    add_rule("input, select, button") do
      add_property("font", "inherit")
      add_property("border-radius", "7px")
      add_property("border", "1px solid var(--line)")
      add_property("background", "var(--card)")
      add_property("color", "var(--text)")
      add_property("padding", "6px 9px")
    end
    
    add_rule("button") do
      add_property("cursor", "pointer")
      add_property("font-weight", "600")
    end
    
    add_rule("button.primary") do
      add_property("background", "var(--accent)")
      add_property("border-color", "var(--accent)")
      add_property("color", "#fff")
    end
    
    add_rule(".player") do
      add_property("position", "relative")
      add_property("width", "100%")
      add_property("aspect-ratio", "9/16")
      add_property("max-height", "360px")
      add_property("background", "#000")
      add_property("border-radius", "10px")
      add_property("overflow", "hidden")
      add_property("border", "1px solid var(--line)")
      add_property("margin", "8px 0")
    end
    
    add_rule(".player iframe") do
      add_property("position", "absolute")
      add_property("inset", "0")
      add_property("width", "100%")
      add_property("height", "100%")
      add_property("border", "0")
    end
    
    add_rule(".placeholder") do
      add_property("position", "absolute")
      add_property("inset", "0")
      add_property("display", "flex")
      add_property("flex-direction", "column")
      add_property("gap", "6px")
      add_property("align-items", "center")
      add_property("justify-content", "center")
      add_property("color", "var(--muted)")
      add_property("text-align", "center")
      add_property("padding", "16px")
      add_property("font-size", "13px")
    end
    
    add_rule(".card") do
      add_property("background", "var(--card)")
      add_property("border", "1px solid var(--line)")
      add_property("border-radius", "10px")
      add_property("padding", "10px 12px")
      add_property("margin-bottom", "8px")
    end
    
    add_rule("h2") do
      add_property("font-size", "11px")
      add_property("text-transform", "uppercase")
      add_property("letter-spacing", ".05em")
      add_property("color", "var(--muted)")
      add_property("margin", "0 0 6px")
      add_property("font-weight", "650")
    end
    
    add_rule(".meta") do
      add_property("color", "var(--muted)")
      add_property("font-size", "12.5px")
    end
    
    add_rule(".strong") do
      add_property("color", "var(--text)")
      add_property("font-weight", "600")
    end
    
    add_rule(".stream") do
      add_property("display", "flex")
      add_property("gap", "8px")
      add_property("padding", "5px 0")
      add_property("border-bottom", "1px solid var(--line)")
      add_property("font-size", "12.5px")
    end
    
    add_rule(".stream:last-child") do
      add_property("border-bottom", "0")
    end
    
    add_rule(".stream .when") do
      add_property("color", "var(--muted)")
      add_property("white-space", "nowrap")
      add_property("font-variant-numeric", "tabular-nums")
    end
    
    add_rule(".stream .t") do
      add_property("flex", "1")
      add_property("min-width", "0")
      add_property("overflow", "hidden")
      add_property("text-overflow", "ellipsis")
      add_property("white-space", "nowrap")
    end
    
    add_rule(".stream.now") do
      add_property("color", "var(--accent)")
      add_property("font-weight", "650")
    end
    
    add_rule(".err") do
      add_property("background", "#3a1d22")
      add_property("border", "1px solid #5c2a33")
      add_property("color", "#ffb4c0")
      add_property("padding", "8px 10px")
      add_property("border-radius", "8px")
      add_property("font-size", "12.5px")
      add_property("margin-bottom", "8px")
    end
    
    add_media_query("(prefers-color-scheme: light)") do
      add_rule(".err") do
        add_property("background", "#fdeceb")
        add_property("border-color", "#f5c6c2")
        add_property("color", "#b91c1c")
      end
    end
    
    add_rule(".note") do
      add_property("font-size", "11.5px")
      add_property("color", "var(--muted)")
      add_property("line-height", "1.4")
      add_property("margin-top", "8px")
    end
    
    add_rule("a") do
      add_property("color", "var(--accent)")
    end
    
    @css_content
  end

  def write_to_file(filename)
    File.open(filename, 'w') do |file|
      file.write(generate_css)
    end
  end

  private

  def add_comment(text)
    @css_content += "/* #{text} */\n"
  end

  def add_rule(selector)
    @css_content += "#{selector} {\n"
    yield if block_given?
    @css_content += "}\n\n"
  end

  def add_property(property, value)
    @css_content += "  #{property}: #{value};\n"
  end

  def add_media_query(query)
    @css_content += "@media #{query} {\n"
    yield if block_given?
    @css_content += "}\n\n"
  end

  def add_keyframes(name)
    @css_content += "@keyframes #{name} {\n"
    yield if block_given?
    @css_content += "}\n\n"
  end

  def add_keyframe(step)
    @css_content += "  #{step} {\n"
    yield if block_given?
    @css_content += "  }\n"
  end
end

if __FILE__ == $0
  generator = PopupCSSGenerator.new
  output_file = ARGV[0] || "popup.css"
  generator.write_to_file(output_file)
  puts "CSS file generated: #{output_file}"
end
