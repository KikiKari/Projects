#!/bin/bash
# 3d.js — portiert nach shell
# Quelle: javascript, Projects@abstractions:javascript/3d.js
# Erzeugt: 2026-08-18 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# 3d.html — portiert nach bash
# Quelle: html, Projects@tagesstatus-live-public:public/3d.html
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

# Prüfe, ob ein Dateiname übergeben wurde
if [ $# -lt 1 ]; then
    echo "Verwendung: $0 <dateiname>" >&2
    exit 1
fi

filename="$1"

# Erstelle das HTML-Dokument
cat > "$filename" << 'EOF'
<!DOCTYPE html>
<html lang="de">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Tagesstatus Live Public — Interaktive Architektur</title>
<meta name="description" content="Acht Dienste, ein Blick: Tokens, Abruf, Kacheln — drehen, zoomen, Knoten auswählen.">
<meta name="theme-color" content="#0f766e">
<style>
:root{
  --bg:#fbfaf7; --panel:#fff; --line:#e6e3dc; --text:#16191d; --muted:#5f6773;
  --ac:#0f766e; --buehne:#0e1420; --buehne-line:#1d2739;
  color-scheme: light;
}
@media (prefers-color-scheme: dark){
  :root{ --bg:#0f1115; --panel:#171a21; --line:#262b36; --text:#f2f4f8; --muted:#9aa3b2;
         color-scheme: dark; }
}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--text);
     font:15px/1.55 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif}
.wrap{max-width:1240px;margin:0 auto;padding:34px 22px 60px}
.technik{font-size:12px;font-weight:700;letter-spacing:.1em;text-transform:uppercase;
         color:var(--ac);margin:0 0 10px}
h1{font-size:clamp(30px,5vw,52px);line-height:1.05;margin:0 0 14px;letter-spacing:-.03em}
.lede{font-size:16.5px;color:var(--muted);max-width:62ch;margin:0 0 26px}
.raster{display:grid;grid-template-columns:minmax(0,1fr) 288px;gap:18px;align-items:start}
@media (max-width:880px){ .raster{grid-template-columns:1fr} }
.buehne{position:relative;background:var(--buehne);border-radius:14px;overflow:hidden;
        min-height:520px;aspect-ratio:16/11}
.buehne canvas{display:block;width:100%;height:100%}
.knoepfe{position:absolute;top:14px;right:14px;display:flex;gap:8px;z-index:2}
button{font:inherit;font-size:14px;font-weight:650;padding:9px 14px;border-radius:9px;
       border:1px solid var(--line);background:var(--panel);color:var(--text);cursor:pointer}
button:hover{border-color:var(--ac)}
button[aria-pressed="true"]{background:var(--ac);border-color:var(--ac);color:#fff}
.karte{background:var(--panel);border:1px solid var(--line);border-radius:14px;padding:20px}
.karte h2{font-size:11px;font-weight:700;letter-spacing:.09em;text-transform:uppercase;
          color:var(--muted);margin:0 0 12px}
.karte h3{font-size:23px;margin:0 0 4px;letter-spacing:-.02em}
.karte .sub{color:var(--muted);margin:0 0 18px;font-size:14.5px}
.feld{border-top:1px solid var(--line);padding:12px 0 0;margin:0 0 12px}
.feld dt{font-size:11px;font-weight:700;letter-spacing:.08em;text-transform:uppercase;
         color:var(--muted);margin:0 0 3px}
.feld dd{margin:0;font-weight:650}
.blaettern{display:flex;gap:8px;margin-top:16px}
.blaettern button{flex:1;text-align:center;line-height:1.25;padding:11px 8px}
.legende{display:flex;gap:22px;flex-wrap:wrap;margin:16px 0 0;font-size:13.5px;color:var(--muted)}
.legende span{display:inline-flex;align-items:center;gap:9px}
.strich{width:30px;height:0;border-top-width:3px;border-top-style:solid;display:inline-block}
.fuss{margin:14px 0 0;font-size:13px;color:var(--muted);max-width:80ch}
.fehler{padding:40px;text-align:center;color:var(--muted)}
a{color:var(--ac)}
</style>
</head>
<body>
<div class="wrap">
<p class="technik">three.js · r128</p>
<h1>Tagesstatus Live Public</h1>
<p class="lede">Acht Dienste, ein Blick: Tokens, Abruf, Kacheln — drehen, zoomen, Knoten auswählen.</p>
<div class="raster">
<div class="buehne" id="buehne">
<div class="knoepfe">
<button id="btn-plus" title="Näher">+</button>
<button id="btn-minus" title="Weiter weg">−</button>
<button id="btn-reset">Zurücksetzen</button>
<button id="btn-iso" aria-pressed="true" title="Isometrisch oder perspektivisch">Iso</button>
</div>
</div>
<aside class="karte">
<h2>Ausgewählter Knoten</h2>
<h3 id="k-name">—</h3>
<p class="sub" id="k-sub">Knoten anklicken oder durchblättern</p>
<dl class="feld">
<dt>Schicht</dt>
<dd id="k-schicht">—</dd>
</dl>
<dl class="feld">
<dt>ID</dt>
<dd id="k-id">—</dd>
</dl>
<div class="blaettern">
<button id="btn-prev">←<br>Vorheriger</button>
<button id="btn-next">Nächster<br>→</button>
</div>
</aside>
</div>
<div class="legende" id="legende"></div>
<p class="fuss">Schematische Dokumentationsansicht — Blockgrößen messen weder Datenmenge noch Leistung. Keine Telemetrie, keine Fernabfragen: Die Seite lädt einmalig three.js vom CDN und rechnet danach ausschließlich lokal.</p>
</div>
<script>
// Hauptfunktion zur Erstellung der 3D-Szene
function create3DScene() {
  const SPEC = {
    "schichten": [
      {
        "name": "Tokens",
        "farbe": "#5f6773",
        "blocks": [
          {"id": "abfrage-beim-oeffnen", "name": "Abfrage beim Oeffnen", "untertitel": "kein Vorbelegen"},
          {"id": "localstorage", "name": "localStorage", "untertitel": "nur lokal"},
          {"id": "keine-vorbelegung", "name": "keine Vorbelegung", "untertitel": "leer geliefert"}
        ]
      },
      {
        "name": "Quellen",
        "farbe": "#2481cc",
        "blocks": [
          {"id": "github", "name": "GitHub", "untertitel": "Repos, Kontingent"},
          {"id": "vercel", "name": "Vercel", "untertitel": "Deployments"},
          {"id": "docker-hub", "name": "Docker Hub", "untertitel": "Abbilder"},
          {"id": "openrouter", "name": "OpenRouter", "untertitel": "Guthaben"},
          {"id": "openai", "name": "OpenAI", "untertitel": "Admin-Key"},
          {"id": "anthropic", "name": "Anthropic", "untertitel": "Admin-Key"},
          {"id": "tailscale", "name": "Tailscale", "untertitel": "Geraete"},
          {"id": "clawhub", "name": "ClawHub", "untertitel": "Skills"}
        ]
      },
      {
        "name": "Abruf",
        "farbe": "#6d5bd0",
        "blocks": [
          {"id": "fetch-je-quelle", "name": "fetch je Quelle", "untertitel": "direkt"},
          {"id": "cors-pruefung", "name": "CORS-Pruefung", "untertitel": "entscheidet"},
          {"id": "fehler-isolieren", "name": "Fehler isolieren", "untertitel": "je Kachel"}
        ]
      },
      {
        "name": "Ausgabe",
        "farbe": "#0f766e",
        "blocks": [
          {"id": "kacheln", "name": "Kacheln", "untertitel": "ein Blick"},
          {"id": "verbrauch", "name": "Verbrauch", "untertitel": "Zahlen"},
          {"id": "keine-daten-hinweis", "name": "keine Daten = Hinweis", "untertitel": "mit Grund"}
        ]
      }
    ],
    "kanten": [
      {"von": "abfrage-beim-oeffnen", "nach": "github", "art": "fluss"},
      {"von": "localstorage", "nach": "vercel", "art": "fluss"},
      {"von": "keine-vorbelegung", "nach": "docker-hub", "art": "fluss"},
      {"von": "github", "nach": "fetch-je-quelle", "art": "fluss"},
      {"von": "vercel", "nach": "cors-pruefung", "art": "fluss"},
      {"von": "docker-hub", "nach": "fehler-isolieren", "art": "fluss"},
      {"von": "openrouter", "nach": "fetch-je-quelle", "art": "fluss"},
      {"von": "openai", "nach": "cors-pruefung", "art": "fluss"},
      {"von": "anthropic", "nach": "fehler-isolieren", "art": "fluss"},
      {"von": "tailscale", "nach": "fetch-je-quelle", "art": "fluss"},
      {"von": "clawhub", "nach": "cors-pruefung", "art": "fluss"},
      {"von": "fetch-je-quelle", "nach": "kacheln", "art": "fluss"},
      {"von": "cors-pruefung", "nach": "verbrauch", "art": "fluss"},
      {"von": "fehler-isolieren", "nach": "keine-daten-hinweis", "art": "fluss"}
    ],
    "kantenarten": [
      {"art": "fluss", "farbe": "#0f766e", "stil": "voll", "text": "Fluss von unten nach oben"}
    ]
  };

  // Erstelle das Canvas-Element
  const canvas = document.createElement('canvas');
  canvas.width = 800;
  canvas.height = 600;
  canvas.style.display = 'block';
  canvas.style.width = '100%';
  canvas.style.height = '100%';

  // Füge das Canvas zur Bühne hinzu
  const buehne = document.getElementById('buehne');
  buehne.appendChild(canvas);

  // Erstelle die Three.js Szene
  const scene = new THREE.Scene();
  scene.background = new THREE.Color(0x0e1420);

  const renderer = new THREE.WebGLRenderer({ canvas: canvas, antialias: true });
  renderer.setPixelRatio(Math.min(2, 2));
  renderer.setSize(canvas.width, canvas.height);

  const D = 26, radius = 82;
  const cameraIso = new THREE.OrthographicCamera(-D, D, D, -D, 0.1, 600);
  const cameraPersp = new THREE.PerspectiveCamera(42, 1, 0.1, 600);
  let camera = cameraIso, iso = true;

  scene.add(new THREE.AmbientLight(0xffffff, 0.66));
  const light = new THREE.DirectionalLight(0xffffff, 0.8);
  light.position.set(30, 46, 26);
  scene.add(light);
  const against = new THREE.DirectionalLight(0x8ea2ff, 0.3);
  against.position.set(-32, 16, -28);
  scene.add(against);

  const grid = new THREE.GridHelper(110, 34, 0x25324a, 0x1a2333);
  grid.position.y = -24;
  scene.add(grid);

  // Funktion zum Erstellen von Schildern
  function createSign(text, subtitle) {
    const canvas = document.createElement("canvas");
    const ctx = canvas.getContext("2d");
    const font1 = "700 40px -apple-system,Segoe UI,Roboto,sans-serif";
    const font2 = "500 27px -apple-system,Segoe UI,Roboto,sans-serif";
    ctx.font = font1;
    const w1 = ctx.measureText(text).width;
    ctx.font = font2;
    const w2 = subtitle ? ctx.measureText(subtitle).width : 0;
    const w = Math.ceil(Math.max(w1, w2)) + 40;
    const h = subtitle ? 96 : 62;
    canvas.width = w;
    canvas.height = h;
    const ctx2 = canvas.getContext("2d");
    ctx2.fillStyle = "rgba(255,255,255,.95)";
    if (ctx2.roundRect) {
      ctx2.beginPath();
      ctx2.roundRect(0, 0, w, h, 13);
      ctx2.fill();
    } else {
      ctx2.fillRect(0, 0, w, h);
    }
    ctx2.fillStyle = "#16191d";
    ctx2.font = font1;
    ctx2.textBaseline = "middle";
    ctx2.fillText(text, 20, subtitle ? 32 : 31);
    if (subtitle) {
      ctx2.fillStyle = "#5f6773";
      ctx2.font = font2;
      ctx2.fillText(subtitle, 20, 68);
    }
    const texture = new THREE.CanvasTexture(canvas);
    texture.minFilter = THREE.LinearFilter;
    const material = new THREE.SpriteMaterial({ map: texture, transparent: true, depthTest: false });
    const sprite = new THREE.Sprite(material);
    sprite.scale.set(w / 62 * 2.5, h / 62 * 2.5, 1);
    sprite.renderOrder = 999;
    return sprite;
  }

  // Aufbau der Szene
  const BW = 7.4, BD = 4.2, BH = 1.7, LUFT = 1.3, ABSTAND = 11.4, START = -17;
  const nodes = [], byId = {}, clickable = [];
  const group = new THREE.Group();

  SPEC.schichten.forEach((sch, si) => {
    const y = START + si * ABSTAND;
    const blocks = sch.blocks.map(b => {
      return (typeof b === "string") ? { id: null, name: b, untertitel: "" } : b;
    });
    const columns = Math.max(1, Math.ceil(blocks.length / 2));
    const rows = blocks.length <= 1 ? 1 : 2;
    const gx = columns * BW + (columns - 1) * LUFT;
    const gz = rows * BD + (rows - 1) * LUFT;

    const plate = new THREE.Mesh(
      new THREE.BoxGeometry(gx + 3, 0.6, gz + 3),
      new THREE.MeshLambertMaterial({ color: new THREE.Color(sch.farbe).multiplyScalar(0.4) })
    );
    plate.position.set(0, y - 1.7, 0);
    group.add(plate);

    blocks.forEach((b, i) => {
      const col = i % columns;
      const row = Math.floor(i / columns);
      const x = -gx / 2 + BW / 2 + col * (BW + LUFT);
      const z = -gz / 2 + BD / 2 + row * (BD + LUFT);
      const material = new THREE.MeshLambertMaterial({ color: sch.farbe });
      const mesh = new THREE.Mesh(new THREE.BoxGeometry(BW, BH, BD), material);
      mesh.position.set(x, y, z);
      group.add(mesh);
      clickable.push(mesh);
      const edges = new THREE.LineSegments(
        new THREE.EdgesGeometry(mesh.geometry),
        new THREE.LineBasicMaterial({ color: 0x0e1420, transparent: true, opacity: 0.55 })
      );
      edges.position.copy(mesh.position);
      group.add(edges);

      const sign = createSign(b.name, b.untertitel);
      sign.position.set(x, y + BH / 2 + (b.untertitel ? 2.1 : 1.6), z);
      group.add(sign);

      const id = b.id || (b.name.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, ""));
      const entry = {
        id: id,
        name: b.name,
        untertitel: b.untertitel || "",
        schicht: sch.name,
        mesh: mesh,
        material: material,
        color: new THREE.Color(sch.farbe),
        position: mesh.position
      };
      mesh.userData.index = nodes.length;
      nodes.push(entry);
      byId[id] = entry;
    });
  });

  // Kanten
  const STYLE = {};
  (SPEC.kantenarten || []).forEach(a => {
    STYLE[a.art] = a;
  });

  (SPEC.kanten || []).forEach(k => {
    const a = byId[k.von], b = byId[k.nach];
    if (!a || !b) return;
    const style = STYLE[k.art] || { farbe: "#8ea2ff", stil: "voll" };
    const geometry = new THREE.BufferGeometry().setFromPoints([
      a.position.clone().setY(a.position.y + 0.9),
      b.position.clone().setY(b.position.y - 0.9)
    ]);
    let line;
    if (style.stil === "gestrichelt") {
      line = new THREE.Line(geometry, new THREE.LineDashedMaterial({
        color: style.farbe,
        dashSize: 1.4,
        gapSize: 1.0,
        transparent: true,
        opacity: 0.9
      }));
      line.computeLineDistances();
    } else {
      line = new THREE.Line(geometry, new THREE.LineBasicMaterial({
        color: style.farbe,
        transparent: true,
        opacity: 0.85
      }));
    }
    group.add(line);
  });

  scene.add(group);

  // Legende
  const legend = document.getElementById("legende");
  (SPEC.kantenarten || []).forEach(a => {
    const span = document.createElement("span");
    span.innerHTML = `<i class="strich" style="border-top-color:${a.farbe};border-top-style:${a.stil === "gestrichelt" ? "dashed" : "solid"}"></i>${a.text}`;
    legend.appendChild(span);
  });

  // Animationsschleife
  function animate() {
    requestAnimationFrame(animate);
    renderer.render(scene, camera);
  }
  animate();
}

// Lade Three.js und erstelle die Szene
const script = document.createElement('script');
script.src = 'https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js';
script.onload = create3DScene;
document.head.appendChild(script);
</script>
</body>
</html>
EOF

echo "HTML-Datei wurde erfolgreich erstellt: $filename"
