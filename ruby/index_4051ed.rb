#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "9263abd01da4d5916cf3611cef1a4375001a61a6179328dc6cfa67e17c5e6a07", "source_sha256": "c1bffd970108bca04ccb5b3a9aee8861acc4c11c8c4c461ea0c573b20c5e2f21", "target_language": "ruby"}
# index_4051ed.css — portiert nach ruby
# Quelle: css, Projects@abstractions:css/index_4051ed.css
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

# abstraction-provenance: {"artifact_sha256": "c0c2aa7750474bc55c705ff744495daa7aef344568dc1eadca3165b431837a79", "source_sha256": "4051edeb8cf3a53e4fdc417f40a86a4e9f16f24bcbc4b7334babe6d8f7500c24", "target_language": "ruby"}
# index.html — portiert nach css
# Quelle: html, Projects@Telegram-Monitor:web/index.html
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

class CSSGenerator
  def initialize
    @rules = {}
  end

  def add_rule(selector, properties)
    @rules[selector] = properties
  end

  def generate
    output = []
    
    # Add comments at the top
    output << "/* abstraction-provenance: {\"artifact_sha256\": \"c0c2aa7750474bc55c705ff744495daa7aef344568dc1eadca3165b431837a79\", \"source_sha256\": \"4051edeb8cf3a53e4fdc417f40a86a4e9f16f24bcbc4b7334babe6d8f7500c24\", \"target_language\": \"css\"} */"
    output << "/* index.html — portiert nach css */"
    output << "/* Quelle: html, Projects@Telegram-Monitor:web/index.html */"
    output << "/* Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py */"
    output << ""

    @rules.each do |selector, properties|
      output << "#{selector}{"
      properties.each do |prop, value|
        output << "  #{prop}:#{value};"
      end
      output << "}"
    end

    output.join("\n")
  end
end

def generate_css
  css = CSSGenerator.new
  
  # Root variables
  css.add_rule(":root", {
    "--bg" => "#f6f7f9",
    "--card" => "#fff",
    "--line" => "#e3e6ea",
    "--text" => "#16191d",
    "--muted" => "#6b7280",
    "--accent" => "#2481cc",
    "--accent-soft" => "#e8f2fb",
    "--discord" => "#5865f2",
    "--discord-soft" => "#eceefe",
    "--ok" => "#15803d",
    "--warn" => "#b45309",
    "--err" => "#b91c1c",
    "color-scheme" => "light"
  })
  
  # Universal selector
  css.add_rule("*", {
    "box-sizing" => "border-box"
  })
  
  # Body
  css.add_rule("body", {
    "margin" => "0",
    "background" => "var(--bg)",
    "color" => "var(--text)",
    "font" => "15px/1.5 -apple-system,BlinkMacSystemFont,\"Segoe UI\",Roboto,sans-serif"
  })
  
  # Header
  css.add_rule("header", {
    "background" => "var(--card)",
    "border-bottom" => "1px solid var(--line)",
    "padding" => "14px 20px",
    "display" => "flex",
    "align-items" => "center",
    "gap" => "14px",
    "flex-wrap" => "wrap",
    "position" => "sticky",
    "top" => "0",
    "z-index" => "5"
  })
  
  css.add_rule("header h1", {
    "font-size" => "17px",
    "margin" => "0",
    "font-weight" => "650"
  })
  
  # Pills
  css.add_rule(".pill", {
    "font-size" => "11px",
    "padding" => "2px 8px",
    "border-radius" => "99px",
    "background" => "var(--accent-soft)",
    "color" => "var(--accent)",
    "font-weight" => "600",
    "white-space" => "nowrap"
  })
  
  css.add_rule(".pill.off", {
    "background" => "#f1f2f4",
    "color" => "var(--muted)"
  })
  
  css.add_rule(".pill.dc", {
    "background" => "var(--discord-soft)",
    "color" => "var(--discord)"
  })
  
  # Navigation
  css.add_rule("nav", {
    "display" => "flex",
    "gap" => "4px",
    "padding" => "0 20px",
    "background" => "var(--card)",
    "border-bottom" => "1px solid var(--line)"
  })
  
  css.add_rule("nav button", {
    "border" => "0",
    "background" => "none",
    "padding" => "11px 14px",
    "font" => "inherit",
    "font-weight" => "500",
    "color" => "var(--muted)",
    "cursor" => "pointer",
    "border-bottom" => "2px solid transparent"
  })
  
  css.add_rule("nav button.active", {
    "color" => "var(--accent)",
    "border-bottom-color" => "var(--accent)"
  })
  
  # Main
  css.add_rule("main", {
    "padding" => "20px",
    "max-width" => "1080px",
    "margin" => "0 auto"
  })
  
  # Panels
  css.add_rule(".panel", {
    "display" => "none"
  })
  
  css.add_rule(".panel.active", {
    "display" => "block"
  })
  
  # Rows
  css.add_rule(".row", {
    "display" => "flex",
    "gap" => "8px",
    "flex-wrap" => "wrap",
    "align-items" => "center",
    "margin-bottom" => "14px"
  })
  
  # Inputs and selects
  css.add_rule("input,select", {
    "padding" => "9px 11px",
    "border" => "1px solid var(--line)",
    "border-radius" => "8px",
    "font" => "inherit",
    "background" => "var(--card)",
    "min-width" => "180px"
  })
  
  css.add_rule("input:focus,select:focus", {
    "outline" => "2px solid var(--accent-soft)",
    "border-color" => "var(--accent)"
  })
  
  # Buttons
  css.add_rule("button.go", {
    "background" => "var(--accent)",
    "color" => "#fff",
    "border" => "0",
    "border-radius" => "8px",
    "padding" => "9px 16px",
    "font" => "inherit",
    "font-weight" => "600",
    "cursor" => "pointer"
  })
  
  css.add_rule("button.go.sec", {
    "background" => "var(--card)",
    "color" => "var(--text)",
    "border" => "1px solid var(--line)"
  })
  
  css.add_rule("button.go.dc", {
    "background" => "var(--discord)"
  })
  
  css.add_rule("button.go:disabled", {
    "opacity" => ".5",
    "cursor" => "default"
  })
  
  # Cards
  css.add_rule(".card", {
    "background" => "var(--card)",
    "border" => "1px solid var(--line)",
    "border-radius" => "12px",
    "padding" => "14px 16px",
    "margin-bottom" => "10px"
  })
  
  css.add_rule(".card h3", {
    "margin" => "0 0 2px",
    "font-size" => "15px",
    "display" => "flex",
    "align-items" => "center",
    "gap" => "8px",
    "flex-wrap" => "wrap"
  })
  
  css.add_rule(".card .meta", {
    "color" => "var(--muted)",
    "font-size" => "13px"
  })
  
  css.add_rule(".card .desc", {
    "margin-top" => "7px",
    "font-size" => "13.5px",
    "white-space" => "pre-wrap"
  })
  
  # Avatar
  css.add_rule(".avatar", {
    "width" => "34px",
    "height" => "34px",
    "border-radius" => "50%",
    "object-fit" => "cover",
    "background" => "#eceff3",
    "flex" => "none"
  })
  
  # Head
  css.add_rule(".head", {
    "display" => "flex",
    "gap" => "11px",
    "align-items" => "flex-start"
  })
  
  # Score
  css.add_rule(".score", {
    "font-variant-numeric" => "tabular-nums",
    "font-size" => "12px",
    "color" => "var(--muted)",
    "border" => "1px solid var(--line)",
    "border-radius" => "6px",
    "padding" => "1px 6px"
  })
  
  # Tags
  css.add_rule(".tag", {
    "font-size" => "11px",
    "padding" => "2px 7px",
    "border-radius" => "5px",
    "background" => "#f1f2f4",
    "color" => "var(--muted)",
    "font-weight" => "600"
  })
  
  css.add_rule(".tag.ok", {
    "background" => "#e7f6ec",
    "color" => "var(--ok)"
  })
  
  css.add_rule(".tag.no", {
    "background" => "#fdeceb",
    "color" => "var(--err)"
  })
  
  # Posts
  css.add_rule(".post", {
    "border-left" => "3px solid var(--accent-soft)",
    "padding" => "6px 0 6px 11px",
    "margin" => "9px 0",
    "font-size" => "13.5px"
  })
  
  css.add_rule(".post .when", {
    "color" => "var(--muted)",
    "font-size" => "12px"
  })
  
  css.add_rule(".post .txt", {
    "white-space" => "pre-wrap",
    "margin-top" => "2px"
  })
  
  # Links
  css.add_rule("a", {
    "color" => "var(--accent)",
    "text-decoration" => "none"
  })
  
  css.add_rule("a:hover", {
    "text-decoration" => "underline"
  })
  
  # Empty
  css.add_rule(".empty", {
    "color" => "var(--muted)",
    "padding" => "22px",
    "text-align" => "center",
    "border" => "1px dashed var(--line)",
    "border-radius" => "12px"
  })
  
  # Error
  css.add_rule(".err", {
    "background" => "#fdeceb",
    "border" => "1px solid #f5c6c2",
    "color" => "var(--err)",
    "padding" => "10px 13px",
    "border-radius" => "8px",
    "margin-bottom" => "12px",
    "font-size" => "13.5px"
  })
  
  # Spin
  css.add_rule(".spin", {
    "color" => "var(--muted)",
    "padding" => "16px 0"
  })
  
  # Table
  css.add_rule("table", {
    "width" => "100%",
    "border-collapse" => "collapse",
    "font-size" => "13.5px"
  })
  
  css.add_rule("th,td", {
    "text-align" => "left",
    "padding" => "8px 10px",
    "border-bottom" => "1px solid var(--line)",
    "vertical-align" => "top"
  })
  
  css.add_rule("th", {
    "color" => "var(--muted)",
    "font-weight" => "600",
    "font-size" => "12px",
    "text-transform" => "uppercase",
    "letter-spacing" => ".03em"
  })
  
  # Code
  css.add_rule("code", {
    "background" => "#f1f2f4",
    "padding" => "1px 5px",
    "border-radius" => "4px",
    "font-size" => "12.5px"
  })
  
  # Hint
  css.add_rule(".hint", {
    "color" => "var(--muted)",
    "font-size" => "13px",
    "margin" => "-4px 0 14px"
  })
  
  # Stream
  css.add_rule(".stream", {
    "max-height" => "460px",
    "overflow" => "auto",
    "border" => "1px solid var(--line)",
    "border-radius" => "10px",
    "padding" => "6px 12px",
    "margin-top" => "10px",
    "background" => "var(--card)"
  })
  
  # Fresh posts
  css.add_rule(".post.fresh", {
    "border-left-color" => "var(--ok)",
    "background" => "#f3fbf5"
  })
  
  css.add_rule(".post.fresh .when::after", {
    "content" => "\" NEU\"",
    "color" => "var(--ok)",
    "font-weight" => "700"
  })
  
  # Dot
  css.add_rule(".dot", {
    "width" => "8px",
    "height" => "8px",
    "border-radius" => "50%",
    "background" => "var(--ok)",
    "display" => "inline-block",
    "margin-right" => "6px",
    "animation" => "pulse 2s infinite"
  })
  
  # Keyframes
  css.add_rule("@keyframes pulse", {
    "0%,100%" => "{opacity:1}",
    "50%" => "{opacity:.35}"
  })
  
  # Idle
  css.add_rule(".idle", {
    "background" => "var(--muted)!important",
    "animation" => "none"
  })
  
  # TT elements
  css.add_rule(".tt-live", {
    "background" => "#fe2c55",
    "color" => "#fff",
    "font-weight" => "700",
    "font-size" => "11px",
    "padding" => "2px 9px",
    "border-radius" => "99px"
  })
  
  css.add_rule(".tt-off", {
    "background" => "#f1f2f4",
    "color" => "var(--muted)",
    "font-weight" => "700",
    "font-size" => "11px",
    "padding" => "2px 9px",
    "border-radius" => "99px"
  })
  
  css.add_rule(".tt-player", {
    "position" => "relative",
    "width" => "100%",
    "max-width" => "340px",
    "aspect-ratio" => "9/16",
    "background" => "#000",
    "border-radius" => "10px",
    "overflow" => "hidden",
    "margin-top" => "10px",
    "border" => "1px solid var(--line)"
  })
  
  css.add_rule(".tt-player iframe", {
    "position" => "absolute",
    "inset" => "0",
    "width" => "100%",
    "height" => "100%",
    "border" => "0"
  })
  
  # Events
  css.add_rule(".ev", {
    "display" => "flex",
    "gap" => "10px",
    "padding" => "7px 0",
    "border-bottom" => "1px solid var(--line)",
    "font-size" => "13.5px"
  })
  
  css.add_rule(".ev:last-child", {
    "border-bottom" => "0"
  })
  
  css.add_rule(".ev .k", {
    "font-weight" => "650",
    "white-space" => "nowrap"
  })
  
  css.add_rule(".ev .k.start", {
    "color" => "#fe2c55"
  })
  
  css.add_rule(".ev .k.end", {
    "color" => "var(--muted)"
  })
  
  css.generate
end

# Main execution
if __FILE__ == $0
  if ARGV.length != 1
    puts "Usage: #{$0} <output_file>"
    exit 1
  end
  
  output_file = ARGV[0]
  
  File.open(output_file, 'w') do |file|
    file.write(generate_css)
  end
  
  puts "CSS file generated: #{output_file}"
end
