#!/usr/bin/env node
// 3d_053a4a_2780c2.pl — portiert nach javascript
// Quelle: perl5, Projects@abstractions:perl5/3d_053a4a_2780c2.pl
// Erzeugt: 2026-08-18 durch ABSTRACTIONS_MANAGER.py

// 3d_053a4a.tcl — portiert nach perl5
// Quelle: tcl, Projects@abstractions:tcl/3d_053a4a.tcl
// Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

// 3d.html — portiert nach tcl
// Quelle: html, Projects@python-hardener:public/3d.html
// Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

// Tcl 8.6 script to generate 3d.html
// Usage: tclsh this_script.tcl > 3d.html

function generate_html() {
    let html = [];
    
    // DOCTYPE and html tag
    html.push('<!DOCTYPE html>');
    html.push('<html lang="de">');
    
    // Head section
    html.push('<head>');
    html.push('<meta charset="utf-8">');
    html.push('<meta name="viewport" content="width=device-width, initial-scale=1">');
    html.push('<title>Python Hardener — Interaktive Architektur</title>');
    html.push('<meta name="description" content="Der Messplatz: zwei Läufe, dieselben Behauptungen, ein Ergebnis — drehen, zoomen, Knoten auswählen.">');
    html.push('<meta name="theme-color" content="#b45309">');
    
    // CSS styles
    html.push('<style>');
    html.push('  :root{');
    html.push('    --bg:#fbfaf7; --panel:#fff; --line:#e6e3dc; --text:#16191d; --muted:#5f6773;');
    html.push('    --ac:#b45309; --buehne:#0e1420; --buehne-line:#1d2739;');
    html.push('    color-scheme: light;');
    html.push('  }');
    html.push('  @media (prefers-color-scheme: dark){');
    html.push('    :root{ --bg:#0f1115; --panel:#171a21; --line:#262b36; --text:#f2f4f8; --muted:#9aa3b2;');
    html.push('           color-scheme: dark; }');
    html.push('  }');
    html.push('  *{box-sizing:border-box}');
    html.push('  body{margin:0;background:var(--bg);color:var(--text);');
    html.push('       font:15px/1.55 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif}');
    html.push('  .wrap{max-width:1240px;margin:0 auto;padding:34px 22px 60px}');
    html.push('  .technik{font-size:12px;font-weight:700;letter-spacing:.1em;text-transform:uppercase;');
    html.push('           color:var(--ac);margin:0 0 10px}');
    html.push('  h1{font-size:clamp(30px,5vw,52px);line-height:1.05;margin:0 0 14px;letter-spacing:-.03em}');
    html.push('  .lede{font-size:16.5px;color:var(--muted);max-width:62ch;margin:0 0 26px}');
    html.push('  .raster{display:grid;grid-template-columns:minmax(0,1fr) 288px;gap:18px;align-items:start}');
    html.push('  @media (max-width:880px){ .raster{grid-template-columns:1fr} }');
    html.push('  .buehne{position:relative;background:var(--buehne);border-radius:14px;overflow:hidden;');
    html.push('          min-height:520px;aspect-ratio:16/11}');
    html.push('  .buehne canvas{display:block;width:100%;height:100%}');
    html.push('  .knoepfe{position:absolute;top:14px;right:14px;display:flex;gap:8px;z-index:2}');
    html.push('  button{font:inherit;font-size:14px;font-weight:650;padding:9px 14px;border-radius:9px;');
    html.push('         border:1px solid var(--line);background:var(--panel);color:var(--text);cursor:pointer}');
    html.push('  button:hover{border-color:var(--ac)}');
    html.push('  button[aria-pressed="true"]{background:var(--ac);border-color:var(--ac);color:#fff}');
    html.push('  .karte{background:var(--panel);border:1px solid var(--line);border-radius:14px;padding:20px}');
    html.push('  .karte h2{font-size:11px;font-weight:700;letter-spacing:.09em;text-transform:uppercase;');
    html.push('            color:var(--muted);margin:0 0 12px}');
    html.push('  .karte h3{font-size:23px;margin:0 0 4px;letter-spacing:-.02em}');
    html.push('  .karte .sub{color:var(--muted);margin:0 0 18px;font-size:14.5px}');
    html.push('  .feld{border-top:1px solid var(--line);padding:12px 0 0;margin:0 0 12px}');
    html.push('  .feld dt{font-size:11px;font-weight:700;letter-spacing:.08em;text-transform:uppercase;');
    html.push('           color:var(--muted);margin:0 0 3px}');
    html.push('  .feld dd{margin:0;font-weight:650}');
    html.push('  .blaettern{display:flex;gap:8px;margin-top:16px}');
    html.push('  .blaettern button{flex:1;text-align:center;line-height:1.25;padding:11px 8px}');
    html.push('  .legende{display:flex;gap:22px;flex-wrap:wrap;margin:16px 0 0;font-size:13.5px;color:var(--muted)}');
    html.push('  .legende span{display:inline-flex;align-items:center;gap:9px}');
    html.push('  .strich{width:30px;height:0;border-top-width:3px;border-top-style:solid;display:inline-block}');
    html.push('  .fuss{margin:14px 0 0;font-size:13px;color:var(--muted);max-width:80ch}');
    html.push('  .fehler{padding:40px;text-align:center;color:var(--muted)}');
    html.push('  a{color:var(--ac)}');
    html.push('}');
    html.push('</style>');
    html.push('</head>');
    
    // Body section
    html.push('<body>');
    html.push('<div class="wrap">');
    
    html.push('<p class="technik">three.js · r128</p>');
    html.push('<h1>Python Hardener</h1>');
    html.push('<p class="lede">Der Messplatz: zwei Läufe, dieselben Behauptungen, ein Ergebnis — drehen, zoomen, Knoten auswählen.</p>');
    
    html.push('<div class="raster">');
    html.push('<div class="buehne" id="buehne">');
    html.push('<div class="knoepfe">');
    html.push('<button id="btn-plus" title="Näher">+</button>');
    html.push('<button id="btn-minus" title="Weiter weg">−</button>');
    html.push('<button id="btn-reset">Zurücksetzen</button>');
    html.push('<button id="btn-iso" aria-pressed="true" title="Isometrisch oder perspektivisch">Iso</button>');
    html.push('</div>');
    html.push('</div>');
    
    html.push('<aside class="karte">');
    html.push('<h2>Ausgewählter Knoten</h2>');
    html.push('<h3 id="k-name">—</h3>');
    html.push('<p class="sub" id="k-sub">Knoten anklicken oder durchblättern</p>');
    html.push('<dl class="feld"><dt>Schicht</dt><dd id="k-schicht">—</dd></dl>');
    html.push('<dl class="feld"><dt>ID</dt><dd id="k-id">—</dd></dl>');
    html.push('<div class="blaettern">');
    html.push('<button id="btn-prev">←<br>Vorheriger</button>');
    html.push('<button id="btn-next">Nächster<br>→</button>');
    html.push('</div>');
    html.push('</aside>');
    html.push('</div>');
    
    html.push('<div class="legende" id="legende"></div>');
    html.push('<p class="fuss">Schematische Dokumentationsansicht — Blockgrößen messen weder Datenmenge noch Leistung. Keine Telemetrie, keine Fernabfragen: Die Seite lädt einmalig three.js vom CDN und rechnet danach ausschließlich lokal.</p>');
    
    html.push('</div>');
    
    // External script
    html.push('<script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>');
    
    // Inline script
    html.push('<script>');
    html.push('(function(){');
    html.push('  "use strict";');
    html.push('  var SPEC = {"schichten": [{"name": "Eingaben", "farbe": "#5f6773", "blocks": [{"id": "job-runner-py", "name": "job_runner.py", "untertitel": "Cronjob"}, {"id": "report-db-py", "name": "report_db.py", "untertitel": "SQL"}]}, {"name": "Laeufe", "farbe": "#2481cc", "blocks": [{"id": "with-skill", "name": "with_skill", "untertitel": "mit Skill"}, {"id": "without-skill", "name": "without_skill", "untertitel": "Gegenprobe"}]}, {"name": "Pruefung", "farbe": "#6d5bd0", "blocks": [{"id": "ast-assertions", "name": "AST-Assertions", "untertitel": "Syntaxbaum"}, {"id": "not-contains", "name": "not_contains", "untertitel": "Textregel"}, {"id": "grading", "name": "Grading", "untertitel": "je Behauptung"}]}, {"name": "Ergebnis", "farbe": "#b45309", "blocks": [{"id": "benchmark-json", "name": "benchmark.json", "untertitel": "pass_rate"}, {"id": "timing-json", "name": "timing.json", "untertitel": "Laufzeit"}, {"id": "eval-review-html", "name": "eval-review.html", "untertitel": "Gegenueberstellung"}]}], "kanten": [{"von": "job-runner-py", "nach": "with-skill", "art": "fluss"}, {"von": "report-db-py", "nach": "without-skill", "art": "fluss"}, {"von": "with-skill", "nach": "ast-assertions", "art": "fluss"}, {"von": "without-skill", "nach": "not-contains", "art": "fluss"}, {"von": "ast-assertions", "nach": "benchmark-json", "art": "fluss"}, {"von": "not-contains", "nach": "timing-json", "art": "fluss"}, {"von": "grading", "nach": "eval-review-html", "art": "fluss"}], "kantenarten": [{"art": "fluss", "farbe": "#b45309", "stil": "voll", "text": "Fluss von unten nach oben"}]};');
    html.push('');
    html.push('  var buehne = document.getElementById("buehne");');
    html.push('  if (typeof THREE === "undefined"){');
    html.push('    buehne.insertAdjacentHTML("beforeend",');
    html.push('      \'<div class="fehler">three.js konnte nicht geladen werden. \' +');
    html.push('      \'Die Seite braucht einmalig Netzzugang zum CDN.</div>\');');
    html.push('    return;');
    html.push('  }');
    html.push('');
    html.push('  // ---------------------------------------------------------------- Szene ---');
    html.push('  var szene = new THREE.Scene();');
    html.push('  szene.background = new THREE.Color(0x0e1420);');
    html.push('  var renderer = new THREE.WebGLRenderer({antialias:true});');
    html.push('  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));');
    html.push('  buehne.appendChild(renderer.domElement);');
    html.push('');
    html.push('  var D = 26, radius = 82, aspekt = 1;');
    html.push('  var kameraIso = new THREE.OrthographicCamera(-D, D, D, -D, 0.1, 600);');
    html.push('  var kameraPersp = new THREE.PerspectiveCamera(42, 1, 0.1, 600);');
    html.push('  var kamera = kameraIso, iso = true;');
    html.push('');
    html.push('  szene.add(new THREE.AmbientLight(0xffffff, 0.66));');
    html.push('  var licht = new THREE.DirectionalLight(0xffffff, 0.8);');
    html.push('  licht.position.set(30, 46, 26); szene.add(licht);');
    html.push('  var gegen = new THREE.DirectionalLight(0x8ea2ff, 0.3);');
    html.push('  gegen.position.set(-32, 16, -28); szene.add(gegen);');
    html.push('');
    html.push('  var raster = new THREE.GridHelper(110, 34, 0x25324a, 0x1a2333);');
    html.push('  raster.position.y = -24; szene.add(raster);');
    html.push('');
    html.push('  // ------------------------------------------------------------ Schilder ---');
    html.push('  // Text auf eine Textur, dann als Billboard — bleibt bei jeder Drehung lesbar.');
    html.push('  function schild(text, unter){');
    html.push('    var c = document.createElement("canvas"), x = c.getContext("2d");');
    html.push('    var f1 = "700 40px -apple-system,Segoe UI,Roboto,sans-serif";');
    html.push('    var f2 = "500 27px -apple-system,Segoe UI,Roboto,sans-serif";');
    html.push('    x.font = f1; var w1 = x.measureText(text).width;');
    html.push('    x.font = f2; var w2 = unter ? x.measureText(unter).width : 0;');
    html.push('    var w = Math.ceil(Math.max(w1, w2)) + 40, h = unter ? 96 : 62;');
    html.push('    c.width = w; c.height = h;');
    html.push('    x = c.getContext("2d");');
    html.push('    x.fillStyle = "rgba(255,255,255,.95)";');
    html.push('    if (x.roundRect){ x.beginPath(); x.roundRect(0,0,w,h,13); x.fill(); }');
    html.push('    else x.fillRect(0,0,w,h);');
    html.push('    x.fillStyle = "#16191d"; x.font = f1; x.textBaseline = "middle";');
    html.push('    x.fillText(text, 20, unter ? 32 : 31);');
    html.push('    if (unter){ x.fillStyle = "#5f6773"; x.font = f2; x.fillText(unter, 20, 68); }');
    html.push('    var t = new THREE.CanvasTexture(c); t.minFilter = THREE.LinearFilter;');
    html.push('    var s = new THREE.Sprite(new THREE.SpriteMaterial({map:t, transparent:true, depthTest:false}));');
    html.push('    s.scale.set(w/62*2.5, h/62*2.5, 1);');
    html.push('    s.renderOrder = 999;');
    html.push('    return s;');
    html.push('  }');
    html.push('');
    html.push('  // -------------------------------------------------------------- Aufbau ---');
    html.push('  var BW = 7.4, BD = 4.2, BH = 1.7, LUFT = 1.3, ABSTAND = 11.4, START = -17;');
    html.push('  var knoten = [], nachId = {}, klickbar = [];');
    html.push('  var gruppe = new THREE.Group();');
    html.push('');
    html.push('  SPEC.schichten.forEach(function(sch, si){');
    html.push('    var y = START + si * ABSTAND;');
    html.push('    var bl = sch.blocks.map(function(b){');
    html.push('      return (typeof b === "string") ? {id:null, name:b, untertitel:""} : b;');
    html.push('    });');
    html.push('    var spalten = Math.max(1, Math.ceil(bl.length / 2));');
    html.push('    var reihen = bl.length <= 1 ? 1 : 2;');
    html.push('    var gx = spalten*BW + (spalten-1)*LUFT, gz = reihen*BD + (reihen-1)*LUFT;');
    html.push('');
    html.push('    var platte = new THREE.Mesh(');
    html.push('      new THREE.BoxGeometry(gx+3, 0.6, gz+3),');
    html.push('      new THREE.MeshLambertMaterial({color:new THREE.Color(sch.farbe).multiplyScalar(0.4)}));');
    html.push('    platte.position.set(0, y-1.7, 0); gruppe.add(platte);');
    html.push('');
    html.push('    bl.forEach(function(b, i){');
    html.push('      var sp = i % spalten, re = Math.floor(i / spalten);');
    html.push('      var x = -gx/2 + BW/2 + sp*(BW+LUFT), z = -gz/2 + BD/2 + re*(BD+LUFT);');
    html.push('      var mat = new THREE.MeshLambertMaterial({color:sch.farbe});');
    html.push('      var m = new THREE.Mesh(new THREE.BoxGeometry(BW, BH, BD), mat);');
    html.push('      m.position.set(x, y, z);');
    html.push('      gruppe.add(m); klickbar.push(m);');
    html.push('      var kante = new THREE.LineSegments(new THREE.EdgesGeometry(m.geometry),');
    html.push('        new THREE.LineBasicMaterial({color:0x0e1420, transparent:true, opacity:.55}));');
    html.push('      kante.position.copy(m.position); gruppe.add(kante);');
    html.push('');
    html.push('      var s = schild(b.name, b.untertitel);');
    html.push('      s.position.set(x, y + BH/2 + (b.untertitel ? 2.1 : 1.6), z);');
    html.push('      gruppe.add(s);');
    html.push('');
    html.push('      var id = b.id || (b.name.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, ""));');
    html.push('      var eintrag = {id:id, name:b.name, untertitel:b.untertitel||"", schicht:sch.name,');
    html.push('                     mesh:m, mat:mat, farbe:new THREE.Color(sch.farbe), pos:m.position};');
    html.push('      m.userData.index = knoten.length;');
    html.push('      knoten.push(eintrag); nachId[id] = eintrag;');
    html.push('    });');
    html.push('  });');
    html.push('');
    html.push('  // -------------------------------------------------------------- Kanten ---');
    html.push('  var STIL = {};');
    html.push('  (SPEC.kantenarten || []).forEach(function(a){ STIL[a.art] = a; });');
    html.push('');
    html.push('  (SPEC.kanten || []).forEach(function(k){');
    html.push('    var a = nachId[k.von], b = nachId[k.nach];');
    html.push('    if (!a || !b) return;');
    html.push('    var art = STIL[k.art] || {farbe:"#8ea2ff", stil:"voll"};');
    html.push('    var g = new THREE.BufferGeometry().setFromPoints([');
    html.push('      a.pos.clone().setY(a.pos.y + 0.9), b.pos.clone().setY(b.pos.y - 0.9)]);');
    html.push('    var linie;');
    html.push('    if (art.stil === "gestrichelt"){');
    html.push('      linie = new THREE.Line(g, new THREE.LineDashedMaterial(');
    html.push('        {color:art.farbe, dashSize:1.4, gapSize:1.0, transparent:true, opacity:.9}));');
    html.push('      linie.computeLineDistances();');
    html.push('    } else {');
    html.push('      linie = new THREE.Line(g, new THREE.LineBasicMaterial(');
    html.push('        {color:art.farbe, transparent:true, opacity:.85}));');
    html.push('    }');
    html.push('    gruppe.add(linie);');
    html.push('  });');
    html.push('');
    html.push('  szene.add(gruppe);');
    html.push('');
    html.push('  var leg = document.getElementById("legende");');
    html.push('  (SPEC.kantenarten || []).forEach(function(a){');
    html.push('    var s = document.createElement("span");');
    html.push('    s.innerHTML = \'<i class="strich" style="border-top-color:\' + a.farbe +');
    html.push('                  \';border-top-style:\' + (a.stil === "gestrichelt" ? "dashed" : "solid") +');
    html.push('                  \'"></i>\' + a.text;');
    html.push('    leg.appendChild(s);');
    html.push('  });');
    html.push('');
    html.push('  // ------------------------------------------------------------- Auswahl ---');
    html.push('  var aktiv = -1;');
    html.push('  function waehle(i){');
    html.push('    if (aktiv >= 0){');
    html.push('      knoten[aktiv].mat.color.copy(knoten[aktiv].farbe);');
    html.push('      knoten[aktiv].mat.emissive.setHex(0x000000);');
    html.push('      knoten[aktiv].mesh.scale.set(1,1,1);');
    html.push('    }');
    html.push('    aktiv = ((i % knoten.length) + knoten.length) % knoten.length;');
    html.push('    var k = knoten[aktiv];');
    html.push('    k.mat.emissive.setHex(0x333333);');
    html.push('    k.mesh.scale.set(1.1, 1.5, 1.1);');
    html.push('    document.getElementById("k-name").textContent = k.name;');
    html.push('    document.getElementById("k-sub").textContent = k.untertitel || "—";');
    html.push('    document.getElementById("k-schicht").textContent = k.schicht;');
    html.push('    document.getElementById("k-id").textContent = k.id;');
    html.push('  }');
    html.push('');
    html.push('  var strahl = new THREE.Raycaster(), zeiger = new THREE.Vector2();');
    html.push('  renderer.domElement.addEventListener("click", function(e){');
    html.push('    if (gezogen) return;');
    html.push('    var r = renderer.domElement.getBoundingClientRect();');
    html.push('    zeiger.x = ((e.clientX - r.left) / r.width) * 2 - 1;');
    html.push('    zeiger.y = -((e.clientY - r.top) / r.height) * 2 + 1;');
    html.push('    strahl.setFromCamera(zeiger, kamera);');
    html.push('    var treffer = strahl.intersectObjects(klickbar, false);');
    html.push('    if (treffer.length) waehle(treffer[0].object.userData.index);');
    html.push('  });');
    html.push('  document.getElementById("btn-prev").addEventListener("click", function(){ waehle(aktiv - 1); });');
    html.push('  document.getElementById("btn-next").addEventListener("click", function(){ waehle(aktiv + 1); });');
    html.push('');
    html.push('  // ------------------------------------------------------------- Kamera ----');
    html.push('  var azimut = Math.PI/4, elevation = 0.62, rotiert = true;');
    html.push('  function stelle(){');
    html.push('    var x = radius*Math.cos(elevation)*Math.sin(azimut);');
    html.push('    var y = radius*Math.sin(elevation);');
    html.push('    var z = radius*Math.cos(elevation)*Math.cos(azimut);');
    html.push('    kamera.position.set(x, y, z); kamera.lookAt(0, 0, 0);');
    html.push('  }');
    html.push('  var zieht = false, gezogen = false, lx = 0, ly = 0;');
    html.push('  renderer.domElement.addEventListener("pointerdown", function(e){');
    html.push('    zieht = true; gezogen = false; lx = e.clientX; ly = e.clientY;');
    html.push('  });');
    html.push('  window.addEventListener("pointermove", function(e){');
    html.push('    if (!zieht) return;');
    html.push('    if (Math.abs(e.clientX-lx) + Math.abs(e.clientY-ly) > 3){ gezogen = true; rotiert = false; }');
    html.push('    azimut -= (e.clientX - lx) * 0.006;');
    html.push('    elevation = Math.max(0.08, Math.min(1.45, elevation + (e.clientY - ly) * 0.005));');
    html.push('    lx = e.clientX; ly = e.clientY;');
    html.push('  });');
    html.push('  window.addEventListener("pointerup", function(){ zieht = false; setTimeout(function(){ gezogen = false; }, 0); });');
    html.push('');
    html.push('  function zoom(f){');
    html.push('    if (iso){ D = Math.max(11, Math.min(54, D * f)); groesse(); }');
    html.push('    else { radius = Math.max(32, Math.min(160, radius * f)); }');
    html.push('  }');
    html.push('  document.getElementById("btn-plus").addEventListener("click", function(){ zoom(0.85); });');
    html.push('  document.getElementById("btn-minus").addEventListener("click", function(){ zoom(1.18); });');
    html.push('  renderer.domElement.addEventListener("wheel", function(e){');
    html.push('    e.preventDefault(); zoom(e.deltaY > 0 ? 1.08 : 0.93);');
    html.push('  }, {passive:false});');
    html.push('  document.getElementById("btn-reset").addEventListener("click", function(){');
    html.push('    azimut = Math.PI/4; elevation = 0.62; D = 26; radius = 82; rotiert = true;');
    html.push('    iso = true; kamera = kameraIso;');
    html.push('    document.getElementById("btn-iso").setAttribute("aria-pressed", "true");');
    html.push('    document.getElementById("btn-iso").textContent = "Iso";');
    html.push('    waehle(0); groesse();');
    html.push('  });');
    html.push('  document.getElementById("btn-iso").addEventListener("click", function(){');
    html.push('    iso = !iso; kamera = iso ? kameraIso : kameraPersp;');
    html.push('    this.setAttribute("aria-pressed", String(iso));');
    html.push('    this.textContent = iso ? "Iso" : "Persp";');
    html.push('    groesse();');
    html.push('  });');
    html.push('');
    html.push('  function groesse(){');
    html.push('    var w = buehne.clientWidth, h = buehne.clientHeight;');
    html.push('    aspekt = w / h;');
    html.push('    kameraIso.left = -D*aspekt; kameraIso.right = D*aspekt;');
    html.push('    kameraIso.top = D; kameraIso.bottom = -D; kameraIso.updateProjectionMatrix();');
    html.push('    kameraPersp.aspect = aspekt; kameraPersp.updateProjectionMatrix();');
    html.push('    renderer.setSize(w, h, false);');
    html.push('  }');
    html.push('  window.addEventListener("resize", groesse);');
    html.push('');
    html.push('  groesse();');
    html.push('  waehle(0);');
    html.push('  (function schleife(){');
    html.push('    requestAnimationFrame(schleife);');
    html.push('    if (rotiert) azimut += 0.003;');
    html.push('    stelle();');
    html.push('    renderer.render(szene, kamera);');
    html.push('  })();');
    html.push('})();');
    html.push('</script>');
    html.push('</body>');
    html.push('</html>');
    
    // Join all lines with newlines
    return html.join("\n");
}

// Main execution
console.log(generate_html());
