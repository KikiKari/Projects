#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "a054ff222752789f9b2391ca36e37c11d648d2474ac610abfef3c71522ac881a", "source_sha256": "1af3533731f49a592a9bf1403bd2219e023d0d8fc974ae8ed0223565071239ed", "target_language": "ruby"}
# 3d.html — portiert nach ruby
# Quelle: html, Projects@MCP-Server-Monitor:public/3d.html
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

require 'json'

# Helper to generate HTML elements with attributes and content
class HtmlGenerator
  def initialize
    @output = []
  end

  def tag(name, attrs = {}, &block)
    attr_str = attrs.map { |k, v| "#{k}=\"#{v}\"" }.join(' ')
    attr_str = " #{attr_str}" unless attr_str.empty?
    
    if block_given?
      content = capture(&block)
      @output << "<#{name}#{attr_str}>#{content}</#{name}>"
    else
      @output << "<#{name}#{attr_str}></#{name}>"
    end
  end

  def self_closing_tag(name, attrs = {})
    attr_str = attrs.map { |k, v| "#{k}=\"#{v}\"" }.join(' ')
    attr_str = " #{attr_str}" unless attr_str.empty?
    @output << "<#{name}#{attr_str}>"
  end

  def text(content)
    @output << content
  end

  def method_missing(method_name, *args, &block)
    if block_given?
      tag(method_name.to_s, args.first || {}, &block)
    else
      tag(method_name.to_s, args.first || {})
    end
  end

  def to_s
    @output.join("\n")
  end

  private

  def capture(&block)
    old_output = @output.dup
    @output.clear
    instance_eval(&block)
    result = @output.join
    @output = old_output
    result
  end
end

def generate_html(spec_data)
  html = HtmlGenerator.new
  
  html.doctype 'html'
  html.html(lang: 'de') do
    html.head do
      html.meta(charset: 'utf-8')
      html.meta(name: 'viewport', content: 'width=device-width, initial-scale=1')
      html.title { 'MCP-Server-Monitor — Interaktive Architektur' }
      html.meta(name: 'description', content: 'Warum fehlen die Tools? Vier Schichten von der Netz-Sonde bis zur Ausgabe — drehen, zoomen, Knoten auswählen.')
      html.meta(name: 'theme-color', content: '#6d5bd0')
      
      html.style do
        <<-CSS
  :root{
    --bg:#fbfaf7; --panel:#fff; --line:#e6e3dc; --text:#16191d; --muted:#5f6773;
    --ac:#6d5bd0; --buehne:#0e1420; --buehne-line:#1d2739;
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
        CSS
      end
    end
    
    html.body do
      html.div(class: 'wrap') do
        html.p(class: 'technik') { 'three.js · r128' }
        html.h1 { 'MCP-Server-Monitor' }
        html.p(class: 'lede') { 'Warum fehlen die Tools? Vier Schichten von der Netz-Sonde bis zur Ausgabe — drehen, zoomen, Knoten auswählen.' }
        
        html.div(class: 'raster') do
          html.div(class: 'buehne', id: 'buehne') do
            html.div(class: 'knoepfe') do
              html.button(id: 'btn-plus', title: 'Näher') { '+' }
              html.button(id: 'btn-minus', title: 'Weiter weg') { '−' }
              html.button(id: 'btn-reset') { 'Zurücksetzen' }
              html.button(id: 'btn-iso', 'aria-pressed': 'true', title: 'Isometrisch oder perspektivisch') { 'Iso' }
            end
          end
          
          html.aside(class: 'karte') do
            html.h2 { 'Ausgewählter Knoten' }
            html.h3(id: 'k-name') { '—' }
            html.p(class: 'sub', id: 'k-sub') { 'Knoten anklicken oder durchblättern' }
            html.dl(class: 'feld') do
              html.dt { 'Schicht' }
              html.dd(id: 'k-schicht') { '—' }
            end
            html.dl(class: 'feld') do
              html.dt { 'ID' }
              html.dd(id: 'k-id') { '—' }
            end
            html.div(class: 'blaettern') do
              html.button(id: 'btn-prev') { "←\nVorheriger" }
              html.button(id: 'btn-next') { "Nächster\n→" }
            end
          end
        end
        
        html.div(class: 'legende', id: 'legende') {}
        html.p(class: 'fuss') { 'Schematische Dokumentationsansicht — Blockgrößen messen weder Datenmenge noch Leistung. Keine Telemetrie, keine Fernabfragen: Die Seite lädt einmalig three.js vom CDN und rechnet danach ausschließlich lokal.' }
      end
    end
    
    html.script(src: 'https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js') {}
    
    html.script do
      "(function(){
  \"use strict\";
  var SPEC = #{spec_data.to_json};

  var buehne = document.getElementById(\"buehne\");
  if (typeof THREE === \"undefined\"){
    buehne.insertAdjacentHTML(\"beforeend\",
      '<div class=\"fehler\">three.js konnte nicht geladen werden. ' +
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
    var c = document.createElement(\"canvas\"), x = c.getContext(\"2d\");
    var f1 = \"700 40px -apple-system,Segoe UI,Roboto,sans-serif\";
    var f2 = \"500 27px -apple-system,Segoe UI,Roboto,sans-serif\";
    x.font = f1; var w1 = x.measureText(text).width;
    x.font = f2; var w2 = unter ? x.measureText(unter).width : 0;
    var w = Math.ceil(Math.max(w1, w2)) + 40, h = unter ? 96 : 62;
    c.width = w; c.height = h;
    x = c.getContext(\"2d\");
    x.fillStyle = \"rgba(255,255,255,.95)\";
    if (x.roundRect){ x.beginPath(); x.roundRect(0,0,w,h,13); x.fill(); }
    else x.fillRect(0,0,w,h);
    x.fillStyle = \"#16191d\"; x.font = f1; x.textBaseline = \"middle\";
    x.fillText(text, 20, unter ? 32 : 31);
    if (unter){ x.fillStyle = \"#5f6773\"; x.font = f2; x.fillText(unter, 20, 68); }
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
      return (typeof b === \"string\") ? {id:null, name:b, untertitel:\"\"} : b;
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

      var id = b.id || (b.name.toLowerCase().replace(/[^a-z0-9]+/g, \"-\").replace(/^-|-$/g, \"\"));
      var eintrag = {id:id, name:b.name, untertitel:b.untertitel||\"\", schicht:sch.name,
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
    var art = STIL[k.art] || {farbe:\"#8ea2ff\", stil:\"voll\"};
    var g = new THREE.BufferGeometry().setFromPoints([
      a.pos.clone().setY(a.pos.y + 0.9), b.pos.clone().setY(b.pos.y - 0.9)]);
    var linie;
    if (art.stil === \"gestrichelt\"){
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

  var leg = document.getElementById(\"legende\");
  (SPEC.kantenarten || []).forEach(function(a){
    var s = document.createElement(\"span\");
    s.innerHTML = '<i class=\"strich\" style=\"border-top-color:' + a.farbe +
                  ';border-top-style:' + (a.stil === \"gestrichelt\" ? \"dashed\" : \"solid\") +
                  '\"></i>' + a.text;
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
    document.getElementById(\"k-name\").textContent = k.name;
    document.getElementById(\"k-sub\").textContent = k.untertitel || \"—\";
    document.getElementById(\"k-schicht\").textContent = k.schicht;
    document.getElementById(\"k-id\").textContent = k.id;
  }

  var strahl = new THREE.Raycaster(), zeiger = new THREE.Vector2();
  renderer.domElement.addEventListener(\"click\", function(e){
    if (gezogen) return;
    var r = renderer.domElement.getBoundingClientRect();
    zeiger.x = ((e.clientX - r.left) / r.width) * 2 - 1;
    zeiger.y = -((e.clientY - r.top) / r.height) * 2 + 1;
    strahl.setFromCamera(zeiger, kamera);
    var treffer = strahl.intersectObjects(klickbar, false);
    if (treffer.length) waehle(treffer[0].object.userData.index);
  });
  document.getElementById(\"btn-prev\").addEventListener(\"click\", function(){ waehle(aktiv - 1); });
  document.getElementById(\"btn-next\").addEventListener(\"click\", function(){ waehle(aktiv + 1); });

  // ------------------------------------------------------------- Kamera ----
  var azimut = Math.PI/4, elevation = 0.62, rotiert = true;
  function stelle(){
    var x = radius*Math.cos(elevation)*Math.sin(azimut);
    var y = radius*Math.sin(elevation);
    var z = radius*Math.cos(elevation)*Math.cos(azimut);
    kamera.position.set(x, y, z); kamera.lookAt(0, 0, 0);
  }
  var zieht = false, gezogen = false, lx = 0, ly = 0;
  renderer.domElement.addEventListener(\"pointerdown\", function(e){
    zieht = true; gezogen = false; lx = e.clientX; ly = e.clientY;
  });
  window.addEventListener(\"pointermove\", function(e){
    if (!zieht) return;
    if (Math.abs(e.clientX-lx) + Math.abs(e.clientY-ly) > 3){ gezogen = true; rotiert = false; }
    azimut -= (e.clientX - lx) * 0.006;
    elevation = Math.max(0.08, Math.min(1.45, elevation + (e.clientY - ly) * 0.005));
    lx = e.clientX; ly = e.clientY;
  });
  window.addEventListener(\"pointerup\", function(){ zieht = false; setTimeout(function(){ gezogen = false; }, 0); });

  function zoom(f){
    if (iso){ D = Math.max(11, Math.min(54, D * f)); groesse(); }
    else { radius = Math.max(32, Math.min(160, radius * f)); }
  }
  document.getElementById(\"btn-plus\").addEventListener(\"click\", function(){ zoom(0.85); });
  document.getElementById(\"btn-minus\").addEventListener(\"click\", function(){ zoom(1.18); });
  renderer.domElement.addEventListener(\"wheel\", function(e){
    e.preventDefault(); zoom(e.deltaY > 0 ? 1.08 : 0.93);
  }, {passive:false});
  document.getElementById(\"btn-reset\").addEventListener(\"click\", function(){
    azimut = Math.PI/4; elevation = 0.62; D = 26; radius = 82; rotiert = true;
    iso = true; kamera = kameraIso;
    document.getElementById(\"btn-iso\").setAttribute(\"aria-pressed\", \"true\");
    document.getElementById(\"btn-iso\").textContent = \"Iso\";
    waehle(0); groesse();
  });
  document.getElementById(\"btn-iso\").addEventListener(\"click\", function(){
    iso = !iso; kamera = iso ? kameraIso : kameraPersp;
    this.setAttribute(\"aria-pressed\", String(iso));
    this.textContent = iso ? \"Iso\" : \"Persp\";
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
  window.addEventListener(\"resize\", groesse);

  groesse();
  waehle(0);
  (function schleife(){
    requestAnimationFrame(schleife);
    if (rotiert) azimut += 0.003;
    stelle();
    renderer.render(szene, kamera);
  })();
})();"
    end
  end
  
  html.to_s
end

# Main execution
if __FILE__ == $0
  # Read specification data from file or use default
  spec_file = ARGV[0] || 'spec.json'
  
  if File.exist?(spec_file)
    spec_data = JSON.parse(File.read(spec_file))
  else
    # Default specification data
    spec_data = {
      "schichten" => [
        {
          "name" => "Quellen",
          "farbe" => "#5f6773",
          "blocks" => [
            {"id" => "mcp-domain", "name" => "mcp.DOMAIN", "untertitel" => "Streamable HTTP"},
            {"id" => "docs-mcp", "name" => "docs/mcp", "untertitel" => "Anbieterdoku"},
            {"id" => "well-known", "name" => ".well-known", "untertitel" => "OAuth-Metadaten"},
            {"id" => "config-json", "name" => "config.json", "untertitel" => "claude_desktop_config"}
          ]
        },
        {
          "name" => "Sonde",
          "farbe" => "#2481cc",
          "blocks" => [
            {"id" => "discovery-py", "name" => "discovery.py", "untertitel" => "sechs Pfade"},
            {"id" => "config-py", "name" => "config.py", "untertitel" => "MSIX-Falle"}
          ]
        },
        {
          "name" => "Klassifikation",
          "farbe" => "#6d5bd0",
          "blocks" => [
            {"id" => "state-py", "name" => "state.py", "untertitel" => "fuenf Zustaende"}
          ]
        },
        {
          "name" => "Ausgabe",
          "farbe" => "#15803d",
          "blocks" => [
            {"id" => "report-py", "name" => "report.py", "untertitel" => "Textausgabe"},
            {"id" => "server-py", "name" => "server.py", "untertitel" => "127.0.0.1"},
            {"id" => "index-html", "name" => "index.html", "untertitel" => "statische Seite"}
          ]
        }
      ],
      "kanten" => [
        {"von" => "mcp-domain", "nach" => "discovery-py", "art" => "fluss"},
        {"von" => "docs-mcp", "nach" => "config-py", "art" => "fluss"},
        {"von" => "well-known", "nach" => "discovery-py", "art" => "fluss"},
        {"von" => "config-json", "nach" => "config-py", "art" => "fluss"},
        {"von" => "discovery-py", "nach" => "state-py", "art" => "fluss"},
        {"von" => "config-py", "nach" => "state-py", "art" => "fluss"},
        {"von" => "state-py", "nach" => "report-py", "art" => "fluss"}
      ],
      "kantenarten" => [
        {"art" => "fluss", "farbe" => "#6d5bd0", "stil" => "voll", "text" => "Fluss von unten nach oben"}
      ]
    }
  end
  
  # Generate HTML
  html_content = generate_html(spec_data)
  
  # Output to file or stdout
  output_file = ARGV[1] if ARGV.length > 1
  
  if output_file
    File.write(output_file, html_content)
    puts "HTML generated and saved to #{output_file}"
  else
    puts html_content
  end
end
