// abstraction-provenance: {"artifact_sha256": "4e9d938770670609aa06618a7c731f76f10b602116912cac614d3f92c339a53b", "source_sha256": "02dd111b283ac08d7a9f3fbbe30150fb6db98097ed7bc68f2677c6df9c744bfb", "target_language": "fsharp"}
// index.html — portiert nach fsharp
// Quelle: html, Projects@Vision-Check:Vision-Check/app/index.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

open System
open System.IO
open System.Text

let generateHTML () =
    let sb = StringBuilder()

    // DOCTYPE and html tag
    sb.AppendLine("<!DOCTYPE html>") |> ignore
    sb.AppendLine("<html lang=\"de\">") |> ignore
    
    // HEAD section
    sb.AppendLine("<head>") |> ignore
    sb.AppendLine("  <meta charset=\"UTF-8\">") |> ignore
    sb.AppendLine("  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no\">") |> ignore
    sb.AppendLine("  <meta name=\"theme-color\" content=\"#0a0f1e\">") |> ignore
    sb.AppendLine("  <meta name=\"description\" content=\"Lokale KI-gestützte Bildanalyse für Tiere & Insekten\">") |> ignore
    sb.AppendLine("  <meta name=\"apple-mobile-web-app-capable\" content=\"yes\">") |> ignore
    sb.AppendLine("  <meta name=\"apple-mobile-web-app-status-bar-style\" content=\"black-translucent\">") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("  <title>Vision-Check</title>") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("  <link rel=\"manifest\" href=\"manifest.json\">") |> ignore
    sb.AppendLine("  <link rel=\"icon\" type=\"image/svg+xml\" href=\"icons/icon.svg\">") |> ignore
    sb.AppendLine("  <link rel=\"apple-touch-icon\" href=\"icons/icon-192.png\">") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("  <!-- Fonts -->") |> ignore
    sb.AppendLine("  <link rel=\"preconnect\" href=\"https://fonts.googleapis.com\">") |> ignore
    sb.AppendLine("  <link href=\"https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@400;600&display=swap\" rel=\"stylesheet\">") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("  <!-- TensorFlow.js + COCO-SSD -->") |> ignore
    sb.AppendLine("  <script src=\"https://cdn.jsdelivr.net/npm/@tensorflow/tfjs@4.22.0/dist/tf.min.js\" defer></script>") |> ignore
    sb.AppendLine("  <script src=\"https://cdn.jsdelivr.net/npm/@tensorflow-models/coco-ssd@2.2.3/dist/coco-ssd.min.js\" defer></script>") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("  <!-- App CSS -->") |> ignore
    sb.AppendLine("  <link rel=\"stylesheet\" href=\"css/style.css\">") |> ignore
    sb.AppendLine("</head>") |> ignore
    sb.AppendLine("<body>") |> ignore
    sb.AppendLine("") |> ignore
    
    // HEADER
    sb.AppendLine("<!-- ══════════ HEADER ══════════ -->") |> ignore
    sb.AppendLine("<div id=\"app\">") |> ignore
    sb.AppendLine("  <header id=\"app-header\">") |> ignore
    sb.AppendLine("    <div class=\"header-brand\">") |> ignore
    sb.AppendLine("      <svg viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"1.8\" stroke-linecap=\"round\" stroke-linejoin=\"round\">") |> ignore
    sb.AppendLine("        <circle cx=\"12\" cy=\"12\" r=\"3\"/>") |> ignore
    sb.AppendLine("        <path d=\"M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2z\" opacity=\".3\"/>") |> ignore
    sb.AppendLine("        <path d=\"M12 8a4 4 0 0 1 4 4\"/>") |> ignore
    sb.AppendLine("        <path d=\"M8 12a4 4 0 0 1 4-4\"/>") |> ignore
    sb.AppendLine("        <path d=\"M12 16a4 4 0 0 1-4-4\"/>") |> ignore
    sb.AppendLine("        <path d=\"M16 12a4 4 0 0 1-4 4\"/>") |> ignore
    sb.AppendLine("      </svg>") |> ignore
    sb.AppendLine("      <h1>Vision-Check</h1>") |> ignore
    sb.AppendLine("    </div>") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("    <div style=\"display:flex;align-items:center;gap:6px;font-size:11px;color:var(--text-dim)\">") |> ignore
    sb.AppendLine("      <!-- Layer-Indikatoren -->") |> ignore
    sb.AppendLine("      <div class=\"layer-indicator\" title=\"Aktive KI-Schichten\">") |> ignore
    sb.AppendLine("        <div class=\"layer-dot\" data-layer=\"0\" style=\"color:var(--layer-0);background:var(--layer-0)\" title=\"iNaturalist\"></div>") |> ignore
    sb.AppendLine("        <div class=\"layer-dot\" data-layer=\"1\" style=\"color:var(--layer-1);background:var(--layer-1)\" title=\"TF.js COCO-SSD\"></div>") |> ignore
    sb.AppendLine("        <div class=\"layer-dot\" data-layer=\"2\" style=\"color:var(--layer-2);background:var(--layer-2)\" title=\"Canvas-Filter\"></div>") |> ignore
    sb.AppendLine("        <div class=\"layer-dot\" data-layer=\"3\" style=\"color:var(--layer-3-gpt);background:var(--layer-3-gpt)\" title=\"Cloud APIs\"></div>") |> ignore
    sb.AppendLine("      </div>") |> ignore
    sb.AppendLine("    </div>") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("    <div class=\"header-controls\">") |> ignore
    sb.AppendLine("      <button class=\"btn btn-icon\" id=\"btn-settings\" title=\"Einstellungen / API-Keys\">") |> ignore
    sb.AppendLine("        <svg width=\"16\" height=\"16\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\">") |> ignore
    sb.AppendLine("          <circle cx=\"12\" cy=\"12\" r=\"3\"/>") |> ignore
    sb.AppendLine("          <path d=\"M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z\"/>") |> ignore
    sb.AppendLine("        </svg>") |> ignore
    sb.AppendLine("      </button>") |> ignore
    sb.AppendLine("    </div>") |> ignore
    sb.AppendLine("  </header>") |> ignore
    sb.AppendLine("") |> ignore
    
    // BOARD
    sb.AppendLine("  <!-- ══════════ BOARD ══════════ -->") |> ignore
    sb.AppendLine("  <div id=\"board\">") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("    <!-- ── Kamera-Panel (links) ── -->") |> ignore
    sb.AppendLine("    <div id=\"camera-panel\">") |> ignore
    sb.AppendLine("      <div class=\"panel-header\">") |> ignore
    sb.AppendLine("        <span class=\"panel-title\">Kamera / Bild</span>") |> ignore
    sb.AppendLine("        <div style=\"display:flex;align-items:center;gap:8px\">") |> ignore
    sb.AppendLine("          <span id=\"resolution-info\" style=\"font-size:10px;color:var(--text-dim)\">–</span>") |> ignore
    sb.AppendLine("          <span id=\"cam-badge\" class=\"badge badge-idle\">Bereit</span>") |> ignore
    sb.AppendLine("        </div>") |> ignore
    sb.AppendLine("      </div>") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("      <!-- Kamera-Viewport -->") |> ignore
    sb.AppendLine("      <div id=\"camera-viewport\">") |> ignore
    sb.AppendLine("        <video id=\"video\" autoplay playsinline muted></video>") |> ignore
    sb.AppendLine("        <canvas id=\"canvas-overlay\"></canvas>") |> ignore
    sb.AppendLine("        <canvas id=\"snap-canvas\" style=\"display:none\"></canvas>") |> ignore
    sb.AppendLine("        <canvas id=\"filtered-canvas\" style=\"display:none\"></canvas>") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("        <!-- Pixel-Lupe -->") |> ignore
    sb.AppendLine("        <div id=\"pixel-loupe\">") |> ignore
    sb.AppendLine("          <canvas id=\"loupe-canvas\" width=\"160\" height=\"160\"></canvas>") |> ignore
    sb.AppendLine("          <div id=\"loupe-info\">–</div>") |> ignore
    sb.AppendLine("        </div>") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("        <!-- Start-Overlay wenn keine Kamera -->") |> ignore
    sb.AppendLine("        <div id=\"start-overlay\" style=\"position:absolute;inset:0;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:16px;background:rgba(10,15,30,0.8)\">") |> ignore
    sb.AppendLine("          <svg width=\"48\" height=\"48\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"var(--accent)\" stroke-width=\"1.5\">") |> ignore
    sb.AppendLine("            <path d=\"M23 7l-7 5 7 5V7z\"/>") |> ignore
    sb.AppendLine("            <rect x=\"1\" y=\"5\" width=\"15\" height=\"14\" rx=\"2\" ry=\"2\"/>") |> ignore
    sb.AppendLine("          </svg>") |> ignore
    sb.AppendLine("          <p style=\"color:var(--text-muted);font-size:13px;text-align:center\">Kamera starten oder Bild hochladen</p>") |> ignore
    sb.AppendLine("          <div style=\"display:flex;gap:8px\">") |> ignore
    sb.AppendLine("            <button class=\"btn btn-primary\" id=\"btn-start-camera\">") |> ignore
    sb.AppendLine("              <svg width=\"14\" height=\"14\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\">") |> ignore
    sb.AppendLine("                <path d=\"M23 7l-7 5 7 5V7z\"/>") |> ignore
    sb.AppendLine("                <rect x=\"1\" y=\"5\" width=\"15\" height=\"14\" rx=\"2\" ry=\"2\"/>") |> ignore
    sb.AppendLine("              </svg>") |> ignore
    sb.AppendLine("              Kamera starten") |> ignore
    sb.AppendLine("            </button>") |> ignore
    sb.AppendLine("            <button class=\"btn\" id=\"btn-upload\">") |> ignore
    sb.AppendLine("              <svg width=\"14\" height=\"14\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\">") |> ignore
    sb.AppendLine("                <path d=\"M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4\"/>") |> ignore
    sb.AppendLine("                <polyline points=\"17 8 12 3 7 8\"/>") |> ignore
    sb.AppendLine("                <line x1=\"12\" y1=\"3\" x2=\"12\" y2=\"15\"/>") |> ignore
    sb.AppendLine("              </svg>") |> ignore
    sb.AppendLine("              Bild laden") |> ignore
    sb.AppendLine("            </button>") |> ignore
    sb.AppendLine("          </div>") |> ignore
    sb.AppendLine("        </div>") |> ignore
    sb.AppendLine("      </div>") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("      <!-- Kamera-Steuerleiste -->") |> ignore
    sb.AppendLine("      <div id=\"camera-controls\">") |> ignore
    sb.AppendLine("        <select id=\"camera-select\" style=\"max-width:160px\"></select>") |> ignore
    sb.AppendLine("        <select id=\"resolution-select\" style=\"max-width:140px\"></select>") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("        <div style=\"flex:1\"></div>") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("        <button class=\"btn btn-icon\" id=\"btn-toggle-loupe\" title=\"Pixel-Lupe ein/aus\">") |> ignore
    sb.AppendLine("          <svg width=\"14\" height=\"14\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\">") |> ignore
    sb.AppendLine("            <circle cx=\"11\" cy=\"11\" r=\"8\"/>") |> ignore
    sb.AppendLine("            <line x1=\"21\" y1=\"21\" x2=\"16.65\" y2=\"16.65\"/>") |> ignore
    sb.AppendLine("            <line x1=\"11\" y1=\"8\" x2=\"11\" y2=\"14\"/>") |> ignore
    sb.AppendLine("            <line x1=\"8\" y1=\"11\" x2=\"14\" y2=\"11\"/>") |> ignore
    sb.AppendLine("          </svg>") |> ignore
    sb.AppendLine("        </button>") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("        <button class=\"btn btn-snap\" id=\"btn-snap\" disabled>") |> ignore
    sb.AppendLine("          <svg width=\"14\" height=\"14\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\">") |> ignore
    sb.AppendLine("            <circle cx=\"12\" cy=\"12\" r=\"3\"/>") |> ignore
    sb.AppendLine("            <path d=\"M20 7h-3a2 2 0 0 1-2-2V4a2 2 0 0 0-2-2h-2a2 2 0 0 0-2 2v1a2 2 0 0 1-2 2H4a2 2 0 0 0-2 2v10a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2z\"/>") |> ignore
    sb.AppendLine("          </svg>") |> ignore
    sb.AppendLine("          Snapshot") |> ignore
    sb.AppendLine("        </button>") |> ignore
    sb.AppendLine("      </div>") |> ignore
    sb.AppendLine("    </div>") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("    <!-- ── Rechtes Panel ── -->") |> ignore
    sb.AppendLine("    <div id=\"right-panel\">") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("      <!-- Filter-Karte -->") |> ignore
    sb.AppendLine("      <div class=\"card\">") |> ignore
    sb.AppendLine("        <div class=\"panel-header\">") |> ignore
    sb.AppendLine("          <span class=\"panel-title\" style=\"color:var(--layer-2)\">Schicht 2 — Filter</span>") |> ignore
    sb.AppendLine("          <button class=\"btn btn-sm\" id=\"btn-reset-filters\">Reset</button>") |> ignore
    sb.AppendLine("        </div>") |> ignore
    sb.AppendLine("        <div class=\"card-body\">") |> ignore
    sb.AppendLine("          <div class=\"slider-row\">") |> ignore
    sb.AppendLine("            <span class=\"slider-label\">Helligkeit</span>") |> ignore
    sb.AppendLine("            <input type=\"range\" id=\"slider-brightness\" min=\"-80\" max=\"80\" value=\"0\" step=\"1\">") |> ignore
    sb.AppendLine("            <span class=\"slider-value\" id=\"val-brightness\">0</span>") |> ignore
    sb.AppendLine("          </div>") |> ignore
    sb.AppendLine("          <div class=\"slider-row\">") |> ignore
    sb.AppendLine("            <span class=\"slider-label\">Sättigung</span>") |> ignore
    sb.AppendLine("            <input type=\"range\" id=\"slider-saturation\" min=\"0\" max=\"3\" value=\"1.2\" step=\"0.1\">") |> ignore
    sb.AppendLine("            <span class=\"slider-value\" id=\"val-saturation\">1.2</span>") |> ignore
    sb.AppendLine("          </div>") |> ignore
    sb.AppendLine("          <div class=\"slider-row\">") |> ignore
    sb.AppendLine("            <span class=\"slider-label\">CLAHE (Kontrast)</span>") |> ignore
    sb.AppendLine("            <input type=\"range\" id=\"slider-clahe\" min=\"1\" max=\"4\" value=\"1.5\" step=\"0.1\">") |> ignore
    sb.AppendLine("            <span class=\"slider-value\" id=\"val-clahe\">1.5x</span>") |> ignore
    sb.AppendLine("          </div>") |> ignore
    sb.AppendLine("          <div class=\"slider-row\">") |> ignore
    sb.AppendLine("            <span class=\"slider-label\">Schärfe (Unsharp)</span>") |> ignore
    sb.AppendLine("            <input type=\"range\" id=\"slider-unsharp\" min=\"0\" max=\"5\" value=\"2\" step=\"1\">") |> ignore
    sb.AppendLine("            <span class=\"slider-value\" id=\"val-unsharp\">2</span>") |> ignore
    sb.AppendLine("          </div>") |> ignore
    sb.AppendLine("        </div>") |> ignore
    sb.AppendLine("      </div>") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("      <!-- Snapshot-Vorschau -->") |> ignore
    sb.AppendLine("      <div class=\"card\" id=\"snapshot-area\" style=\"display:none\">") |> ignore
    sb.AppendLine("        <div class=\"panel-header\">") |> ignore
    sb.AppendLine("          <span class=\"panel-title\">Snapshot (gefiltert)</span>") |> ignore
    sb.AppendLine("          <div style=\"display:flex;gap:4px\">") |> ignore
    sb.AppendLine("            <button class=\"btn btn-sm\" id=\"btn-upload-replace\">") |> ignore
    sb.AppendLine("              <svg width=\"12\" height=\"12\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\">") |> ignore
    sb.AppendLine("                <path d=\"M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4\"/>") |> ignore
    sb.AppendLine("                <polyline points=\"17 8 12 3 7 8\"/>") |> ignore
    sb.AppendLine("                <line x1=\"12\" y1=\"3\" x2=\"12\" y2=\"15\"/>") |> ignore
    sb.AppendLine("              </svg>") |> ignore
    sb.AppendLine("              Ersetzen") |> ignore
    sb.AppendLine("            </button>") |> ignore
    sb.AppendLine("          </div>") |> ignore
    sb.AppendLine("        </div>") |> ignore
    sb.AppendLine("        <div class=\"card-body\" style=\"padding:0\">") |> ignore
    sb.AppendLine("          <img id=\"snapshot-preview\" style=\"width:100%;display:block;border-radius:0 0 14px 14px\" alt=\"Snapshot\">") |> ignore
    sb.AppendLine("        </div>") |> ignore
    sb.AppendLine("      </div>") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("      <!-- Pixel-Inspektor -->") |> ignore
    sb.AppendLine("      <div class=\"card\">") |> ignore
    sb.AppendLine("        <div class=\"panel-header\">") |> ignore
    sb.AppendLine("          <span class=\"panel-title\">Pixel-Inspektor</span>") |> ignore
    sb.AppendLine("          <span style=\"font-size:10px;color:var(--text-dim)\">8× Zoom-Lupe</span>") |> ignore
    sb.AppendLine("        </div>") |> ignore
    sb.AppendLine("        <div class=\"card-body\">") |> ignore
    sb.AppendLine("          <div id=\"pixel-info\">") |> ignore
    sb.AppendLine("            <div class=\"pixel-swatch\" id=\"pixel-swatch\" style=\"background:#333\"></div>") |> ignore
    sb.AppendLine("            <div class=\"pixel-values\">") |> ignore
    sb.AppendLine("              <span id=\"pixel-values-text\" style=\"color:var(--text-dim);font-size:11px\">Maus über Bild bewegen</span>") |> ignore
    sb.AppendLine("            </div>") |> ignore
    sb.AppendLine("          </div>") |> ignore
    sb.AppendLine("          <p style=\"font-size:10px;color:var(--text-dim);margin-top:8px\">") |> ignore
    sb.AppendLine("            Lupe-Icon aktivieren → Lupe über Bild fahren") |> ignore
    sb.AppendLine("          </p>") |> ignore
    sb.AppendLine("        </div>") |> ignore
    sb.AppendLine("      </div>") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("      <!-- Analyse-Panel -->") |> ignore
    sb.AppendLine("      <div class=\"card\" style=\"flex:1\">") |> ignore
    sb.AppendLine("        <div class=\"panel-header\">") |> ignore
    sb.AppendLine("          <span class=\"panel-title\">Analyse-Ergebnisse</span>") |> ignore
    sb.AppendLine("          <div id=\"analyze-spinner\" class=\"spinner\" style=\"display:none\"></div>") |> ignore
    sb.AppendLine("        </div>") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("        <!-- Tabs -->") |> ignore
    sb.AppendLine("        <div class=\"tab-bar\">") |> ignore
    sb.AppendLine("          <button class=\"tab active\" data-tab=\"tab-inat\">") |> ignore
    sb.AppendLine("            <span style=\"color:var(--layer-0)\">● </span>iNaturalist") |> ignore
    sb.AppendLine("          </button>") |> ignore
    sb.AppendLine("          <button class=\"tab\" data-tab=\"tab-layer1\">") |> ignore
    sb.AppendLine("            <span style=\"color:var(--layer-1)\">● </span>Lokal") |> ignore
    sb.AppendLine("          </button>") |> ignore
    sb.AppendLine("          <button class=\"tab\" data-tab=\"tab-cloud\">") |> ignore
    sb.AppendLine("            <span style=\"color:var(--layer-3-gpt)\">● </span>Cloud") |> ignore
    sb.AppendLine("          </button>") |> ignore
    sb.AppendLine("        </div>") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("        <!-- Tab-Inhalte -->") |> ignore
    sb.AppendLine("        <div id=\"tab-content-inat\" class=\"tab-content active\" style=\"padding:12px\">") |> ignore
    sb.AppendLine("          <div id=\"result-layer0\">") |> ignore
    sb.AppendLine("            <p style=\"color:var(--text-dim);font-size:12px\">iNaturalist — Artenbestimmung nach Snapshot + Analyse</p>") |> ignore
    sb.AppendLine("          </div>") |> ignore
    sb.AppendLine("        </div>") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("        <div id=\"tab-content-layer1\" class=\"tab-content\" style=\"padding:12px\">") |> ignore
    sb.AppendLine("          <div style=\"margin-bottom:8px\">") |> ignore
    sb.AppendLine("            <span class=\"badge\" style=\"color:var(--layer-1);background:rgba(79,209,197,0.1)\">TF.js COCO-SSD — Live-Erkennung</span>") |> ignore
    sb.AppendLine("          </div>") |> ignore
    sb.AppendLine("          <div id=\"result-layer1\">") |> ignore
    sb.AppendLine("            <p style=\"color:var(--text-dim);font-size:12px\">Echtzeit-Detektion läuft nach Kamera-Start</p>") |> ignore
    sb.AppendLine("          </div>") |> ignore
    sb.AppendLine("        </div>") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("        <div id=\"tab-content-cloud\" class=\"tab-content\" style=\"padding:12px\">") |> ignore
    sb.AppendLine("          <div id=\"results-container\">") |> ignore
    sb.AppendLine("            <div id=\"result-layer3\">") |> ignore
    sb.AppendLine("              <p style=\"color:var(--text-dim);font-size:12px\">Cloud-APIs (GPT-4o / Gemini 2.5 / Claude) nach Snapshot + Analyse-Button</p>") |> ignore
    sb.AppendLine("            </div>") |> ignore
    sb.AppendLine("          </div>") |> ignore
    sb.AppendLine("        </div>") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("        <!-- Analyse-Button -->") |> ignore
    sb.AppendLine("        <div style=\"padding:12px;border-top:1px solid var(--border)\">") |> ignore
    sb.AppendLine("          <button class=\"btn btn-primary\" id=\"btn-analyze\" disabled style=\"width:100%;justify-content:center;padding:10px\">") |> ignore
    sb.AppendLine("            <svg width=\"14\" height=\"14\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\">") |> ignore
    sb.AppendLine("              <circle cx=\"11\" cy=\"11\" r=\"8\"/>") |> ignore
    sb.AppendLine("              <line x1=\"21\" y1=\"21\" x2=\"16.65\" y2=\"16.65\"/>") |> ignore
    sb.AppendLine("            </svg>") |> ignore
    sb.AppendLine("            Alle APIs analysieren") |> ignore
    sb.AppendLine("          </button>") |> ignore
    sb.AppendLine("        </div>") |> ignore
    sb.AppendLine("      </div>") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("    </div><!-- /right-panel -->") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("    <!-- ── Status-Leiste ── -->") |> ignore
    sb.AppendLine("    <div id=\"status-bar\">") |> ignore
    sb.AppendLine("      <div id=\"status-dot\" class=\"status-dot\"></div>") |> ignore
    sb.AppendLine("      <span id=\"status-text\">Initialisiere...</span>") |> ignore
    sb.AppendLine("    </div>") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("  </div><!-- /board -->") |> ignore
    sb.AppendLine("</div><!-- /app -->") |> ignore
    sb.AppendLine("") |> ignore
    
    // SETTINGS MODAL
    sb.AppendLine("<!-- ══════════ SETTINGS MODAL (EnvManager) ══════════ -->") |> ignore
    sb.AppendLine("<div id=\"settings-modal\">") |> ignore
    sb.AppendLine("  <div class=\"modal-box\" style=\"width:560px\">") |> ignore
    sb.AppendLine("    <div class=\"modal-title\">⚙ Einstellungen &amp; API-Keys</div>") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("    <!-- Sicherheitshinweis -->") |> ignore
    sb.AppendLine("    <div style=\"background:rgba(251,211,141,0.1);border:1px solid rgba(251,211,141,0.3);border-radius:8px;padding:10px 12px;margin-bottom:20px;font-size:11px;color:var(--accent-warn)\">") |> ignore
    sb.AppendLine("      🔒 Alle API-Keys bleiben ausschließlich lokal in deinem Browser (localStorage). Kein Backend, keine Weiterleitung.") |> ignore
    sb.AppendLine("    </div>") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("    <!-- OpenAI -->") |> ignore
    sb.AppendLine("    <div class=\"settings-section\">") |> ignore
    sb.AppendLine("      <div class=\"settings-section-title\" style=\"color:var(--layer-3-gpt)\">OpenAI — GPT-4o Vision</div>") |> ignore
    sb.AppendLine("      <label class=\"settings-label\">API-Key (sk-proj-…)</label>") |> ignore
    sb.AppendLine("      <input class=\"settings-input\" type=\"password\" id=\"openai-key\" placeholder=\"sk-proj-...\">") |> ignore
    sb.AppendLine("      <p class=\"settings-hint\">Aus <a href=\"https://platform.openai.com/api-keys\" target=\"_blank\" style=\"color:var(--accent)\">platform.openai.com/api-keys</a> — kein CORS-Problem, direkt nutzbar.</p>") |> ignore
    sb.AppendLine("    </div>") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("    <!-- Gemini -->") |> ignore
    sb.AppendLine("    <div class=\"settings-section\">") |> ignore
    sb.AppendLine("      <div class=\"settings-section-title\" style=\"color:var(--layer-3-gemini)\">Google Gemini — 2.5 Pro Vision</div>") |> ignore
    sb.AppendLine("      <label class=\"settings-label\">API-Key (AIza…)</label>") |> ignore
    sb.AppendLine("      <input class=\"settings-input\" type=\"password\" id=\"gemini-key\" placeholder=\"AIzaSy...\">") |> ignore
    sb.AppendLine("      <p class=\"settings-hint\">Aus <a href=\"https://aistudio.google.com/app/apikey\" target=\"_blank\" style=\"color:var(--accent)\">Google AI Studio</a> — kein CORS-Problem.</p>") |> ignore
    sb.AppendLine("    </div>") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("    <!-- Claude -->") |> ignore
    sb.AppendLine("    <div class=\"settings-section\">") |> ignore
    sb.AppendLine("      <div class=\"settings-section-title\" style=\"color:var(--layer-3-claude)\">Anthropic Claude — Opus 4.8 / Fable 5</div>") |> ignore
    sb.AppendLine("      <label class=\"settings-label\">API-Key (sk-ant-…)</label>") |> ignore
    sb.AppendLine("      <input class=\"settings-input\" type=\"password\" id=\"claude-key\" placeholder=\"sk-ant-...\">") |> ignore
    sb.AppendLine("      <p class=\"settings-hint\">Aus <a href=\"https://console.anthropic.com\" target=\"_blank\" style=\"color:var(--accent)\">console.anthropic.com</a></p>") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("      <label class=\"settings-label\" style=\"margin-top:12px\">Modell</label>") |> ignore
    sb.AppendLine("      <select class=\"settings-input\" id=\"claude-model\" style=\"padding:8px 12px\">") |> ignore
    sb.AppendLine("        <option value=\"claude-opus-4-8\">claude-opus-4-8 (High-Res Vision)</option>") |> ignore
    sb.AppendLine("        <option value=\"claude-fable-5\">claude-fable-5 (High-Res Vision)</option>") |> ignore
    sb.AppendLine("      </select>") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("      <label class=\"settings-label\" style=\"margin-top:12px\">CORS-Proxy URL <span style=\"color:var(--accent-warn)\">(erforderlich für Claude)</span></label>") |> ignore
    sb.AppendLine("      <input class=\"settings-input\" type=\"url\" id=\"claude-proxy\" placeholder=\"https://your-worker.workers.dev\">") |> ignore
    sb.AppendLine("      <p class=\"settings-hint\">") |> ignore
    sb.AppendLine("        Cloudflare Worker als CORS-Pass-Through nötig (Browser blockiert direkte Anthropic-Calls).<br>") |> ignore
    sb.AppendLine("        Anleitung: <a href=\"https://github.com/seveibar/cloudflare-cors-proxy\" target=\"_blank\" style=\"color:var(--accent)\">cloudflare-cors-proxy</a> — kostenlos, 100k Req/Tag Free-Tier.") |> ignore
    sb.AppendLine("      </p>")
