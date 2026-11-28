// abstraction-provenance: {"artifact_sha256": "d31a1d8b01ba37ef3665dd9c753530940b9b767db103a5449ccdae1154a35287", "source_sha256": "58d92c4f40bf7edb6d494c682f4fa1268aea0c52ab326535c779d2f2c808fffd", "target_language": "c"}
// index_02dd11.css — portiert nach c
// Quelle: css, Projects@abstractions:css/index_02dd11.css
// Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void write_css_file(const char *filename) {
    FILE *file = fopen(filename, "w");
    if (!file) {
        perror("Failed to open file");
        return;
    }

    fprintf(file, "/* abstraction-provenance: {\"artifact_sha256\": \"8b76660533c644ac76ba28b4dcfb567e78b781d329ee59f8e75ceb7f8348f402\", \"source_sha256\": \"02dd111b283ac08d7a9f3fbbe30150fb6db98097ed7bc68f2677c6df9c744bfb\", \"target_language\": \"css\"} */\n");
    fprintf(file, "/* index.html — portiert nach css */\n");
    fprintf(file, "/* Quelle: html, Projects@Vision-Check:Vision-Check/app/index.html */\n");
    fprintf(file, "/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */\n\n");

    fprintf(file, "/* Root-Variablen */\n");
    fprintf(file, ":root {\n");
    fprintf(file, "  --bg-dark: #0a0f1e;\n");
    fprintf(file, "  --bg-card: #121826;\n");
    fprintf(file, "  --bg-panel: #1a2236;\n");
    fprintf(file, "  --border: #25324d;\n");
    fprintf(file, "  --text-main: #e6ecf5;\n");
    fprintf(file, "  --text-muted: #a0b0cc;\n");
    fprintf(file, "  --text-dim: #6c7a96;\n");
    fprintf(file, "  --accent: #5d8aff;\n");
    fprintf(file, "  --accent-hover: #7a9fff;\n");
    fprintf(file, "  --accent-warn: #fbd38d;\n");
    fprintf(file, "  --layer-0: #ff7eb9;\n");
    fprintf(file, "  --layer-1: #4fd1c5;\n");
    fprintf(file, "  --layer-2: #ffd166;\n");
    fprintf(file, "  --layer-3-gpt: #6a5acd;\n");
    fprintf(file, "  --layer-3-gemini: #4285f4;\n");
    fprintf(file, "  --layer-3-claude: #f4a261;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "/* Basis-Stile */\n");
    fprintf(file, "* {\n");
    fprintf(file, "  box-sizing: border-box;\n");
    fprintf(file, "  margin: 0;\n");
    fprintf(file, "  padding: 0;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "body {\n");
    fprintf(file, "  font-family: 'Inter', sans-serif;\n");
    fprintf(file, "  background: var(--bg-dark);\n");
    fprintf(file, "  color: var(--text-main);\n");
    fprintf(file, "  line-height: 1.5;\n");
    fprintf(file, "  overflow: hidden;\n");
    fprintf(file, "  height: 100vh;\n");
    fprintf(file, "  display: flex;\n");
    fprintf(file, "  flex-direction: column;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "/* Header */\n");
    fprintf(file, "#app-header {\n");
    fprintf(file, "  display: flex;\n");
    fprintf(file, "  align-items: center;\n");
    fprintf(file, "  justify-content: space-between;\n");
    fprintf(file, "  padding: 12px 20px;\n");
    fprintf(file, "  background: rgba(10, 15, 30, 0.8);\n");
    fprintf(file, "  backdrop-filter: blur(10px);\n");
    fprintf(file, "  border-bottom: 1px solid var(--border);\n");
    fprintf(file, "  position: relative;\n");
    fprintf(file, "  z-index: 10;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".header-brand {\n");
    fprintf(file, "  display: flex;\n");
    fprintf(file, "  align-items: center;\n");
    fprintf(file, "  gap: 10px;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".header-brand h1 {\n");
    fprintf(file, "  font-size: 18px;\n");
    fprintf(file, "  font-weight: 600;\n");
    fprintf(file, "  color: var(--text-main);\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".layer-indicator {\n");
    fprintf(file, "  display: flex;\n");
    fprintf(file, "  align-items: center;\n");
    fprintf(file, "  gap: 4px;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".layer-dot {\n");
    fprintf(file, "  width: 8px;\n");
    fprintf(file, "  height: 8px;\n");
    fprintf(file, "  border-radius: 50%%;\n");
    fprintf(file, "  opacity: 0.4;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".layer-dot.active {\n");
    fprintf(file, "  opacity: 1;\n");
    fprintf(file, "  box-shadow: 0 0 6px currentColor;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".header-controls {\n");
    fprintf(file, "  display: flex;\n");
    fprintf(file, "  gap: 8px;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "/* Hauptbereich */\n");
    fprintf(file, "#board {\n");
    fprintf(file, "  display: flex;\n");
    fprintf(file, "  flex: 1;\n");
    fprintf(file, "  overflow: hidden;\n");
    fprintf(file, "  padding: 16px;\n");
    fprintf(file, "  gap: 16px;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "/* Kamera-Panel */\n");
    fprintf(file, "#camera-panel {\n");
    fprintf(file, "  flex: 1;\n");
    fprintf(file, "  display: flex;\n");
    fprintf(file, "  flex-direction: column;\n");
    fprintf(file, "  background: var(--bg-card);\n");
    fprintf(file, "  border-radius: 16px;\n");
    fprintf(file, "  border: 1px solid var(--border);\n");
    fprintf(file, "  overflow: hidden;\n");
    fprintf(file, "  min-width: 320px;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".panel-header {\n");
    fprintf(file, "  display: flex;\n");
    fprintf(file, "  justify-content: space-between;\n");
    fprintf(file, "  align-items: center;\n");
    fprintf(file, "  padding: 12px 16px;\n");
    fprintf(file, "  border-bottom: 1px solid var(--border);\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".panel-title {\n");
    fprintf(file, "  font-size: 12px;\n");
    fprintf(file, "  font-weight: 600;\n");
    fprintf(file, "  text-transform: uppercase;\n");
    fprintf(file, "  letter-spacing: 0.5px;\n");
    fprintf(file, "  color: var(--text-muted);\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".badge {\n");
    fprintf(file, "  font-size: 10px;\n");
    fprintf(file, "  padding: 2px 6px;\n");
    fprintf(file, "  border-radius: 4px;\n");
    fprintf(file, "  background: rgba(106, 90, 205, 0.15);\n");
    fprintf(file, "  color: var(--layer-3-gpt);\n");
    fprintf(file, "  border: 1px solid rgba(106, 90, 205, 0.3);\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".badge-idle {\n");
    fprintf(file, "  background: rgba(106, 205, 172, 0.15);\n");
    fprintf(file, "  color: #6acda5;\n");
    fprintf(file, "  border: 1px solid rgba(106, 205, 172, 0.3);\n");
    fprintf(file, "}\n\n");

    fprintf(file, "#camera-viewport {\n");
    fprintf(file, "  position: relative;\n");
    fprintf(file, "  flex: 1;\n");
    fprintf(file, "  background: #000;\n");
    fprintf(file, "  overflow: hidden;\n");
    fprintf(file, "  display: flex;\n");
    fprintf(file, "  align-items: center;\n");
    fprintf(file, "  justify-content: center;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "#video, #canvas-overlay, #snap-canvas, #filtered-canvas {\n");
    fprintf(file, "  position: absolute;\n");
    fprintf(file, "  top: 0;\n");
    fprintf(file, "  left: 0;\n");
    fprintf(file, "  width: 100%%;\n");
    fprintf(file, "  height: 100%%;\n");
    fprintf(file, "  object-fit: contain;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "#canvas-overlay {\n");
    fprintf(file, "  pointer-events: none;\n");
    fprintf(file, "  z-index: 2;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "#start-overlay {\n");
    fprintf(file, "  position: absolute;\n");
    fprintf(file, "  inset: 0;\n");
    fprintf(file, "  display: flex;\n");
    fprintf(file, "  flex-direction: column;\n");
    fprintf(file, "  align-items: center;\n");
    fprintf(file, "  justify-content: center;\n");
    fprintf(file, "  gap: 16px;\n");
    fprintf(file, "  background: rgba(10, 15, 30, 0.8);\n");
    fprintf(file, "  z-index: 5;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "#pixel-loupe {\n");
    fprintf(file, "  position: absolute;\n");
    fprintf(file, "  bottom: 20px;\n");
    fprintf(file, "  right: 20px;\n");
    fprintf(file, "  background: rgba(0, 0, 0, 0.7);\n");
    fprintf(file, "  border-radius: 8px;\n");
    fprintf(file, "  padding: 8px;\n");
    fprintf(file, "  display: none;\n");
    fprintf(file, "  flex-direction: column;\n");
    fprintf(file, "  align-items: center;\n");
    fprintf(file, "  gap: 6px;\n");
    fprintf(file, "  z-index: 3;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "#loupe-canvas {\n");
    fprintf(file, "  width: 80px;\n");
    fprintf(file, "  height: 80px;\n");
    fprintf(file, "  image-rendering: pixelated;\n");
    fprintf(file, "  border: 1px solid rgba(255, 255, 255, 0.1);\n");
    fprintf(file, "}\n\n");

    fprintf(file, "#loupe-info {\n");
    fprintf(file, "  font-size: 10px;\n");
    fprintf(file, "  color: var(--text-dim);\n");
    fprintf(file, "}\n\n");

    fprintf(file, "#camera-controls {\n");
    fprintf(file, "  display: flex;\n");
    fprintf(file, "  align-items: center;\n");
    fprintf(file, "  padding: 12px 16px;\n");
    fprintf(file, "  gap: 12px;\n");
    fprintf(file, "  border-top: 1px solid var(--border);\n");
    fprintf(file, "}\n\n");

    fprintf(file, "select {\n");
    fprintf(file, "  background: var(--bg-panel);\n");
    fprintf(file, "  color: var(--text-main);\n");
    fprintf(file, "  border: 1px solid var(--border);\n");
    fprintf(file, "  border-radius: 6px;\n");
    fprintf(file, "  padding: 6px 10px;\n");
    fprintf(file, "  font-size: 12px;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "/* Rechtes Panel */\n");
    fprintf(file, "#right-panel {\n");
    fprintf(file, "  width: 320px;\n");
    fprintf(file, "  display: flex;\n");
    fprintf(file, "  flex-direction: column;\n");
    fprintf(file, "  gap: 16px;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".card {\n");
    fprintf(file, "  background: var(--bg-card);\n");
    fprintf(file, "  border-radius: 16px;\n");
    fprintf(file, "  border: 1px solid var(--border);\n");
    fprintf(file, "  overflow: hidden;\n");
    fprintf(file, "  display: flex;\n");
    fprintf(file, "  flex-direction: column;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".card-body {\n");
    fprintf(file, "  padding: 16px;\n");
    fprintf(file, "  flex: 1;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".slider-row {\n");
    fprintf(file, "  display: flex;\n");
    fprintf(file, "  align-items: center;\n");
    fprintf(file, "  gap: 8px;\n");
    fprintf(file, "  margin-bottom: 12px;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".slider-label {\n");
    fprintf(file, "  font-size: 12px;\n");
    fprintf(file, "  width: 100px;\n");
    fprintf(file, "  color: var(--text-muted);\n");
    fprintf(file, "}\n\n");

    fprintf(file, "input[type=\"range\"] {\n");
    fprintf(file, "  flex: 1;\n");
    fprintf(file, "  height: 4px;\n");
    fprintf(file, "  -webkit-appearance: none;\n");
    fprintf(file, "  background: var(--bg-panel);\n");
    fprintf(file, "  border-radius: 2px;\n");
    fprintf(file, "  outline: none;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "input[type=\"range\"]::-webkit-slider-thumb {\n");
    fprintf(file, "  -webkit-appearance: none;\n");
    fprintf(file, "  width: 16px;\n");
    fprintf(file, "  height: 16px;\n");
    fprintf(file, "  border-radius: 50%%;\n");
    fprintf(file, "  background: var(--accent);\n");
    fprintf(file, "  cursor: pointer;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".slider-value {\n");
    fprintf(file, "  font-size: 12px;\n");
    fprintf(file, "  width: 40px;\n");
    fprintf(file, "  text-align: right;\n");
    fprintf(file, "  color: var(--text-muted);\n");
    fprintf(file, "}\n\n");

    fprintf(file, "/* Tabs */\n");
    fprintf(file, ".tab-bar {\n");
    fprintf(file, "  display: flex;\n");
    fprintf(file, "  border-bottom: 1px solid var(--border);\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".tab {\n");
    fprintf(file, "  flex: 1;\n");
    fprintf(file, "  padding: 10px 12px;\n");
    fprintf(file, "  font-size: 12px;\n");
    fprintf(file, "  background: transparent;\n");
    fprintf(file, "  border: none;\n");
    fprintf(file, "  color: var(--text-dim);\n");
    fprintf(file, "  cursor: pointer;\n");
    fprintf(file, "  text-align: center;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".tab.active {\n");
    fprintf(file, "  color: var(--text-main);\n");
    fprintf(file, "  border-bottom: 2px solid var(--accent);\n");
    fprintf(file, "  background: rgba(93, 138, 255, 0.05);\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".tab-content {\n");
    fprintf(file, "  display: none;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".tab-content.active {\n");
    fprintf(file, "  display: block;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "/* Status-Leiste */\n");
    fprintf(file, "#status-bar {\n");
    fprintf(file, "  display: flex;\n");
    fprintf(file, "  align-items: center;\n");
    fprintf(file, "  gap: 8px;\n");
    fprintf(file, "  padding: 8px 20px;\n");
    fprintf(file, "  background: rgba(10, 15, 30, 0.6);\n");
    fprintf(file, "  border-top: 1px solid var(--border);\n");
    fprintf(file, "  font-size: 12px;\n");
    fprintf(file, "  color: var(--text-dim);\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".status-dot {\n");
    fprintf(file, "  width: 8px;\n");
    fprintf(file, "  height: 8px;\n");
    fprintf(file, "  border-radius: 50%%;\n");
    fprintf(file, "  background: #6acda5;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".status-dot.loading {\n");
    fprintf(file, "  background: #fbd38d;\n");
    fprintf(file, "  animation: pulse 1.5s infinite;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "@keyframes pulse {\n");
    fprintf(file, "  0%% { opacity: 0.4; }\n");
    fprintf(file, "  50%% { opacity: 1; }\n");
    fprintf(file, "  100%% { opacity: 0.4; }\n");
    fprintf(file, "}\n\n");

    fprintf(file, "/* Buttons */\n");
    fprintf(file, ".btn {\n");
    fprintf(file, "  display: inline-flex;\n");
    fprintf(file, "  align-items: center;\n");
    fprintf(file, "  gap: 6px;\n");
    fprintf(file, "  padding: 8px 12px;\n");
    fprintf(file, "  border-radius: 8px;\n");
    fprintf(file, "  border: 1px solid var(--border);\n");
    fprintf(file, "  background: var(--bg-panel);\n");
    fprintf(file, "  color: var(--text-main);\n");
    fprintf(file, "  font-size: 12px;\n");
    fprintf(file, "  font-weight: 500;\n");
    fprintf(file, "  cursor: pointer;\n");
    fprintf(file, "  transition: all 0.2s ease;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".btn:hover {\n");
    fprintf(file, "  background: rgba(93, 138, 255, 0.1);\n");
    fprintf(file, "  border-color: var(--accent);\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".btn:disabled {\n");
    fprintf(file, "  opacity: 0.5;\n");
    fprintf(file, "  cursor: not-allowed;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".btn-primary {\n");
    fprintf(file, "  background: var(--accent);\n");
    fprintf(file, "  border-color: var(--accent);\n");
    fprintf(file, "  color: white;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".btn-primary:hover:not(:disabled) {\n");
    fprintf(file, "  background: var(--accent-hover);\n");
    fprintf(file, "  border-color: var(--accent-hover);\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".btn-icon {\n");
    fprintf(file, "  padding: 8px;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".btn-snap {\n");
    fprintf(file, "  background: linear-gradient(135deg, #ff7eb9, #ff758c);\n");
    fprintf(file, "  border: 1px solid #ff7eb9;\n");
    fprintf(file, "  color: white;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".btn-sm {\n");
    fprintf(file, "  padding: 4px 8px;\n");
    fprintf(file, "  font-size: 11px;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "/* Spinner */\n");
    fprintf(file, ".spinner {\n");
    fprintf(file, "  width: 16px;\n");
    fprintf(file, "  height: 16px;\n");
    fprintf(file, "  border: 2px solid rgba(255, 255, 255, 0.2);\n");
    fprintf(file, "  border-left-color: var(--accent);\n");
    fprintf(file, "  border-radius: 50%%;\n");
    fprintf(file, "  animation: spin 1s linear infinite;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "@keyframes spin {\n");
    fprintf(file, "  to { transform: rotate(360deg); }\n");
    fprintf(file, "}\n\n");

    fprintf(file, "/* Settings Modal */\n");
    fprintf(file, "#settings-modal {\n");
    fprintf(file, "  position: fixed;\n");
    fprintf(file, "  inset: 0;\n");
    fprintf(file, "  background: rgba(0, 0, 0, 0.7);\n");
    fprintf(file, "  display: none;\n");
    fprintf(file, "  align-items: center;\n");
    fprintf(file, "  justify-content: center;\n");
    fprintf(file, "  z-index: 1000;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".modal-box {\n");
    fprintf(file, "  background: var(--bg-card);\n");
    fprintf(file, "  border-radius: 16px;\n");
    fprintf(file, "  border: 1px solid var(--border);\n");
    fprintf(file, "  padding: 20px;\n");
    fprintf(file, "  max-height: 90vh;\n");
    fprintf(file, "  overflow-y: auto;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".modal-title {\n");
    fprintf(file, "  font-size: 18px;\n");
    fprintf(file, "  font-weight: 600;\n");
    fprintf(file, "  margin-bottom: 20px;\n");
    fprintf(file, "  color: var(--text-main);\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".settings-section {\n");
    fprintf(file, "  margin-bottom: 24px;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".settings-section-title {\n");
    fprintf(file, "  font-size: 14px;\n");
    fprintf(file, "  font-weight: 600;\n");
    fprintf(file, "  margin-bottom: 12px;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".settings-label {\n");
    fprintf(file, "  display: block;\n");
    fprintf(file, "  font-size: 12px;\n");
    fprintf(file, "  margin-bottom: 6px;\n");
    fprintf(file, "  color: var(--text-muted);\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".settings-input {\n");
    fprintf(file, "  width: 100%%;\n");
    fprintf(file, "  padding: 10px 12px;\n");
    fprintf(file, "  border-radius: 8px;\n");
    fprintf(file, "  border: 1px solid var(--border);\n");
    fprintf(file, "  background: var(--bg-panel);\n");
    fprintf(file, "  color: var(--text-main);\n");
    fprintf(file, "  font-size: 12px;\n");
    fprintf(file, "  margin-bottom: 4px;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".settings-hint {\n");
    fprintf(file, "  font-size: 11px;\n");
    fprintf(file, "  color: var(--text-dim);\n");
    fprintf(file, "  margin-top: 4px;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".toggle-switch {\n");
    fprintf(file, "  position: relative;\n");
    fprintf(file, "  display: inline-block;\n");
    fprintf(file, "  width: 40px;\n");
    fprintf(file, "  height: 20px;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".toggle-switch input {\n");
    fprintf(file, "  opacity: 0;\n");
    fprintf(file, "  width: 0;\n");
    fprintf(file, "  height: 0;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".toggle-track {\n");
    fprintf(file, "  position: absolute;\n");
    fprintf(file, "  cursor: pointer;\n");
    fprintf(file, "  top: 0;\n");
    fprintf(file, "  left: 0;\n");
    fprintf(file, "  right: 0;\n");
    fprintf(file, "  bottom: 0;\n");
    fprintf(file, "  background: var(--bg-panel);\n");
    fprintf(file, "  border: 1px solid var(--border);\n");
    fprintf(file, "  border-radius: 20px;\n");
    fprintf(file, "  transition: .3s;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".toggle-thumb {\n");
    fprintf(file, "  position: absolute;\n");
    fprintf(file, "  content: \"\";\n");
    fprintf(file, "  height: 14px;\n");
    fprintf(file, "  width: 14px;\n");
    fprintf(file, "  left: 3px;\n");
    fprintf(file, "  bottom: 2px;\n");
    fprintf(file, "  background: var(--text-dim);\n");
    fprintf(file, "  border-radius: 50%%;\n");
    fprintf(file, "  transition: .3s;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "input:checked + .toggle-track {\n");
    fprintf(file, "  background: var(--accent);\n");
    fprintf(file, "  border-color: var(--accent);\n");
    fprintf(file, "}\n\n");

    fprintf(file, "input:checked + .toggle-track .toggle-thumb {\n");
    fprintf(file, "  background: white;\n");
    fprintf(file, "  transform: translateX(20px);\n");
    fprintf(file, "}\n\n");

    fprintf(file, "/* Pixel-Inspektor */\n");
    fprintf(file, ".pixel-swatch {\n");
    fprintf(file, "  width: 24px;\n");
    fprintf(file, "  height: 24px;\n");
    fprintf(file, "  border-radius: 4px;\n");
    fprintf(file, "  border: 1px solid var(--border);\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".pixel-values {\n");
    fprintf(file, "  display: flex;\n");
    fprintf(file, "  flex-direction: column;\n");
    fprintf(file, "  font-size: 11px;\n");
    fprintf(file, "  color: var(--text-dim);\n");
    fprintf(file, "  gap: 2px;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "/* Upload-Zone */\n");
    fprintf(file, "#upload-zone {\n");
    fprintf(file, "  position: fixed;\n");
    fprintf(file, "  inset: 0;\n");
    fprintf(file, "  background: rgba(0, 0, 0, 0.8);\n");
    fprintf(file, "  display: none;\n");
    fprintf(file, "  align-items: center;\n");
    fprintf(file, "  justify-content: center;\n");
    fprintf(file, "  color: var(--text-main);\n");
    fprintf(file, "  font-size: 16px;\n");
    fprintf(file, "  z-index: 100;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "/* Responsive */\n");
    fprintf(file, "@media (max-width: 768px) {\n");
    fprintf(file, "  #board {\n");
    fprintf(file, "    flex-direction: column;\n");
    fprintf(file, "  }\n\n");
    fprintf(file, "  #right-panel {\n");
    fprintf(file, "    width: 100%%;\n");
    fprintf(file, "  }\n\n");
    fprintf(file, "  #camera-panel {\n");
    fprintf(file, "    min-width: unset;\n");
    fprintf(file, "  }\n");
    fprintf(file, "}\n");

    fclose(file);
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <output_filename>\n", argv[0]);
        return 1;
    }

    write_css_file(argv[1]);
    return 0;
}
