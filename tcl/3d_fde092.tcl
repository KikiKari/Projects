#!/usr/bin/env tclsh
# abstraction-provenance: {"artifact_sha256": "af2a77e654dc83af2e9971061051cb8bfb118a262eebaa8fa7e258764edb3914", "source_sha256": "fde0925c6da9f2674781482e5d06631c48818efbac6d63d45e764a139fc3bdf4", "target_language": "tcl"}
# 3d.html — portiert nach tcl
# Quelle: html, Projects@secret-vault-public:public/3d.html
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# Tcl/Tk port of the 3D interactive architecture visualization
# This script generates an equivalent HTML file with all functionality intact

proc generate_html {filename} {
    set html [list]
    
    lappend html {<!DOCTYPE html>}
    lappend html {<html lang="de">}
    lappend html {<head>}
    lappend html {<meta charset="utf-8">}
    lappend html {<meta name="viewport" content="width=device-width, initial-scale=1">}
    lappend html {<title>Secret-Vault Public — Interaktive Architektur</title>}
    lappend html {<meta name="description" content="Vom Passwort zur verschlüsselten Datei — jede Schicht bleibt im Browser. Drehen, zoomen, Knoten auswählen.">}
    lappend html {<meta name="theme-color" content="#5b5bd6">}
    lappend html {<style>}
    lappend html {:root\{}
    lappend html {  --bg:#fbfaf7; --panel:#fff; --line:#e6e3dc; --text:#16191d; --muted:#5f6773;}
    lappend html {  --ac:#5b5bd6; --buehne:#0e1420; --buehne-line:#1d2739;}
    lappend html {  color-scheme: light;}
    lappend html {\}}
    lappend html {@media (prefers-color-scheme: dark)\{}
    lappend html {  :root\{ --bg:#0f1115; --panel:#171a21; --line:#262b36; --text:#f2f4f8; --muted:#9aa3b2;}
    lappend html {         color-scheme: dark; \}}
    lappend html {\}}
    lappend html {*\{box-sizing:border-box\}}
    lappend html {body\{margin:0;background:var(--bg);color:var(--text);}
    lappend html {     font:15px/1.55 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif\}}
    lappend html {.wrap\{max-width:1240px;margin:0 auto;padding:34px 22px 60px\}}
    lappend html {.technik\{font-size:12px;font-weight:700;letter-spacing:.1em;text-transform:uppercase;}
    lappend html {         color:var(--ac);margin:0 0 10px\}}
    lappend html {h1\{font-size:clamp(30px,5vw,52px);line-height:1.05;margin:0 0 14px;letter-spacing:-.03em\}}
    lappend html {.lede\{font-size:16.5px;color:var(--muted);max-width:62ch;margin:0 0 26px\}}
    lappend html {.raster\{display:grid;grid-template-columns:minmax(0,1fr) 288px;gap:18px;align-items:start\}}
    lappend html {@media (max-width:880px)\{ .raster\{grid-template-columns:1fr\} \}}
    lappend html {.buehne\{position:relative;background:var(--buehne);border-radius:14px;overflow:hidden;}
    lappend html {        min-height:520px;aspect-ratio:16/11\}}
    lappend html {.buehne canvas\{display:block;width:100%;height:100%\}}
    lappend html {.knoepfe\{position:absolute;top:14px;right:14px;display:flex;gap:8px;z-index:2\}}
    lappend html {button\{font:inherit;font-size:14px;font-weight:650;padding:9px 14px;border-radius:9px;}
    lappend html {       border:1px solid var(--line);background:var(--panel);color:var(--text);cursor:pointer\}}
    lappend html {button:hover\{border-color:var(--ac)\}}
    lappend html {button[aria-pressed="true"]\{background:var(--ac);border-color:var(--ac);color:#fff\}}
    lappend html {.karte\{background:var(--panel);border:1px solid var(--line);border-radius:14px;padding:20px\}}
    lappend html {.karte h2\{font-size:11px;font-weight:700;letter-spacing:.09em;text-transform:uppercase;}
    lappend html {          color:var(--muted);margin:0 0 12px\}}
    lappend html {.karte h3\{font-size:23px;margin:0 0 4px;letter-spacing:-.02em\}}
    lappend html {.karte .sub\{color:var(--muted);margin:0 0 18px;font-size:14.5px\}}
    lappend html {.feld\{border-top:1px solid var(--line);padding:12px 0 0;margin:0 0 12px\}}
    lappend html {.feld dt\{font-size:11px;font-weight:700;letter-spacing:.08em;text-transform:uppercase;}
    lappend html {         color:var(--muted);margin:0 0 3px\}}
    lappend html {.feld dd\{margin:0;font-weight:650\}}
    lappend html {.blaettern\{display:flex;gap:8px;margin-top:16px\}}
    lappend html {.blaettern button\{flex:1;text-align:center;line-height:1.25;padding:11px 8px\}}
    lappend html {.legende\{display:flex;gap:22px;flex-wrap:wrap;margin:16px 0 0;font-size:13.5px;color:var(--muted)\}}
    lappend html {.legende span\{display:inline-flex;align-items:center;gap:9px\}}
    lappend html {.strich\{width:30px;height:0;border-top-width:3px;border-top-style:solid;display:inline-block\}}
    lappend html {.fuss\{margin:14px 0 0;font-size:13px;color:var(--muted);max-width:80ch\}}
    lappend html {.fehler\{padding:40px;text-align:center;color:var(--muted)\}}
    lappend html {a\{color:var(--ac)\}}
    lappend html {</style>}
    lappend html {</head>}
    lappend html {<body>}
    lappend html {<div class="wrap">}
    lappend html {}
    lappend html {  <p class="technik">three.js · r128</p>}
    lappend html {  <h1>Secret-Vault Public</h1>}
    lappend html {  <p class="lede">Vom Passwort zur verschlüsselten Datei — jede Schicht bleibt im Browser. Drehen, zoomen, Knoten auswählen.</p>}
    lappend html {}
    lappend html {  <div class="raster">}
    lappend html {    <div class="buehne" id="buehne">}
    lappend html {      <div class="knoepfe">}
    lappend html {        <button id="btn-plus" title="Näher">+</button>}
    lappend html {        <button id="btn-minus" title="Weiter weg">−</button>}
    lappend html {        <button id="btn-reset">Zurücksetzen</button>}
    lappend html {        <button id="btn-iso" aria-pressed="true" title="Isometrisch oder perspektivisch">Iso</button>}
    lappend html {      </div>}
    lappend html {    </div>}
    lappend html {}
    lappend html {    <aside class="karte">}
    lappend html {      <h2>Ausgewählter Knoten</h2>}
    lappend html {      <h3 id="k-name">—</h3>}
    lappend html {      <p class="sub" id="k-sub">Knoten anklicken oder durchblättern</p>}
    lappend html {      <dl class="feld"><dt>Schicht</dt><dd id="k-schicht">—</dd></dl>}
    lappend html {      <dl class="feld"><dt>ID</dt><dd id="k-id">—</dd></dl>}
    lappend html {      <div class="blaettern">}
    lappend html {        <button id="btn-prev">←<br>Vorheriger</button>}
    lappend html {        <button id="btn-next">Nächster<br>→</button>}
    lappend html {      </div>}
    lappend html {    </aside>}
    lappend html {  </div>}
    lappend html {}
    lappend html {  <div class="legende" id="legende"></div>}
    lappend html {  <p class="fuss">Schematische Dokumentationsansicht — Blockgrößen messen weder Datenmenge noch Leistung. Keine Telemetrie, keine Fernabfragen: Die Seite lädt einmalig three.js vom CDN und rechnet danach ausschließlich lokal.</p>}
    lappend html {}
    lappend html {</div>}
    lappend html {}
    lappend html {<script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>}
    lappend html {<script>}
    lappend html {(function()\{}
    lappend html {  "use strict";}
    lappend html {  var SPEC = \{"schichten": [\{"name": "Eingaben", "farbe": "#5f6773", "blocks": [\{"id": "passphrase", "name": "Passphrase", "untertitel": "nie gespeichert"\}, \{"id": "vault-datei", "name": "Vault-Datei", "untertitel": "Ciphertext"\}, \{"id": "neue-felder", "name": "neue Felder", "untertitel": "Formular"\}\]\}, \{"name": "Schluesselableitung", "farbe": "#2481cc", "blocks": [\{"id": "pbkdf2-210k", "name": "PBKDF2 210k", "untertitel": "Iterationen"\}, \{"id": "salt-16-b", "name": "Salt 16 B", "untertitel": "zufaellig"\}, \{"id": "sha-256", "name": "SHA-256", "untertitel": "HMAC"\}\]\}, \{"name": "Verschluesselung", "farbe": "#5b5bd6", "blocks": [\{"id": "aes-256-gcm", "name": "AES-256-GCM", "untertitel": "authentisiert"\}, \{"id": "iv-12-b", "name": "IV 12 B", "untertitel": "nie doppelt"\}, \{"id": "crypto-subtle", "name": "crypto.subtle", "untertitel": "WebCrypto"\}\]\}, \{"name": "Verwaltung", "farbe": "#b45309", "blocks": [\{"id": "anbieter", "name": "Anbieter", "untertitel": "Gruppen"\}, \{"id": "felder", "name": "Felder", "untertitel": "Schluessel/Wert"\}, \{"id": "rotation", "name": "Rotation", "untertitel": "neuer Wert"\}\]\}, \{"name": "Ausgabe", "farbe": "#22a06b", "blocks": [\{"id": "download", "name": "Download", "untertitel": "Blob-URL"\}, \{"id": "export", "name": "Export", "untertitel": "JSON"\}, \{"id": "zwischenablage", "name": "Zwischenablage", "untertitel": "nur auf Klick"\}\]\}\], "kanten": [\{"von": "passphrase", "nach": "pbkdf2-210k", "art": "fluss"\}, \{"von": "vault-datei", "nach": "salt-16-b", "art": "fluss"\}, \{"von": "neue-felder", "nach": "sha-256", "art": "fluss"\}, \{"von": "pbkdf2-210k", "nach": "aes-256-gcm", "art": "fluss"\}, \{"von": "salt-16-b", "nach": "iv-12-b", "art": "fluss"\}, \{"von": "sha-256", "nach": "crypto-subtle", "art": "fluss"\}, \{"von": "aes-256-gcm", "nach": "anbieter", "art": "fluss"\}, \{"von": "iv-12-b", "nach": "felder", "art": "fluss"\}, \{"von": "crypto-subtle", "nach": "rotation", "art": "fluss"\}, \{"von": "anbieter", "nach": "download", "art": "fluss"\}, \{"von": "felder", "nach": "export", "art": "fluss"\}, \{"von": "rotation", "nach": "zwischenablage", "art": "fluss"\}\], "kantenarten": [\{"art": "fluss", "farbe": "#5b5bd6", "stil": "voll", "text": "Fluss von unten nach oben"\}\]\};}
    lappend html {}
    lappend html {  var buehne = document.getElementById("buehne");}
    lappend html {  if (typeof THREE === "undefined")\{}
    lappend html {    buehne.insertAdjacentHTML("beforeend",}
    lappend html {      '<div class="fehler">three.js konnte nicht geladen werden. ' +}
    lappend html {      'Die Seite braucht einmalig Netzzugang zum CDN.</div>');}
    lappend html {    return;}
    lappend html {  \}}
    lappend html {}
    lappend html {  // ---------------------------------------------------------------- Szene ---}
    lappend html {  var szene = new THREE.Scene();}
    lappend html {  szene.background = new THREE.Color(0x0e1420);}
    lappend html {  var renderer = new THREE.WebGLRenderer(\{antialias:true\});}
    lappend html {  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));}
    lappend html {  buehne.appendChild(renderer.domElement);}
    lappend html {}
    lappend html {  var D = 26, radius = 82, aspekt = 1;}
    lappend html {  var kameraIso = new THREE.OrthographicCamera(-D, D, D, -D, 0.1, 600);}
    lappend html {  var kameraPersp = new THREE.PerspectiveCamera(42, 1, 0.1, 600);}
    lappend html {  var kamera = kameraIso, iso = true;}
    lappend html {}
    lappend html {  szene.add(new THREE.AmbientLight(0xffffff, 0.66));}
    lappend html {  var licht = new THREE.DirectionalLight(0xffffff, 0.8);}
    lappend html {  licht.position.set(30, 46, 26); szene.add(licht);}
    lappend html {  var gegen = new THREE.DirectionalLight(0x8ea2ff, 0.3);}
    lappend html {  gegen.position.set(-32, 16, -28); szene.add(gegen);}
    lappend html {}
    lappend html {  var raster = new THREE.GridHelper(110, 34, 0x25324a, 0x1a2333);}
    lappend html {  raster.position.y = -24; szene.add(raster);}
    lappend html {}
    lappend html {  // ------------------------------------------------------------ Schilder ---}
    lappend html {  // Text auf eine Textur, dann als Billboard — bleibt bei jeder Drehung lesbar.}
    lappend html {  function schild(text, unter)\{}
    lappend html {    var c = document.createElement("canvas"), x = c.getContext("2d");}
    lappend html {    var f1 = "700 40px -apple-system,Segoe UI,Roboto,sans-serif";}
    lappend html {    var f2 = "500 27px -apple-system,Segoe UI,Roboto,sans-serif";}
    lappend html {    x.font = f1; var w1 = x.measureText(text).width;}
    lappend html {    x.font = f2; var w2 = unter ? x.measureText(unter).width : 0;}
    lappend html {    var w = Math.ceil(Math.max(w1, w2)) + 40, h = unter ? 96 : 62;}
    lappend html {    c.width = w; c.height = h;}
    lappend html {    x = c.getContext("2d");}
    lappend html {    x.fillStyle = "rgba(255,255,255,.95)";}
    lappend html {    if (x.roundRect)\{ x.beginPath(); x.roundRect(0,0,w,h,13); x.fill(); \}}
    lappend html {    else x.fillRect(0,0,w,h);}
    lappend html {    x.fillStyle = "#16191d"; x.font = f1; x.textBaseline = "middle";}
    lappend html {    x.fillText(text, 20, unter ? 32 : 31);}
    lappend html {    if (unter)\{ x.fillStyle = "#5f6773"; x.font = f2; x.fillText(unter, 20, 68); \}}
    lappend html {    var t = new THREE.CanvasTexture(c); t.minFilter = THREE.LinearFilter;}
    lappend html {    var s = new THREE.Sprite(new THREE.SpriteMaterial(\{map:t, transparent:true, depthTest:false\}));}
    lappend html {    s.scale.set(w/62*2.5, h/62*2.5, 1);}
    lappend html {    s.renderOrder = 999;}
    lappend html {    return s;}
    lappend html {  \}}
    lappend html {}
    lappend html {  // -------------------------------------------------------------- Aufbau ---}
    lappend html {  var BW = 7.4, BD = 4.2, BH = 1.7, LUFT = 1.3, ABSTAND = 11.4, START = -17;}
    lappend html {  var knoten = [], nachId = \{\}, klickbar = [];}
    lappend html {  var gruppe = new THREE.Group();}
    lappend html {}
    lappend html {  SPEC.schichten.forEach(function(sch, si)\{}
    lappend html {    var y = START + si * ABSTAND;}
    lappend html {    var bl = sch.blocks.map(function(b)\{}
    lappend html {      return (typeof b === "string") ? \{id:null, name:b, untertitel:""\} : b;}
    lappend html {    \});}
    lappend html {    var spalten = Math.max(1, Math.ceil(bl.length / 2));}
    lappend html {    var reihen = bl.length <= 1 ? 1 : 2;}
    lappend html {    var gx = spalten*BW + (spalten-1)*LUFT, gz = reihen*BD + (reihen-1)*LUFT;}
    lappend html {}
    lappend html {    var platte = new THREE.Mesh(}
    lappend html {      new THREE.BoxGeometry(gx+3, 0.6, gz+3),}
    lappend html {      new THREE.MeshLambertMaterial(\{color:new THREE.Color(sch.farbe).multiplyScalar(0.4)\}));}
    lappend html {    platte.position.set(0, y-1.7, 0); gruppe.add(platte);}
    lappend html {}
    lappend html {    bl.forEach(function(b, i)\{}
    lappend html {      var sp = i % spalten, re = Math.floor(i / spalten);}
    lappend html {      var x = -gx/2 + BW/2 + sp*(BW+LUFT), z = -gz/2 + BD/2 + re*(BD+LUFT);}
    lappend html {      var mat = new THREE.MeshLambertMaterial(\{color:sch.farbe\});}
    lappend html {      var m = new THREE.Mesh(new THREE.BoxGeometry(BW, BH, BD), mat);}
    lappend html {      m.position.set(x, y, z);}
    lappend html {      gruppe.add(m); klickbar.push(m);}
    lappend html {      var kante = new THREE.LineSegments(new THREE.EdgesGeometry(m.geometry),}
    lappend html {        new THREE.LineBasicMaterial(\{color:0x0e1420, transparent:true, opacity:.55\}));}
    lappend html {      kante.position.copy(m.position); gruppe.add(kante);}
    lappend html {}
    lappend html {      var s = schild(b.name, b.untertitel);}
    lappend html {      s.position.set(x, y + BH/2 + (b.untertitel ? 2.1 : 1.6), z);}
    lappend html {      gruppe.add(s);}
    lappend html {}
    lappend html {      var id = b.id || (b.name.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, ""));}
    lappend html {      var eintrag = \{id:id, name:b.name, untertitel:b.untertitel||"", schicht:sch.name,}
    lappend html {                     mesh:m, mat:mat, farbe:new THREE.Color(sch.farbe), pos:m.position\};}
    lappend html {      m.userData.index = knoten.length;}
    lappend html {      knoten.push(eintrag); nachId[id] = eintrag;}
    lappend html {    \});}
    lappend html {  \});}
    lappend html {}
    lappend html {  // -------------------------------------------------------------- Kanten ---}
    lappend html {  var STIL = \{\};}
    lappend html {  (SPEC.kantenarten || []).forEach(function(a)\{ STIL[a.art] = a; \});}
    lappend html {}
    lappend html {  (SPEC.kanten || []).forEach(function(k)\{}
    lappend html {    var a = nachId[k.von], b = nachId[k.nach];}
    lappend html {    if (!a || !b) return;}
    lappend html {    var art = STIL[k.art] || \{farbe:"#8ea2ff", stil:"voll"\};}
    lappend html {    var g = new THREE.BufferGeometry().setFromPoints([}
    lappend html {      a.pos.clone().setY(a.pos.y + 0.9), b.pos.clone().setY(b.pos.y - 0.9)]);}
    lappend html {    var linie;}
    lappend html {    if (art.stil === "gestrichelt")\{}
    lappend html {      linie = new THREE.Line(g, new THREE.LineDashedMaterial(}
    lappend html {        \{color:art.farbe, dashSize:1.4, gapSize:1.0, transparent:true, opacity:.9\}));}
    lappend html {      linie.computeLineDistances();}
    lappend html {    \} else \{}
    lappend html {      linie = new THREE.Line(g, new THREE.LineBasicMaterial(}
    lappend html {        \{color:art.farbe, transparent:true, opacity:.85\}));}
    lappend html {    \}}
    lappend html {    gruppe.add(linie);}
    lappend html {  \});}
    lappend html {}
    lappend html {  szene.add(gruppe);}
    lappend html {}
    lappend html {  var leg = document.getElementById("legende");}
    lappend html {  (SPEC.kantenarten || []).forEach(function(a)\{}
    lappend html {    var s = document.createElement("span");}
    lappend html {    s.innerHTML = '<i class="strich" style="border-top-color:' + a.farbe +}
    lappend html {                  ';border-top-style:' + (a.stil === "gestrichelt" ? "dashed" : "solid") +}
    lappend html {                  '"></i>' + a.text;}
    lappend html {    leg.appendChild(s);}
    lappend html {  \});}
    lappend html {}
    lappend html {  // ------------------------------------------------------------- Auswahl ---}
    lappend html {  var aktiv = -1;}
    lappend html {  function waehle(i)\{}
    lappend html {    if (aktiv >= 0)\{}
    lappend html {      knoten[aktiv].mat.color.copy(knoten[aktiv].farbe);}
    lappend html {      knoten[aktiv].mat.emissive.setHex(0x000000);}
    lappend html {      knoten[aktiv].mesh.scale.set(1,1,1);}
    lappend html {    \}}
    lappend html {    aktiv = ((i % knoten.length) + knoten.length) % knoten.length;}
    lappend html {    var k = knoten[aktiv];}
    lappend html {    k.mat.emissive.setHex(0x333333);}
    lappend html {    k.mesh.scale.set(1.1, 1.5, 1.1);}
    lappend html {    document.getElementById("k-name").textContent = k.name;}
    lappend html {    document.getElementById("k-sub").textContent = k.untertitel || "—";}
    lappend html {    document.getElementById("k-schicht").textContent = k.schicht;}
    lappend html {    document.getElementById("k-id").textContent = k.id;}
    lappend html {  \}}
    lappend html {}
    lappend html {  var strahl = new THREE.Raycaster(), zeiger = new THREE.Vector2();}
    lappend html {  renderer.domElement.addEventListener("click", function(e)\{}
    lappend html {    if (gezogen) return;}
    lappend html {    var r = renderer.domElement.getBoundingClientRect();}
    lappend html {    zeiger.x = ((e.clientX - r.left) / r.width) * 2 - 1;}
    lappend html {    zeiger.y = -((e.clientY - r.top) / r.height) * 2 + 1;}
    lappend html {    strahl.setFromCamera(zeiger, kamera);}
    lappend html {    var treffer = strahl.intersectObjects(klickbar, false);}
    lappend html {    if (treffer.length) waehle(treffer[0].object.userData.index);}
    lappend html {  \});}
    lappend html {  document.getElementById("btn-prev").addEventListener("click", function()\{ waehle(aktiv - 1); \});}
    lappend html {  document.getElementById("btn-next").addEventListener("click", function()\{ waehle(aktiv + 1); \});}
    lappend html {}
    lappend html {  // ------------------------------------------------------------- Kamera ----}
    lappend html {  var azimut = Math.PI/4, elevation = 0.62, rotiert = true;}
    lappend html {  function stelle()\{}
    lappend html {    var x = radius*Math.cos(elevation)*Math.sin(azimut);}
    lappend html {    var y = radius*Math.sin(elevation);}
    lappend html {    var z = radius*Math.cos(elevation)*Math.cos(azimut);}
    lappend html {    kamera.position.set(x, y, z); kamera.lookAt(0, 0, 0);}
    lappend html {  \}}
    lappend html {  var zieht = false, gezogen = false, lx = 0, ly = 0;}
    lappend html {  renderer.domElement.addEventListener("pointerdown", function(e)\{}
    lappend html {    zieht = true; gezogen = false; lx = e.clientX; ly = e.clientY;}
    lappend html {  \});}
    lappend html {  window.addEventListener("pointermove", function(e)\{}
    lappend html {    if (!zieht) return;}
    lappend html {    if (Math.abs(e.clientX-lx) + Math.abs(e.clientY-ly) > 3)\{ gezogen = true; rotiert = false; \}}
    lappend html {    azimut -= (e.clientX - lx) * 0.006;}
    lappend html {    elevation = Math.max(0.08, Math.min(1.45, elevation + (e.clientY - ly) * 0.005));}
    lappend html {    lx = e.clientX; ly = e.clientY;}
    lappend html {  \});}
    lappend html {  window.addEventListener("pointerup", function()\{ zieht = false; setTimeout(function()\{ gezogen = false; \}, 0); \});}
    lappend html {}
    lappend html {  function zoom(f)\{}
    lappend html {    if (iso)\{ D = Math.max(11, Math.min(54, D * f)); groesse(); \}}
    lappend html {    else \{ radius = Math.max(32, Math.min(160, radius * f)); \}}
    lappend html {  \}}
    lappend html {  document.getElementById("btn-plus").addEventListener("click", function()\{ zoom(0.85); \});}
    lappend html {  document.getElementById("btn-minus").addEventListener("click", function()\{ zoom(1.18); \});}
    lappend html {  renderer.domElement.addEventListener("wheel", function(e)\{}
    lappend html {    e.preventDefault(); zoom(e.deltaY > 0 ? 1.08 : 0.93);}
    lappend html {  \}, \{passive:false\});}
    lappend html {  document.getElementById("btn-reset").addEventListener("click", function()\{}
    lappend html {    azimut = Math.PI/4; elevation = 0.62; D = 26; radius = 82; rotiert = true;}
    lappend html {    iso = true; kamera = kameraIso;}
    lappend html {    document.getElementById("btn-iso").setAttribute("aria-pressed", "true");}
    lappend html {    document.getElementById("btn-iso").textContent = "Iso";}
    lappend html {    waehle(0); groesse();}
    lappend html {  \});}
    lappend html {  document.getElementById("btn-iso").addEventListener("click", function()\{}
    lappend html {    iso = !iso; kamera = iso ? kameraIso : kameraPersp;}
    lappend html {    this.setAttribute("aria-pressed", String(iso));}
    lappend html {    this.textContent = iso ? "Iso" : "Persp";}
    lappend html {    groesse();}
    lappend html {  \});}
    lappend html {}
    lappend html {  function groesse()\{}
    lappend html {    var w = buehne.clientWidth, h = buehne.clientHeight;}
    lappend html {    aspekt = w / h;}
    lappend html {    kameraIso.left = -D*aspekt; kameraIso.right = D*aspekt;}
    lappend html {    kameraIso.top = D; kameraIso.bottom = -D; kameraIso.updateProjectionMatrix();}
    lappend html {    kameraPersp.aspect = aspekt; kameraPersp.updateProjectionMatrix();}
    lappend html {    renderer.setSize(w, h, false);}
    lappend html {  \}}
    lappend html {  window.addEventListener("resize", groesse);}
    lappend html {}
    lappend html {  groesse();}
    lappend html {  waehle(0);}
    lappend html {  (function schleife()\{}
    lappend html {    requestAnimationFrame(schleife);}
    lappend html {    if (rotiert) azimut += 0.003;}
    lappend html {    stelle();}
    lappend html {    renderer.render(szene, kamera);}
    lappend html {  \})();}
    lappend html {})();}
    lappend html {</script>}
    lappend html {</body>}
    lappend html {</html>}
    
    # Write to file
    set f [open $filename w]
    foreach line $html {
        puts $f $line
    }
    close $f
    
    puts "Generated $filename successfully"
}

# Main execution
if {$argc != 1} {
    puts "Usage: $argv0 <output-file>"
    exit 1
}

generate_html [lindex $argv 0]
