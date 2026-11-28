#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "53ac498fc2fbe8e194ffab4e721164e014e9314f3ddb657e374090ef8d9315d1", "source_sha256": "58d92c4f40bf7edb6d494c682f4fa1268aea0c52ab326535c779d2f2c808fffd", "target_language": "ruby"}
# index_02dd11.css — portiert nach ruby
# Quelle: css, Projects@abstractions:css/index_02dd11.css
# Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

# abstraction-provenance: {"artifact_sha256": "8b76660533c644ac76ba28b4dcfb567e78b781d329ee59f8e75ceb7f8348f402", "source_sha256": "02dd111b283ac08d7a9f3fbbe30150fb6db98097ed7bc68f2677c6df9c744bfb", "target_language": "ruby"}
# index.html — portiert nach css
# Quelle: html, Projects@Vision-Check:Vision-Check/app/index.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

class CSSGenerator
  def initialize
    @variables = {
      '--bg-dark' => '#0a0f1e',
      '--bg-card' => '#121826',
      '--bg-panel' => '#1a2236',
      '--border' => '#25324d',
      '--text-main' => '#e6ecf5',
      '--text-muted' => '#a0b0cc',
      '--text-dim' => '#6c7a96',
      '--accent' => '#5d8aff',
      '--accent-hover' => '#7a9fff',
      '--accent-warn' => '#fbd38d',
      '--layer-0' => '#ff7eb9',
      '--layer-1' => '#4fd1c5',
      '--layer-2' => '#ffd166',
      '--layer-3-gpt' => '#6a5acd',
      '--layer-3-gemini' => '#4285f4',
      '--layer-3-claude' => '#f4a261'
    }
  end

  def generate_css
    css = []
    
    # Add comment header
    css << "/* abstraction-provenance: {\"artifact_sha256\": \"8b76660533c644ac76ba28b4dcfb567e78b781d329ee59f8e75ceb7f8348f402\", \"source_sha256\": \"02dd111b283ac08d7a9f3fbbe30150fb6db98097ed7bc68f2677c6df9c744bfb\", \"target_language\": \"css\"} */"
    css << "/* index.html — portiert nach css */"
    css << "/* Quelle: html, Projects@Vision-Check:Vision-Check/app/index.html */"
    css << "/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */"
    css << ""
    
    # Root variables
    css << "/* Root-Variablen */"
    css << ":root {"
    @variables.each do |key, value|
      css << "  #{key}: #{value};"
    end
    css << "}"
    css << ""
    
    # Base styles
    css << "/* Basis-Stile */"
    css << "* {"
    css << "  box-sizing: border-box;"
    css << "  margin: 0;"
    css << "  padding: 0;"
    css << "}"
    css << ""
    
    css << "body {"
    css << "  font-family: 'Inter', sans-serif;"
    css << "  background: var(--bg-dark);"
    css << "  color: var(--text-main);"
    css << "  line-height: 1.5;"
    css << "  overflow: hidden;"
    css << "  height: 100vh;"
    css << "  display: flex;"
    css << "  flex-direction: column;"
    css << "}"
    css << ""
    
    # Header
    css << "/* Header */"
    css << "#app-header {"
    css << "  display: flex;"
    css << "  align-items: center;"
    css << "  justify-content: space-between;"
    css << "  padding: 12px 20px;"
    css << "  background: rgba(10, 15, 30, 0.8);"
    css << "  backdrop-filter: blur(10px);"
    css << "  border-bottom: 1px solid var(--border);"
    css << "  position: relative;"
    css << "  z-index: 10;"
    css << "}"
    css << ""
    
    css << ".header-brand {"
    css << "  display: flex;"
    css << "  align-items: center;"
    css << "  gap: 10px;"
    css << "}"
    css << ""
    
    css << ".header-brand h1 {"
    css << "  font-size: 18px;"
    css << "  font-weight: 600;"
    css << "  color: var(--text-main);"
    css << "}"
    css << ""
    
    css << ".layer-indicator {"
    css << "  display: flex;"
    css << "  align-items: center;"
    css << "  gap: 4px;"
    css << "}"
    css << ""
    
    css << ".layer-dot {"
    css << "  width: 8px;"
    css << "  height: 8px;"
    css << "  border-radius: 50%;"
    css << "  opacity: 0.4;"
    css << "}"
    css << ""
    
    css << ".layer-dot.active {"
    css << "  opacity: 1;"
    css << "  box-shadow: 0 0 6px currentColor;"
    css << "}"
    css << ""
    
    css << ".header-controls {"
    css << "  display: flex;"
    css << "  gap: 8px;"
    css << "}"
    css << ""
    
    # Main area
    css << "/* Hauptbereich */"
    css << "#board {"
    css << "  display: flex;"
    css << "  flex: 1;"
    css << "  overflow: hidden;"
    css << "  padding: 16px;"
    css << "  gap: 16px;"
    css << "}"
    css << ""
    
    # Camera panel
    css << "/* Kamera-Panel */"
    css << "#camera-panel {"
    css << "  flex: 1;"
    css << "  display: flex;"
    css << "  flex-direction: column;"
    css << "  background: var(--bg-card);"
    css << "  border-radius: 16px;"
    css << "  border: 1px solid var(--border);"
    css << "  overflow: hidden;"
    css << "  min-width: 320px;"
    css << "}"
    css << ""
    
    css << ".panel-header {"
    css << "  display: flex;"
    css << "  justify-content: space-between;"
    css << "  align-items: center;"
    css << "  padding: 12px 16px;"
    css << "  border-bottom: 1px solid var(--border);"
    css << "}"
    css << ""
    
    css << ".panel-title {"
    css << "  font-size: 12px;"
    css << "  font-weight: 600;"
    css << "  text-transform: uppercase;"
    css << "  letter-spacing: 0.5px;"
    css << "  color: var(--text-muted);"
    css << "}"
    css << ""
    
    css << ".badge {"
    css << "  font-size: 10px;"
    css << "  padding: 2px 6px;"
    css << "  border-radius: 4px;"
    css << "  background: rgba(106, 90, 205, 0.15);"
    css << "  color: var(--layer-3-gpt);"
    css << "  border: 1px solid rgba(106, 90, 205, 0.3);"
    css << "}"
    css << ""
    
    css << ".badge-idle {"
    css << "  background: rgba(106, 205, 172, 0.15);"
    css << "  color: #6acda5;"
    css << "  border: 1px solid rgba(106, 205, 172, 0.3);"
    css << "}"
    css << ""
    
    css << "#camera-viewport {"
    css << "  position: relative;"
    css << "  flex: 1;"
    css << "  background: #000;"
    css << "  overflow: hidden;"
    css << "  display: flex;"
    css << "  align-items: center;"
    css << "  justify-content: center;"
    css << "}"
    css << ""
    
    css << "#video, #canvas-overlay, #snap-canvas, #filtered-canvas {"
    css << "  position: absolute;"
    css << "  top: 0;"
    css << "  left: 0;"
    css << "  width: 100%;"
    css << "  height: 100%;"
    css << "  object-fit: contain;"
    css << "}"
    css << ""
    
    css << "#canvas-overlay {"
    css << "  pointer-events: none;"
    css << "  z-index: 2;"
    css << "}"
    css << ""
    
    css << "#start-overlay {"
    css << "  position: absolute;"
    css << "  inset: 0;"
    css << "  display: flex;"
    css << "  flex-direction: column;"
    css << "  align-items: center;"
    css << "  justify-content: center;"
    css << "  gap: 16px;"
    css << "  background: rgba(10, 15, 30, 0.8);"
    css << "  z-index: 5;"
    css << "}"
    css << ""
    
    css << "#pixel-loupe {"
    css << "  position: absolute;"
    css << "  bottom: 20px;"
    css << "  right: 20px;"
    css << "  background: rgba(0, 0, 0, 0.7);"
    css << "  border-radius: 8px;"
    css << "  padding: 8px;"
    css << "  display: none;"
    css << "  flex-direction: column;"
    css << "  align-items: center;"
    css << "  gap: 6px;"
    css << "  z-index: 3;"
    css << "}"
    css << ""
    
    css << "#loupe-canvas {"
    css << "  width: 80px;"
    css << "  height: 80px;"
    css << "  image-rendering: pixelated;"
    css << "  border: 1px solid rgba(255, 255, 255, 0.1);"
    css << "}"
    css << ""
    
    css << "#loupe-info {"
    css << "  font-size: 10px;"
    css << "  color: var(--text-dim);"
    css << "}"
    css << ""
    
    css << "#camera-controls {"
    css << "  display: flex;"
    css << "  align-items: center;"
    css << "  padding: 12px 16px;"
    css << "  gap: 12px;"
    css << "  border-top: 1px solid var(--border);"
    css << "}"
    css << ""
    
    css << "select {"
    css << "  background: var(--bg-panel);"
    css << "  color: var(--text-main);"
    css << "  border: 1px solid var(--border);"
    css << "  border-radius: 6px;"
    css << "  padding: 6px 10px;"
    css << "  font-size: 12px;"
    css << "}"
    css << ""
    
    # Right panel
    css << "/* Rechtes Panel */"
    css << "#right-panel {"
    css << "  width: 320px;"
    css << "  display: flex;"
    css << "  flex-direction: column;"
    css << "  gap: 16px;"
    css << "}"
    css << ""
    
    css << ".card {"
    css << "  background: var(--bg-card);"
    css << "  border-radius: 16px;"
    css << "  border: 1px solid var(--border);"
    css << "  overflow: hidden;"
    css << "  display: flex;"
    css << "  flex-direction: column;"
    css << "}"
    css << ""
    
    css << ".card-body {"
    css << "  padding: 16px;"
    css << "  flex: 1;"
    css << "}"
    css << ""
    
    css << ".slider-row {"
    css << "  display: flex;"
    css << "  align-items: center;"
    css << "  gap: 8px;"
    css << "  margin-bottom: 12px;"
    css << "}"
    css << ""
    
    css << ".slider-label {"
    css << "  font-size: 12px;"
    css << "  width: 100px;"
    css << "  color: var(--text-muted);"
    css << "}"
    css << ""
    
    css << "input[type=\"range\"] {"
    css << "  flex: 1;"
    css << "  height: 4px;"
    css << "  -webkit-appearance: none;"
    css << "  background: var(--bg-panel);"
    css << "  border-radius: 2px;"
    css << "  outline: none;"
    css << "}"
    css << ""
    
    css << "input[type=\"range\"]::-webkit-slider-thumb {"
    css << "  -webkit-appearance: none;"
    css << "  width: 16px;"
    css << "  height: 16px;"
    css << "  border-radius: 50%;"
    css << "  background: var(--accent);"
    css << "  cursor: pointer;"
    css << "}"
    css << ""
    
    css << ".slider-value {"
    css << "  font-size: 12px;"
    css << "  width: 40px;"
    css << "  text-align: right;"
    css << "  color: var(--text-muted);"
    css << "}"
    css << ""
    
    # Tabs
    css << "/* Tabs */"
    css << ".tab-bar {"
    css << "  display: flex;"
    css << "  border-bottom: 1px solid var(--border);"
    css << "}"
    css << ""
    
    css << ".tab {"
    css << "  flex: 1;"
    css << "  padding: 10px 12px;"
    css << "  font-size: 12px;"
    css << "  background: transparent;"
    css << "  border: none;"
    css << "  color: var(--text-dim);"
    css << "  cursor: pointer;"
    css << "  text-align: center;"
    css << "}"
    css << ""
    
    css << ".tab.active {"
    css << "  color: var(--text-main);"
    css << "  border-bottom: 2px solid var(--accent);"
    css << "  background: rgba(93, 138, 255, 0.05);"
    css << "}"
    css << ""
    
    css << ".tab-content {"
    css << "  display: none;"
    css << "}"
    css << ""
    
    css << ".tab-content.active {"
    css << "  display: block;"
    css << "}"
    css << ""
    
    # Status bar
    css << "/* Status-Leiste */"
    css << "#status-bar {"
    css << "  display: flex;"
    css << "  align-items: center;"
    css << "  gap: 8px;"
    css << "  padding: 8px 20px;"
    css << "  background: rgba(10, 15, 30, 0.6);"
    css << "  border-top: 1px solid var(--border);"
    css << "  font-size: 12px;"
    css << "  color: var(--text-dim);"
    css << "}"
    css << ""
    
    css << ".status-dot {"
    css << "  width: 8px;"
    css << "  height: 8px;"
    css << "  border-radius: 50%;"
    css << "  background: #6acda5;"
    css << "}"
    css << ""
    
    css << ".status-dot.loading {"
    css << "  background: #fbd38d;"
    css << "  animation: pulse 1.5s infinite;"
    css << "}"
    css << ""
    
    css << "@keyframes pulse {"
    css << "  0% { opacity: 0.4; }"
    css << "  50% { opacity: 1; }"
    css << "  100% { opacity: 0.4; }"
    css << "}"
    css << ""
    
    # Buttons
    css << "/* Buttons */"
    css << ".btn {"
    css << "  display: inline-flex;"
    css << "  align-items: center;"
    css << "  gap: 6px;"
    css << "  padding: 8px 12px;"
    css << "  border-radius: 8px;"
    css << "  border: 1px solid var(--border);"
    css << "  background: var(--bg-panel);"
    css << "  color: var(--text-main);"
    css << "  font-size: 12px;"
    css << "  font-weight: 500;"
    css << "  cursor: pointer;"
    css << "  transition: all 0.2s ease;"
    css << "}"
    css << ""
    
    css << ".btn:hover {"
    css << "  background: rgba(93, 138, 255, 0.1);"
    css << "  border-color: var(--accent);"
    css << "}"
    css << ""
    
    css << ".btn:disabled {"
    css << "  opacity: 0.5;"
    css << "  cursor: not-allowed;"
    css << "}"
    css << ""
    
    css << ".btn-primary {"
    css << "  background: var(--accent);"
    css << "  border-color: var(--accent);"
    css << "  color: white;"
    css << "}"
    css << ""
    
    css << ".btn-primary:hover:not(:disabled) {"
    css << "  background: var(--accent-hover);"
    css << "  border-color: var(--accent-hover);"
    css << "}"
    css << ""
    
    css << ".btn-icon {"
    css << "  padding: 8px;"
    css << "}"
    css << ""
    
    css << ".btn-snap {"
    css << "  background: linear-gradient(135deg, #ff7eb9, #ff758c);"
    css << "  border: 1px solid #ff7eb9;"
    css << "  color: white;"
    css << "}"
    css << ""
    
    css << ".btn-sm {"
    css << "  padding: 4px 8px;"
    css << "  font-size: 11px;"
    css << "}"
    css << ""
    
    # Spinner
    css << "/* Spinner */"
    css << ".spinner {"
    css << "  width: 16px;"
    css << "  height: 16px;"
    css << "  border: 2px solid rgba(255, 255, 255, 0.2);"
    css << "  border-left-color: var(--accent);"
    css << "  border-radius: 50%;"
    css << "  animation: spin 1s linear infinite;"
    css << "}"
    css << ""
    
    css << "@keyframes spin {"
    css << "  to { transform: rotate(360deg); }"
    css << "}"
    css << ""
    
    # Settings modal
    css << "/* Settings Modal */"
    css << "#settings-modal {"
    css << "  position: fixed;"
    css << "  inset: 0;"
    css << "  background: rgba(0, 0, 0, 0.7);"
    css << "  display: none;"
    css << "  align-items: center;"
    css << "  justify-content: center;"
    css << "  z-index: 1000;"
    css << "}"
    css << ""
    
    css << ".modal-box {"
    css << "  background: var(--bg-card);"
    css << "  border-radius: 16px;"
    css << "  border: 1px solid var(--border);"
    css << "  padding: 20px;"
    css << "  max-height: 90vh;"
    css << "  overflow-y: auto;"
    css << "}"
    css << ""
    
    css << ".modal-title {"
    css << "  font-size: 18px;"
    css << "  font-weight: 600;"
    css << "  margin-bottom: 20px;"
    css << "  color: var(--text-main);"
    css << "}"
    css << ""
    
    css << ".settings-section {"
    css << "  margin-bottom: 24px;"
    css << "}"
    css << ""
    
    css << ".settings-section-title {"
    css << "  font-size: 14px;"
    css << "  font-weight: 600;"
    css << "  margin-bottom: 12px;"
    css << "}"
    css << ""
    
    css << ".settings-label {"
    css << "  display: block;"
    css << "  font-size: 12px;"
    css << "  margin-bottom: 6px;"
    css << "  color: var(--text-muted);"
    css << "}"
    css << ""
    
    css << ".settings-input {"
    css << "  width: 100%;"
    css << "  padding: 10px 12px;"
    css << "  border-radius: 8px;"
    css << "  border: 1px solid var(--border);"
    css << "  background: var(--bg-panel);"
    css << "  color: var(--text-main);"
    css << "  font-size: 12px;"
    css << "  margin-bottom: 4px;"
    css << "}"
    css << ""
    
    css << ".settings-hint {"
    css << "  font-size: 11px;"
    css << "  color: var(--text-dim);"
    css << "  margin-top: 4px;"
    css << "}"
    css << ""
    
    css << ".toggle-switch {"
    css << "  position: relative;"
    css << "  display: inline-block;"
    css << "  width: 40px;"
    css << "  height: 20px;"
    css << "}"
    css << ""
    
    css << ".toggle-switch input {"
    css << "  opacity: 0;"
    css << "  width: 0;"
    css << "  height: 0;"
    css << "}"
    css << ""
    
    css << ".toggle-track {"
    css << "  position: absolute;"
    css << "  cursor: pointer;"
    css << "  top: 0;"
    css << "  left: 0;"
    css << "  right: 0;"
    css << "  bottom: 0;"
    css << "  background: var(--bg-panel);"
    css << "  border: 1px solid var(--border);"
    css << "  border-radius: 20px;"
    css << "  transition: .3s;"
    css << "}"
    css << ""
    
    css << ".toggle-thumb {"
    css << "  position: absolute;"
    css << "  content: \"\";"
    css << "  height: 14px;"
    css << "  width: 14px;"
    css << "  left: 3px;"
    css << "  bottom: 2px;"
    css << "  background: var(--text-dim);"
    css << "  border-radius: 50%;"
    css << "  transition: .3s;"
    css << "}"
    css << ""
    
    css << "input:checked + .toggle-track {"
    css << "  background: var(--accent);"
    css << "  border-color: var(--accent);"
    css << "}"
    css << ""
    
    css << "input:checked + .toggle-track .toggle-thumb {"
    css << "  background: white;"
    css << "  transform: translateX(20px);"
    css << "}"
    css << ""
    
    # Pixel inspector
    css << "/* Pixel-Inspektor */"
    css << ".pixel-swatch {"
    css << "  width: 24px;"
    css << "  height: 24px;"
    css << "  border-radius: 4px;"
    css << "  border: 1px solid var(--border);"
    css << "}"
    css << ""
    
    css << ".pixel-values {"
    css << "  display: flex;"
    css << "  flex-direction: column;"
    css << "  font-size: 11px;"
    css << "  color: var(--text-dim);"
    css << "  gap: 2px;"
    css << "}"
    css << ""
    
    # Upload zone
    css << "/* Upload-Zone */"
    css << "#upload-zone {"
    css << "  position: fixed;"
    css << "  inset: 0;"
    css << "  background: rgba(0, 0, 0, 0.8);"
    css << "  display: none;"
    css << "  align-items: center;"
    css << "  justify-content: center;"
    css << "  color: var(--text-main);"
    css << "  font-size: 16px;"
    css << "  z-index: 100;"
    css << "}"
    css << ""
    
    # Responsive
    css << "/* Responsive */"
    css << "@media (max-width: 768px) {"
    css << "  #board {"
    css << "    flex-direction: column;"
    css << "  }"
    css << ""
    css << "  #right-panel {"
    css << "    width: 100%;"
    css << "  }"
    css << ""
    css << "  #camera-panel {"
    css << "    min-width: unset;"
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
