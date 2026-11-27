#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "3db7d2068cbd589e5f258f01140f4d2e595213c3dce0c01a7776db8c5b1beca6", "source_sha256": "f9571a381240f9d09733d99d5efdbd1df3ed653107eadfccbced6324e1b78049", "target_language": "ruby"}
# index_6925e5.css — portiert nach ruby
# Quelle: css, Projects@abstractions:css/index_6925e5.css
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

# abstraction-provenance: {"artifact_sha256": "ede701dd0faa101fb7d23c7e6bd8e28625c33e7b3d07a7ededc1bf14cbfcb761", "source_sha256": "6925e5ed34d3344b10c23ce3442546a31631cc8434f3b7df4bdc003d32218523", "target_language": "ruby"}
# index.html — portiert nach css
# Quelle: html, Projects@MCP-Server-Monitor:public/index.html
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

class CSSGenerator
  def initialize
    @styles = {}
  end

  def add_rule(selector, properties)
    @styles[selector] = properties
  end

  def add_media_query(query, rules)
    @styles[query] = rules
  end

  def generate_css
    css = []
    
    # Root styles
    css << ":root{"
    css << "  --bg:#fff; --soft:#f6f7f9; --line:#e3e6ea; --text:#16191d; --muted:#5f6773;"
    css << "  --ac:#6d5bd0; --ac-soft:#efecfb;"
    css << "  --ok:#15803d; --ok-soft:#e7f6ec; --warn:#b45309; --warn-soft:#fdf3e3;"
    css << "  color-scheme: light;"
    css << "}"
    
    # Dark mode media query
    css << "@media (prefers-color-scheme: dark){"
    css << "  :root{ --bg:#0f1115; --soft:#171a21; --line:#262b36; --text:#f2f4f8; --muted:#9aa3b2;"
    css << "         --ac-soft:#1e1a33; --ok-soft:#12261a; --warn-soft:#2c2110; color-scheme: dark; }"
    css << "}"
    
    # Universal selector
    css << "*{box-sizing:border-box}"
    
    # Body styles
    css << "body{margin:0;background:var(--bg);color:var(--text);"
    css << "     font:16px/1.6 -apple-system,BlinkMacSystemFont,\"Segoe UI\",Roboto,sans-serif}"
    
    # Wrap container
    css << ".wrap{max-width:840px;margin:0 auto;padding:0 20px 72px}"
    
    # Header
    css << "header{padding:64px 0 36px;border-bottom:1px solid var(--line)}"
    
    # Headings
    css << "h1{font-size:34px;line-height:1.2;margin:0 0 12px;letter-spacing:-.02em}"
    css << ".lede{font-size:18px;color:var(--muted);margin:0 0 20px;max-width:62ch}"
    css << "h2{font-size:13px;margin:48px 0 14px;text-transform:uppercase;letter-spacing:.06em;"
    css << "   color:var(--muted);font-weight:650}"
    css << "h3{font-size:17px;margin:24px 0 6px}"
    
    # Paragraphs
    css << "p{margin:0 0 14px;max-width:70ch}"
    
    # Badges
    css << ".badges{display:flex;gap:7px;flex-wrap:wrap;margin-bottom:20px}"
    css << ".badge{font-size:12px;font-weight:650;padding:4px 11px;border-radius:99px;"
    css << "       background:var(--soft);color:var(--muted);border:1px solid var(--line)}"
    css << ".badge.on{background:var(--ok-soft);color:var(--ok);border-color:transparent}"
    
    # Tables
    css << "table{border-collapse:collapse;width:100%;font-size:14.5px;margin:0 0 14px}"
    css << "th,td{text-align:left;padding:9px 10px;border-bottom:1px solid var(--line);vertical-align:top}"
    css << "th{font-size:12px;text-transform:uppercase;letter-spacing:.04em;color:var(--muted)}"
    
    # Code blocks
    css << "code{background:var(--soft);padding:2px 7px;border-radius:5px;font-size:13.5px;"
    css << "     font-family:ui-monospace,SFMono-Regular,Menlo,monospace;word-break:break-word}"
    css << "pre{background:var(--soft);border:1px solid var(--line);border-radius:10px;"
    css << "    padding:13px 15px;overflow-x:auto;margin:0 0 14px}"
    css << "pre code{background:none;padding:0}"
    
    # Cards and notes
    css << ".card{border:1px solid var(--line);border-radius:12px;padding:18px 20px;background:var(--bg)}"
    css << ".note{background:var(--warn-soft);border:1px solid transparent;border-radius:10px;"
    css << "      padding:14px 16px;margin:0 0 16px;font-size:14.5px}"
    css << ".note b{color:var(--warn)}"
    
    # Form elements
    css << "fieldset{border:1px solid var(--line);border-radius:10px;padding:14px 16px;margin:0 0 14px}"
    css << "legend{font-size:12px;text-transform:uppercase;letter-spacing:.05em;color:var(--muted);padding:0 6px}"
    css << "label.q{display:flex;gap:10px;align-items:flex-start;padding:7px 0;font-size:15px;cursor:pointer}"
    css << "label.q input{margin-top:4px;flex:none}"
    css << "label.q span small{display:block;color:var(--muted);font-size:13px}"
    css << "#ergebnis{margin-top:6px}"
    
    # Verdict section
    css << ".verdict{border:1px solid var(--line);border-left:4px solid var(--ac);"
    css << "         border-radius:10px;padding:16px 18px;background:var(--soft)}"
    css << ".verdict h3{margin:0 0 6px;font-size:18px}"
    css << ".verdict .step{font-weight:650;margin:10px 0 0}"
    css << ".verdict .w{margin-top:12px;padding:11px 13px;background:var(--warn-soft);"
    css << "            border-radius:8px;font-size:14px}"
    
    # Probe section
    css << ".probe{display:flex;gap:8px;flex-wrap:wrap;margin-bottom:12px}"
    css << ".probe input{flex:1 1 240px;padding:10px 12px;border:1px solid var(--line);"
    css << "             border-radius:9px;background:var(--bg);color:var(--text);font-size:15px}"
    
    # Buttons
    css << ".btn{font-weight:650;font-size:15px;padding:10px 18px;border-radius:9px;"
    css << "     border:1px solid var(--ac);background:var(--ac);color:#fff;cursor:pointer}"
    css << ".btn.ghost{background:var(--bg);color:var(--text);border-color:var(--line)}"
    
    # Footer
    css << "footer{margin-top:56px;padding-top:22px;border-top:1px solid var(--line);"
    css << "       color:var(--muted);font-size:14px}"
    
    # Links
    css << "a{color:var(--ac)}"
    
    css.join("\n")
  end

  def write_to_file(filename)
    File.open(filename, 'w') do |file|
      file.write(generate_css)
    end
  end
end

# Main execution
if __FILE__ == $0
  if ARGV.length != 1
    puts "Verwendung: #{$0} <ausgabedatei>"
    exit 1
  end

  generator = CSSGenerator.new
  output_file = ARGV[0]
  
  generator.write_to_file(output_file)
  puts "CSS erfolgreich generiert und gespeichert in: #{output_file}"
end
