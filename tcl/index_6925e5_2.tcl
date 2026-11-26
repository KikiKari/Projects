#!/usr/bin/env tclsh
# abstraction-provenance: {"artifact_sha256": "43c55105e8ec680f995beced6b593157bdd122cdd1a3d263b51ef257ffd5a998", "source_sha256": "6925e5ed34d3344b10c23ce3442546a31631cc8434f3b7df4bdc003d32218523", "target_language": "tcl"}
# index.html — portiert nach tcl
# Quelle: html, Projects@MCP-Server-Monitor:public/index.html
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# Tcl 8.6 script to generate the MCP-Server-Monitor HTML page
# Usage: tclsh this_script.tcl > output_file.html

proc generate_html {} {
    set html {}

    append html "<!DOCTYPE html>\n"
    append html "<html lang=\"de\">\n<head>\n"
    append html "<meta charset=\"utf-8\">\n"
    append html "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n"
    append html "<title>MCP-Server-Monitor — Zustand feststellen statt raten</title>\n"
    append html "<meta name=\"description\" content=\"Fremde, offizielle MCP-Server finden, ihren Zustand feststellen und einrichten lassen. Fuenf Zustaende, ein naechster Schritt pro Zustand.\">\n"
    append html "<meta name=\"theme-color\" content=\"#6d5bd0\">\n"
    append html "<meta property=\"og:title\" content=\"MCP-Server-Monitor\">\n"
    append html "<meta property=\"og:description\" content=\"Warum fehlen die Tools? Fuenf Zustaende, ein naechster Schritt pro Zustand.\">\n"
    append html "<meta property=\"og:type\" content=\"website\">\n"
    
    append html [generate_css]
    append html "</head>\n<body>\n<div class=\"wrap\">\n\n"
    append html [generate_header]
    append html [generate_state_determination]
    append html [generate_five_states]
    append html [generate_discovery]
    append html [generate_registration]
    append html [generate_error_images]
    append html [generate_operational_limits]
    append html [generate_footer]
    append html "\n</div>\n"
    append html [generate_javascript]
    append html "</body>\n</html>\n"

    return $html
}

proc generate_css {} {
    set css {}
    append css "<style>\n"
    append css "  :root{\n"
    append css "    --bg:#fff; --soft:#f6f7f9; --line:#e3e6ea; --text:#16191d; --muted:#5f6773;\n"
    append css "    --ac:#6d5bd0; --ac-soft:#efecfb;\n"
    append css "    --ok:#15803d; --ok-soft:#e7f6ec; --warn:#b45309; --warn-soft:#fdf3e3;\n"
    append css "    color-scheme: light;\n"
    append css "  }\n"
    append css "  @media (prefers-color-scheme: dark){\n"
    append css "    :root{ --bg:#0f1115; --soft:#171a21; --line:#262b36; --text:#f2f4f8; --muted:#9aa3b2;\n"
    append css "           --ac-soft:#1e1a33; --ok-soft:#12261a; --warn-soft:#2c2110; color-scheme: dark; }\n"
    append css "  }\n"
    append css "  *{box-sizing:border-box}\n"
    append css "  body{margin:0;background:var(--bg);color:var(--text);\n"
    append css "       font:16px/1.6 -apple-system,BlinkMacSystemFont,\"Segoe UI\",Roboto,sans-serif}\n"
    append css "  .wrap{max-width:840px;margin:0 auto;padding:0 20px 72px}\n"
    append css "  header{padding:64px 0 36px;border-bottom:1px solid var(--line)}\n"
    append css "  h1{font-size:34px;line-height:1.2;margin:0 0 12px;letter-spacing:-.02em}\n"
    append css "  .lede{font-size:18px;color:var(--muted);margin:0 0 20px;max-width:62ch}\n"
    append css "  h2{font-size:13px;margin:48px 0 14px;text-transform:uppercase;letter-spacing:.06em;\n"
    append css "     color:var(--muted);font-weight:650}\n"
    append css "  h3{font-size:17px;margin:24px 0 6px}\n"
    append css "  p{margin:0 0 14px;max-width:70ch}\n"
    append css "  .badges{display:flex;gap:7px;flex-wrap:wrap;margin-bottom:20px}\n"
    append css "  .badge{font-size:12px;font-weight:650;padding:4px 11px;border-radius:99px;\n"
    append css "         background:var(--soft);color:var(--muted);border:1px solid var(--line)}\n"
    append css "  .badge.on{background:var(--ok-soft);color:var(--ok);border-color:transparent}\n"
    append css "  table{border-collapse:collapse;width:100%;font-size:14.5px;margin:0 0 14px}\n"
    append css "  th,td{text-align:left;padding:9px 10px;border-bottom:1px solid var(--line);vertical-align:top}\n"
    append css "  th{font-size:12px;text-transform:uppercase;letter-spacing:.04em;color:var(--muted)}\n"
    append css "  code{background:var(--soft);padding:2px 7px;border-radius:5px;font-size:13.5px;\n"
    append css "       font-family:ui-monospace,SFMono-Regular,Menlo,monospace;word-break:break-word}\n"
    append css "  pre{background:var(--soft);border:1px solid var(--line);border-radius:10px;\n"
    append css "      padding:13px 15px;overflow-x:auto;margin:0 0 14px}\n"
    append css "  pre code{background:none;padding:0}\n"
    append css "  .card{border:1px solid var(--line);border-radius:12px;padding:18px 20px;background:var(--bg)}\n"
    append css "  .note{background:var(--warn-soft);border:1px solid transparent;border-radius:10px;\n"
    append css "        padding:14px 16px;margin:0 0 16px;font-size:14.5px}\n"
    append css "  .note b{color:var(--warn)}\n"
    append css "  fieldset{border:1px solid var(--line);border-radius:10px;padding:14px 16px;margin:0 0 14px}\n"
    append css "  legend{font-size:12px;text-transform:uppercase;letter-spacing:.05em;color:var(--muted);padding:0 6px}\n"
    append css "  label.q{display:flex;gap:10px;align-items:flex-start;padding:7px 0;font-size:15px;cursor:pointer}\n"
    append css "  label.q input{margin-top:4px;flex:none}\n"
    append css "  label.q span small{display:block;color:var(--muted);font-size:13px}\n"
    append css "  #ergebnis{margin-top:6px}\n"
    append css "  .verdict{border:1px solid var(--line);border-left:4px solid var(--ac);\n"
    append css "           border-radius:10px;padding:16px 18px;background:var(--soft)}\n"
    append css "  .verdict h3{margin:0 0 6px;font-size:18px}\n"
    append css "  .verdict .step{font-weight:650;margin:10px 0 0}\n"
    append css "  .verdict .w{margin-top:12px;padding:11px 13px;background:var(--warn-soft);\n"
    append css "              border-radius:8px;font-size:14px}\n"
    append css "  .probe{display:flex;gap:8px;flex-wrap:wrap;margin-bottom:12px}\n"
    append css "  .probe input{flex:1 1 240px;padding:10px 12px;border:1px solid var(--line);\n"
    append css "               border-radius:9px;background:var(--bg);color:var(--text);font-size:15px}\n"
    append css "  .btn{font-weight:650;font-size:15px;padding:10px 18px;border-radius:9px;\n"
    append css "       border:1px solid var(--ac);background:var(--ac);color:#fff;cursor:pointer}\n"
    append css "  .btn.ghost{background:var(--bg);color:var(--text);border-color:var(--line)}\n"
    append css "  footer{margin-top:56px;padding-top:22px;border-top:1px solid var(--line);\n"
    append css "         color:var(--muted);font-size:14px}\n"
    append css "  a{color:var(--ac)}\n"
    append css "</style>\n"

    return $css
}

proc generate_header {} {
    set header {}
    append header "<header>\n"
    append header "  <div class=\"badges\">\n"
    append header "    <span class=\"badge on\">Fuenf Zustaende</span>\n"
    append header "    <span class=\"badge\">Discovery</span>\n"
    append header "    <span class=\"badge\">MSIX-Pfadfalle</span>\n"
    append header "    <span class=\"badge\" id=\"modus\">statisch</span>\n"
    append header "  </div>\n"
    append header "  <h1>MCP-Server-Monitor</h1>\n"
    append header "  <p class=\"lede\">Fast jede Frage nach einem MCP-Server ist in Wahrheit eine\n"
    append header "  Zustandsfrage. Wer den Zustand feststellt, hat die Antwort meist schon.</p>\n"
    append header "  <p class=\"lede\" style=\"font-size:16px\">Dieses Werkzeug traegt <b>keine</b> Server\n"
    append header "  ein und meldet niemanden an. Es diagnostiziert, sucht und bereitet den Klickweg\n"
    append header "  exakt vor. Den Klick macht der Nutzer — das ist geprüfte Grenze, keine Bequemlichkeit.</p>\n"
    append header "</header>\n\n"

    return $header
}

proc generate_state_determination {} {
    set state {}
    append state "<h2>Zustand bestimmen</h2>\n"
    append state "<div class=\"card\">\n"
    append state "  <fieldset>\n"
    append state "    <legend>Was siehst du?</legend>\n"
    append state "    <label class=\"q\"><input type=\"checkbox\" id=\"q_tools\"><span>Es gibt Tools mit dem Namensmuster des Servers\n"
    append state "      <small>Das verlaesslichste Signal — Tool-Listen sind scope-gefiltert. Was da ist, ist nutzbar.</small></span></label>\n"
    append state "    <label class=\"q\"><input type=\"checkbox\" id=\"q_haekchen\"><span>Der Konnektor steht in der Liste, mit Haekchen\n"
    append state "      <small>Einstellungen → Anpassen → Konnektoren. Ferne Server haben Typ „Web\".</small></span></label>\n"
    append state "    <label class=\"q\"><input type=\"checkbox\" id=\"q_auth\"><span>Es kommt die Meldung „benoetigt Authentifizierung\"</span></label>\n"
    append state "    <label class=\"q\"><input type=\"checkbox\" id=\"q_plugin\"><span>Derselbe Name laeuft auch als <code>plugin:…</code>\n"
    append state "      <small>Dann sind es zwei verschiedene Server mit getrennter Anmeldung.</small></span></label>\n"
    append state "    <label class=\"q\"><input type=\"checkbox\" id=\"q_angemeldet\"><span>Es wurde fuer diesen Dienst schon einmal etwas angemeldet</span></label>\n"
    append state "  </fieldset>\n"
    append state "  <div id=\"ergebnis\"></div>\n"
    append state "</div>\n\n"

    return $state
}

proc generate_five_states {} {
    set states {}
    append states "<h2>Die fuenf Zustaende</h2>\n"
    append states "<table>\n"
    append states "  <tr><th>Zustand</th><th>Woran erkennbar</th><th>Naechster Schritt</th></tr>\n"
    append states "  <tr><td><b>1 — Offen</b></td><td>Tools vorhanden, nie etwas angemeldet</td><td>Direkt benutzen</td></tr>\n"
    append states "  <tr><td><b>2 — Verbunden, mit Tools</b></td><td>Konnektor mit Haekchen, Tools vorhanden</td><td>Direkt benutzen</td></tr>\n"
    append states "  <tr><td><b>3 — Verbunden, ohne Tools</b></td><td>Konnektor mit Haekchen, aber keine Tools</td><td>Liefert er ueberhaupt Tools? Scope erteilt?</td></tr>\n"
    append states "  <tr><td><b>4 — Installiert, unangemeldet</b></td><td>gelistet, Tools fehlen, „benoetigt Authentifizierung\"</td><td>Anmelden — braucht eine interaktive Sitzung</td></tr>\n"
    append states "  <tr><td><b>5 — Nicht vorhanden</b></td><td>nichts</td><td>Suchen, dann eintragen lassen</td></tr>\n"
    append states "</table>\n"
    append states "<p>Zustand 3 ist der, der als Fehler missverstanden wird. Ein Konnektor kann verbunden\n"
    append states "sein und trotzdem keine Tools mitbringen, weil er gar keine liefert. Die GitHub-Integration\n"
    append states "ist so ein Fall: Sie oeffnet Repository-Zugriff, eine Tool-Sammlung ist sie nicht.</p>\n\n"

    return $states
}

proc generate_discovery {} {
    set discovery {}
    append discovery "<h2>Discovery</h2>\n"
    append discovery "<div class=\"note\" id=\"cors-hinweis\">\n"
    append discovery "  <b>Warum hier kein Knopf steht.</b> Diese Seite ruft keine fremden Endpunkte ab.\n"
    append discovery "  Ein <code>fetch</code> aus dem Browser auf <code>mcp.DOMAIN</code> scheitert an CORS —\n"
    append discovery "  eine Seite, die es trotzdem versucht, bleibt leer und sieht dabei kaputt aus.\n"
    append discovery "  Die echten Proben macht der lokale Companion. Start: <code>python cli.py serve</code>,\n"
    append discovery "  dann diese Seite unter <code>http://127.0.0.1:8787</code> oeffnen — der Knopf erscheint dort von selbst.\n"
    append discovery "</div>\n"
    append discovery "<div id=\"probe-ui\" hidden>\n"
    append discovery "  <div class=\"probe\">\n"
    append discovery "    <input id=\"dom\" placeholder=\"domain, z. B. linear.app\" autocomplete=\"off\">\n"
    append discovery "    <button class=\"btn\" id=\"go\">Pruefen</button>\n"
    append discovery "  </div>\n"
    append discovery "  <div id=\"probe-out\"></div>\n"
    append discovery "</div>\n"
    append discovery "<p>Geprueft wird in dieser Reihenfolge:</p>\n"
    append discovery "<table>\n"
    append discovery "  <tr><th>#</th><th>Pfad</th><th>Bedeutung</th></tr>\n"
    append discovery "  <tr><td>1</td><td><code>https://mcp.DOMAIN/</code></td><td>Streamable-HTTP-Endpunkt</td></tr>\n"
    append discovery "  <tr><td>2</td><td><code>https://mcp.DOMAIN/mcp</code></td><td>haeufige Pfadvariante</td></tr>\n"
    append discovery "  <tr><td>3</td><td><code>https://docs.DOMAIN/mcp</code></td><td>dort steht sie bei den meisten Anbietern</td></tr>\n"
    append discovery "  <tr><td>4</td><td><code>/.well-known/oauth-protected-resource</code></td><td>existiert sie, gibt es einen OAuth-faehigen Server</td></tr>\n"
    append discovery "  <tr><td>5</td><td><code>/.well-known/oauth-authorization-server</code></td><td>dito, mit Revocation-Endpunkt</td></tr>\n"
    append discovery "</table>\n"
    append discovery "<p><b>Eine leere Antwort auf ein nacktes GET beweist nichts.</b> Streamable-HTTP-Endpunkte\n"
    append discovery "antworten darauf oft mit gar nichts, und 400/401/405 sind regulaere Ablehnungen, keine\n"
    append discovery "Negativbefunde. Erst wenn auch die Discovery-Pfade fehlen, ist von Abwesenheit auszugehen.</p>\n\n"

    return $discovery
}

proc generate_registration {} {
    set registration {}
    append registration "<h2>Eintragen — der reale Weg</h2>\n"
    append registration "<p><b>Ferne Server gehoeren unter Konnektoren, nicht unter Erweiterungen.</b>\n"
    append registration "<i>Erweiterungen</i> liegt im Abschnitt „Desktop-App\" und meint lokale Erweiterungen.\n"
    append registration "<i>Konnektoren</i> liegt unter „Anpassen\" und ist der richtige Ort.</p>\n"
    append registration "<h3>Weg 1 — Claude-App</h3>\n"
    append registration "<p>Einstellungen → Anpassen → Konnektoren → „Hinzufuegen\" oben rechts → URL eintragen.\n"
    append registration "Danach fuehrt die Anmeldung durch den Browser.</p>\n"
    append registration "<h3>Weg 2 — Claude Code</h3>\n"
    append registration "<pre><code>claude mcp add --transport http NAME https://mcp.DOMAIN/</code></pre>\n"
    append registration "<p>Danach <code>/mcp</code> aufrufen und im Browser anmelden.</p>\n"
    append registration "<h3>Weg 3 — Konfigurationsdatei</h3>\n"
    append registration "<table>\n"
    append registration "  <tr><th>Installationsart</th><th>Pfad</th></tr>\n"
    append registration "  <tr><td>Standard-Installer</td><td><code>%APPDATA%\\Claude\\claude_desktop_config.json</code></td></tr>\n"
    append registration "  <tr><td>MSIX (Store, WinGet, Enterprise)</td><td><code>%LOCALAPPDATA%\\Packages\\Claude_pzs8sxrjxfjjc\\LocalCache\\Roaming\\Claude\\claude_desktop_config.json</code></td></tr>\n"
    append registration "</table>\n"
    append registration "<div class=\"note\"><b>Die Falle.</b> Bei MSIX oeffnet „Edit Config\" im Entwickler-Menue die\n"
    append registration "<b>erste</b> Datei, gelesen wird die <b>zweite</b>. Wer dort eintraegt, wartet vergeblich.\n"
    append registration "Und die App liest die Datei nur beim Start — nach dem Aendern vollstaendig beenden und neu oeffnen.</div>\n"
    append registration "<p>Welche Datei bei dir wirkt, sagt <code>python cli.py config</code>.</p>\n\n"

    return $registration
}

proc generate_error_images {} {
    set errors {}
    append errors "<h2>Fehlerbilder</h2>\n"
    append errors "<table>\n"
    append errors "  <tr><th>Bild</th><th>Wahrscheinliche Ursache</th></tr>\n"
    append errors "  <tr><td>Verbunden, aber keine Tools</td><td>Konnektor liefert keine Tools, oder Scope fehlt</td></tr>\n"
    append errors "  <tr><td>Name doppelt: verbunden <b>und</b> „benoetigt Auth\"</td><td>Konnektor und Plugin-Server verwechselt</td></tr>\n"
    append errors "  <tr><td><code>invalid_scope</code></td><td>Mehr angefragt, als der Client registriert hat</td></tr>\n"
    append errors "  <tr><td>Haengt dauerhaft in „connecting\"</td><td>Endpunkt falsch, Netz blockiert, oder Server unten</td></tr>\n"
    append errors "  <tr><td>401 nach Wochen problemlosen Betriebs</td><td>Refresh-Token abgelaufen oder widerrufen — neu anmelden</td></tr>\n"
    append errors "  <tr><td>Manuell eingetragener Server bleibt stumm</td><td>MSIX-Pfadfalle, oder App nicht neu gestartet</td></tr>\n"
    append errors "  <tr><td>Tools nach Update verschwunden</td><td>Server neu verbunden, Scopes neu erteilen</td></tr>\n"
    append errors "</table>\n\n"

    return $errors
}

proc generate_operational_limits {} {
    set limits {}
    append limits "<h2>Betriebsgrenzen</h2>\n"
    append limits "<p>Ferne Server sind bequem, aber nicht kostenlos: kein Binaer-Upload (die meisten nehmen\n"
    append limits "nur URLs), ein Roundtrip pro Aufruf, und jeder Aufruf verbraucht echtes Kontingent beim\n"
    append limits "Anbieter — genau wie ein direkter API-Aufruf. Daraus die Regel: <b>Fuer Einzelfragen der\n"
    append limits "MCP-Server. Ab mehreren Aufrufen, bei Dateien oder in Skripten die Direkt-API.</b></p>\n\n"

    return $limits
}

proc generate_footer {} {
    set footer {}
    append footer "<footer>\n"
    append footer "  MCP-Server-Monitor — Branch <code>MCP-Server-Monitor</code> in\n"
    append footer "  <a href=\"https://github.com/KikiKari/Projects/tree/MCP-Server-Monitor\">KikiKari/Projects</a>.\n"
    append footer "  Statisch ausgeliefert aus <code>public/</code>, kein Build, keine Zaehlpixel.\n"
    append footer "</footer>\n\n"

    return $footer
}

proc generate_javascript {} {
    set js {}
    append js "<script>\n"
    append js "(function(){\n"
    append js "  \"use strict\";\n"
    append js "  var Z = {\n"
    append js "    offen:      [\"1 — Offen\",\"Direkt benutzen.\"],\n"
    append js "    mitTools:   [\"2 — Verbunden, mit Tools\",\"Direkt benutzen.\"],\n"
    append js "    ohneTools:  [\"3 — Verbunden, ohne Tools\",\"Pruefen, ob der Konnektor ueberhaupt Tools liefert; danach die erteilten Scopes. Die Tool-Liste ist scope-gefiltert — ein fehlendes Tool heisst fast immer fehlender Scope, nicht fehlende Funktion.\"],\n"
    append js "    unauth:     [\"4 — Installiert, unangemeldet\",\"Anmelden. Das braucht eine interaktive Sitzung — in einer nicht-interaktiven Sitzung startet kein OAuth-Flow.\"],\n"
    append js "    absent:     [\"5 — Nicht vorhanden\",\"Discovery laufen lassen (Connector-Registry, dann die fuenf Pfade unten), danach unter Anpassen → Konnektoren eintragen.\"]\n"
    append js "  };\n"
    append js "  var W_PLUGIN = \"Der Name laeuft auch als <code>plugin:…</code> — das ist ein zweiter, separat anzumeldender Server. Konnektoren haengen am Konto, Plugins bringen eigene MCP-Server mit. Wer das nicht trennt, meldet sich an und sucht den Fehler an der falschen Stelle.\";\n"
    append js "  var W_Z3 = \"Zustand 3 wird oft als Fehler missverstanden. Lies die Beschreibung des Konnektors im Dialog, bevor du einen Fehler vermutest.\";\n\n"
    append js "  var ids = [\"q_tools\",\"q_haekchen\",\"q_auth\",\"q_plugin\",\"q_angemeldet\"];\n"
    append js "  var el = {}; ids.forEach(function(i){ el[i] = document.getElementById(i); });\n"
    append js "  var out = document.getElementById(\"ergebnis\");\n\n"
    append js "  function bestimme(){\n"
    append js "    var t=el.q_tools.checked, h=el.q_haekchen.checked, a=el.q_auth.checked,\n"
    append js "        pl=el.q_plugin.checked, an=el.q_angemeldet.checked;\n"
    append js "    var key, warn=[];\n"
    append js "    if (pl) warn.push(W_PLUGIN);\n"
    append js "    if (t)        key = (h||an) ? \"mitTools\" : \"offen\";\n"
    append js "    else if (a)   key = \"unauth\";\n"
    append js "    else if (h)   { key = \"ohneTools\"; warn.push(W_Z3); }\n"
    append js "    else          key = \"absent\";\n"
    append js "    var z = Z[key];\n"
    append js "    out.innerHTML = '<div class=\"verdict\"><h3>' + z[0] + '</h3>' +\n"
    append js "      '<p class=\"step\">Naechster Schritt</p><p>' + z[1] + '</p>' +\n"
    append js "      warn.map(function(w){ return '<div class=\"w\">' + w + '</div>'; }).join(\"\") +\n"
    append js "      '</div>';\n"
    append js "  }\n"
    append js "  ids.forEach(function(i){ el[i].addEventListener(\"change\", bestimme); });\n"
    append js "  bestimme();\n\n"
    append js "  // Der Live-Probe-Knopf erscheint nur beim lokalen Companion. Im Browser auf\n"
    append js "  // einer fremden Herkunft scheitert der Abruf an CORS — dann lieber gar nicht\n"
    append js "  // anbieten, als leer laufen lassen.\n"
    append js "  var lokal = [\"127.0.0.1\",\"localhost\",\"[::1]\"].indexOf(location.hostname) !== -1;\n"
    append js "  if (lokal){\n"
    append js "    document.getElementById(\"modus\").textContent = \"lokal — Proben aktiv\";\n"
    append js "    document.getElementById(\"modus\").className = \"badge on\";\n"
    append js "    document.getElementById(\"probe-ui\").hidden = false;\n"
    append js "    document.getElementById(\"cors-hinweis\").hidden = true;\n"
    append js "    var po = document.getElementById(\"probe-out\");\n"
    append js "    document.getElementById(\"go\").addEventListener(\"click\", function(){\n"
    append js "      var d = document.getElementById(\"dom\").value.trim();\n"
    append js "      if (!d) return;\n"
    append js "      po.innerHTML = \"<p>pruefe \" + d + \" …</p>\";\n"
    append js "      fetch(\"/api/probe?domain=\" + encodeURIComponent(d))\n"
    append js "        .then(function(r){ return r.json(); })\n"
    append js "        .then(function(r){\n"
    append js "          var rows = r.proben.map(function(p){\n"
    append js "            return \"<tr><td><code>\" + (p.status || \"ERR\") + \"</code></td><td>\" + p.art +\n"
    append js "                   \"</td><td style='word-break:break-all'>\" + p.url + \"</td></tr>\";\n"
    append js "          }).join(\"\");\n"
    append js "          po.innerHTML = '<div class=\"verdict\"><h3>' + r.urteil + \"</h3><p>\" + r.deutung +\n"
    append js "                         \"</p><table><tr><th>HTTP</th><th>Art</th><th>URL</th></tr>\" +\n"
    append js "                         rows + \"</table></div>\";\n"
    append js "        })\n"
    append js "        .catch(function(e){ po.innerHTML = \"<p>Fehlgeschlagen: \" + e + \"</p>\"; });\n"
    append js "    });\n"
    append js "    document.getElementById(\"dom\").addEventListener(\"keydown\", function(e){\n"
    append js "      if (e.key === \"Enter\") document.getElementById(\"go\").click();\n"
    append js "    });\n"
    append js "  }\n"
    append js "})();\n"
    append js "</script>\n"

    return $js
}

# Main execution
puts [generate_html]
