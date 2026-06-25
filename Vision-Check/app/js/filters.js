// ═══════════════════════════════════════════
// Vision-Check — Canvas-Filter-Pipeline (Schicht 2)
// CLAHE-Simulation, Unsharp Mask, Helligkeit, Sättigung
// ═══════════════════════════════════════════

'use strict';

const Filters = (() => {

  // ── Hilfsfunktionen ──────────────────────────────

  function clamp(v) { return Math.max(0, Math.min(255, v)); }

  function getPixelData(canvas) {
    const ctx = canvas.getContext('2d');
    return ctx.getImageData(0, 0, canvas.width, canvas.height);
  }

  function putPixelData(canvas, imageData) {
    const ctx = canvas.getContext('2d');
    ctx.putImageData(imageData, 0, 0);
  }

  // ── Helligkeit & Sättigung ───────────────────────

  function adjustBrightnessSaturation(imageData, brightness, saturation) {
    // brightness: -100 ... +100, saturation: 0 ... 3
    const data = imageData.data;
    const b = brightness / 100;
    const s = saturation;

    for (let i = 0; i < data.length; i += 4) {
      let r = data[i], g = data[i+1], bl = data[i+2];

      // Helligkeit
      r = clamp(r + b * 255);
      g = clamp(g + b * 255);
      bl = clamp(bl + b * 255);

      // Sättigung (über Graustufen-Interpolation)
      const gray = 0.299 * r + 0.587 * g + 0.114 * bl;
      data[i]   = clamp(gray + s * (r - gray));
      data[i+1] = clamp(gray + s * (g - gray));
      data[i+2] = clamp(gray + s * (bl - gray));
    }
    return imageData;
  }

  // ── CLAHE-Simulation (Lokale Kontrastverstärkung) ──
  // Vereinfachte Implementierung: Tile-basierte Histogramm-Equalisierung
  // mit Clip-Limit (echtes CLAHE benötigt OpenCV; diese Variante ist Browser-optimiert)

  function applyCLAHE(imageData, clipFactor) {
    // clipFactor: 1 (keine Verstärkung) ... 4 (max)
    if (clipFactor <= 1) return imageData;

    const { width, height, data } = imageData;
    const tileW = Math.max(32, Math.round(width / 8));
    const tileH = Math.max(32, Math.round(height / 8));

    // Graustufen extrahieren
    const luma = new Float32Array(width * height);
    for (let i = 0; i < width * height; i++) {
      const p = i * 4;
      luma[i] = 0.299 * data[p] + 0.587 * data[p+1] + 0.114 * data[p+2];
    }

    // Tile-LUT aufbauen
    const tileCols = Math.ceil(width / tileW);
    const tileRows = Math.ceil(height / tileH);
    const luts = [];

    for (let tr = 0; tr < tileRows; tr++) {
      for (let tc = 0; tc < tileCols; tc++) {
        const x0 = tc * tileW, y0 = tr * tileH;
        const x1 = Math.min(x0 + tileW, width);
        const y1 = Math.min(y0 + tileH, height);

        // Histogramm für dieses Tile
        const hist = new Float32Array(256);
        let count = 0;
        for (let y = y0; y < y1; y++) {
          for (let x = x0; x < x1; x++) {
            hist[Math.round(luma[y * width + x])]++;
            count++;
          }
        }

        // Clip-Limit anwenden
        const clipLimit = (clipFactor * count) / 256;
        let excess = 0;
        for (let v = 0; v < 256; v++) {
          if (hist[v] > clipLimit) {
            excess += hist[v] - clipLimit;
            hist[v] = clipLimit;
          }
        }
        const add = excess / 256;
        for (let v = 0; v < 256; v++) hist[v] += add;

        // Kumulative Verteilung → LUT
        const lut = new Uint8Array(256);
        let cum = 0;
        for (let v = 0; v < 256; v++) {
          cum += hist[v];
          lut[v] = clamp(Math.round((cum / count) * 255));
        }
        luts.push(lut);
      }
    }

    // Bilineare Interpolation der Tile-LUTs auf jeden Pixel anwenden
    for (let y = 0; y < height; y++) {
      for (let x = 0; x < width; x++) {
        const idx = y * width + x;
        const p = idx * 4;

        // Tile-Position (float)
        const tcf = (x / tileW) - 0.5;
        const trf = (y / tileH) - 0.5;
        const tc0 = Math.max(0, Math.floor(tcf));
        const tr0 = Math.max(0, Math.floor(trf));
        const tc1 = Math.min(tileCols - 1, tc0 + 1);
        const tr1 = Math.min(tileRows - 1, tr0 + 1);
        const wc = tcf - tc0, wr = trf - tr0;

        const l = Math.round(luma[idx]);
        const v00 = luts[tr0 * tileCols + tc0][l];
        const v10 = luts[tr0 * tileCols + tc1][l];
        const v01 = luts[tr1 * tileCols + tc0][l];
        const v11 = luts[tr1 * tileCols + tc1][l];

        const mapped = clamp(Math.round(
          v00 * (1-wc) * (1-wr) + v10 * wc * (1-wr) +
          v01 * (1-wc) * wr     + v11 * wc * wr
        ));

        // Helligkeit proportional skalieren, Farbe erhalten
        const origL = luma[idx] || 1;
        const scale = mapped / origL;
        data[p]   = clamp(data[p]   * scale);
        data[p+1] = clamp(data[p+1] * scale);
        data[p+2] = clamp(data[p+2] * scale);
      }
    }
    return imageData;
  }

  // ── Unsharp Mask ─────────────────────────────────
  // Echte Pixelmatrix-Convolution (Gauss-Kernel, konfigurierbar)

  const UNSHARP_KERNELS = [
    // Stufe 0: kein Sharpening
    null,
    // Stufe 1: leicht
    { radius: 1, strength: 0.5 },
    // Stufe 2: mittel
    { radius: 1, strength: 1.0 },
    // Stufe 3: stark
    { radius: 2, strength: 1.5 },
    // Stufe 4: sehr stark
    { radius: 2, strength: 2.5 },
    // Stufe 5: extrem (Insektenerkennung)
    { radius: 3, strength: 4.0 }
  ];

  function gaussKernel(radius) {
    const size = radius * 2 + 1;
    const sigma = radius / 2;
    const kernel = [];
    let sum = 0;
    for (let y = -radius; y <= radius; y++) {
      for (let x = -radius; x <= radius; x++) {
        const val = Math.exp(-(x*x + y*y) / (2 * sigma * sigma));
        kernel.push(val);
        sum += val;
      }
    }
    return kernel.map(v => v / sum);
  }

  function convolve(data, width, height, kernel, radius) {
    const blurred = new Uint8ClampedArray(data.length);
    const kSize = radius * 2 + 1;

    for (let y = 0; y < height; y++) {
      for (let x = 0; x < width; x++) {
        let r = 0, g = 0, b = 0;
        for (let ky = -radius; ky <= radius; ky++) {
          for (let kx = -radius; kx <= radius; kx++) {
            const px = Math.min(width-1, Math.max(0, x + kx));
            const py = Math.min(height-1, Math.max(0, y + ky));
            const pi = (py * width + px) * 4;
            const ki = (ky + radius) * kSize + (kx + radius);
            r += data[pi]   * kernel[ki];
            g += data[pi+1] * kernel[ki];
            b += data[pi+2] * kernel[ki];
          }
        }
        const idx = (y * width + x) * 4;
        blurred[idx]   = r;
        blurred[idx+1] = g;
        blurred[idx+2] = b;
        blurred[idx+3] = data[idx+3];
      }
    }
    return blurred;
  }

  function applyUnsharpMask(imageData, level) {
    if (!level || level === 0) return imageData;
    const cfg = UNSHARP_KERNELS[Math.min(level, 5)];
    if (!cfg) return imageData;

    const { width, height, data } = imageData;
    const kernel = gaussKernel(cfg.radius);
    const blurred = convolve(data, width, height, kernel, cfg.radius);

    for (let i = 0; i < data.length; i += 4) {
      data[i]   = clamp(data[i]   + cfg.strength * (data[i]   - blurred[i]));
      data[i+1] = clamp(data[i+1] + cfg.strength * (data[i+1] - blurred[i+1]));
      data[i+2] = clamp(data[i+2] + cfg.strength * (data[i+2] - blurred[i+2]));
    }
    return imageData;
  }

  // ── Vollständige Pipeline anwenden ───────────────

  function applyPipeline(srcCanvas, dstCanvas, params) {
    const { brightness = 0, saturation = 1, clahe = 1, unsharp = 0 } = params;

    // Quell-Canvas auf Ziel kopieren
    dstCanvas.width = srcCanvas.width;
    dstCanvas.height = srcCanvas.height;
    const ctx = dstCanvas.getContext('2d');
    ctx.drawImage(srcCanvas, 0, 0);

    let imgData = ctx.getImageData(0, 0, dstCanvas.width, dstCanvas.height);

    // Reihenfolge: CLAHE → Helligkeit/Sättigung → Unsharp
    if (clahe > 1) imgData = applyCLAHE(imgData, clahe);
    if (brightness !== 0 || saturation !== 1) {
      imgData = adjustBrightnessSaturation(imgData, brightness, saturation);
    }
    if (unsharp > 0) imgData = applyUnsharpMask(imgData, unsharp);

    ctx.putImageData(imgData, 0, 0);
    return dstCanvas;
  }

  // ── Pixel-Inspektor ──────────────────────────────

  function getPixelAt(canvas, x, y) {
    const ctx = canvas.getContext('2d');
    const px = ctx.getImageData(Math.round(x), Math.round(y), 1, 1).data;
    const r = px[0], g = px[1], b = px[2], a = px[3];
    const hex = '#' + [r,g,b].map(v => v.toString(16).padStart(2,'0')).join('').toUpperCase();
    const brightness = Math.round(0.299 * r + 0.587 * g + 0.114 * b);
    return { r, g, b, a, hex, brightness };
  }

  function renderLoupe(srcCanvas, loupeCanvas, cx, cy, zoom = 8) {
    const lCtx = loupeCanvas.getContext('2d');
    const lw = loupeCanvas.width;
    const lh = loupeCanvas.height;

    // Ausschnitt im Originalbild
    const srcW = lw / zoom;
    const srcH = lh / zoom;
    const sx = Math.max(0, cx - srcW / 2);
    const sy = Math.max(0, cy - srcH / 2);

    lCtx.clearRect(0, 0, lw, lh);
    lCtx.imageSmoothingEnabled = false; // Pixel-perfekt

    lCtx.drawImage(
      srcCanvas,
      sx, sy, srcW, srcH,
      0, 0, lw, lh
    );

    // Fadenkreuz
    lCtx.strokeStyle = 'rgba(99,179,237,0.8)';
    lCtx.lineWidth = 1;
    lCtx.beginPath();
    lCtx.moveTo(lw/2, 0); lCtx.lineTo(lw/2, lh);
    lCtx.moveTo(0, lh/2); lCtx.lineTo(lw, lh/2);
    lCtx.stroke();
  }

  return {
    applyPipeline,
    getPixelAt,
    renderLoupe,
    applyCLAHE,
    applyUnsharpMask,
    adjustBrightnessSaturation,
    UNSHARP_KERNELS
  };

})();
