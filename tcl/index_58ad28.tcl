#!/usr/bin/env tclsh
# index.html — portiert nach tcl
# Quelle: html, Projects@Telegram-Monitor:public/index.html
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

# Tcl 8.6 script to generate the index.html file
# Usage: tclsh this_script.tcl output_file.html

if {$argc != 1} {
    puts stderr "Usage: $argv0 output_file.html"
    exit 1
}

set output_file [lindex $argv 0]

# Open file for writing
if {[catch {open $output_file w} fd]} {
    puts stderr "Error: Could not open $output_file for writing: $fd"
    exit 1
}

# Write the complete HTML document
puts $fd {<!DOCTYPE html>
<html lang="de">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Telegram Monitor — lokaler Beobachtungs-Companion</title>
<meta name="description" content="Beobachtet öffentliche Telegram-Kanäle und TikTok-Konten auf dem eigenen Rechner und meldet den Livegang. Keine Cloud, keine Anmeldung.">
<meta name="theme-color" content="#2481cc">
<meta property="og:title" content="Telegram Monitor">
<meta property="og:description" content="Lokaler Beobachtungs-Companion. Docker, PWA, Meldung beim Livegang.">
<meta property="og:type" content="website">
<style>
  :root{
    --bg:#ffffff; --soft:#f6f7f9; --line:#e3e6ea; --text:#16191d; --muted:#5f6773;
    --tg:#2481cc; --tg-soft:#e8f2fb; --tt:#fe2c55;
    --ok:#15803d; --ok-soft:#e7f6ec; --warn:#b45309; --warn-soft:#fdf3e3;
    color-scheme: light;
  }
  @media (prefers-color-scheme: dark){
    :root{ --bg:#0f1115; --soft:#171a21; --line:#262b36; --text:#f2f4f8; --muted:#9aa3b2;
           --tg-soft:#132a3d; --ok-soft:#12261a; --warn-soft:#2c2110; color-scheme: dark; }
  }
  *{box-sizing:border-box}
  body{margin:0;background:var(--bg);color:var(--text);
       font:16px/1.6 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif}
  .wrap{max-width:820px;margin:0 auto;padding:0 20px 72px}
  header{padding:64px 0 40px;border-bottom:1px solid var(--line);margin-bottom:8px}
  h1{font-size:34px;line-height:1.2;margin:0 0 12px;letter-spacing:-.02em}
  .lede{font-size:18px;color:var(--muted);margin:0 0 22px;max-width:60ch}
  h2{font-size:13px;margin:44px 0 14px;text-transform:uppercase;letter-spacing:.06em;
     color:var(--muted);font-weight:650}
  h3{font-size:17px;margin:26px 0 6px}
  p{margin:0 0 14px;max-width:68ch}
  .badges{display:flex;gap:7px;flex-wrap:wrap;margin-bottom:22px}
  .badge{font-size:12px;font-weight:650;padding:4px 11px;border-radius:99px;
         background:var(--soft);color:var(--muted);border:1px solid var(--line)}
  .badge.on{background:var(--ok-soft);color:var(--ok);border-color:transparent}
  .cta{display:flex;gap:10px;flex-wrap:wrap}
  .btn{display:inline-block;font-weight:650;font-size:15px;padding:11px 20px;
       border-radius:9px;text-decoration:none;border:1px solid var(--line);
       background:var(--bg);color:var(--text)}
  .btn.primary{background:var(--tg);border-color:var(--tg);color:#fff}
  .btn:hover{border-color:var(--tg)}
  .grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(230px,1fr));gap:14px}
  .card{border:1px solid var(--line);border-radius:12px;padding:16px 18px;background:var(--bg)}
  .card h3{margin-top:0;font-size:15.5px}
  .card p{font-size:14px;color:var(--muted);margin:0}
  ol.steps{list-style:none;counter-reset:s;padding:0;margin:0}
  ol.steps li{counter-increment:s;position:relative;padding:0 0 20px 40px;
              border-left:2px solid var(--line);margin-left:11px}
  ol.steps li:last-child{border-left-color:transparent;padding-bottom:0}
  ol.steps li::before{content:counter(s);position:absolute;left:-13px;top:0;
       width:24px;height:24px;border-radius:50%;background:var(--tg);color:#fff;
       display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:700}
  ol.steps b{display:block;margin-bottom:3px}
  ol.steps p{font-size:14.5px;color:var(--muted);margin:0 0 8px}
  code{background:var(--soft);padding:2px 7px;border-radius:5px;font-size:13.5px;
       font-family:ui-monospace,SFMono-Regular,Menlo,monospace;word-break:break-word}
  pre{background:var(--soft);border:1px solid var(--line);border-radius:10px;
      padding:13px 15px;overflow-x:auto;margin:0 0 14px}
  pre code{background:none;padding:0;font-size:13.5px;line-height:1.7}
  table{width:100%;border-collapse:collapse;font-size:14.5px;margin:0 0 16px}
  th,td{text-align:left;padding:9px 11px;border-bottom:1px solid var(--line);vertical-align:top}
  th{color:var(--muted);font-size:12px;text-transform:uppercase;letter-spacing:.04em;font-weight:650}
  .note{border-left:3px solid var(--warn);background:var(--warn-soft);
        border-radius:0 9px 9px 0;padding:13px 16px;margin:0 0 16px;font-size:14.5px}
  .note b{display:block;margin-bottom:3px}
  a{color:var(--tg)}
  footer{margin-top:52px;padding-top:22px;border-top:1px solid var(--line);
         font-size:13.5px;color:var(--muted)}
</style>
</head>
<body>
<div class="wrap">

<header>
  <h1>Telegram Monitor</h1>
  <p class="lede">Beobachtet öffentliche Telegram-Kanäle und TikTok-Konten auf
     deinem eigenen Rechner und meldet sich, wenn jemand live geht. Keine Cloud,
     kein Konto, keine App-Installation auf dem Telefon nötig.</p>
  <div class="badges">
    <span class="badge on">Standardbibliothek</span>
    <span class="badge on">Docker</span>
    <span class="badge on">installierbar als App</span>
    <span class="badge on">Browser-Erweiterung</span>
    <span class="badge">Windows · macOS · Linux</span>
  </div>
  <div class="cta">
    <a class="btn primary" href="https://github.com/KikiKari/Projects/tree/Telegram-Monitor">Quelltext auf GitHub</a>
    <a class="btn" href="/viewer">Live-Viewer öffnen</a>
  </div>
</header>

<h2>Was es tut</h2>
<div class="grid">
  <div class="card">
    <h3>Beobachten</h3>
    <p>Fragt jeden Kanal im eingestellten Turnus ab und sammelt den Verlauf auf
       der Platte — neueste Beiträge oben, anders als in Telegram selbst.</p>
  </div>
  <div class="card">
    <h3>Erkennen</h3>
    <p>Vergleicht den Zustand mit dem letzten Durchlauf. Gemeldet wird nur ein
       echter Wechsel; ein fehlgeschlagener Abruf gilt nicht als „offline".</p>
  </div>
  <div class="card">
    <h3>Melden</h3>
    <p>Drei Wege gleichzeitig: Ereignisprotokoll, Systemmeldung und Webhook.
       Fällt einer aus, steht der Wechsel trotzdem mit Zeitstempel fest.</p>
  </div>
</div>

<h2>Drei Zugänge, ein Monitor</h2>
<table>
  <tr><th>Zugang</th><th>wofür</th></tr>
  <tr><td><b>Installierte App</b></td>
      <td>Vollständige Oberfläche mit allen Reitern, eigenes Fenster ohne
          Adressleiste, Symbol im Startmenü</td></tr>
  <tr><td><b>Browser-Erweiterung</b></td>
      <td>Meldung beim Livegang, ohne dass ein Tab offen sein muss</td></tr>
  <tr><td><b>Live-Viewer</b></td>
      <td>Bettet den offiziellen Player ein — ohne Anmeldung, ohne Geschenk-
          oder Kauf-Oberfläche. <a href="/viewer">Hier direkt ausprobieren.</a></td></tr>
</table>

<h2>Einrichten</h2>
<ol class="steps">
  <li>
    <b>Repository holen</b>
    <p>Branch <code>Telegram-Monitor</code> auschecken.</p>
<pre><code>git clone -b Telegram-Monitor https://github.com/KikiKari/Projects.git
cd Projects</code></pre>
  </li>
  <li>
    <b>Dauerhaft starten</b>
    <p>Bindet an <code>127.0.0.1:8765</code>, der Verlauf liegt im Volume
       <code>monitor-data</code> und überlebt jedes Neubauen. Unter Windows
       genügt ein Doppelklick auf <code>Telegram Monitor - Docker.cmd</code>.</p>
<pre><code>docker compose up -d --build</code></pre>
  </li>
  <li>
    <b>Ohne Docker</b>
    <p>Der Kern braucht nur die Standardbibliothek — nichts zu installieren.</p>
<pre><code>python server.py --poll-interval 120</code></pre>
  </li>
  <li>
    <b>Als App einrichten</b>
    <p>In der geöffneten Oberfläche auf <b>Als App installieren</b> klicken.
       Danach liegt der Monitor als eigenes Programm im Startmenü.</p>
  </li>
  <li>
    <b>Aufs Telefon bringen</b>
    <p>Über das eigene VPN freigeben, dann die <code>https</code>-Adresse auf
       dem Telefon öffnen und dort installieren. Eine <code>.apk</code> gibt es
       nicht und wird auch nicht gebraucht.</p>
<pre><code>tailscale serve --bg 8765</code></pre>
  </li>
</ol>

<h2>Was hier nicht läuft</h2>
<div class="note">
  <b>Diese Seite ist nur die Visitenkarte.</b>
  Der Monitor selbst läuft <i>nicht</i> im Web. Sein Kern ist ein
  Hintergrundprozess, der dauerhaft abfragt und Zustand auf die Platte
  schreibt — beides gibt es in einer serverlosen Umgebung nicht. Ausgeliefert
  werden hier nur diese Seite und der Viewer, der ohnehin ohne Server
  auskommt. Beobachtet wird auf deinem Rechner.
</div>

<h2>Grenzen</h2>
<p>Gelesen wird ausschließlich, was öffentlich abrufbar ist. Anmeldeschranken
   und Zugriffssperren werden nicht umgangen — wo es offizielle Einbettungen
   gibt, werden die genommen. Private Telegram-Konten liefern nur Name und Bio;
   das ist eine Einschränkung von Telegram, kein Fehler.</p>
<p>Der Turnus bleibt höflich: ein bis fünf Minuten. Sekundentakt bringt selten
   mehr Information und handelt eine Sperre ein.</p>

<footer>
  Läuft lokal, gehört dir. Das wiederverwendbare Muster dahinter steckt im Skill
  <code>lokaler-companion</code>.
</footer>

</div>
</body>
</html>}

# Close the file
close $fd

puts "HTML file generated successfully: $output_file"
