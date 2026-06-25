// ═══════════════════════════════════════════
// Vision-Check — Kamera-Modul
// MediaStream API, 4K-Anforderung, Geräte-Dropdown
// ═══════════════════════════════════════════

'use strict';

const Camera = (() => {
  let stream = null;
  let deviceList = [];
  let currentDeviceId = null;
  let currentResolution = '4K';

  const RESOLUTIONS = {
    '4K':  { width: 3840, height: 2160, label: '4K (3840×2160)' },
    '2K':  { width: 2560, height: 1440, label: '2K (2560×1440)' },
    'FHD': { width: 1920, height: 1080, label: 'Full HD (1920×1080)' },
    'HD':  { width: 1280, height: 720,  label: 'HD (1280×720)' }
  };

  // Geräte auflisten
  async function enumerateDevices() {
    try {
      // Erst Berechtigung anfordern, damit Labels sichtbar sind
      if (!stream) {
        const tempStream = await navigator.mediaDevices.getUserMedia({ video: true });
        tempStream.getTracks().forEach(t => t.stop());
      }
      const devices = await navigator.mediaDevices.enumerateDevices();
      deviceList = devices.filter(d => d.kind === 'videoinput');
      return deviceList;
    } catch (err) {
      console.error('Geräte-Enumeration fehlgeschlagen:', err);
      return [];
    }
  }

  // UI-Dropdown befüllen
  async function populateDeviceDropdown(selectEl) {
    const devices = await enumerateDevices();
    selectEl.innerHTML = '';
    if (devices.length === 0) {
      selectEl.innerHTML = '<option value="">Keine Kamera gefunden</option>';
      return;
    }
    devices.forEach((dev, i) => {
      const opt = document.createElement('option');
      opt.value = dev.deviceId;
      opt.textContent = dev.label || `Kamera ${i + 1}`;
      selectEl.appendChild(opt);
    });
    if (currentDeviceId) {
      selectEl.value = currentDeviceId;
    }
  }

  // Auflösungs-Dropdown befüllen
  function populateResolutionDropdown(selectEl) {
    selectEl.innerHTML = '';
    Object.entries(RESOLUTIONS).forEach(([key, val]) => {
      const opt = document.createElement('option');
      opt.value = key;
      opt.textContent = val.label;
      selectEl.appendChild(opt);
    });
    selectEl.value = currentResolution;
  }

  // Stream starten / neu starten
  async function start(videoEl, deviceId, resolution) {
    if (stream) stop();

    currentDeviceId = deviceId || currentDeviceId;
    currentResolution = resolution || currentResolution;

    const res = RESOLUTIONS[currentResolution];

    const constraints = {
      video: {
        deviceId: currentDeviceId ? { exact: currentDeviceId } : undefined,
        width: { ideal: res.width },
        height: { ideal: res.height },
        facingMode: currentDeviceId ? undefined : { ideal: 'environment' }
      },
      audio: false
    };

    try {
      stream = await navigator.mediaDevices.getUserMedia(constraints);
      videoEl.srcObject = stream;
      await videoEl.play();

      const track = stream.getVideoTracks()[0];
      const settings = track.getSettings();
      currentDeviceId = settings.deviceId;

      return {
        ok: true,
        actualWidth: settings.width,
        actualHeight: settings.height,
        deviceLabel: track.label
      };
    } catch (err) {
      console.error('Kamera-Start fehlgeschlagen:', err);
      return { ok: false, error: err.message };
    }
  }

  function stop() {
    if (stream) {
      stream.getTracks().forEach(t => t.stop());
      stream = null;
    }
  }

  // Snapshot auf Canvas ziehen und als Base64 zurückgeben
  function captureFrame(videoEl, canvasEl, maxWidth = 1920) {
    const vw = videoEl.videoWidth;
    const vh = videoEl.videoHeight;

    if (!vw || !vh) return null;

    // Skalierung falls nötig (für API-Upload)
    const scale = Math.min(1, maxWidth / vw);
    canvasEl.width  = Math.round(vw * scale);
    canvasEl.height = Math.round(vh * scale);

    const ctx = canvasEl.getContext('2d');
    ctx.drawImage(videoEl, 0, 0, canvasEl.width, canvasEl.height);

    return {
      dataURL: canvasEl.toDataURL('image/jpeg', 0.92),
      width:   canvasEl.width,
      height:  canvasEl.height,
      origWidth: vw,
      origHeight: vh
    };
  }

  // Overlay-Canvas auf Video-Größe synchen
  function syncOverlayCanvas(videoEl, overlayCanvas) {
    const rect = videoEl.getBoundingClientRect();
    overlayCanvas.width  = rect.width;
    overlayCanvas.height = rect.height;
    overlayCanvas.style.width  = rect.width + 'px';
    overlayCanvas.style.height = rect.height + 'px';
  }

  // Bounding Boxes zeichnen
  function drawDetections(overlayCanvas, videoEl, predictions) {
    syncOverlayCanvas(videoEl, overlayCanvas);
    const ctx = overlayCanvas.getContext('2d');
    ctx.clearRect(0, 0, overlayCanvas.width, overlayCanvas.height);

    const scaleX = overlayCanvas.width  / videoEl.videoWidth;
    const scaleY = overlayCanvas.height / videoEl.videoHeight;

    predictions.forEach(pred => {
      const [x, y, w, h] = pred.bbox;
      const sx = x * scaleX, sy = y * scaleY;
      const sw = w * scaleX, sh = h * scaleY;

      // Box
      ctx.strokeStyle = '#4fd1c5';
      ctx.lineWidth = 2;
      ctx.strokeRect(sx, sy, sw, sh);

      // Hintergrund Label
      const label = `${pred.class} ${Math.round(pred.score * 100)}%`;
      ctx.font = 'bold 12px Inter, sans-serif';
      const tw = ctx.measureText(label).width;
      ctx.fillStyle = 'rgba(79, 209, 197, 0.85)';
      ctx.fillRect(sx, sy - 22, tw + 12, 20);

      // Label Text
      ctx.fillStyle = '#0a0f1e';
      ctx.fillText(label, sx + 6, sy - 7);
    });
  }

  return {
    start,
    stop,
    captureFrame,
    populateDeviceDropdown,
    populateResolutionDropdown,
    drawDetections,
    syncOverlayCanvas,
    getStream: () => stream,
    getCurrentDeviceId: () => currentDeviceId,
    getCurrentResolution: () => currentResolution,
    RESOLUTIONS
  };
})();
