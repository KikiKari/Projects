#!/usr/bin/env tclsh
# index.html — portiert nach tcl
# Quelle: html, Projects@MCP-Server-Monitor:public/index.html
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

# Portierte Version von index.html nach Tcl 8.6
# Erzeugt das HTML-Dokument dynamisch und schreibt es in eine Datei

proc write_html {filename} {
    set fp [open $filename w]
    
    puts $fp {<!DOCTYPE html>}
    puts $fp {<html lang="de">}
    puts $fp {<head>}
    puts $fp {<meta charset="utf-8">}
    puts $fp {<meta name="viewport" content="width=device-width, initial-scale=1">}
    puts $fp {<title>MCP-Server-Monitor — Zustand feststellen statt raten</title>}
    puts $fp {<meta name="description" content="Fremde, offizielle MCP-Server finden, ihren Zustand feststellen und einrichten lassen. Fuenf Zustaende, ein naechster Schritt pro Zustand.">}
    puts $fp {<meta name="theme-color" content="#6d5bd0">}
    puts $fp {<meta property="og:title" content="MCP-Server-Monitor">}
    puts $fp {<meta property="og:description" content="Warum fehlen die Tools? Fuenf Zustaende, ein naechster Schritt pro Zustand.">}
    puts $fp {<meta property="og:type" content="website">}
    puts $fp {<style>}
    puts $fp {
  :root{
    --bg:#fff; --soft:#f6f7f9; --line:#e3e6ea; --text:#16191d; --muted:#5f6773;
    --ac:#6d5bd0; --ac-soft:#efecfb;
    --ok:#15803d; --ok-soft:#e7f6ec; --warn:#b45309; --warn-soft:#fdf3e3;
    color-scheme: light;
  }
  @media (prefers-color-scheme: dark){
    :root{ --bg:#0f1115; --soft:#171a21; --line:#262b36; --text:#f2f4f8; --muted:#9aa3b2;
           --ac-soft:#1e1a33; --ok-soft:#12261a; --warn-soft:#2c2110; color-scheme: dark; }
  }
  *{box-sizing:border-box}
  body{margin:0;background:var(--bg);color:var(--text);
       font:16px/1.6 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif}
  .wrap{max-width:840px;margin:0 auto;padding:0 20px 72px}
  header{padding:64px 0 36px;border-bottom:1px solid var(--line)}
  h1{font-size:34px;line-height:1.2;margin:0 0 12px;letter-spacing:-.02em}
  .lede{font-size:18px;color:var(--muted);margin:0 0 20px;max-width:62ch}
  h2{font-size:13px;margin:48px 0 14px;text-transform:uppercase;letter-spacing:.06em;
     color:var(--muted);font-weight:650}
  h3{font-size:17px;margin:24px 0 6px}
  p{margin:0 0 14px;max-width:70ch}
  .badges{display:flex;gap:7px;flex-wrap:wrap;margin-bottom:20px}
  .badge{font-size:12px;font-weight:650;padding:4px 11px;border-radius:99px;
         background:var(--soft);color:var(--muted);border:1px solid var(--line)}
  .badge.on{background:var(--ok-soft);color:var(--ok);border-color:transparent}
  table{border-collapse:collapse;width:100%;font-size:14.5px;margin:0 0 14px}
  th,td{text-align:left;padding:9px 10px;border-bottom:1px solid var(--line);vertical-align:top}
  th{font-size:12px;text-transform:uppercase;letter-spacing:.04em;color:var(--muted)}
  code{background:var(--soft);padding:2px 7px;border-radius:5px;font-size:13.5px;
       font-family:ui-monospace,SFMono-Regular,Menlo,monospace;word-break:break-word}
  pre{background:var(--soft);border:1px solid var(--line);border-radius:10px;
      padding:13px 15px;overflow-x:auto;margin:0 0 14px}
  pre code{background:none;padding:0}
  .card{border:1px solid var(--line);border-radius:12px;padding:18px 20px;background:var(--bg)}
  .note{background:var(--warn-soft);border:1px solid transparent;border-radius:10px;
        padding:14px 16px;margin:0 0 16px;font-size:14.5px}
  .note b{color:var(--warn)}
  fieldset{border:1px solid var(--line);border-radius:10px;padding:14px 16px;margin:0 0 14px}
  legend{font-size:12px;text-transform:uppercase;letter-spacing:.05em;color:var(--muted);padding:0 6px}
  label.q{display:flex;gap:10px;align-items:flex-start;padding:7px 0;font-size:15px;cursor:pointer}
  label.q input{margin-top:4px;flex:none}
  label.q span small{display:block;color:var(--muted);font-size:13px}
  #ergebnis{margin-top:6px}
  .verdict{border:1px solid var(--line);border-left:4px solid var(--ac);
           border-radius:10px;padding:16px 18px;background:var(--soft)}
  .verdict h3{margin:0 0 6px;font-size:18px}
  .verdict .step{font-weight:650;margin:10px 0 0}
  .verdict .w{margin-top:12px;padding:11px 13px;background:var(--warn-soft);
              border-radius:8px;font-size:14px}
  .probe{display:flex;gap:8px;flex-wrap:wrap;margin-bottom:12px}
  .probe input{flex:1 1 240px;padding:10px 12px;border:1px solid var(--line);
               border-radius:9px;background:var(--bg);color:var(--text);font-size:15px}
  .btn{font-weight:650;font-size:15px;padding:10px 18px;border-radius:9px;
       border:1px solid var(--ac);background:var(--ac);color:#fff;cursor:pointer}
  .btn.ghost{background:var(--bg);color:var(--text);border-color:var(--line)}
  footer{margin-top:56px;padding-top:22px;border-top:1px solid var(--line);
         color:var(--muted);font-size:14px}
  a{color:var(--ac)}
}
    puts $fp {</style>}
    puts $fp {</head>}
    puts $fp {<body>}
    puts $fp {<div class="wrap">}

    puts $fp {}
    puts $fp {<header>}
    puts $fp {  <div class="badges">}
    puts $fp {    <span class="badge on">Fuenf Zustaende</span>}
    puts $fp {    <span class="badge">Discovery</span>}
    puts $fp {    <span class="badge">MSIX-Pfadfalle</span>}
    puts $fp {    <span class="badge" id="modus">statisch</span>}
    puts $fp {  </div>}
    puts $fp {  <h1>MCP-Server-Monitor</h1>}
    puts $fp {  <p class="lede">Fast jede Frage nach einem MCP-Server ist in Wahrheit eine}
    puts $fp {  Zustandsfrage. Wer den Zustand feststellt, hat die Antwort meist schon.</p>}
    puts $fp {  <p class="lede" style="font-size:16px">Dieses Werkzeug traegt <b>keine</b> Server}
    puts $fp {  ein und meldet niemanden an. Es diagnostiziert, sucht und bereitet den Klickweg}
    puts $fp {  exakt vor. Den Klick macht der Nutzer — das ist geprüfte Grenze, keine Bequemlichkeit.</p>}
    puts $fp {</header>}

    puts $fp {}
    puts $fp {<h2>Zustand bestimmen</h2>}
    puts $fp {<div class="card">}
    puts $fp {  <fieldset>}
    puts $fp {    <legend>Was siehst du?</legend>}
    puts $fp {    <label class="q"><input type="checkbox" id="q_tools"><span>Es gibt Tools mit dem Namensmuster des Servers}
    puts $fp {      <small>Das verlaesslichste Signal — Tool-Listen sind scope-gefiltert. Was da ist, ist nutzbar.</small></span></label>}
    puts $fp {    <label class="q"><input type="checkbox" id="q_haekchen"><span>Der Konnektor steht in der Liste, mit Haekchen}
    puts $fp {      <small>Einstellungen → Anpassen → Konnektoren. Ferne Server haben Typ „Web".</small></span></label>}
    puts $fp {    <label class="q"><input type="checkbox" id="q_auth"><span>Es kommt die Meldung „benoetigt Authentifizierung"</span></label>}
    puts $fp {    <label class="q"><input type="checkbox" id="q_plugin"><span>Derselbe Name laeuft auch als <code>plugin:…</code>}
    puts $fp {      <small>Dann sind es zwei verschiedene Server mit getrennter Anmeldung.</small></span></label>}
    puts $fp {    <label class="q"><input type="checkbox" id="q_angemeldet"><span>Es wurde fuer diesen Dienst schon einmal etwas angemeldet</span></label>}
    puts $fp {  </fieldset>}
    puts $fp {  <div id="ergebnis"></div>}
    puts $fp {</div>}

    puts $fp {}
    puts $fp {<h2>Die fuenf Zustaende</h2>}
    puts $fp {<table>}
    puts $fp {  <tr><th>Zustand</th><th>Woran erkennbar</th><th>Naechster Schritt</th></tr>}
    puts $fp {  <tr><td><b>1 — Offen</b></td><td>Tools vorhanden, nie etwas angemeldet</td><td>Direkt benutzen</td></tr>}
    puts $fp {  <tr><td><b>2 — Verbunden, mit Tools</b></td><td>Konnektor mit Haekchen, Tools vorhanden</td><td>Direkt benutzen</td></tr>}
    puts $fp {  <tr><td><b>3 — Verbunden, ohne Tools</b></td><td>Konnektor mit Haekchen, aber keine Tools</td><td>Liefert er ueberhaupt Tools? Scope erteilt?</td></tr>}
    puts $fp {  <tr><td><b>4 — Installiert, unangemeldet</b></td><td>gelistet, Tools fehlen, „benoetigt Authentifizierung"</td><td>Anmelden — braucht eine interaktive Sitzung</td></tr>}
    puts $fp {  <tr><td><b>5 — Nicht vorhanden</b></td><td>nichts</td><td>Suchen, dann eintragen lassen</td></tr>}
    puts $fp {</table>}
    puts $fp {<p>Zustand 3 ist der, der als Fehler missverstanden wird. Ein Konnektor kann verbunden}
    puts $fp {sein und trotzdem keine Tools mitbringen, weil er gar keine liefert. Die GitHub-Integration}
    puts $fp {ist so ein Fall: Sie oeffnet Repository-Zugriff, eine Tool-Sammlung ist sie nicht.</p>}

    puts $fp {}
    puts $fp {<h2>Discovery</h2>}
    puts $fp {<div class="note" id="cors-hinweis">}
    puts $fp {  <b>Warum hier kein Knopf steht.</b> Diese Seite ruft keine fremden Endpunkte ab.}
    puts $fp {  Ein <code>fetch</code> aus dem Browser auf <code>mcp.DOMAIN</code> scheitert an CORS —}
    puts $fp {  eine Seite, die es trotzdem versucht, bleibt leer und sieht dabei kaputt aus.}
    puts $fp {  Die echten Proben macht der lokale Companion. Start: <code>python cli.py serve</code>,}
    puts $fp {  dann diese Seite unter <code>http://127.0.0.1:8787</code> oeffnen — der Knopf erscheint dort von selbst.}
    puts $fp {</div>}
    puts $fp {<div id="probe-ui" hidden>}
    puts $fp {  <div class="probe">}
    puts $fp {    <input id="dom" placeholder="domain, z. B. linear.app" autocomplete="off">}
    puts $fp {    <button class="btn" id="go">Pruefen</button>}
    puts $fp {  </div>}
    puts $fp {  <div id="probe-out"></div>}
    puts $fp {</div>}
    puts $fp {<p>Geprueft wird in dieser Reihenfolge:</p>}
    puts $fp {<table>}
    puts $fp {  <tr><th>#</th><th>Pfad</th><th>Bedeutung</th></tr>}
    puts $fp {  <tr><td>1</td><td><code>https://mcp.DOMAIN/</code></td><td>Streamable-HTTP-Endpunkt</td></tr>}
    puts $fp {  <tr><td>2</td><td><code>https://mcp.DOMAIN/mcp</code></td><td>haeufige Pfadvariante</td></tr>}
    puts $fp {  <tr><td>3</td><td><code>https://docs.DOMAIN/mcp</code></td><td>dort steht sie bei den meisten Anbietern</td></tr>}
    puts $fp {  <tr><td>4</td><td><code>/.well-known/oauth-protected-resource</code></td><td>existiert sie, gibt es einen OAuth-faehigen Server</td></tr>}
    puts $fp {  <tr><td>5</td><td><code>/.well-known/oauth-authorization-server</code></td><td>dito, mit Revocation-Endpunkt</td></tr>}
    puts $fp {</table>}
    puts $fp {<p><b>Eine leere Antwort auf ein nacktes GET beweist nichts.</b> Streamable-HTTP-Endpunkte}
    puts $fp {antworten darauf oft mit gar nichts, und 400/401/405 sind regulaere Ablehnungen, keine}
    puts $fp {Negativbefunde. Erst wenn auch die Discovery-Pfade fehlen, ist von Abwesenheit auszugehen.</p>}

    puts $fp {}
    puts $fp {<h2>Eintragen — der reale Weg</h2>}
    puts $fp {<p><b>Ferne Server gehoeren unter Konnektoren, nicht unter Erweiterungen.</b>}
    puts $fp {<i>Erweiterungen</i> liegt im Abschnitt „Desktop-App" und meint lokale Erweiterungen.}
    puts $fp {<i>Konnektoren</i> liegt unter „Anpassen" und ist der richtige Ort.</p>}
    puts $fp {<h3>Weg 1 — Claude-App</h3>}
    puts $fp {<p>Einstellungen → Anpassen → Konnektoren → „Hinzufuegen" oben rechts → URL eintragen.}
    puts $fp {Danach fuehrt die Anmeldung durch den Browser.</p>}
    puts $fp {<h3>Weg 2 — Claude Code</h3>}
    puts $fp {<pre><code>claude mcp add --transport http NAME https://mcp.DOMAIN/</code></pre>}
    puts $fp {<p>Danach <code>/mcp</code> aufrufen und im Browser anmelden.</p>}
    puts $fp {<h3>Weg 3 — Konfigurationsdatei</h3>}
    puts $fp {<table>}
    puts $fp {  <tr><th>Installationsart</th><th>Pfad</th></tr>}
    puts $fp {  <tr><td>Standard-Installer</td><td><code>%APPDATA%\Claude\claude_desktop_config.json</code></td></tr>}
    puts $fp {  <tr><td>MSIX (Store, WinGet, Enterprise)</td><td><code>%LOCALAPPDATA%\Packages\Claude_pzs8sxrjxfjjc\LocalCache\Roaming\Claude\claude_desktop_config.json</code></td></tr>}
    puts $fp {</table>}
    puts $fp {<div class="note"><b>Die Falle.</b> Bei MSIX oeffnet „Edit Config" im Entwickler-Menue die}
    puts $fp {<b>erste</b> Datei, gelesen wird die <b>zweite</b>. Wer dort eintraegt, wartet vergeblich.}
    puts $fp {Und die App liest die Datei nur beim Start — nach dem Aendern vollstaendig beenden und neu oeffnen.</div>}
    puts $fp {<p>Welche Datei bei dir wirkt, sagt <code>python cli.py config</code>.</p>}

    puts $fp {}
    puts $fp {<h2>Fehlerbilder</h2>}
    puts $fp {<table>}
    puts $fp {  <tr><th>Bild</th><th>Wahrscheinliche Ursache</th></tr>}
    puts $fp {  <tr><td>Verbunden, aber keine Tools</td><td>Konnektor liefert keine Tools, oder Scope fehlt</td></tr>}
    puts $fp {  <tr><td>Name doppelt: verbunden <b>und</b> „benoetigt Auth"</td><td>Konnektor und Plugin-Server verwechselt</td></tr>}
    puts $fp {  <tr><td><code>invalid_scope</code></td><td>Mehr angefragt, als der Client registriert hat</td></tr>}
    puts $fp {  <tr><td>Haengt dauerhaft in „connecting"</td><td>Endpunkt falsch, Netz blockiert, oder Server unten</td></tr>}
    puts $fp {  <tr><td>401 nach Wochen problemlosen Betriebs</td><td>Refresh-Token abgelaufen oder widerrufen — neu anmelden</td></tr>}
    puts $fp {  <tr><td>Manuell eingetragener Server bleibt stumm</td><td>MSIX-Pfadfalle, oder App nicht neu gestartet</td></tr>}
    puts $fp {  <tr><td>Tools nach Update verschwunden</td><td>Server neu verbunden, Scopes neu erteilen</td></tr>}
    puts $fp {</table>}

    puts $fp {}
    puts $fp {<h2>Betriebsgrenzen</h2>}
    puts $fp {<p>Ferne Server sind bequem, aber nicht kostenlos: kein Binaer-Upload (die meisten nehmen}
    puts $fp {nur URLs), ein Roundtrip pro Aufruf, und jeder Aufruf verbraucht echtes Kontingent beim}
    puts $fp {Anbieter — genau wie ein direkter API-Aufruf. Daraus die Regel: <b>Fuer Einzelfragen der}
    puts $fp {MCP-Server. Ab mehreren Aufrufen, bei Dateien oder in Skripten die Direkt-API.</b></p>}

    puts $fp {}
    puts $fp {<footer>}
    puts $fp {  MCP-Server-Monitor — Branch <code>MCP-Server-Monitor</code> in}
    puts $fp {  <a href="https://github.com/KikiKari/Projects/tree/MCP-Server-Monitor">KikiKari/Projects</a>.}
    puts $fp {  Statisch ausgeliefert aus <code>public/</code>, kein Build, keine Zaehlpixel.}
    puts $fp {</footer>}

    puts $fp {}
    puts $fp {</div>}
    puts $fp {<script>}
    puts $fp {(function(){}
    puts $fp {  "use strict";}
    puts $fp {  var Z = \{}
    puts $fp {    offen:      ["1 — Offen","Direkt benutzen."],}
    puts $fp {    mitTools:   ["2 — Verbunden, mit Tools","Direkt benutzen."],}
    puts $fp {    ohneTools:  ["3 — Verbunden, ohne Tools","Pruefen, ob der Konnektor ueberhaupt Tools liefert; danach die erteilten Scopes. Die Tool-Liste ist scope-gefiltert — ein fehlendes Tool heisst fast immer fehlender Scope, nicht fehlende Funktion."],}
    puts $fp {    unauth:     ["4 — Installiert, unangemeldet","Anmelden. Das braucht eine interaktive Sitzung — in einer nicht-interaktiven Sitzung startet kein OAuth-Flow."],}
    puts $fp {    absent:     ["5 — Nicht vorhanden","Discovery laufen lassen (Connector-Registry, dann die fuenf Pfade unten), danach unter Anpassen → Konnektoren eintragen."]}
    puts $fp {  \};}
    puts $fp {  var W_PLUGIN = "Der Name laeuft auch als <code>plugin:…</code> — das ist ein zweiter, separat anzumeldender Server. Konnektoren haengen am Konto, Plugins bringen eigene MCP-Server mit. Wer das nicht trennt, meldet sich an und sucht den Fehler an der falschen Stelle.";}
    puts $fp {  var W_Z3 = "Zustand 3 wird oft als Fehler missverstanden. Lies die Beschreibung des Konnektors im Dialog, bevor du einen Fehler vermutest.";}}
    puts $fp {}
    puts $fp {  var ids = ["q_tools","q_haekchen","q_auth","q_plugin","q_angemeldet"];}
    puts $fp {  var el = \{\}; ids.forEach(function(i)\{ el[i] = document.getElementById(i); \});}
    puts $fp {  var out = document.getElementById("ergebnis");}
    puts $fp {}
    puts $fp {  function bestimme()\{}
    puts $fp {    var t=el.q_tools.checked, h=el.q_haekchen.checked, a=el.q_auth.checked,}
    puts $fp {        pl=el.q_plugin.checked, an=el.q_angemeldet.checked;}
    puts $fp {    var key, warn=[];}
    puts $fp {    if (pl) warn.push(W_PLUGIN);}
    puts $fp {    if (t)        key = (h||an) ? "mitTools" : "offen";}
    puts $fp {    else if (a)   key = "unauth";}
    puts $fp {    else if (h)   \{ key = "ohneTools"; warn.push(W_Z3); \}}
    puts $fp {    else          key = "absent";}
    puts $fp {    var z = Z[key];}
    puts $fp {    out.innerHTML = '<div class="verdict"><h3>' + z[0] + '</h3>' +}
    puts $fp {      '<p class="step">Naechster Schritt</p><p>' + z[1] + '</p>' +}
    puts $fp {      warn.map(function(w)\{ return '<div class="w">' + w + '</div>'; \}).join("") +}
    puts $fp {      '</div>';}
    puts $fp {  \}}
    puts $fp {  ids.forEach(function(i)\{ el[i].addEventListener("change", bestimme); \});}
    puts $fp {  bestimme();}
    puts $fp {}
    puts $fp {  // Der Live-Probe-Knopf erscheint nur beim lokalen Companion. Im Browser auf}
    puts $fp {  // einer fremden Herkunft scheitert der Abruf an CORS — dann lieber gar nicht}
    puts $fp {  // anbieten, als leer laufen lassen.}
    puts $fp {  var lokal = ["127.0.0.1","localhost","[::1]"].indexOf(location.hostname) !== -1;}
    puts $fp {  if (lokal)\{}
    puts $fp {    document.getElementById("modus").textContent = "lokal — Proben aktiv";}
    puts $fp {    document.getElementById("modus").className = "badge on";}
    puts $fp {    document.getElementById("probe-ui").hidden = false;}
    puts $fp {    document.getElementById("cors-hinweis").hidden = true;}
    puts $fp {    var po = document.getElementById("probe-out");}
    puts $fp {    document.getElementById("go").addEventListener("click", function()\{}
    puts $fp {      var d = document.getElementById("dom").value.trim();}
    puts $fp {      if (!d) return;}
    puts $fp {      po.innerHTML = "<p>pruefe " + d + " …</p>";}
    puts $fp {      fetch("/api/probe?domain=" + encodeURIComponent(d))}
    puts $fp {        .then(function(r)\{ return r.json(); \})}
    puts $fp {        .then(function(r)\{}
    puts $fp {          var rows = r.proben.map(function(p)\{}
    puts $fp {            return "<tr><td><code>" + (p.status || "ERR") + "</code></td><td>" + p.art +}
    puts $fp {                   "</td><td style='word-break:break-all'>" + p.url + "</td></tr>";}
    puts $fp {          \}).join("");}}
    puts $fp {          po.innerHTML = '<div class="verdict"><h3>' + r.urteil + "</h3><p>" + r.deutung +}
    puts $fp {                         "</p><table><tr><th>HTTP</th><th>Art</th><th>URL</th></tr>" +}
    puts $fp {                         rows + "</table></div>";}
    puts $fp {        \})}
    puts $fp {        .catch(function(e)\{ po.innerHTML = "<p>Fehlgeschlagen: " + e + "</p>"; \});}
    puts $fp {    \});}
    puts $fp {    document.getElementById("dom").addEventListener("keydown", function(e)\{}
    puts $fp {      if (e.key === "Enter") document.getElementById("go").click();}
    puts $fp {    \});}
    puts $fp {  \}}
    puts $fp {\})();}
    puts $fp {</script>}
    puts $fp {</body>}
    puts $fp {</html>}
    
    close $fp
}

# Hauptprogramm
if {$argc != 1} {
    puts stderr "Verwendung: $argv0 <ausgabedatei>"
    exit 1
}

set output_file [lindex $argv 0]
write_html $output_file
puts "HTML-Datei erfolgreich erstellt: $output_file"
