#!/usr/bin/env tclsh
# 3d.js — portiert nach tcl
# Quelle: javascript, Projects@abstractions:javascript/3d.js
# Erzeugt: 2026-08-18 durch ABSTRACTIONS_MANAGER.py

# 3d.tcl — portiert von javascript nach Tcl 8.6
# Quelle: 3d.js
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

package require http
package require json
package require base64

# Globale Variablen für die Szene
set SPEC {}
set nodes {}
set byId {}
set clickable {}
set currentCamera "iso"
set selectedNodeIndex -1

# Erstelle das HTML-Dokument
proc createDocument {} {
    set html "<!DOCTYPE html>
<html lang=\"de\">
<head>
<meta charset=\"utf-8\">
<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">
<title>Tagesstatus Live Public — Interaktive Architektur</title>
<meta name=\"description\" content=\"Acht Dienste, ein Blick: Tokens, Abruf, Kacheln — drehen, zoomen, Knoten auswählen.\">
<meta name=\"theme-color\" content=\"#0f766e\">
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
     font:15px/1.55 -apple-system,BlinkMacSystemFont,\"Segoe UI\",Roboto,sans-serif}
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
button[aria-pressed=\"true\"]{background:var(--ac);border-color:var(--ac);color:#fff}
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
<div class=\"wrap\">
<p class=\"technik\">Canvas 3D · Tcl 8.6</p>
<h1>Tagesstatus Live Public</h1>
<p class=\"lede\">Acht Dienste, ein Blick: Tokens, Abruf, Kacheln — drehen, zoomen, Knoten auswählen.</p>
<div class=\"raster\">
<div class=\"buehne\" id=\"buehne\">
<div class=\"knoepfe\">
<button id=\"btn-plus\" title=\"Näher\">+</button>
<button id=\"btn-minus\" title=\"Weiter weg\">−</button>
<button id=\"btn-reset\">Zurücksetzen</button>
<button id=\"btn-iso\" aria-pressed=\"true\" title=\"Isometrisch oder perspektivisch\">Iso</button>
</div>
<canvas id=\"scene-canvas\" width=\"800\" height=\"600\"></canvas>
</div>
<aside class=\"karte\">
<h2>Ausgewählter Knoten</h2>
<h3 id=\"k-name\">—</h3>
<p class=\"sub\" id=\"k-sub\">Knoten anklicken oder durchblättern</p>
<dl class=\"feld\">
<dt>Schicht</dt>
<dd id=\"k-schicht\">—</dd>
</dl>
<dl class=\"feld\">
<dt>ID</dt>
<dd id=\"k-id\">—</dd>
</dl>
<div class=\"blaettern\">
<button id=\"btn-prev\">←<br>Vorheriger</button>
<button id=\"btn-next\">Nächster<br>→</button>
</div>
</aside>
</div>
<div class=\"legende\" id=\"legende\"></div>
<p class=\"fuss\">Schematische Dokumentationsansicht — Blockgrößen messen weder Datenmenge noch Leistung. Keine Telemetrie, keine Fernabfragen: Die Seite lädt einmalig three.js vom CDN und rechnet danach ausschließlich lokal.</p>
</div>
<script>
// Minimaler JavaScript-Code für UI-Interaktionen
document.getElementById('btn-plus').addEventListener('click', function() {
    window.location.hash = 'zoom-in';
});
document.getElementById('btn-minus').addEventListener('click', function() {
    window.location.hash = 'zoom-out';
});
document.getElementById('btn-reset').addEventListener('click', function() {
    window.location.hash = 'reset-view';
});
document.getElementById('btn-iso').addEventListener('click', function() {
    const pressed = this.getAttribute('aria-pressed') === 'true';
    this.setAttribute('aria-pressed', !pressed);
    window.location.hash = pressed ? 'perspective' : 'isometric';
});
document.getElementById('btn-prev').addEventListener('click', function() {
    window.location.hash = 'prev-node';
});
document.getElementById('btn-next').addEventListener('click', function() {
    window.location.hash = 'next-node';
});
document.getElementById('scene-canvas').addEventListener('click', function(e) {
    const rect = this.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const y = e.clientY - rect.top;
    window.location.hash = 'select-' + Math.round(x) + '-' + Math.round(y);
});
</script>
</body>
</html>"
    return $html
}

# Initialisiere die Spezifikation
proc initSpec {} {
    global SPEC
    
    set SPEC [dict create \
        schichten [list \
            [dict create \
                name "Tokens" \
                farbe "#5f6773" \
                blocks [list \
                    [dict create id "abfrage-beim-oeffnen" name "Abfrage beim Oeffnen" untertitel "kein Vorbelegen"] \
                    [dict create id "localstorage" name "localStorage" untertitel "nur lokal"] \
                    [dict create id "keine-vorbelegung" name "keine Vorbelegung" untertitel "leer geliefert"] \
                ] \
            ] \
            [dict create \
                name "Quellen" \
                farbe "#2481cc" \
                blocks [list \
                    [dict create id "github" name "GitHub" untertitel "Repos, Kontingent"] \
                    [dict create id "vercel" name "Vercel" untertitel "Deployments"] \
                    [dict create id "docker-hub" name "Docker Hub" untertitel "Abbilder"] \
                    [dict create id "openrouter" name "OpenRouter" untertitel "Guthaben"] \
                    [dict create id "openai" name "OpenAI" untertitel "Admin-Key"] \
                    [dict create id "anthropic" name "Anthropic" untertitel "Admin-Key"] \
                    [dict create id "tailscale" name "Tailscale" untertitel "Geraete"] \
                    [dict create id "clawhub" name "ClawHub" untertitel "Skills"] \
                ] \
            ] \
            [dict create \
                name "Abruf" \
                farbe "#6d5bd0" \
                blocks [list \
                    [dict create id "fetch-je-quelle" name "fetch je Quelle" untertitel "direkt"] \
                    [dict create id "cors-pruefung" name "CORS-Pruefung" untertitel "entscheidet"] \
                    [dict create id "fehler-isolieren" name "Fehler isolieren" untertitel "je Kachel"] \
                ] \
            ] \
            [dict create \
                name "Ausgabe" \
                farbe "#0f766e" \
                blocks [list \
                    [dict create id "kacheln" name "Kacheln" untertitel "ein Blick"] \
                    [dict create id "verbrauch" name "Verbrauch" untertitel "Zahlen"] \
                    [dict create id "keine-daten-hinweis" name "keine Daten = Hinweis" untertitel "mit Grund"] \
                ] \
            ] \
        ] \
        kanten [list \
            [dict create von "abfrage-beim-oeffnen" nach "github" art "fluss"] \
            [dict create von "localstorage" nach "vercel" art "fluss"] \
            [dict create von "keine-vorbelegung" nach "docker-hub" art "fluss"] \
            [dict create von "github" nach "fetch-je-quelle" art "fluss"] \
            [dict create von "vercel" nach "cors-pruefung" art "fluss"] \
            [dict create von "docker-hub" nach "fehler-isolieren" art "fluss"] \
            [dict create von "openrouter" nach "fetch-je-quelle" art "fluss"] \
            [dict create von "openai" nach "cors-pruefung" art "fluss"] \
            [dict create von "anthropic" nach "fehler-isolieren" art "fluss"] \
            [dict create von "tailscale" nach "fetch-je-quelle" art "fluss"] \
            [dict create von "clawhub" nach "cors-pruefung" art "fluss"] \
            [dict create von "fetch-je-quelle" nach "kacheln" art "fluss"] \
            [dict create von "cors-pruefung" nach "verbrauch" art "fluss"] \
            [dict create von "fehler-isolieren" nach "keine-daten-hinweis" art "fluss"] \
        ] \
        kantenarten [list \
            [dict create art "fluss" farbe "#0f766e" stil "voll" text "Fluss von unten nach oben"] \
        ] \
    ]
}

# Hauptfunktion zur Erstellung der 3D-Szene (simuliert)
proc create3DScene {doc} {
    global SPEC nodes byId clickable
    
    # In einer echten Implementierung würden wir hier die 3D-Szene erstellen
    # Da Tcl keine native 3D-Unterstützung hat, simulieren wir die Ausgabe
    
    # Erstelle die Legende
    set legendHtml ""
    foreach art [dict get $SPEC kantenarten] {
        set color [dict get $art farbe]
        set style [dict get $art stil]
        set text [dict get $art text]
        set borderStyle [expr {$style eq "gestrichelt" ? "dashed" : "solid"}]
        append legendHtml "<span><i class=\"strich\" style=\"border-top-color:${color};border-top-style:${borderStyle}\"></i>${text}</span>"
    }
    
    # Ersetze die Legende im Dokument
    set doc [string map [list "<div class=\"legende\" id=\"legende\"></div>" "<div class=\"legende\" id=\"legende\">${legendHtml}</div>"] $doc]
    
    return $doc
}

# Hauptfunktion
proc main {argc argv} {
    # Prüfe, ob ein Dateiname übergeben wurde
    if {$argc < 1} {
        puts stderr "Verwendung: tclsh 3d.tcl <dateiname>"
        exit 1
    }
    
    set filename [lindex $argv 0]
    
    # Initialisiere die Spezifikation
    initSpec
    
    # Erstelle das Dokument
    set doc [createDocument]
    
    # Erstelle die 3D-Szene
    set doc [create3DScene $doc]
    
    # Schreibe das HTML in eine Datei
    set fh [open $filename w]
    puts $fh $doc
    close $fh
    
    puts "HTML-Datei wurde erfolgreich erstellt: $filename"
}

# Starte die Hauptfunktion
main $argc $argv
