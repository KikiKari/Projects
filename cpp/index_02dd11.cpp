// abstraction-provenance: {"artifact_sha256": "796baa69883c68185cfc98eec22c0fe74b388ae02821c705abaead7576c6220e", "source_sha256": "58d92c4f40bf7edb6d494c682f4fa1268aea0c52ab326535c779d2f2c808fffd", "target_language": "cpp"}
// index_02dd11.css — portiert nach cpp
// Quelle: css, Projects@abstractions:css/index_02dd11.css
// Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <fstream>
#include <string>
#include <map>

void generateCSS(const std::string& filename) {
    std::ofstream file(filename);
    if (!file.is_open()) {
        std::cerr << "Error: Could not open file " << filename << " for writing." << std::endl;
        return;
    }

    // Write comments
    file << "/* abstraction-provenance: {\"artifact_sha256\": \"8b76660533c644ac76ba28b4dcfb567e78b781d329ee59f8e75ceb7f8348f402\", \"source_sha256\": \"02dd111b283ac08d7a9f3fbbe30150fb6db98097ed7bc68f2677c6df9c744bfb\", \"target_language\": \"css\"} */\n";
    file << "/* index.html — portiert nach css */\n";
    file << "/* Quelle: html, Projects@Vision-Check:Vision-Check/app/index.html */\n";
    file << "/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */\n\n";

    // Root variables
    file << "/* Root-Variablen */\n";
    file << ":root {\n";
    file << "  --bg-dark: #0a0f1e;\n";
    file << "  --bg-card: #121826;\n";
    file << "  --bg-panel: #1a2236;\n";
    file << "  --border: #25324d;\n";
    file << "  --text-main: #e6ecf5;\n";
    file << "  --text-muted: #a0b0cc;\n";
    file << "  --text-dim: #6c7a96;\n";
    file << "  --accent: #5d8aff;\n";
    file << "  --accent-hover: #7a9fff;\n";
    file << "  --accent-warn: #fbd38d;\n";
    file << "  --layer-0: #ff7eb9;\n";
    file << "  --layer-1: #4fd1c5;\n";
    file << "  --layer-2: #ffd166;\n";
    file << "  --layer-3-gpt: #6a5acd;\n";
    file << "  --layer-3-gemini: #4285f4;\n";
    file << "  --layer-3-claude: #f4a261;\n";
    file << "}\n\n";

    // Base styles
    file << "/* Basis-Stile */\n";
    file << "* {\n";
    file << "  box-sizing: border-box;\n";
    file << "  margin: 0;\n";
    file << "  padding: 0;\n";
    file << "}\n\n";

    file << "body {\n";
    file << "  font-family: 'Inter', sans-serif;\n";
    file << "  background: var(--bg-dark);\n";
    file << "  color: var(--text-main);\n";
    file << "  line-height: 1.5;\n";
    file << "  overflow: hidden;\n";
    file << "  height: 100vh;\n";
    file << "  display: flex;\n";
    file << "  flex-direction: column;\n";
    file << "}\n\n";

    // Header
    file << "/* Header */\n";
    file << "#app-header {\n";
    file << "  display: flex;\n";
    file << "  align-items: center;\n";
    file << "  justify-content: space-between;\n";
    file << "  padding: 12px 20px;\n";
    file << "  background: rgba(10, 15, 30, 0.8);\n";
    file << "  backdrop-filter: blur(10px);\n";
    file << "  border-bottom: 1px solid var(--border);\n";
    file << "  position: relative;\n";
    file << "  z-index: 10;\n";
    file << "}\n\n";

    file << ".header-brand {\n";
    file << "  display: flex;\n";
    file << "  align-items: center;\n";
    file << "  gap: 10px;\n";
    file << "}\n\n";

    file << ".header-brand h1 {\n";
    file << "  font-size: 18px;\n";
    file << "  font-weight: 600;\n";
    file << "  color: var(--text-main);\n";
    file << "}\n\n";

    file << ".layer-indicator {\n";
    file << "  display: flex;\n";
    file << "  align-items: center;\n";
    file << "  gap: 4px;\n";
    file << "}\n\n";

    file << ".layer-dot {\n";
    file << "  width: 8px;\n";
    file << "  height: 8px;\n";
    file << "  border-radius: 50%;\n";
    file << "  opacity: 0.4;\n";
    file << "}\n\n";

    file << ".layer-dot.active {\n";
    file << "  opacity: 1;\n";
    file << "  box-shadow: 0 0 6px currentColor;\n";
    file << "}\n\n";

    file << ".header-controls {\n";
    file << "  display: flex;\n";
    file << "  gap: 8px;\n";
    file << "}\n\n";

    // Main area
    file << "/* Hauptbereich */\n";
    file << "#board {\n";
    file << "  display: flex;\n";
    file << "  flex: 1;\n";
    file << "  overflow: hidden;\n";
    file << "  padding: 16px;\n";
    file << "  gap: 16px;\n";
    file << "}\n\n";

    // Camera panel
    file << "/* Kamera-Panel */\n";
    file << "#camera-panel {\n";
    file << "  flex: 1;\n";
    file << "  display: flex;\n";
    file << "  flex-direction: column;\n";
    file << "  background: var(--bg-card);\n";
    file << "  border-radius: 16px;\n";
    file << "  border: 1px solid var(--border);\n";
    file << "  overflow: hidden;\n";
    file << "  min-width: 320px;\n";
    file << "}\n\n";

    file << ".panel-header {\n";
    file << "  display: flex;\n";
    file << "  justify-content: space-between;\n";
    file << "  align-items: center;\n";
    file << "  padding: 12px 16px;\n";
    file << "  border-bottom: 1px solid var(--border);\n";
    file << "}\n\n";

    file << ".panel-title {\n";
    file << "  font-size: 12px;\n";
    file << "  font-weight: 600;\n";
    file << "  text-transform: uppercase;\n";
    file << "  letter-spacing: 0.5px;\n";
    file << "  color: var(--text-muted);\n";
    file << "}\n\n";

    file << ".badge {\n";
    file << "  font-size: 10px;\n";
    file << "  padding: 2px 6px;\n";
    file << "  border-radius: 4px;\n";
    file << "  background: rgba(106, 90, 205, 0.15);\n";
    file << "  color: var(--layer-3-gpt);\n";
    file << "  border: 1px solid rgba(106, 90, 205, 0.3);\n";
    file << "}\n\n";

    file << ".badge-idle {\n";
    file << "  background: rgba(106, 205, 172, 0.15);\n";
    file << "  color: #6acda5;\n";
    file << "  border: 1px solid rgba(106, 205, 172, 0.3);\n";
    file << "}\n\n";

    file << "#camera-viewport {\n";
    file << "  position: relative;\n";
    file << "  flex: 1;\n";
    file << "  background: #000;\n";
    file << "  overflow: hidden;\n";
    file << "  display: flex;\n";
    file << "  align-items: center;\n";
    file << "  justify-content: center;\n";
    file << "}\n\n";

    file << "#video, #canvas-overlay, #snap-canvas, #filtered-canvas {\n";
    file << "  position: absolute;\n";
    file << "  top: 0;\n";
    file << "  left: 0;\n";
    file << "  width: 100%;\n";
    file << "  height: 100%;\n";
    file << "  object-fit: contain;\n";
    file << "}\n\n";

    file << "#canvas-overlay {\n";
    file << "  pointer-events: none;\n";
    file << "  z-index: 2;\n";
    file << "}\n\n";

    file << "#start-overlay {\n";
    file << "  position: absolute;\n";
    file << "  inset: 0;\n";
    file << "  display: flex;\n";
    file << "  flex-direction: column;\n";
    file << "  align-items: center;\n";
    file << "  justify-content: center;\n";
    file << "  gap: 16px;\n";
    file << "  background: rgba(10, 15, 30, 0.8);\n";
    file << "  z-index: 5;\n";
    file << "}\n\n";

    file << "#pixel-loupe {\n";
    file << "  position: absolute;\n";
    file << "  bottom: 20px;\n";
    file << "  right: 20px;\n";
    file << "  background: rgba(0, 0, 0, 0.7);\n";
    file << "  border-radius: 8px;\n";
    file << "  padding: 8px;\n";
    file << "  display: none;\n";
    file << "  flex-direction: column;\n";
    file << "  align-items: center;\n";
    file << "  gap: 6px;\n";
    file << "  z-index: 3;\n";
    file << "}\n\n";

    file << "#loupe-canvas {\n";
    file << "  width: 80px;\n";
    file << "  height: 80px;\n";
    file << "  image-rendering: pixelated;\n";
    file << "  border: 1px solid rgba(255, 255, 255, 0.1);\n";
    file << "}\n\n";

    file << "#loupe-info {\n";
    file << "  font-size: 10px;\n";
    file << "  color: var(--text-dim);\n";
    file << "}\n\n";

    file << "#camera-controls {\n";
    file << "  display: flex;\n";
    file << "  align-items: center;\n";
    file << "  padding: 12px 16px;\n";
    file << "  gap: 12px;\n";
    file << "  border-top: 1px solid var(--border);\n";
    file << "}\n\n";

    file << "select {\n";
    file << "  background: var(--bg-panel);\n";
    file << "  color: var(--text-main);\n";
    file << "  border: 1px solid var(--border);\n";
    file << "  border-radius: 6px;\n";
    file << "  padding: 6px 10px;\n";
    file << "  font-size: 12px;\n";
    file << "}\n\n";

    // Right panel
    file << "/* Rechtes Panel */\n";
    file << "#right-panel {\n";
    file << "  width: 320px;\n";
    file << "  display: flex;\n";
    file << "  flex-direction: column;\n";
    file << "  gap: 16px;\n";
    file << "}\n\n";

    file << ".card {\n";
    file << "  background: var(--bg-card);\n";
    file << "  border-radius: 16px;\n";
    file << "  border: 1px solid var(--border);\n";
    file << "  overflow: hidden;\n";
    file << "  display: flex;\n";
    file << "  flex-direction: column;\n";
    file << "}\n\n";

    file << ".card-body {\n";
    file << "  padding: 16px;\n";
    file << "  flex: 1;\n";
    file << "}\n\n";

    file << ".slider-row {\n";
    file << "  display: flex;\n";
    file << "  align-items: center;\n";
    file << "  gap: 8px;\n";
    file << "  margin-bottom: 12px;\n";
    file << "}\n\n";

    file << ".slider-label {\n";
    file << "  font-size: 12px;\n";
    file << "  width: 100px;\n";
    file << "  color: var(--text-muted);\n";
    file << "}\n\n";

    file << "input[type=\"range\"] {\n";
    file << "  flex: 1;\n";
    file << "  height: 4px;\n";
    file << "  -webkit-appearance: none;\n";
    file << "  background: var(--bg-panel);\n";
    file << "  border-radius: 2px;\n";
    file << "  outline: none;\n";
    file << "}\n\n";

    file << "input[type=\"range\"]::-webkit-slider-thumb {\n";
    file << "  -webkit-appearance: none;\n";
    file << "  width: 16px;\n";
    file << "  height: 16px;\n";
    file << "  border-radius: 50%;\n";
    file << "  background: var(--accent);\n";
    file << "  cursor: pointer;\n";
    file << "}\n\n";

    file << ".slider-value {\n";
    file << "  font-size: 12px;\n";
    file << "  width: 40px;\n";
    file << "  text-align: right;\n";
    file << "  color: var(--text-muted);\n";
    file << "}\n\n";

    // Tabs
    file << "/* Tabs */\n";
    file << ".tab-bar {\n";
    file << "  display: flex;\n";
    file << "  border-bottom: 1px solid var(--border);\n";
    file << "}\n\n";

    file << ".tab {\n";
    file << "  flex: 1;\n";
    file << "  padding: 10px 12px;\n";
    file << "  font-size: 12px;\n";
    file << "  background: transparent;\n";
    file << "  border: none;\n";
    file << "  color: var(--text-dim);\n";
    file << "  cursor: pointer;\n";
    file << "  text-align: center;\n";
    file << "}\n\n";

    file << ".tab.active {\n";
    file << "  color: var(--text-main);\n";
    file << "  border-bottom: 2px solid var(--accent);\n";
    file << "  background: rgba(93, 138, 255, 0.05);\n";
    file << "}\n\n";

    file << ".tab-content {\n";
    file << "  display: none;\n";
    file << "}\n\n";

    file << ".tab-content.active {\n";
    file << "  display: block;\n";
    file << "}\n\n";

    // Status bar
    file << "/* Status-Leiste */\n";
    file << "#status-bar {\n";
    file << "  display: flex;\n";
    file << "  align-items: center;\n";
    file << "  gap: 8px;\n";
    file << "  padding: 8px 20px;\n";
    file << "  background: rgba(10, 15, 30, 0.6);\n";
    file << "  border-top: 1px solid var(--border);\n";
    file << "  font-size: 12px;\n";
    file << "  color: var(--text-dim);\n";
    file << "}\n\n";

    file << ".status-dot {\n";
    file << "  width: 8px;\n";
    file << "  height: 8px;\n";
    file << "  border-radius: 50%;\n";
    file << "  background: #6acda5;\n";
    file << "}\n\n";

    file << ".status-dot.loading {\n";
    file << "  background: #fbd38d;\n";
    file << "  animation: pulse 1.5s infinite;\n";
    file << "}\n\n";

    file << "@keyframes pulse {\n";
    file << "  0% { opacity: 0.4; }\n";
    file << "  50% { opacity: 1; }\n";
    file << "  100% { opacity: 0.4; }\n";
    file << "}\n\n";

    // Buttons
    file << "/* Buttons */\n";
    file << ".btn {\n";
    file << "  display: inline-flex;\n";
    file << "  align-items: center;\n";
    file << "  gap: 6px;\n";
    file << "  padding: 8px 12px;\n";
    file << "  border-radius: 8px;\n";
    file << "  border: 1px solid var(--border);\n";
    file << "  background: var(--bg-panel);\n";
    file << "  color: var(--text-main);\n";
    file << "  font-size: 12px;\n";
    file << "  font-weight: 500;\n";
    file << "  cursor: pointer;\n";
    file << "  transition: all 0.2s ease;\n";
    file << "}\n\n";

    file << ".btn:hover {\n";
    file << "  background: rgba(93, 138, 255, 0.1);\n";
    file << "  border-color: var(--accent);\n";
    file << "}\n\n";

    file << ".btn:disabled {\n";
    file << "  opacity: 0.5;\n";
    file << "  cursor: not-allowed;\n";
    file << "}\n\n";

    file << ".btn-primary {\n";
    file << "  background: var(--accent);\n";
    file << "  border-color: var(--accent);\n";
    file << "  color: white;\n";
    file << "}\n\n";

    file << ".btn-primary:hover:not(:disabled) {\n";
    file << "  background: var(--accent-hover);\n";
    file << "  border-color: var(--accent-hover);\n";
    file << "}\n\n";

    file << ".btn-icon {\n";
    file << "  padding: 8px;\n";
    file << "}\n\n";

    file << ".btn-snap {\n";
    file << "  background: linear-gradient(135deg, #ff7eb9, #ff758c);\n";
    file << "  border: 1px solid #ff7eb9;\n";
    file << "  color: white;\n";
    file << "}\n\n";

    file << ".btn-sm {\n";
    file << "  padding: 4px 8px;\n";
    file << "  font-size: 11px;\n";
    file << "}\n\n";

    // Spinner
    file << "/* Spinner */\n";
    file << ".spinner {\n";
    file << "  width: 16px;\n";
    file << "  height: 16px;\n";
    file << "  border: 2px solid rgba(255, 255, 255, 0.2);\n";
    file << "  border-left-color: var(--accent);\n";
    file << "  border-radius: 50%;\n";
    file << "  animation: spin 1s linear infinite;\n";
    file << "}\n\n";

    file << "@keyframes spin {\n";
    file << "  to { transform: rotate(360deg); }\n";
    file << "}\n\n";

    // Settings modal
    file << "/* Settings Modal */\n";
    file << "#settings-modal {\n";
    file << "  position: fixed;\n";
    file << "  inset: 0;\n";
    file << "  background: rgba(0, 0, 0, 0.7);\n";
    file << "  display: none;\n";
    file << "  align-items: center;\n";
    file << "  justify-content: center;\n";
    file << "  z-index: 1000;\n";
    file << "}\n\n";

    file << ".modal-box {\n";
    file << "  background: var(--bg-card);\n";
    file << "  border-radius: 16px;\n";
    file << "  border: 1px solid var(--border);\n";
    file << "  padding: 20px;\n";
    file << "  max-height: 90vh;\n";
    file << "  overflow-y: auto;\n";
    file << "}\n\n";

    file << ".modal-title {\n";
    file << "  font-size: 18px;\n";
    file << "  font-weight: 600;\n";
    file << "  margin-bottom: 20px;\n";
    file << "  color: var(--text-main);\n";
    file << "}\n\n";

    file << ".settings-section {\n";
    file << "  margin-bottom: 24px;\n";
    file << "}\n\n";

    file << ".settings-section-title {\n";
    file << "  font-size: 14px;\n";
    file << "  font-weight: 600;\n";
    file << "  margin-bottom: 12px;\n";
    file << "}\n\n";

    file << ".settings-label {\n";
    file << "  display: block;\n";
    file << "  font-size: 12px;\n";
    file << "  margin-bottom: 6px;\n";
    file << "  color: var(--text-muted);\n";
    file << "}\n\n";

    file << ".settings-input {\n";
    file << "  width: 100%;\n";
    file << "  padding: 10px 12px;\n";
    file << "  border-radius: 8px;\n";
    file << "  border: 1px solid var(--border);\n";
    file << "  background: var(--bg-panel);\n";
    file << "  color: var(--text-main);\n";
    file << "  font-size: 12px;\n";
    file << "  margin-bottom: 4px;\n";
    file << "}\n\n";

    file << ".settings-hint {\n";
    file << "  font-size: 11px;\n";
    file << "  color: var(--text-dim);\n";
    file << "  margin-top: 4px;\n";
    file << "}\n\n";

    file << ".toggle-switch {\n";
    file << "  position: relative;\n";
    file << "  display: inline-block;\n";
    file << "  width: 40px;\n";
    file << "  height: 20px;\n";
    file << "}\n\n";

    file << ".toggle-switch input {\n";
    file << "  opacity: 0;\n";
    file << "  width: 0;\n";
    file << "  height: 0;\n";
    file << "}\n\n";

    file << ".toggle-track {\n";
    file << "  position: absolute;\n";
    file << "  cursor: pointer;\n";
    file << "  top: 0;\n";
    file << "  left: 0;\n";
    file << "  right: 0;\n";
    file << "  bottom: 0;\n";
    file << "  background: var(--bg-panel);\n";
    file << "  border: 1px solid var(--border);\n";
    file << "  border-radius: 20px;\n";
    file << "  transition: .3s;\n";
    file << "}\n\n";

    file << ".toggle-thumb {\n";
    file << "  position: absolute;\n";
    file << "  content: \"\";\n";
    file << "  height: 14px;\n";
    file << "  width: 14px;\n";
    file << "  left: 3px;\n";
    file << "  bottom: 2px;\n";
    file << "  background: var(--text-dim);\n";
    file << "  border-radius: 50%;\n";
    file << "  transition: .3s;\n";
    file << "}\n\n";

    file << "input:checked + .toggle-track {\n";
    file << "  background: var(--accent);\n";
    file << "  border-color: var(--accent);\n";
    file << "}\n\n";

    file << "input:checked + .toggle-track .toggle-thumb {\n";
    file << "  background: white;\n";
    file << "  transform: translateX(20px);\n";
    file << "}\n\n";

    // Pixel inspector
    file << "/* Pixel-Inspektor */\n";
    file << ".pixel-swatch {\n";
    file << "  width: 24px;\n";
    file << "  height: 24px;\n";
    file << "  border-radius: 4px;\n";
    file << "  border: 1px solid var(--border);\n";
    file << "}\n\n";

    file << ".pixel-values {\n";
    file << "  display: flex;\n";
    file << "  flex-direction: column;\n";
    file << "  font-size: 11px;\n";
    file << "  color: var(--text-dim);\n";
    file << "  gap: 2px;\n";
    file << "}\n\n";

    // Upload zone
    file << "/* Upload-Zone */\n";
    file << "#upload-zone {\n";
    file << "  position: fixed;\n";
    file << "  inset: 0;\n";
    file << "  background: rgba(0, 0, 0, 0.8);\n";
    file << "  display: none;\n";
    file << "  align-items: center;\n";
    file << "  justify-content: center;\n";
    file << "  color: var(--text-main);\n";
    file << "  font-size: 16px;\n";
    file << "  z-index: 100;\n";
    file << "}\n\n";

    // Responsive
    file << "/* Responsive */\n";
    file << "@media (max-width: 768px) {\n";
    file << "  #board {\n";
    file << "    flex-direction: column;\n";
    file << "  }\n\n";
    file << "  #right-panel {\n";
    file << "    width: 100%;\n";
    file << "  }\n\n";
    file << "  #camera-panel {\n";
    file << "    min-width: unset;\n";
    file << "  }\n";
    file << "}\n";

    file.close();
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::cerr << "Usage: " << argv[0] << " <output_filename>" << std::endl;
        return 1;
    }

    generateCSS(argv[1]);
    return 0;
}
