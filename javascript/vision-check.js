#!/usr/bin/env node
// vision-check.html — portiert nach javascript
// Quelle: html, Projects@Vision-Check:Vision-Check/vision-check.html
// auch in: Onboarding@main:docs/reference-library/examples/vision-check.html
// Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

function generateHTML() {
  return `<!DOCTYPE html>
<html lang="de" data-theme="dark">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Vision-Check</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300..700&family=JetBrains+Mono:wght@400;600&display=swap" rel="stylesheet">
<script src="https://cdn.jsdelivr.net/npm/@tensorflow/tfjs@4.22.0/dist/tf.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/@tensorflow-models/coco-ssd@2.2.3/dist/coco-ssd.min.js"></script>
<style>
:root,[data-theme="dark"]{
  --color-bg:#0e1117;--color-surface:#161b22;--color-surface-2:#1c2230;
  --color-surface-offset:#1f2937;--color-border:#30363d;--color-divider:#21262d;
  --color-text:#e6edf3;--color-text-muted:#8b949e;--color-text-faint:#484f58;
  --color-primary:#3fb950;--color-primary-hover:#2ea043;--color-primary-highlight:#0d2c14;
  --color-accent:#58a6ff;--color-accent-hover:#388bfd;--color-warning:#d29922;
  --color-error:#f85149;--color-purple:#bc8cff;
  --font-body:'Inter',system-ui,sans-serif;
  --font-mono:'JetBrains Mono',monospace;
  --text-xs:clamp(0.75rem,0.7rem + 0.25vw,0.875rem);
  --text-sm:clamp(0.875rem,0.8rem + 0.35vw,1rem);
  --text-base:clamp(1rem,0.95rem + 0.25vw,1.125rem);
  --text-lg:clamp(1.125rem,1rem + 0.75vw,1.5rem);
  --text-xl:clamp(1.5rem,1.2rem + 1.25vw,2.25rem);
  --space-1:0.25rem;--space-2:0.5rem;--space-3:0.75rem;--space-4:1rem;
  --space-5:1.25rem;--space-6:1.5rem;--space-8:2rem;--space-10:2.5rem;
  --space-12:3rem;--space-16:4rem;
  --radius-sm:0.375rem;--radius-md:0.5rem;--radius-lg:0.75rem;--radius-xl:1rem;
  --radius-full:9999px;
  --transition:180ms cubic-bezier(0.16,1,0.3,1);
  --shadow-md:0 4px 12px rgba(0,0,0,0.4);--shadow-lg:0 12px 32px rgba(0,0,0,0.5);
}
[data-theme="light"]{
  --color-bg:#f0f6ff;--color-surface:#ffffff;--color-surface-2:#f6f8fa;
  --color-surface-offset:#eaeef2;--color-border:#d0d7de;--color-divider:#e1e4e8;
  --color-text:#1f2328;--color-text-muted:#57606a;--color-text-faint:#8c959f;
  --color-primary:#1a7f37;--color-primary-hover:#116329;--color-primary-highlight:#d4efdb;
  --color-accent:#0969da;--color-accent-hover:#0550ae;--color-warning:#9a6700;
  --color-error:#cf222e;--color-purple:#8250df;
  --shadow-md:0 4px 12px rgba(0,0,0,0.1);--shadow-lg:0 12px 32px rgba(0,0,0,0.15);
}
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
html{-webkit-font-smoothing:antialiased;scroll-behavior:smooth}
body{min-height:100dvh;font-family:var(--font-body);font-size:var(--text-base);
  color:var(--color-text);background:var(--color-bg);line-height:1.6}
img,canvas,video{display:block;max-width:100%;height:auto}
button{cursor:pointer;background:none;border:none;font:inherit;color:inherit;
  transition:color var(--transition),background var(--transition),border-color var(--transition),box-shadow var(--transition)}
a{color:var(--color-accent);text-decoration:none}
a:hover{text-decoration:underline}

/* ─── LAYOUT ─── */
.app{display:flex;flex-direction:column;min-height:100dvh}
header{background:var(--color-surface);border-bottom:1px solid var(--color-border);
  padding:var(--space-3) var(--space-6);display:flex;align-items:center;
  gap:var(--space-4);position:sticky;top:0;z-index:100;box-shadow:var(--shadow-md)}
.logo{display:flex;align-items:center;gap:var(--space-3);flex:1}
.logo-svg{width:36px;height:36px;flex-shrink:0}
.logo-title{font-size:var(--text-lg);font-weight:700;letter-spacing:-0.02em;line-height:1}
.logo-sub{font-size:var(--text-xs);color:var(--color-text-muted);font-family:var(--font-mono)}
.header-actions{display:flex;align-items:center;gap:var(--space-2)}
.btn-icon{width:36px;height:36px;border-radius:var(--radius-md);display:flex;
  align-items:center;justify-content:center;color:var(--color-text-muted);
  border:1px solid transparent}
.btn-icon:hover{background:var(--color-surface-offset);color:var(--color-text);
  border-color:var(--color-border)}
main{flex:1;padding:var(--space-6);max-width:1400px;margin:0 auto;width:100%}
.status-bar{background:var(--color-surface);border:1px solid var(--color-border);
  border-radius:var(--radius-lg);padding:var(--space-3) var(--space-5);
  margin-bottom:var(--space-6);display:flex;align-items:center;gap:var(--space-3);
  font-size:var(--text-sm);font-family:var(--font-mono)}
.status-dot{width:8px;height:8px;border-radius:50%;background:var(--color-warning);
  flex-shrink:0;animation:pulse 2s ease-in-out infinite}
.status-dot.ready{background:var(--color-primary);animation:none}
.status-dot.analyzing{background:var(--color-accent);animation:pulse 1s ease-in-out infinite}
.status-dot.error{background:var(--color-error);animation:none}
@keyframes pulse{0%,100%{opacity:1}50%{opacity:0.4}}
.grid{display:grid;grid-template-columns:1fr 380px;gap:var(--space-6);align-items:start}
@media(max-width:900px){.grid{grid-template-columns:1fr}}

/* ─── PANELS ─── */
.panel{background:var(--color-surface);border:1px solid var(--color-border);
  border-radius:var(--radius-xl);overflow:hidden}
.panel-header{padding:var(--space-4) var(--space-5);border-bottom:1px solid var(--color-divider);
  display:flex;align-items:center;justify-content:space-between}
.panel-title{font-size:var(--text-sm);font-weight:600;color:var(--color-text-muted);
  text-transform:uppercase;letter-spacing:0.08em;font-family:var(--font-mono)}
.panel-body{padding:var(--space-5)}

/* ─── CAMERA / CANVAS ─── */
.capture-area{position:relative;background:var(--color-bg);border-radius:var(--radius-lg);
  overflow:hidden;aspect-ratio:16/9;display:flex;align-items:center;justify-content:center}
#videoEl{position:absolute;inset:0;width:100%;height:100%;object-fit:cover}
#annotationCanvas{position:absolute;inset:0;width:100%;height:100%;pointer-events:none}
.capture-placeholder{display:flex;flex-direction:column;align-items:center;gap:var(--space-3);
  color:var(--color-text-faint);text-align:center;padding:var(--space-8)}
.capture-placeholder svg{opacity:0.4}
.capture-placeholder p{font-size:var(--text-sm);max-width:30ch}
.upload-drop-zone{border:2px dashed var(--color-border);border-radius:var(--radius-lg);
  padding:var(--space-8);text-align:center;cursor:pointer;transition:border-color var(--transition),background var(--transition)}
.upload-drop-zone:hover{border-color:var(--color-accent);background:rgba(88,166,255,0.05)}
.upload-drop-zone.dragover{border-color:var(--color-primary);background:rgba(63,185,80,0.05)}
#uploadedCanvas{border-radius:var(--radius-lg);width:100%;height:auto;display:none}
.upscale-controls{margin-top:var(--space-4);display:flex;align-items:center;gap:var(--space-3);flex-wrap:wrap}
.slider-wrap{flex:1;min-width:200px}
label.field-label{display:block;font-size:var(--text-xs);color:var(--color-text-muted);
  margin-bottom:var(--space-1);font-family:var(--font-mono)}
input[type=range]{width:100%;accent-color:var(--color-accent);cursor:pointer}
.badge{display:inline-flex;align-items:center;gap:4px;padding:2px 8px;
  border-radius:var(--radius-full);font-size:var(--text-xs);font-weight:600;
  font-family:var(--font-mono)}
.badge-green{background:var(--color-primary-highlight);color:var(--color-primary)}
.badge-blue{background:rgba(88,166,255,0.15);color:var(--color-accent)}
.badge-yellow{background:rgba(210,153,34,0.15);color:var(--color-warning)}
.badge-red{background:rgba(248,81,73,0.15);color:var(--color-error)}
.badge-purple{background:rgba(188,140,255,0.15);color:var(--color-purple)}

/* ─── BUTTONS ─── */
.btn{display:inline-flex;align-items:center;justify-content:center;gap:var(--space-2);
  padding:var(--space-2) var(--space-5);border-radius:var(--radius-md);
  font-size:var(--text-sm);font-weight:600;border:1px solid transparent;
  transition:background var(--transition),border-color var(--transition),box-shadow var(--transition)}
.btn:disabled{opacity:0.4;cursor:not-allowed}
.btn-primary{background:var(--color-primary);color:#fff;border-color:var(--color-primary)}
.btn-primary:hover:not(:disabled){background:var(--color-primary-hover)}
.btn-secondary{background:var(--color-surface-offset);color:var(--color-text);
  border-color:var(--color-border)}
.btn-secondary:hover:not(:disabled){border-color:var(--color-accent);color:var(--color-accent)}
.btn-danger{background:rgba(248,81,73,0.1);color:var(--color-error);border-color:var(--color-error)}
.btn-danger:hover:not(:disabled){background:rgba(248,81,73,0.2)}
.btn-group{display:flex;gap:var(--space-2);flex-wrap:wrap;margin-top:var(--space-4)}

/* ─── TABS ─── */
.tabs{display:flex;gap:2px;background:var(--color-surface-offset);padding:3px;
  border-radius:var(--radius-md);margin-bottom:var(--space-5)}
.tab{flex:1;padding:var(--space-2) var(--space-3);border-radius:calc(var(--radius-md) - 2px);
  font-size:var(--text-xs);font-weight:600;color:var(--color-text-muted);
  transition:background var(--transition),color var(--transition)}
.tab.active{background:var(--color-surface);color:var(--color-text);box-shadow:var(--shadow-md)}
.tab:hover:not(.active){color:var(--color-text)}
.tab-content{display:none}.tab-content.active{display:block}

/* ─── RESULTS ─── */
.result-list{display:flex;flex-direction:column;gap:var(--space-2)}
.result-item{background:var(--color-surface-2);border:1px solid var(--color-border);
  border-radius:var(--radius-md);padding:var(--space-3) var(--space-4);
  display:flex;align-items:flex-start;gap:var(--space-3)}
.result-item.highlight{border-color:var(--color-primary);background:var(--color-primary-highlight)}
.result-icon{font-size:1.4em;flex-shrink:0;line-height:1}
.result-info{flex:1;min-width:0}
.result-name{font-weight:600;font-size:var(--text-sm)}
.result-meta{font-size:var(--text-xs);color:var(--color-text-muted);font-family:var(--font-mono);margin-top:2px}
.result-conf{font-size:var(--text-xs);font-family:var(--font-mono);font-weight:700;color:var(--color-primary)}
.conf-bar-wrap{margin-top:var(--space-1);height:3px;background:var(--color-surface-offset);
  border-radius:var(--radius-full);overflow:hidden}
.conf-bar{height:100%;background:var(--color-primary);border-radius:var(--radius-full);
  transition:width 0.5s ease}
.empty-state{display:flex;flex-direction:column;align-items:center;gap:var(--space-3);
  padding:var(--space-10) var(--space-6);color:var(--color-text-faint);text-align:center}
.empty-state svg{opacity:0.3}
.empty-state p{font-size:var(--text-sm);max-width:28ch}

/* ─── AI PROMPT AREA ─── */
.ai-result{background:var(--color-surface-2);border:1px solid var(--color-border);
  border-radius:var(--radius-md);padding:var(--space-4);margin-top:var(--space-3);
  font-size:var(--text-sm);line-height:1.7;max-height:400px;overflow-y:auto;
  white-space:pre-wrap;font-family:var(--font-mono)}
.ai-result.loading{color:var(--color-text-muted)}
textarea.prompt-input{width:100%;background:var(--color-surface-offset);
  border:1px solid var(--color-border);border-radius:var(--radius-md);
  padding:var(--space-3);color:var(--color-text);font-size:var(--text-sm);
  font-family:var(--font-body);resize:vertical;min-height:80px;
  transition:border-color var(--transition)}
textarea.prompt-input:focus{outline:none;border-color:var(--color-accent)}
select.select-input{width:100%;background:var(--color-surface-offset);
  border:1px solid var(--color-border);border-radius:var(--radius-md);
  padding:var(--space-2) var(--space-3);color:var(--color-text);
  font-size:var(--text-sm);appearance:none;cursor:pointer;
  transition:border-color var(--transition)}
select.select-input:focus{outline:none;border-color:var(--color-accent)}
.form-row{margin-bottom:var(--space-4)}
.api-key-wrap{position:relative}
input.text-input{width:100%;background:var(--color-surface-offset);
  border:1px solid var(--color-border);border-radius:var(--radius-md);
  padding:var(--space-2) var(--space-3);color:var(--color-text);font-size:var(--text-sm);
  transition:border-color var(--transition)}
input.text-input:focus{outline:none;border-color:var(--color-accent)}

/* ─── PIXEL INSPECTOR ─── */
.pixel-inspector{display:flex;flex-direction:column;gap:var(--space-3)}
.magnifier-wrap{position:relative;cursor:crosshair}
#magnifierCanvas{width:100%;border-radius:var(--radius-md);border:1px solid var(--color-border);
  background:var(--color-bg)}
.pixel-info{background:var(--color-surface-2);border:1px solid var(--color-border);
  border-radius:var(--radius-md);padding:var(--space-3);font-family:var(--font-mono);
  font-size:var(--text-xs);display:grid;grid-template-columns:1fr 1fr;gap:var(--space-2)}
.pixel-info-item span:first-child{color:var(--color-text-muted)}
.pixel-info-item span:last-child{color:var(--color-text);font-weight:600}
.color-swatch{width:24px;height:24px;border-radius:var(--radius-sm);
  border:1px solid var(--color-border);display:inline-block;vertical-align:middle;margin-right:6px}

/* ─── PROGRESS ─── */
.progress-wrap{margin-top:var(--space-3)}
.progress-label{font-size:var(--text-xs);color:var(--color-text-muted);font-family:var(--font-mono);
  margin-bottom:var(--space-1);display:flex;justify-content:space-between}
.progress-bar-bg{height:4px;background:var(--color-surface-offset);border-radius:var(--radius-full);overflow:hidden}
.progress-bar-fill{height:100%;background:linear-gradient(90deg,var(--color-accent),var(--color-primary));
  border-radius:var(--radius-full);transition:width 0.3s ease;width:0%}
.shimmer{background:linear-gradient(90deg,var(--color-surface-offset) 25%,var(--color-surface-2) 50%,var(--color-surface-offset) 75%);
  background-size:200% 100%;animation:shimmer 1.5s ease-in-out infinite;border-radius:var(--radius-sm)}
@keyframes shimmer{0%{background-position:-200% 0}100%{background-position:200% 0}}
.skeleton-line{height:1em;margin-bottom:var(--space-2)}
.model-badge{display:inline-flex;align-items:center;gap:4px;padding:1px 6px;
  border-radius:3px;font-size:10px;font-weight:700;font-family:var(--font-mono);
  background:rgba(88,166,255,0.15);color:var(--color-accent);margin-left:6px}
.divider{height:1px;background:var(--color-divider);margin:var(--space-4) 0}
.help-text{font-size:var(--text-xs);color:var(--color-text-faint);margin-top:var(--space-1);line-height:1.5}
.chip-row{display:flex;flex-wrap:wrap;gap:var(--space-2);margin-top:var(--space-3)}
.chip{padding:3px 10px;background:var(--color-surface-offset);border:1px solid var(--color-border);
  border-radius:var(--radius-full);font-size:var(--text-xs);cursor:pointer;
  transition:background var(--transition),border-color var(--transition)}
.chip:hover{border-color:var(--color-accent);color:var(--color-accent)}
.chip.active{background:rgba(88,166,255,0.15);border-color:var(--color-accent);color:var(--color-accent)}
footer{padding:var(--space-4) var(--space-6);border-top:1px solid var(--color-border);
  display:flex;align-items:center;justify-content:space-between;font-size:var(--text-xs);
  color:var(--color-text-faint);font-family:var(--font-mono);background:var(--color-surface)}
</style>
</head>
<body>
<div class="app">
<!-- HEADER -->
<header>
  <div class="logo">
    <svg class="logo-svg" viewBox="0 0 36 36" fill="none" aria-label="Vision-Check Logo">
      <circle cx="18" cy="18" r="17" stroke="#3fb950" stroke-width="1.5"/>
      <circle cx="18" cy="18" r="9" stroke="#58a6ff" stroke-width="1.5"/>
      <circle cx="18" cy="18" r="3" fill="#3fb950"/>
      <line x1="1" y1="18" x2="9" y2="18" stroke="#3fb950" stroke-width="1.5"/>
      <line x1="27" y1="18" x2="35" y2="18" stroke="#3fb950" stroke-width="1.5"/>
      <line x1="18" y1="1" x2="18" y2="9" stroke="#58a6ff" stroke-width="1.5"/>
      <line x1="18" y1="27" x2="18" y2="35" stroke="#58a6ff" stroke-width="1.5"/>
      <line x1="5.05" y1="5.05" x2="10.6" y2="10.6" stroke="#bc8cff" stroke-width="1"/>
      <line x1="25.4" y1="25.4" x2="30.95" y2="30.95" stroke="#bc8cff" stroke-width="1"/>
    </svg>
    <div>
      <div class="logo-title">Vision-Check</div>
      <div class="logo-sub">Biodiversity Detection System</div>
    </div>
  </div>
  <div class="header-actions">
    <button class="btn-icon" id="themeToggle" aria-label="Theme wechseln">
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/>
      </svg>
    </button>
    <button class="btn-icon" id="settingsBtn" aria-label="Einstellungen">
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/>
      </svg>
    </button>
  </div>
</header>

<main>
<!-- STATUS BAR -->
<div class="status-bar">
  <div class="status-dot" id="statusDot"></div>
  <span id="statusText">Lade KI-Modelle (TF.js COCO-SSD)…</span>
  <div style="margin-left:auto;display:flex;gap:8px;flex-wrap:wrap">
    <span class="badge badge-blue" id="modelBadge">⏳ Initialisierung</span>
    <span class="badge badge-purple" id="apiBadge">🔑 API: nicht konfiguriert</span>
  </div>
</div>

<div class="grid">
<!-- LEFT COLUMN -->
<div style="display:flex;flex-direction:column;gap:var(--space-5)">

  <!-- TABS: Kamera / Upload -->
  <div class="panel">
    <div class="panel-header">
      <span class="panel-title">📷 Bildquelle</span>
      <div style="display:flex;gap:var(--space-2)">
        <span class="badge badge-green" id="resBadge">—</span>
      </div>
    </div>
    <div class="panel-body">
      <div class="tabs">
        <button class="tab active" data-tab="camera">📷 Kamera (Live)</button>
        <button class="tab" data-tab="upload">🗂️ Bild laden</button>
      </div>

      <!-- CAMERA TAB -->
      <div class="tab-content active" id="tab-camera">
        <div class="capture-area" id="cameraArea">
          <video id="videoEl" autoplay playsinline muted style="display:none"></video>
          <canvas id="annotationCanvas"></canvas>
          <div class="capture-placeholder" id="cameraPlaceholder">
            <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
              <path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z"/>
              <circle cx="12" cy="13" r="4"/>
            </svg>
            <p>Kamera starten für Live-Detektion mit bis zu 4K</p>
          </div>
        </div>
        <div class="btn-group">
          <button class="btn btn-primary" id="startCameraBtn">📷 Kamera starten</button>
          <button class="btn btn-secondary" id="stopCameraBtn" disabled>⏹ Stopp</button>
          <button class="btn btn-secondary" id="captureBtn" disabled>📸 Bild aufnehmen</button>
          <button class="btn btn-secondary" id="analyzeRealtimeBtn" disabled>🔍 Echtzeit-Analyse</button>
        </div>
        <div class="form-row" style="margin-top:var(--space-4)">
          <label class="field-label">Kamera-Gerät</label>
          <select class="select-input" id="cameraSelect"></select>
        </div>
        <div class="form-row">
          <label class="field-label">Auflösung</label>
          <select class="select-input" id="resolutionSelect">
            <option value="4096x2160">4K UHD (3840×2160)</option>
            <option value="2560x1440">2K QHD (2560×1440)</option>
            <option value="1920x1080" selected>Full HD (1920×1080)</option>
            <option value="1280x720">HD (1280×720)</option>
          </select>
        </div>
      </div>

      <!-- UPLOAD TAB -->
      <div class="tab-content" id="tab-upload">
        <div class="upload-drop-zone" id="dropZone">
          <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="margin:0 auto var(--space-3);opacity:0.5">
            <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>
            <polyline points="17 8 12 3 7 8"/><line x1="12" y1="3" x2="12" y2="15"/>
          </svg>
          <p style="font-size:var(--text-sm);color:var(--color-text-muted)">Bild hier ablegen oder klicken</p>
          <p style="font-size:var(--text-xs);color:var(--color-text-faint);margin-top:4px">JPG, PNG, WebP — keine Größenbegrenzung</p>
          <input type="file" id="fileInput" accept="image/*" style="display:none">
        </div>
        <canvas id="uploadedCanvas"></canvas>
      </div>
    </div>
  </div>

  <!-- UPSCALE / FILTER PANEL -->
  <div class="panel">
    <div class="panel-header">
      <span class="panel-title">🔬 Bildverbesserung & Interpolation</span>
    </div>
    <div class="panel-body">
      <div class="upscale-controls">
        <div class="slider-wrap">
          <label class="field-label">Kontrastverstärkung (CLAHE-Simulation) — <span id="contrastVal">1.0</span>×</label>
          <input type="range" id="contrastSlider" min="0.5" max="4" step="0.1" value="1">
        </div>
        <div class="slider-wrap">
          <label class="field-label">Schärfe-Filter — <span id="sharpnessVal">0</span></label>
          <input type="range" id="sharpnessSlider" min="0" max="5" step="1" value="0">
        </div>
      </div>
      <div class="upscale-controls" style="margin-top:var(--space-3)">
        <div class="slider-wrap">
          <label class="field-label">Helligkeit — <span id="brightnessVal">1.0</span></label>
          <input type="range" id="brightnessSlider" min="0.3" max="3" step="0.05" value="1">
        </div>
        <div class="slider-wrap">
          <label class="field-label">Sättigung — <span id="saturationVal">1.0</span></label>
          <input type="range" id="saturationSlider" min="0" max="4" step="0.1" value="1">
        </div>
      </div>
      <div class="btn-group">
        <button class="btn btn-secondary" id="applyFiltersBtn">✨ Filter anwenden</button>
        <button class="btn btn-secondary" id="resetFiltersBtn">↩ Zurücksetzen</button>
        <button class="btn btn-secondary" id="downloadBtn">💾 Bild speichern</button>
      </div>
      <div class="progress-wrap" id="upscaleProgress" style="display:none">
        <div class="progress-label"><span>Verarbeitung…</span><span id="progressPct">0%</span></div>
        <div class="progress-bar-bg"><div class="progress-bar-fill" id="progressFill"></div></div>
      </div>
    </div>
  </div>

  <!-- PIXEL INSPECTOR -->
  <div class="panel">
    <div class="panel-header">
      <span class="panel-title">🔭 Pixel-Inspektor</span>
    </div>
    <div class="panel-body">
      <div class="pixel-inspector">
        <div class="magnifier-wrap">
          <canvas id="magnifierCanvas" width="400" height="200"></canvas>
        </div>
        <div class="pixel-info" id="pixelInfo">
          <div class="pixel-info-item"><span>Position</span><span id="piPos">—</span></div>
          <div class="pixel-info-item"><span>Farbe</span><span id="piColor">—</span></div>
