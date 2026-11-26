// abstraction-provenance: {"artifact_sha256": "65663e777ebb09d9dfeb0e3c14507687896e3da79237f423cd39820871893de5", "source_sha256": "fde0925c6da9f2674781482e5d06631c48818efbac6d63d45e764a139fc3bdf4", "target_language": "fsharp"}
// 3d.html — portiert nach fsharp
// Quelle: html, Projects@secret-vault-public:public/3d.html
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

open System
open System.IO
open System.Text

type Block = {
    id: string
    name: string
    untertitel: string
}

type Schicht = {
    name: string
    farbe: string
    blocks: Block list
}

type Kante = {
    von: string
    nach: string
    art: string
}

type Kantenart = {
    art: string
    farbe: string
    stil: string
    text: string
}

type Spec = {
    schichten: Schicht list
    kanten: Kante list
    kantenarten: Kantenart list
}

let createSpec() : Spec = {
    schichten = [
        {
            name = "Eingaben"
            farbe = "#5f6773"
            blocks = [
                {id = "passphrase"; name = "Passphrase"; untertitel = "nie gespeichert"}
                {id = "vault-datei"; name = "Vault-Datei"; untertitel = "Ciphertext"}
                {id = "neue-felder"; name = "neue Felder"; untertitel = "Formular"}
            ]
        }
        {
            name = "Schluesselableitung"
            farbe = "#2481cc"
            blocks = [
                {id = "pbkdf2-210k"; name = "PBKDF2 210k"; untertitel = "Iterationen"}
                {id = "salt-16-b"; name = "Salt 16 B"; untertitel = "zufaellig"}
                {id = "sha-256"; name = "SHA-256"; untertitel = "HMAC"}
            ]
        }
        {
            name = "Verschluesselung"
            farbe = "#5b5bd6"
            blocks = [
                {id = "aes-256-gcm"; name = "AES-256-GCM"; untertitel = "authentisiert"}
                {id = "iv-12-b"; name = "IV 12 B"; untertitel = "nie doppelt"}
                {id = "crypto-subtle"; name = "crypto.subtle"; untertitel = "WebCrypto"}
            ]
        }
        {
            name = "Verwaltung"
            farbe = "#b45309"
            blocks = [
                {id = "anbieter"; name = "Anbieter"; untertitel = "Gruppen"}
                {id = "felder"; name = "Felder"; untertitel = "Schluessel/Wert"}
                {id = "rotation"; name = "Rotation"; untertitel = "neuer Wert"}
            ]
        }
        {
            name = "Ausgabe"
            farbe = "#22a06b"
            blocks = [
                {id = "download"; name = "Download"; untertitel = "Blob-URL"}
                {id = "export"; name = "Export"; untertitel = "JSON"}
                {id = "zwischenablage"; name = "Zwischenablage"; untertitel = "nur auf Klick"}
            ]
        }
    ]
    kanten = [
        {von = "passphrase"; nach = "pbkdf2-210k"; art = "fluss"}
        {von = "vault-datei"; nach = "salt-16-b"; art = "fluss"}
        {von = "neue-felder"; nach = "sha-256"; art = "fluss"}
        {von = "pbkdf2-210k"; nach = "aes-256-gcm"; art = "fluss"}
        {von = "salt-16-b"; nach = "iv-12-b"; art = "fluss"}
        {von = "sha-256"; nach = "crypto-subtle"; art = "fluss"}
        {von = "aes-256-gcm"; nach = "anbieter"; art = "fluss"}
        {von = "iv-12-b"; nach = "felder"; art = "fluss"}
        {von = "crypto-subtle"; nach = "rotation"; art = "fluss"}
        {von = "anbieter"; nach = "download"; art = "fluss"}
        {von = "felder"; nach = "export"; art = "fluss"}
        {von = "rotation"; nach = "zwischenablage"; art = "fluss"}
    ]
    kantenarten = [
        {art = "fluss"; farbe = "#5b5bd6"; stil = "voll"; text = "Fluss von unten nach oben"}
    ]
}

let generateHtml(spec: Spec) =
    let sb = StringBuilder()
    
    sb.AppendLine("<!DOCTYPE html>") |> ignore
    sb.AppendLine("<html lang=\"de\">") |> ignore
    sb.AppendLine("<head>") |> ignore
    sb.AppendLine("<meta charset=\"utf-8\">") |> ignore
    sb.AppendLine("<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">") |> ignore
    sb.AppendLine("<title>Secret-Vault Public — Interaktive Architektur</title>") |> ignore
    sb.AppendLine("<meta name=\"description\" content=\"Vom Passwort zur verschlüsselten Datei — jede Schicht bleibt im Browser. Drehen, zoomen, Knoten auswählen.\">") |> ignore
    sb.AppendLine("<meta name=\"theme-color\" content=\"#5b5bd6\">") |> ignore
    sb.AppendLine("<style>") |> ignore
    sb.AppendLine("  :root{") |> ignore
    sb.AppendLine("    --bg:#fbfaf7; --panel:#fff; --line:#e6e3dc; --text:#16191d; --muted:#5f6773;") |> ignore
    sb.AppendLine("    --ac:#5b5bd6; --buehne:#0e1420; --buehne-line:#1d2739;") |> ignore
    sb.AppendLine("    color-scheme: light;") |> ignore
    sb.AppendLine("  }") |> ignore
    sb.AppendLine("  @media (prefers-color-scheme: dark){") |> ignore
    sb.AppendLine("    :root{ --bg:#0f1115; --panel:#171a21; --line:#262b36; --text:#f2f4f8; --muted:#9aa3b2;") |> ignore
    sb.AppendLine("           color-scheme: dark; }") |> ignore
    sb.AppendLine("  }") |> ignore
    sb.AppendLine("  *{box-sizing:border-box}") |> ignore
    sb.AppendLine("  body{margin:0;background:var(--bg);color:var(--text);") |> ignore
    sb.AppendLine("       font:15px/1.55 -apple-system,BlinkMacSystemFont,\"Segoe UI\",Roboto,sans-serif}") |> ignore
    sb.AppendLine("  .wrap{max-width:1240px;margin:0 auto;padding:34px 22px 60px}") |> ignore
    sb.AppendLine("  .technik{font-size:12px;font-weight:700;letter-spacing:.1em;text-transform:uppercase;") |> ignore
    sb.AppendLine("           color:var(--ac);margin:0 0 10px}") |> ignore
    sb.AppendLine("  h1{font-size:clamp(30px,5vw,52px);line-height:1.05;margin:0 0 14px;letter-spacing:-.03em}") |> ignore
    sb.AppendLine("  .lede{font-size:16.5px;color:var(--muted);max-width:62ch;margin:0 0 26px}") |> ignore
    sb.AppendLine("  .raster{display:grid;grid-template-columns:minmax(0,1fr) 288px;gap:18px;align-items:start}") |> ignore
    sb.AppendLine("  @media (max-width:880px){ .raster{grid-template-columns:1fr} }") |> ignore
    sb.AppendLine("  .buehne{position:relative;background:var(--buehne);border-radius:14px;overflow:hidden;") |> ignore
    sb.AppendLine("          min-height:520px;aspect-ratio:16/11}") |> ignore
    sb.AppendLine("  .buehne canvas{display:block;width:100%;height:100%}") |> ignore
    sb.AppendLine("  .knoepfe{position:absolute;top:14px;right:14px;display:flex;gap:8px;z-index:2}") |> ignore
    sb.AppendLine("  button{font:inherit;font-size:14px;font-weight:650;padding:9px 14px;border-radius:9px;") |> ignore
    sb.AppendLine("         border:1px solid var(--line);background:var(--panel);color:var(--text);cursor:pointer}") |> ignore
    sb.AppendLine("  button:hover{border-color:var(--ac)}") |> ignore
    sb.AppendLine("  button[aria-pressed=\"true\"]{background:var(--ac);border-color:var(--ac);color:#fff}") |> ignore
    sb.AppendLine("  .karte{background:var(--panel);border:1px solid var(--line);border-radius:14px;padding:20px}") |> ignore
    sb.AppendLine("  .karte h2{font-size:11px;font-weight:700;letter-spacing:.09em;text-transform:uppercase;") |> ignore
    sb.AppendLine("            color:var(--muted);margin:0 0 12px}") |> ignore
    sb.AppendLine("  .karte h3{font-size:23px;margin:0 0 4px;letter-spacing:-.02em}") |> ignore
    sb.AppendLine("  .karte .sub{color:var(--muted);margin:0 0 18px;font-size:14.5px}") |> ignore
    sb.AppendLine("  .feld{border-top:1px solid var(--line);padding:12px 0 0;margin:0 0 12px}") |> ignore
    sb.AppendLine("  .feld dt{font-size:11px;font-weight:700;letter-spacing:.08em;text-transform:uppercase;") |> ignore
    sb.AppendLine("           color:var(--muted);margin:0 0 3px}") |> ignore
    sb.AppendLine("  .feld dd{margin:0;font-weight:650}") |> ignore
    sb.AppendLine("  .blaettern{display:flex;gap:8px;margin-top:16px}") |> ignore
    sb.AppendLine("  .blaettern button{flex:1;text-align:center;line-height:1.25;padding:11px 8px}") |> ignore
    sb.AppendLine("  .legende{display:flex;gap:22px;flex-wrap:wrap;margin:16px 0 0;font-size:13.5px;color:var(--muted)}") |> ignore
    sb.AppendLine("  .legende span{display:inline-flex;align-items:center;gap:9px}") |> ignore
    sb.AppendLine("  .strich{width:30px;height:0;border-top-width:3px;border-top-style:solid;display:inline-block}") |> ignore
    sb.AppendLine("  .fuss{margin:14px 0 0;font-size:13px;color:var(--muted);max-width:80ch}") |> ignore
    sb.AppendLine("  .fehler{padding:40px;text-align:center;color:var(--muted)}") |> ignore
    sb.AppendLine("  a{color:var(--ac)}") |> ignore
    sb.AppendLine("</style>") |> ignore
    sb.AppendLine("</head>") |> ignore
    sb.AppendLine("<body>") |> ignore
    sb.AppendLine("<div class=\"wrap\">") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("  <p class=\"technik\">three.js · r128</p>") |> ignore
    sb.AppendLine("  <h1>Secret-Vault Public</h1>") |> ignore
    sb.AppendLine("  <p class=\"lede\">Vom Passwort zur verschlüsselten Datei — jede Schicht bleibt im Browser. Drehen, zoomen, Knoten auswählen.</p>") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("  <div class=\"raster\">") |> ignore
    sb.AppendLine("    <div class=\"buehne\" id=\"buehne\">") |> ignore
    sb.AppendLine("      <div class=\"knoepfe\">") |> ignore
    sb.AppendLine("        <button id=\"btn-plus\" title=\"Näher\">+</button>") |> ignore
    sb.AppendLine("        <button id=\"btn-minus\" title=\"Weiter weg\">−</button>") |> ignore
    sb.AppendLine("        <button id=\"btn-reset\">Zurücksetzen</button>") |> ignore
    sb.AppendLine("        <button id=\"btn-iso\" aria-pressed=\"true\" title=\"Isometrisch oder perspektivisch\">Iso</button>") |> ignore
    sb.AppendLine("      </div>") |> ignore
    sb.AppendLine("    </div>") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("    <aside class=\"karte\">") |> ignore
    sb.AppendLine("      <h2>Ausgewählter Knoten</h2>") |> ignore
    sb.AppendLine("      <h3 id=\"k-name\">—</h3>") |> ignore
    sb.AppendLine("      <p class=\"sub\" id=\"k-sub\">Knoten anklicken oder durchblättern</p>") |> ignore
    sb.AppendLine("      <dl class=\"feld\"><dt>Schicht</dt><dd id=\"k-schicht\">—</dd></dl>") |> ignore
    sb.AppendLine("      <dl class=\"feld\"><dt>ID</dt><dd id=\"k-id\">—</dd></dl>") |> ignore
    sb.AppendLine("      <div class=\"blaettern\">") |> ignore
    sb.AppendLine("        <button id=\"btn-prev\">←<br>Vorheriger</button>") |> ignore
    sb.AppendLine("        <button id=\"btn-next\">Nächster<br>→</button>") |> ignore
    sb.AppendLine("      </div>") |> ignore
    sb.AppendLine("    </aside>") |> ignore
    sb.AppendLine("  </div>") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("  <div class=\"legende\" id=\"legende\"></div>") |> ignore
    sb.AppendLine("  <p class=\"fuss\">Schematische Dokumentationsansicht — Blockgrößen messen weder Datenmenge noch Leistung. Keine Telemetrie, keine Fernabfragen: Die Seite lädt einmalig three.js vom CDN und rechnet danach ausschließlich lokal.</p>") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("</div>") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("<script src=\"https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js\"></script>") |> ignore
    sb.AppendLine("<script>") |> ignore
    sb.AppendLine("(function(){") |> ignore
    sb.AppendLine("  \"use strict\";") |> ignore
    
    // Generate SPEC JSON
    sb.Append("  var SPEC = ") |> ignore
    sb.Append("{") |> ignore
    sb.Append("\"schichten\": [") |> ignore
    
    for i = 0 to spec.schichten.Length - 1 do
        let schicht = spec.schichten.[i]
        sb.Append("{") |> ignore
        sb.Append("\"name\": \"") |> ignore
        sb.Append(schicht.name.Replace("\"", "\\\"")) |> ignore
        sb.Append("\", \"farbe\": \"") |> ignore
        sb.Append(schicht.farbe) |> ignore
        sb.Append("\", \"blocks\": [") |> ignore
        
        for j = 0 to schicht.blocks.Length - 1 do
            let block = schicht.blocks.[j]
            sb.Append("{") |> ignore
            sb.Append("\"id\": \"") |> ignore
            sb.Append(block.id.Replace("\"", "\\\"")) |> ignore
            sb.Append("\", \"name\": \"") |> ignore
            sb.Append(block.name.Replace("\"", "\\\"")) |> ignore
            sb.Append("\", \"untertitel\": \"") |> ignore
            sb.Append(block.untertitel.Replace("\"", "\\\"")) |> ignore
            sb.Append("\"}") |> ignore
            if j < schicht.blocks.Length - 1 then sb.Append(",") |> ignore
            
        sb.Append("]}") |> ignore
        if i < spec.schichten.Length - 1 then sb.Append(",") |> ignore
        
    sb.Append("], \"kanten\": [") |> ignore
    
    for i = 0 to spec.kanten.Length - 1 do
        let kante = spec.kanten.[i]
        sb.Append("{") |> ignore
        sb.Append("\"von\": \"") |> ignore
        sb.Append(kante.von.Replace("\"", "\\\"")) |> ignore
        sb.Append("\", \"nach\": \"") |> ignore
        sb.Append(kante.nach.Replace("\"", "\\\"")) |> ignore
        sb.Append("\", \"art\": \"") |> ignore
        sb.Append(kante.art.Replace("\"", "\\\"")) |> ignore
        sb.Append("\"}") |> ignore
        if i < spec.kanten.Length - 1 then sb.Append(",") |> ignore
        
    sb.Append("], \"kantenarten\": [") |> ignore
    
    for i = 0 to spec.kantenarten.Length - 1 do
        let kantenart = spec.kantenarten.[i]
        sb.Append("{") |> ignore
        sb.Append("\"art\": \"") |> ignore
        sb.Append(kantenart.art.Replace("\"", "\\\"")) |> ignore
        sb.Append("\", \"farbe\": \"") |> ignore
        sb.Append(kantenart.farbe) |> ignore
        sb.Append("\", \"stil\": \"") |> ignore
        sb.Append(kantenart.stil.Replace("\"", "\\\"")) |> ignore
        sb.Append("\", \"text\": \"") |> ignore
        sb.Append(kantenart.text.Replace("\"", "\\\"")) |> ignore
        sb.Append("\"}") |> ignore
        if i < spec.kantenarten.Length - 1 then sb.Append(",") |> ignore
        
    sb.Append("]}") |> ignore
    sb.AppendLine(";") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("  var buehne = document.getElementById(\"buehne\");") |> ignore
    sb.AppendLine("  if (typeof THREE === \"undefined\"){") |> ignore
    sb.AppendLine("    buehne.insertAdjacentHTML(\"beforeend\",") |> ignore
    sb.AppendLine("      '<div class=\"fehler\">three.js konnte nicht geladen werden. ' +") |> ignore
    sb.AppendLine("      'Die Seite braucht einmalig Netzzugang zum CDN.</div>');") |> ignore
    sb.AppendLine("    return;") |> ignore
    sb.AppendLine("  }") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("  // ---------------------------------------------------------------- Szene ---") |> ignore
    sb.AppendLine("  var szene = new THREE.Scene();") |> ignore
    sb.AppendLine("  szene.background = new THREE.Color(0x0e1420);") |> ignore
    sb.AppendLine("  var renderer = new THREE.WebGLRenderer({antialias:true});") |> ignore
    sb.AppendLine("  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));") |> ignore
    sb.AppendLine("  buehne.appendChild(renderer.domElement);") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("  var D = 26, radius = 82, aspekt = 1;") |> ignore
    sb.AppendLine("  var kameraIso = new THREE.OrthographicCamera(-D, D, D, -D, 0.1, 600);") |> ignore
    sb.AppendLine("  var kameraPersp = new THREE.PerspectiveCamera(42, 1, 0.1, 600);") |> ignore
    sb.AppendLine("  var kamera = kameraIso, iso = true;") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("  szene.add(new THREE.AmbientLight(0xffffff, 0.66));") |> ignore
    sb.AppendLine("  var licht = new THREE.DirectionalLight(0xffffff, 0.8);") |> ignore
    sb.AppendLine("  licht.position.set(30, 46, 26); szene.add(licht);") |> ignore
    sb.AppendLine("  var gegen = new THREE.DirectionalLight(0x8ea2ff, 0.3);") |> ignore
    sb.AppendLine("  gegen.position.set(-32, 16, -28); szene.add(gegen);") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("  var raster = new THREE.GridHelper(110, 34, 0x25324a, 0x1a2333);") |> ignore
    sb.AppendLine("  raster.position.y = -24; szene.add(raster);") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("  // ------------------------------------------------------------ Schilder ---") |> ignore
    sb.AppendLine("  // Text auf eine Textur, dann als Billboard — bleibt bei jeder Drehung lesbar.") |> ignore
    sb.AppendLine("  function schild(text, unter){") |> ignore
    sb.AppendLine("    var c = document.createElement(\"canvas\"), x = c.getContext(\"2d\");") |> ignore
    sb.AppendLine("    var f1 = \"700 40px -apple-system,Segoe UI,Roboto,sans-serif\";") |> ignore
    sb.AppendLine("    var f2 = \"500 27px -apple-system,Segoe UI,Roboto,sans-serif\";") |> ignore
    sb.AppendLine("    x.font = f1; var w1 = x.measureText(text).width;") |> ignore
    sb.AppendLine("    x.font = f2; var w2 = unter ? x.measureText(unter).width : 0;") |> ignore
    sb.AppendLine("    var w = Math.ceil(Math.max(w1, w2)) + 40, h = unter ? 96 : 62;") |> ignore
    sb.AppendLine("    c.width = w; c.height = h;") |> ignore
    sb.AppendLine("    x = c.getContext(\"2d\");") |> ignore
    sb.AppendLine("    x.fillStyle = \"rgba(255,255,255,.95)\";") |> ignore
    sb.AppendLine("    if (x.roundRect){ x.beginPath(); x.roundRect(0,0,w,h,13); x.fill(); }") |> ignore
    sb.AppendLine("    else x.fillRect(0,0,w,h);") |> ignore
    sb.AppendLine("    x.fillStyle = \"#16191d\"; x.font = f1; x.textBaseline = \"middle\";") |> ignore
    sb.AppendLine("    x.fillText(text, 20, unter ? 32 : 31);") |> ignore
    sb.AppendLine("    if (unter){ x.fillStyle = \"#5f6773\"; x.font = f2; x.fillText(unter, 20, 68); }") |> ignore
    sb.AppendLine("    var t = new THREE.CanvasTexture(c); t.minFilter = THREE.LinearFilter;") |> ignore
    sb.AppendLine("    var s = new THREE.Sprite(new THREE.SpriteMaterial({map:t, transparent:true, depthTest:false}));") |> ignore
    sb.AppendLine("    s.scale.set(w/62*2.5, h/62*2.5, 1);") |> ignore
    sb.AppendLine("    s.renderOrder = 999;") |> ignore
    sb.AppendLine("    return s;") |> ignore
    sb.AppendLine("  }") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("  // -------------------------------------------------------------- Aufbau ---") |> ignore
    sb.AppendLine("  var BW = 7.4, BD = 4.2, BH = 1.7, LUFT = 1.3, ABSTAND = 11.4, START = -17;") |> ignore
    sb.AppendLine("  var knoten = [], nachId = {}, klickbar = [];") |> ignore
    sb.AppendLine("  var gruppe = new THREE.Group();") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("  SPEC.schichten.forEach(function(sch, si){") |> ignore
    sb.AppendLine("    var y = START + si * ABSTAND;") |> ignore
    sb.AppendLine("    var bl = sch.blocks.map(function(b){") |> ignore
    sb.AppendLine("      return (typeof b === \"string\") ? {id:null, name:b, untertitel:\"\"} : b;") |> ignore
    sb.AppendLine("    });") |> ignore
    sb.AppendLine("    var spalten = Math.max(1, Math.ceil(bl.length / 2));") |> ignore
    sb.AppendLine("    var reihen = bl.length <= 1 ? 1 : 2;") |> ignore
    sb.AppendLine("    var gx = spalten*BW + (spalten-1)*LUFT, gz = reihen*BD + (reihen-1)*LUFT;") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("    var platte = new THREE.Mesh(") |> ignore
    sb.AppendLine("      new THREE.BoxGeometry(gx+3, 0.6, gz+3),") |> ignore
    sb.AppendLine("      new THREE.MeshLambertMaterial({color:new THREE.Color(sch.farbe).multiplyScalar(0.4)}));") |> ignore
    sb.AppendLine("    platte.position.set(0, y-1.7, 0); gruppe.add(platte);") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("    bl.forEach(function(b, i){") |> ignore
    sb.AppendLine("      var sp = i % spalten, re = Math.floor(i / spalten);") |> ignore
    sb.AppendLine("      var x = -gx/2 + BW/2 + sp*(BW+LUFT), z = -gz/2 + BD/2 + re*(BD+LUFT);") |> ignore
    sb.AppendLine("      var mat = new THREE.MeshLambertMaterial({color:sch.farbe});") |> ignore
    sb.AppendLine("      var m = new THREE.Mesh(new THREE.BoxGeometry(BW, BH, BD), mat);") |> ignore
    sb.AppendLine("      m.position.set(x, y, z);") |> ignore
    sb.AppendLine("      gruppe.add(m); klickbar.push(m);") |> ignore
    sb.AppendLine("      var kante = new THREE.LineSegments(new THREE.EdgesGeometry(m.geometry),") |> ignore
    sb.AppendLine("        new THREE.LineBasicMaterial({color:0x0e1420, transparent:true, opacity:.55}));") |> ignore
    sb.AppendLine("      kante.position.copy(m.position); gruppe.add(kante);") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("      var s = schild(b.name, b.untertitel);") |> ignore
    sb.AppendLine("      s.position.set(x, y + BH/2 + (b.untertitel ? 2.1 : 1.6), z);") |> ignore
    sb.AppendLine("      gruppe.add(s);") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("      var id = b.id || (b.name.toLowerCase().replace(/[^a-z0-9]+/g, \"-\").replace(/^-|-$/g, \"\"));") |> ignore
    sb.AppendLine("      var eintrag = {id:id, name:b.name, untertitel:b.untertitel||\"\", schicht:sch.name,") |> ignore
    sb.AppendLine("                     mesh:m, mat:mat, farbe:new THREE.Color(sch.farbe), pos:m.position};") |> ignore
    sb.AppendLine("      m.userData.index = knoten.length;") |> ignore
    sb.AppendLine("      knoten.push(eintrag); nachId[id] = eintrag;") |> ignore
    sb.AppendLine("    });") |> ignore
    sb.AppendLine("  });") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("  // -------------------------------------------------------------- Kanten ---") |> ignore
    sb.AppendLine("  var STIL = {};") |> ignore
    sb.AppendLine("  (SPEC.kantenarten || []).forEach(function(a){ STIL[a.art] = a; });") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("  (SPEC.kanten || []).forEach(function(k){") |> ignore
    sb.AppendLine("    var a = nachId[k.von], b = nachId[k.nach];") |> ignore
    sb.AppendLine("    if (!a || !b) return;") |> ignore
    sb.AppendLine("    var art = STIL[k.art] || {farbe:\"#8ea2ff\", stil:\"voll\"};") |> ignore
    sb.AppendLine("    var g = new THREE.BufferGeometry().setFromPoints([") |> ignore
    sb.AppendLine("      a.pos.clone().setY(a.pos.y + 0.9), b.pos.clone().setY(b.pos.y - 0.9)]);") |> ignore
    sb.AppendLine("    var linie;") |> ignore
    sb.AppendLine("    if (art.stil === \"gestrichelt\"){") |> ignore
    sb.AppendLine("      linie = new THREE.Line(g, new THREE.LineDashedMaterial(") |> ignore
    sb.AppendLine("        {color:art.farbe, dashSize:1.4, gapSize:1.0, transparent:true, opacity:.9}));") |> ignore
    sb.AppendLine("      linie.computeLineDistances();") |> ignore
    sb.AppendLine("    } else {") |> ignore
    sb.AppendLine("      linie = new THREE.Line(g, new THREE.LineBasicMaterial(") |> ignore
    sb.AppendLine("        {color:art.farbe, transparent:true, opacity:.85}));") |> ignore
    sb.AppendLine("    }") |> ignore
    sb.AppendLine("    gruppe.add(linie);") |> ignore
    sb.AppendLine("  });") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("  szene.add(gruppe);") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("  var leg = document.getElementById(\"legende\");") |> ignore
    sb.AppendLine("  (SPEC.kantenarten || []).forEach(function(a){") |> ignore
    sb.AppendLine("    var s = document.createElement(\"span\");") |> ignore
    sb.AppendLine("    s.innerHTML = '<i class=\"strich\" style=\"border-top-color:' + a.farbe +") |> ignore
    sb.AppendLine("                  ';border-top-style:' + (a.stil === \"gestrichelt\" ? \"dashed\" : \"solid\") +") |> ignore
    sb.AppendLine("                  '\"></i>' + a.text;") |> ignore
    sb.AppendLine("    leg.appendChild(s);") |> ignore
    sb.AppendLine("  });") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("  // ------------------------------------------------------------- Auswahl ---") |> ignore
    sb.AppendLine("  var aktiv = -1;") |> ignore
    sb.AppendLine("  function waehle(i){") |> ignore
    sb.AppendLine("    if (aktiv >= 0){") |> ignore
    sb.AppendLine("      knoten[aktiv].mat.color.copy(knoten[aktiv].farbe);") |> ignore
    sb.AppendLine("      knoten[aktiv].mat.emissive.setHex(0x000000);") |> ignore
    sb.AppendLine("      knoten[aktiv].mesh.scale.set(1,1,1);") |> ignore
    sb.AppendLine("    }") |> ignore
    sb.AppendLine("    aktiv = ((i % knoten.length) + knoten.length) % knoten.length;") |> ignore
    sb.AppendLine("    var k = knoten[aktiv];") |> ignore
    sb.AppendLine("    k.mat.emissive.setHex(0x333333);") |> ignore
    sb.AppendLine("    k.mesh.scale.set(1.1, 1.5, 1.1);") |> ignore
    sb.AppendLine("    document.getElementById(\"k-name\").textContent = k.name;") |> ignore
    sb.AppendLine("    document.getElementById(\"k-sub\").textContent = k.untertitel || \"—\";") |> ignore
    sb.AppendLine("    document.getElementById(\"k-schicht\").textContent = k.schicht;") |> ignore
    sb.AppendLine("    document.getElementById(\"k-id\").textContent = k.id;") |> ignore
    sb.AppendLine("  }") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("  var strahl = new THREE.Raycaster(), zeiger = new THREE.Vector2();") |> ignore
    sb.AppendLine("  renderer.domElement.addEventListener(\"click\", function(e){") |> ignore
    sb.AppendLine("    if (gezogen) return;") |> ignore
    sb.AppendLine("    var r = renderer.domElement.getBoundingClientRect();") |> ignore
    sb.AppendLine("    zeiger.x = ((e.clientX - r.left) / r.width) * 2 - 1;") |> ignore
    sb.AppendLine("    zeiger.y = -((e.clientY - r.top) / r.height) * 2 + 1;") |> ignore
    sb.AppendLine("    strahl.setFromCamera(zeiger, kamera);") |> ignore
    sb.AppendLine("    var treffer = strahl.intersectObjects(klickbar, false);") |> ignore
    sb.AppendLine("    if (treffer.length) waehle(treffer[0].object.userData.index);") |> ignore
    sb.AppendLine("  });") |> ignore
    sb.AppendLine("  document.getElementById(\"btn-prev\").addEventListener(\"click\", function(){ waehle(aktiv - 1); });") |> ignore
    sb.AppendLine("  document.getElementById(\"btn-next\").addEventListener(\"click\", function(){ waehle(aktiv + 1); });") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("  // ------------------------------------------------------------- Kamera ----") |> ignore
    sb.AppendLine("  var azimut = Math.PI/4, elevation = 0.62, rotiert = true;") |> ignore
    sb.AppendLine("  function stelle(){") |> ignore
    sb.AppendLine("    var x = radius*Math.cos(elevation)*Math.sin(azimut);") |> ignore
    sb.AppendLine("    var y = radius*Math.sin(elevation);") |> ignore
    sb.AppendLine("    var z = radius*Math.cos(elevation)*Math.cos(azimut);") |> ignore
    sb.AppendLine("    kamera.position.set(x, y, z); kamera.lookAt(0, 0, 0);") |> ignore
    sb.AppendLine("  }") |> ignore
    sb.AppendLine("  var zieht = false, gezogen = false, lx = 0, ly = 0;") |> ignore
    sb.AppendLine("  renderer.domElement.addEventListener(\"pointerdown\", function(e){") |> ignore
    sb.AppendLine("    zieht = true; gezogen = false; lx = e.clientX; ly = e.clientY;") |> ignore
    sb.AppendLine("  });") |> ignore
    sb.AppendLine("  window.addEventListener(\"pointermove\", function(e){") |> ignore
    sb.AppendLine("    if (!zieht) return;") |> ignore
    sb.AppendLine("    if (Math.abs(e.clientX-lx) + Math.abs(e.clientY-ly) > 3){ gezogen = true; rotiert = false; }") |> ignore
    sb.AppendLine("    azimut -= (e.clientX - lx) * 0.006;") |> ignore
