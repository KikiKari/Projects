#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "358ab145b2e1257b45479e5ca9ff65fa8d64830bdc3e7b720008cf35c067f0d6", "source_sha256": "6d5dca1c8e19dae2ce42eb7176af64667ccb1401e8cd9c26f7687d201f7eeca8", "target_language": "lua"}
-- 3d.html — portiert nach lua
-- Quelle: html, Projects@TikTok-Live-Companion:public/3d.html
-- auch in: Projects@TikTok-Live-Companion-Android:public/3d.html
-- auch in: Projects@TikTok-Live-Companion-iOS:public/3d.html
-- auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:public/3d.html
-- auch in: 1 weiteren Fundstellen
-- Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

local function escape_html(text)
  local replacements = {
    ["&"] = "&amp;",
    ["<"] = "&lt;",
    [">"] = "&gt;",
    ['"'] = "&quot;",
    ["'"] = "&#39;"
  }
  return text:gsub("[&<>\"']", replacements)
end

local function generate_html(spec)
  local html = {}

  table.insert(html, '<!DOCTYPE html>')
  table.insert(html, '<html lang="de">')
  table.insert(html, '<head>')
  table.insert(html, '<meta charset="utf-8">')
  table.insert(html, '<meta name="viewport" content="width=device-width, initial-scale=1">')
  table.insert(html, '<title>TikTok LIVE Companion — Interaktive Architektur</title>')
  table.insert(html, '<meta name="description" content="Die Schichtsicht der Browser-Erweiterung: Quelle, Beobachtung, Zustand, Ausgabe.">')
  table.insert(html, '<meta name="theme-color" content="#fe2c55">')
  table.insert(html, '<style>')
  table.insert(html, '  :root{')
  table.insert(html, '    --bg:#fbfaf7; --panel:#fff; --line:#e6e3dc; --text:#16191d; --muted:#5f6773;')
  table.insert(html, '    --ac:#fe2c55; --buehne:#0e1420; --buehne-line:#1d2739;')
  table.insert(html, '    color-scheme: light;')
  table.insert(html, '  }')
  table.insert(html, '  @media (prefers-color-scheme: dark){')
  table.insert(html, '    :root{ --bg:#0f1115; --panel:#171a21; --line:#262b36; --text:#f2f4f8; --muted:#9aa3b2;')
  table.insert(html, '           color-scheme: dark; }')
  table.insert(html, '  }')
  table.insert(html, '  *{box-sizing:border-box}')
  table.insert(html, '  body{margin:0;background:var(--bg);color:var(--text);')
  table.insert(html, '       font:15px/1.55 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif}')
  table.insert(html, '  .wrap{max-width:1240px;margin:0 auto;padding:34px 22px 60px}')
  table.insert(html, '  .technik{font-size:12px;font-weight:700;letter-spacing:.1em;text-transform:uppercase;')
  table.insert(html, '           color:var(--ac);margin:0 0 10px}')
  table.insert(html, '  h1{font-size:clamp(30px,5vw,52px);line-height:1.05;margin:0 0 14px;letter-spacing:-.03em}')
  table.insert(html, '  .lede{font-size:16.5px;color:var(--muted);max-width:62ch;margin:0 0 26px}')
  table.insert(html, '  .raster{display:grid;grid-template-columns:minmax(0,1fr) 288px;gap:18px;align-items:start}')
  table.insert(html, '  @media (max-width:880px){ .raster{grid-template-columns:1fr} }')
  table.insert(html, '  .buehne{position:relative;background:var(--buehne);border-radius:14px;overflow:hidden;')
  table.insert(html, '          min-height:520px;aspect-ratio:16/11}')
  table.insert(html, '  .buehne canvas{display:block;width:100%;height:100%}')
  table.insert(html, '  .knoepfe{position:absolute;top:14px;right:14px;display:flex;gap:8px;z-index:2}')
  table.insert(html, '  button{font:inherit;font-size:14px;font-weight:650;padding:9px 14px;border-radius:9px;')
  table.insert(html, '         border:1px solid var(--line);background:var(--panel);color:var(--text);cursor:pointer}')
  table.insert(html, '  button:hover{border-color:var(--ac)}')
  table.insert(html, '  button[aria-pressed="true"]{background:var(--ac);border-color:var(--ac);color:#fff}')
  table.insert(html, '  .karte{background:var(--panel);border:1px solid var(--line);border-radius:14px;padding:20px}')
  table.insert(html, '  .karte h2{font-size:11px;font-weight:700;letter-spacing:.09em;text-transform:uppercase;')
  table.insert(html, '            color:var(--muted);margin:0 0 12px}')
  table.insert(html, '  .karte h3{font-size:23px;margin:0 0 4px;letter-spacing:-.02em}')
  table.insert(html, '  .karte .sub{color:var(--muted);margin:0 0 18px;font-size:14.5px}')
  table.insert(html, '  .feld{border-top:1px solid var(--line);padding:12px 0 0;margin:0 0 12px}')
  table.insert(html, '  .feld dt{font-size:11px;font-weight:700;letter-spacing:.08em;text-transform:uppercase;')
  table.insert(html, '           color:var(--muted);margin:0 0 3px}')
  table.insert(html, '  .feld dd{margin:0;font-weight:650}')
  table.insert(html, '  .blaettern{display:flex;gap:8px;margin-top:16px}')
  table.insert(html, '  .blaettern button{flex:1;text-align:center;line-height:1.25;padding:11px 8px}')
  table.insert(html, '  .legende{display:flex;gap:22px;flex-wrap:wrap;margin:16px 0 0;font-size:13.5px;color:var(--muted)}')
  table.insert(html, '  .legende span{display:inline-flex;align-items:center;gap:9px}')
  table.insert(html, '  .strich{width:30px;height:0;border-top-width:3px;border-top-style:solid;display:inline-block}')
  table.insert(html, '  .fuss{margin:14px 0 0;font-size:13px;color:var(--muted);max-width:80ch}')
  table.insert(html, '  .fehler{padding:40px;text-align:center;color:var(--muted)}')
  table.insert(html, '  a{color:var(--ac)}')
  table.insert(html, '</style>')
  table.insert(html, '</head>')
  table.insert(html, '<body>')
  table.insert(html, '<div class="wrap">')
  table.insert(html, '')
  table.insert(html, '  <p class="technik">three.js · r128</p>')
  table.insert(html, '  <h1>TikTok LIVE Companion</h1>')
  table.insert(html, '  <p class="lede">Die Schichtsicht der Browser-Erweiterung: Quelle, Beobachtung, Zustand, Ausgabe.</p>')
  table.insert(html, '')
  table.insert(html, '  <div class="raster">')
  table.insert(html, '    <div class="buehne" id="buehne">')
  table.insert(html, '      <div class="knoepfe">')
  table.insert(html, '        <button id="btn-plus" title="Näher">+</button>')
  table.insert(html, '        <button id="btn-minus" title="Weiter weg">−</button>')
  table.insert(html, '        <button id="btn-reset">Zurücksetzen</button>')
  table.insert(html, '        <button id="btn-iso" aria-pressed="true" title="Isometrisch oder perspektivisch">Iso</button>')
  table.insert(html, '      </div>')
  table.insert(html, '    </div>')
  table.insert(html, '')
  table.insert(html, '    <aside class="karte">')
  table.insert(html, '      <h2>Ausgewählter Knoten</h2>')
  table.insert(html, '      <h3 id="k-name">—</h3>')
  table.insert(html, '      <p class="sub" id="k-sub">Knoten anklicken oder durchblättern</p>')
  table.insert(html, '      <dl class="feld"><dt>Schicht</dt><dd id="k-schicht">—</dd></dl>')
  table.insert(html, '      <dl class="feld"><dt>ID</dt><dd id="k-id">—</dd></dl>')
  table.insert(html, '      <div class="blaettern">')
  table.insert(html, '        <button id="btn-prev">←<br>Vorheriger</button>')
  table.insert(html, '        <button id="btn-next">Nächster<br>→</button>')
  table.insert(html, '      </div>')
  table.insert(html, '    </aside>')
  table.insert(html, '  </div>')
  table.insert(html, '')
  table.insert(html, '  <div class="legende" id="legende"></div>')
  table.insert(html, '  <p class="fuss">Schematische Dokumentationsansicht — Blockgrößen messen weder Datenmenge noch Leistung. Keine Telemetrie, keine Fernabfragen: Die Seite lädt einmalig three.js vom CDN und rechnet danach ausschließlich lokal.</p>')
  table.insert(html, '')
  table.insert(html, '</div>')
  table.insert(html, '')
  table.insert(html, '<script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>')
  table.insert(html, '<script>')
  table.insert(html, '(function(){')
  table.insert(html, '  "use strict";')
  
  -- Generate spec JSON
  local json_spec = require("cjson").encode(spec)
  table.insert(html, '  var SPEC = ' .. json_spec .. ';')
  
  table.insert(html, '')
  table.insert(html, '  var buehne = document.getElementById("buehne");')
  table.insert(html, '  if (typeof THREE === "undefined"){')
  table.insert(html, '    buehne.insertAdjacentHTML("beforeend",')
  table.insert(html, '      \'<div class="fehler">three.js konnte nicht geladen werden. \' +')
  table.insert(html, '      \'Die Seite braucht einmalig Netzzugang zum CDN.</div>\');')
  table.insert(html, '    return;')
  table.insert(html, '  }')
  table.insert(html, '')
  table.insert(html, '  // ---------------------------------------------------------------- Szene ---')
  table.insert(html, '  var szene = new THREE.Scene();')
  table.insert(html, '  szene.background = new THREE.Color(0x0e1420);')
  table.insert(html, '  var renderer = new THREE.WebGLRenderer({antialias:true});')
  table.insert(html, '  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));')
  table.insert(html, '  buehne.appendChild(renderer.domElement);')
  table.insert(html, '')
  table.insert(html, '  var D = 26, radius = 82, aspekt = 1;')
  table.insert(html, '  var kameraIso = new THREE.OrthographicCamera(-D, D, D, -D, 0.1, 600);')
  table.insert(html, '  var kameraPersp = new THREE.PerspectiveCamera(42, 1, 0.1, 600);')
  table.insert(html, '  var kamera = kameraIso, iso = true;')
  table.insert(html, '')
  table.insert(html, '  szene.add(new THREE.AmbientLight(0xffffff, 0.66));')
  table.insert(html, '  var licht = new THREE.DirectionalLight(0xffffff, 0.8);')
  table.insert(html, '  licht.position.set(30, 46, 26); szene.add(licht);')
  table.insert(html, '  var gegen = new THREE.DirectionalLight(0x8ea2ff, 0.3);')
  table.insert(html, '  gegen.position.set(-32, 16, -28); szene.add(gegen);')
  table.insert(html, '')
  table.insert(html, '  var raster = new THREE.GridHelper(110, 34, 0x25324a, 0x1a2333);')
  table.insert(html, '  raster.position.y = -24; szene.add(raster);')
  table.insert(html, '')
  table.insert(html, '  // ------------------------------------------------------------ Schilder ---')
  table.insert(html, '  // Text auf eine Textur, dann als Billboard — bleibt bei jeder Drehung lesbar.')
  table.insert(html, '  function schild(text, unter){')
  table.insert(html, '    var c = document.createElement("canvas"), x = c.getContext("2d");')
  table.insert(html, '    var f1 = "700 40px -apple-system,Segoe UI,Roboto,sans-serif";')
  table.insert(html, '    var f2 = "500 27px -apple-system,Segoe UI,Roboto,sans-serif";')
  table.insert(html, '    x.font = f1; var w1 = x.measureText(text).width;')
  table.insert(html, '    x.font = f2; var w2 = unter ? x.measureText(unter).width : 0;')
  table.insert(html, '    var w = Math.ceil(Math.max(w1, w2)) + 40, h = unter ? 96 : 62;')
  table.insert(html, '    c.width = w; c.height = h;')
  table.insert(html, '    x = c.getContext("2d");')
  table.insert(html, '    x.fillStyle = "rgba(255,255,255,.95)";')
  table.insert(html, '    if (x.roundRect){ x.beginPath(); x.roundRect(0,0,w,h,13); x.fill(); }')
  table.insert(html, '    else x.fillRect(0,0,w,h);')
  table.insert(html, '    x.fillStyle = "#16191d"; x.font = f1; x.textBaseline = "middle";')
  table.insert(html, '    x.fillText(text, 20, unter ? 32 : 31);')
  table.insert(html, '    if (unter){ x.fillStyle = "#5f6773"; x.font = f2; x.fillText(unter, 20, 68); }')
  table.insert(html, '    var t = new THREE.CanvasTexture(c); t.minFilter = THREE.LinearFilter;')
  table.insert(html, '    var s = new THREE.Sprite(new THREE.SpriteMaterial({map:t, transparent:true, depthTest:false}));')
  table.insert(html, '    s.scale.set(w/62*2.5, h/62*2.5, 1);')
  table.insert(html, '    s.renderOrder = 999;')
  table.insert(html, '    return s;')
  table.insert(html, '  }')
  table.insert(html, '')
  table.insert(html, '  // -------------------------------------------------------------- Aufbau ---')
  table.insert(html, '  var BW = 7.4, BD = 4.2, BH = 1.7, LUFT = 1.3, ABSTAND = 11.4, START = -17;')
  table.insert(html, '  var knoten = [], nachId = {}, klickbar = [];')
  table.insert(html, '  var gruppe = new THREE.Group();')
  table.insert(html, '')
  table.insert(html, '  SPEC.schichten.forEach(function(sch, si){')
  table.insert(html, '    var y = START + si * ABSTAND;')
  table.insert(html, '    var bl = sch.blocks.map(function(b){')
  table.insert(html, '      return (typeof b === "string") ? {id:null, name:b, untertitel:""} : b;')
  table.insert(html, '    });')
  table.insert(html, '    var spalten = Math.max(1, Math.ceil(bl.length / 2));')
  table.insert(html, '    var reihen = bl.length <= 1 ? 1 : 2;')
  table.insert(html, '    var gx = spalten*BW + (spalten-1)*LUFT, gz = reihen*BD + (reihen-1)*LUFT;')
  table.insert(html, '')
  table.insert(html, '    var platte = new THREE.Mesh(')
  table.insert(html, '      new THREE.BoxGeometry(gx+3, 0.6, gz+3),')
  table.insert(html, '      new THREE.MeshLambertMaterial({color:new THREE.Color(sch.farbe).multiplyScalar(0.4)}));')
  table.insert(html, '    platte.position.set(0, y-1.7, 0); gruppe.add(platte);')
  table.insert(html, '')
  table.insert(html, '    bl.forEach(function(b, i){')
  table.insert(html, '      var sp = i % spalten, re = Math.floor(i / spalten);')
  table.insert(html, '      var x = -gx/2 + BW/2 + sp*(BW+LUFT), z = -gz/2 + BD/2 + re*(BD+LUFT);')
  table.insert(html, '      var mat = new THREE.MeshLambertMaterial({color:sch.farbe});')
  table.insert(html, '      var m = new THREE.Mesh(new THREE.BoxGeometry(BW, BH, BD), mat);')
  table.insert(html, '      m.position.set(x, y, z);')
  table.insert(html, '      gruppe.add(m); klickbar.push(m);')
  table.insert(html, '      var kante = new THREE.LineSegments(new THREE.EdgesGeometry(m.geometry),')
  table.insert(html, '        new THREE.LineBasicMaterial({color:0x0e1420, transparent:true, opacity:.55}));')
  table.insert(html, '      kante.position.copy(m.position); gruppe.add(kante);')
  table.insert(html, '')
  table.insert(html, '      var s = schild(b.name, b.untertitel);')
  table.insert(html, '      s.position.set(x, y + BH/2 + (b.untertitel ? 2.1 : 1.6), z);')
  table.insert(html, '      gruppe.add(s);')
  table.insert(html, '')
  table.insert(html, '      var id = b.id || (b.name.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, ""));')
  table.insert(html, '      var eintrag = {id:id, name:b.name, untertitel:b.untertitel||"", schicht:sch.name,')
  table.insert(html, '                     mesh:m, mat:mat, farbe:new THREE.Color(sch.farbe), pos:m.position};')
  table.insert(html, '      m.userData.index = knoten.length;')
  table.insert(html, '      knoten.push(eintrag); nachId[id] = eintrag;')
  table.insert(html, '    });')
  table.insert(html, '  });')
  table.insert(html, '')
  table.insert(html, '  // -------------------------------------------------------------- Kanten ---')
  table.insert(html, '  var STIL = {};')
  table.insert(html, '  (SPEC.kantenarten || []).forEach(function(a){ STIL[a.art] = a; });')
  table.insert(html, '')
  table.insert(html, '  (SPEC.kanten || []).forEach(function(k){')
  table.insert(html, '    var a = nachId[k.von], b = nachId[k.nach];')
  table.insert(html, '    if (!a || !b) return;')
  table.insert(html, '    var art = STIL[k.art] || {farbe:"#8ea2ff", stil:"voll"};')
  table.insert(html, '    var g = new THREE.BufferGeometry().setFromPoints([')
  table.insert(html, '      a.pos.clone().setY(a.pos.y + 0.9), b.pos.clone().setY(b.pos.y - 0.9)]);')
  table.insert(html, '    var linie;')
  table.insert(html, '    if (art.stil === "gestrichelt"){')
  table.insert(html, '      linie = new THREE.Line(g, new THREE.LineDashedMaterial(')
  table.insert(html, '        {color:art.farbe, dashSize:1.4, gapSize:1.0, transparent:true, opacity:.9}));')
  table.insert(html, '      linie.computeLineDistances();')
  table.insert(html, '    } else {')
  table.insert(html, '      linie = new THREE.Line(g, new THREE.LineBasicMaterial(')
  table.insert(html, '        {color:art.farbe, transparent:true, opacity:.85}));')
  table.insert(html, '    }')
  table.insert(html, '    gruppe.add(linie);')
  table.insert(html, '  });')
  table.insert(html, '')
  table.insert(html, '  szene.add(gruppe);')
  table.insert(html, '')
  table.insert(html, '  var leg = document.getElementById("legende");')
  table.insert(html, '  (SPEC.kantenarten || []).forEach(function(a){')
  table.insert(html, '    var s = document.createElement("span");')
  table.insert(html, '    s.innerHTML = \'<i class="strich" style="border-top-color:\' + a.farbe +')
  table.insert(html, '                  \';border-top-style:\' + (a.stil === "gestrichelt" ? "dashed" : "solid") +')
  table.insert(html, '                  \'"></i>\' + a.text;')
  table.insert(html, '    leg.appendChild(s);')
  table.insert(html, '  });')
  table.insert(html, '')
  table.insert(html, '  // ------------------------------------------------------------- Auswahl ---')
  table.insert(html, '  var aktiv = -1;')
  table.insert(html, '  function waehle(i){')
  table.insert(html, '    if (aktiv >= 0){')
  table.insert(html, '      knoten[aktiv].mat.color.copy(knoten[aktiv].farbe);')
  table.insert(html, '      knoten[aktiv].mat.emissive.setHex(0x000000);')
  table.insert(html, '      knoten[aktiv].mesh.scale.set(1,1,1);')
  table.insert(html, '    }')
  table.insert(html, '    aktiv = ((i % knoten.length) + knoten.length) % knoten.length;')
  table.insert(html, '    var k = knoten[aktiv];')
  table.insert(html, '    k.mat.emissive.setHex(0x333333);')
  table.insert(html, '    k.mesh.scale.set(1.1, 1.5, 1.1);')
  table.insert(html, '    document.getElementById("k-name").textContent = k.name;')
  table.insert(html, '    document.getElementById("k-sub").textContent = k.untertitel || "—";')
  table.insert(html, '    document.getElementById("k-schicht").textContent = k.schicht;')
  table.insert(html, '    document.getElementById("k-id").textContent = k.id;')
  table.insert(html, '  }')
  table.insert(html, '')
  table.insert(html, '  var strahl = new THREE.Raycaster(), zeiger = new THREE.Vector2();')
  table.insert(html, '  renderer.domElement.addEventListener("click", function(e){')
  table.insert(html, '    if (gezogen) return;')
  table.insert(html, '    var r = renderer.domElement.getBoundingClientRect();')
  table.insert(html, '    zeiger.x = ((e.clientX - r.left) / r.width) * 2 - 1;')
  table.insert(html, '    zeiger.y = -((e.clientY - r.top) / r.height) * 2 + 1;')
  table.insert(html, '    strahl.setFromCamera(zeiger, kamera);')
  table.insert(html, '    var treffer = strahl.intersectObjects(klickbar, false);')
  table.insert(html, '    if (treffer.length) waehle(treffer[0].object.userData.index);')
  table.insert(html, '  });')
  table.insert(html, '  document.getElementById("btn-prev").addEventListener("click", function(){ waehle(aktiv - 1); });')
  table.insert(html, '  document.getElementById("btn-next").addEventListener("click", function(){ waehle(aktiv + 1); });')
  table.insert(html, '')
  table.insert(html, '  // ------------------------------------------------------------- Kamera ----')
  table.insert(html, '  var azimut = Math.PI/4, elevation = 0.62, rotiert = true;')
  table.insert(html, '  function stelle(){')
  table.insert(html, '    var x = radius*Math.cos(elevation)*Math.sin(azimut);')
  table.insert(html, '    var y = radius*Math.sin(elevation);')
  table.insert(html, '    var z = radius*Math.cos(elevation)*Math.cos(azimut);')
  table.insert(html, '    kamera.position.set(x, y, z); kamera.lookAt(0, 0, 0);')
  table.insert(html, '  }')
  table.insert(html, '  var zieht = false, gezogen = false, lx = 0, ly = 0;')
  table.insert(html, '  renderer.domElement.addEventListener("pointerdown", function(e){')
  table.insert(html, '    zieht = true; gezogen = false; lx = e.clientX; ly = e.clientY;')
  table.insert(html, '  });')
  table.insert(html, '  window.addEventListener("pointermove", function(e){')
  table.insert(html, '    if (!zieht) return;')
  table.insert(html, '    if (Math.abs(e.clientX-lx) + Math.abs(e.clientY-ly) > 3){ gezogen = true; rotiert = false; }')
  table.insert(html, '    azimut -= (e.clientX - lx) * 0.006;')
  table.insert(html, '    elevation = Math.max(0.08, Math.min(1.45, elevation + (e.clientY - ly) * 0.005));')
  table.insert(html, '    lx = e.clientX; ly = e.clientY;')
  table.insert(html, '  });')
  table.insert(html, '  window.addEventListener("pointerup", function(){ zieht = false; setTimeout(function(){ gezogen = false; }, 0); });')
  table.insert(html, '')
  table.insert(html, '  function zoom(f){')
  table.insert(html, '    if (iso){ D = Math.max(11, Math.min(54, D * f)); groesse(); }')
  table.insert(html, '    else { radius = Math.max(32, Math.min(160, radius * f)); }')
  table.insert(html, '  }')
  table.insert(html, '  document.getElementById("btn-plus").addEventListener("click", function(){ zoom(0.85); });')
  table.insert(html, '  document.getElementById("btn-minus").addEventListener("click", function(){ zoom(1.18); });')
  table.insert(html, '  renderer.domElement.addEventListener("wheel", function(e){')
  table.insert(html, '    e.preventDefault(); zoom(e.deltaY > 0 ? 1.08 : 0.93);')
  table.insert(html, '  }, {passive:false});')
  table.insert(html, '  document.getElementById("btn-reset").addEventListener("click", function(){')
  table.insert(html, '    azimut = Math.PI/4; elevation = 0.62; D = 26; radius = 82; rotiert = true;')
  table.insert(html, '    iso = true; kamera = kameraIso;')
  table.insert(html, '    document.getElementById("btn-iso").setAttribute("aria-pressed", "true");')
  table.insert(html, '    document.getElementById("btn-iso").textContent = "Iso";')
  table.insert(html, '    waehle(0); groesse();')
  table.insert(html, '  });')
  table.insert(html, '  document.getElementById("btn-iso").addEventListener("click", function(){')
  table.insert(html, '    iso = !iso; kamera = iso ? kameraIso : kameraPersp;')
  table.insert(html, '    this.setAttribute("aria-pressed", String(iso));')
  table.insert(html, '    this.textContent = iso ? "Iso" : "Persp";')
  table.insert(html, '    groesse();')
  table.insert(html, '  });')
  table.insert(html, '')
  table.insert(html, '  function groesse(){')
  table.insert(html, '    var w = buehne.clientWidth, h = buehne.clientHeight;')
  table.insert(html, '    aspekt = w / h;')
  table.insert(html, '    kameraIso.left = -D*aspekt; kameraIso.right = D*aspekt;')
  table.insert(html, '    kameraIso.top = D; kameraIso.bottom = -D; kameraIso.updateProjectionMatrix();')
  table.insert(html, '    kameraPersp.aspect = aspekt; kameraPersp.updateProjectionMatrix();')
  table.insert(html, '    renderer.setSize(w, h, false);')
  table.insert(html, '  }')
  table.insert(html, '  window.addEventListener("resize", groesse);')
  table.insert(html, '')
  table.insert(html, '  groesse();')
  table.insert(html, '  waehle(0);')
  table.insert(html, '  (function schleife(){')
  table.insert(html, '    requestAnimationFrame(schleife);')
  table.insert(html, '    if (rotiert) azimut += 0.003;')
  table.insert(html, '    stelle();')
  table.insert(html, '    renderer.render(szene, kamera);')
  table.insert(html, '  })();')
  table.insert(html, '})();')
  table.insert(html, '</script>')
  table.insert(html, '</body>')
  table.insert(html, '</html>')

  return table.concat(html, "\n")
end

-- Main execution
local spec = {
  schichten = {
    {
      name = "Quelle",
      farbe = "#5f6773",
      blocks = {
        {id = "tiktok-live-tab", name = "TikTok-LIVE-Tab", untertitel = "oeffentliche Seite"},
        {id = "oeffentliche-dom-daten", name = "oeffentliche DOM-Daten", untertitel = "gelesen"},
        {id = "eingebettete-metadaten", name = "eingebettete Metadaten", untertitel = "JSON"}
      }
    },
    {
      name = "Beobachtung",
      farbe = "#2481cc",
      blocks = {
        {id = "content-js", name = "content.js", untertitel = "isolierte Welt"},
        {id = "websocket-hook", name = "WebSocket-Hook", untertitel = "passiv"}
      }
    },
    {
      name = "Zustand",
      farbe = "#6d5bd0",
      blocks = {
        {id = "background-js", name = "background.js", untertitel = "Filter + Zustand"},
        {id = "storage-session", name = "storage.session", untertitel = "fluechtig"}
      }
    },
    {
      name = "Ausgabe",
      farbe = "#fe2c55",
      blocks = {
        {id = "seitenpanel", name = "Seitenpanel", untertitel = "textContent"},
        {id = "vorlesen", name = "Vorlesen", untertitel = "lokal"},
        {id = "playersteuerung", name = "Playersteuerung", untertitel = "vorhandener Player"}
      }
    },
    {
      name = "Doku",
      farbe = "#0f766e",
      blocks = {
        {id = "docs-de", name = "docs/de", untertitel = "deutsch"},
        {id = "docs-en", name = "docs/en", untertitel = "englisch"},
        {id = "vercel-site", name = "Vercel-Site", untertitel = "statisch"}
      }
    }
  },
  kanten = {
    {von = "tiktok-live-tab", nach = "content-js", art = "fluss"},
    {von = "oeffentliche-dom-daten", nach = "websocket-hook", art = "fluss"},
    {von = "eingebettete-metadaten", nach = "content-js", art = "fluss"},
    {von = "content-js", nach = "background-js", art = "fluss"},
    {von = "websocket-hook", nach = "storage-session", art = "fluss"},
    {von = "background-js", nach = "seitenpanel", art = "fluss"},
    {von = "storage-session", nach = "vorlesen", art = "fluss"},
    {von = "seitenpanel", nach = "docs-de", art = "fluss"},
    {von = "vorlesen", nach = "docs-en", art = "fluss"},
    {von = "playersteuerung", nach = "vercel-site", art = "fluss"}
  },
  kantenarten = {
    {art = "fluss", farbe = "#fe2c55", stil = "voll", text = "Fluss von unten nach oben"}
  }
}

local html_content = generate_html(spec)

-- Write to file if filename provided as argument
if arg[1] then
  local file = io.open(arg[1], "w")
  if file then
    file:write(html_content)
    file:close()
    print("HTML file written to " .. arg[1])
  else
    print("Error: Could not write to file " .. arg[1])
  end
else
  print(html_content)
end
