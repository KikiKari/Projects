#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "b70acf80845fa5a4333345051a159538d70cd381680442f541fa592b73ef081f", "source_sha256": "902e4e6fa157d8f76bb20b7b21eb51af1e266f087317cd16510ad7f701088c8a", "target_language": "ruby"}
# index_8000e9.css — portiert nach ruby
# Quelle: css, Projects@abstractions:css/index_8000e9.css
# Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

# abstraction-provenance: {"artifact_sha256": "50aebf2d1d10e4ad074a50e2b0bd451a6c86206ca6d2a94a111305552465c90c", "source_sha256": "8000e9809d37f9906f93defd5eae67343fbc40139349c6251ff385eeee2cb8fb", "target_language": "ruby"}
# index.html — portiert nach css
# Quelle: html, Onboarding@main:development/preview-renders/hover-mock/index.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

class CSSGenerator
  def initialize
    @variables = {
      '--bg' => '#FAF8F4',
      '--ink' => '#1B1A17',
      '--accent' => '#A8542F',
      '--accent-2' => '#2E7D7B',
      '--font-display' => "'Newsreader', Georgia, serif",
      '--font-body' => "'Hanken Grotesk', -apple-system, sans-serif",
      '--font-mono' => "'JetBrains Mono', monospace"
    }
    
    @rules = []
  end
  
  def generate_css
    css = []
    
    # Root variables
    css << ":root {"
    @variables.each do |name, value|
      css << "  #{name}: #{value};"
    end
    css << "}\n"
    
    # Universal selector
    css << "* {"
    css << "  box-sizing: border-box;"
    css << "  margin: 0;"
    css << "  padding: 0;"
    css << "}\n"
    
    # Body styles
    css << "body {"
    css << "  font-family: var(--font-body);"
    css << "  background: var(--bg);"
    css << "  color: var(--ink);"
    css << "  padding: 32px 16px 80px;"
    css << "}\n"
    
    # Heading styles
    css << "h1 {"
    css << "  font-family: var(--font-display);"
    css << "  font-weight: 500;"
    css << "  font-size: 28px;"
    css << "  max-width: 1400px;"
    css << "  margin: 0 auto 12px;"
    css << "}\n"
    
    # Intro styles
    css << ".intro {"
    css << "  max-width: 1400px;"
    css << "  margin: 0 auto 32px;"
    css << "  color: #666;"
    css << "  font-size: 14px;"
    css << "  line-height: 1.5;"
    css << "}\n"
    
    # Grid layout
    css << ".grid {"
    css << "  display: grid;"
    css << "  gap: 32px;"
    css << "  max-width: 1400px;"
    css << "  margin: 0 auto;"
    css << "}\n"
    
    # Variant container
    css << ".variant {"
    css << "  background: #000;"
    css << "  border-radius: 16px;"
    css << "  overflow: hidden;"
    css << "  box-shadow: 0 12px 40px rgba(0,0,0,0.15);"
    css << "}\n"
    
    # Variant header
    css << ".variant-header {"
    css << "  background: #fff;"
    css << "  padding: 16px 24px;"
    css << "  display: flex;"
    css << "  align-items: center;"
    css << "  justify-content: space-between;"
    css << "  gap: 16px;"
    css << "  border-bottom: 1px solid #eee;"
    css << "}\n"
    
    # Variant label
    css << ".variant-label {"
    css << "  font-family: var(--font-mono);"
    css << "  font-size: 11px;"
    css << "  letter-spacing: 0.2em;"
    css << "  text-transform: uppercase;"
    css << "  color: var(--accent);"
    css << "  font-weight: 600;"
    css << "}\n"
    
    # Variant title
    css << ".variant-title {"
    css << "  font-family: var(--font-display);"
    css << "  font-size: 20px;"
    css << "  font-weight: 500;"
    css << "}\n"
    
    # Variant description
    css << ".variant-desc {"
    css << "  font-size: 13px;"
    css << "  color: #666;"
    css << "  flex: 1;"
    css << "  text-align: right;"
    css << "}\n"
    
    # Scene container
    css << ".scene {"
    css << "  position: relative;"
    css << "  aspect-ratio: 16 / 9;"
    css << "  background: url('bg.png') center/cover no-repeat;"
    css << "  overflow: hidden;"
    css << "}\n"
    
    # Orb element
    css << ".orb {"
    css << "  position: absolute;"
    css << "  width: 12%;"
    css << "  aspect-ratio: 1;"
    css << "  left: 42%;"
    css << "  top: 55%;"
    css << "  transform: translate(-50%, -50%);"
    css << "  cursor: pointer;"
    css << "}\n"
    
    # Orb image
    css << ".orb img {"
    css << "  width: 100%;"
    css << "  height: 100%;"
    css << "  object-fit: contain;"
    css << "}\n"
    
    # Card preview
    css << ".card-preview {"
    css << "  position: absolute;"
    css << "  left: 55%;"
    css << "  top: 45%;"
    css << "  background: rgba(255,255,255,0.98);"
    css << "  padding: 16px 20px;"
    css << "  border-radius: 12px;"
    css << "  box-shadow: 0 8px 24px rgba(0,0,0,0.25);"
    css << "  width: 240px;"
    css << "  animation: slideIn 0.3s ease-out;"
    css << "}\n"
    
    # Badge style
    css << ".card-preview .badge {"
    css << "  display: inline-block;"
    css << "  background: var(--accent-2);"
    css << "  color: white;"
    css << "  font-family: var(--font-mono);"
    css << "  font-size: 9px;"
    css << "  letter-spacing: 0.15em;"
    css << "  text-transform: uppercase;"
    css << "  padding: 3px 8px;"
    css << "  border-radius: 3px;"
    css << "  margin-bottom: 8px;"
    css << "}\n"
    
    # Card preview heading
    css << ".card-preview h3 {"
    css << "  font-family: var(--font-display);"
    css << "  font-size: 18px;"
    css << "  font-weight: 500;"
    css << "  margin-bottom: 6px;"
    css << "  color: var(--ink);"
    css << "}\n"
    
    # Card preview paragraph
    css << ".card-preview p {"
    css << "  font-size: 12px;"
    css << "  color: #555;"
    css << "  line-height: 1.4;"
    css << "}\n"
    
    # Slide in animation
    css << "@keyframes slideIn {"
    css << "  from {"
    css << "    opacity: 0;"
    css << "    transform: translateX(-8px);"
    css << "  }"
    css << "  to {"
    css << "    opacity: 1;"
    css << "    transform: translateX(0);"
    css << "  }"
    css << "}\n"
    
    # Tooltip
    css << ".tooltip {"
    css << "  position: absolute;"
    css << "  left: 42%;"
    css << "  top: 46%;"
    css << "  transform: translate(-50%, -100%);"
    css << "  color: white;"
    css << "  text-shadow: 0 2px 12px rgba(0,0,0,0.8);"
    css << "  font-family: var(--font-display);"
    css << "  font-size: 20px;"
    css << "  font-weight: 500;"
    css << "  white-space: nowrap;"
    css << "  animation: fadeUp 0.3s ease-out;"
    css << "}\n"
    
    # Fade up animation
    css << "@keyframes fadeUp {"
    css << "  from {"
    css << "    opacity: 0;"
    css << "    transform: translate(-50%, -80%);"
    css << "  }"
    css << "  to {"
    css << "    opacity: 1;"
    css << "    transform: translate(-50%, -100%);"
    css << "  }"
    css << "}\n"
    
    # Full overlay
    css << ".full-overlay {"
    css << "  position: absolute;"
    css << "  inset: 0;"
    css << "  background: rgba(0,0,0,0.5);"
    css << "  backdrop-filter: blur(6px);"
    css << "  display: flex;"
    css << "  align-items: center;"
    css << "  justify-content: center;"
    css << "  animation: fadeIn 0.35s ease-out;"
    css << "}\n"
    
    # Overlay panel
    css << ".full-overlay .panel {"
    css << "  background: rgba(255,255,255,0.98);"
    css << "  padding: 32px 40px;"
    css << "  border-radius: 20px;"
    css << "  max-width: 420px;"
    css << "  box-shadow: 0 20px 60px rgba(0,0,0,0.4);"
    css << "  text-align: center;"
    css << "}\n"
    
    # Overlay badge
    css << ".full-overlay .badge {"
    css << "  display: inline-block;"
    css << "  background: var(--accent);"
    css << "  color: white;"
    css << "  font-family: var(--font-mono);"
    css << "  font-size: 10px;"
    css << "  letter-spacing: 0.2em;"
    css << "  text-transform: uppercase;"
    css << "  padding: 4px 10px;"
    css << "  border-radius: 4px;"
    css << "  margin-bottom: 14px;"
    css << "}\n"
    
    # Overlay heading
    css << ".full-overlay h3 {"
    css << "  font-family: var(--font-display);"
    css << "  font-size: 28px;"
    css << "  font-weight: 500;"
    css << "  margin-bottom: 10px;"
    css << "  color: var(--ink);"
    css << "}\n"
    
    # Overlay paragraph
    css << ".full-overlay p {"
    css << "  font-size: 14px;"
    css << "  color: #555;"
    css << "  line-height: 1.5;"
    css << "  margin-bottom: 20px;"
    css << "}\n"
    
    # Preview image
    css << ".full-overlay .preview-img {"
    css << "  width: 100%;"
    css << "  aspect-ratio: 16/10;"
    css << "  background: linear-gradient(135deg, #A8542F, #2E7D7B);"
    css << "  border-radius: 8px;"
    css << "  margin-bottom: 16px;"
    css << "  display: flex;"
    css << "  align-items: center;"
    css << "  justify-content: center;"
    css << "  color: white;"
    css << "  font-family: var(--font-mono);"
    css << "  font-size: 11px;"
    css << "  letter-spacing: 0.15em;"
    css << "  opacity: 0.9;"
    css << "}\n"
    
    # Fade in animation
    css << "@keyframes fadeIn {"
    css << "  from {"
    css << "    opacity: 0;"
    css << "  }"
    css << "  to {"
    css << "    opacity: 1;"
    css << "  }"
    css << "}\n"
    
    # Instruction text
    css << ".instruction {"
    css << "  text-align: center;"
    css << "  color: #999;"
    css << "  font-size: 12px;"
    css << "  margin-top: 16px;"
    css << "  font-family: var(--font-mono);"
    css << "  letter-spacing: 0.15em;"
    css << "  text-transform: uppercase;"
    css << "}\n"
    
    # Media query for smaller screens
    css << "@media (max-width: 900px) {"
    css << "  .card-preview {"
    css << "    width: 180px;"
    css << "    padding: 12px 14px;"
    css << "  }"
    css << "  "
    css << "  .card-preview h3 {"
    css << "    font-size: 15px;"
    css << "  }"
    css << "  "
    css << "  .card-preview p {"
    css << "    font-size: 11px;"
    css << "  }"
    css << "  "
    css << "  .tooltip {"
    css << "    font-size: 15px;"
    css << "  }"
    css << "  "
    css << "  .full-overlay .panel {"
    css << "    padding: 20px 24px;"
    css << "    max-width: 300px;"
    css << "  }"
    css << "  "
    css << "  .full-overlay h3 {"
    css << "    font-size: 20px;"
    css << "  }"
    css << "}"
    
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
    puts "Usage: #{$0} <output_filename>"
    exit 1
  end
  
  generator = CSSGenerator.new
  generator.write_to_file(ARGV[0])
end
