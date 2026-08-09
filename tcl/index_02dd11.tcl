#!/usr/bin/env tclsh
# index.html — portiert nach tcl
# Quelle: html, Projects@Vision-Check:Vision-Check/app/index.html
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

# Tcl 8.6 script to generate index.html
# Usage: tclsh generate_html.tcl <output_file>

proc generate_html {} {
    set html {}

    append html {<!DOCTYPE html>} \n
    append html {<html lang="de">} \n
    append html {<head>} \n
    append html {  <meta charset="UTF-8">} \n
    append html {  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">} \n
    append html {  <meta name="theme-color" content="#0a0f1e">} \n
    append html {  <meta name="description" content="Lokale KI-gestützte Bildanalyse für Tiere & Insekten">} \n
    append html {  <meta name="apple-mobile-web-app-capable" content="yes">} \n
    append html {  <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">} \n
    append html \n
    append html {  <title>Vision-Check</title>} \n
    append html \n
    append html {  <link rel="manifest" href="manifest.json">} \n
    append html {  <link rel="icon" type="image/svg+xml" href="icons/icon.svg">} \n
    append html {  <link rel="apple-touch-icon" href="icons/icon-192.png">} \n
    append html \n
    append html {  <!-- Fonts -->} \n
    append html {  <link rel="preconnect" href="https://fonts.googleapis.com">} \n
    append html {  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@400;600&display=swap" rel="stylesheet">} \n
    append html \n
    append html {  <!-- TensorFlow.js + COCO-SSD -->} \n
    append html {  <script src="https://cdn.jsdelivr.net/npm/@tensorflow/tfjs@4.22.0/dist/tf.min.js" defer></script>} \n
    append html {  <script src="https://cdn.jsdelivr.net/npm/@tensorflow-models/coco-ssd@2.2.3/dist/coco-ssd.min.js" defer></script>} \n
    append html \n
    append html {  <!-- App CSS -->} \n
    append html {  <link rel="stylesheet" href="css/style.css">} \n
    append html {</head>} \n
    append html {<body>} \n
    append html \n
    append html {<!-- ══════════ HEADER ══════════ -->} \n
    append html {<div id="app">} \n
    append html {  <header id="app-header">} \n
    append html {    <div class="header-brand">} \n
    append html {      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">} \n
    append html {        <circle cx="12" cy="12" r="3"/>} \n
    append html {        <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2z" opacity=".3"/>} \n
    append html {        <path d="M12 8a4 4 0 0 1 4 4"/>} \n
    append html {        <path d="M8 12a4 4 0 0 1 4-4"/>} \n
    append html {        <path d="M12 16a4 4 0 0 1-4-4"/>} \n
    append html {        <path d="M16 12a4 4 0 0 1-4 4"/>} \n
    append html {      </svg>} \n
    append html {      <h1>Vision-Check</h1>} \n
    append html {    </div>} \n
    append html \n
    append html {    <div style="display:flex;align-items:center;gap:6px;font-size:11px;color:var(--text-dim)">} \n
    append html {      <!-- Layer-Indikatoren -->} \n
    append html {      <div class="layer-indicator" title="Aktive KI-Schichten">} \n
    append html {        <div class="layer-dot" data-layer="0" style="color:var(--layer-0);background:var(--layer-0)" title="iNaturalist"></div>} \n
    append html {        <div class="layer-dot" data-layer="1" style="color:var(--layer-1);background:var(--layer-1)" title="TF.js COCO-SSD"></div>} \n
    append html {        <div class="layer-dot" data-layer="2" style="color:var(--layer-2);background:var(--layer-2)" title="Canvas-Filter"></div>} \n
    append html {        <div class="layer-dot" data-layer="3" style="color:var(--layer-3-gpt);background:var(--layer-3-gpt)" title="Cloud APIs"></div>} \n
    append html {      </div>} \n
    append html {    </div>} \n
    append html \n
    append html {    <div class="header-controls">} \n
    append html {      <button class="btn btn-icon" id="btn-settings" title="Einstellungen / API-Keys">} \n
    append html {        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">} \n
    append html {          <circle cx="12" cy="12" r="3"/>} \n
    append html {          <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/>} \n
    append html {        </svg>} \n
    append html {      </button>} \n
    append html {    </div>} \n
    append html {  </header>} \n
    append html \n
    append html {  <!-- ══════════ BOARD ══════════ -->} \n
    append html {  <div id="board">} \n
    append html \n
    append html {    <!-- ── Kamera-Panel (links) ── -->} \n
    append html {    <div id="camera-panel">} \n
    append html {      <div class="panel-header">} \n
    append html {        <span class="panel-title">Kamera / Bild</span>} \n
    append html {        <div style="display:flex;align-items:center;gap:8px">} \n
    append html {          <span id="resolution-info" style="font-size:10px;color:var(--text-dim)">–</span>} \n
    append html {          <span id="cam-badge" class="badge badge-idle">Bereit</span>} \n
    append html {        </div>} \n
    append html {      </div>} \n
    append html \n
    append html {      <!-- Kamera-Viewport -->} \n
    append html {      <div id="camera-viewport">} \n
    append html {        <video id="video" autoplay playsinline muted></video>} \n
    append html {        <canvas id="canvas-overlay"></canvas>} \n
    append html {        <canvas id="snap-canvas" style="display:none"></canvas>} \n
    append html {        <canvas id="filtered-canvas" style="display:none"></canvas>} \n
    append html \n
    append html {        <!-- Pixel-Lupe -->} \n
    append html {        <div id="pixel-loupe">} \n
    append html {          <canvas id="loupe-canvas" width="160" height="160"></canvas>} \n
    append html {          <div id="loupe-info">–</div>} \n
    append html {        </div>} \n
    append html \n
    append html {        <!-- Start-Overlay wenn keine Kamera -->} \n
    append html {        <div id="start-overlay" style="position:absolute;inset:0;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:16px;background:rgba(10,15,30,0.8)">} \n
    append html {          <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="var(--accent)" stroke-width="1.5">} \n
    append html {            <path d="M23 7l-7 5 7 5V7z"/>} \n
    append html {            <rect x="1" y="5" width="15" height="14" rx="2" ry="2"/>} \n
    append html {          </svg>} \n
    append html {          <p style="color:var(--text-muted);font-size:13px;text-align:center">Kamera starten oder Bild hochladen</p>} \n
    append html {          <div style="display:flex;gap:8px">} \n
    append html {            <button class="btn btn-primary" id="btn-start-camera">} \n
    append html {              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">} \n
    append html {                <path d="M23 7l-7 5 7 5V7z"/>} \n
    append html {                <rect x="1" y="5" width="15" height="14" rx="2" ry="2"/>} \n
    append html {              </svg>} \n
    append html {              Kamera starten} \n
    append html {            </button>} \n
    append html {            <button class="btn" id="btn-upload">} \n
    append html {              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">} \n
    append html {                <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>} \n
    append html {                <polyline points="17 8 12 3 7 8"/>} \n
    append html {                <line x1="12" y1="3" x2="12" y2="15"/>} \n
    append html {              </svg>} \n
    append html {              Bild laden} \n
    append html {            </button>} \n
    append html {          </div>} \n
    append html {        </div>} \n
    append html {      </div>} \n
    append html \n
    append html {      <!-- Kamera-Steuerleiste -->} \n
    append html {      <div id="camera-controls">} \n
    append html {        <select id="camera-select" style="max-width:160px"></select>} \n
    append html {        <select id="resolution-select" style="max-width:140px"></select>} \n
    append html \n
    append html {        <div style="flex:1"></div>} \n
    append html \n
    append html {        <button class="btn btn-icon" id="btn-toggle-loupe" title="Pixel-Lupe ein/aus">} \n
    append html {          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">} \n
    append html {            <circle cx="11" cy="11" r="8"/>} \n
    append html {            <line x1="21" y1="21" x2="16.65" y2="16.65"/>} \n
    append html {            <line x1="11" y1="8" x2="11" y2="14"/>} \n
    append html {            <line x1="8" y1="11" x2="14" y2="11"/>} \n
    append html {          </svg>} \n
    append html {        </button>} \n
    append html \n
    append html {        <button class="btn btn-snap" id="btn-snap" disabled>} \n
    append html {          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">} \n
    append html {            <circle cx="12" cy="12" r="3"/>} \n
    append html {            <path d="M20 7h-3a2 2 0 0 1-2-2V4a2 2 0 0 0-2-2h-2a2 2 0 0 0-2 2v1a2 2 0 0 1-2 2H4a2 2 0 0 0-2 2v10a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2z"/>} \n
    append html {          </svg>} \n
    append html {          Snapshot} \n
    append html {        </button>} \n
    append html {      </div>} \n
    append html {    </div>} \n
    append html \n
    append html {    <!-- ── Rechtes Panel ── -->} \n
    append html {    <div id="right-panel">} \n
    append html \n
    append html {      <!-- Filter-Karte -->} \n
    append html {      <div class="card">} \n
    append html {        <div class="panel-header">} \n
    append html {          <span class="panel-title" style="color:var(--layer-2)">Schicht 2 — Filter</span>} \n
    append html {          <button class="btn btn-sm" id="btn-reset-filters">Reset</button>} \n
    append html {        </div>} \n
    append html {        <div class="card-body">} \n
    append html {          <div class="slider-row">} \n
    append html {            <span class="slider-label">Helligkeit</span>} \n
    append html {            <input type="range" id="slider-brightness" min="-80" max="80" value="0" step="1">} \n
    append html {            <span class="slider-value" id="val-brightness">0</span>} \n
    append html {          </div>} \n
    append html {          <div class="slider-row">} \n
    append html {            <span class="slider-label">Sättigung</span>} \n
    append html {            <input type="range" id="slider-saturation" min="0" max="3" value="1.2" step="0.1">} \n
    append html {            <span class="slider-value" id="val-saturation">1.2</span>} \n
    append html {          </div>} \n
    append html {          <div class="slider-row">} \n
    append html {            <span class="slider-label">CLAHE (Kontrast)</span>} \n
    append html {            <input type="range" id="slider-clahe" min="1" max="4" value="1.5" step="0.1">} \n
    append html {            <span class="slider-value" id="val-clahe">1.5x</span>} \n
    append html {          </div>} \n
    append html {          <div class="slider-row">} \n
    append html {            <span class="slider-label">Schärfe (Unsharp)</span>} \n
    append html {            <input type="range" id="slider-unsharp" min="0" max="5" value="2" step="1">} \n
    append html {            <span class="slider-value" id="val-unsharp">2</span>} \n
    append html {          </div>} \n
    append html {        </div>} \n
    append html {      </div>} \n
    append html \n
    append html {      <!-- Snapshot-Vorschau -->} \n
    append html {      <div class="card" id="snapshot-area" style="display:none">} \n
    append html {        <div class="panel-header">} \n
    append html {          <span class="panel-title">Snapshot (gefiltert)</span>} \n
    append html {          <div style="display:flex;gap:4px">} \n
    append html {            <button class="btn btn-sm" id="btn-upload-replace">} \n
    append html {              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">} \n
    append html {                <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>} \n
    append html {                <polyline points="17 8 12 3 7 8"/>} \n
    append html {                <line x1="12" y1="3" x2="12" y2="15"/>} \n
    append html {              </svg>} \n
    append html {              Ersetzen} \n
    append html {            </button>} \n
    append html {          </div>} \n
    append html {        </div>} \n
    append html {        <div class="card-body" style="padding:0">} \n
    append html {          <img id="snapshot-preview" style="width:100%;display:block;border-radius:0 0 14px 14px" alt="Snapshot">} \n
    append html {        </div>} \n
    append html {      </div>} \n
    append html \n
    append html {      <!-- Pixel-Inspektor -->} \n
    append html {      <div class="card">} \n
    append html {        <div class="panel-header">} \n
    append html {          <span class="panel-title">Pixel-Inspektor</span>} \n
    append html {          <span style="font-size:10px;color:var(--text-dim)">8× Zoom-Lupe</span>} \n
    append html {        </div>} \n
    append html {        <div class="card-body">} \n
    append html {          <div id="pixel-info">} \n
    append html {            <div class="pixel-swatch" id="pixel-swatch" style="background:#333"></div>} \n
    append html {            <div class="pixel-values">} \n
    append html {              <span id="pixel-values-text" style="color:var(--text-dim);font-size:11px">Maus über Bild bewegen</span>} \n
    append html {            </div>} \n
    append html {          </div>} \n
    append html {          <p style="font-size:10px;color:var(--text-dim);margin-top:8px">} \n
    append html {            Lupe-Icon aktivieren → Lupe über Bild fahren} \n
    append html {          </p>} \n
    append html {        </div>} \n
    append html {      </div>} \n
    append html \n
    append html {      <!-- Analyse-Panel -->} \n
    append html {      <div class="card" style="flex:1">} \n
    append html {        <div class="panel-header">} \n
    append html {          <span class="panel-title">Analyse-Ergebnisse</span>} \n
    append html {          <div id="analyze-spinner" class="spinner" style="display:none"></div>} \n
    append html {        </div>} \n
    append html \n
    append html {        <!-- Tabs -->} \n
    append html {        <div class="tab-bar">} \n
    append html {          <button class="tab active" data-tab="tab-inat">} \n
    append html {            <span style="color:var(--layer-0)">● </span>iNaturalist} \n
    append html {          </button>} \n
    append html {          <button class="tab" data-tab="tab-layer1">} \n
    append html {            <span style="color:var(--layer-1)">● </span>Lokal} \n
    append html {          </button>} \n
    append html {          <button class="tab" data-tab="tab-cloud">} \n
    append html {            <span style="color:var(--layer-3-gpt)">● </span>Cloud} \n
    append html {          </button>} \n
    append html {        </div>} \n
    append html \n
    append html {        <!-- Tab-Inhalte -->} \n
    append html {        <div id="tab-content-inat" class="tab-content active" style="padding:12px">} \n
    append html {          <div id="result-layer0">} \n
    append html {            <p style="color:var(--text-dim);font-size:12px">iNaturalist — Artenbestimmung nach Snapshot + Analyse</p>} \n
    append html {          </div>} \n
    append html {        </div>} \n
    append html \n
    append html {        <div id="tab-content-layer1" class="tab-content" style="padding:12px">} \n
    append html {          <div style="margin-bottom:8px">} \n
    append html {            <span class="badge" style="color:var(--layer-1);background:rgba(79,209,197,0.1)">TF.js COCO-SSD — Live-Erkennung</span>} \n
    append html {          </div>} \n
    append html {          <div id="result-layer1">} \n
    append html {            <p style="color:var(--text-dim);font-size:12px">Echtzeit-Detektion läuft nach Kamera-Start</p>} \n
    append html {          </div>} \n
    append html {        </div>} \n
    append html \n
    append html {        <div id="tab-content-cloud" class="tab-content" style="padding:12px">} \n
    append html {          <div id="results-container">} \n
    append html {            <div id="result-layer3">} \n
    append html {              <p style="color:var(--text-dim);font-size:12px">Cloud-APIs (GPT-4o / Gemini 2.5 / Claude) nach Snapshot + Analyse-Button</p>} \n
    append html {            </div>} \n
    append html {          </div>} \n
    append html {        </div>} \n
    append html \n
    append html {        <!-- Analyse-Button -->} \n
    append html {        <div style="padding:12px;border-top:1px solid var(--border)">} \n
    append html {          <button class="btn btn-primary" id="btn-analyze" disabled style="width:100%;justify-content:center;padding:10px">} \n
    append html {            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">} \n
    append html {              <circle cx="11" cy="11" r="8"/>} \n
    append html {              <line x1="21" y1="21" x2="16.65" y2="16.65"/>} \n
    append html {            </svg>} \n
    append html {            Alle APIs analysieren} \n
    append html {          </button>} \n
    append html {        </div>} \n
    append html {      </div>} \n
    append html \n
    append html {    </div><!-- /right-panel -->} \n
    append html \n
    append html {    <!-- ── Status-Leiste ── -->} \n
    append html {    <div id="status-bar">} \n
    append html {      <div id="status-dot" class="status-dot"></div>} \n
    append html {      <span id="status-text">Initialisiere...</span>} \n
    append html {    </div>} \n
    append html \n
    append html {  </div><!-- /board -->} \n
    append html {</div><!-- /app -->} \n
    append html \n
    append html {<!-- ══════════ SETTINGS MODAL (EnvManager) ══════════ -->} \n
    append html {<div id="settings-modal">} \n
    append html {  <div class="modal-box" style="width:560px">} \n
    append html {    <div class="modal-title">⚙ Einstellungen &amp; API-Keys</div>} \n
    append html \n
    append html {    <!-- Sicherheitshinweis -->} \n
    append html {    <div style="background:rgba(251,211,141,0.1);border:1px solid rgba(251,211,141,0.3);border-radius:8px;padding:10px 12px;margin-bottom:20px;font-size:11px;color:var(--accent-warn)">} \n
    append html {      🔒 Alle API-Keys bleiben ausschließlich lokal in deinem Browser (localStorage). Kein Backend, keine Weiterleitung.} \n
    append html {    </div>} \n
    append html \n
    append html {    <!-- OpenAI -->} \n
    append html {    <div class="settings-section">} \n
    append html {      <div class="settings-section-title" style="color:var(--layer-3-gpt)">OpenAI — GPT-4o Vision</div>} \n
    append html {      <label class="settings-label">API-Key (sk-proj-…)</label>} \n
    append html {      <input class="settings-input" type="password" id="openai-key" placeholder="sk-proj-...">} \n
    append html {      <p class="settings-hint">Aus <a href="https://platform.openai.com/api-keys" target="_blank" style="color:var(--accent)">platform.openai.com/api-keys</a> — kein CORS-Problem, direkt nutzbar.</p>} \n
    append html {    </div>} \n
    append html \n
    append html {    <!-- Gemini -->} \n
    append html {    <div class="settings-section">} \n
    append html {      <div class="settings-section-title" style="color:var(--layer-3-gemini)">Google Gemini — 2.5 Pro Vision</div>} \n
    append html {      <label class="settings-label">API-Key (AIza…)</label>} \n
    append html {      <input class="settings-input" type="password" id="gemini-key" placeholder="AIzaSy...">} \n
    append html {      <p class="settings-hint">Aus <a href="https://aistudio.google.com/app/apikey" target="_blank" style="color:var(--accent)">Google AI Studio</a> — kein CORS-Problem.</p>} \n
    append html {    </div>} \n
    append html \n
    append html {    <!-- Claude -->} \n
    append html {    <div class="settings-section">} \n
    append html {      <div class="settings-section-title" style="color:var(--layer-3-claude)">Anthropic Claude — Opus 4.8 / Fable 5</div>} \n
    append html {      <label class="settings-label">API-Key (sk-ant-…)</label>} \n
    append html {      <input class="settings-input" type="password" id="claude-key" placeholder="sk-ant-...">} \n
    append html {      <p class="settings-hint">Aus <a href="https://console.anthropic.com" target="_blank" style="color:var(--accent)">console.anthropic.com</a></p>} \n
    append html \n
    append html {      <label class="settings-label" style="margin-top:12px">Modell</label>} \n
    append html {      <select class="settings-input" id="claude-model" style="padding:8px 12px">} \n
    append html {        <option value="claude-opus-4-8">claude-opus-4-8 (High-Res Vision)</option>} \n
    append html {        <option value="claude-fable-5">claude-fable-5 (High-Res Vision)</option>} \n
    append html {      </select>} \n
    append html \n
    append html {      <label class="settings-label" style="margin-top:12px">CORS-Proxy URL <span style="color:var(--accent-warn)">(erforderlich für Claude)</span></label>} \n
    append html {      <input class="settings-input" type="url" id="claude-proxy" placeholder="https://your-worker.workers.dev">} \n
    append html {      <p class="settings-hint">} \n
    append html {        Cloudflare Worker als CORS-Pass-Through nötig (Browser blockiert direkte Anthropic-Calls).<br>} \n
    append html {        Anleitung: <a href="https://github.com/seveibar/cloudflare-cors-proxy" target="_blank" style="color:var(--accent)">cloudflare-cors-proxy</a> — kostenlos, 100k Req/Tag Free-Tier.} \n
    append html {      </p>} \n
    append html {    </div>} \n
    append html \n
    append html {    <!-- Feature-Flags -->} \n
    append html {    <div class="settings-section">} \n
    append html {      <div class="settings-section-title">Funktionen</div>} \n
    append html \n
    append html {      <div style="display:flex;align-items
