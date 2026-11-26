#!/usr/bin/env tcl
# abstraction-provenance: {"artifact_sha256": "b3b7c42790472747d121dbbbfe79feb28a934724c2061d532c338f9038992447", "source_sha256": "053a4a25365c46b29ec10a81cfe903f6e9ea862724535da32839a93d5c3823f8", "target_language": "tcl"}
# 3d.html — portiert nach tcl
# Quelle: html, Projects@python-hardener:public/3d.html
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# Port of 3d.html to Tcl 8.6
# Generates the HTML file dynamically

proc generate_3d_html {filename} {
    set html [open $filename w]
    
    puts $html {<!DOCTYPE html>}
    puts $html {<html lang="de">}
    puts $html {<head>}
    puts $html {<meta charset="utf-8">}
    puts $html {<meta name="viewport" content="width=device-width, initial-scale=1">}
    puts $html {<title>Python Hardener — Interaktive Architektur</title>}
    puts $html {<meta name="description" content="Der Messplatz: zwei Läufe, dieselben Behauptungen, ein Ergebnis — drehen, zoomen, Knoten auswählen.">}
    puts $html {<meta name="theme-color" content="#b45309">}
    puts $html {<style>}
    puts $html {  :root\{}
    puts $html {    --bg:#fbfaf7; --panel:#fff; --line:#e6e3dc; --text:#16191d; --muted:#5f6773;}
    puts $html {    --ac:#b45309; --buehne:#0e1420; --buehne-line:#1d2739;}
    puts $html {    color-scheme: light;}
    puts $html {  \}}
    puts $html {  @media (prefers-color-scheme: dark)\{}
    puts $html {    :root\{ --bg:#0f1115; --panel:#171a21; --line:#262b36; --text:#f2f4f8; --muted:#9aa3b2;}
    puts $html {           color-scheme: dark; \}}
    puts $html {  \}}
    puts $html {  *\{box-sizing:border-box\}}
    puts $html {  body\{margin:0;background:var(--bg);color:var(--text);}
    puts $html {       font:15px/1.55 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif\}}
    puts $html {  .wrap\{max-width:1240px;margin:0 auto;padding:34px 22px 60px\}}
    puts $html {  .technik\{font-size:12px;font-weight:700;letter-spacing:.1em;text-transform:uppercase;}
    puts $html {           color:var(--ac);margin:0 0 10px\}}
    puts $html {  h1\{font-size:clamp(30px,5vw,52px);line-height:1.05;margin:0 0 14px;letter-spacing:-.03em\}}
    puts $html {  .lede\{font-size:16.5px;color:var(--muted);max-width:62ch;margin:0 0 26px\}}
    puts $html {  .raster\{display:grid;grid-template-columns:minmax(0,1fr) 288px;gap:18px;align-items:start\}}
    puts $html {  @media (max-width:880px)\{ .raster\{grid-template-columns:1fr\} \}}
    puts $html {  .buehne\{position:relative;background:var(--buehne);border-radius:14px;overflow:hidden;}
    puts $html {          min-height:520px;aspect-ratio:16/11\}}
    puts $html {  .buehne canvas\{display:block;width:100%;height:100%\}}
    puts $html {  .knoepfe\{position:absolute;top:14px;right:14px;display:flex;gap:8px;z-index:2\}}
    puts $html {  button\{font:inherit;font-size:14px;font-weight:650;padding:9px 14px;border-radius:9px;}
    puts $html {         border:1px solid var(--line);background:var(--panel);color:var(--text);cursor:pointer\}}
    puts $html {  button:hover\{border-color:var(--ac)\}}
    puts $html {  button[aria-pressed="true"]\{background:var(--ac);border-color:var(--ac);color:#fff\}}
    puts $html {  .karte\{background:var(--panel);border:1px solid var(--line);border-radius:14px;padding:20px\}}
    puts $html {  .karte h2\{font-size:11px;font-weight:700;letter-spacing:.09em;text-transform:uppercase;}
    puts $html {            color:var(--muted);margin:0 0 12px\}}
    puts $html {  .karte h3\{font-size:23px;margin:0 0 4px;letter-spacing:-.02em\}}
    puts $html {  .karte .sub\{color:var(--muted);margin:0 0 18px;font-size:14.5px\}}
    puts $html {  .feld\{border-top:1px solid var(--line);padding:12px 0 0;margin:0 0 12px\}}
    puts $html {  .feld dt\{font-size:11px;font-weight:700;letter-spacing:.08em;text-transform:uppercase;}
    puts $html {           color:var(--muted);margin:0 0 3px\}}
    puts $html {  .feld dd\{margin:0;font-weight:650\}}
    puts $html {  .blaettern\{display:flex;gap:8px;margin-top:16px\}}
    puts $html {  .blaettern button\{flex:1;text-align:center;line-height:1.25;padding:11px 8px\}}
    puts $html {  .legende\{display:flex;gap:22px;flex-wrap:wrap;margin:16px 0 0;font-size:13.5px;color:var(--muted)\}}
    puts $html {  .legende span\{display:inline-flex;align-items:center;gap:9px\}}
    puts $html {  .strich\{width:30px;height:0;border-top-width:3px;border-top-style:solid;display:inline-block\}}
    puts $html {  .fuss\{margin:14px 0 0;font-size:13px;color:var(--muted);max-width:80ch\}}
    puts $html {  .fehler\{padding:40px;text-align:center;color:var(--muted)\}}
    puts $html {  a\{color:var(--ac)\}}
    puts $html {</style>}
    puts $html {</head>}
    puts $html {<body>}
    puts $html {<div class="wrap">}
    puts $html {}
    puts $html {  <p class="technik">three.js · r128</p>}
    puts $html {  <h1>Python Hardener</h1>}
    puts $html {  <p class="lede">Der Messplatz: zwei Läufe, dieselben Behauptungen, ein Ergebnis — drehen, zoomen, Knoten auswählen.</p>}
    puts $html {}
    puts $html {  <div class="raster">}
    puts $html {    <div class="buehne" id="buehne">}
    puts $html {      <div class="knoepfe">}
    puts $html {        <button id="btn-plus" title="Näher">+</button>}
    puts $html {        <button id="btn-minus" title="Weiter weg">−</button>}
    puts $html {        <button id="btn-reset">Zurücksetzen</button>}
    puts $html {        <button id="btn-iso" aria-pressed="true" title="Isometrisch oder perspektivisch">Iso</button>}
    puts $html {      </div>}
    puts $html {    </div>}
    puts $html {}
    puts $html {    <aside class="karte">}
    puts $html {      <h2>Ausgewählter Knoten</h2>}
    puts $html {      <h3 id="k-name">—</h3>}
    puts $html {      <p class="sub" id="k-sub">Knoten anklicken oder durchblättern</p>}
    puts $html {      <dl class="feld"><dt>Schicht</dt><dd id="k-schicht">—</dd></dl>}
    puts $html {      <dl class="feld"><dt>ID</dt><dd id="k-id">—</dd></dl>}
    puts $html {      <div class="blaettern">}
    puts $html {        <button id="btn-prev">←<br>Vorheriger</button>}
    puts $html {        <button id="btn-next">Nächster<br>→</button>}
    puts $html {      </div>}
    puts $html {    </aside>}
    puts $html {  </div>}
    puts $html {}
    puts $html {  <div class="legende" id="legende"></div>}
    puts $html {  <p class="fuss">Schematische Dokumentationsansicht — Blockgrößen messen weder Datenmenge noch Leistung. Keine Telemetrie, keine Fernabfragen: Die Seite lädt einmalig three.js vom CDN und rechnet danach ausschließlich lokal.</p>}
    puts $html {}
    puts $html {</div>}
    puts $html {}
    puts $html {<script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>}
    puts $html {<script>}
    puts $html {(function()\{}
    puts $html {  "use strict";}
    puts $html {  var SPEC = \{"schichten": \[\{"name": "Eingaben", "farbe": "#5f6773", "blocks": \[\{"id": "job-runner-py", "name": "job_runner.py", "untertitel": "Cronjob"\}, \{"id": "report-db-py", "name": "report_db.py", "untertitel": "SQL"\}\]\}, \{"name": "Laeufe", "farbe": "#2481cc", "blocks": \[\{"id": "with-skill", "name": "with_skill", "untertitel": "mit Skill"\}, \{"id": "without-skill", "name": "without_skill", "untertitel": "Gegenprobe"\}\]\}, \{"name": "Pruefung", "farbe": "#6d5bd0", "blocks": \[\{"id": "ast-assertions", "name": "AST-Assertions", "untertitel": "Syntaxbaum"\}, \{"id": "not-contains", "name": "not_contains", "untertitel": "Textregel"\}, \{"id": "grading", "name": "Grading", "untertitel": "je Behauptung"\}\]\}, \{"name": "Ergebnis", "farbe": "#b45309", "blocks": \[\{"id": "benchmark-json", "name": "benchmark.json", "untertitel": "pass_rate"\}, \{"id": "timing-json", "name": "timing.json", "untertitel": "Laufzeit"\}, \{"id": "eval-review-html", "name": "eval-review.html", "untertitel": "Gegenueberstellung"\}\]\]\}, "kanten": \[\{"von": "job-runner-py", "nach": "with-skill", "art": "fluss"\}, \{"von": "report-db-py", "nach": "without-skill", "art": "fluss"\}, \{"von": "with-skill", "nach": "ast-assertions", "art": "fluss"\}, \{"von": "without-skill", "nach": "not-contains", "art": "fluss"\}, \{"von": "ast-assertions", "nach": "benchmark-json", "art": "fluss"\}, \{"von": "not-contains", "nach": "timing-json", "art": "fluss"\}, \{"von": "grading", "nach": "eval-review-html", "art": "fluss"\}\], "kantenarten": \[\{"art": "fluss", "farbe": "#b45309", "stil": "voll", "text": "Fluss von unten nach oben"\}\]\};}
    puts $html {}
    puts $html {  var buehne = document.getElementById("buehne");}
    puts $html {  if (typeof THREE === "undefined"\){}}
    puts $html {    buehne.insertAdjacentHTML("beforeend",}
    puts $html {      '<div class="fehler">three.js konnte nicht geladen werden. ' +}
    puts $html {      'Die Seite braucht einmalig Netzzugang zum CDN.</div>');}
    puts $html {    return;}
    puts $html {  \}}
    puts $html {}
    puts $html {  // ---------------------------------------------------------------- Szene ---}
    puts $html {  var szene = new THREE.Scene();}
    puts $html {  szene.background = new THREE.Color(0x0e1420);}
    puts $html {  var renderer = new THREE.WebGLRenderer(\{antialias:true\});}
    puts $html {  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));}
    puts $html {  buehne.appendChild(renderer.domElement);}
    puts $html {}
    puts $html {  var D = 26, radius = 82, aspekt = 1;}
    puts $html {  var kameraIso = new THREE.OrthographicCamera(-D, D, D, -D, 0.1, 600);}
    puts $html {  var kameraPersp = new THREE.PerspectiveCamera(42, 1, 0.1, 600);}
    puts $html {  var kamera = kameraIso, iso = true;}
    puts $html {}
    puts $html {  szene.add(new THREE.AmbientLight(0xffffff, 0.66));}
    puts $html {  var licht = new THREE.DirectionalLight(0xffffff, 0.8);}
    puts $html {  licht.position.set(30, 46, 26); szene.add(licht);}
    puts $html {  var gegen = new THREE.DirectionalLight(0x8ea2ff, 0.3);}
    puts $html {  gegen.position.set(-32, 16, -28); szene.add(gegen);}
    puts $html {}
    puts $html {  var raster = new THREE.GridHelper(110, 34, 0x25324a, 0x1a2333);}
    puts $html {  raster.position.y = -24; szene.add(raster);}
    puts $html {}
    puts $html {  // ------------------------------------------------------------ Schilder ---}
    puts $html {  // Text auf eine Textur, dann als Billboard — bleibt bei jeder Drehung lesbar.}
    puts $html {  function schild(text, unter)\{}
    puts $html {    var c = document.createElement("canvas"), x = c.getContext("2d");}
    puts $html {    var f1 = "700 40px -apple-system,Segoe UI,Roboto,sans-serif";}
    puts $html {    var f2 = "500 27px -apple-system,Segoe UI,Roboto,sans-serif";}
    puts $html {    x.font = f1; var w1 = x.measureText(text).width;}
    puts $html {    x.font = f2; var w2 = unter ? x.measureText(unter).width : 0;}
    puts $html {    var w = Math.ceil(Math.max(w1, w2)) + 40, h = unter ? 96 : 62;}
    puts $html {    c.width = w; c.height = h;}
    puts $html {    x = c.getContext("2d");}
    puts $html {    x.fillStyle = "rgba(255,255,255,.95)";}
    puts $html {    if (x.roundRect)\{ x.beginPath(); x.roundRect(0,0,w,h,13); x.fill(); \}}
    puts $html {    else x.fillRect(0,0,w,h);}
    puts $html {    x.fillStyle = "#16191d"; x.font = f1; x.textBaseline = "middle";}
    puts $html {    x.fillText(text, 20, unter ? 32 : 31);}
    puts $html {    if (unter)\{ x.fillStyle = "#5f6773"; x.font = f2; x.fillText(unter, 20, 68); \}}
    puts $html {    var t = new THREE.CanvasTexture(c); t.minFilter = THREE.LinearFilter;}
    puts $html {    var s = new THREE.Sprite(new THREE.SpriteMaterial(\{map:t, transparent:true, depthTest:false\}));}
    puts $html {    s.scale.set(w/62*2.5, h/62*2.5, 1);}
    puts $html {    s.renderOrder = 999;}
    puts $html {    return s;}
    puts $html {  \}}
    puts $html {}
    puts $html {  // -------------------------------------------------------------- Aufbau ---}
    puts $html {  var BW = 7.4, BD = 4.2, BH = 1.7, LUFT = 1.3, ABSTAND = 11.4, START = -17;}
    puts $html {  var knoten = \[\], nachId = \{\}, klickbar = \[\];}
    puts $html {  var gruppe = new THREE.Group();}
    puts $html {}
    puts $html {  SPEC.schichten.forEach(function(sch, si)\{}
    puts $html {    var y = START + si * ABSTAND;}
    puts $html {    var bl = sch.blocks.map(function(b)\{}
    puts $html {      return (typeof b === "string") ? \{id:null, name:b, untertitel:""\} : b;}
    puts $html {    \});}
    puts $html {    var spalten = Math.max(1, Math.ceil(bl.length / 2));}
    puts $html {    var reihen = bl.length <= 1 ? 1 : 2;}
    puts $html {    var gx = spalten*BW + (spalten-1)*LUFT, gz = reihen*BD + (reihen-1)*LUFT;}
    puts $html {}
    puts $html {    var platte = new THREE.Mesh(}
    puts $html {      new THREE.BoxGeometry(gx+3, 0.6, gz+3),}
    puts $html {      new THREE.MeshLambertMaterial(\{color:new THREE.Color(sch.farbe).multiplyScalar(0.4)\}));}
    puts $html {    platte.position.set(0, y-1.7, 0); gruppe.add(platte);}
    puts $html {}
    puts $html {    bl.forEach(function(b, i)\{}
    puts $html {      var sp = i % spalten, re = Math.floor(i / spalten);}
    puts $html {      var x = -gx/2 + BW/2 + sp*(BW+LUFT), z = -gz/2 + BD/2 + re*(BD+LUFT);}
    puts $html {      var mat = new THREE.MeshLambertMaterial(\{color:sch.farbe\});}
    puts $html {      var m = new THREE.Mesh(new THREE.BoxGeometry(BW, BH, BD), mat);}
    puts $html {      m.position.set(x, y, z);}
    puts $html {      gruppe.add(m); klickbar.push(m);}
    puts $html {      var kante = new THREE.LineSegments(new THREE.EdgesGeometry(m.geometry),}
    puts $html {        new THREE.LineBasicMaterial(\{color:0x0e1420, transparent:true, opacity:.55\}));}
    puts $html {      kante.position.copy(m.position); gruppe.add(kante);}
    puts $html {}
    puts $html {      var s = schild(b.name, b.untertitel);}
    puts $html {      s.position.set(x, y + BH/2 + (b.untertitel ? 2.1 : 1.6), z);}
    puts $html {      gruppe.add(s);}
    puts $html {}
    puts $html {      var id = b.id || (b.name.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, ""));}
    puts $html {      var eintrag = \{id:id, name:b.name, untertitel:b.untertitel||"", schicht:sch.name,}
    puts $html {                     mesh:m, mat:mat, farbe:new THREE.Color(sch.farbe), pos:m.position\};}
    puts $html {      m.userData.index = knoten.length;}
    puts $html {      knoten.push(eintrag); nachId[id] = eintrag;}
    puts $html {    \});}
    puts $html {  \});}
    puts $html {}
    puts $html {  // -------------------------------------------------------------- Kanten ---}
    puts $html {  var STIL = \{\};}
    puts $html {  (SPEC.kantenarten || \[\]).forEach(function(a)\{ STIL[a.art] = a; \});}
    puts $html {}
    puts $html {  (SPEC.kanten || \[\]).forEach(function(k)\{}
    puts $html {    var a = nachId[k.von], b = nachId[k.nach];}
    puts $html {    if (!a || !b) return;}
    puts $html {    var art = STIL[k.art] || \{farbe:"#8ea2ff", stil:"voll"\};}
    puts $html {    var g = new THREE.BufferGeometry().setFromPoints\([}
    puts $html {      a.pos.clone().setY(a.pos.y + 0.9), b.pos.clone().setY(b.pos.y - 0.9)\]);}
    puts $html {    var linie;}
    puts $html {    if (art.stil === "gestrichelt"\{}}
    puts $html {      linie = new THREE.Line(g, new THREE.LineDashedMaterial(}
    puts $html {        \{color:art.farbe, dashSize:1.4, gapSize:1.0, transparent:true, opacity:.9\}));}
    puts $html {      linie.computeLineDistances();}
    puts $html {    \} else \{}
    puts $html {      linie = new THREE.Line(g, new THREE.LineBasicMaterial(}
    puts $html {        \{color:art.farbe, transparent:true, opacity:.85\}));}
    puts $html {    \}}
    puts $html {    gruppe.add(linie);}
    puts $html {  \});}
    puts $html {}
    puts $html {  szene.add(gruppe);}
    puts $html {}
    puts $html {  var leg = document.getElementById("legende");}
    puts $html {  (SPEC.kantenarten || \[\]).forEach(function(a)\{}
    puts $html {    var s = document.createElement("span");}
    puts $html {    s.innerHTML = '<i class="strich" style="border-top-color:' + a.farbe +}
    puts $html {                  ';border-top-style:' + (a.stil === "gestrichelt" ? "dashed" : "solid") +}
    puts $html {                  '"></i>' + a.text;}
    puts $html {    leg.appendChild(s);}
    puts $html {  \});}
    puts $html {}
    puts $html {  // ------------------------------------------------------------- Auswahl ---}
    puts $html {  var aktiv = -1;}
    puts $html {  function waehle(i)\{}
    puts $html {    if (aktiv >= 0)\{}
    puts $html {      knoten[aktiv].mat.color.copy(knoten[aktiv].farbe);}
    puts $html {      knoten[aktiv].mat.emissive.setHex(0x000000);}
    puts $html {      knoten[aktiv].mesh.scale.set(1,1,1);}
    puts $html {    \}}
    puts $html {    aktiv = ((i % knoten.length) + knoten.length) % knoten.length;}
    puts $html {    var k = knoten[aktiv];}
    puts $html {    k.mat.emissive.setHex(0x333333);}
    puts $html {    k.mesh.scale.set(1.1, 1.5, 1.1);}
    puts $html {    document.getElementById("k-name").textContent = k.name;}
    puts $html {    document.getElementById("k-sub").textContent = k.untertitel || "—";}
    puts $html {    document.getElementById("k-schicht").textContent = k.schicht;}
    puts $html {    document.getElementById("k-id").textContent = k.id;}
    puts $html {  \}}
    puts $html {}
    puts $html {  var strahl = new THREE.Raycaster(), zeiger = new THREE.Vector2();}
    puts $html {  renderer.domElement.addEventListener("click", function(e)\{}
    puts $html {    if (gezogen) return;}
    puts $html {    var r = renderer.domElement.getBoundingClientRect();}
    puts $html {    zeiger.x = ((e.clientX - r.left) / r.width) * 2 - 1;}
    puts $html {    zeiger.y = -((e.clientY - r.top) / r.height) * 2 + 1;}
    puts $html {    strahl.setFromCamera(zeiger, kamera);}
    puts $html {    var treffer = strahl.intersectObjects(klickbar, false);}
    puts $html {    if (treffer.length) waehle(treffer[0].object.userData.index);}
    puts $html {  \});}
    puts $html {  document.getElementById("btn-prev").addEventListener("click", function()\{ waehle(aktiv - 1); \});}
    puts $html {  document.getElementById("btn-next").addEventListener("click", function()\{ waehle(aktiv + 1); \});}
    puts $html {}
    puts $html {  // ------------------------------------------------------------- Kamera ----}
    puts $html {  var azimut = Math.PI/4, elevation = 0.62, rotiert = true;}
    puts $html {  function stelle()\{}
    puts $html {    var x = radius*Math.cos(elevation)*Math.sin(azimut);}
    puts $html {    var y = radius*Math.sin(elevation);}
    puts $html {    var z = radius*Math.cos(elevation)*Math.cos(azimut);}
    puts $html {    kamera.position.set(x, y, z); kamera.lookAt(0, 0, 0);}
    puts $html {  \}}
    puts $html {  var zieht = false, gezogen = false, lx = 0, ly = 0;}
    puts $html {  renderer.domElement.addEventListener("pointerdown", function(e)\{}
    puts $html {    zieht = true; gezogen = false; lx = e.clientX; ly = e.clientY;}
    puts $html {  \});}
    puts $html {  window.addEventListener("pointermove", function(e)\{}
    puts $html {    if (!zieht) return;}
    puts $html {    if (Math.abs(e.clientX-lx) + Math.abs(e.clientY-ly) > 3)\{ gezogen = true; rotiert = false; \}}
    puts $html {    azimut -= (e.clientX - lx) * 0.006;}
    puts $html {    elevation = Math.max(0.08, Math.min(1.45, elevation + (e.clientY - ly) * 0.005));}
    puts $html {    lx = e.clientX; ly = e.clientY;}
    puts $html {  \});}
    puts $html {  window.addEventListener("pointerup", function()\{ zieht = false; setTimeout(function()\{ gezogen = false; \}, 0); \});}
    puts $html {}
    puts $html {  function zoom(f)\{}
    puts $html {    if (iso)\{ D = Math.max(11, Math.min(54, D * f)); groesse(); \}}
    puts $html {    else \{ radius = Math.max(32, Math.min(160, radius * f)); \}}
    puts $html {  \}}
    puts $html {  document.getElementById("btn-plus").addEventListener("click", function()\{ zoom(0.85); \});}
    puts $html {  document.getElementById("btn-minus").addEventListener("click", function()\{ zoom(1.18); \});}
    puts $html {  renderer.domElement.addEventListener("wheel", function(e)\{}
    puts $html {    e.preventDefault(); zoom(e.deltaY > 0 ? 1.08 : 0.93);}
    puts $html {  \}, \{passive:false\});}
    puts $html {  document.getElementById("btn-reset").addEventListener("click", function()\{}
    puts $html {    azimut = Math.PI/4; elevation = 0.62; D = 26; radius = 82; rotiert = true;}
    puts $html {    iso = true; kamera = kameraIso;}
    puts $html {    document.getElementById("btn-iso").setAttribute("aria-pressed", "true");}
    puts $html {    document.getElementById("btn-iso").textContent = "Iso";}
    puts $html {    waehle(0); groesse();}
    puts $html {  \});}
    puts $html {  document.getElementById("btn-iso").addEventListener("click", function()\{}
    puts $html {    iso = !iso; kamera = iso ? kameraIso : kameraPersp;}
    puts $html {    this.setAttribute("aria-pressed", String(iso));}
    puts $html {    this.textContent = iso ? "Iso" : "Persp";}
    puts $html {    groesse();}
    puts $html {  \});}
    puts $html {}
    puts $html {  function groesse()\{}
    puts $html {    var w = buehne.clientWidth, h = buehne.clientHeight;}
    puts $html {    aspekt = w / h;}
    puts $html {    kameraIso.left = -D*aspekt; kameraIso.right = D*aspekt;}
    puts $html {    kameraIso.top = D; kameraIso.bottom = -D; kameraIso.updateProjectionMatrix();}
    puts $html {    kameraPersp.aspect = aspekt; kameraPersp.updateProjectionMatrix();}
    puts $html {    renderer.setSize(w, h, false);}
    puts $html {  \}}
    puts $html {  window.addEventListener("resize", groesse);}
    puts $html {}
    puts $html {  groesse();}
    puts $html {  waehle(0);}
    puts $html {  (function schleife()\{}
    puts $html {    requestAnimationFrame(schleife);}
    puts $html {    if (rotiert) azimut += 0.003;}
    puts $html {    stelle();}
    puts $html {    renderer.render(szene, kamera);}
    puts $html {  \})();}
    puts $html {\})();}
    puts $html {</script>}
    puts $html {</body>}
    puts $html {</html>}
    
    close $html
}

# Main execution
if {$argc != 1} {
    puts stderr "Usage: [info script] <output-file>"
    exit 1
}

generate_3d_html [lindex $argv 0]
