#!/usr/bin/env tclsh
# abstraction-provenance: {"artifact_sha256": "22501781b01e0ae9f139021187aa29a73c163e48193b18bff4c175d415539fad", "source_sha256": "8000e9809d37f9906f93defd5eae67343fbc40139349c6251ff385eeee2cb8fb", "target_language": "tcl"}
# index.html — portiert nach tcl
# Quelle: html, Onboarding@main:development/preview-renders/hover-mock/index.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

# Tcl 8.6 Script zur Erstellung der HTML-Datei index.html
# Portierung von HTML zu Tcl mit strukturiertem Aufbau

proc write_html {filename} {
    set f [open $filename w]
    
    puts $f {<!DOCTYPE html>}
    puts $f {<html lang="de">}
    puts $f {<head>}
    puts $f {<meta charset="UTF-8">}
    puts $f {<title>Hover-Preview Varianten · Vergleich</title>}
    puts $f {<style>}
    puts $f {  :root \{}
    puts $f {    --bg: #FAF8F4;}
    puts $f {    --ink: #1B1A17;}
    puts $f {    --accent: #A8542F;}
    puts $f {    --accent-2: #2E7D7B;}
    puts $f {    --font-display: 'Newsreader', Georgia, serif;}
    puts $f {    --font-body: 'Hanken Grotesk', -apple-system, sans-serif;}
    puts $f {    --font-mono: 'JetBrains Mono', monospace;}
    puts $f {  \}}
    puts $f {  * \{ box-sizing: border-box; margin: 0; padding: 0; \}}
    puts $f {  body \{}
    puts $f {    font-family: var(--font-body);}
    puts $f {    background: var(--bg);}
    puts $f {    color: var(--ink);}
    puts $f {    padding: 32px 16px 80px;}
    puts $f {  \}}
    puts $f {  h1 \{}
    puts $f {    font-family: var(--font-display);}
    puts $f {    font-weight: 500;}
    puts $f {    font-size: 28px;}
    puts $f {    max-width: 1400px;}
    puts $f {    margin: 0 auto 12px;}
    puts $f {  \}}
    puts $f {  .intro \{}
    puts $f {    max-width: 1400px;}
    puts $f {    margin: 0 auto 32px;}
    puts $f {    color: #666;}
    puts $f {    font-size: 14px;}
    puts $f {    line-height: 1.5;}
    puts $f {  \}}
    puts $f {  .grid \{}
    puts $f {    display: grid;}
    puts $f {    gap: 32px;}
    puts $f {    max-width: 1400px;}
    puts $f {    margin: 0 auto;}
    puts $f {  \}}
    puts $f {  .variant \{}
    puts $f {    background: #000;}
    puts $f {    border-radius: 16px;}
    puts $f {    overflow: hidden;}
    puts $f {    box-shadow: 0 12px 40px rgba(0,0,0,0.15);}
    puts $f {  \}}
    puts $f {  .variant-header \{}
    puts $f {    background: #fff;}
    puts $f {    padding: 16px 24px;}
    puts $f {    display: flex;}
    puts $f {    align-items: center;}
    puts $f {    justify-content: space-between;}
    puts $f {    gap: 16px;}
    puts $f {    border-bottom: 1px solid #eee;}
    puts $f {  \}}
    puts $f {  .variant-label \{}
    puts $f {    font-family: var(--font-mono);}
    puts $f {    font-size: 11px;}
    puts $f {    letter-spacing: 0.2em;}
    puts $f {    text-transform: uppercase;}
    puts $f {    color: var(--accent);}
    puts $f {    font-weight: 600;}
    puts $f {  \}}
    puts $f {  .variant-title \{}
    puts $f {    font-family: var(--font-display);}
    puts $f {    font-size: 20px;}
    puts $f {    font-weight: 500;}
    puts $f {  \}}
    puts $f {  .variant-desc \{}
    puts $f {    font-size: 13px;}
    puts $f {    color: #666;}
    puts $f {    flex: 1;}
    puts $f {    text-align: right;}
    puts $f {  \}}
    puts $f {  .scene \{}
    puts $f {    position: relative;}
    puts $f {    aspect-ratio: 16 / 9;}
    puts $f {    background: url('bg.png') center/cover no-repeat;}
    puts $f {    overflow: hidden;}
    puts $f {  \}}
    puts $f {  .orb \{}
    puts $f {    position: absolute;}
    puts $f {    width: 12%;}
    puts $f {    aspect-ratio: 1;}
    puts $f {    left: 42%;}
    puts $f {    top: 55%;}
    puts $f {    transform: translate(-50%, -50%);}
    puts $f {    cursor: pointer;}
    puts $f {  \}}
    puts $f {  .orb img \{ width: 100%; height: 100%; object-fit: contain; \}}

    puts $f {  /* Variante 1: Karte daneben */}
    puts $f {  .card-preview \{}
    puts $f {    position: absolute;}
    puts $f {    left: 55%;}
    puts $f {    top: 45%;}
    puts $f {    background: rgba(255,255,255,0.98);}
    puts $f {    padding: 16px 20px;}
    puts $f {    border-radius: 12px;}
    puts $f {    box-shadow: 0 8px 24px rgba(0,0,0,0.25);}
    puts $f {    width: 240px;}
    puts $f {    animation: slideIn 0.3s ease-out;}
    puts $f {  \}}
    puts $f {  .card-preview .badge \{}
    puts $f {    display: inline-block;}
    puts $f {    background: var(--accent-2);}
    puts $f {    color: white;}
    puts $f {    font-family: var(--font-mono);}
    puts $f {    font-size: 9px;}
    puts $f {    letter-spacing: 0.15em;}
    puts $f {    text-transform: uppercase;}
    puts $f {    padding: 3px 8px;}
    puts $f {    border-radius: 3px;}
    puts $f {    margin-bottom: 8px;}
    puts $f {  \}}
    puts $f {  .card-preview h3 \{}
    puts $f {    font-family: var(--font-display);}
    puts $f {    font-size: 18px;}
    puts $f {    font-weight: 500;}
    puts $f {    margin-bottom: 6px;}
    puts $f {    color: var(--ink);}
    puts $f {  \}}
    puts $f {  .card-preview p \{}
    puts $f {    font-size: 12px;}
    puts $f {    color: #555;}
    puts $f {    line-height: 1.4;}
    puts $f {  \}}
    puts $f {  @keyframes slideIn \{}
    puts $f {    from \{ opacity: 0; transform: translateX(-8px); \}}
    puts $f {    to \{ opacity: 1; transform: translateX(0); \}}
    puts $f {  \}}

    puts $f {  /* Variante 2: Minimaler Tooltip */}
    puts $f {  .tooltip \{}
    puts $f {    position: absolute;}
    puts $f {    left: 42%;}
    puts $f {    top: 46%;}
    puts $f {    transform: translate(-50%, -100%);}
    puts $f {    color: white;}
    puts $f {    text-shadow: 0 2px 12px rgba(0,0,0,0.8);}
    puts $f {    font-family: var(--font-display);}
    puts $f {    font-size: 20px;}
    puts $f {    font-weight: 500;}
    puts $f {    white-space: nowrap;}
    puts $f {    animation: fadeUp 0.3s ease-out;}
    puts $f {  \}}
    puts $f {  @keyframes fadeUp \{}
    puts $f {    from \{ opacity: 0; transform: translate(-50%, -80%); \}}
    puts $f {    to \{ opacity: 1; transform: translate(-50%, -100%); \}}
    puts $f {  \}}

    puts $f {  /* Variante 3: Vollflächiges Overlay */}
    puts $f {  .full-overlay \{}
    puts $f {    position: absolute;}
    puts $f {    inset: 0;}
    puts $f {    background: rgba(0,0,0,0.5);}
    puts $f {    backdrop-filter: blur(6px);}
    puts $f {    display: flex;}
    puts $f {    align-items: center;}
    puts $f {    justify-content: center;}
    puts $f {    animation: fadeIn 0.35s ease-out;}
    puts $f {  \}}
    puts $f {  .full-overlay .panel \{}
    puts $f {    background: rgba(255,255,255,0.98);}
    puts $f {    padding: 32px 40px;}
    puts $f {    border-radius: 20px;}
    puts $f {    max-width: 420px;}
    puts $f {    box-shadow: 0 20px 60px rgba(0,0,0,0.4);}
    puts $f {    text-align: center;}
    puts $f {  \}}
    puts $f {  .full-overlay .badge \{}
    puts $f {    display: inline-block;}
    puts $f {    background: var(--accent);}
    puts $f {    color: white;}
    puts $f {    font-family: var(--font-mono);}
    puts $f {    font-size: 10px;}
    puts $f {    letter-spacing: 0.2em;}
    puts $f {    text-transform: uppercase;}
    puts $f {    padding: 4px 10px;}
    puts $f {    border-radius: 4px;}
    puts $f {    margin-bottom: 14px;}
    puts $f {  \}}
    puts $f {  .full-overlay h3 \{}
    puts $f {    font-family: var(--font-display);}
    puts $f {    font-size: 28px;}
    puts $f {    font-weight: 500;}
    puts $f {    margin-bottom: 10px;}
    puts $f {    color: var(--ink);}
    puts $f {  \}}
    puts $f {  .full-overlay p \{}
    puts $f {    font-size: 14px;}
    puts $f {    color: #555;}
    puts $f {    line-height: 1.5;}
    puts $f {    margin-bottom: 20px;}
    puts $f {  \}}
    puts $f {  .full-overlay .preview-img \{}
    puts $f {    width: 100%;}
    puts $f {    aspect-ratio: 16/10;}
    puts $f {    background: linear-gradient(135deg, #A8542F, #2E7D7B);}
    puts $f {    border-radius: 8px;}
    puts $f {    margin-bottom: 16px;}
    puts $f {    display: flex;}
    puts $f {    align-items: center;}
    puts $f {    justify-content: center;}
    puts $f {    color: white;}
    puts $f {    font-family: var(--font-mono);}
    puts $f {    font-size: 11px;}
    puts $f {    letter-spacing: 0.15em;}
    puts $f {    opacity: 0.9;}
    puts $f {  \}}
    puts $f {  @keyframes fadeIn \{}
    puts $f {    from \{ opacity: 0; \}}
    puts $f {    to \{ opacity: 1; \}}
    puts $f {  \}}

    puts $f {  .instruction \{}
    puts $f {    text-align: center;}
    puts $f {    color: #999;}
    puts $f {    font-size: 12px;}
    puts $f {    margin-top: 16px;}
    puts $f {    font-family: var(--font-mono);}
    puts $f {    letter-spacing: 0.15em;}
    puts $f {    text-transform: uppercase;}
    puts $f {  \}}

    puts $f {  @media (max-width: 900px) \{}
    puts $f {    .card-preview \{ width: 180px; padding: 12px 14px; \}}
    puts $f {    .card-preview h3 \{ font-size: 15px; \}}
    puts $f {    .card-preview p \{ font-size: 11px; \}}
    puts $f {    .tooltip \{ font-size: 15px; \}}
    puts $f {    .full-overlay .panel \{ padding: 20px 24px; max-width: 300px; \}}
    puts $f {    .full-overlay h3 \{ font-size: 20px; \}}
    puts $f {  \}}
    puts $f {</style>}
    puts $f {<link rel="preconnect" href="https://fonts.googleapis.com">}
    puts $f {<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>}
    puts $f {<link href="https://fonts.googleapis.com/css2?family=Newsreader:wght@400;500&family=Hanken+Grotesk:wght@400;500&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">}
    puts $f {</head>}
    puts $f {<body>}
    puts $f {}
    puts $f {<h1>Hover-Preview · drei Varianten im Vergleich</h1>}
    puts $f {<p class="intro">Gleiche Szene, gleiche Kugel-Position (Beispiel: Projekt-Kugel "Weather-Check").<br>Alle drei Varianten zeigen den Zustand <em>bei Maushover</em>. Welche soll ins Projekt?</p>}
    puts $f {}
    puts $f {<div class="grid">}
    puts $f {}

    # Variante 1
    puts $f {  <!-- Variante 1 -->}
    puts $f {  <div class="variant">}
    puts $f {    <div class="variant-header">}
    puts $f {      <div>}
    puts $f {        <div class="variant-label">Variante 1</div>}
    puts $f {        <div class="variant-title">Karte daneben</div>}
    puts $f {      </div>}
    puts $f {      <div class="variant-desc">Kompakte Card rechts der Kugel · Titel + Badge + kurze Beschreibung aus content.ts · dezent, nicht störend</div>}
    puts $f {    </div>}
    puts $f {    <div class="scene">}
    puts $f {      <div class="orb"><img src="orb-01-teal.png" alt=""></div>}
    puts $f {      <div class="card-preview">}
    puts $f {        <span class="badge">GitHub · Public</span>}
    puts $f {        <h3>Weather-Check</h3>}
    puts $f {        <p>Progressive Web App für lokale Wetterdaten mit Live-Radar und Push-Benachrichtigungen.</p>}
    puts $f {      </div>}
    puts $f {    </div>}
    puts $f {  </div>}
    puts $f {}

    # Variante 2
    puts $f {  <!-- Variante 2 -->}
    puts $f {  <div class="variant">}
    puts $f {    <div class="variant-header">}
    puts $f {      <div>}
    puts $f {        <div class="variant-label">Variante 2</div>}
    puts $f {        <div class="variant-title">Minimaler Tooltip</div>}
    puts $f {      </div>}
    puts $f {      <div class="variant-desc">Nur der Titel schwebt über der Kugel · maximal reduziert · schnell erfassbar · lässt die Bildwirkung ungestört</div>}
    puts $f {    </div>}
    puts $f {    <div class="scene">}
    puts $f {      <div class="orb"><img src="orb-01-teal.png" alt=""></div>}
    puts $f {      <div class="tooltip">Weather-Check</div>}
    puts $f {    </div>}
    puts $f {  </div>}
    puts $f {}

    # Variante 3
    puts $f {  <!-- Variante 3 -->}
    puts $f {  <div class="variant">}
    puts $f {    <div class="variant-header">}
    puts $f {      <div>}
    puts $f {        <div class="variant-label">Variante 3</div>}
    puts $f {        <div class="variant-title">Vollflächiges Overlay</div>}
    puts $f {      </div>}
    puts $f {      <div class="variant-desc">Zentrales Modal mit Preview-Bild + Titel + Beschreibung · prominent · lädt zum Klicken ein · verdeckt aber Szene</div>}
    puts $f {    </div>}
    puts $f {    <div class="scene">}
    puts $f {      <div class="orb"><img src="orb-01-teal.png" alt=""></div>}
    puts $f {      <div class="full-overlay">}
    puts $f {        <div class="panel">}
    puts $f {          <div class="preview-img">PROJEKT-PREVIEW</div>}
    puts $f {          <span class="badge">GitHub · Public</span>}
    puts $f {          <h3>Weather-Check</h3>}
    puts $f {          <p>Progressive Web App für lokale Wetterdaten mit Live-Radar und Push-Benachrichtigungen.</p>}
    puts $f {        </div>}
    puts $f {      </div>}
    puts $f {    </div>}
    puts $f {  </div>}
    puts $f {}

    puts $f {</div>}
    puts $f {}
    puts $f {<p class="instruction">Sag mir welche Variante — dann baue ich sie ins Frontend ein.</p>}
    puts $f {}
    puts $f {</body>}
    puts $f {</html>}
    
    close $f
}

# Hauptprogramm - liest ersten Parameter als Dateinamen
if {$argc != 1} {
    puts "Verwendung: $argv0 <dateiname>"
    exit 1
}

set filename [lindex $argv 0]
write_html $filename
