#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "8a556d6ae048285bfc19a152b1063037a53d8414f9763711753e5bf83e0c7850", "source_sha256": "618fbec1aa70b1376cdfa3b8809f339c78f591a33e1ef35fb84ee21ffcdc97cf", "target_language": "ruby"}
# periodensystem.css — portiert nach ruby
# Quelle: css, Projects@abstractions:css/periodensystem.css
# Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

# abstraction-provenance: {"artifact_sha256": "57a7240136c3ce381e11df3125a02154266008c65c09f97475511fe273d71a65", "source_sha256": "dd2fb3ad5bb22a75afbf2a71e58025215a6cba660525d3fa1c6b4ea12fc311fb", "target_language": "ruby"}
# periodensystem.html — portiert nach css
# Quelle: html, Onboarding@main:docs/reference-library/examples/periodensystem.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

class PeriodensystemCSSGenerator
  def initialize
    @rules = []
  end

  def generate_css
    add_reset_styles
    add_variables
    add_dark_mode_variables
    add_body_styles
    add_typography
    add_detail_section
    add_grid_layout
    add_cell_styles
    add_category_colors
    add_dark_mode_category_colors
    add_legend_styles
    
    compile_css
  end

  private

  def add_rule(selector, properties)
    @rules << { selector: selector, properties: properties }
  end

  def add_reset_styles
    add_rule("*", {
      "box-sizing" => "border-box",
      "margin" => "0",
      "padding" => "0"
    })
  end

  def add_variables
    add_rule(":root", {
      "--bg" => "#fafaf7",
      "--surface" => "#ffffff",
      "--border" => "rgba(0,0,0,0.12)",
      "--text" => "#1a1a1a",
      "--text-muted" => "#666"
    })
  end

  def add_dark_mode_variables
    dark_rule = {
      "--bg" => "#1a1a1a",
      "--surface" => "#242424",
      "--border" => "rgba(255,255,255,0.15)",
      "--text" => "#f0f0f0",
      "--text-muted" => "#aaa"
    }
    
    @rules << {
      selector: "@media (prefers-color-scheme: dark)",
      nested_rules: [
        { selector: ":root", properties: dark_rule }
      ]
    }
  end

  def add_body_styles
    add_rule("body", {
      "font-family" => "-apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif",
      "background" => "var(--bg)",
      "color" => "var(--text)",
      "padding" => "24px",
      "max-width" => "1100px",
      "margin" => "0 auto",
      "line-height" => "1.5"
    })
  end

  def add_typography
    add_rule("h1", {
      "font-size" => "22px",
      "font-weight" => "500",
      "margin-bottom" => "4px"
    })

    add_rule(".subtitle", {
      "color" => "var(--text-muted)",
      "font-size" => "14px",
      "margin-bottom" => "20px"
    })
  end

  def add_detail_section
    add_rule(".detail", {
      "background" => "var(--surface)",
      "border" => "1px solid var(--border)",
      "border-radius" => "12px",
      "padding" => "16px 20px",
      "min-height" => "110px",
      "display" => "flex",
      "align-items" => "center",
      "gap" => "20px",
      "margin-bottom" => "16px"
    })

    add_rule(".detail-empty", {
      "color" => "var(--text-muted)",
      "font-size" => "14px",
      "text-align" => "center",
      "width" => "100%"
    })

    add_rule(".symbol-box", {
      "font-size" => "40px",
      "font-weight" => "500",
      "line-height" => "1",
      "width" => "80px",
      "height" => "80px",
      "display" => "flex",
      "align-items" => "center",
      "justify-content" => "center",
      "border-radius" => "8px",
      "flex-shrink" => "0"
    })

    add_rule(".info-name", {
      "font-size" => "20px",
      "font-weight" => "500",
      "margin-bottom" => "8px"
    })

    add_rule(".info-meta", {
      "font-size" => "13px",
      "color" => "var(--text-muted)",
      "display" => "grid",
      "grid-template-columns" => "repeat(2, minmax(0, 1fr))",
      "gap" => "4px 24px"
    })

    add_rule(".info-meta b", {
      "font-weight" => "500",
      "color" => "var(--text)",
      "margin-left" => "6px"
    })
  end

  def add_grid_layout
    add_rule(".grid", {
      "display" => "grid",
      "grid-template-columns" => "repeat(18, minmax(0, 1fr))",
      "gap" => "3px"
    })

    add_rule(".fgrid", {
      "margin-top" => "8px"
    })
  end

  def add_cell_styles
    add_rule(".cell", {
      "aspect-ratio" => "1",
      "border-radius" => "4px",
      "padding" => "3px",
      "display" => "flex",
      "flex-direction" => "column",
      "align-items" => "center",
      "justify-content" => "center",
      "cursor" => "pointer",
      "font-family" => "inherit",
      "line-height" => "1",
      "transition" => "transform 0.12s ease",
      "border" => "0",
      "position" => "relative",
      "overflow" => "hidden"
    })

    add_rule(".cell:hover", {
      "transform" => "scale(1.18)",
      "z-index" => "5",
      "box-shadow" => "0 2px 8px rgba(0,0,0,0.15)"
    })

    add_rule(".cell:focus-visible", {
      "outline" => "2px solid var(--text)",
      "outline-offset" => "1px"
    })

    add_rule(".cell.active", {
      "outline" => "2px solid var(--text)",
      "outline-offset" => "1px",
      "z-index" => "4"
    })

    add_rule(".cell .num", {
      "font-size" => "9px",
      "opacity" => "0.75",
      "align-self" => "flex-start",
      "line-height" => "1",
      "padding-left" => "2px"
    })

    add_rule(".cell .sym", {
      "font-size" => "14px",
      "font-weight" => "500",
      "margin-top" => "2px"
    })

    add_rule(".cell-marker", {
      "cursor" => "default",
      "font-size" => "9px",
      "font-weight" => "500",
      "border" => "1px dashed currentColor",
      "background" => "transparent !important"
    })

    add_rule(".cell-marker:hover", {
      "transform" => "none",
      "box-shadow" => "none"
    })
  end

  def add_category_colors
    categories = {
      ".cat-am" => { bg: "#FCEBEB", color: "#501313" },
      ".cat-em" => { bg: "#FAEEDA", color: "#412402" },
      ".cat-tm" => { bg: "#E6F1FB", color: "#042C53" },
      ".cat-ptm" => { bg: "#F1EFE8", color: "#2C2C2A" },
      ".cat-hm" => { bg: "#E1F5EE", color: "#04342C" },
      ".cat-nm" => { bg: "#EAF3DE", color: "#173404" },
      ".cat-h" => { bg: "#EEEDFE", color: "#26215C" },
      ".cat-eg" => { bg: "#FBEAF0", color: "#4B1528" },
      ".cat-la" => { bg: "#FAECE7", color: "#4A1B0C" },
      ".cat-ac" => { bg: "#F5C4B3", color: "#4A1B0C" }
    }

    categories.each do |selector, colors|
      add_rule(selector, {
        "background" => colors[:bg],
        "color" => colors[:color]
      })
    end
  end

  def add_dark_mode_category_colors
    dark_categories = {
      ".cat-am" => { bg: "#791F1F", color: "#F7C1C1" },
      ".cat-em" => { bg: "#633806", color: "#FAC775" },
      ".cat-tm" => { bg: "#0C447C", color: "#B5D4F4" },
      ".cat-ptm" => { bg: "#444441", color: "#D3D1C7" },
      ".cat-hm" => { bg: "#085041", color: "#9FE1CB" },
      ".cat-nm" => { bg: "#27500A", color: "#C0DD97" },
      ".cat-h" => { bg: "#3C3489", color: "#CECBF6" },
      ".cat-eg" => { bg: "#72243E", color: "#F4C0D1" },
      ".cat-la" => { bg: "#712B13", color: "#F5C4B3" },
      ".cat-ac" => { bg: "#993C1D", color: "#F5C4B3" }
    }

    dark_rules = dark_categories.map do |selector, colors|
      {
        selector: selector,
        properties: {
          "background" => colors[:bg],
          "color" => colors[:color]
        }
      }
    end

    @rules << {
      selector: "@media (prefers-color-scheme: dark)",
      nested_rules: dark_rules
    }
  end

  def add_legend_styles
    add_rule(".legend", {
      "display" => "grid",
      "grid-template-columns" => "repeat(auto-fit, minmax(160px, 1fr))",
      "gap" => "8px 16px",
      "margin-top" => "24px",
      "font-size" => "12px",
      "color" => "var(--text-muted)"
    })

    add_rule(".legend-item", {
      "display" => "flex",
      "align-items" => "center",
      "gap" => "8px"
    })

    add_rule(".legend-swatch", {
      "width" => "14px",
      "height" => "14px",
      "border-radius" => "3px",
      "flex-shrink" => "0"
    })
  end

  def compile_css
    css = ""
    
    @rules.each do |rule|
      if rule[:nested_rules]
        css += "#{rule[:selector]} {\n"
        rule[:nested_rules].each do |nested_rule|
          css += "  #{nested_rule[:selector]} {\n"
          nested_rule[:properties].each do |prop, value|
            css += "    #{prop}: #{value};\n"
          end
          css += "  }\n"
        end
        css += "}\n\n"
      else
        css += "#{rule[:selector]} {\n"
        rule[:properties].each do |prop, value|
          css += "  #{prop}: #{value};\n"
        end
        css += "}\n\n"
      end
    end
    
    css
  end
end

# Hauptprogramm
if __FILE__ == $0
  generator = PeriodensystemCSSGenerator.new
  css_content = generator.generate_css
  
  if ARGV.length > 0
    File.write(ARGV[0], css_content)
    puts "CSS wurde in '#{ARGV[0]}' geschrieben."
  else
    puts css_content
  end
end
