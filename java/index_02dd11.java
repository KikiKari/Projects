// abstraction-provenance: {"artifact_sha256": "16b3a095b35d198db7e1aad4e9bbc3e78a54f4365158606e48efd87b96d8ec10", "source_sha256": "58d92c4f40bf7edb6d494c682f4fa1268aea0c52ab326535c779d2f2c808fffd", "target_language": "java"}
// index_02dd11.css — portiert nach java
// Quelle: css, Projects@abstractions:css/index_02dd11.css
// Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;

public class CSSGenerator {

    public static void main(String[] args) {
        if (args.length != 1) {
            System.err.println("Usage: java CSSGenerator <output-file>");
            System.exit(1);
        }
        
        String outputFile = args[0];
        StringBuilder css = new StringBuilder();
        
        // Root variables
        css.append("/* abstraction-provenance: {\"artifact_sha256\": \"8b76660533c644ac76ba28b4dcfb567e78b781d329ee59f8e75ceb7f8348f402\", \"source_sha256\": \"02dd111b283ac08d7a9f3fbbe30150fb6db98097ed7bc68f2677c6df9c744bfb\", \"target_language\": \"css\"} */\n");
        css.append("/* index.html — portiert nach css */\n");
        css.append("/* Quelle: html, Projects@Vision-Check:Vision-Check/app/index.html */\n");
        css.append("/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */\n\n");
        css.append("/* Root-Variablen */\n");
        css.append(":root {\n");
        css.append("  --bg-dark: #0a0f1e;\n");
        css.append("  --bg-card: #121826;\n");
        css.append("  --bg-panel: #1a2236;\n");
        css.append("  --border: #25324d;\n");
        css.append("  --text-main: #e6ecf5;\n");
        css.append("  --text-muted: #a0b0cc;\n");
        css.append("  --text-dim: #6c7a96;\n");
        css.append("  --accent: #5d8aff;\n");
        css.append("  --accent-hover: #7a9fff;\n");
        css.append("  --accent-warn: #fbd38d;\n");
        css.append("  --layer-0: #ff7eb9;\n");
        css.append("  --layer-1: #4fd1c5;\n");
        css.append("  --layer-2: #ffd166;\n");
        css.append("  --layer-3-gpt: #6a5acd;\n");
        css.append("  --layer-3-gemini: #4285f4;\n");
        css.append("  --layer-3-claude: #f4a261;\n");
        css.append("}\n\n");
        
        // Base styles
        css.append("/* Basis-Stile */\n");
        css.append("* {\n");
        css.append("  box-sizing: border-box;\n");
        css.append("  margin: 0;\n");
        css.append("  padding: 0;\n");
        css.append("}\n\n");
        
        css.append("body {\n");
        css.append("  font-family: 'Inter', sans-serif;\n");
        css.append("  background: var(--bg-dark);\n");
        css.append("  color: var(--text-main);\n");
        css.append("  line-height: 1.5;\n");
        css.append("  overflow: hidden;\n");
        css.append("  height: 100vh;\n");
        css.append("  display: flex;\n");
        css.append("  flex-direction: column;\n");
        css.append("}\n\n");
        
        // Header
        css.append("/* Header */\n");
        css.append("#app-header {\n");
        css.append("  display: flex;\n");
        css.append("  align-items: center;\n");
        css.append("  justify-content: space-between;\n");
        css.append("  padding: 12px 20px;\n");
        css.append("  background: rgba(10, 15, 30, 0.8);\n");
        css.append("  backdrop-filter: blur(10px);\n");
        css.append("  border-bottom: 1px solid var(--border);\n");
        css.append("  position: relative;\n");
        css.append("  z-index: 10;\n");
        css.append("}\n\n");
        
        css.append(".header-brand {\n");
        css.append("  display: flex;\n");
        css.append("  align-items: center;\n");
        css.append("  gap: 10px;\n");
        css.append("}\n\n");
        
        css.append(".header-brand h1 {\n");
        css.append("  font-size: 18px;\n");
        css.append("  font-weight: 600;\n");
        css.append("  color: var(--text-main);\n");
        css.append("}\n\n");
        
        css.append(".layer-indicator {\n");
        css.append("  display: flex;\n");
        css.append("  align-items: center;\n");
        css.append("  gap: 4px;\n");
        css.append("}\n\n");
        
        css.append(".layer-dot {\n");
        css.append("  width: 8px;\n");
        css.append("  height: 8px;\n");
        css.append("  border-radius: 50%;\n");
        css.append("  opacity: 0.4;\n");
        css.append("}\n\n");
        
        css.append(".layer-dot.active {\n");
        css.append("  opacity: 1;\n");
        css.append("  box-shadow: 0 0 6px currentColor;\n");
        css.append("}\n\n");
        
        css.append(".header-controls {\n");
        css.append("  display: flex;\n");
        css.append("  gap: 8px;\n");
        css.append("}\n\n");
        
        // Main area
        css.append("/* Hauptbereich */\n");
        css.append("#board {\n");
        css.append("  display: flex;\n");
        css.append("  flex: 1;\n");
        css.append("  overflow: hidden;\n");
        css.append("  padding: 16px;\n");
        css.append("  gap: 16px;\n");
        css.append("}\n\n");
        
        // Camera panel
        css.append("/* Kamera-Panel */\n");
        css.append("#camera-panel {\n");
        css.append("  flex: 1;\n");
        css.append("  display: flex;\n");
        css.append("  flex-direction: column;\n");
        css.append("  background: var(--bg-card);\n");
        css.append("  border-radius: 16px;\n");
        css.append("  border: 1px solid var(--border);\n");
        css.append("  overflow: hidden;\n");
        css.append("  min-width: 320px;\n");
        css.append("}\n\n");
        
        css.append(".panel-header {\n");
        css.append("  display: flex;\n");
        css.append("  justify-content: space-between;\n");
        css.append("  align-items: center;\n");
        css.append("  padding: 12px 16px;\n");
        css.append("  border-bottom: 1px solid var(--border);\n");
        css.append("}\n\n");
        
        css.append(".panel-title {\n");
        css.append("  font-size: 12px;\n");
        css.append("  font-weight: 600;\n");
        css.append("  text-transform: uppercase;\n");
        css.append("  letter-spacing: 0.5px;\n");
        css.append("  color: var(--text-muted);\n");
        css.append("}\n\n");
        
        css.append(".badge {\n");
        css.append("  font-size: 10px;\n");
        css.append("  padding: 2px 6px;\n");
        css.append("  border-radius: 4px;\n");
        css.append("  background: rgba(106, 90, 205, 0.15);\n");
        css.append("  color: var(--layer-3-gpt);\n");
        css.append("  border: 1px solid rgba(106, 90, 205, 0.3);\n");
        css.append("}\n\n");
        
        css.append(".badge-idle {\n");
        css.append("  background: rgba(106, 205, 172, 0.15);\n");
        css.append("  color: #6acda5;\n");
        css.append("  border: 1px solid rgba(106, 205, 172, 0.3);\n");
        css.append("}\n\n");
        
        css.append("#camera-viewport {\n");
        css.append("  position: relative;\n");
        css.append("  flex: 1;\n");
        css.append("  background: #000;\n");
        css.append("  overflow: hidden;\n");
        css.append("  display: flex;\n");
        css.append("  align-items: center;\n");
        css.append("  justify-content: center;\n");
        css.append("}\n\n");
        
        css.append("#video, #canvas-overlay, #snap-canvas, #filtered-canvas {\n");
        css.append("  position: absolute;\n");
        css.append("  top: 0;\n");
        css.append("  left: 0;\n");
        css.append("  width: 100%;\n");
        css.append("  height: 100%;\n");
        css.append("  object-fit: contain;\n");
        css.append("}\n\n");
        
        css.append("#canvas-overlay {\n");
        css.append("  pointer-events: none;\n");
        css.append("  z-index: 2;\n");
        css.append("}\n\n");
        
        css.append("#start-overlay {\n");
        css.append("  position: absolute;\n");
        css.append("  inset: 0;\n");
        css.append("  display: flex;\n");
        css.append("  flex-direction: column;\n");
        css.append("  align-items: center;\n");
        css.append("  justify-content: center;\n");
        css.append("  gap: 16px;\n");
        css.append("  background: rgba(10, 15, 30, 0.8);\n");
        css.append("  z-index: 5;\n");
        css.append("}\n\n");
        
        css.append("#pixel-loupe {\n");
        css.append("  position: absolute;\n");
        css.append("  bottom: 20px;\n");
        css.append("  right: 20px;\n");
        css.append("  background: rgba(0, 0, 0, 0.7);\n");
        css.append("  border-radius: 8px;\n");
        css.append("  padding: 8px;\n");
        css.append("  display: none;\n");
        css.append("  flex-direction: column;\n");
        css.append("  align-items: center;\n");
        css.append("  gap: 6px;\n");
        css.append("  z-index: 3;\n");
        css.append("}\n\n");
        
        css.append("#loupe-canvas {\n");
        css.append("  width: 80px;\n");
        css.append("  height: 80px;\n");
        css.append("  image-rendering: pixelated;\n");
        css.append("  border: 1px solid rgba(255, 255, 255, 0.1);\n");
        css.append("}\n\n");
        
        css.append("#loupe-info {\n");
        css.append("  font-size: 10px;\n");
        css.append("  color: var(--text-dim);\n");
        css.append("}\n\n");
        
        css.append("#camera-controls {\n");
        css.append("  display: flex;\n");
        css.append("  align-items: center;\n");
        css.append("  padding: 12px 16px;\n");
        css.append("  gap: 12px;\n");
        css.append("  border-top: 1px solid var(--border);\n");
        css.append("}\n\n");
        
        css.append("select {\n");
        css.append("  background: var(--bg-panel);\n");
        css.append("  color: var(--text-main);\n");
        css.append("  border: 1px solid var(--border);\n");
        css.append("  border-radius: 6px;\n");
        css.append("  padding: 6px 10px;\n");
        css.append("  font-size: 12px;\n");
        css.append("}\n\n");
        
        // Right panel
        css.append("/* Rechtes Panel */\n");
        css.append("#right-panel {\n");
        css.append("  width: 320px;\n");
        css.append("  display: flex;\n");
        css.append("  flex-direction: column;\n");
        css.append("  gap: 16px;\n");
        css.append("}\n\n");
        
        css.append(".card {\n");
        css.append("  background: var(--bg-card);\n");
        css.append("  border-radius: 16px;\n");
        css.append("  border: 1px solid var(--border);\n");
        css.append("  overflow: hidden;\n");
        css.append("  display: flex;\n");
        css.append("  flex-direction: column;\n");
        css.append("}\n\n");
        
        css.append(".card-body {\n");
        css.append("  padding: 16px;\n");
        css.append("  flex: 1;\n");
        css.append("}\n\n");
        
        css.append(".slider-row {\n");
        css.append("  display: flex;\n");
        css.append("  align-items: center;\n");
        css.append("  gap: 8px;\n");
        css.append("  margin-bottom: 12px;\n");
        css.append("}\n\n");
        
        css.append(".slider-label {\n");
        css.append("  font-size: 12px;\n");
        css.append("  width: 100px;\n");
        css.append("  color: var(--text-muted);\n");
        css.append("}\n\n");
        
        css.append("input[type=\"range\"] {\n");
        css.append("  flex: 1;\n");
        css.append("  height: 4px;\n");
        css.append("  -webkit-appearance: none;\n");
        css.append("  background: var(--bg-panel);\n");
        css.append("  border-radius: 2px;\n");
        css.append("  outline: none;\n");
        css.append("}\n\n");
        
        css.append("input[type=\"range\"]::-webkit-slider-thumb {\n");
        css.append("  -webkit-appearance: none;\n");
        css.append("  width: 16px;\n");
        css.append("  height: 16px;\n");
        css.append("  border-radius: 50%;\n");
        css.append("  background: var(--accent);\n");
        css.append("  cursor: pointer;\n");
        css.append("}\n\n");
        
        css.append(".slider-value {\n");
        css.append("  font-size: 12px;\n");
        css.append("  width: 40px;\n");
        css.append("  text-align: right;\n");
        css.append("  color: var(--text-muted);\n");
        css.append("}\n\n");
        
        // Tabs
        css.append("/* Tabs */\n");
        css.append(".tab-bar {\n");
        css.append("  display: flex;\n");
        css.append("  border-bottom: 1px solid var(--border);\n");
        css.append("}\n\n");
        
        css.append(".tab {\n");
        css.append("  flex: 1;\n");
        css.append("  padding: 10px 12px;\n");
        css.append("  font-size: 12px;\n");
        css.append("  background: transparent;\n");
        css.append("  border: none;\n");
        css.append("  color: var(--text-dim);\n");
        css.append("  cursor: pointer;\n");
        css.append("  text-align: center;\n");
        css.append("}\n\n");
        
        css.append(".tab.active {\n");
        css.append("  color: var(--text-main);\n");
        css.append("  border-bottom: 2px solid var(--accent);\n");
        css.append("  background: rgba(93, 138, 255, 0.05);\n");
        css.append("}\n\n");
        
        css.append(".tab-content {\n");
        css.append("  display: none;\n");
        css.append("}\n\n");
        
        css.append(".tab-content.active {\n");
        css.append("  display: block;\n");
        css.append("}\n\n");
        
        // Status bar
        css.append("/* Status-Leiste */\n");
        css.append("#status-bar {\n");
        css.append("  display: flex;\n");
        css.append("  align-items: center;\n");
        css.append("  gap: 8px;\n");
        css.append("  padding: 8px 20px;\n");
        css.append("  background: rgba(10, 15, 30, 0.6);\n");
        css.append("  border-top: 1px solid var(--border);\n");
        css.append("  font-size: 12px;\n");
        css.append("  color: var(--text-dim);\n");
        css.append("}\n\n");
        
        css.append(".status-dot {\n");
        css.append("  width: 8px;\n");
        css.append("  height: 8px;\n");
        css.append("  border-radius: 50%;\n");
        css.append("  background: #6acda5;\n");
        css.append("}\n\n");
        
        css.append(".status-dot.loading {\n");
        css.append("  background: #fbd38d;\n");
        css.append("  animation: pulse 1.5s infinite;\n");
        css.append("}\n\n");
        
        css.append("@keyframes pulse {\n");
        css.append("  0% { opacity: 0.4; }\n");
        css.append("  50% { opacity: 1; }\n");
        css.append("  100% { opacity: 0.4; }\n");
        css.append("}\n\n");
        
        // Buttons
        css.append("/* Buttons */\n");
        css.append(".btn {\n");
        css.append("  display: inline-flex;\n");
        css.append("  align-items: center;\n");
        css.append("  gap: 6px;\n");
        css.append("  padding: 8px 12px;\n");
        css.append("  border-radius: 8px;\n");
        css.append("  border: 1px solid var(--border);\n");
        css.append("  background: var(--bg-panel);\n");
        css.append("  color: var(--text-main);\n");
        css.append("  font-size: 12px;\n");
        css.append("  font-weight: 500;\n");
        css.append("  cursor: pointer;\n");
        css.append("  transition: all 0.2s ease;\n");
        css.append("}\n\n");
        
        css.append(".btn:hover {\n");
        css.append("  background: rgba(93, 138, 255, 0.1);\n");
        css.append("  border-color: var(--accent);\n");
        css.append("}\n\n");
        
        css.append(".btn:disabled {\n");
        css.append("  opacity: 0.5;\n");
        css.append("  cursor: not-allowed;\n");
        css.append("}\n\n");
        
        css.append(".btn-primary {\n");
        css.append("  background: var(--accent);\n");
        css.append("  border-color: var(--accent);\n");
        css.append("  color: white;\n");
        css.append("}\n\n");
        
        css.append(".btn-primary:hover:not(:disabled) {\n");
        css.append("  background: var(--accent-hover);\n");
        css.append("  border-color: var(--accent-hover);\n");
        css.append("}\n\n");
        
        css.append(".btn-icon {\n");
        css.append("  padding: 8px;\n");
        css.append("}\n\n");
        
        css.append(".btn-snap {\n");
        css.append("  background: linear-gradient(135deg, #ff7eb9, #ff758c);\n");
        css.append("  border: 1px solid #ff7eb9;\n");
        css.append("  color: white;\n");
        css.append("}\n\n");
        
        css.append(".btn-sm {\n");
        css.append("  padding: 4px 8px;\n");
        css.append("  font-size: 11px;\n");
        css.append("}\n\n");
        
        // Spinner
        css.append("/* Spinner */\n");
        css.append(".spinner {\n");
        css.append("  width: 16px;\n");
        css.append("  height: 16px;\n");
        css.append("  border: 2px solid rgba(255, 255, 255, 0.2);\n");
        css.append("  border-left-color: var(--accent);\n");
        css.append("  border-radius: 50%;\n");
        css.append("  animation: spin 1s linear infinite;\n");
        css.append("}\n\n");
        
        css.append("@keyframes spin {\n");
        css.append("  to { transform: rotate(360deg); }\n");
        css.append("}\n\n");
        
        // Settings modal
        css.append("/* Settings Modal */\n");
        css.append("#settings-modal {\n");
        css.append("  position: fixed;\n");
        css.append("  inset: 0;\n");
        css.append("  background: rgba(0, 0, 0, 0.7);\n");
        css.append("  display: none;\n");
        css.append("  align-items: center;\n");
        css.append("  justify-content: center;\n");
        css.append("  z-index: 1000;\n");
        css.append("}\n\n");
        
        css.append(".modal-box {\n");
        css.append("  background: var(--bg-card);\n");
        css.append("  border-radius: 16px;\n");
        css.append("  border: 1px solid var(--border);\n");
        css.append("  padding: 20px;\n");
        css.append("  max-height: 90vh;\n");
        css.append("  overflow-y: auto;\n");
        css.append("}\n\n");
        
        css.append(".modal-title {\n");
        css.append("  font-size: 18px;\n");
        css.append("  font-weight: 600;\n");
        css.append("  margin-bottom: 20px;\n");
        css.append("  color: var(--text-main);\n");
        css.append("}\n\n");
        
        css.append(".settings-section {\n");
        css.append("  margin-bottom: 24px;\n");
        css.append("}\n\n");
        
        css.append(".settings-section-title {\n");
        css.append("  font-size: 14px;\n");
        css.append("  font-weight: 600;\n");
        css.append("  margin-bottom: 12px;\n");
        css.append("}\n\n");
        
        css.append(".settings-label {\n");
        css.append("  display: block;\n");
        css.append("  font-size: 12px;\n");
        css.append("  margin-bottom: 6px;\n");
        css.append("  color: var(--text-muted);\n");
        css.append("}\n\n");
        
        css.append(".settings-input {\n");
        css.append("  width: 100%;\n");
        css.append("  padding: 10px 12px;\n");
        css.append("  border-radius: 8px;\n");
        css.append("  border: 1px solid var(--border);\n");
        css.append("  background: var(--bg-panel);\n");
        css.append("  color: var(--text-main);\n");
        css.append("  font-size: 12px;\n");
        css.append("  margin-bottom: 4px;\n");
        css.append("}\n\n");
        
        css.append(".settings-hint {\n");
        css.append("  font-size: 11px;\n");
        css.append("  color: var(--text-dim);\n");
        css.append("  margin-top: 4px;\n");
        css.append("}\n\n");
        
        css.append(".toggle-switch {\n");
        css.append("  position: relative;\n");
        css.append("  display: inline-block;\n");
        css.append("  width: 40px;\n");
        css.append("  height: 20px;\n");
        css.append("}\n\n");
        
        css.append(".toggle-switch input {\n");
        css.append("  opacity: 0;\n");
        css.append("  width: 0;\n");
        css.append("  height: 0;\n");
        css.append("}\n\n");
        
        css.append(".toggle-track {\n");
        css.append("  position: absolute;\n");
        css.append("  cursor: pointer;\n");
        css.append("  top: 0;\n");
        css.append("  left: 0;\n");
        css.append("  right: 0;\n");
        css.append("  bottom: 0;\n");
        css.append("  background: var(--bg-panel);\n");
        css.append("  border: 1px solid var(--border);\n");
        css.append("  border-radius: 20px;\n");
        css.append("  transition: .3s;\n");
        css.append("}\n\n");
        
        css.append(".toggle-thumb {\n");
        css.append("  position: absolute;\n");
        css.append("  content: \"\";\n");
        css.append("  height: 14px;\n");
        css.append("  width: 14px;\n");
        css.append("  left: 3px;\n");
        css.append("  bottom: 2px;\n");
        css.append("  background: var(--text-dim);\n");
        css.append("  border-radius: 50%;\n");
        css.append("  transition: .3s;\n");
        css.append("}\n\n");
        
        css.append("input:checked + .toggle-track {\n");
        css.append("  background: var(--accent);\n");
        css.append("  border-color: var(--accent);\n");
        css.append("}\n\n");
        
        css.append("input:checked + .toggle-track .toggle-thumb {\n");
        css.append("  background: white;\n");
        css.append("  transform: translateX(20px);\n");
        css.append("}\n\n");
        
        // Pixel inspector
        css.append("/* Pixel-Inspektor */\n");
        css.append(".pixel-swatch {\n");
        css.append("  width: 24px;\n");
        css.append("  height: 24px;\n");
        css.append("  border-radius: 4px;\n");
        css.append("  border: 1px solid var(--border);\n");
        css.append("}\n\n");
        
        css.append(".pixel-values {\n");
        css.append("  display: flex;\n");
        css.append("  flex-direction: column;\n");
        css.append("  font-size: 11px;\n");
        css.append("  color: var(--text-dim);\n");
        css.append("  gap: 2px;\n");
        css.append("}\n\n");
        
        // Upload zone
        css.append("/* Upload-Zone */\n");
        css.append("#upload-zone {\n");
        css.append("  position: fixed;\n");
        css.append("  inset: 0;\n");
        css.append("  background: rgba(0, 0, 0, 0.8);\n");
        css.append("  display: none;\n");
        css.append("  align-items: center;\n");
        css.append("  justify-content: center;\n");
        css.append("  color: var(--text-main);\n");
        css.append("  font-size: 16px;\n");
        css.append("  z-index: 100;\n");
        css.append("}\n\n");
        
        // Responsive
        css.append("/* Responsive */\n");
        css.append("@media (max-width: 768px) {\n");
        css.append("  #board {\n");
        css.append("    flex-direction: column;\n");
        css.append("  }\n\n");
        css.append("  #right-panel {\n");
        css.append("    width: 100%;\n");
        css.append("  }\n\n");
        css.append("  #camera-panel {\n");
        css.append("    min-width: unset;\n");
        css.append("  }\n");
        css.append("}\n");
        
        try (FileWriter writer = new FileWriter(outputFile)) {
            writer.write(css.toString());
            System.out.println("CSS file generated successfully: " + outputFile);
        } catch (IOException e) {
            System.err.println("Error writing CSS file: " + e.getMessage());
            System.exit(1);
        }
    }
}
