#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "8dd309bdd4036230493d8ebc150c53a4e6be1a53fd1f60f08305ca952ea9faf9", "source_sha256": "b32c733987d23de98ace1b2a5119f7cb7989a0887c165c1db133ecb4ef278438", "target_language": "ruby"}
# index_f17dea.css — portiert nach ruby
# Quelle: css, Projects@abstractions:css/index_f17dea.css
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

# abstraction-provenance: {"artifact_sha256": "9ebfdd610ffe88b7273a5ac8e215314a7bee0dffecf25fe9a995b6a39703e204", "source_sha256": "f17deae3e31b89fd76d250bd20903b36591af417c97b34d987e923632be9ac37", "target_language": "ruby"}
# index.html — portiert nach css
# Quelle: html, OpenClaw@gateway1:skills/scripting-utils/references/raku/index.html
# auch in: OpenClaw@gateway2:skills/scripting-utils/references/raku/index.html
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

class CSSGenerator
  def initialize
    @rules = {}
  end

  def add_rule(selector, properties)
    @rules[selector] = properties
  end

  def generate_css
    css = ""
    @rules.each do |selector, properties|
      css += "#{selector} {\n"
      properties.each do |property, value|
        css += "    #{property}: #{value};\n"
      end
      css += "}\n\n"
    end
    css
  end

  def write_to_file(filename)
    File.open(filename, 'w') do |file|
      file.write(generate_css)
    end
  end

  def self.create_index_css
    generator = new

    # General Styles
    generator.add_rule("html", {
      "scroll-padding-top" => "60px"
    })

    generator.add_rule("body.has-navbar-fixed-top", {
      "padding-top" => "60px"
    })

    # Navbar Styles
    generator.add_rule(".navbar.is-fixed-top", {
      "position" => "fixed",
      "top" => "0",
      "left" => "0",
      "right" => "0",
      "z-index" => "30",
      "min-height" => "3.25rem"
    })

    generator.add_rule(".navbar.is-flex-touch", {
      "display" => "flex"
    })

    generator.add_rule(".container.is-justify-content-space-around", {
      "justify-content" => "space-around"
    })

    generator.add_rule(".navbar-brand", {
      "display" => "flex",
      "align-items" => "center"
    })

    generator.add_rule(".navbar-logo", {
      "display" => "flex",
      "align-items" => "center"
    })

    generator.add_rule(".navbar-logo-tm", {
      "font-size" => "0.75rem",
      "margin-left" => "0.25rem"
    })

    generator.add_rule(".navbar-burger", {
      "display" => "block",
      "position" => "relative",
      "cursor" => "pointer"
    })

    generator.add_rule(".navbar-burger span", {
      "display" => "block",
      "height" => "1px",
      "width" => "20px",
      "background-color" => "currentColor",
      "margin" => "5px 0",
      "transition" => "transform 0.3s ease"
    })

    generator.add_rule(".navbar-menu", {
      "display" => "none"
    })

    generator.add_rule(".navbar-start, .navbar-end", {
      "display" => "flex",
      "align-items" => "center"
    })

    generator.add_rule(".navbar-item", {
      "display" => "block",
      "padding" => "0.5rem 0.75rem"
    })

    generator.add_rule(".navbar-link", {
      "display" => "block",
      "padding" => "0.5rem 0.75rem"
    })

    generator.add_rule(".navbar-dropdown", {
      "display" => "none",
      "position" => "absolute",
      "top" => "100%",
      "left" => "0",
      "background-color" => "white",
      "border-radius" => "4px",
      "box-shadow" => "0 0.5em 1em -0.125em rgba(10, 10, 10, 0.1)"
    })

    generator.add_rule(".navbar-dropdown.is-right", {
      "left" => "auto",
      "right" => "0"
    })

    generator.add_rule(".navbar-dropdown.is-rounded", {
      "border-radius" => "4px"
    })

    generator.add_rule(".navbar-divider", {
      "display" => "block",
      "height" => "1px",
      "background-color" => "#dbdbdb",
      "margin" => "0.5rem 0"
    })

    generator.add_rule(".has-dropdown:hover .navbar-dropdown", {
      "display" => "block"
    })

    generator.add_rule(".navbar-search-wrapper", {
      "display" => "flex",
      "align-items" => "center"
    })

    generator.add_rule(".field.has-addons", {
      "display" => "flex"
    })

    generator.add_rule(".control", {
      "position" => "relative"
    })

    generator.add_rule(".autoComplete_options", {
      "flex-grow" => "1"
    })

    generator.add_rule(".input", {
      "display" => "block",
      "width" => "100%",
      "padding" => "0.375rem 0.75rem",
      "font-size" => "1rem",
      "line-height" => "1.5",
      "color" => "#495057",
      "background-color" => "#fff",
      "background-clip" => "padding-box",
      "border" => "1px solid #ced4da",
      "border-radius" => "0.25rem",
      "transition" => "border-color 0.15s ease-in-out, box-shadow 0.15s ease-in-out"
    })

    generator.add_rule(".button.is-primary", {
      "background-color" => "#00d1b2",
      "border-color" => "transparent",
      "color" => "#fff"
    })

    generator.add_rule(".icon", {
      "display" => "inline-flex",
      "justify-content" => "center",
      "align-items" => "center"
    })

    generator.add_rule(".modal", {
      "position" => "fixed",
      "top" => "0",
      "left" => "0",
      "right" => "0",
      "bottom" => "0",
      "z-index" => "40",
      "display" => "none",
      "opacity" => "0",
      "transition" => "opacity 0.15s linear"
    })

    generator.add_rule(".modal.is-active", {
      "display" => "flex",
      "opacity" => "1"
    })

    generator.add_rule(".modal-background", {
      "position" => "absolute",
      "top" => "0",
      "left" => "0",
      "right" => "0",
      "bottom" => "0",
      "background-color" => "rgba(10, 10, 10, 0.86)"
    })

    generator.add_rule(".modal-content", {
      "position" => "relative",
      "width" => "100%",
      "max-height" => "calc(100vh - 160px)",
      "overflow" => "auto",
      "margin" => "0 auto",
      "padding" => "20px"
    })

    generator.add_rule(".box", {
      "background-color" => "white",
      "border-radius" => "6px",
      "box-shadow" => "0 0.5em 1em -0.125em rgba(10, 10, 10, 0.1), 0 0 0 1px rgba(10, 10, 10, 0.02)",
      "padding" => "1.25rem"
    })

    generator.add_rule(".modal-close", {
      "position" => "absolute",
      "top" => "20px",
      "right" => "20px",
      "width" => "40px",
      "height" => "40px",
      "background" => "none",
      "border" => "none",
      "cursor" => "pointer"
    })

    generator.add_rule(".options-search-controls", {
      "display" => "flex",
      "flex-direction" => "column",
      "gap" => "1rem"
    })

    generator.add_rule(".centreToggle", {
      "display" => "flex",
      "align-items" => "center",
      "gap" => "0.5rem"
    })

    generator.add_rule(".centreToggle input[type=\"checkbox\"]", {
      "width" => "var(--switch-width, 10.5em)",
      "height" => "2em",
      "appearance" => "none",
      "background" => "#ccc",
      "border-radius" => "1em",
      "position" => "relative",
      "cursor" => "pointer"
    })

    generator.add_rule(".centreToggle input[type=\"checkbox\"]:checked", {
      "background" => "#00d1b2"
    })

    generator.add_rule(".centreToggle input[type=\"checkbox\"]::before", {
      "content" => "''",
      "position" => "absolute",
      "width" => "1.6em",
      "height" => "1.6em",
      "background" => "white",
      "border-radius" => "50%",
      "top" => "0.2em",
      "left" => "0.2em",
      "transition" => "transform 0.3s"
    })

    generator.add_rule(".centreToggle input[type=\"checkbox\"]:checked::before", {
      "transform" => "translateX(calc(var(--switch-width, 10.5em) - 2em))"
    })

    generator.add_rule(".centreToggle .text,\n.centreToggle .on,\n.centreToggle .off", {
      "font-weight" => "bold"
    })

    generator.add_rule(".centreToggle .on,\n.centreToggle .off", {
      "position" => "absolute",
      "top" => "50%",
      "transform" => "translateY(-50%)"
    })

    generator.add_rule(".centreToggle .on", {
      "left" => "0.5em",
      "color" => "white"
    })

    generator.add_rule(".centreToggle .off", {
      "right" => "0.5em",
      "color" => "#333"
    })

    # Hero Section
    generator.add_rule(".hero.is-medium", {
      "min-height" => "300px"
    })

    generator.add_rule(".hero.is-primary", {
      "background-color" => "#00d1b2",
      "color" => "#fff"
    })

    generator.add_rule(".hero-body", {
      "padding" => "3rem 1.5rem"
    })

    generator.add_rule(".title.is-1", {
      "font-size" => "3rem"
    })

    generator.add_rule(".subtitle.is-4", {
      "font-size" => "1.5rem"
    })

    generator.add_rule(".mt-3", {
      "margin-top" => "0.75rem"
    })

    generator.add_rule(".has-text-centered", {
      "text-align" => "center"
    })

    # Cards
    generator.add_rule(".card-home", {
      "border-radius" => "6px",
      "box-shadow" => "0 0.5em 1em -0.125em rgba(10, 10, 10, 0.1), 0 0 0 1px rgba(10, 10, 10, 0.02)",
      "background-color" => "white",
      "margin-bottom" => "1.5rem"
    })

    generator.add_rule(".card-content", {
      "padding" => "1.5rem"
    })

    generator.add_rule(".content.has-text-centered", {
      "text-align" => "center"
    })

    generator.add_rule(".title.is-5", {
      "font-size" => "1.25rem",
      "margin-bottom" => "0.5rem"
    })

    generator.add_rule(".has-text-primary", {
      "color" => "#00d1b2 !important"
    })

    generator.add_rule(".icon.is-large", {
      "font-size" => "2rem"
    })

    # Links Block
    generator.add_rule(".raku.links-block", {
      "background-color" => "#f5f5f5",
      "padding" => "2rem 0"
    })

    generator.add_rule(".columns.is-vcentered", {
      "align-items" => "center"
    })

    generator.add_rule(".column.is-one-third", {
      "flex" => "none",
      "width" => "33.3333%"
    })

    generator.add_rule(".column.is-two-thirds", {
      "flex" => "none",
      "width" => "66.6666%"
    })

    generator.add_rule(".pt-5", {
      "padding-top" => "1.5rem"
    })

    generator.add_rule(".head", {
      "font-weight" => "bold",
      "margin-bottom" => "0.5rem"
    })

    # Footer
    generator.add_rule(".footer.main-footer", {
      "background-color" => "#fafafa",
      "padding" => "3rem 1.5rem"
    })

    generator.add_rule(".level", {
      "display" => "flex",
      "justify-content" => "space-between",
      "align-items" => "center"
    })

    generator.add_rule(".level-left, .level-right", {
      "display" => "flex",
      "align-items" => "center"
    })

    generator.add_rule(".level-item", {
      "margin" => "0 0.5rem"
    })

    # Responsive Adjustments
    generator.add_rule("@media screen and (max-width: 1023px)", {
      ".navbar-menu" => "{\n        background-color: white;\n        box-shadow: 0 8px 16px rgba(10, 10, 10, 0.1);\n        padding: 0.5rem 0;\n    }",
      ".navbar-menu.is-active" => "{\n        display: block;\n    }",
      ".navbar-end" => "{\n        margin-top: 1rem;\n    }"
    })

    generator.add_rule("@media screen and (max-width: 768px)", {
      ".title.is-1.is-size-2-mobile" => "{\n        font-size: 2rem;\n    }",
      ".columns.is-multiline" => "{\n        display: flex;\n        flex-wrap: wrap;\n    }",
      ".column.is-one-half, \n    .column.is-one-third" => "{\n        width: 100%;\n    }",
      ".raku.links-block .columns" => "{\n        flex-direction: column;\n    }",
      ".column.is-one-third, \n    .column.is-two-thirds" => "{\n        width: 100%;\n    }"
    })

    generator
  end
end

# Hauptprogramm
if __FILE__ == $0
  if ARGV.length != 1
    puts "Verwendung: #{$0} <ausgabedatei>"
    exit 1
  end

  output_file = ARGV[0]
  generator = CSSGenerator.create_index_css
  generator.write_to_file(output_file)
  puts "CSS-Datei wurde erfolgreich erstellt: #{output_file}"
end
