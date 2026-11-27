#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "b5795735ae2ae244dba78862f1c235c7eb8b560872925144250bde9a0982f9e8", "source_sha256": "8c27d4100abf548d397238253c635c8516dc1bf3a1f72639a0d8228e949fcbbd", "target_language": "javascript"}
// style.css — portiert nach javascript
// Quelle: css, Projects@Vision-Check:Vision-Check/app/css/style.css
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

const fs = require('fs');
const path = require('path');

function generateCSS() {
  const cssRules = [];

  // Root variables
  cssRules.push(`:root {
  /* Farben */
  --bg-deep:      #0a0f1e;
  --bg-surface:   #111827;
  --bg-card:      #1a2235;
  --bg-hover:     #1f2d45;
  --border:       rgba(99, 179, 237, 0.15);
  --border-glow:  rgba(99, 179, 237, 0.4);

  --accent:       #63b3ed;
  --accent-2:     #4fd1c5;
  --accent-warn:  #fbd38d;
  --accent-ok:    #68d391;
  --accent-err:   #fc8181;

  --text-primary: #e2e8f0;
  --text-muted:   #718096;
  --text-dim:     #4a5568;

  /* Schicht-Farben */
  --layer-0: #805ad5; /* iNaturalist */
  --layer-1: #4fd1c5; /* TensorFlow lokal */
  --layer-2: #fbd38d; /* Canvas Filter */
  --layer-3-gpt:    #68d391;
  --layer-3-gemini: #63b3ed;
  --layer-3-claude: #fc8181;

  /* Spacing */
  --radius:  8px;
  --radius-l: 14px;
  --gap:     12px;
}`);

  // Universal selector
  cssRules.push(`*, *::before, *::after {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}`);

  // HTML and Body
  cssRules.push(`html, body {
  height: 100%;
  background: var(--bg-deep);
  color: var(--text-primary);
  font-family: 'Inter', system-ui, -apple-system, sans-serif;
  font-size: 14px;
  line-height: 1.5;
  overflow: hidden;
}`);

  // App Header
  cssRules.push(`#app-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 16px;
  background: var(--bg-surface);
  border-bottom: 1px solid var(--border);
  height: 52px;
  flex-shrink: 0;
  z-index: 100;
}`);

  cssRules.push(`.header-brand {
  display: flex;
  align-items: center;
  gap: 8px;
}`);

  cssRules.push(`.header-brand svg {
  width: 28px;
  height: 28px;
  color: var(--accent);
}`);

  cssRules.push(`.header-brand h1 {
  font-size: 16px;
  font-weight: 700;
  background: linear-gradient(90deg, var(--accent), var(--accent-2));
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}`);

  cssRules.push(`.header-controls {
  display: flex;
  align-items: center;
  gap: 8px;
}`);

  // App Layout
  cssRules.push(`#app {
  display: flex;
  flex-direction: column;
  height: 100vh;
}`);

  cssRules.push(`#board {
  display: grid;
  grid-template-columns: 1fr 320px;
  grid-template-rows: 1fr auto;
  gap: var(--gap);
  padding: var(--gap);
  flex: 1;
  overflow: hidden;
}`);

  // Camera Panel
  cssRules.push(`#camera-panel {
  grid-column: 1;
  grid-row: 1;
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-radius: var(--radius-l);
  display: flex;
  flex-direction: column;
  overflow: hidden;
  position: relative;
}`);

  cssRules.push(`.panel-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 14px;
  border-bottom: 1px solid var(--border);
  background: var(--bg-surface);
  flex-shrink: 0;
}`);

  cssRules.push(`.panel-title {
  font-size: 12px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  color: var(--text-muted);
}`);

  cssRules.push(`.badge {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 2px 8px;
  border-radius: 20px;
  font-size: 10px;
  font-weight: 600;
  text-transform: uppercase;
}`);

  cssRules.push(`.badge-live {
  background: rgba(104, 211, 145, 0.15);
  color: var(--accent-ok);
}`);

  cssRules.push(`.badge-idle {
  background: rgba(113, 128, 150, 0.15);
  color: var(--text-muted);
}`);

  cssRules.push(`.badge-loading {
  background: rgba(251, 211, 141, 0.15);
  color: var(--accent-warn);
}`);

  // Camera Viewport
  cssRules.push(`#camera-viewport {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
  background: #000;
  overflow: hidden;
}`);

  cssRules.push(`#video {
  width: 100%;
  height: 100%;
  object-fit: contain;
  display: block;
}`);

  cssRules.push(`#canvas-overlay {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  pointer-events: none;
}`);

  cssRules.push(`#snap-canvas {
  display: none;
}`);

  // Zoom Loupe
  cssRules.push(`#pixel-loupe {
  position: absolute;
  bottom: 16px;
  right: 16px;
  width: 160px;
  height: 160px;
  border: 2px solid var(--accent);
  border-radius: var(--radius);
  overflow: hidden;
  background: #000;
  display: none;
  box-shadow: 0 0 20px rgba(99, 179, 237, 0.3);
}`);

  cssRules.push(`#loupe-canvas {
  width: 100%;
  height: 100%;
}`);

  cssRules.push(`#loupe-info {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  background: rgba(0, 0, 0, 0.8);
  padding: 4px 6px;
  font-size: 10px;
  font-family: 'JetBrains Mono', monospace;
  color: var(--accent);
  text-align: center;
}`);

  // Camera Controls
  cssRules.push(`#camera-controls {
  padding: 10px 14px;
  border-top: 1px solid var(--border);
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
  background: var(--bg-surface);
  flex-shrink: 0;
}`);

  // Right Panel
  cssRules.push(`#right-panel {
  grid-column: 2;
  grid-row: 1 / 3;
  display: flex;
  flex-direction: column;
  gap: var(--gap);
  overflow-y: auto;
  padding-right: 2px;
}`);

  cssRules.push(`#right-panel::-webkit-scrollbar {
  width: 4px;
}`);

  cssRules.push(`#right-panel::-webkit-scrollbar-track {
  background: transparent;
}`);

  cssRules.push(`#right-panel::-webkit-scrollbar-thumb {
  background: var(--border);
  border-radius: 2px;
}`);

  // Cards
  cssRules.push(`.card {
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-radius: var(--radius-l);
  overflow: hidden;
}`);

  cssRules.push(`.card-body {
  padding: 12px 14px;
}`);

  // Filter Panel
  cssRules.push(`.slider-row {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 10px;
}`);

  cssRules.push(`.slider-row:last-child {
  margin-bottom: 0;
}`);

  cssRules.push(`.slider-label {
  width: 90px;
  font-size: 11px;
  color: var(--text-muted);
  flex-shrink: 0;
}`);

  cssRules.push(`.slider-row input[type="range"] {
  flex: 1;
  -webkit-appearance: none;
  height: 4px;
  border-radius: 2px;
  background: var(--bg-deep);
  outline: none;
  cursor: pointer;
}`);

  cssRules.push(`.slider-row input[type="range"]::-webkit-slider-thumb {
  -webkit-appearance: none;
  width: 14px;
  height: 14px;
  border-radius: 50%;
  background: var(--accent);
  border: 2px solid var(--bg-card);
  cursor: pointer;
  transition: transform 0.15s;
}`);

  cssRules.push(`.slider-row input[type="range"]::-webkit-slider-thumb:hover {
  transform: scale(1.2);
}`);

  cssRules.push(`.slider-value {
  width: 32px;
  font-size: 11px;
  color: var(--accent);
  font-family: monospace;
  text-align: right;
  flex-shrink: 0;
}`);

  // Analysis Results
  cssRules.push(`.result-block {
  margin-bottom: 12px;
  padding: 10px;
  background: var(--bg-surface);
  border: 1px solid var(--border);
  border-radius: var(--radius);
}`);

  cssRules.push(`.result-block:last-child {
  margin-bottom: 0;
}`);

  cssRules.push(`.result-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 6px;
}`);

  cssRules.push(`.layer-tag {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  font-size: 10px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.06em;
}`);

  cssRules.push(`.result-text {
  font-size: 12px;
  color: var(--text-primary);
  line-height: 1.6;
  white-space: pre-wrap;
}`);

  cssRules.push(`.detection-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 4px 0;
  border-bottom: 1px solid var(--border);
  font-size: 12px;
}`);

  cssRules.push(`.detection-item:last-child {
  border-bottom: none;
}`);

  cssRules.push(`.detection-class {
  font-weight: 600;
  color: var(--layer-1);
}`);

  cssRules.push(`.confidence-bar {
  display: flex;
  align-items: center;
  gap: 6px;
}`);

  cssRules.push(`.confidence-track {
  width: 60px;
  height: 4px;
  background: var(--bg-deep);
  border-radius: 2px;
  overflow: hidden;
}`);

  cssRules.push(`.confidence-fill {
  height: 100%;
  background: var(--accent-ok);
  border-radius: 2px;
  transition: width 0.3s;
}`);

  cssRules.push(`.confidence-pct {
  font-size: 10px;
  color: var(--text-muted);
  width: 32px;
  text-align: right;
}`);

  // Pixel Inspector
  cssRules.push(`#pixel-info {
  display: flex;
  gap: 8px;
  align-items: center;
}`);

  cssRules.push(`.pixel-swatch {
  width: 36px;
  height: 36px;
  border-radius: var(--radius);
  border: 2px solid var(--border);
  flex-shrink: 0;
}`);

  cssRules.push(`.pixel-values {
  display: flex;
  flex-direction: column;
  gap: 2px;
}`);

  cssRules.push(`.pixel-values span {
  font-size: 11px;
  font-family: 'JetBrains Mono', monospace;
  color: var(--text-primary);
}`);

  // Buttons
  cssRules.push(`.btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 7px 14px;
  border: 1px solid var(--border);
  border-radius: var(--radius);
  background: var(--bg-surface);
  color: var(--text-primary);
  font-size: 12px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
  white-space: nowrap;
}`);

  cssRules.push(`.btn:hover {
  background: var(--bg-hover);
  border-color: var(--border-glow);
}`);

  cssRules.push(`.btn:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}`);

  cssRules.push(`.btn-primary {
  background: rgba(99, 179, 237, 0.15);
  border-color: var(--accent);
  color: var(--accent);
}`);

  cssRules.push(`.btn-primary:hover {
  background: rgba(99, 179, 237, 0.25);
}`);

  cssRules.push(`.btn-snap {
  background: rgba(104, 211, 145, 0.15);
  border-color: var(--accent-ok);
  color: var(--accent-ok);
  padding: 9px 20px;
  font-size: 13px;
  font-weight: 600;
}`);

  cssRules.push(`.btn-snap:hover {
  background: rgba(104, 211, 145, 0.25);
}`);

  cssRules.push(`.btn-danger {
  background: rgba(252, 129, 129, 0.1);
  border-color: var(--accent-err);
  color: var(--accent-err);
}`);

  cssRules.push(`.btn-sm {
  padding: 4px 10px;
  font-size: 11px;
}`);

  cssRules.push(`.btn-icon {
  padding: 7px;
  border-radius: var(--radius);
}`);

  // Select
  cssRules.push(`select {
  background: var(--bg-surface);
  border: 1px solid var(--border);
  color: var(--text-primary);
  border-radius: var(--radius);
  padding: 6px 10px;
  font-size: 12px;
  cursor: pointer;
  outline: none;
  transition: border-color 0.2s;
}`);

  cssRules.push(`select:hover, select:focus {
  border-color: var(--border-glow);
}`);

  // Spinner
  cssRules.push(`.spinner {
  width: 16px;
  height: 16px;
  border: 2px solid var(--border);
  border-top-color: var(--accent);
  border-radius: 50%;
  animation: spin 0.7s linear infinite;
  flex-shrink: 0;
}`);

  cssRules.push(`@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}`);

  // Settings Modal
  cssRules.push(`#settings-modal {
  display: none;
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.7);
  z-index: 200;
  align-items: center;
  justify-content: center;
  backdrop-filter: blur(4px);
}`);

  cssRules.push(`#settings-modal.open {
  display: flex;
}`);

  cssRules.push(`.modal-box {
  background: var(--bg-card);
  border: 1px solid var(--border-glow);
  border-radius: var(--radius-l);
  padding: 24px;
  width: 480px;
  max-width: calc(100vw - 32px);
  max-height: 80vh;
  overflow-y: auto;
}`);

  cssRules.push(`.modal-title {
  font-size: 16px;
  font-weight: 700;
  color: var(--accent);
  margin-bottom: 20px;
}`);

  cssRules.push(`.settings-section {
  margin-bottom: 20px;
}`);

  cssRules.push(`.settings-label {
  display: block;
  font-size: 11px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  color: var(--text-muted);
  margin-bottom: 6px;
}`);

  cssRules.push(`.settings-input {
  width: 100%;
  background: var(--bg-deep);
  border: 1px solid var(--border);
  color: var(--text-primary);
  border-radius: var(--radius);
  padding: 8px 12px;
  font-size: 12px;
  font-family: 'JetBrains Mono', monospace;
  outline: none;
  transition: border-color 0.2s;
}`);

  cssRules.push(`.settings-input:focus {
  border-color: var(--accent);
}`);

  cssRules.push(`.settings-hint {
  font-size: 10px;
  color: var(--text-dim);
  margin-top: 4px;
}`);

  cssRules.push(`.settings-section-title {
  font-size: 13px;
  font-weight: 600;
  color: var(--text-primary);
  margin-bottom: 12px;
  padding-bottom: 8px;
  border-bottom: 1px solid var(--border);
}`);

  // Snapshot Preview
  cssRules.push(`#snapshot-area {
  display: none;
}`);

  cssRules.push(`#snapshot-preview {
  width: 100%;
  border-radius: var(--radius);
  border: 1px solid var(--border);
}`);

  // Status Bar
  cssRules.push(`#status-bar {
  grid-column: 1;
  grid-row: 2;
  background: var(--bg-surface);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  padding: 6px 12px;
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 11px;
  color: var(--text-muted);
  flex-shrink: 0;
}`);

  cssRules.push(`.status-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: var(--text-dim);
  flex-shrink: 0;
}`);

  cssRules.push(`.status-dot.ok {
  background: var(--accent-ok);
  box-shadow: 0 0 6px var(--accent-ok);
}`);

  cssRules.push(`.status-dot.warn {
  background: var(--accent-warn);
}`);

  cssRules.push(`.status-dot.err {
  background: var(--accent-err);
}`);

  cssRules.push(`#status-text {
  flex: 1;
}`);

  // Layer Indicator
  cssRules.push(`.layer-indicator {
  display: flex;
  gap: 4px;
  align-items: center;
}`);

  cssRules.push(`.layer-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  opacity: 0.3;
  transition: opacity 0.3s, box-shadow 0.3s;
}`);

  cssRules.push(`.layer-dot.active {
  opacity: 1;
  box-shadow: 0 0 6px currentColor;
}`);

  // Analysis Tabs
  cssRules.push(`.tab-bar {
  display: flex;
  gap: 2px;
  padding: 8px 14px;
  border-bottom: 1px solid var(--border);
  background: var(--bg-surface);
}`);

  cssRules.push(`.tab {
  padding: 5px 12px;
  border-radius: var(--radius);
  font-size: 11px;
  font-weight: 600;
  cursor: pointer;
  color: var(--text-muted);
  transition: all 0.2s;
  border: 1px solid transparent;
  background: transparent;
}`);

  cssRules.push(`.tab.active {
  background: var(--bg-hover);
  border-color: var(--border-glow);
  color: var(--accent);
}`);

  cssRules.push(`.tab-content {
  display: none;
}`);

  cssRules.push(`.tab-content.active {
  display: block;
}`);

  // iNaturalist Card
  cssRules.push(`.species-card {
  display: flex;
  gap: 10px;
  padding: 8px;
  background: var(--bg-deep);
  border-radius: var(--radius);
  margin-bottom: 8px;
  border: 1px solid var(--border);
}`);

  cssRules.push(`.species-img {
  width: 48px;
  height: 48px;
  border-radius: var(--radius);
  object-fit: cover;
  flex-shrink: 0;
  background: var(--bg-surface);
}`);

  cssRules.push(`.species-info {
  flex: 1;
  min-width: 0;
}`);

  cssRules.push(`.species-name {
  font-size: 12px;
  font-weight: 600;
  color: var(--layer-0);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}`);

  cssRules.push(`.species-latin {
  font-size: 10px;
  color: var(--text-muted);
  font-style: italic;
}`);

  cssRules.push(`.species-score {
  font-size: 10px;
  color: var(--text-dim);
  margin-top: 2px;
}`);

  // Media Query for Mobile
  cssRules.push(`@media (max-width: 768px) {
  #board {
    grid-template-columns: 1fr;
    grid-template-rows: 1fr auto auto;
    overflow-y: auto;
  }

  #camera-panel {
    grid-column: 1;
    grid-row: 1;
    min-height: 55vw;
  }

  #right-panel {
    grid-column: 1;
    grid-row: 2;
    overflow-y: visible;
    max-height: none;
  }

  #status-bar {
    grid-column: 1;
    grid-row: 3;
  }

  html, body {
    overflow: auto;
  }
}`);

  // Animations
  cssRules.push(`@keyframes pulse-glow {
  0%, 100% {
    box-shadow: 0 0 4px var(--accent);
  }

  50% {
    box-shadow: 0 0 16px var(--accent);
  }
}`);

  cssRules.push(`.glow-pulse {
  animation: pulse-glow 2s ease-in-out infinite;
}`);

  cssRules.push(`.fade-in {
  animation: fadeIn 0.3s ease;
}`);

  cssRules.push(`@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(4px);
  }

  to {
    opacity: 1;
    transform: translateY(0);
  }
}`);

  // Upload Zone
  cssRules.push(`#upload-zone {
  border: 2px dashed var(--border);
  border-radius: var(--radius);
  padding: 20px;
  text-align: center;
  cursor: pointer;
  transition: all 0.2s;
  color: var(--text-muted);
  font-size: 12px;
}`);

  cssRules.push(`#upload-zone:hover, #upload-zone.drag-over {
  border-color: var(--accent);
  background: rgba(99, 179, 237, 0.05);
  color: var(--accent);
}`);

  // Toggle Switch
  cssRules.push(`.toggle-switch {
  position: relative;
  width: 36px;
  height: 20px;
  flex-shrink: 0;
}`);

  cssRules.push(`.toggle-switch input {
  display: none;
}`);

  cssRules.push(`.toggle-track {
  position: absolute;
  inset: 0;
  border-radius: 10px;
  background: var(--bg-deep);
  border: 1px solid var(--border);
  cursor: pointer;
  transition: background 0.2s;
}`);

  cssRules.push(`.toggle-thumb {
  position: absolute;
  top: 3px;
  left: 3px;
  width: 12px;
  height: 12px;
  border-radius: 50%;
  background: var(--text-dim);
  transition: transform 0.2s, background 0.2s;
}`);

  cssRules.push(`.toggle-switch input:checked + .toggle-track {
  background: rgba(99, 179, 237, 0.2);
  border-color: var(--accent);
}`);

  cssRules.push(`.toggle-switch input:checked ~ .toggle-thumb,
.toggle-switch input:checked + .toggle-track + .toggle-thumb {
  background: var(--accent);
  transform: translateX(16px);
}`);

  return cssRules.join('\n\n');
}

// Main execution
if (process.argv.length !== 3) {
  console.error('Usage: node script.js <output-file>');
  process.exit(1);
}

const outputFile = process.argv[2];

try {
  const cssContent = generateCSS();
  fs.writeFileSync(outputFile, cssContent, 'utf8');
  console.log(`CSS file generated successfully: ${outputFile}`);
} catch (error) {
  console.error('Error generating CSS file:', error.message);
  process.exit(1);
}
