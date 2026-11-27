#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "b3ad287ff25e0c360ee2425db5f88ca27801c496aaa0f0fa74c09cf7bf90a6a7", "source_sha256": "b53b17806f268da8dc7115668f5a04c5ff39edd9b2305ba40f1b04e598002f81", "target_language": "ruby"}
# index_5f1051.css — portiert nach ruby
# Quelle: css, Projects@abstractions:css/index_5f1051.css
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

# abstraction-provenance: {"artifact_sha256": "cdcc9e9ffa451d8c92fd763b0dfd0b1974003a826baaae753e2f347cfd3c9f57", "source_sha256": "5f1051ecfd7f7a7dbdb89449a4e356b1ff5b7daa5e21e2c82defb13ede719988", "target_language": "ruby"}
# index.html — portiert nach ruby
# Quelle: html, OpenClaw@gateway1:skills/scripting-utils/references/tcl/index.html
# auch in: OpenClaw@gateway2:skills/scripting-utils/references/tcl/index.html
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

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
    css << "/* abstraction-provenance: {\"artifact_sha256\": \"cdcc9e9ffa451d8c92fd763b0dfd0b1974003a826baaae753e2f347cfd3c9f57\", \"source_sha256\": \"5f1051ecfd7f7a7dbdb89449a4e356b1ff5b7daa5e21e2c82defb13ede719988\", \"target_language\": \"css\"} */"
    css << "/* index.html — portiert nach css */"
    css << "/* Quelle: html, OpenClaw@gateway1:skills/scripting-utils/references/tcl/index.html */"
    css << "/* auch in: OpenClaw@gateway2:skills/scripting-utils/references/tcl/index.html */"
    css << "/* Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py */"
    css << ""

    @rules.each do |selector, properties|
      css << "#{selector} {"
      properties.each do |property, value|
        css << "    #{property}: #{value};"
      end
      css << "}"
      css << ""
    end

    css.join("\n")
  end

  def save_to_file(filename)
    File.write(filename, generate_css)
  end

  def self.create_index_css
    generator = new
    
    # body
    generator.add_rule("body", {
      "background-color" => "white",
      "color" => "black",
      "margin" => "0",
      "padding" => "0",
      "font-family" => "Arial, sans-serif"
    })

    # table
    generator.add_rule("table", {
      "border-collapse" => "collapse"
    })

    # .globalnav-container
    generator.add_rule(".globalnav-container", {
      "width" => "780px",
      "border" => "0",
      "cellpadding" => "0",
      "cellspacing" => "0"
    })

    # .header-left
    generator.add_rule(".header-left", {
      "vertical-align" => "top",
      "text-align" => "left"
    })

    # .header-right
    generator.add_rule(".header-right", {
      "vertical-align" => "top",
      "text-align" => "right"
    })

    # .logo-link
    generator.add_rule(".logo-link", {
      "text-decoration" => "none",
      "border" => "0"
    })

    # .logo-image
    generator.add_rule(".logo-image", {
      "border" => "0"
    })

    # .hosted-by
    generator.add_rule(".hosted-by", {
      "font-size" => "1px",
      "text-decoration" => "none"
    })

    # .active-state-logo
    generator.add_rule(".active-state-logo", {
      "border" => "0",
      "title" => "\"This site is hosted by ActiveState\""
    })

    # #globalnav
    generator.add_rule("#globalnav", {
      "clear" => "both"
    })

    # #globalnav ul
    generator.add_rule("#globalnav ul", {
      "list-style-type" => "none",
      "margin" => "0",
      "padding" => "0",
      "overflow" => "hidden"
    })

    # #globalnav li
    generator.add_rule("#globalnav li", {
      "float" => "left"
    })

    # #globalnav a
    generator.add_rule("#globalnav a", {
      "display" => "block",
      "padding" => "8px 16px",
      "text-decoration" => "none",
      "color" => "#000"
    })

    # #globalnav a.here
    generator.add_rule("#globalnav a.here", {
      "background-color" => "#3163CE",
      "color" => "white"
    })

    # .divider-top
    generator.add_rule(".divider-top", {
      "border-top" => "2px solid #3163CE",
      "width" => "780px"
    })

    # .search-table
    generator.add_rule(".search-table", {
      "width" => "780px",
      "border" => "0",
      "cellpadding" => "2",
      "cellspacing" => "0"
    })

    # .search-container
    generator.add_rule(".search-container", {
      "display" => "table-cell",
      "vertical-align" => "middle",
      "margin" => "0px"
    })

    # .search-form
    generator.add_rule(".search-form", {
      "display" => "inline"
    })

    # .search-input
    generator.add_rule(".search-input", {
      "size" => "20",
      "maxlength" => "255",
      "value" => "\"\""
    })

    # .submit-button
    generator.add_rule(".submit-button", {
      "border" => "0"
    })

    # .hidden-input
    generator.add_rule(".hidden-input", {
      "display" => "none"
    })

    # .banner
    generator.add_rule(".banner", {
      "text-align" => "right",
      "font-weight" => "bold",
      "margin" => "0"
    })

    # .divider-yellow
    generator.add_rule(".divider-yellow", {
      "border-top" => "1px solid #FFCE00",
      "margin-bottom" => "2px",
      "width" => "780px"
    })

    # .content-table
    generator.add_rule(".content-table", {
      "width" => "780px",
      "border" => "0",
      "cellpadding" => "0",
      "cellspacing" => "0"
    })

    # .keylist
    generator.add_rule(".keylist", {
      "margin" => "0",
      "padding" => "0"
    })

    # .keylist dt
    generator.add_rule(".keylist dt", {
      "font-weight" => "bold",
      "margin-top" => "10px"
    })

    # .keylist dd
    generator.add_rule(".keylist dd", {
      "margin-left" => "20px",
      "margin-bottom" => "10px"
    })

    # .footer
    generator.add_rule(".footer", {
      "text-align" => "center",
      "clear" => "both"
    })

    # .footer small
    generator.add_rule(".footer small", {
      "font-size" => "12px"
    })

    # .footer a
    generator.add_rule(".footer a", {
      "text-decoration" => "none",
      "color" => "#000"
    })

    # .footer a:hover
    generator.add_rule(".footer a:hover", {
      "text-decoration" => "underline"
    })

    # .clear
    generator.add_rule(".clear", {
      "clear" => "both"
    })

    generator
  end
end

# Main execution
if __FILE__ == $0
  if ARGV.length != 1
    puts "Usage: #{$0} <output_filename>"
    exit 1
  end

  filename = ARGV[0]
  generator = CSSGenerator.create_index_css
  generator.save_to_file(filename)
  puts "CSS file generated: #{filename}"
end
