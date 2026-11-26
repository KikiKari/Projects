<?php
// abstraction-provenance: {"artifact_sha256": "2e28128635be909867bdf65c8723b4f1b16aeff425ab43353257aeec4d3fb20c", "source_sha256": "1af3533731f49a592a9bf1403bd2219e023d0d8fc974ae8ed0223565071239ed", "target_language": "php"}
// 3d.html — portiert nach php
// Quelle: html, Projects@MCP-Server-Monitor:public/3d.html
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py
// 3d.php - Generiert das interaktive 3D-Diagramm als HTML-Seite

// Funktion zur Erstellung des HTML-Dokuments
function generate3dPage() {
    $html = '<!DOCTYPE html>';
    $html .= '<html lang="de">';
    $html .= '<head>';
    $html .= '<meta charset="utf-8">';
    $html .= '<meta name="viewport" content="width=device-width, initial-scale=1">';
    $html .= '<title>MCP-Server-Monitor — Interaktive Architektur</title>';
    $html .= '<meta name="description" content="Warum fehlen die Tools? Vier Schichten von der Netz-Sonde bis zur Ausgabe — drehen, zoomen, Knoten auswählen.">';
    $html .= '<meta name="theme-color" content="#6d5bd0">';
    $html .= '<style>';
    $html .= ':root{';
    $html .= '--bg:#fbfaf7; --panel:#fff; --line:#e6e3dc; --text:#16191d; --muted:#5f6773;';
    $html .= '--ac:#6d5bd0; --buehne:#0e1420; --buehne-line:#1d2739;';
    $html .= 'color-scheme: light;';
    $html .= '}';
    $html .= '@media (prefers-color-scheme: dark){';
    $html .= ':root{ --bg:#0f1115; --panel:#171a21; --line:#262b36; --text:#f2f4f8; --muted:#9aa3b2;';
    $html .= 'color-scheme: dark; }';
    $html .= '}';
    $html .= '*{box-sizing:border-box}';
    $html .= 'body{margin:0;background:var(--bg);color:var(--text);';
    $html .= 'font:15px/1.55 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif}';
    $html .= '.wrap{max-width:1240px;margin:0 auto;padding:34px 22px 60px}';
    $html .= '.technik{font-size:12px;font-weight:700;letter-spacing:.1em;text-transform:uppercase;';
    $html .= 'color:var(--ac);margin:0 0 10px}';
    $html .= 'h1{font-size:clamp(30px,5vw,52px);line-height:1.05;margin:0 0 14px;letter-spacing:-.03em}';
    $html .= '.lede{font-size:16.5px;color:var(--muted);max-width:62ch;margin:0 0 26px}';
    $html .= '.raster{display:grid;grid-template-columns:minmax(0,1fr) 288px;gap:18px;align-items:start}';
    $html .= '@media (max-width:880px){ .raster{grid-template-columns:1fr} }';
    $html .= '.buehne{position:relative;background:var(--buehne);border-radius:14px;overflow:hidden;';
    $html .= 'min-height:520px;aspect-ratio:16/11}';
    $html .= '.buehne canvas{display:block;width:100%;height:100%}';
    $html .= '.knoepfe{position:absolute;top:14px;right:14px;display:flex;gap:8px;z-index:2}';
    $html .= 'button{font:inherit;font-size:14px;font-weight:650;padding:9px 14px;border-radius:9px;';
    $html .= 'border:1px solid var(--line);background:var(--panel);color:var(--text);cursor:pointer}';
    $html .= 'button:hover{border-color:var(--ac)}';
    $html .= 'button[aria-pressed="true"]{background:var(--ac);border-color:var(--ac);color:#fff}';
    $html .= '.karte{background:var(--panel);border:1px solid var(--line);border-radius:14px;padding:20px}';
    $html .= '.karte h2{font-size:11px;font-weight:700;letter-spacing:.09em;text-transform:uppercase;';
    $html .= 'color:var(--muted);margin:0 0 12px}';
    $html .= '.karte h3{font-size:23px;margin:0 0 4px;letter-spacing:-.02em}';
    $html .= '.karte .sub{color:var(--muted);margin:0 0 18px;font-size:14.5px}';
    $html .= '.feld{border-top:1px solid var(--line);padding:12px 0 0;margin:0 0 12px}';
    $html .= '.feld dt{font-size:11px;font-weight:700;letter-spacing:.08em;text-transform:uppercase;';
    $html .= 'color:var(--muted);margin:0 0 3px}';
    $html .= '.feld dd{margin:0;font-weight:650}';
    $html .= '.blaettern{display:flex;gap:8px;margin-top:16px}';
    $html .= '.blaettern button{flex:1;text-align:center;line-height:1.25;padding:11px 8px}';
    $html .= '.legende{display:flex;gap:22px;flex-wrap:wrap;margin:16px 0 0;font-size:13.5px;color:var(--muted)}';
    $html .= '.legende span{display:inline-flex;align-items:center;gap:9px}';
    $html .= '.strich{width:30px;height:0;border-top-width:3px;border-top-style:solid;display:inline-block}';
    $html .= '.fuss{margin:14px 0 0;font-size:13px;color:var(--muted);max-width:80ch}';
    $html .= '.fehler{padding:40px;text-align:center;color:var(--muted)}';
    $html .= 'a{color:var(--ac)}';
    $html .= '</style>';
    $html .= '</head>';
    $html .= '<body>';
    $html .= '<div class="wrap">';

    $html .= '<p class="technik">three.js · r128</p>';
    $html .= '<h1>MCP-Server-Monitor</h1>';
    $html .= '<p class="lede">Warum fehlen die Tools? Vier Schichten von der Netz-Sonde bis zur Ausgabe — drehen, zoomen, Knoten auswählen.</p>';

    $html .= '<div class="raster">';
    $html .= '<div class="buehne" id="buehne">';
    $html .= '<div class="knoepfe">';
    $html .= '<button id="btn-plus" title="Näher">+</button>';
    $html .= '<button id="btn-minus" title="Weiter weg">−</button>';
    $html .= '<button id="btn-reset">Zurücksetzen</button>';
    $html .= '<button id="btn-iso" aria-pressed="true" title="Isometrisch oder perspektivisch">Iso</button>';
    $html .= '</div>';
    $html .= '</div>';

    $html .= '<aside class="karte">';
    $html .= '<h2>Ausgewählter Knoten</h2>';
    $html .= '<h3 id="k-name">—</h3>';
    $html .= '<p class="sub" id="k-sub">Knoten anklicken oder durchblättern</p>';
    $html .= '<dl class="feld"><dt>Schicht</dt><dd id="k-schicht">—</dd></dl>';
    $html .= '<dl class="feld"><dt>ID</dt><dd id="k-id">—</dd></dl>';
    $html .= '<div class="blaettern">';
    $html .= '<button id="btn-prev">←<br>Vorheriger</button>';
    $html .= '<button id="btn-next">Nächster<br>→</button>';
    $html .= '</div>';
    $html .= '</aside>';
    $html .= '</div>';

    $html .= '<div class="legende" id="legende"></div>';
    $html .= '<p class="fuss">Schematische Dokumentationsansicht — Blockgrößen messen weder Datenmenge noch Leistung. Keine Telemetrie, keine Fernabfragen: Die Seite lädt einmalig three.js vom CDN und rechnet danach ausschließlich lokal.</p>';

    $html .= '</div>';

    $html .= '<script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>';
    $html .= '<script>';
    $html .= '(function(){';
    $html .= '"use strict";';
    $html .= 'var SPEC = {"schichten": [{"name": "Quellen", "farbe": "#5f6773", "blocks": [{"id": "mcp-domain", "name": "mcp.DOMAIN", "untertitel": "Streamable HTTP"}, {"id": "docs-mcp", "name": "docs/mcp", "untertitel": "Anbieterdoku"}, {"id": "well-known", "name": ".well-known", "untertitel": "OAuth-Metadaten"}, {"id": "config-json", "name": "config.json", "untertitel": "claude_desktop_config"}]}, {"name": "Sonde", "farbe": "#2481cc", "blocks": [{"id": "discovery-py", "name": "discovery.py", "untertitel": "sechs Pfade"}, {"id": "config-py", "name": "config.py", "untertitel": "MSIX-Falle"}]}, {"name": "Klassifikation", "farbe": "#6d5bd0", "blocks": [{"id": "state-py", "name": "state.py", "untertitel": "fuenf Zustaende"}]}, {"name": "Ausgabe", "farbe": "#15803d", "blocks": [{"id": "report-py", "name": "report.py", "untertitel": "Textausgabe"}, {"id": "server-py", "name": "server.py", "untertitel": "127.0.0.1"}, {"id": "index-html", "name": "index.html", "untertitel": "statische Seite"}]}], "kanten": [{"von": "mcp-domain", "nach": "discovery-py", "art": "fluss"}, {"von": "docs-mcp", "nach": "config-py", "art": "fluss"}, {"von": "well-known", "nach": "discovery-py", "art": "fluss"}, {"von": "config-json", "nach": "config-py", "art": "fluss"}, {"von": "discovery-py", "nach": "state-py", "art": "fluss"}, {"von": "config-py", "nach": "state-py", "art": "fluss"}, {"von": "state-py", "nach": "report-py", "art": "fluss"}], "kantenarten": [{"art": "fluss", "farbe": "#6d5bd0", "stil": "voll", "text": "Fluss von unten nach oben"}]};';

    $html .= 'var buehne = document.getElementById("buehne");';
    $html .= 'if (typeof THREE === "undefined"){';
    $html .= 'buehne.insertAdjacentHTML("beforeend",';
    $html .= '\'<div class="fehler">three.js konnte nicht geladen werden. \' +';
    $html .= '\'Die Seite braucht einmalig Netzzugang zum CDN.</div>\');';
    $html .= 'return;';
    $html .= '}';

    $html .= '// ---------------------------------------------------------------- Szene ---';
    $html .= 'var szene = new THREE.Scene();';
    $html .= 'szene.background = new THREE.Color(0x0e1420);';
    $html .= 'var renderer = new THREE.WebGLRenderer({antialias:true});';
    $html .= 'renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));';
    $html .= 'buehne.appendChild(renderer.domElement);';

    $html .= 'var D = 26, radius = 82, aspekt = 1;';
    $html .= 'var kameraIso = new THREE.OrthographicCamera(-D, D, D, -D, 0.1, 600);';
    $html .= 'var kameraPersp = new THREE.PerspectiveCamera(42, 1, 0.1, 600);';
    $html .= 'var kamera = kameraIso, iso = true;';

    $html .= 'szene.add(new THREE.AmbientLight(0xffffff, 0.66));';
    $html .= 'var licht = new THREE.DirectionalLight(0xffffff, 0.8);';
    $html .= 'licht.position.set(30, 46, 26); szene.add(licht);';
    $html .= 'var gegen = new THREE.DirectionalLight(0x8ea2ff, 0.3);';
    $html .= 'gegen.position.set(-32, 16, -28); szene.add(gegen);';

    $html .= 'var raster = new THREE.GridHelper(110, 34, 0x25324a, 0x1a2333);';
    $html .= 'raster.position.y = -24; szene.add(raster);';

    $html .= '// ------------------------------------------------------------ Schilder ---';
    $html .= '// Text auf eine Textur, dann als Billboard — bleibt bei jeder Drehung lesbar.';
    $html .= 'function schild(text, unter){';
    $html .= 'var c = document.createElement("canvas"), x = c.getContext("2d");';
    $html .= 'var f1 = "700 40px -apple-system,Segoe UI,Roboto,sans-serif";';
    $html .= 'var f2 = "500 27px -apple-system,Segoe UI,Roboto,sans-serif";';
    $html .= 'x.font = f1; var w1 = x.measureText(text).width;';
    $html .= 'x.font = f2; var w2 = unter ? x.measureText(unter).width : 0;';
    $html .= 'var w = Math.ceil(Math.max(w1, w2)) + 40, h = unter ? 96 : 62;';
    $html .= 'c.width = w; c.height = h;';
    $html .= 'x = c.getContext("2d");';
    $html .= 'x.fillStyle = "rgba(255,255,255,.95)";';
    $html .= 'if (x.roundRect){ x.beginPath(); x.roundRect(0,0,w,h,13); x.fill(); }';
    $html .= 'else x.fillRect(0,0,w,h);';
    $html .= 'x.fillStyle = "#16191d"; x.font = f1; x.textBaseline = "middle";';
    $html .= 'x.fillText(text, 20, unter ? 32 : 31);';
    $html .= 'if (unter){ x.fillStyle = "#5f6773"; x.font = f2; x.fillText(unter, 20, 68); }';
    $html .= 'var t = new THREE.CanvasTexture(c); t.minFilter = THREE.LinearFilter;';
    $html .= 'var s = new THREE.Sprite(new THREE.SpriteMaterial({map:t, transparent:true, depthTest:false}));';
    $html .= 's.scale.set(w/62*2.5, h/62*2.5, 1);';
    $html .= 's.renderOrder = 999;';
    $html .= 'return s;';
    $html .= '}';

    $html .= '// -------------------------------------------------------------- Aufbau ---';
    $html .= 'var BW = 7.4, BD = 4.2, BH = 1.7, LUFT = 1.3, ABSTAND = 11.4, START = -17;';
    $html .= 'var knoten = [], nachId = {}, klickbar = [];';
    $html .= 'var gruppe = new THREE.Group();';

    $html .= 'SPEC.schichten.forEach(function(sch, si){';
    $html .= 'var y = START + si * ABSTAND;';
    $html .= 'var bl = sch.blocks.map(function(b){';
    $html .= 'return (typeof b === "string") ? {id:null, name:b, untertitel:""} : b;';
    $html .= '});';
    $html .= 'var spalten = Math.max(1, Math.ceil(bl.length / 2));';
    $html .= 'var reihen = bl.length <= 1 ? 1 : 2;';
    $html .= 'var gx = spalten*BW + (spalten-1)*LUFT, gz = reihen*BD + (reihen-1)*LUFT;';

    $html .= 'var platte = new THREE.Mesh(';
    $html .= 'new THREE.BoxGeometry(gx+3, 0.6, gz+3),';
    $html .= 'new THREE.MeshLambertMaterial({color:new THREE.Color(sch.farbe).multiplyScalar(0.4)}));';
    $html .= 'platte.position.set(0, y-1.7, 0); gruppe.add(platte);';

    $html .= 'bl.forEach(function(b, i){';
    $html .= 'var sp = i % spalten, re = Math.floor(i / spalten);';
    $html .= 'var x = -gx/2 + BW/2 + sp*(BW+LUFT), z = -gz/2 + BD/2 + re*(BD+LUFT);';
    $html .= 'var mat = new THREE.MeshLambertMaterial({color:sch.farbe});';
    $html .= 'var m = new THREE.Mesh(new THREE.BoxGeometry(BW, BH, BD), mat);';
    $html .= 'm.position.set(x, y, z);';
    $html .= 'gruppe.add(m); klickbar.push(m);';
    $html .= 'var kante = new THREE.LineSegments(new THREE.EdgesGeometry(m.geometry),';
    $html .= 'new THREE.LineBasicMaterial({color:0x0e1420, transparent:true, opacity:.55}));';
    $html .= 'kante.position.copy(m.position); gruppe.add(kante);';

    $html .= 'var s = schild(b.name, b.untertitel);';
    $html .= 's.position.set(x, y + BH/2 + (b.untertitel ? 2.1 : 1.6), z);';
    $html .= 'gruppe.add(s);';

    $html .= 'var id = b.id || (b.name.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, ""));';
    $html .= 'var eintrag = {id:id, name:b.name, untertitel:b.untertitel||"", schicht:sch.name,';
    $html .= 'mesh:m, mat:mat, farbe:new THREE.Color(sch.farbe), pos:m.position};';
    $html .= 'm.userData.index = knoten.length;';
    $html .= 'knoten.push(eintrag); nachId[id] = eintrag;';
    $html .= '});';
    $html .= '});';

    $html .= '// -------------------------------------------------------------- Kanten ---';
    $html .= 'var STIL = {};';
    $html .= '(SPEC.kantenarten || []).forEach(function(a){ STIL[a.art] = a; });';

    $html .= '(SPEC.kanten || []).forEach(function(k){';
    $html .= 'var a = nachId[k.von], b = nachId[k.nach];';
    $html .= 'if (!a || !b) return;';
    $html .= 'var art = STIL[k.art] || {farbe:"#8ea2ff", stil:"voll"};';
    $html .= 'var g = new THREE.BufferGeometry().setFromPoints([';
    $html .= 'a.pos.clone().setY(a.pos.y + 0.9), b.pos.clone().setY(b.pos.y - 0.9)]);';
    $html .= 'var linie;';
    $html .= 'if (art.stil === "gestrichelt"){';
    $html .= 'linie = new THREE.Line(g, new THREE.LineDashedMaterial(';
    $html .= '{color:art.farbe, dashSize:1.4, gapSize:1.0, transparent:true, opacity:.9}));';
    $html .= 'linie.computeLineDistances();';
    $html .= '} else {';
    $html .= 'linie = new THREE.Line(g, new THREE.LineBasicMaterial(';
    $html .= '{color:art.farbe, transparent:true, opacity:.85}));';
    $html .= '}';
    $html .= 'gruppe.add(linie);';
    $html .= '});';

    $html .= 'szene.add(gruppe);';

    $html .= 'var leg = document.getElementById("legende");';
    $html .= '(SPEC.kantenarten || []).forEach(function(a){';
    $html .= 'var s = document.createElement("span");';
    $html .= 's.innerHTML = \'<i class="strich" style="border-top-color:\' + a.farbe +';
    $html .= '\';border-top-style:\' + (a.stil === "gestrichelt" ? "dashed" : "solid") +';
    $html .= '\'"></i>\' + a.text;';
    $html .= 'leg.appendChild(s);';
    $html .= '});';

    $html .= '// ------------------------------------------------------------- Auswahl ---';
    $html .= 'var aktiv = -1;';
    $html .= 'function waehle(i){';
    $html .= 'if (aktiv >= 0){';
    $html .= 'knoten[aktiv].mat.color.copy(knoten[aktiv].farbe);';
    $html .= 'knoten[aktiv].mat.emissive.setHex(0x000000);';
    $html .= 'knoten[aktiv].mesh.scale.set(1,1,1);';
    $html .= '}';
    $html .= 'aktiv = ((i % knoten.length) + knoten.length) % knoten.length;';
    $html .= 'var k = knoten[aktiv];';
    $html .= 'k.mat.emissive.setHex(0x333333);';
    $html .= 'k.mesh.scale.set(1.1, 1.5, 1.1);';
    $html .= 'document.getElementById("k-name").textContent = k.name;';
    $html .= 'document.getElementById("k-sub").textContent = k.untertitel || "—";';
    $html .= 'document.getElementById("k-schicht").textContent = k.schicht;';
    $html .= 'document.getElementById("k-id").textContent = k.id;';
    $html .= '}';

    $html .= 'var strahl = new THREE.Raycaster(), zeiger = new THREE.Vector2();';
    $html .= 'renderer.domElement.addEventListener("click", function(e){';
    $html .= 'if (gezogen) return;';
    $html .= 'var r = renderer.domElement.getBoundingClientRect();';
    $html .= 'zeiger.x = ((e.clientX - r.left) / r.width) * 2 - 1;';
    $html .= 'zeiger.y = -((e.clientY - r.top) / r.height) * 2 + 1;';
    $html .= 'strahl.setFromCamera(zeiger, kamera);';
    $html .= 'var treffer = strahl.intersectObjects(klickbar, false);';
    $html .= 'if (treffer.length) waehle(treffer[0].object.userData.index);';
    $html .= '});';
    $html .= 'document.getElementById("btn-prev").addEventListener("click", function(){ waehle(aktiv - 1); });';
    $html .= 'document.getElementById("btn-next").addEventListener("click", function(){ waehle(aktiv + 1); });';

    $html .= '// ------------------------------------------------------------- Kamera ----';
    $html .= 'var azimut = Math.PI/4, elevation = 0.62, rotiert = true;';
    $html .= 'function stelle(){';
    $html .= 'var x = radius*Math.cos(elevation)*Math.sin(azimut);';
    $html .= 'var y = radius*Math.sin(elevation);';
    $html .= 'var z = radius*Math.cos(elevation)*Math.cos(azimut);';
    $html .= 'kamera.position.set(x, y, z); kamera.lookAt(0, 0, 0);';
    $html .= '}';
    $html .= 'var zieht = false, gezogen = false, lx = 0, ly = 0;';
    $html .= 'renderer.domElement.addEventListener("pointerdown", function(e){';
    $html .= 'zieht = true; gezogen = false; lx = e.clientX; ly = e.clientY;';
    $html .= '});';
    $html .= 'window.addEventListener("pointermove", function(e){';
    $html .= 'if (!zieht) return;';
    $html .= 'if (Math.abs(e.clientX-lx) + Math.abs(e.clientY-ly) > 3){ gezogen = true; rotiert = false; }';
    $html .= 'azimut -= (e.clientX - lx) * 0.006;';
    $html .= 'elevation = Math.max(0.08, Math.min(1.45, elevation + (e.clientY - ly) * 0.005));';
    $html .= 'lx = e.clientX; ly = e.clientY;';
    $html .= '});';
    $html .= 'window.addEventListener("pointerup", function(){ zieht = false; setTimeout(function(){ gezogen = false; }, 0); });';

    $html .= 'function zoom(f){';
    $html .= 'if (iso){ D = Math.max(11, Math.min(54, D * f)); groesse(); }';
    $html .= 'else { radius = Math.max(32, Math.min(160, radius * f)); }';
    $html .= '}';
    $html .= 'document.getElementById("btn-plus").addEventListener("click", function(){ zoom(0.85); });';
    $html .= 'document.getElementById("btn-minus").addEventListener("click", function(){ zoom(1.18); });';
    $html .= 'renderer.domElement.addEventListener("wheel", function(e){';
    $html .= 'e.preventDefault(); zoom(e.deltaY > 0 ? 1.08 : 0.93);';
    $html .= '}, {passive:false});';
    $html .= 'document.getElementById("btn-reset").addEventListener("click", function(){';
    $html .= 'azimut = Math.PI/4; elevation = 0.62; D = 26; radius = 82; rotiert = true;';
    $html .= 'iso = true; kamera = kameraIso;';
    $html .= 'document.getElementById("btn-iso").setAttribute("aria-pressed", "true");';
    $html .= 'document.getElementById("btn-iso").textContent = "Iso";';
    $html .= 'waehle(0); groesse();';
    $html .= '});';
    $html .= 'document.getElementById("btn-iso").addEventListener("click", function(){';
    $html .= 'iso = !iso; kamera = iso ? kameraIso : kameraPersp;';
    $html .= 'this.setAttribute("aria-pressed", String(iso));';
    $html .= 'this.textContent = iso ? "Iso" : "Persp";';
    $html .= 'groesse();';
    $html .= '});';

    $html .= 'function groesse(){';
    $html .= 'var w = buehne.clientWidth, h = buehne.clientHeight;';
    $html .= 'aspekt = w / h;';
    $html .= 'kameraIso.left = -D*aspekt; kameraIso.right = D*aspekt;';
    $html .= 'kameraIso.top = D; kameraIso.bottom = -D; kameraIso.updateProjectionMatrix();';
    $html .= 'kameraPersp.aspect = aspekt; kameraPersp.updateProjectionMatrix();';
    $html .= 'renderer.setSize(w, h, false);';
    $html .= '}';
    $html .= 'window.addEventListener("resize", groesse);';

    $html .= 'groesse();';
    $html .= 'waehle(0);';
    $html .= '(function schleife(){';
    $html .= 'requestAnimationFrame(schleife);';
    $html .= 'if (rotiert) azimut += 0.003;';
    $html .= 'stelle();';
    $html .= 'renderer.render(szene, kamera);';
    $html .= '})();';
    $html .= '})();';
    $html .= '</script>';
    $html .= '</body>';
    $html .= '</html>';

    return $html;
}

// Hauptausführung
if (isset($argv[1])) {
    // Wenn ein Dateiname als Parameter übergeben wurde, speichere die Ausgabe in diese Datei
    $filename = $argv[1];
    file_put_contents($filename, generate3dPage());
    echo "Datei '$filename' erfolgreich erstellt.\n";
} else {
    // Ansonsten gib den HTML-Code direkt aus
    echo generate3dPage();
}
?>
