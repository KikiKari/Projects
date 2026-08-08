#!/usr/bin/env perl
# 3d_31a461.ps1 — portiert nach perl5
# Quelle: powershell, Projects@abstractions:powershell/3d_31a461.ps1
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use Getopt::Long;
use File::Basename;

my $output_path;
GetOptions("output-path=s" => \$output_path) or die "Fehler in Kommandozeilenargumenten\n";

if (!$output_path) {
    die "Verwendung: $0 --output-path <Pfad>\n";
}

my $html_content = <<'HTML_END';
<!DOCTYPE html>
<html lang="de">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>TikTok LIVE Companion iOS — Interaktive Architektur</title>
<meta name="description" content="Die Schichtsicht der iOS-App: WKWebView, Brücke, SwiftUI, ShazamKit.">
<meta name="theme-color" content="#fe2c55">
<style>
  :root{
    --bg:#fbfaf7; --panel:#fff; --line:#e6e3dc; --text:#16191d; --muted:#5f6773;
    --ac:#fe2c55; --buehne:#0e1420; --buehne-line:#1d2739;
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
  <h1>TikTok LIVE Companion iOS</h1>
  <p class="lede">Die Schichtsicht der iOS-App: WKWebView, Brücke, SwiftUI, ShazamKit.</p>

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
      <dl class="feld"><dt>Schicht</dt><dd id="k-schicht">—</dd></dl>
      <dl class="feld"><dt>ID</dt><dd id="k-id">—</dd></dl>
      <div class="blaettern">
        <button id="btn-prev">←<br>Vorheriger</button>
        <button id="btn-next">Nächster<br>→</button>
      </div>
    </aside>
  </div>

  <div class="legende" id="legende"></div>
  <p class="fuss">Schematische Dokumentationsansicht — Blockgrößen messen weder Datenmenge noch Leistung. Keine Telemetrie, keine Fernabfragen: Die Seite lädt einmalig three.js vom CDN und rechnet danach ausschließlich lokal.</p>

</div>

<script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
<script>
(function(){
  "use strict";
  var SPEC = {"schichten": [{"name": "Quelle", "farbe": "#5f6773", "blocks": [{"id": "wkwebview", "name": "WKWebView", "untertitel": "Hauptframe"}, {"id": "www-tiktok-com", "name": "www.tiktok.com", "untertitel": "nur diese Origin"}, {"id": "hauptframe", "name": "Hauptframe", "untertitel": "kein iframe"}]}, {"name": "Bruecke", "farbe": "#2481cc", "blocks": [{"id": "mobile-bridge-v1", "name": "Mobile Bridge v1", "untertitel": "Origin + Typ"}, {"id": "origin-pruefung", "name": "Origin-Pruefung", "untertitel": "fail closed"}, {"id": "typ-groesse", "name": "Typ + Groesse", "untertitel": "begrenzt"}]}, {"name": "App", "farbe": "#6d5bd0", "blocks": [{"id": "swift", "name": "Swift", "untertitel": "Sprache"}, {"id": "swiftui", "name": "SwiftUI", "untertitel": "Oberflaeche"}, {"id": "webkit", "name": "WebKit", "untertitel": "WebView"}]}, {"name": "Audio", "farbe": "#b45309", "blocks": [{"id": "shazamkit", "name": "ShazamKit", "untertitel": "nur nach Klick"}, {"id": "mikrofon", "name": "Mikrofon", "untertitel": "stabil"}, {"id": "webview-pcm-exp", "name": "WebView-PCM (exp.)", "untertitel": "experimentell"}]}, {"name": "Ausgabe", "farbe": "#fe2c55", "blocks": [{"id": "fluechtiger-streamzustand", "name": "fluechtiger Streamzustand", "untertitel": "nicht persistiert"}, {"id": "panel", "name": "Panel", "untertitel": "Anzeige"}, {"id": "ipa", "name": "IPA", "untertitel": "iOS-Artefakt"}]}], "kanten": [{"von": "wkwebview", "nach": "mobile-bridge-v1", "art": "fluss"}, {"von": "www-tiktok-com", "nach": "origin-pruefung", "art": "fluss"}, {"von": "hauptframe", "nach": "typ-groesse", "art": "fluss"}, {"von": "mobile-bridge-v1", "nach": "swift", "art": "fluss"}, {"von": "origin-pruefung", "nach": "swiftui", "art": "fluss"}, {"von": "typ-groesse", "nach": "webkit", "art": "fluss"}, {"von": "swift", "nach": "shazamkit", "art": "fluss"}, {"von": "swiftui", "nach": "mikrofon", "art": "fluss"}, {"von": "webkit", "nach": "webview-pcm-exp", "art": "fluss"}, {"von": "shazamkit", "nach": "fluechtiger-streamzustand", "art": "fluss"}, {"von": "mikrofon", "nach": "panel", "art": "fluss"}, {"von": "webview-pcm-exp", "nach": "ipa", "art": "fluss"}], "kantenarten": [{"art": "fluss", "farbe": "#fe2c55", "stil": "voll", "text": "Fluss von unten nach oben"}]};

  var buehne = document.getElementById("buehne");
  if (typeof THREE === "undefined"){
    buehne.insertAdjacentHTML("beforeend",
      '<div class="fehler">three.js konnte nicht geladen werden. ' +
      'Die Seite braucht einmalig Netzzugang zum CDN.</div>');
    return;
  }

  // ---------------------------------------------------------------- Szene ---
  var szene = new THREE.Scene();
  szene.background = new THREE.Color(0x0e1420);
  var renderer = new THREE.WebGLRenderer({antialias:true});
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
  buehne.appendChild(renderer.domElement);

  var D = 26, radius = 82, aspekt = 1;
  var kameraIso = new THREE.OrthographicCamera(-D, D, D, -D, 0.1, 600);
  var kameraPersp = new THREE.PerspectiveCamera(42, 1, 0.1, 600);
  var kamera = kameraIso, iso = true;

  szene.add(new THREE.AmbientLight(0xffffff, 0.66));
  var licht = new THREE.DirectionalLight(0xffffff, 0.8);
  licht.position.set(30, 46, 26); szene.add(licht);
  var gegen = new THREE.DirectionalLight(0x8ea2ff, 0.3);
  gegen.position.set(-32, 16, -28); szene.add(gegen);

  var raster = new THREE.GridHelper(110, 34, 0x25324a, 0x1a2333);
  raster.position.y = -24; szene.add(raster);

  // ------------------------------------------------------------ Schilder ---
  // Text auf eine Textur, dann als Billboard — bleibt bei jeder Drehung lesbar.
  function schild(text, unter){
    var c = document.createElement("canvas"), x = c.getContext("2d");
    var f1 = "700 40px -apple-system,Segoe UI,Roboto,sans-serif";
    var f2 = "500 27px -apple-system,Segoe UI,Roboto,sans-serif";
    x.font = f1; var w1 = x.measureText(text).width;
    x.font = f2; var w2 = unter ? x.measureText(unter).width : 0;
    var w = Math.ceil(Math.max(w1, w2)) + 40, h = unter ? 96 : 62;
    c.width = w; c.height = h;
    x = c.getContext("2d");
    x.fillStyle = "rgba(255,255,255,.95)";
    if (x.roundRect){ x.beginPath(); x.roundRect(0,0,w,h,13); x.fill(); }
    else x.fillRect(0,0,w,h);
    x.fillStyle = "#16191d"; x.font = f1; x.textBaseline = "middle";
    x.fillText(text, 20, unter ? 32 : 31);
    if (unter){ x.fillStyle = "#5f6773"; x.font = f2; x.fillText(unter, 20, 68); }
    var t = new THREE.CanvasTexture(c); t.minFilter = THREE.LinearFilter;
    var s = new THREE.Sprite(new THREE.SpriteMaterial({map:t, transparent:true, depthTest:false}));
    s.scale.set(w/62*2.5, h/62*2.5, 1);
    s.renderOrder = 999;
    return s;
  }

  // -------------------------------------------------------------- Aufbau ---
  var BW = 7.4, BD = 4.2, BH = 1.7, LUFT = 1.3, ABSTAND = 11.4, START = -17;
  var knoten = [], nachId = {}, klickbar = [];
  var gruppe = new THREE.Group();

  SPEC.schichten.forEach(function(sch, si){
    var y = START + si * ABSTAND;
    var bl = sch.blocks.map(function(b){
      return (typeof b === "string") ? {id:null, name:b, untertitel:""} : b;
    });
    var spalten = Math.max(1, Math.ceil(bl.length / 2));
    var reihen = bl.length <= 1 ? 1 : 2;
    var gx = spalten*BW + (spalten-1)*LUFT, gz = reihen*BD + (reihen-1)*LUFT;

    var platte = new THREE.Mesh(
      new THREE.BoxGeometry(gx+3, 0.6, gz+3),
      new THREE.MeshLambertMaterial({color:new THREE.Color(sch.farbe).multiplyScalar(0.4)}));
    platte.position.set(0, y-1.7, 0); gruppe.add(platte);

    bl.forEach(function(b, i){
      var sp = i % spalten, re = Math.floor(i / spalten);
      var x = -gx/2 + BW/2 + sp*(BW+LUFT), z = -gz/2 + BD/2 + re*(BD+LUFT);
      var mat = new THREE.MeshLambertMaterial({color:sch.farbe});
      var m = new THREE.Mesh(new THREE.BoxGeometry(BW, BH, BD), mat);
      m.position.set(x, y, z);
      gruppe.add(m); klickbar.push(m);
      var kante = new THREE.LineSegments(new THREE.EdgesGeometry(m.geometry),
        new THREE.LineBasicMaterial({color:0x0e1420, transparent:true, opacity:.55}));
      kante.position.copy(m.position); gruppe.add(kante);

      var s = schild(b.name, b.untertitel);
      s.position.set(x, y + BH/2 + (b.untertitel ? 2.1 : 1.6), z);
      gruppe.add(s);

      var id = b.id || (b.name.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, ""));
      var eintrag = {id:id, name:b.name, untertitel:b.untertitel||"", schicht:sch.name,
                     mesh:m, mat:mat, farbe:new THREE.Color(sch.farbe), pos:m.position};
      m.userData.index = knoten.length;
      knoten.push(eintrag); nachId[id] = eintrag;
    });
  });

  // -------------------------------------------------------------- Kanten ---
  var STIL = {};
  (SPEC.kantenarten || []).forEach(function(a){ STIL[a.art] = a; });

  (SPEC.kanten || []).forEach(function(k){
    var a = nachId[k.von], b = nachId[k.nach];
    if (!a || !b) return;
    var art = STIL[k.art] || {farbe:"#8ea2ff", stil:"voll"};
    var g = new THREE.BufferGeometry().setFromPoints([
      a.pos.clone().setY(a.pos.y + 0.9), b.pos.clone().setY(b.pos.y - 0.9)]);
    var linie;
    if (art.stil === "gestrichelt"){
      linie = new THREE.Line(g, new THREE.LineDashedMaterial(
        {color:art.farbe, dashSize:1.4, gapSize:1.0, transparent:true, opacity:.9}));
      linie.computeLineDistances();
    } else {
      linie = new THREE.Line(g, new THREE.LineBasicMaterial(
        {color:art.farbe, transparent:true, opacity:.85}));
    }
    gruppe.add(linie);
  });

  szene.add(gruppe);

  var leg = document.getElementById("legende");
  (SPEC.kantenarten || []).forEach(function(a){
    var s = document.createElement("span");
    s.innerHTML = '<i class="strich" style="border-top-color:' + a.farbe +
                  ';border-top-style:' + (a.stil === "gestrichelt" ? "dashed" : "solid") +
                  '"></i>' + a.text;
    leg.appendChild(s);
  });

  // ------------------------------------------------------------- Auswahl ---
  var aktiv = -1;
  function waehle(i){
    if (aktiv >= 0){
      knoten[aktiv].mat.color.copy(knoten[aktiv].farbe);
      knoten[aktiv].mat.emissive.setHex(0x000000);
      knoten[aktiv].mesh.scale.set(1,1,1);
    }
    aktiv = ((i % knoten.length) + knoten.length) % knoten.length;
    var k = knoten[aktiv];
    k.mat.emissive.setHex(0x333333);
    k.mesh.scale.set(1.1, 1.5, 1.1);
    document.getElementById("k-name").textContent = k.name;
    document.getElementById("k-sub").textContent = k.untertitel || "—";
    document.getElementById("k-schicht").textContent = k.schicht;
    document.getElementById("k-id").textContent = k.id;
  }

  var strahl = new THREE.Raycaster(), zeiger = new THREE.Vector2();
  renderer.domElement.addEventListener("click", function(e){
    if (gezogen) return;
    var r = renderer.domElement.getBoundingClientRect();
    zeiger.x = ((e.clientX - r.left) / r.width) * 2 - 1;
    zeiger.y = -((e.clientY - r.top) / r.height) * 2 + 1;
    strahl.setFromCamera(zeiger, kamera);
    var treffer = strahl.intersectObjects(klickbar, false);
    if (treffer.length) waehle(treffer[0].object.userData.index);
  });
  document.getElementById("btn-prev").addEventListener("click", function(){ waehle(aktiv - 1); });
  document.getElementById("btn-next").addEventListener("click", function(){ waehle(aktiv + 1); });

  // ------------------------------------------------------------- Kamera ----
  var azimut = Math.PI/4, elevation = 0.62, rotiert = true;
  function stelle(){
    var x = radius*Math.cos(elevation)*Math.sin(azimut);
    var y = radius*Math.sin(elevation);
    var z = radius*Math.cos(elevation)*Math.cos(azimut);
    kamera.position.set(x, y, z); kamera.lookAt(0, 0, 0);
  }
  var zieht = false, gezogen = false, lx = 0, ly = 0;
  renderer.domElement.addEventListener("pointerdown", function(e){
    zieht = true; gezogen = false; lx = e.clientX; ly = e.clientY;
  });
  window.addEventListener("pointermove", function(e){
    if (!zieht) return;
    if (Math.abs(e.clientX-lx) + Math.abs(e.clientY-ly) > 3){ gezogen = true; rotiert = false; }
    azimut -= (e.clientX - lx) * 0.006;
    elevation = Math.max(0.08, Math.min(1.45, elevation + (e.clientY - ly) * 0.005));
    lx = e.clientX; ly = e.clientY;
  });
  window.addEventListener("pointerup", function(){ zieht = false; setTimeout(function(){ gezogen = false; }, 0); });

  function zoom(f){
    if (iso){ D = Math.max(11, Math.min(54, D * f)); groesse(); }
    else { radius = Math.max(32, Math.min(160, radius * f)); }
  }
  document.getElementById("btn-plus").addEventListener("click", function(){ zoom(0.85); });
  document.getElementById("btn-minus").addEventListener("click", function(){ zoom(1.18); });
  renderer.domElement.addEventListener("wheel", function(e){
    e.preventDefault(); zoom(e.deltaY > 0 ? 1.08 : 0.93);
  }, {passive:false});
  document.getElementById("btn-reset").addEventListener("click", function(){
    azimut = Math.PI/4; elevation = 0.62; D = 26; radius = 82; rotiert = true;
    iso = true; kamera = kameraIso;
    document.getElementById("btn-iso").setAttribute("aria-pressed", "true");
    document.getElementById("btn-iso").textContent = "Iso";
    waehle(0); groesse();
  });
  document.getElementById("btn-iso").addEventListener("click", function(){
    iso = !iso; kamera = iso ? kameraIso : kameraPersp;
    this.setAttribute("aria-pressed", String(iso));
    this.textContent = iso ? "Iso" : "Persp";
    groesse();
  });

  function groesse(){
    var w = buehne.clientWidth, h = buehne.clientHeight;
    aspekt = w / h;
    kameraIso.left = -D*aspekt; kameraIso.right = D*aspekt;
    kameraIso.top = D; kameraIso.bottom = -D; kameraIso.updateProjectionMatrix();
    kameraPersp.aspect = aspekt; kameraPersp.updateProjectionMatrix();
    renderer.setSize(w, h, false);
  }
  window.addEventListener("resize", groesse);

  groesse();
  waehle(0);
  (function schleife(){
    requestAnimationFrame(schleife);
    if (rotiert) azimut += 0.003;
    stelle();
    renderer.render(szene, kamera);
  })();
})();
</script>
</body>
</html>
HTML_END

open my $fh, '>:encoding(UTF-8)', $output_path or die "Konnte Datei '$output_path' nicht öffnen: $!";
print $fh $html_content;
close $fh;
