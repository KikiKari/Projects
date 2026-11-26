#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "3c371944c6f991ce269e9b38269326ef2ba7eea218e002d14b7adb59c4217a7e", "source_sha256": "fce23ec10c43acef00ba36b3975889539f87b908bd4cfce77616443d2b5f569e", "target_language": "ruby"}
# icon-controls.css — portiert nach ruby
# Quelle: css, Projects@TikTok-Live-Companion:plugin-source/browser-extension/icon-controls.css
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/icon-controls.css
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/icon-controls.css
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/browser-extension/icon-controls.css
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# Generates CSS for icon controls based on different icon styles
class IconControlsGenerator
  ICON_STYLES = %w[plastisch glass linear].freeze
  ICONS = %w[
    auto-chat-refresh-counter browser captions chat-counter fullscreen mute
    off on pip play player protection-slider recommendation-counter report
    reset settings status stop unmute volume-slider
  ].freeze

  def initialize
    @styles = {}
    generate_styles
  end

  def generate_css
    css = []
    
    # Generate style definitions
    ICON_STYLES.each do |style|
      css << "html[data-icon-style=\"#{style}\"] {"
      ICONS.each do |icon|
        css << "--icon-#{icon}:url(\"icons/#{style}/#{icon}.png\");"
      end
      css << "}"
    end
    
    # Add control button styles
    css << <<~CSS
      button[data-control-icon]::before,.control-icon::before { content:""; display:inline-block; width:32px; height:32px; flex:0 0 32px; background:var(--control-icon) center/contain no-repeat; vertical-align:middle; margin-inline-end:0; pointer-events:none; }
      button[data-control-icon] { min-height:44px; min-width:44px; font-size:0; display:inline-flex; align-items:center; justify-content:center; }
      button[data-control-icon][hidden] { display:none; }
    CSS
    
    # Add checkbox styles
    css << <<~CSS
      input[type="checkbox"] { appearance:none; -webkit-appearance:none; width:44px; height:44px; min-width:44px; border:0; background:var(--icon-off) center/40px no-repeat; cursor:pointer; vertical-align:middle; }
      input[type="checkbox"]:checked { background-image:var(--icon-on); }
      input[type="checkbox"]:focus-visible,button[data-control-icon]:focus-visible { outline:2px solid #1769df; outline-offset:2px; }
      input[type="checkbox"]:disabled { opacity:.45; cursor:default; }
    CSS
    
    # Add other control styles
    css << <<~CSS
      .control-icon { display:inline-flex; align-items:center; }
      input[type="range"] { min-height:32px; }
      .icon-style-setting { display:flex; align-items:center; gap:8px; }
    CSS
    
    # Add individual icon control definitions
    ICONS.each do |icon|
      css << "[data-control-icon=\"#{icon}\"] { --control-icon:var(--icon-#{icon}); }"
    end
    
    css.join("\n")
  end

  private

  def generate_styles
    ICON_STYLES.each do |style|
      @styles[style] = {}
      ICONS.each do |icon|
        @styles[style][icon] = "url(\"icons/#{style}/#{icon}.png\")"
      end
    end
  end
end

# Main execution
if __FILE__ == $0
  if ARGV.length != 1
    puts "Usage: #{$PROGRAM_NAME} <output_file>"
    exit 1
  end

  output_file = ARGV[0]
  generator = IconControlsGenerator.new
  
  File.open(output_file, 'w') do |file|
    file.write(generator.generate_css)
  end
  
  puts "CSS file generated: #{output_file}"
end
