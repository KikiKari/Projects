// ═══════════════════════════════════════════
// Vision-Check — Haupt-App (Analyse-Board)
// Orchestriert: Kamera · Filter · TF.js · Cloud APIs
// ═══════════════════════════════════════════

'use strict';

// ── DOM-Referenzen ───────────────────────────────────
const $ = id => document.getElementById(id);

const video       = $('video');
const overlayCanvas = $('canvas-overlay');
const snapCanvas  = $('snap-canvas');
const filteredCanvas = $('filtered-canvas');
const loupeCanvas = $('loupe-canvas');
const loupeInfo   = $('loupe-info');
const pixelLoupe  = $('pixel-loupe');

const btnStartCamera  = $('btn-start-camera');
const btnSnap         = $('btn-snap');
const btnAnalyze      = $('btn-analyze');
const btnSettings     = $('btn-settings');
const btnToggleLoupe  = $('btn-toggle-loupe');
const btnResetFilters = $('btn-reset-filters');
const btnUpload       = $('btn-upload');
const fileInput       = $('file-input');

const cameraSelect    = $('camera-select');
const resolutionSelect = $('resolution-select');

const statusDot  = $('status-dot');
const statusText = $('status-text');
const camBadge   = $('cam-badge');
const resolutionInfo = $('resolution-info');

const sliderBrightness = $('slider-brightness');
const sliderSaturation = $('slider-saturation');
const sliderClahe      = $('slider-clahe');
const sliderUnsharp    = $('slider-unsharp');
const valBrightness    = $('val-brightness');
const valSaturation    = $('val-saturation');
const valClahe         = $('val-clahe');
const valUnsharp       = $('val-unsharp');

const settingsModal = $('settings-modal');
const snapshotArea  = $('snapshot-area');
const snapshotPreview = $('snapshot-preview');

const resultsContainer = $('results-container');
const layerIndicators  = document.querySelectorAll('.layer-dot');
const analyzeTabBtns   = document.querySelectorAll('.tab');
const analyzeTabContents = document.querySelectorAll('.tab-content');

// ── State ────────────────────────────────────────────
let appState = {
  cameraActive: false,
  snapshotDataURL: null,
  loupeActive: false,
  isAnalyzing: false,
  tfModel: null,
  tfBackend: null,
  filterParams: null,
  settings: null,
  liveDetectionRunning: false,
  rafId: null
};

// ── Init ─────────────────────────────────────────────
async function init() {
  setStatus('Initialisiere...', 'loading');

  // Einstellungen laden
  appState.settings = Settings.load();
  applyFilterParamsFromSettings();

  // Service Worker
  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register('/sw.js').catch(e => console.warn('SW:', e));
  }

  // Dropdowns befüllen
  await Camera.populateDeviceDropdown(cameraSelect);
  Camera.populateResolutionDropdown(resolutionSelect);

  // Slider-Werte aus Settings setzen
  syncSlidersFromParams();

  // Settings-Modal binden
  Settings.bindModal(settingsModal, newCfg => {
    appState.settings = newCfg;
  });

  // Event-Listener
  bindEvents();

  // TensorFlow.js laden (non-blocking)
  loadTFModel();

  setStatus('Bereit — Kamera starten', '');
}

// ── TensorFlow.js + COCO-SSD ─────────────────────────
async function loadTFModel() {
  setLayerIndicator(1, 'loading');
  setStatus('Lade TensorFlow.js...', 'loading');

  try {
    // Backend-Auswahl: WebGPU > WebGL > CPU
    const backendFn = async () => {
      if (navigator.gpu) {
        try {
          await tf.setBackend('webgpu');
          return 'webgpu';
        } catch {}
      }
      if (await tf.setBackend('webgl')) return 'webgl';
      await tf.setBackend('cpu');
      return 'cpu';
    };

    appState.tfBackend = await backendFn();
    console.log('TF Backend:', appState.tfBackend);

    appState.tfModel = await cocoSsd.load({ base: 'mobilenet_v2' });
    setLayerIndicator(1, 'active');
    setStatus(`TF.js (${appState.tfBackend}) bereit`, 'ok');

    // Kamera automatisch starten nach Modell-Load
    if (appState.cameraActive) startLiveDetection();

  } catch (err) {
    setLayerIndicator(1, 'err');
    console.error('TF.js Fehler:', err);
    setStatus('TF.js nicht verfügbar (Cloud-APIs weiter nutzbar)', 'warn');
  }
}

// ── Kamera ───────────────────────────────────────────
async function startCamera() {
  setStatus('Starte Kamera...', 'loading');
  camBadge.textContent = 'Verbinde';
  camBadge.className = 'badge badge-loading';

  const result = await Camera.start(video, cameraSelect.value, resolutionSelect.value);

  if (result.ok) {
    appState.cameraActive = true;
    camBadge.textContent = 'Live';
    camBadge.className = 'badge badge-live';
    resolutionInfo.textContent = `${result.actualWidth}×${result.actualHeight}`;
    setStatus(`Kamera aktiv — ${result.deviceLabel || 'Gerät'} (${result.actualWidth}×${result.actualHeight})`, 'ok');
    btnSnap.disabled = false;

    // Live-Detektion
    if (appState.tfModel) startLiveDetection();

  } else {
    setStatus(`Kamera-Fehler: ${result.error}`, 'err');
    camBadge.textContent = 'Fehler';
    camBadge.className = 'badge badge-idle';
  }
}

// ── Live-Detektion (requestAnimationFrame) ────────────
function startLiveDetection() {
  if (appState.liveDetectionRunning) return;
  appState.liveDetectionRunning = true;

  let frameCount = 0;
  const DETECT_EVERY = 10; // Jedes 10. Frame (≈6fps Detektion bei 60fps rAF)

  async function loop() {
    if (!appState.cameraActive || !appState.tfModel) {
      appState.liveDetectionRunning = false;
      return;
    }

    if (++frameCount % DETECT_EVERY === 0 && video.readyState === 4) {
      try {
        const predictions = await appState.tfModel.detect(video);
        Camera.drawDetections(overlayCanvas, video, predictions);

        if (predictions.length > 0) {
          renderLocalDetections(predictions);
        }
      } catch {}
    }

    appState.rafId = requestAnimationFrame(loop);
  }

  loop();
}

function stopLiveDetection() {
  appState.liveDetectionRunning = false;
  if (appState.rafId) cancelAnimationFrame(appState.rafId);
}

// ── Snapshot ─────────────────────────────────────────
function takeSnapshot() {
  if (!appState.cameraActive) {
    Settings.showToast('Bitte zuerst Kamera starten');
    return;
  }

  const frame = Camera.captureFrame(video, snapCanvas, 2048);
  if (!frame) { Settings.showToast('Kein Bild verfügbar'); return; }

  // Filter anwenden
  applyFiltersToSnapshot(snapCanvas);

  appState.snapshotDataURL = filteredCanvas.toDataURL('image/jpeg', 0.92);

  // Vorschau
  snapshotPreview.src = appState.snapshotDataURL;
  snapshotArea.style.display = 'block';
  snapshotArea.classList.add('fade-in');

  btnAnalyze.disabled = false;
  setStatus('Snapshot gespeichert — Filter angewendet', 'ok');

  // Auto-Analyse?
  if (appState.settings?.autoAnalyze) {
    runCloudAnalysis();
  }
}

// ── Filter auf Snapshot anwenden ─────────────────────
function applyFiltersToSnapshot(srcCanvas) {
  const params = getFilterParams();
  filteredCanvas.width = srcCanvas.width;
  filteredCanvas.height = srcCanvas.height;
  Filters.applyPipeline(srcCanvas, filteredCanvas, params);
}

function getFilterParams() {
  return {
    brightness: parseFloat(sliderBrightness?.value || 0),
    saturation: parseFloat(sliderSaturation?.value || 1.2),
    clahe:      parseFloat(sliderClahe?.value || 1.5),
    unsharp:    parseInt(sliderUnsharp?.value || 2)
  };
}

// ── Cloud-Analyse ─────────────────────────────────────
async function runCloudAnalysis() {
  if (!appState.snapshotDataURL) {
    Settings.showToast('Erst Snapshot aufnehmen');
    return;
  }
  if (appState.isAnalyzing) return;

  appState.isAnalyzing = true;
  btnAnalyze.disabled = true;
  setStatus('Analysiere...', 'loading');
  setLayerIndicator(3, 'loading');

  clearResults();
  showAnalysisSpinner(true);

  const settings = appState.settings;
  const hasAnyKey = settings.openaiKey || settings.geminiKey || settings.claudeKey;

  if (!hasAnyKey && settings.inat === false) {
    showNoKeyHint();
    appState.isAnalyzing = false;
    return;
  }

  await CloudAPI.analyzeAll(appState.snapshotDataURL, settings, (source, result) => {
    // Progress: Ergebnis sofort zeigen wenn es ankommt
    renderCloudResult(source, result);
  });

  appState.isAnalyzing = false;
  btnAnalyze.disabled = false;
  showAnalysisSpinner(false);
  setLayerIndicator(3, 'active');
  setStatus('Analyse abgeschlossen', 'ok');
}

// ── Ergebnisse rendern ───────────────────────────────
function clearResults() {
  const container = $('result-layer0');
  const containerCloud = $('result-layer3');
  if (container) container.innerHTML = '';
  if (containerCloud) containerCloud.innerHTML = '';
}

function renderLocalDetections(predictions) {
  const container = $('result-layer1');
  if (!container) return;

  container.innerHTML = '';
  if (predictions.length === 0) {
    container.innerHTML = '<p style="color:var(--text-dim);font-size:12px;">Keine Objekte erkannt</p>';
    return;
  }

  predictions.slice(0, 8).forEach(pred => {
    const el = document.createElement('div');
    el.className = 'detection-item fade-in';
    const pct = Math.round(pred.score * 100);
    el.innerHTML = `
      <span class="detection-class">${pred.class}</span>
      <div class="confidence-bar">
        <div class="confidence-track">
          <div class="confidence-fill" style="width:${pct}%"></div>
        </div>
        <span class="confidence-pct">${pct}%</span>
      </div>
    `;
    container.appendChild(el);
  });
}

function renderCloudResult(source, result) {
  // Tab auswählen basierend auf Quelle
  let containerId;
  if (source === 'iNaturalist') containerId = 'result-layer0';
  else containerId = 'result-layer3';

  const container = $(containerId);
  if (!container) return;

  if (!result.ok) {
    const el = document.createElement('div');
    el.className = 'result-block fade-in';
    el.innerHTML = `
      <div class="result-header">
        <span class="layer-tag" style="color:var(--accent-err)">${result.source || source}</span>
        <span class="badge" style="color:var(--accent-err);background:rgba(252,129,129,0.1)">Fehler</span>
      </div>
      <p class="result-text" style="color:var(--accent-err)">${result.error}</p>
    `;
    container.appendChild(el);
    return;
  }

  if (source === 'iNaturalist' && result.results) {
    // iNaturalist Cards
    const wrapper = document.createElement('div');
    wrapper.className = 'fade-in';
    result.results.forEach(r => {
      const card = document.createElement('div');
      card.className = 'species-card';
      card.innerHTML = `
        ${r.photoUrl ? `<img class="species-img" src="${r.photoUrl}" alt="${r.name}" loading="lazy">` : '<div class="species-img"></div>'}
        <div class="species-info">
          <div class="species-name">${r.name}</div>
          <div class="species-latin">${r.scientificName || ''}</div>
          <div class="species-score">Score: ${r.score ? (r.score * 100).toFixed(1) + '%' : '–'} · ${r.rank || ''}</div>
        </div>
      `;
      wrapper.appendChild(card);
    });
    container.appendChild(wrapper);

    // Tab aktivieren
    switchTab('tab-inat');
    return;
  }

  // Text-Ergebnis (OpenAI / Gemini / Claude)
  const colorMap = {
    'OpenAI GPT-4o': 'var(--layer-3-gpt)',
    'Gemini 2.5 Pro': 'var(--layer-3-gemini)',
    'Claude claude-opus-4-8': 'var(--layer-3-claude)',
    'Claude claude-fable-5': 'var(--layer-3-claude)'
  };
  const color = colorMap[result.source] || 'var(--accent)';

  const el = document.createElement('div');
  el.className = 'result-block fade-in';
  el.innerHTML = `
    <div class="result-header">
      <span class="layer-tag" style="color:${color}">
        <span style="width:8px;height:8px;border-radius:50%;background:${color};display:inline-block"></span>
        ${result.source}
      </span>
      ${result.tokens ? `<span class="badge" style="color:var(--text-dim);background:transparent;font-size:10px">~${result.tokens.output || '?'} Tokens</span>` : ''}
    </div>
    <div class="result-text">${markdownToHTML(result.text)}</div>
  `;
  container.appendChild(el);
  switchTab('tab-cloud');
}

function showNoKeyHint() {
  const container = $('result-layer3');
  if (!container) return;
  container.innerHTML = `
    <div class="result-block fade-in">
      <p class="result-text" style="color:var(--accent-warn)">
        Keine API-Keys konfiguriert.<br>
        Öffne die Einstellungen (⚙) und trage OpenAI, Gemini oder Claude-Key ein.
      </p>
    </div>
  `;
  showAnalysisSpinner(false);
  btnAnalyze.disabled = false;
  appState.isAnalyzing = false;
}

// ── Einfacher Markdown-zu-HTML Konverter ─────────────
function markdownToHTML(text) {
  if (!text) return '';
  return text
    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
    .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
    .replace(/\*(.+?)\*/g, '<em>$1</em>')
    .replace(/^### (.+)$/gm, '<h4 style="color:var(--accent);margin:8px 0 4px">$1</h4>')
    .replace(/^## (.+)$/gm, '<h3 style="color:var(--accent);margin:10px 0 4px">$1</h3>')
    .replace(/^# (.+)$/gm, '<h3 style="color:var(--accent);margin:10px 0 4px">$1</h3>')
    .replace(/^\d+\. (.+)$/gm, '<div style="margin:2px 0;padding-left:12px">$1</div>')
    .replace(/^[-•] (.+)$/gm, '<div style="margin:2px 0;padding-left:12px">• $1</div>')
    .replace(/\n\n/g, '<br><br>')
    .replace(/\n/g, '<br>');
}

// ── Tab-Steuerung ─────────────────────────────────────
function switchTab(tabId) {
  analyzeTabBtns.forEach(btn => {
    btn.classList.toggle('active', btn.dataset.tab === tabId);
  });
  analyzeTabContents.forEach(content => {
    content.classList.toggle('active', content.id === tabId.replace('tab-', 'tab-content-'));
  });
}

// ── Pixel-Inspektor & Lupe ────────────────────────────
function bindLoupeEvents() {
  const viewport = $('camera-viewport');
  if (!viewport) return;

  viewport.addEventListener('mousemove', e => {
    if (!appState.loupeActive) return;
    if (!appState.snapshotDataURL && !appState.cameraActive) return;

    const rect = viewport.getBoundingClientRect();
    const mx = e.clientX - rect.left;
    const my = e.clientY - rect.top;

    // Koordinaten auf Original-Video skalieren
    const scaleX = video.videoWidth / rect.width;
    const scaleY = video.videoHeight / rect.height;
    const cx = mx * scaleX, cy = my * scaleY;

    // Lupe rendern (aus Snapshot oder Video)
    const src = filteredCanvas.width > 0 ? filteredCanvas : snapCanvas;
    if (src.width > 0) {
      loupeCanvas.width = 160;
      loupeCanvas.height = 160;
      Filters.renderLoupe(src, loupeCanvas, cx, cy, appState.settings?.loupeZoom || 8);

      // Pixel-Info
      const px = Filters.getPixelAt(src, cx, cy);
      loupeInfo.textContent = `${px.hex} · ${px.brightness}L`;

      // Pixel-Swatch
      const swatch = $('pixel-swatch');
      const values = $('pixel-values-text');
      if (swatch) swatch.style.background = px.hex;
      if (values) values.innerHTML = `
        <span>${px.hex}</span>
        <span>R:${px.r} G:${px.g} B:${px.b}</span>
        <span>Helligkeit: ${px.brightness}</span>
      `;
    }

    // Lupe positionieren
    pixelLoupe.style.display = 'block';
  });

  viewport.addEventListener('mouseleave', () => {
    if (!appState.loupeActive) return;
    pixelLoupe.style.display = 'none';
  });
}

// ── Status-Helfer ─────────────────────────────────────
function setStatus(msg, state) {
  if (statusText) statusText.textContent = msg;
  if (statusDot) {
    statusDot.className = 'status-dot';
    if (state === 'ok') statusDot.classList.add('ok');
    else if (state === 'warn') statusDot.classList.add('warn');
    else if (state === 'err' || state === 'error') statusDot.classList.add('err');
  }
}

function setLayerIndicator(layer, state) {
  const dot = document.querySelector(`.layer-dot[data-layer="${layer}"]`);
  if (!dot) return;
  dot.classList.toggle('active', state === 'active' || state === 'loading');
}

function showAnalysisSpinner(show) {
  const spinner = $('analyze-spinner');
  if (spinner) spinner.style.display = show ? 'block' : 'none';
}

// ── Filter-Slider-Sync ────────────────────────────────
function syncSlidersFromParams() {
  const cfg = appState.settings || Settings.DEFAULTS;
  if (sliderBrightness) { sliderBrightness.value = cfg.brightness; valBrightness.textContent = cfg.brightness; }
  if (sliderSaturation) { sliderSaturation.value = cfg.saturation; valSaturation.textContent = cfg.saturation; }
  if (sliderClahe)      { sliderClahe.value = cfg.clahe;           valClahe.textContent = cfg.clahe + 'x'; }
  if (sliderUnsharp)    { sliderUnsharp.value = cfg.unsharp;       valUnsharp.textContent = cfg.unsharp; }
}

function applyFilterParamsFromSettings() {
  // Nichts zu tun — Params werden direkt aus Slidern gelesen
}

function bindSliderEvents() {
  const pairs = [
    [sliderBrightness, valBrightness, v => v, ''],
    [sliderSaturation, valSaturation, v => v, ''],
    [sliderClahe,      valClahe,      v => v, 'x'],
    [sliderUnsharp,    valUnsharp,    v => v, '']
  ];
  pairs.forEach(([slider, label, fn, suffix]) => {
    if (!slider) return;
    slider.addEventListener('input', () => {
      if (label) label.textContent = fn(slider.value) + suffix;
      // Vorschau live aktualisieren wenn Snapshot vorhanden
      if (appState.snapshotDataURL && snapCanvas.width > 0) {
        applyFiltersToSnapshot(snapCanvas);
        snapshotPreview.src = filteredCanvas.toDataURL('image/jpeg', 0.88);
      }
    });
  });
}

// ── Upload-Handling ───────────────────────────────────
function handleUpload(file) {
  if (!file || !file.type.startsWith('image/')) {
    Settings.showToast('Bitte ein Bild hochladen');
    return;
  }
  const reader = new FileReader();
  reader.onload = e => {
    const img = new Image();
    img.onload = () => {
      snapCanvas.width = img.width;
      snapCanvas.height = img.height;
      snapCanvas.getContext('2d').drawImage(img, 0, 0);
      applyFiltersToSnapshot(snapCanvas);
      appState.snapshotDataURL = filteredCanvas.toDataURL('image/jpeg', 0.92);
      snapshotPreview.src = appState.snapshotDataURL;
      snapshotArea.style.display = 'block';
      btnAnalyze.disabled = false;
      setStatus(`Bild geladen: ${img.width}×${img.height}px`, 'ok');
      if (appState.settings?.autoAnalyze) runCloudAnalysis();
    };
    img.src = e.target.result;
  };
  reader.readAsDataURL(file);
}

// ── Event-Listener binden ─────────────────────────────
function bindEvents() {
  // Kamera
  btnStartCamera?.addEventListener('click', startCamera);

  cameraSelect?.addEventListener('change', () => {
    if (appState.cameraActive) startCamera();
  });

  resolutionSelect?.addEventListener('change', () => {
    if (appState.cameraActive) startCamera();
  });

  // Snapshot
  btnSnap?.addEventListener('click', takeSnapshot);

  // Analyse
  btnAnalyze?.addEventListener('click', runCloudAnalysis);

  // Einstellungen
  btnSettings?.addEventListener('click', () => Settings.openModal(settingsModal));

  // Lupe Toggle
  btnToggleLoupe?.addEventListener('click', () => {
    appState.loupeActive = !appState.loupeActive;
    btnToggleLoupe.classList.toggle('btn-primary', appState.loupeActive);
    if (!appState.loupeActive) pixelLoupe.style.display = 'none';
  });

  // Filter Reset
  btnResetFilters?.addEventListener('click', () => {
    const d = Settings.DEFAULTS;
    if (sliderBrightness) sliderBrightness.value = d.brightness;
    if (sliderSaturation) sliderSaturation.value = d.saturation;
    if (sliderClahe)      sliderClahe.value = d.clahe;
    if (sliderUnsharp)    sliderUnsharp.value = d.unsharp;
    syncSlidersFromParams();
    if (appState.snapshotDataURL && snapCanvas.width > 0) {
      applyFiltersToSnapshot(snapCanvas);
      snapshotPreview.src = filteredCanvas.toDataURL('image/jpeg', 0.88);
    }
  });

  // Upload
  btnUpload?.addEventListener('click', () => fileInput?.click());
  $('btn-upload-replace')?.addEventListener('click', () => fileInput?.click());
  fileInput?.addEventListener('change', e => {
    if (e.target.files[0]) handleUpload(e.target.files[0]);
  });

  // Drag & Drop auf Upload-Zone
  const uploadZone = $('upload-zone');
  if (uploadZone) {
    uploadZone.addEventListener('dragover', e => { e.preventDefault(); uploadZone.classList.add('drag-over'); });
    uploadZone.addEventListener('dragleave', () => uploadZone.classList.remove('drag-over'));
    uploadZone.addEventListener('drop', e => {
      e.preventDefault();
      uploadZone.classList.remove('drag-over');
      if (e.dataTransfer.files[0]) handleUpload(e.dataTransfer.files[0]);
    });
    uploadZone.addEventListener('click', () => fileInput?.click());
  }

  // Analyse-Tabs
  analyzeTabBtns.forEach(btn => {
    btn.addEventListener('click', () => switchTab(btn.dataset.tab));
  });

  // Slider
  bindSliderEvents();

  // Lupe
  bindLoupeEvents();

  // Resize
  window.addEventListener('resize', () => {
    if (appState.cameraActive) Camera.syncOverlayCanvas(video, overlayCanvas);
  });
}

// ── Start ─────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', init);
