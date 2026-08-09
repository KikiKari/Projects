#!/usr/bin/env node
// index.html — portiert nach javascript
// Quelle: html, Projects@MCP-Server-Monitor:public/index.html
// Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

const fs = require('fs');

function generateHTML() {
  const html = `<!DOCTYPE html>
<html lang="de">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>MCP-Server-Monitor — Zustand feststellen statt raten</title>
<meta name="description" content="Fremde, offizielle MCP-Server finden, ihren Zustand feststellen und einrichten lassen. Fuenf Zustaende, ein naechster Schritt pro Zustand.">
<meta name="theme-color" content="#6d5bd0">
<meta property="og:title" content="MCP-Server-Monitor">
<meta property="og:description" content="Warum fehlen die Tools? Fuenf Zustaende, ein naechster Schritt pro Zustand.">
<meta property="og:type" content="website">
<style>
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
</style>
</head>
<body>
<div class="wrap">

<header>
  <div class="badges">
    <span class="badge on">Fuenf Zustaende</span>
    <span class="badge">Discovery</span>
    <span class="badge">MSIX-Pfadfalle</span>
    <span class="badge" id="modus">statisch</span>
  </div>
  <h1>MCP-Server-Monitor</h1>
  <p class="lede">Fast jede Frage nach einem MCP-Server ist in Wahrheit eine
  Zustandsfrage. Wer den Zustand feststellt, hat die Antwort meist schon.</p>
  <p class="lede" style="font-size:16px">Dieses Werkzeug traegt <b>keine</b> Server
  ein und meldet niemanden an. Es diagnostiziert, sucht und bereitet den Klickweg
  exakt vor. Den Klick macht der Nutzer — das ist geprüfte Grenze, keine Bequemlichkeit.</p>
</header>

<h2>Zustand bestimmen</h2>
<div class="card">
  <fieldset>
    <legend>Was siehst du?</legend>
    <label class="q"><input type="checkbox" id="q_tools"><span>Es gibt Tools mit dem Namensmuster des Servers
      <small>Das verlaesslichste Signal — Tool-Listen sind scope-gefiltert. Was da ist, ist nutzbar.</small></span></label>
    <label class="q"><input type="checkbox" id="q_haekchen"><span>Der Konnektor steht in der Liste, mit Haekchen
      <small>Einstellungen → Anpassen → Konnektoren. Ferne Server haben Typ „Web".</small></span></label>
    <label class="q"><input type="checkbox" id="q_auth"><span>Es kommt die Meldung „benoetigt Authentifizierung"</span></label>
    <label class="q"><input type="checkbox" id="q_plugin"><span>Derselbe Name laeuft auch als <code>plugin:…</code>
      <small>Dann sind es zwei verschiedene Server mit getrennter Anmeldung.</small></span></label>
    <label class="q"><input type="checkbox" id="q_angemeldet"><span>Es wurde fuer diesen Dienst schon einmal etwas angemeldet</span></label>
  </fieldset>
  <div id="ergebnis"></div>
</div>

<h2>Die fuenf Zustaende</h2>
<table>
  <tr><th>Zustand</th><th>Woran erkennbar</th><th>Naechster Schritt</th></tr>
  <tr><td><b>1 — Offen</b></td><td>Tools vorhanden, nie etwas angemeldet</td><td>Direkt benutzen</td></tr>
  <tr><td><b>2 — Verbunden, mit Tools</b></td><td>Konnektor mit Haekchen, Tools vorhanden</td><td>Direkt benutzen</td></tr>
  <tr><td><b>3 — Verbunden, ohne Tools</b></td><td>Konnektor mit Haekchen, aber keine Tools</td><td>Liefert er ueberhaupt Tools? Scope erteilt?</td></tr>
  <tr><td><b>4 — Installiert, unangemeldet</b></td><td>gelistet, Tools fehlen, „benoetigt Authentifizierung"</td><td>Anmelden — braucht eine interaktive Sitzung</td></tr>
  <tr><td><b>5 — Nicht vorhanden</b></td><td>nichts</td><td>Suchen, dann eintragen lassen</td></tr>
</table>
<p>Zustand 3 ist der, der als Fehler missverstanden wird. Ein Konnektor kann verbunden
sein und trotzdem keine Tools mitbringen, weil er gar keine liefert. Die GitHub-Integration
ist so ein Fall: Sie oeffnet Repository-Zugriff, eine Tool-Sammlung ist sie nicht.</p>

<h2>Discovery</h2>
<div class="note" id="cors-hinweis">
  <b>Warum hier kein Knopf steht.</b> Diese Seite ruft keine fremden Endpunkte ab.
  Ein <code>fetch</code> aus dem Browser auf <code>mcp.DOMAIN</code> scheitert an CORS —
  eine Seite, die es trotzdem versucht, bleibt leer und sieht dabei kaputt aus.
  Die echten Proben macht der lokale Companion. Start: <code>python cli.py serve</code>,
  dann diese Seite unter <code>http://127.0.0.1:8787</code> oeffnen — der Knopf erscheint dort von selbst.
</div>
<div id="probe-ui" hidden>
  <div class="probe">
    <input id="dom" placeholder="domain, z. B. linear.app" autocomplete="off">
    <button class="btn" id="go">Pruefen</button>
  </div>
  <div id="probe-out"></div>
</div>
<p>Geprueft wird in dieser Reihenfolge:</p>
<table>
  <tr><th>#</th><th>Pfad</th><th>Bedeutung</th></tr>
  <tr><td>1</td><td><code>https://mcp.DOMAIN/</code></td><td>Streamable-HTTP-Endpunkt</td></tr>
  <tr><td>2</td><td><code>https://mcp.DOMAIN/mcp</code></td><td>haeufige Pfadvariante</td></tr>
  <tr><td>3</td><td><code>https://docs.DOMAIN/mcp</code></td><td>dort steht sie bei den meisten Anbietern</td></tr>
  <tr><td>4</td><td><code>/.well-known/oauth-protected-resource</code></td><td>existiert sie, gibt es einen OAuth-faehigen Server</td></tr>
  <tr><td>5</td><td><code>/.well-known/oauth-authorization-server</code></td><td>dito, mit Revocation-Endpunkt</td></tr>
</table>
<p><b>Eine leere Antwort auf ein nacktes GET beweist nichts.</b> Streamable-HTTP-Endpunkte
antworten darauf oft mit gar nichts, und 400/401/405 sind regulaere Ablehnungen, keine
Negativbefunde. Erst wenn auch die Discovery-Pfade fehlen, ist von Abwesenheit auszugehen.</p>

<h2>Eintragen — der reale Weg</h2>
<p><b>Ferne Server gehoeren unter Konnektoren, nicht unter Erweiterungen.</b>
<i>Erweiterungen</i> liegt im Abschnitt „Desktop-App" und meint lokale Erweiterungen.
<i>Konnektoren</i> liegt unter „Anpassen" und ist der richtige Ort.</p>
<h3>Weg 1 — Claude-App</h3>
<p>Einstellungen → Anpassen → Konnektoren → „Hinzufuegen" oben rechts → URL eintragen.
Danach fuehrt die Anmeldung durch den Browser.</p>
<h3>Weg 2 — Claude Code</h3>
<pre><code>claude mcp add --transport http NAME https://mcp.DOMAIN/</code></pre>
<p>Danach <code>/mcp</code> aufrufen und im Browser anmelden.</p>
<h3>Weg 3 — Konfigurationsdatei</h3>
<table>
  <tr><th>Installationsart</th><th>Pfad</th></tr>
  <tr><td>Standard-Installer</td><td><code>%APPDATA%\\Claude\\claude_desktop_config.json</code></td></tr>
  <tr><td>MSIX (Store, WinGet, Enterprise)</td><td><code>%LOCALAPPDATA%\\Packages\\Claude_pzs8sxrjxfjjc\\LocalCache\\Roaming\\Claude\\claude_desktop_config.json</code></td></tr>
</table>
<div class="note"><b>Die Falle.</b> Bei MSIX oeffnet „Edit Config" im Entwickler-Menue die
<b>erste</b> Datei, gelesen wird die <b>zweite</b>. Wer dort eintraegt, wartet vergeblich.
Und die App liest die Datei nur beim Start — nach dem Aendern vollstaendig beenden und neu oeffnen.</div>
<p>Welche Datei bei dir wirkt, sagt <code>python cli.py config</code>.</p>

<h2>Fehlerbilder</h2>
<table>
  <tr><th>Bild</th><th>Wahrscheinliche Ursache</th></tr>
  <tr><td>Verbunden, aber keine Tools</td><td>Konnektor liefert keine Tools, oder Scope fehlt</td></tr>
  <tr><td>Name doppelt: verbunden <b>und</b> „benoetigt Auth"</td><td>Konnektor und Plugin-Server verwechselt</td></tr>
  <tr><td><code>invalid_scope</code></td><td>Mehr angefragt, als der Client registriert hat</td></tr>
  <tr><td>Haengt dauerhaft in „connecting"</td><td>Endpunkt falsch, Netz blockiert, oder Server unten</td></tr>
  <tr><td>401 nach Wochen problemlosen Betriebs</td><td>Refresh-Token abgelaufen oder widerrufen — neu anmelden</td></tr>
  <tr><td>Manuell eingetragener Server bleibt stumm</td><td>MSIX-Pfadfalle, oder App nicht neu gestartet</td></tr>
  <tr><td>Tools nach Update verschwunden</td><td>Server neu verbunden, Scopes neu erteilen</td></tr>
</table>

<h2>Betriebsgrenzen</h2>
<p>Ferne Server sind bequem, aber nicht kostenlos: kein Binaer-Upload (die meisten nehmen
nur URLs), ein Roundtrip pro Aufruf, und jeder Aufruf verbraucht echtes Kontingent beim
Anbieter — genau wie ein direkter API-Aufruf. Daraus die Regel: <b>Fuer Einzelfragen der
MCP-Server. Ab mehreren Aufrufen, bei Dateien oder in Skripten die Direkt-API.</b></p>

<footer>
  MCP-Server-Monitor — Branch <code>MCP-Server-Monitor</code> in
  <a href="https://github.com/KikiKari/Projects/tree/MCP-Server-Monitor">KikiKari/Projects</a>.
  Statisch ausgeliefert aus <code>public/</code>, kein Build, keine Zaehlpixel.
</footer>

</div>
<script>
(function(){
  "use strict";
  var Z = {
    offen:      ["1 — Offen","Direkt benutzen."],
    mitTools:   ["2 — Verbunden, mit Tools","Direkt benutzen."],
    ohneTools:  ["3 — Verbunden, ohne Tools","Pruefen, ob der Konnektor ueberhaupt Tools liefert; danach die erteilten Scopes. Die Tool-Liste ist scope-gefiltert — ein fehlendes Tool heisst fast immer fehlender Scope, nicht fehlende Funktion."],
    unauth:     ["4 — Installiert, unangemeldet","Anmelden. Das braucht eine interaktive Sitzung — in einer nicht-interaktiven Sitzung startet kein OAuth-Flow."],
    absent:     ["5 — Nicht vorhanden","Discovery laufen lassen (Connector-Registry, dann die fuenf Pfade unten), danach unter Anpassen → Konnektoren eintragen."]
  };
  var W_PLUGIN = "Der Name laeuft auch als <code>plugin:…</code> — das ist ein zweiter, separat anzumeldender Server. Konnektoren haengen am Konto, Plugins bringen eigene MCP-Server mit. Wer das nicht trennt, meldet sich an und sucht den Fehler an der falschen Stelle.";
  var W_Z3 = "Zustand 3 wird oft als Fehler missverstanden. Lies die Beschreibung des Konnektors im Dialog, bevor du einen Fehler vermutest.";

  var ids = ["q_tools","q_haekchen","q_auth","q_plugin","q_angemeldet"];
  var el = {}; ids.forEach(function(i){ el[i] = document.getElementById(i); });
  var out = document.getElementById("ergebnis");

  function bestimme(){
    var t=el.q_tools.checked, h=el.q_haekchen.checked, a=el.q_auth.checked,
        pl=el.q_plugin.checked, an=el.q_angemeldet.checked;
    var key, warn=[];
    if (pl) warn.push(W_PLUGIN);
    if (t)        key = (h||an) ? "mitTools" : "offen";
    else if (a)   key = "unauth";
    else if (h)   { key = "ohneTools"; warn.push(W_Z3); }
    else          key = "absent";
    var z = Z[key];
    out.innerHTML = '<div class="verdict"><h3>' + z[0] + '</h3>' +
      '<p class="step">Naechster Schritt</p><p>' + z[1] + '</p>' +
      warn.map(function(w){ return '<div class="w">' + w + '</div>'; }).join("") +
      '</div>';
  }
  ids.forEach(function(i){ el[i].addEventListener("change", bestimme); });
  bestimme();

  // Der Live-Probe-Knopf erscheint nur beim lokalen Companion. Im Browser auf
  // einer fremden Herkunft scheitert der Abruf an CORS — dann lieber gar nicht
  // anbieten, als leer laufen lassen.
  var lokal = ["127.0.0.1","localhost","[::1]"].indexOf(location.hostname) !== -1;
  if (lokal){
    document.getElementById("modus").textContent = "lokal — Proben aktiv";
    document.getElementById("modus").className = "badge on";
    document.getElementById("probe-ui").hidden = false;
    document.getElementById("cors-hinweis").hidden = true;
    var po = document.getElementById("probe-out");
    document.getElementById("go").addEventListener("click", function(){
      var d = document.getElementById("dom").value.trim();
      if (!d) return;
      po.innerHTML = "<p>pruefe " + d + " …</p>";
      fetch("/api/probe?domain=" + encodeURIComponent(d))
        .then(function(r){ return r.json(); })
        .then(function(r){
          var rows = r.proben.map(function(p){
            return "<tr><td><code>" + (p.status || "ERR") + "</code></td><td>" + p.art +
                   "</td><td style='word-break:break-all'>" + p.url + "</td></tr>";
          }).join("");
          po.innerHTML = '<div class="verdict"><h3>' + r.urteil + "</h3><p>" + r.deutung +
                         "</p><table><tr><th>HTTP</th><th>Art</th><th>URL</th></tr>" +
                         rows + "</table></div>";
        })
        .catch(function(e){ po.innerHTML = "<p>Fehlgeschlagen: " + e + "</p>"; });
    });
    document.getElementById("dom").addEventListener("keydown", function(e){
      if (e.key === "Enter") document.getElementById("go").click();
    });
  }
})();
</script>
</body>
</html>`;
  
  return html;
}

function main() {
  const outputFile = process.argv[2];
  
  if (!outputFile) {
    console.error('Usage: node script.js <output-file>');
    process.exit(1);
  }
  
  const htmlContent = generateHTML();
  
  try {
    fs.writeFileSync(outputFile, htmlContent, 'utf8');
    console.log(`HTML file generated successfully: ${outputFile}`);
  } catch (error) {
    console.error(`Error writing file: ${error.message}`);
    process.exit(1);
  }
}

main();
