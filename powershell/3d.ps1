#!/usr/bin/env pwsh
# 3d.js — portiert nach powershell
# Quelle: javascript, Projects@abstractions:javascript/3d.js
# Erzeugt: 2026-08-18 durch ABSTRACTIONS_MANAGER.py

# 3d.html — portiert nach PowerShell
# Quelle: html, Projects@tagesstatus-live-public:public/3d.html
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

# Prüfe, ob ein Dateiname übergeben wurde
if ($args.Count -lt 1) {
    Write-Error "Verwendung: pwsh 3d.ps1 <dateiname>"
    exit 1
}

$filename = $args[0]

# Erstelle das HTML-Dokument
function Create-Document {
    $html = @"
<!DOCTYPE html>
<html lang="de">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Tagesstatus Live Public — Interaktive Architektur</title>
<meta name="description" content="Acht Dienste, ein Blick: Tokens, Abruf, Kacheln — drehen, zoomen, Knoten auswählen.">
<meta name="theme-color" content="#0f766e">
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
<p class="technik">PowerShell · ohne 3D</p>
<h1>Tagesstatus Live Public</h1>
<p class="lede">Acht Dienste, ein Blick: Tokens, Abruf, Kacheln — drehen, zoomen, Knoten auswählen.</p>
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
<dl class="feld">
<dt>Schicht</dt>
<dd id="k-schicht">—</dd>
</dl>
<dl class="feld">
<dt>ID</dt>
<dd id="k-id">—</dd>
</dl>
<div class="blaettern">
<button id="btn-prev">←<br>Vorheriger</button>
<button id="btn-next">Nächster<br>→</button>
</div>
</aside>
</div>
<div class="legende" id="legende"></div>
<p class="fuss">Schematische Dokumentationsansicht — Blockgrößen messen weder Datenmenge noch Leistung. Keine Telemetrie, keine Fernabfragen: Die Seite lädt einmalig three.js vom CDN und rechnet danach ausschließlich lokal.</p>
</div>
</body>
</html>
"@
    return $html
}

# Hauptfunktion
function Main {
    # Erstelle das Dokument
    $doc = Create-Document
    
    # Schreibe das HTML in eine Datei
    $doc | Out-File -FilePath $filename -Encoding UTF8
    
    Write-Output "HTML-Datei wurde erfolgreich erstellt: $filename"
}

Main
