#!/usr/bin/perl
# app.js — portiert nach perl5
# Quelle: javascript, Projects@Vision-Check:Vision-Check/app/js/app.js
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;

# ═══════════════════════════════════════════
# Vision-Check — Haupt-App (Analyse-Board)
# Orchestriert: Kamera · Filter · TF.js · Cloud APIs
# ═══════════════════════════════════════════

# ── DOM-Referenzen ───────────────────────────────────
my $video;
my $overlayCanvas;
my $snapCanvas;
my $filteredCanvas;
my $loupeCanvas;
my $loupeInfo;
my $pixelLoupe;

my $btnStartCamera;
my $btnSnap;
my $btnAnalyze;
my $btnSettings;
my $btnToggleLoupe;
my $btnResetFilters;
my $btnUpload;
my $fileInput;

my $cameraSelect;
my $resolutionSelect;

my $statusDot;
my $statusText;
my $camBadge;
my $resolutionInfo;

my $sliderBrightness;
my $sliderSaturation;
my $sliderClahe;
my $sliderUnsharp;
my $valBrightness;
my $valSaturation;
my $valClahe;
my $valUnsharp;

my $settingsModal;
my $snapshotArea;
my $snapshotPreview;

my $resultsContainer;
my @layerIndicators;
my @analyzeTabBtns;
my @analyzeTabContents;

# ── State ────────────────────────────────────────────
my %appState = (
  cameraActive => 0,
  snapshotDataURL => undef,
  loupeActive => 0,
  isAnalyzing => 0,
  tfModel => undef,
  tfBackend => undef,
  filterParams => undef,
  settings => undef,
  liveDetectionRunning => 0,
  rafId => undef
);

# ── Init ─────────────────────────────────────────────
sub init {
  setStatus('Initialisiere...', 'loading');

  # Einstellungen laden
  $appState{settings} = Settings::load();
  applyFilterParamsFromSettings();

  # Service Worker
  # if ('serviceWorker' in navigator) {
  #   navigator.serviceWorker.register('/sw.js').catch(e => console.warn('SW:', e));
  # }

  # Dropdowns befüllen
  # await Camera.populateDeviceDropdown(cameraSelect);
  # Camera.populateResolutionDropdown(resolutionSelect);

  # Slider-Werte aus Settings setzen
  syncSlidersFromParams();

  # Settings-Modal binden
  # Settings.bindModal(settingsModal, newCfg => {
  #   appState.settings = newCfg;
  # });

  # Event-Listener
  bindEvents();

  # TensorFlow.js laden (non-blocking)
  loadTFModel();

  setStatus('Bereit — Kamera starten', '');
}

# ── TensorFlow.js + COCO-SSD ─────────────────────────
sub loadTFModel {
  setLayerIndicator(1, 'loading');
  setStatus('Lade TensorFlow.js...', 'loading');

  # try {
  #   # Backend-Auswahl: WebGPU > WebGL > CPU
  #   const backendFn = async () => {
  #     if (navigator.gpu) {
  #       try {
  #         await tf.setBackend('webgpu');
  #         return 'webgpu';
  #       } catch {}
  #     }
  #     if (await tf.setBackend('webgl')) return 'webgl';
  #     await tf.setBackend('cpu');
  #     return 'cpu';
  #   };

  #   appState.tfBackend = await backendFn();
  #   console.log('TF Backend:', appState.tfBackend);

  #   appState.tfModel = await cocoSsd.load({ base: 'mobilenet_v2' });
  #   setLayerIndicator(1, 'active');
  #   setStatus(`TF.js (${appState.tfBackend}) bereit`, 'ok');

  #   # Kamera automatisch starten nach Modell-Load
  #   if (appState.cameraActive) startLiveDetection();

  # } catch (err) {
  #   setLayerIndicator(1, 'err');
  #   console.error('TF.js Fehler:', err);
  #   setStatus('TF.js nicht verfügbar (Cloud-APIs weiter nutzbar)', 'warn');
  # }
}

# ── Kamera ───────────────────────────────────────────
sub startCamera {
  setStatus('Starte Kamera...', 'loading');
  # camBadge.textContent = 'Verbinde';
  # camBadge.className = 'badge badge-loading';

  # const result = await Camera.start(video, cameraSelect.value, resolutionSelect.value);

  # if (result.ok) {
  #   appState.cameraActive = true;
  #   camBadge.textContent = 'Live';
  #   camBadge.className = 'badge badge-live';
  #   resolutionInfo.textContent = `${result.actualWidth}×${result.actualHeight}`;
  #   setStatus(`Kamera aktiv — ${result.deviceLabel || 'Gerät'} (${result.actualWidth}×${result.actualHeight})`, 'ok');
  #   btnSnap.disabled = false;

  #   # Live-Detektion
  #   if (appState.tfModel) startLiveDetection();

  # } else {
  #   setStatus(`Kamera-Fehler: ${result.error}`, 'err');
  #   camBadge.textContent = 'Fehler';
  #   camBadge.className = 'badge badge-idle';
  # }
}

# ── Live-Detektion (requestAnimationFrame) ────────────
sub startLiveDetection {
  return if $appState{liveDetectionRunning};
  $appState{liveDetectionRunning} = 1;

  my $frameCount = 0;
  my $DETECT_EVERY = 10; # Jedes 10. Frame (≈6fps Detektion bei 60fps rAF)

  # async function loop() {
  #   if (!appState.cameraActive || !appState.tfModel) {
  #     appState.liveDetectionRunning = false;
  #     return;
  #   }

  #   if (++frameCount % DETECT_EVERY === 0 && video.readyState === 4) {
  #     try {
  #       const predictions = await appState.tfModel.detect(video);
  #       Camera.drawDetections(overlayCanvas, video, predictions);

  #       if (predictions.length > 0) {
  #         renderLocalDetections(predictions);
  #       }
  #     } catch {}
  #   }

  #   appState.rafId = requestAnimationFrame(loop);
  # }

  # loop();
}

sub stopLiveDetection {
  $appState{liveDetectionRunning} = 0;
  # if (appState.rafId) cancelAnimationFrame(appState.rafId);
}

# ── Snapshot ─────────────────────────────────────────
sub takeSnapshot {
  if (!$appState{cameraActive}) {
    Settings::showToast('Bitte zuerst Kamera starten');
    return;
  }

  # const frame = Camera.captureFrame(video, snapCanvas, 2048);
  # if (!frame) { Settings.showToast('Kein Bild verfügbar'); return; }

  # # Filter anwenden
  # applyFiltersToSnapshot(snapCanvas);

  # appState.snapshotDataURL = filteredCanvas.toDataURL('image/jpeg', 0.92);

  # # Vorschau
  # snapshotPreview.src = appState.snapshotDataURL;
  # snapshotArea.style.display = 'block';
  # snapshotArea.classList.add('fade-in');

  # btnAnalyze.disabled = false;
  # setStatus('Snapshot gespeichert — Filter angewendet', 'ok');

  # # Auto-Analyse?
  # if (appState.settings?.autoAnalyze) {
  #   runCloudAnalysis();
  # }
}

# ── Filter auf Snapshot anwenden ─────────────────────
sub applyFiltersToSnapshot {
  my ($srcCanvas) = @_;
  # const params = getFilterParams();
  # filteredCanvas.width = srcCanvas.width;
  # filteredCanvas.height = srcCanvas.height;
  # Filters.applyPipeline(srcCanvas, filteredCanvas, params);
}

sub getFilterParams {
  return {
    brightness => $sliderBrightness ? $sliderBrightness->value : 0,
    saturation => $sliderSaturation ? $sliderSaturation->value : 1.2,
    clahe      => $sliderClahe      ? $sliderClahe->value      : 1.5,
    unsharp    => $sliderUnsharp    ? $sliderUnsharp->value    : 2
  };
}

# ── Cloud-Analyse ─────────────────────────────────────
sub runCloudAnalysis {
  if (!$appState{snapshotDataURL}) {
    Settings::showToast('Erst Snapshot aufnehmen');
    return;
  }
  return if $appState{isAnalyzing};

  $appState{isAnalyzing} = 1;
  # btnAnalyze.disabled = true;
  setStatus('Analysiere...', 'loading');
  setLayerIndicator(3, 'loading');

  clearResults();
  showAnalysisSpinner(1);

  my $settings = $appState{settings};
  my $hasAnyKey = $settings->{openaiKey} || $settings->{geminiKey} || $settings->{claudeKey};

  if (!$hasAnyKey && !$settings->{inat}) {
    showNoKeyHint();
    $appState{isAnalyzing} = 0;
    return;
  }

  # await CloudAPI.analyzeAll(appState.snapshotDataURL, settings, (source, result) => {
  #   # Progress: Ergebnis sofort zeigen wenn es ankommt
  #   renderCloudResult(source, result);
  # });

  $appState{isAnalyzing} = 0;
  # btnAnalyze.disabled = false;
  showAnalysisSpinner(0);
  setLayerIndicator(3, 'active');
  setStatus('Analyse abgeschlossen', 'ok');
}

# ── Ergebnisse rendern ───────────────────────────────
sub clearResults {
  # const container = $('result-layer0');
  # const containerCloud = $('result-layer3');
  # if (container) container.innerHTML = '';
  # if (containerCloud) containerCloud.innerHTML = '';
}

sub renderLocalDetections {
  my ($predictions) = @_;
  # const container = $('result-layer1');
  # if (!container) return;

  # container.innerHTML = '';
  # if (predictions.length === 0) {
  #   container.innerHTML = '<p style="color:var(--text-dim);font-size:12px;">Keine Objekte erkannt</p>';
  #   return;
  # }

  # predictions.slice(0, 8).forEach(pred => {
  #   const el = document.createElement('div');
  #   el.className = 'detection-item fade-in';
  #   const pct = Math.round(pred.score * 100);
  #   el.innerHTML = `
  #     <span class="detection-class">${pred.class}</span>
  #     <div class="confidence-bar">
  #       <div class="confidence-track">
  #         <div class="confidence-fill" style="width:${pct}%"></div>
  #       </div>
  #       <span class="confidence-pct">${pct}%</span>
  #     </div>
  #   `;
  #   container.appendChild(el);
  # });
}

sub renderCloudResult {
  my ($source, $result) = @_;
  # Tab auswählen basierend auf Quelle
  my $containerId;
  if ($source eq 'iNaturalist') { $containerId = 'result-layer0'; }
  else { $containerId = 'result-layer3'; }

  # const container = $(containerId);
  # if (!container) return;

  # if (!result.ok) {
  #   const el = document.createElement('div');
  #   el.className = 'result-block fade-in';
  #   el.innerHTML = `
  #     <div class="result-header">
  #       <span class="layer-tag" style="color:var(--accent-err)">${result.source || source}</span>
  #       <span class="badge" style="color:var(--accent-err);background:rgba(252,129,129,0.1)">Fehler</span>
  #     </div>
  #     <p class="result-text" style="color:var(--accent-err)">${result.error}</p>
  #   `;
  #   container.appendChild(el);
  #   return;
  # }

  # if (source === 'iNaturalist' && result.results) {
  #   # iNaturalist Cards
  #   const wrapper = document.createElement('div');
  #   wrapper.className = 'fade-in';
  #   result.results.forEach(r => {
  #     const card = document.createElement('div');
  #     card.className = 'species-card';
  #     card.innerHTML = `
  #       ${r.photoUrl ? `<img class="species-img" src="${r.photoUrl}" alt="${r.name}" loading="lazy">` : '<div class="species-img"></div>'}
  #       <div class="species-info">
  #         <div class="species-name">${r.name}</div>
  #         <div class="species-latin">${r.scientificName || ''}</div>
  #         <div class="species-score">Score: ${r.score ? (r.score * 100).toFixed(1) + '%' : '–'} · ${r.rank || ''}</div>
  #       </div>
  #     `;
  #     wrapper.appendChild(card);
  #   });
  #   container.appendChild(wrapper);

  #   # Tab aktivieren
  #   switchTab('tab-inat');
  #   return;
  # }

  # Text-Ergebnis (OpenAI / Gemini / Claude)
  # const colorMap = {
  #   'OpenAI GPT-4o': 'var(--layer-3-gpt)',
  #   'Gemini 2.5 Pro': 'var(--layer-3-gemini)',
  #   'Claude claude-opus-4-8': 'var(--layer-3-claude)',
  #   'Claude claude-fable-5': 'var(--layer-3-claude)'
  # };
  # const color = colorMap[result.source] || 'var(--accent)';

  # const el = document.createElement('div');
  # el.className = 'result-block fade-in';
  # el.innerHTML = `
  #   <div class="result-header">
  #     <span class="layer-tag" style="color:${color}">
  #       <span style="width:8px;height:8px;border-radius:50%;background:${color};display:inline-block"></span>
  #       ${result.source}
  #     </span>
  #     ${result.tokens ? `<span class="badge" style="color:var(--text-dim);background:transparent;font-size:10px">~${result.tokens.output || '?'} Tokens</span>` : ''}
  #   </div>
  #   <div class="result-text">${markdownToHTML(result.text)}</div>
  # `;
  # container.appendChild(el);
  # switchTab('tab-cloud');
}

sub showNoKeyHint {
  # const container = $('result-layer3');
  # if (!container) return;
  # container.innerHTML = `
  #   <div class="result-block fade-in">
  #     <p class="result-text" style="color:var(--accent-warn)">
  #       Keine API-Keys konfiguriert.<br>
  #       Öffne die Einstellungen (⚙) und trage OpenAI, Gemini oder Claude-Key ein.
  #     </p>
  #   </div>
  # `;
  # showAnalysisSpinner(false);
  # btnAnalyze.disabled = false;
  # appState.isAnalyzing = false;
}

# ── Einfacher Markdown-zu-HTML Konverter ─────────────
sub markdownToHTML {
  my ($text) = @_;
  return '' unless defined $text;
  $text =~ s/&/&amp;/g;
  $text =~ s/</&lt;/g;
  $text =~ s/>/&gt;/g;
  $text =~ s/\*\*(.+?)\*\*/<strong>$1<\/strong>/g;
  $text =~ s/\*(.+?)\*/<em>$1<\/em>/g;
  $text =~ s/^### (.+)$/ <h4 style="color:var(--accent);margin:8px 0 4px">$1<\/h4>/gm;
  $text =~ s/^## (.+)$/ <h3 style="color:var(--accent);margin:10px 0 4px">$1<\/h3>/gm;
  $text =~ s/^# (.+)$/ <h3 style="color:var(--accent);margin:10px 0 4px">$1<\/h3>/gm;
  $text =~ s/^\d+\. (.+)$/ <div style="margin:2px 0;padding-left:12px">$1<\/div>/gm;
  $text =~ s/^[-•] (.+)$/ <div style="margin:2px 0;padding-left:12px">• $1<\/div>/gm;
  $text =~ s/\n\n/<br><br>/g;
  $text =~ s/\n/<br>/g;
  return $text;
}

# ── Tab-Steuerung ─────────────────────────────────────
sub switchTab {
  my ($tabId) = @_;
  # analyzeTabBtns.forEach(btn => {
  #   btn.classList.toggle('active', btn.dataset.tab === tabId);
  # });
  # analyzeTabContents.forEach(content => {
  #   content.classList.toggle('active', content.id === tabId.replace('tab-', 'tab-content-'));
  # });
}

# ── Pixel-Inspektor & Lupe ────────────────────────────
sub bindLoupeEvents {
  # const viewport = $('camera-viewport');
  # if (!viewport) return;

  # viewport.addEventListener('mousemove', e => {
  #   if (!appState.loupeActive) return;
  #   if (!appState.snapshotDataURL && !appState.cameraActive) return;

  #   const rect = viewport.getBoundingClientRect();
  #   const mx = e.clientX - rect.left;
  #   const my = e.clientY - rect.top;

  #   # Koordinaten auf Original-Video skalieren
  #   const scaleX = video.videoWidth / rect.width;
  #   const scaleY = video.videoHeight / rect.height;
  #   const cx = mx * scaleX, cy = my * scaleY;

  #   # Lupe rendern (aus Snapshot oder Video)
  #   const src = filteredCanvas.width > 0 ? filteredCanvas : snapCanvas;
  #   if (src.width > 0) {
  #     loupeCanvas.width = 160;
  #     loupeCanvas.height = 160;
  #     Filters.renderLoupe(src, loupeCanvas, cx, cy, appState.settings?.loupeZoom || 8);

  #     # Pixel-Info
  #     const px = Filters.getPixelAt(src, cx, cy);
  #     loupeInfo.textContent = `${px.hex} · ${px.brightness}L`;

  #     # Pixel-Swatch
  #     const swatch = $('pixel-swatch');
  #     const values = $('pixel-values-text');
  #     if (swatch) swatch.style.background = px.hex;
  #     if (values) values.innerHTML = `
  #       <span>${px.hex}</span>
  #       <span>R:${px.r} G:${px.g} B:${px.b}</span>
  #       <span>Helligkeit: ${px.brightness}</span>
  #     `;
  #   }

  #   # Lupe positionieren
  #   pixelLoupe.style.display = 'block';
  # });

  # viewport.addEventListener('mouseleave', () => {
  #   if (!appState.loupeActive) return;
  #   pixelLoupe.style.display = 'none';
  # });
}

# ── Status-Helfer ─────────────────────────────────────
sub setStatus {
  my ($msg, $state) = @_;
  # if (statusText) statusText.textContent = msg;
  # if (statusDot) {
  #   statusDot.className = 'status-dot';
  #   if (state === 'ok') statusDot.classList.add('ok');
  #   else if (state === 'warn') statusDot.classList.add('warn');
  #   else if (state === 'err' || state === 'error') statusDot.classList.add('err');
  # }
}

sub setLayerIndicator {
  my ($layer, $state) = @_;
  # const dot = document.querySelector(`.layer-dot[data-layer="${layer}"]`);
  # if (!dot) return;
  # dot.classList.toggle('active', state === 'active' || state === 'loading');
}

sub showAnalysisSpinner {
  my ($show) = @_;
  # const spinner = $('analyze-spinner');
  # if (spinner) spinner.style.display = show ? 'block' : 'none';
}

# ── Filter-Slider-Sync ────────────────────────────────
sub syncSlidersFromParams {
  my $cfg = $appState{settings} || Settings::DEFAULTS();
  if ($sliderBrightness) { $sliderBrightness->value($cfg->{brightness}); $valBrightness->textContent($cfg->{brightness}); }
  if ($sliderSaturation) { $sliderSaturation->value($cfg->{saturation}); $valSaturation->textContent($cfg->{saturation}); }
  if ($sliderClahe)      { $sliderClahe->value($cfg->{clahe});           $valClahe->textContent($cfg->{clahe} . 'x'); }
  if ($sliderUnsharp)    { $sliderUnsharp->value($cfg->{unsharp});       $valUnsharp->textContent($cfg->{unsharp}); }
}

sub applyFilterParamsFromSettings {
  # Nichts zu tun — Params werden direkt aus Slidern gelesen
}

sub bindSliderEvents {
  my @pairs = (
    [$sliderBrightness, $valBrightness, sub { $_[0] }, ''],
    [$sliderSaturation, $valSaturation, sub { $_[0] }, ''],
    [$sliderClahe,      $valClahe,      sub { $_[0] }, 'x'],
    [$sliderUnsharp,    $valUnsharp,    sub { $_[0] }, '']
  );
  for my $pair (@pairs) {
    my ($slider, $label, $fn, $suffix) = @$pair;
    next unless $slider;
    # slider.addEventListener('input', () => {
    #   if (label) label.textContent = fn(slider.value) + suffix;
    #   # Vorschau live aktualisieren wenn Snapshot vorhanden
    #   if (appState.snapshotDataURL && snapCanvas.width > 0) {
    #     applyFiltersToSnapshot(snapCanvas);
    #     snapshotPreview.src = filteredCanvas.toDataURL('image/jpeg', 0.88);
    #   }
    # });
  }
}

# ── Upload-Handling ───────────────────────────────────
sub handleUpload {
  my ($file) = @_;
  # if (!file || !file.type.startsWith('image/')) {
  #   Settings.showToast('Bitte ein Bild hochladen');
  #   return;
  # }
  # const reader = new FileReader();
  # reader.onload = e => {
  #   const img = new Image();
  #   img.onload = () => {
  #     snapCanvas.width = img.width;
  #     snapCanvas.height = img.height;
  #     snapCanvas.getContext('2d').drawImage(img, 0, 0);
  #     applyFiltersToSnapshot(snapCanvas);
  #     appState.snapshotDataURL = filteredCanvas.toDataURL('image/jpeg', 0.92);
  #     snapshotPreview.src = appState.snapshotDataURL;
  #     snapshotArea.style.display = 'block';
  #     btnAnalyze.disabled = false;
  #     setStatus(`Bild geladen: ${img.width}×${img.height}px`, 'ok');
  #     if (appState.settings?.autoAnalyze) runCloudAnalysis();
  #   };
  #   img.src = e.target.result;
  # };
  # reader.readAsDataURL(file);
}

# ── Event-Listener binden ─────────────────────────────
sub bindEvents {
  # Kamera
  # btnStartCamera?.addEventListener('click', startCamera);

  # cameraSelect?.addEventListener('change', () => {
  #   if (appState.cameraActive) startCamera();
  # });

  # resolutionSelect?.addEventListener('change', () => {
  #   if (appState.cameraActive) startCamera();
  # });

  # Snapshot
  # btnSnap?.addEventListener('click', takeSnapshot);

  # Analyse
  # btnAnalyze?.addEventListener('click', runCloudAnalysis);

  # Einstellungen
  # btnSettings?.addEventListener('click', () => Settings.openModal(settingsModal));

  # Lupe Toggle
  # btnToggleLoupe?.addEventListener('click', () => {
  #   appState.loupeActive = !appState.loupeActive;
  #   btnToggleLoupe.classList.toggle('btn-primary', appState.loupeActive);
  #   if (!appState.loupeActive) pixelLoupe.style.display = 'none';
  # });

  # Filter Reset
  # btnResetFilters?.addEventListener('click', () => {
  #   const d = Settings.DEFAULTS;
  #   if (sliderBrightness) sliderBrightness.value = d.brightness;
  #   if (sliderSaturation) sliderSaturation.value = d.saturation;
  #   if (sliderClahe)      sliderClahe.value = d.clahe;
  #   if (sliderUnsharp)    sliderUnsharp.value = d.unsharp;
  #   syncSlidersFromParams();
  #   if (appState.snapshotDataURL && snapCanvas.width > 0) {
  #     applyFiltersToSnapshot(snapCanvas);
  #     snapshotPreview.src = filteredCanvas.toDataURL('image/jpeg', 0.88);
  #   }
  # });

  # Upload
  # btnUpload?.addEventListener('click', () => fileInput?.click());
  # $('btn-upload-replace')?.addEventListener('click', () => fileInput?.click());
  # fileInput?.addEventListener('change', e => {
  #   if (e.target.files[0]) handleUpload(e.target.files[0]);
  # });

  # Drag & Drop auf Upload-Zone
  # const uploadZone = $('upload-zone');
  # if (uploadZone) {
  #   uploadZone.addEventListener('dragover', e => { e.preventDefault(); uploadZone.classList.add('drag-over'); });
  #   uploadZone.addEventListener('dragleave', () => uploadZone.classList.remove('drag-over'));
  #   uploadZone.addEventListener('drop', e => {
  #     e.preventDefault();
  #     uploadZone.classList.remove('drag-over');
  #     if (e.dataTransfer.files[0]) handleUpload(e.dataTransfer.files[0]);
  #   });
  #   uploadZone.addEventListener('click', () => fileInput?.click());
  # }

  # Analyse-Tabs
  # analyzeTabBtns.forEach(btn => {
  #   btn.addEventListener('click', () => switchTab(btn.dataset.tab));
  # });

  # Slider
  bindSliderEvents();

  # Lupe
  bindLoupeEvents();

  # Resize
  # window.addEventListener('resize', () => {
  #   if (appState.cameraActive) Camera.syncOverlayCanvas(video, overlayCanvas);
  # });
}

# ── Start ─────────────────────────────────────────────
# document.addEventListener('DOMContentLoaded', init);

1;
