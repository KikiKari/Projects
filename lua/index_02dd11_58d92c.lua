#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "2a8ab53229aea2ba8e34de44f02a05d79d9fb4c4cf2476eaafba013be246e16d", "source_sha256": "58d92c4f40bf7edb6d494c682f4fa1268aea0c52ab326535c779d2f2c808fffd", "target_language": "lua"}
-- index_02dd11.css — portiert nach lua
-- Quelle: css, Projects@abstractions:css/index_02dd11.css
-- Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

local function generate_css(output_file)
  local css_content = [[
/* abstraction-provenance: {"artifact_sha256": "8b76660533c644ac76ba28b4dcfb567e78b781d329ee59f8e75ceb7f8348f402", "source_sha256": "02dd111b283ac08d7a9f3fbbe30150fb6db98097ed7bc68f2677c6df9c744bfb", "target_language": "css"} */
/* index.html — portiert nach css */
/* Quelle: html, Projects@Vision-Check:Vision-Check/app/index.html */
/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */

/* Root-Variablen */
:root {
  --bg-dark: #0a0f1e;
  --bg-card: #121826;
  --bg-panel: #1a2236;
  --border: #25324d;
  --text-main: #e6ecf5;
  --text-muted: #a0b0cc;
  --text-dim: #6c7a96;
  --accent: #5d8aff;
  --accent-hover: #7a9fff;
  --accent-warn: #fbd38d;
  --layer-0: #ff7eb9;
  --layer-1: #4fd1c5;
  --layer-2: #ffd166;
  --layer-3-gpt: #6a5acd;
  --layer-3-gemini: #4285f4;
  --layer-3-claude: #f4a261;
}

/* Basis-Stile */
* {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

body {
  font-family: 'Inter', sans-serif;
  background: var(--bg-dark);
  color: var(--text-main);
  line-height: 1.5;
  overflow: hidden;
  height: 100vh;
  display: flex;
  flex-direction: column;
}

/* Header */
#app-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 20px;
  background: rgba(10, 15, 30, 0.8);
  backdrop-filter: blur(10px);
  border-bottom: 1px solid var(--border);
  position: relative;
  z-index: 10;
}

.header-brand {
  display: flex;
  align-items: center;
  gap: 10px;
}

.header-brand h1 {
  font-size: 18px;
  font-weight: 600;
  color: var(--text-main);
}

.layer-indicator {
  display: flex;
  align-items: center;
  gap: 4px;
}

.layer-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  opacity: 0.4;
}

.layer-dot.active {
  opacity: 1;
  box-shadow: 0 0 6px currentColor;
}

.header-controls {
  display: flex;
  gap: 8px;
}

/* Hauptbereich */
#board {
  display: flex;
  flex: 1;
  overflow: hidden;
  padding: 16px;
  gap: 16px;
}

/* Kamera-Panel */
#camera-panel {
  flex: 1;
  display: flex;
  flex-direction: column;
  background: var(--bg-card);
  border-radius: 16px;
  border: 1px solid var(--border);
  overflow: hidden;
  min-width: 320px;
}

.panel-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 16px;
  border-bottom: 1px solid var(--border);
}

.panel-title {
  font-size: 12px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  color: var(--text-muted);
}

.badge {
  font-size: 10px;
  padding: 2px 6px;
  border-radius: 4px;
  background: rgba(106, 90, 205, 0.15);
  color: var(--layer-3-gpt);
  border: 1px solid rgba(106, 90, 205, 0.3);
}

.badge-idle {
  background: rgba(106, 205, 172, 0.15);
  color: #6acda5;
  border: 1px solid rgba(106, 205, 172, 0.3);
}

#camera-viewport {
  position: relative;
  flex: 1;
  background: #000;
  overflow: hidden;
  display: flex;
  align-items: center;
  justify-content: center;
}

#video, #canvas-overlay, #snap-canvas, #filtered-canvas {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  object-fit: contain;
}

#canvas-overlay {
  pointer-events: none;
  z-index: 2;
}

#start-overlay {
  position: absolute;
  inset: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 16px;
  background: rgba(10, 15, 30, 0.8);
  z-index: 5;
}

#pixel-loupe {
  position: absolute;
  bottom: 20px;
  right: 20px;
  background: rgba(0, 0, 0, 0.7);
  border-radius: 8px;
  padding: 8px;
  display: none;
  flex-direction: column;
  align-items: center;
  gap: 6px;
  z-index: 3;
}

#loupe-canvas {
  width: 80px;
  height: 80px;
  image-rendering: pixelated;
  border: 1px solid rgba(255, 255, 255, 0.1);
}

#loupe-info {
  font-size: 10px;
  color: var(--text-dim);
}

#camera-controls {
  display: flex;
  align-items: center;
  padding: 12px 16px;
  gap: 12px;
  border-top: 1px solid var(--border);
}

select {
  background: var(--bg-panel);
  color: var(--text-main);
  border: 1px solid var(--border);
  border-radius: 6px;
  padding: 6px 10px;
  font-size: 12px;
}

/* Rechtes Panel */
#right-panel {
  width: 320px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.card {
  background: var(--bg-card);
  border-radius: 16px;
  border: 1px solid var(--border);
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.card-body {
  padding: 16px;
  flex: 1;
}

.slider-row {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 12px;
}

.slider-label {
  font-size: 12px;
  width: 100px;
  color: var(--text-muted);
}

input[type="range"] {
  flex: 1;
  height: 4px;
  -webkit-appearance: none;
  background: var(--bg-panel);
  border-radius: 2px;
  outline: none;
}

input[type="range"]::-webkit-slider-thumb {
  -webkit-appearance: none;
  width: 16px;
  height: 16px;
  border-radius: 50%;
  background: var(--accent);
  cursor: pointer;
}

.slider-value {
  font-size: 12px;
  width: 40px;
  text-align: right;
  color: var(--text-muted);
}

/* Tabs */
.tab-bar {
  display: flex;
  border-bottom: 1px solid var(--border);
}

.tab {
  flex: 1;
  padding: 10px 12px;
  font-size: 12px;
  background: transparent;
  border: none;
  color: var(--text-dim);
  cursor: pointer;
  text-align: center;
}

.tab.active {
  color: var(--text-main);
  border-bottom: 2px solid var(--accent);
  background: rgba(93, 138, 255, 0.05);
}

.tab-content {
  display: none;
}

.tab-content.active {
  display: block;
}

/* Status-Leiste */
#status-bar {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 20px;
  background: rgba(10, 15, 30, 0.6);
  border-top: 1px solid var(--border);
  font-size: 12px;
  color: var(--text-dim);
}

.status-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: #6acda5;
}

.status-dot.loading {
  background: #fbd38d;
  animation: pulse 1.5s infinite;
}

@keyframes pulse {
  0% { opacity: 0.4; }
  50% { opacity: 1; }
  100% { opacity: 0.4; }
}

/* Buttons */
.btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 8px 12px;
  border-radius: 8px;
  border: 1px solid var(--border);
  background: var(--bg-panel);
  color: var(--text-main);
  font-size: 12px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s ease;
}

.btn:hover {
  background: rgba(93, 138, 255, 0.1);
  border-color: var(--accent);
}

.btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.btn-primary {
  background: var(--accent);
  border-color: var(--accent);
  color: white;
}

.btn-primary:hover:not(:disabled) {
  background: var(--accent-hover);
  border-color: var(--accent-hover);
}

.btn-icon {
  padding: 8px;
}

.btn-snap {
  background: linear-gradient(135deg, #ff7eb9, #ff758c);
  border: 1px solid #ff7eb9;
  color: white;
}

.btn-sm {
  padding: 4px 8px;
  font-size: 11px;
}

/* Spinner */
.spinner {
  width: 16px;
  height: 16px;
  border: 2px solid rgba(255, 255, 255, 0.2);
  border-left-color: var(--accent);
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

/* Settings Modal */
#settings-modal {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.7);
  display: none;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal-box {
  background: var(--bg-card);
  border-radius: 16px;
  border: 1px solid var(--border);
  padding: 20px;
  max-height: 90vh;
  overflow-y: auto;
}

.modal-title {
  font-size: 18px;
  font-weight: 600;
  margin-bottom: 20px;
  color: var(--text-main);
}

.settings-section {
  margin-bottom: 24px;
}

.settings-section-title {
  font-size: 14px;
  font-weight: 600;
  margin-bottom: 12px;
}

.settings-label {
  display: block;
  font-size: 12px;
  margin-bottom: 6px;
  color: var(--text-muted);
}

.settings-input {
  width: 100%;
  padding: 10px 12px;
  border-radius: 8px;
  border: 1px solid var(--border);
  background: var(--bg-panel);
  color: var(--text-main);
  font-size: 12px;
  margin-bottom: 4px;
}

.settings-hint {
  font-size: 11px;
  color: var(--text-dim);
  margin-top: 4px;
}

.toggle-switch {
  position: relative;
  display: inline-block;
  width: 40px;
  height: 20px;
}

.toggle-switch input {
  opacity: 0;
  width: 0;
  height: 0;
}

.toggle-track {
  position: absolute;
  cursor: pointer;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: var(--bg-panel);
  border: 1px solid var(--border);
  border-radius: 20px;
  transition: .3s;
}

.toggle-thumb {
  position: absolute;
  content: "";
  height: 14px;
  width: 14px;
  left: 3px;
  bottom: 2px;
  background: var(--text-dim);
  border-radius: 50%;
  transition: .3s;
}

input:checked + .toggle-track {
  background: var(--accent);
  border-color: var(--accent);
}

input:checked + .toggle-track .toggle-thumb {
  background: white;
  transform: translateX(20px);
}

/* Pixel-Inspektor */
.pixel-swatch {
  width: 24px;
  height: 24px;
  border-radius: 4px;
  border: 1px solid var(--border);
}

.pixel-values {
  display: flex;
  flex-direction: column;
  font-size: 11px;
  color: var(--text-dim);
  gap: 2px;
}

/* Upload-Zone */
#upload-zone {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.8);
  display: none;
  align-items: center;
  justify-content: center;
  color: var(--text-main);
  font-size: 16px;
  z-index: 100;
}

/* Responsive */
@media (max-width: 768px) {
  #board {
    flex-direction: column;
  }

  #right-panel {
    width: 100%;
  }

  #camera-panel {
    min-width: unset;
  }
}
]]

  local file = io.open(output_file, "w")
  if file then
    file:write(css_content)
    file:close()
    print("CSS file generated successfully: " .. output_file)
  else
    print("Error: Could not write to file " .. output_file)
  end
end

-- Main execution
if #arg ~= 1 then
  print("Usage: " .. arg[0] .. " <output_file>")
  os.exit(1)
end

generate_css(arg[1])
