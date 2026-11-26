// abstraction-provenance: {"artifact_sha256": "effa418e3fd76aab9f91c04ef02f5047c7d38e2b83c0f71305168bc43e210f3f", "source_sha256": "94885729e4ba377ddf2cb9714fce69ca5f9b052fac60946fde97fad90b92060b", "target_language": "fsharp"}
// 3d.html — portiert nach fsharp
// Quelle: html, Projects@tiktok-monitor:public/3d.html
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

open System
open System.IO
open System.Text

type Schicht = { name: string; farbe: string; blocks: Block list }
and Block = { id: string; name: string; untertitel: string }
type Kante = { von: string; nach: string; art: string }
type Kantenart = { art: string; farbe: string; stil: string; text: string }
type Spec = { schichten: Schicht list; kanten: Kante list; kantenarten: Kantenart list }

let spec =
    { schichten = 
        [ { name = "Quellen"
            farbe = "#5f6773"
            blocks = 
                [ { id = "tiktok-com-user"; name = "tiktok.com/@user"; untertitel = "oeffentlich" }
                  { id = "room-id"; name = "room_id"; untertitel = "aufgeloest" }
                  { id = "m3u8"; name = "m3u8"; untertitel = "Stream-URL" } ] }
          { name = "Werkzeuge"
            farbe = "#2481cc"
            blocks = 
                [ { id = "get-room-id-py"; name = "get_room_id.py"; untertitel = "handle -> id" }
                  { id = "check-alive-py"; name = "check_alive.py"; untertitel = "live ja/nein" }
                  { id = "tt-live-py"; name = "tt_live.py"; untertitel = "alles plus Daemon" } ] }
          { name = "Einstieg"
            farbe = "#6d5bd0"
            blocks = 
                [ { id = "tt-live-sh"; name = "tt-live.sh"; untertitel = "Einstieg" }
                  { id = "tt-live-json"; name = "tt-live.json"; untertitel = "Aufrufe" } ] }
          { name = "Daemon"
            farbe = "#b45309"
            blocks = 
                [ { id = "zeitfenster"; name = "Zeitfenster"; untertitel = "Dauer + Abstand" }
                  { id = "zustandsspeicher"; name = "Zustandsspeicher"; untertitel = "letzter Stand" }
                  { id = "abstand"; name = "Abstand"; untertitel = "Takt" } ] }
          { name = "Ereignisse"
            farbe = "#fe2c55"
            blocks = 
                [ { id = "go-live"; name = "go_live"; untertitel = "Wechsel" }
                  { id = "go-offline"; name = "go_offline"; untertitel = "Wechsel" }
                  { id = "rename-detected"; name = "rename_detected"; untertitel = "Namenswechsel" } ] } ]
      kanten = 
        [ { von = "tiktok-com-user"; nach = "get-room-id-py"; art = "fluss" }
          { von = "room-id"; nach = "check-alive-py"; art = "fluss" }
          { von = "m3u8"; nach = "tt-live-py"; art = "fluss" }
          { von = "get-room-id-py"; nach = "tt-live-sh"; art = "fluss" }
          { von = "check-alive-py"; nach = "tt-live-json"; art = "fluss" }
          { von = "tt-live-py"; nach = "tt-live-sh"; art = "fluss" }
          { von = "tt-live-sh"; nach = "zeitfenster"; art = "fluss" }
          { von = "tt-live-json"; nach = "zustandsspeicher"; art = "fluss" }
          { von = "zeitfenster"; nach = "go-live"; art = "fluss" }
          { von = "zustandsspeicher"; nach = "go-offline"; art = "fluss" }
          { von = "abstand"; nach = "rename-detected"; art = "fluss" } ]
      kantenarten = 
        [ { art = "fluss"; farbe = "#fe2c55"; stil = "voll"; text = "Fluss von unten nach oben" } ] }

let generateHtml() =
    let sb = StringBuilder()
    
    sb.Append("<!DOCTYPE html>") |> ignore
    sb.Append("<html lang=\"de\">") |> ignore
    sb.Append("<head>") |> ignore
    sb.Append("<meta charset=\"utf-8\">") |> ignore
    sb.Append("<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">") |> ignore
    sb.Append("<title>tt-live — Interaktive Architektur</title>") |> ignore
    sb.Append("<meta name=\"description\" content=\"Vom @handle zum Ereignis: Auflösung, Prüfung, Daemon — drehen, zoomen, Knoten auswählen.\">") |> ignore
    sb.Append("<meta name=\"theme-color\" content=\"#fe2c55\">") |> ignore
    
    sb.Append("<style>") |> ignore
    sb.Append(":root{") |> ignore
    sb.Append("--bg:#fbfaf7; --panel:#fff; --line:#e6e3dc; --text:#16191d; --muted:#5f6773;") |> ignore
    sb.Append("--ac:#fe2c55; --buehne:#0e1420; --buehne-line:#1d2739;") |> ignore
    sb.Append("color-scheme: light;") |> ignore
    sb.Append("}") |> ignore
    sb.Append("@media (prefers-color-scheme: dark){") |> ignore
    sb.Append(":root{ --bg:#0f1115; --panel:#171a21; --line:#262b36; --text:#f2f4f8; --muted:#9aa3b2;") |> ignore
    sb.Append("color-scheme: dark; }") |> ignore
    sb.Append("}") |> ignore
    sb.Append("*{box-sizing:border-box}") |> ignore
    sb.Append("body{margin:0;background:var(--bg);color:var(--text);") |> ignore
    sb.Append("font:15px/1.55 -apple-system,BlinkMacSystemFont,\"Segoe UI\",Roboto,sans-serif}") |> ignore
    sb.Append(".wrap{max-width:1240px;margin:0 auto;padding:34px 22px 60px}") |> ignore
    sb.Append(".technik{font-size:12px;font-weight:700;letter-spacing:.1em;text-transform:uppercase;") |> ignore
    sb.Append("color:var(--ac);margin:0 0 10px}") |> ignore
    sb.Append("h1{font-size:clamp(30px,5vw,52px);line-height:1.05;margin:0 0 14px;letter-spacing:-.03em}") |> ignore
    sb.Append(".lede{font-size:16.5px;color:var(--muted);max-width:62ch;margin:0 0 26px}") |> ignore
    sb.Append(".raster{display:grid;grid-template-columns:minmax(0,1fr) 288px;gap:18px;align-items:start}") |> ignore
    sb.Append("@media (max-width:880px){ .raster{grid-template-columns:1fr} }") |> ignore
    sb.Append(".buehne{position:relative;background:var(--buehne);border-radius:14px;overflow:hidden;") |> ignore
    sb.Append("min-height:520px;aspect-ratio:16/11}") |> ignore
    sb.Append(".buehne canvas{display:block;width:100%;height:100%}") |> ignore
    sb.Append(".knoepfe{position:absolute;top:14px;right:14px;display:flex;gap:8px;z-index:2}") |> ignore
    sb.Append("button{font:inherit;font-size:14px;font-weight:650;padding:9px 14px;border-radius:9px;") |> ignore
    sb.Append("border:1px solid var(--line);background:var(--panel);color:var(--text);cursor:pointer}") |> ignore
    sb.Append("button:hover{border-color:var(--ac)}") |> ignore
    sb.Append("button[aria-pressed=\"true\"]{background:var(--ac);border-color:var(--ac);color:#fff}") |> ignore
    sb.Append(".karte{background:var(--panel);border:1px solid var(--line);border-radius:14px;padding:20px}") |> ignore
    sb.Append(".karte h2{font-size:11px;font-weight:700;letter-spacing:.09em;text-transform:uppercase;") |> ignore
    sb.Append("color:var(--muted);margin:0 0 12px}") |> ignore
    sb.Append(".karte h3{font-size:23px;margin:0 0 4px;letter-spacing:-.02em}") |> ignore
    sb.Append(".karte .sub{color:var(--muted);margin:0 0 18px;font-size:14.5px}") |> ignore
    sb.Append(".feld{border-top:1px solid var(--line);padding:12px 0 0;margin:0 0 12px}") |> ignore
    sb.Append(".feld dt{font-size:11px;font-weight:700;letter-spacing:.08em;text-transform:uppercase;") |> ignore
    sb.Append("color:var(--muted);margin:0 0 3px}") |> ignore
    sb.Append(".feld dd{margin:0;font-weight:650}") |> ignore
    sb.Append(".blaettern{display:flex;gap:8px;margin-top:16px}") |> ignore
    sb.Append(".blaettern button{flex:1;text-align:center;line-height:1.25;padding:11px 8px}") |> ignore
    sb.Append(".legende{display:flex;gap:22px;flex-wrap:wrap;margin:16px 0 0;font-size:13.5px;color:var(--muted)}") |> ignore
    sb.Append(".legende span{display:inline-flex;align-items:center;gap:9px}") |> ignore
    sb.Append(".strich{width:30px;height:0;border-top-width:3px;border-top-style:solid;display:inline-block}") |> ignore
    sb.Append(".fuss{margin:14px 0 0;font-size:13px;color:var(--muted);max-width:80ch}") |> ignore
    sb.Append(".fehler{padding:40px;text-align:center;color:var(--muted)}") |> ignore
    sb.Append("a{color:var(--ac)}") |> ignore
    sb.Append("</style>") |> ignore
    
    sb.Append("</head>") |> ignore
    sb.Append("<body>") |> ignore
    sb.Append("<div class=\"wrap\">") |> ignore
    
    sb.Append("<p class=\"technik\">three.js · r128</p>") |> ignore
    sb.Append("<h1>tt-live</h1>") |> ignore
    sb.Append("<p class=\"lede\">Vom @handle zum Ereignis: Auflösung, Prüfung, Daemon — drehen, zoomen, Knoten auswählen.</p>") |> ignore
    
    sb.Append("<div class=\"raster\">") |> ignore
    sb.Append("<div class=\"buehne\" id=\"buehne\">") |> ignore
    sb.Append("<div class=\"knoepfe\">") |> ignore
    sb.Append("<button id=\"btn-plus\" title=\"Näher\">+</button>") |> ignore
    sb.Append("<button id=\"btn-minus\" title=\"Weiter weg\">−</button>") |> ignore
    sb.Append("<button id=\"btn-reset\">Zurücksetzen</button>") |> ignore
    sb.Append("<button id=\"btn-iso\" aria-pressed=\"true\" title=\"Isometrisch oder perspektivisch\">Iso</button>") |> ignore
    sb.Append("</div>") |> ignore
    sb.Append("</div>") |> ignore
    
    sb.Append("<aside class=\"karte\">") |> ignore
    sb.Append("<h2>Ausgewählter Knoten</h2>") |> ignore
    sb.Append("<h3 id=\"k-name\">—</h3>") |> ignore
    sb.Append("<p class=\"sub\" id=\"k-sub\">Knoten anklicken oder durchblättern</p>") |> ignore
    sb.Append("<dl class=\"feld\"><dt>Schicht</dt><dd id=\"k-schicht\">—</dd></dl>") |> ignore
    sb.Append("<dl class=\"feld\"><dt>ID</dt><dd id=\"k-id\">—</dd></dl>") |> ignore
    sb.Append("<div class=\"blaettern\">") |> ignore
    sb.Append("<button id=\"btn-prev\">←<br>Vorheriger</button>") |> ignore
    sb.Append("<button id=\"btn-next\">Nächster<br>→</button>") |> ignore
    sb.Append("</div>") |> ignore
    sb.Append("</aside>") |> ignore
    sb.Append("</div>") |> ignore
    
    sb.Append("<div class=\"legende\" id=\"legende\"></div>") |> ignore
    sb.Append("<p class=\"fuss\">Schematische Dokumentationsansicht — Blockgrößen messen weder Datenmenge noch Leistung. Keine Telemetrie, keine Fernabfragen: Die Seite lädt einmalig three.js vom CDN und rechnet danach ausschließlich lokal.</p>") |> ignore
    
    sb.Append("</div>") |> ignore
    
    sb.Append("<script src=\"https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js\"></script>") |> ignore
    sb.Append("<script>") |> ignore
    sb.Append("(function(){") |> ignore
    sb.Append("\"use strict\";") |> ignore
    
    sb.Append("var SPEC = ") |> ignore
    let json = 
        sprintf "{ \"schichten\": %s, \"kanten\": %s, \"kantenarten\": %s }" 
            (spec.schichten 
             |> List.map (fun s -> 
                 sprintf "{ \"name\": \"%s\", \"farbe\": \"%s\", \"blocks\": [%s] }" 
                     s.name s.farbe 
                     (s.blocks 
                      |> List.map (fun b -> sprintf "{ \"id\": \"%s\", \"name\": \"%s\", \"untertitel\": \"%s\" }" b.id b.name b.untertitel)
                      |> String.concat ","))
             |> String.concat ",")
            (spec.kanten 
             |> List.map (fun k -> sprintf "{ \"von\": \"%s\", \"nach\": \"%s\", \"art\": \"%s\" }" k.von k.nach k.art)
             |> String.concat ",")
            (spec.kantenarten 
             |> List.map (fun ka -> sprintf "{ \"art\": \"%s\", \"farbe\": \"%s\", \"stil\": \"%s\", \"text\": \"%s\" }" ka.art ka.farbe ka.stil ka.text)
             |> String.concat ",")
    sb.Append(json.Replace("\\", "\\\\").Replace("\"", "\\\"")) |> ignore
    sb.Append(";") |> ignore
    
    sb.Append(@"var buehne = document.getElementById(""buehne"");
if (typeof THREE === ""undefined""){
  buehne.insertAdjacentHTML(""beforeend"",
    '<div class=""fehler"">three.js konnte nicht geladen werden. ' +
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
  var c = document.createElement(""canvas""), x = c.getContext(""2d"");
  var f1 = ""700 40px -apple-system,Segoe UI,Roboto,sans-serif"";
  var f2 = ""500 27px -apple-system,Segoe UI,Roboto,sans-serif"";
  x.font = f1; var w1 = x.measureText(text).width;
  x.font = f2; var w2 = unter ? x.measureText(unter).width : 0;
  var w = Math.ceil(Math.max(w1, w2)) + 40, h = unter ? 96 : 62;
  c.width = w; c.height = h;
  x = c.getContext(""2d"");
  x.fillStyle = ""rgba(255,255,255,.95)"";
  if (x.roundRect){ x.beginPath(); x.roundRect(0,0,w,h,13); x.fill(); }
  else x.fillRect(0,0,w,h);
  x.fillStyle = ""#16191d""; x.font = f1; x.textBaseline = ""middle"";
  x.fillText(text, 20, unter ? 32 : 31);
  if (unter){ x.fillStyle = ""#5f6773""; x.font = f2; x.fillText(unter, 20, 68); }
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
    return (typeof b === ""string"") ? {id:null, name:b, untertitel:""""} : b;
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

    var id = b.id || (b.name.toLowerCase().replace(/[^a-z0-9]+/g, ""-"").replace(/^-|-$/g, """"));
    var eintrag = {id:id, name:b.name, untertitel:b.untertitel||"""", schicht:sch.name,
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
  var art = STIL[k.art] || {farbe:""#8ea2ff"", stil:""voll""};
  var g = new THREE.BufferGeometry().setFromPoints([
    a.pos.clone().setY(a.pos.y + 0.9), b.pos.clone().setY(b.pos.y - 0.9)]);
  var linie;
  if (art.stil === ""gestrichelt""){
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

var leg = document.getElementById(""legende"");
(SPEC.kantenarten || []).forEach(function(a){
  var s = document.createElement(""span"");
  s.innerHTML = '<i class=""strich"" style=""border-top-color:' + a.farbe +
                ';border-top-style:' + (a.stil === ""gestrichelt"" ? ""dashed"" : ""solid"") +
                '""></i>' + a.text;
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
  document.getElementById(""k-name"").textContent = k.name;
  document.getElementById(""k-sub"").textContent = k.untertitel || ""—"";
  document.getElementById(""k-schicht"").textContent = k.schicht;
  document.getElementById(""k-id"").textContent = k.id;
}

var strahl = new THREE.Raycaster(), zeiger = new THREE.Vector2();
renderer.domElement.addEventListener(""click"", function(e){
  if (gezogen) return;
  var r = renderer.domElement.getBoundingClientRect();
  zeiger.x = ((e.clientX - r.left) / r.width) * 2 - 1;
  zeiger.y = -((e.clientY - r.top) / r.height) * 2 + 1;
  strahl.setFromCamera(zeiger, kamera);
  var treffer = strahl.intersectObjects(klickbar, false);
  if (treffer.length) waehle(treffer[0].object.userData.index);
});
document.getElementById(""btn-prev"").addEventListener(""click"", function(){ waehle(aktiv - 1); });
document.getElementById(""btn-next"").addEventListener(""click"", function(){ waehle(aktiv + 1); });

// ------------------------------------------------------------- Kamera ----
var azimut = Math.PI/4, elevation = 0.62, rotiert = true;
function stelle(){
  var x = radius*Math.cos(elevation)*Math.sin(azimut);
  var y = radius*Math.sin(elevation);
  var z = radius*Math.cos(elevation)*Math.cos(azimut);
  kamera.position.set(x, y, z); kamera.lookAt(0, 0, 0);
}
var zieht = false, gezogen = false, lx = 0, ly = 0;
renderer.domElement.addEventListener(""pointerdown"", function(e){
  zieht = true; gezogen = false; lx = e.clientX; ly = e.clientY;
});
window.addEventListener(""pointermove"", function(e){
  if (!zieht) return;
  if (Math.abs(e.clientX-lx) + Math.abs(e.clientY-ly) > 3){ gezogen = true; rotiert = false; }
  azimut -= (e.clientX - lx) * 0.006;
  elevation = Math.max(0.08, Math.min(1.45, elevation + (e.clientY - ly) * 0.005));
  lx = e.clientX; ly = e.clientY;
});
window.addEventListener(""pointerup"", function(){ zieht = false; setTimeout(function(){ gezogen = false; }, 0); });

function zoom(f){
  if (iso){ D = Math.max(11, Math.min(54, D * f)); groesse(); }
  else { radius = Math.max(32, Math.min(160, radius * f)); }
}
document.getElementById(""btn-plus"").addEventListener(""click"", function(){ zoom(0.85); });
document.getElementById(""btn-minus"").addEventListener(""click"", function(){ zoom(1.18); });
renderer.domElement.addEventListener(""wheel"", function(e){
  e.preventDefault(); zoom(e.deltaY > 0 ? 1.08 : 0.93);
}, {passive:false});
document.getElementById(""btn-reset"").addEventListener(""click"", function(){
  azimut = Math.PI/4; elevation = 0.62; D = 26; radius = 82; rotiert = true;
  iso = true; kamera = kameraIso;
  document.getElementById(""btn-iso"").setAttribute(""aria-pressed"", ""true"");
  document.getElementById(""btn-iso"").textContent = ""Iso"";
  waehle(0); groesse();
});
document.getElementById(""btn-iso"").addEventListener(""click"", function(){
  iso = !iso; kamera = iso ? kameraIso : kameraPersp;
  this.setAttribute(""aria-pressed"", String(iso));
  this.textContent = iso ? ""Iso"" : ""Persp"";
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
window.addEventListener(""resize"", groesse);

groesse();
waehle(0);
(function schleife(){
  requestAnimationFrame(schleife);
  if (rotiert) azimut += 0.003;
  stelle();
  renderer.render(szene, kamera);
})();
})();") |> ignore
    
    sb.Append("</script>") |> ignore
    sb.Append("</body>") |> ignore
    sb.Append("</html>") |> ignore
    
    sb.ToString()

let writeHtmlToFile filename =
    let html = generateHtml()
    File.WriteAllText(filename, html, Text.Encoding.UTF8)

[<EntryPoint>]
let main argv =
    let filename = if argv.Length > 0 then argv.[0] else "output.html"
    writeHtmlToFile filename
    printfn "HTML file written to %s" filename
    0
