#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "9384d36d984028a7f02814086003ad0d42fde751fed62f9a3be1dfeaca4d26eb", "source_sha256": "58ad2830d3e11b79c54044cfe5a82e7e3fd2a9b1ca1f65c546ff6e92e821c6f3", "target_language": "lua"}
-- index.html — portiert nach lua
-- Quelle: html, Projects@Telegram-Monitor:public/index.html
-- Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

local function generate_html()
    local html = {}

    local function add(...)
        table.insert(html, table.concat({...}))
    end

    -- DOCTYPE and basic structure
    add('<!DOCTYPE html>\n')
    add('<html lang="de">\n')
    add('<head>\n')
    add('<meta charset="utf-8">\n')
    add('<meta name="viewport" content="width=device-width, initial-scale=1">\n')
    add('<title>Telegram Monitor — lokaler Beobachtungs-Companion</title>\n')
    add('<meta name="description" content="Beobachtet öffentliche Telegram-Kanäle und TikTok-Konten auf dem eigenen Rechner und meldet den Livegang. Keine Cloud, keine Anmeldung.">\n')
    add('<meta name="theme-color" content="#2481cc">\n')
    add('<meta property="og:title" content="Telegram Monitor">\n')
    add('<meta property="og:description" content="Lokaler Beobachtungs-Companion. Docker, PWA, Meldung beim Livegang.">\n')
    add('<meta property="og:type" content="website">\n')
    
    -- Styles
    add('<style>\n')
    add('  :root{\n')
    add('    --bg:#ffffff; --soft:#f6f7f9; --line:#e3e6ea; --text:#16191d; --muted:#5f6773;\n')
    add('    --tg:#2481cc; --tg-soft:#e8f2fb; --tt:#fe2c55;\n')
    add('    --ok:#15803d; --ok-soft:#e7f6ec; --warn:#b45309; --warn-soft:#fdf3e3;\n')
    add('    color-scheme: light;\n')
    add('  }\n')
    add('  @media (prefers-color-scheme: dark){\n')
    add('    :root{ --bg:#0f1115; --soft:#171a21; --line:#262b36; --text:#f2f4f8; --muted:#9aa3b2;\n')
    add('           --tg-soft:#132a3d; --ok-soft:#12261a; --warn-soft:#2c2110; color-scheme: dark; }\n')
    add('  }\n')
    add('  *{box-sizing:border-box}\n')
    add('  body{margin:0;background:var(--bg);color:var(--text);\n')
    add('       font:16px/1.6 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif}\n')
    add('  .wrap{max-width:820px;margin:0 auto;padding:0 20px 72px}\n')
    add('  header{padding:64px 0 40px;border-bottom:1px solid var(--line);margin-bottom:8px}\n')
    add('  h1{font-size:34px;line-height:1.2;margin:0 0 12px;letter-spacing:-.02em}\n')
    add('  .lede{font-size:18px;color:var(--muted);margin:0 0 22px;max-width:60ch}\n')
    add('  h2{font-size:13px;margin:44px 0 14px;text-transform:uppercase;letter-spacing:.06em;\n')
    add('     color:var(--muted);font-weight:650}\n')
    add('  h3{font-size:17px;margin:26px 0 6px}\n')
    add('  p{margin:0 0 14px;max-width:68ch}\n')
    add('  .badges{display:flex;gap:7px;flex-wrap:wrap;margin-bottom:22px}\n')
    add('  .badge{font-size:12px;font-weight:650;padding:4px 11px;border-radius:99px;\n')
    add('         background:var(--soft);color:var(--muted);border:1px solid var(--line)}\n')
    add('  .badge.on{background:var(--ok-soft);color:var(--ok);border-color:transparent}\n')
    add('  .cta{display:flex;gap:10px;flex-wrap:wrap}\n')
    add('  .btn{display:inline-block;font-weight:650;font-size:15px;padding:11px 20px;\n')
    add('       border-radius:9px;text-decoration:none;border:1px solid var(--line);\n')
    add('       background:var(--bg);color:var(--text)}\n')
    add('  .btn.primary{background:var(--tg);border-color:var(--tg);color:#fff}\n')
    add('  .btn:hover{border-color:var(--tg)}\n')
    add('  .grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(230px,1fr));gap:14px}\n')
    add('  .card{border:1px solid var(--line);border-radius:12px;padding:16px 18px;background:var(--bg)}\n')
    add('  .card h3{margin-top:0;font-size:15.5px}\n')
    add('  .card p{font-size:14px;color:var(--muted);margin:0}\n')
    add('  ol.steps{list-style:none;counter-reset:s;padding:0;margin:0}\n')
    add('  ol.steps li{counter-increment:s;position:relative;padding:0 0 20px 40px;\n')
    add('              border-left:2px solid var(--line);margin-left:11px}\n')
    add('  ol.steps li:last-child{border-left-color:transparent;padding-bottom:0}\n')
    add('  ol.steps li::before{content:counter(s);position:absolute;left:-13px;top:0;\n')
    add('       width:24px;height:24px;border-radius:50%;background:var(--tg);color:#fff;\n')
    add('       display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:700}\n')
    add('  ol.steps b{display:block;margin-bottom:3px}\n')
    add('  ol.steps p{font-size:14.5px;color:var(--muted);margin:0 0 8px}\n')
    add('  code{background:var(--soft);padding:2px 7px;border-radius:5px;font-size:13.5px;\n')
    add('       font-family:ui-monospace,SFMono-Regular,Menlo,monospace;word-break:break-word}\n')
    add('  pre{background:var(--soft);border:1px solid var(--line);border-radius:10px;\n')
    add('      padding:13px 15px;overflow-x:auto;margin:0 0 14px}\n')
    add('  pre code{background:none;padding:0;font-size:13.5px;line-height:1.7}\n')
    add('  table{width:100%;border-collapse:collapse;font-size:14.5px;margin:0 0 16px}\n')
    add('  th,td{text-align:left;padding:9px 11px;border-bottom:1px solid var(--line);vertical-align:top}\n')
    add('  th{color:var(--muted);font-size:12px;text-transform:uppercase;letter-spacing:.04em;font-weight:650}\n')
    add('  .note{border-left:3px solid var(--warn);background:var(--warn-soft);\n')
    add('        border-radius:0 9px 9px 0;padding:13px 16px;margin:0 0 16px;font-size:14.5px}\n')
    add('  .note b{display:block;margin-bottom:3px}\n')
    add('  a{color:var(--tg)}\n')
    add('  footer{margin-top:52px;padding-top:22px;border-top:1px solid var(--line);\n')
    add('         font-size:13.5px;color:var(--muted)}\n')
    add('</style>\n')
    add('</head>\n')
    add('<body>\n')
    add('<div class="wrap">\n\n')

    -- Header
    add('<header>\n')
    add('  <h1>Telegram Monitor</h1>\n')
    add('  <p class="lede">Beobachtet öffentliche Telegram-Kanäle und TikTok-Konten auf\n')
    add('     deinem eigenen Rechner und meldet sich, wenn jemand live geht. Keine Cloud,\n')
    add('     kein Konto, keine App-Installation auf dem Telefon nötig.</p>\n')
    add('  <div class="badges">\n')
    add('    <span class="badge on">Standardbibliothek</span>\n')
    add('    <span class="badge on">Docker</span>\n')
    add('    <span class="badge on">installierbar als App</span>\n')
    add('    <span class="badge on">Browser-Erweiterung</span>\n')
    add('    <span class="badge">Windows · macOS · Linux</span>\n')
    add('  </div>\n')
    add('  <div class="cta">\n')
    add('    <a class="btn primary" href="https://github.com/KikiKari/Projects/tree/Telegram-Monitor">Quelltext auf GitHub</a>\n')
    add('    <a class="btn" href="/viewer">Live-Viewer öffnen</a>\n')
    add('  </div>\n')
    add('</header>\n\n')

    -- What it does section
    add('<h2>Was es tut</h2>\n')
    add('<div class="grid">\n')
    add('  <div class="card">\n')
    add('    <h3>Beobachten</h3>\n')
    add('    <p>Fragt jeden Kanal im eingestellten Turnus ab und sammelt den Verlauf auf\n')
    add('       der Platte — neueste Beiträge oben, anders als in Telegram selbst.</p>\n')
    add('  </div>\n')
    add('  <div class="card">\n')
    add('    <h3>Erkennen</h3>\n')
    add('    <p>Vergleicht den Zustand mit dem letzten Durchlauf. Gemeldet wird nur ein\n')
    add('       echter Wechsel; ein fehlgeschlagener Abruf gilt nicht als „offline".</p>\n')
    add('  </div>\n')
    add('  <div class="card">\n')
    add('    <h3>Melden</h3>\n')
    add('    <p>Drei Wege gleichzeitig: Ereignisprotokoll, Systemmeldung und Webhook.\n')
    add('       Fällt einer aus, steht der Wechsel trotzdem mit Zeitstempel fest.</p>\n')
    add('  </div>\n')
    add('</div>\n\n')

    -- Three access points section
    add('<h2>Drei Zugänge, ein Monitor</h2>\n')
    add('<table>\n')
    add('  <tr><th>Zugang</th><th>wofür</th></tr>\n')
    add('  <tr><td><b>Installierte App</b></td>\n')
    add('      <td>Vollständige Oberfläche mit allen Reitern, eigenes Fenster ohne\n')
    add('          Adressleiste, Symbol im Startmenü</td></tr>\n')
    add('  <tr><td><b>Browser-Erweiterung</b></td>\n')
    add('      <td>Meldung beim Livegang, ohne dass ein Tab offen sein muss</td></tr>\n')
    add('  <tr><td><b>Live-Viewer</b></td>\n')
    add('      <td>Bettet den offiziellen Player ein — ohne Anmeldung, ohne Geschenk-\n')
    add('          oder Kauf-Oberfläche. <a href="/viewer">Hier direkt ausprobieren.</a></td></tr>\n')
    add('</table>\n\n')

    -- Setup section
    add('<h2>Einrichten</h2>\n')
    add('<ol class="steps">\n')
    
    -- Step 1
    add('  <li>\n')
    add('    <b>Repository holen</b>\n')
    add('    <p>Branch <code>Telegram-Monitor</code> auschecken.</p>\n')
    add('<pre><code>git clone -b Telegram-Monitor https://github.com/KikiKari/Projects.git\n')
    add('cd Projects</code></pre>\n')
    add('  </li>\n')
    
    -- Step 2
    add('  <li>\n')
    add('    <b>Dauerhaft starten</b>\n')
    add('    <p>Bindet an <code>127.0.0.1:8765</code>, der Verlauf liegt im Volume\n')
    add('       <code>monitor-data</code> und überlebt jedes Neubauen. Unter Windows\n')
    add('       genügt ein Doppelklick auf <code>Telegram Monitor - Docker.cmd</code>.</p>\n')
    add('<pre><code>docker compose up -d --build</code></pre>\n')
    add('  </li>\n')
    
    -- Step 3
    add('  <li>\n')
    add('    <b>Ohne Docker</b>\n')
    add('    <p>Der Kern braucht nur die Standardbibliothek — nichts zu installieren.</p>\n')
    add('<pre><code>python server.py --poll-interval 120</code></pre>\n')
    add('  </li>\n')
    
    -- Step 4
    add('  <li>\n')
    add('    <b>Als App einrichten</b>\n')
    add('    <p>In der geöffneten Oberfläche auf <b>Als App installieren</b> klicken.\n')
    add('       Danach liegt der Monitor als eigenes Programm im Startmenü.</p>\n')
    add('  </li>\n')
    
    -- Step 5
    add('  <li>\n')
    add('    <b>Aufs Telefon bringen</b>\n')
    add('    <p>Über das eigene VPN freigeben, dann die <code>https</code>-Adresse auf\n')
    add('       dem Telefon öffnen und dort installieren. Eine <code>.apk</code> gibt es\n')
    add('       nicht und wird auch nicht gebraucht.</p>\n')
    add('<pre><code>tailscale serve --bg 8765</code></pre>\n')
    add('  </li>\n')
    add('</ol>\n\n')

    -- What doesn't run here section
    add('<h2>Was hier nicht läuft</h2>\n')
    add('<div class="note">\n')
    add('  <b>Diese Seite ist nur die Visitenkarte.</b>\n')
    add('  Der Monitor selbst läuft <i>nicht</i> im Web. Sein Kern ist ein\n')
    add('  Hintergrundprozess, der dauerhaft abfragt und Zustand auf die Platte\n')
    add('  schreibt — beides gibt es in einer serverlosen Umgebung nicht. Ausgeliefert\n')
    add('  werden hier nur diese Seite und der Viewer, der ohnehin ohne Server\n')
    add('  auskommt. Beobachtet wird auf deinem Rechner.\n')
    add('</div>\n\n')

    -- Limitations section
    add('<h2>Grenzen</h2>\n')
    add('<p>Gelesen wird ausschließlich, was öffentlich abrufbar ist. Anmeldeschranken\n')
    add('   und Zugriffssperren werden nicht umgangen — wo es offizielle Einbettungen\n')
    add('   gibt, werden die genommen. Private Telegram-Konten liefern nur Name und Bio;\n')
    add('   das ist eine Einschränkung von Telegram, kein Fehler.</p>\n')
    add('<p>Der Turnus bleibt höflich: ein bis fünf Minuten. Sekundentakt bringt selten\n')
    add('   mehr Information und handelt eine Sperre ein.</p>\n\n')

    -- Footer
    add('<footer>\n')
    add('  Läuft lokal, gehört dir. Das wiederverwendbare Muster dahinter steckt im Skill\n')
    add('  <code>lokaler-companion</code>.\n')
    add('</footer>\n\n')

    -- Close tags
    add('</div>\n')
    add('</body>\n')
    add('</html>\n')

    return table.concat(html)
end

-- Main execution
local filename = arg[1] or "index.html"
local file = io.open(filename, "w")
if not file then
    print("Fehler: Kann Datei " .. filename .. " nicht schreiben")
    os.exit(1)
end

file:write(generate_html())
file:close()

print("HTML erfolgreich generiert und gespeichert in " .. filename)
