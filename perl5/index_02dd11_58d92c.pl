#!/usr/bin/perl
# abstraction-provenance: {"artifact_sha256": "61ef8d53977c75b663c3b5c1b378713b4327bc10d88070a9baffbf49139bb6bb", "source_sha256": "58d92c4f40bf7edb6d494c682f4fa1268aea0c52ab326535c779d2f2c808fffd", "target_language": "perl5"}
# index_02dd11.css — portiert nach perl5
# Quelle: css, Projects@abstractions:css/index_02dd11.css
# Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;

# abstraction-provenance: {"artifact_sha256": "8b76660533c644ac76ba28b4dcfb567e78b781d329ee59f8e75ceb7f8348f402", "source_sha256": "02dd111b283ac08d7a9f3fbbe30150fb6db98097ed7bc68f2677c6df9c744bfb", "target_language": "perl"}
# index.html — portiert nach css
# Quelle: html, Projects@Vision-Check:Vision-Check/app/index.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

sub generate_css {
    my $css = '';
    
    # Root-Variablen
    $css .= ":root {\n";
    $css .= "  --bg-dark: #0a0f1e;\n";
    $css .= "  --bg-card: #121826;\n";
    $css .= "  --bg-panel: #1a2236;\n";
    $css .= "  --border: #25324d;\n";
    $css .= "  --text-main: #e6ecf5;\n";
    $css .= "  --text-muted: #a0b0cc;\n";
    $css .= "  --text-dim: #6c7a96;\n";
    $css .= "  --accent: #5d8aff;\n";
    $css .= "  --accent-hover: #7a9fff;\n";
    $css .= "  --accent-warn: #fbd38d;\n";
    $css .= "  --layer-0: #ff7eb9;\n";
    $css .= "  --layer-1: #4fd1c5;\n";
    $css .= "  --layer-2: #ffd166;\n";
    $css .= "  --layer-3-gpt: #6a5acd;\n";
    $css .= "  --layer-3-gemini: #4285f4;\n";
    $css .= "  --layer-3-claude: #f4a261;\n";
    $css .= "}\n\n";
    
    # Basis-Stile
    $css .= "* {\n";
    $css .= "  box-sizing: border-box;\n";
    $css .= "  margin: 0;\n";
    $css .= "  padding: 0;\n";
    $css .= "}\n\n";
    
    $css .= "body {\n";
    $css .= "  font-family: 'Inter', sans-serif;\n";
    $css .= "  background: var(--bg-dark);\n";
    $css .= "  color: var(--text-main);\n";
    $css .= "  line-height: 1.5;\n";
    $css .= "  overflow: hidden;\n";
    $css .= "  height: 100vh;\n";
    $css .= "  display: flex;\n";
    $css .= "  flex-direction: column;\n";
    $css .= "}\n\n";
    
    # Header
    $css .= "#app-header {\n";
    $css .= "  display: flex;\n";
    $css .= "  align-items: center;\n";
    $css .= "  justify-content: space-between;\n";
    $css .= "  padding: 12px 20px;\n";
    $css .= "  background: rgba(10, 15, 30, 0.8);\n";
    $css .= "  backdrop-filter: blur(10px);\n";
    $css .= "  border-bottom: 1px solid var(--border);\n";
    $css .= "  position: relative;\n";
    $css .= "  z-index: 10;\n";
    $css .= "}\n\n";
    
    $css .= ".header-brand {\n";
    $css .= "  display: flex;\n";
    $css .= "  align-items: center;\n";
    $css .= "  gap: 10px;\n";
    $css .= "}\n\n";
    
    $css .= ".header-brand h1 {\n";
    $css .= "  font-size: 18px;\n";
    $css .= "  font-weight: 600;\n";
    $css .= "  color: var(--text-main);\n";
    $css .= "}\n\n";
    
    $css .= ".layer-indicator {\n";
    $css .= "  display: flex;\n";
    $css .= "  align-items: center;\n";
    $css .= "  gap: 4px;\n";
    $css .= "}\n\n";
    
    $css .= ".layer-dot {\n";
    $css .= "  width: 8px;\n";
    $css .= "  height: 8px;\n";
    $css .= "  border-radius: 50%;\n";
    $css .= "  opacity: 0.4;\n";
    $css .= "}\n\n";
    
    $css .= ".layer-dot.active {\n";
    $css .= "  opacity: 1;\n";
    $css .= "  box-shadow: 0 0 6px currentColor;\n";
    $css .= "}\n\n";
    
    $css .= ".header-controls {\n";
    $css .= "  display: flex;\n";
    $css .= "  gap: 8px;\n";
    $css .= "}\n\n";
    
    # Hauptbereich
    $css .= "#board {\n";
    $css .= "  display: flex;\n";
    $css .= "  flex: 1;\n";
    $css .= "  overflow: hidden;\n";
    $css .= "  padding: 16px;\n";
    $css .= "  gap: 16px;\n";
    $css .= "}\n\n";
    
    # Kamera-Panel
    $css .= "#camera-panel {\n";
    $css .= "  flex: 1;\n";
    $css .= "  display: flex;\n";
    $css .= "  flex-direction: column;\n";
    $css .= "  background: var(--bg-card);\n";
    $css .= "  border-radius: 16px;\n";
    $css .= "  border: 1px solid var(--border);\n";
    $css .= "  overflow: hidden;\n";
    $css .= "  min-width: 320px;\n";
    $css .= "}\n\n";
    
    $css .= ".panel-header {\n";
    $css .= "  display: flex;\n";
    $css .= "  justify-content: space-between;\n";
    $css .= "  align-items: center;\n";
    $css .= "  padding: 12px 16px;\n";
    $css .= "  border-bottom: 1px solid var(--border);\n";
    $css .= "}\n\n";
    
    $css .= ".panel-title {\n";
    $css .= "  font-size: 12px;\n";
    $css .= "  font-weight: 600;\n";
    $css .= "  text-transform: uppercase;\n";
    $css .= "  letter-spacing: 0.5px;\n";
    $css .= "  color: var(--text-muted);\n";
    $css .= "}\n\n";
    
    $css .= ".badge {\n";
    $css .= "  font-size: 10px;\n";
    $css .= "  padding: 2px 6px;\n";
    $css .= "  border-radius: 4px;\n";
    $css .= "  background: rgba(106, 90, 205, 0.15);\n";
    $css .= "  color: var(--layer-3-gpt);\n";
    $css .= "  border: 1px solid rgba(106, 90, 205, 0.3);\n";
    $css .= "}\n\n";
    
    $css .= ".badge-idle {\n";
    $css .= "  background: rgba(106, 205, 172, 0.15);\n";
    $css .= "  color: #6acda5;\n";
    $css .= "  border: 1px solid rgba(106, 205, 172, 0.3);\n";
    $css .= "}\n\n";
    
    $css .= "#camera-viewport {\n";
    $css .= "  position: relative;\n";
    $css .= "  flex: 1;\n";
    $css .= "  background: #000;\n";
    $css .= "  overflow: hidden;\n";
    $css .= "  display: flex;\n";
    $css .= "  align-items: center;\n";
    $css .= "  justify-content: center;\n";
    $css .= "}\n\n";
    
    $css .= "#video, #canvas-overlay, #snap-canvas, #filtered-canvas {\n";
    $css .= "  position: absolute;\n";
    $css .= "  top: 0;\n";
    $css .= "  left: 0;\n";
    $css .= "  width: 100%;\n";
    $css .= "  height: 100%;\n";
    $css .= "  object-fit: contain;\n";
    $css .= "}\n\n";
    
    $css .= "#canvas-overlay {\n";
    $css .= "  pointer-events: none;\n";
    $css .= "  z-index: 2;\n";
    $css .= "}\n\n";
    
    $css .= "#start-overlay {\n";
    $css .= "  position: absolute;\n";
    $css .= "  inset: 0;\n";
    $css .= "  display: flex;\n";
    $css .= "  flex-direction: column;\n";
    $css .= "  align-items: center;\n";
    $css .= "  justify-content: center;\n";
    $css .= "  gap: 16px;\n";
    $css .= "  background: rgba(10, 15, 30, 0.8);\n";
    $css .= "  z-index: 5;\n";
    $css .= "}\n\n";
    
    $css .= "#pixel-loupe {\n";
    $css .= "  position: absolute;\n";
    $css .= "  bottom: 20px;\n";
    $css .= "  right: 20px;\n";
    $css .= "  background: rgba(0, 0, 0, 0.7);\n";
    $css .= "  border-radius: 8px;\n";
    $css .= "  padding: 8px;\n";
    $css .= "  display: none;\n";
    $css .= "  flex-direction: column;\n";
    $css .= "  align-items: center;\n";
    $css .= "  gap: 6px;\n";
    $css .= "  z-index: 3;\n";
    $css .= "}\n\n";
    
    $css .= "#loupe-canvas {\n";
    $css .= "  width: 80px;\n";
    $css .= "  height: 80px;\n";
    $css .= "  image-rendering: pixelated;\n";
    $css .= "  border: 1px solid rgba(255, 255, 255, 0.1);\n";
    $css .= "}\n\n";
    
    $css .= "#loupe-info {\n";
    $css .= "  font-size: 10px;\n";
    $css .= "  color: var(--text-dim);\n";
    $css .= "}\n\n";
    
    $css .= "#camera-controls {\n";
    $css .= "  display: flex;\n";
    $css .= "  align-items: center;\n";
    $css .= "  padding: 12px 16px;\n";
    $css .= "  gap: 12px;\n";
    $css .= "  border-top: 1px solid var(--border);\n";
    $css .= "}\n\n";
    
    $css .= "select {\n";
    $css .= "  background: var(--bg-panel);\n";
    $css .= "  color: var(--text-main);\n";
    $css .= "  border: 1px solid var(--border);\n";
    $css .= "  border-radius: 6px;\n";
    $css .= "  padding: 6px 10px;\n";
    $css .= "  font-size: 12px;\n";
    $css .= "}\n\n";
    
    # Rechtes Panel
    $css .= "#right-panel {\n";
    $css .= "  width: 320px;\n";
    $css .= "  display: flex;\n";
    $css .= "  flex-direction: column;\n";
    $css .= "  gap: 16px;\n";
    $css .= "}\n\n";
    
    $css .= ".card {\n";
    $css .= "  background: var(--bg-card);\n";
    $css .= "  border-radius: 16px;\n";
    $css .= "  border: 1px solid var(--border);\n";
    $css .= "  overflow: hidden;\n";
    $css .= "  display: flex;\n";
    $css .= "  flex-direction: column;\n";
    $css .= "}\n\n";
    
    $css .= ".card-body {\n";
    $css .= "  padding: 16px;\n";
    $css .= "  flex: 1;\n";
    $css .= "}\n\n";
    
    $css .= ".slider-row {\n";
    $css .= "  display: flex;\n";
    $css .= "  align-items: center;\n";
    $css .= "  gap: 8px;\n";
    $css .= "  margin-bottom: 12px;\n";
    $css .= "}\n\n";
    
    $css .= ".slider-label {\n";
    $css .= "  font-size: 12px;\n";
    $css .= "  width: 100px;\n";
    $css .= "  color: var(--text-muted);\n";
    $css .= "}\n\n";
    
    $css .= "input[type=\"range\"] {\n";
    $css .= "  flex: 1;\n";
    $css .= "  height: 4px;\n";
    $css .= "  -webkit-appearance: none;\n";
    $css .= "  background: var(--bg-panel);\n";
    $css .= "  border-radius: 2px;\n";
    $css .= "  outline: none;\n";
    $css .= "}\n\n";
    
    $css .= "input[type=\"range\"]::-webkit-slider-thumb {\n";
    $css .= "  -webkit-appearance: none;\n";
    $css .= "  width: 16px;\n";
    $css .= "  height: 16px;\n";
    $css .= "  border-radius: 50%;\n";
    $css .= "  background: var(--accent);\n";
    $css .= "  cursor: pointer;\n";
    $css .= "}\n\n";
    
    $css .= ".slider-value {\n";
    $css .= "  font-size: 12px;\n";
    $css .= "  width: 40px;\n";
    $css .= "  text-align: right;\n";
    $css .= "  color: var(--text-muted);\n";
    $css .= "}\n\n";
    
    # Tabs
    $css .= ".tab-bar {\n";
    $css .= "  display: flex;\n";
    $css .= "  border-bottom: 1px solid var(--border);\n";
    $css .= "}\n\n";
    
    $css .= ".tab {\n";
    $css .= "  flex: 1;\n";
    $css .= "  padding: 10px 12px;\n";
    $css .= "  font-size: 12px;\n";
    $css .= "  background: transparent;\n";
    $css .= "  border: none;\n";
    $css .= "  color: var(--text-dim);\n";
    $css .= "  cursor: pointer;\n";
    $css .= "  text-align: center;\n";
    $css .= "}\n\n";
    
    $css .= ".tab.active {\n";
    $css .= "  color: var(--text-main);\n";
    $css .= "  border-bottom: 2px solid var(--accent);\n";
    $css .= "  background: rgba(93, 138, 255, 0.05);\n";
    $css .= "}\n\n";
    
    $css .= ".tab-content {\n";
    $css .= "  display: none;\n";
    $css .= "}\n\n";
    
    $css .= ".tab-content.active {\n";
    $css .= "  display: block;\n";
    $css .= "}\n\n";
    
    # Status-Leiste
    $css .= "#status-bar {\n";
    $css .= "  display: flex;\n";
    $css .= "  align-items: center;\n";
    $css .= "  gap: 8px;\n";
    $css .= "  padding: 8px 20px;\n";
    $css .= "  background: rgba(10, 15, 30, 0.6);\n";
    $css .= "  border-top: 1px solid var(--border);\n";
    $css .= "  font-size: 12px;\n";
    $css .= "  color: var(--text-dim);\n";
    $css .= "}\n\n";
    
    $css .= ".status-dot {\n";
    $css .= "  width: 8px;\n";
    $css .= "  height: 8px;\n";
    $css .= "  border-radius: 50%;\n";
    $css .= "  background: #6acda5;\n";
    $css .= "}\n\n";
    
    $css .= ".status-dot.loading {\n";
    $css .= "  background: #fbd38d;\n";
    $css .= "  animation: pulse 1.5s infinite;\n";
    $css .= "}\n\n";
    
    $css .= "\@keyframes pulse {\n";
    $css .= "  0% { opacity: 0.4; }\n";
    $css .= "  50% { opacity: 1; }\n";
    $css .= "  100% { opacity: 0.4; }\n";
    $css .= "}\n\n";
    
    # Buttons
    $css .= ".btn {\n";
    $css .= "  display: inline-flex;\n";
    $css .= "  align-items: center;\n";
    $css .= "  gap: 6px;\n";
    $css .= "  padding: 8px 12px;\n";
    $css .= "  border-radius: 8px;\n";
    $css .= "  border: 1px solid var(--border);\n";
    $css .= "  background: var(--bg-panel);\n";
    $css .= "  color: var(--text-main);\n";
    $css .= "  font-size: 12px;\n";
    $css .= "  font-weight: 500;\n";
    $css .= "  cursor: pointer;\n";
    $css .= "  transition: all 0.2s ease;\n";
    $css .= "}\n\n";
    
    $css .= ".btn:hover {\n";
    $css .= "  background: rgba(93, 138, 255, 0.1);\n";
    $css .= "  border-color: var(--accent);\n";
    $css .= "}\n\n";
    
    $css .= ".btn:disabled {\n";
    $css .= "  opacity: 0.5;\n";
    $css .= "  cursor: not-allowed;\n";
    $css .= "}\n\n";
    
    $css .= ".btn-primary {\n";
    $css .= "  background: var(--accent);\n";
    $css .= "  border-color: var(--accent);\n";
    $css .= "  color: white;\n";
    $css .= "}\n\n";
    
    $css .= ".btn-primary:hover:not(:disabled) {\n";
    $css .= "  background: var(--accent-hover);\n";
    $css .= "  border-color: var(--accent-hover);\n";
    $css .= "}\n\n";
    
    $css .= ".btn-icon {\n";
    $css .= "  padding: 8px;\n";
    $css .= "}\n\n";
    
    $css .= ".btn-snap {\n";
    $css .= "  background: linear-gradient(135deg, #ff7eb9, #ff758c);\n";
    $css .= "  border: 1px solid #ff7eb9;\n";
    $css .= "  color: white;\n";
    $css .= "}\n\n";
    
    $css .= ".btn-sm {\n";
    $css .= "  padding: 4px 8px;\n";
    $css .= "  font-size: 11px;\n";
    $css .= "}\n\n";
    
    # Spinner
    $css .= ".spinner {\n";
    $css .= "  width: 16px;\n";
    $css .= "  height: 16px;\n";
    $css .= "  border: 2px solid rgba(255, 255, 255, 0.2);\n";
    $css .= "  border-left-color: var(--accent);\n";
    $css .= "  border-radius: 50%;\n";
    $css .= "  animation: spin 1s linear infinite;\n";
    $css .= "}\n\n";
    
    $css .= "\@keyframes spin {\n";
    $css .= "  to { transform: rotate(360deg); }\n";
    $css .= "}\n\n";
    
    # Settings Modal
    $css .= "#settings-modal {\n";
    $css .= "  position: fixed;\n";
    $css .= "  inset: 0;\n";
    $css .= "  background: rgba(0, 0, 0, 0.7);\n";
    $css .= "  display: none;\n";
    $css .= "  align-items: center;\n";
    $css .= "  justify-content: center;\n";
    $css .= "  z-index: 1000;\n";
    $css .= "}\n\n";
    
    $css .= ".modal-box {\n";
    $css .= "  background: var(--bg-card);\n";
    $css .= "  border-radius: 16px;\n";
    $css .= "  border: 1px solid var(--border);\n";
    $css .= "  padding: 20px;\n";
    $css .= "  max-height: 90vh;\n";
    $css .= "  overflow-y: auto;\n";
    $css .= "}\n\n";
    
    $css .= ".modal-title {\n";
    $css .= "  font-size: 18px;\n";
    $css .= "  font-weight: 600;\n";
    $css .= "  margin-bottom: 20px;\n";
    $css .= "  color: var(--text-main);\n";
    $css .= "}\n\n";
    
    $css .= ".settings-section {\n";
    $css .= "  margin-bottom: 24px;\n";
    $css .= "}\n\n";
    
    $css .= ".settings-section-title {\n";
    $css .= "  font-size: 14px;\n";
    $css .= "  font-weight: 600;\n";
    $css .= "  margin-bottom: 12px;\n";
    $css .= "}\n\n";
    
    $css .= ".settings-label {\n";
    $css .= "  display: block;\n";
    $css .= "  font-size: 12px;\n";
    $css .= "  margin-bottom: 6px;\n";
    $css .= "  color: var(--text-muted);\n";
    $css .= "}\n\n";
    
    $css .= ".settings-input {\n";
    $css .= "  width: 100%;\n";
    $css .= "  padding: 10px 12px;\n";
    $css .= "  border-radius: 8px;\n";
    $css .= "  border: 1px solid var(--border);\n";
    $css .= "  background: var(--bg-panel);\n";
    $css .= "  color: var(--text-main);\n";
    $css .= "  font-size: 12px;\n";
    $css .= "  margin-bottom: 4px;\n";
    $css .= "}\n\n";
    
    $css .= ".settings-hint {\n";
    $css .= "  font-size: 11px;\n";
    $css .= "  color: var(--text-dim);\n";
    $css .= "  margin-top: 4px;\n";
    $css .= "}\n\n";
    
    $css .= ".toggle-switch {\n";
    $css .= "  position: relative;\n";
    $css .= "  display: inline-block;\n";
    $css .= "  width: 40px;\n";
    $css .= "  height: 20px;\n";
    $css .= "}\n\n";
    
    $css .= ".toggle-switch input {\n";
    $css .= "  opacity: 0;\n";
    $css .= "  width: 0;\n";
    $css .= "  height: 0;\n";
    $css .= "}\n\n";
    
    $css .= ".toggle-track {\n";
    $css .= "  position: absolute;\n";
    $css .= "  cursor: pointer;\n";
    $css .= "  top: 0;\n";
    $css .= "  left: 0;\n";
    $css .= "  right: 0;\n";
    $css .= "  bottom: 0;\n";
    $css .= "  background: var(--bg-panel);\n";
    $css .= "  border: 1px solid var(--border);\n";
    $css .= "  border-radius: 20px;\n";
    $css .= "  transition: .3s;\n";
    $css .= "}\n\n";
    
    $css .= ".toggle-thumb {\n";
    $css .= "  position: absolute;\n";
    $css .= "  content: \"\";\n";
    $css .= "  height: 14px;\n";
    $css .= "  width: 14px;\n";
    $css .= "  left: 3px;\n";
    $css .= "  bottom: 2px;\n";
    $css .= "  background: var(--text-dim);\n";
    $css .= "  border-radius: 50%;\n";
    $css .= "  transition: .3s;\n";
    $css .= "}\n\n";
    
    $css .= "input:checked + .toggle-track {\n";
    $css .= "  background: var(--accent);\n";
    $css .= "  border-color: var(--accent);\n";
    $css .= "}\n\n";
    
    $css .= "input:checked + .toggle-track .toggle-thumb {\n";
    $css .= "  background: white;\n";
    $css .= "  transform: translateX(20px);\n";
    $css .= "}\n\n";
    
    # Pixel-Inspektor
    $css .= ".pixel-swatch {\n";
    $css .= "  width: 24px;\n";
    $css .= "  height: 24px;\n";
    $css .= "  border-radius: 4px;\n";
    $css .= "  border: 1px solid var(--border);\n";
    $css .= "}\n\n";
    
    $css .= ".pixel-values {\n";
    $css .= "  display: flex;\n";
    $css .= "  flex-direction: column;\n";
    $css .= "  font-size: 11px;\n";
    $css .= "  color: var(--text-dim);\n";
    $css .= "  gap: 2px;\n";
    $css .= "}\n\n";
    
    # Upload-Zone
    $css .= "#upload-zone {\n";
    $css .= "  position: fixed;\n";
    $css .= "  inset: 0;\n";
    $css .= "  background: rgba(0, 0, 0, 0.8);\n";
    $css .= "  display: none;\n";
    $css .= "  align-items: center;\n";
    $css .= "  justify-content: center;\n";
    $css .= "  color: var(--text-main);\n";
    $css .= "  font-size: 16px;\n";
    $css .= "  z-index: 100;\n";
    $css .= "}\n\n";
    
    # Responsive
    $css .= "\@media (max-width: 768px) {\n";
    $css .= "  #board {\n";
    $css .= "    flex-direction: column;\n";
    $css .= "  }\n\n";
    $css .= "  #right-panel {\n";
    $css .= "    width: 100%;\n";
    $css .= "  }\n\n";
    $css .= "  #camera-panel {\n";
    $css .= "    min-width: unset;\n";
    $css .= "  }\n";
    $css .= "}\n";
    
    return $css;
}

sub write_css_file {
    my ($filename) = @_;
    open my $fh, '>', $filename or die "Kann Datei '$filename' nicht öffnen: $!";
    print $fh generate_css();
    close $fh;
}

# Hauptprogramm
if (@ARGV != 1) {
    die "Verwendung: $0 <ausgabedatei>\n";
}

my $output_file = $ARGV[0];
write_css_file($output_file);
print "CSS erfolgreich in '$output_file' geschrieben.\n";
