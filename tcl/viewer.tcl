#!/usr/bin/env tclsh
# viewer.html — portiert nach tcl
# Quelle: html, Projects@Telegram-Monitor:public/viewer.html
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

# Portierung von viewer.html nach Tcl 8.6
# Erzeugt das HTML-Dokument dynamisch und speichert es in eine Datei

proc generate_html {} {
    set html {}

    # DOCTYPE und HTML-Grundstruktur
    append html {<!DOCTYPE html>}
    append html {\n<html lang="de">}
    append html {\n<head>}
    append html {\n<meta charset="utf-8">}
    append html {\n<meta name="viewport" content="width=device-width, initial-scale=1">}
    append html {\n<title>TikTok Live Companion — Viewer</title>}
    
    # CSS Styles
    append html {\n<style>}
    append html {\n  :root\{}
    append html {\n    --bg:#0f1115; --card:#171a21; --line:#262b36; --text:#f2f4f8; --muted:#9aa3b2;}
    append html {\n    --tt:#fe2c55; --ok:#22c55e; --warn:#f59e0b;}
    append html {\n    color-scheme: dark;}
    append html {\n  \}}
    append html {\n  @media (prefers-color-scheme: light)\{}
    append html {\n    :root\{ --bg:#f6f7f9; --card:#fff; --line:#e3e6ea; --text:#16191d; --muted:#6b7280; \}}
    append html {\n  \}}
    append html {\n  *\{box-sizing:border-box\}}
    append html {\n  body\{margin:0;background:var(--bg);color:var(--text);}
    append html {\n       font:15px/1.5 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif\}}
    append html {\n  .wrap\{max-width:1180px;margin:0 auto;padding:16px\}}
    append html {\n  header\{display:flex;gap:12px;align-items:center;flex-wrap:wrap;margin-bottom:12px\}}
    append html {\n  h1\{font-size:17px;margin:0;font-weight:650\}}
    append html {\n  .badge\{display:inline-flex;align-items:center;gap:6px;font-size:11.5px;font-weight:700;}
    append html {\n         padding:3px 10px;border-radius:99px;background:#2a2f3a;color:var(--muted)\}}
    append html {\n  .badge.live\{background:var(--tt);color:#fff\}}
    append html {\n  .badge .dot\{width:6px;height:6px;border-radius:50%;background:currentColor\}}
    append html {\n  .badge.live .dot\{animation:pulse 1.6s infinite\}}
    append html {\n  @keyframes pulse\{0%,100%\{opacity:1\}50%\{opacity:.25\}\}}
    append html {\n  input,select,button\{font:inherit;border-radius:8px;border:1px solid var(--line);}
    append html {\n                      background:var(--card);color:var(--text);padding:9px 12px\}}
    append html {\n  input\{min-width:220px\}}
    append html {\n  button\{cursor:pointer;font-weight:600\}}
    append html {\n  button.primary\{background:var(--tt);border-color:var(--tt);color:#fff\}}
    append html {\n  .row\{display:flex;gap:8px;flex-wrap:wrap;align-items:center;margin-bottom:10px\}}
    append html {\n  .grid\{display:grid;grid-template-columns:minmax(0,2fr) minmax(280px,1fr);gap:14px\}}
    append html {\n  @media (max-width:900px)\{ .grid\{grid-template-columns:1fr\} \}}
    append html {\n  .card\{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:14px\}}
    append html {\n  .player\{position:relative;width:100%;aspect-ratio:9/16;max-height:80vh;background:#000;}
    append html {\n          border-radius:12px;overflow:hidden;border:1px solid var(--line)\}}
    append html {\n  .player iframe\{position:absolute;inset:0;width:100%;height:100%;border:0\}}
    append html {\n  .ph\{position:absolute;inset:0;display:flex;flex-direction:column;gap:10px;}
    append html {\n      align-items:center;justify-content:center;color:var(--muted);text-align:center;padding:26px\}}
    append html {\n  h2\{font-size:11.5px;text-transform:uppercase;letter-spacing:.05em;color:var(--muted);}
    append html {\n     margin:0 0 8px;font-weight:650\}}
    append html {\n  .meta\{color:var(--muted);font-size:13px\}}
    append html {\n  .strong\{color:var(--text);font-weight:600\}}
    append html {\n  .stream\{display:flex;gap:10px;padding:6px 0;border-bottom:1px solid var(--line);font-size:13px\}}
    append html {\n  .stream:last-child\{border-bottom:0\}}
    append html {\n  .stream .when\{color:var(--muted);white-space:nowrap;font-variant-numeric:tabular-nums\}}
    append html {\n  .stream .t\{flex:1;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap\}}
    append html {\n  .stream.now\{color:var(--tt);font-weight:650\}}
    append html {\n  .hint\{font-size:12.5px;color:var(--muted);line-height:1.45;margin-top:10px\}}
    append html {\n  a\{color:var(--tt)\} a:hover\{text-decoration:underline\}}
    append html {\n  code\{background:rgba(127,127,127,.15);padding:1px 5px;border-radius:4px;font-size:12.5px;}
    append html {\n       font-family:ui-monospace,SFMono-Regular,Menlo,monospace\}}
    append html {\n</style>}
    append html {\n</head>}
    append html {\n<body>}
    
    # Wrapper
    append html {\n<div class="wrap">}
    
    # Header
    append html {\n  <header>}
    append html {\n    <h1>TikTok Live Companion — Viewer</h1>}
    append html {\n    <span class="badge" id="badge"><span class="dot"></span><span id="badgeText">bereit</span></span>}
    append html {\n    <span class="meta" id="checked"></span>}
    append html {\n  </header>}
    
    # Eingabezeile
    append html {\n  <div class="row">}
    append html {\n    <input id="user" placeholder="@name eingeben — beliebiges öffentliches Konto" autofocus>}
    append html {\n    <button class="primary" id="go">Anzeigen</button>}
    append html {\n    <button id="clear">Leeren</button>}
    append html {\n    <select id="every">}
    append html {\n      <option value="0" selected>Status: nur manuell</option>}
    append html {\n      <option value="60">Status alle 60 s</option>}
    append html {\n      <option value="120">alle 2 min</option>}
    append html {\n      <option value="300">alle 5 min</option>}
    append html {\n    </select>}
    append html {\n    <input id="api" value="" placeholder="Monitor-Adresse (nur lokal)" style="min-width:250px">}
    append html {\n  </div>}
    
    # Grid Layout
    append html {\n  <div class="grid">}
    append html {\n    <div>}
    
    # Player
    append html {\n      <div class="player" id="player">}
    append html {\n        <div class="ph" id="ph">}
    append html {\n          <div style="font-size:34px">📺</div>}
    append html {\n          <div id="phText">Namen eintragen und „Anzeigen“ drücken —<br>der Player startet sofort.</div>}
    append html {\n        </div>}
    append html {\n      </div>}
    
    # Hinweis
    append html {\n      <p class="hint">}
    append html {\n        Eingebettet wird der offizielle TikTok-Live-Player}
    append html {\n        <code id="curUrl">tiktok.com/embed/live/@name</code> — <b>keine Anmeldung,}
    append html {\n        keine Geschenk- oder Kauf-Oberfläche</b>. Ist das Konto offline, zeigt der}
    append html {\n        Rahmen eine Fehlerseite von TikTok; das ist das Offline-Zeichen.}
    append html {\n      </p>}
    append html {\n    </div>}
    
    # Rechte Spalte
    append html {\n    <div>}
    
    # Aufruf-Karte
    append html {\n      <div class="card">}
    append html {\n        <h2>Aufruf</h2>}
    append html {\n        <div class="meta" id="links">noch kein Konto gewählt</div>}
    append html {\n      </div>}
    
    # Status-Karte
    append html {\n      <div class="card" style="margin-top:12px">}
    append html {\n        <h2>Status</h2>}
    append html {\n        <div class="meta" id="status">}
    append html {\n          Läuft gerade / seit wann / letzte Sendungen kommen aus dem lokalen Monitor.}
    append html {\n          Ohne ihn zeigt diese Seite nur den Player — eine lokale Datei darf im}
    append html {\n          Browser keine fremden Server abfragen.}
    append html {\n        </div>}
    append html {\n        <div class="hint">}
    append html {\n          Diese Seite läuft im Web und bettet nur den offiziellen Player ein — das funktioniert ohne alles. Status, Verlauf und Meldungen kommen aus dem lokalen Monitor; dafür die Datei <code>TikTok-Live-Viewer.html</code> aus dem Projektordner nehmen. Ein Zugriff von dieser Web-Adresse auf deinen eigenen Rechner wird vom Browser in der Regel unterbunden.}
    append html {\n        </div>}
    append html {\n      </div>}
    
    # Letzte Sendungen
    append html {\n      <div class="card" style="margin-top:12px">}
    append html {\n        <h2>Letzte Sendungen</h2>}
    append html {\n        <div class="meta" id="streams">—</div>}
    append html {\n      </div>}
    append html {\n    </div>}
    append html {\n  </div>}
    append html {\n</div>}
    
    # JavaScript
    append html {\n<script>}
    append html {\nconst \$ = s => document.querySelector(s);}
    append html {\nconst esc = s => String(s ?? '').replace(/[&<>"]/g, c =>}
    append html {\n  (\{'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'\}[c]));}
    append html {\nconst num = n => n == null ? '?' : Number(n).toLocaleString('de-DE');}
    append html {\nconst clean = s => String(s || '').trim()}
    append html {\n  .replace(/^https?:\/\/(www\.)?tiktok\.com\/@?/i, '')}
    append html {\n  .replace(/\/live.*$/i, '').replace(/^@/, '').trim();}
    append html {\n\nlet timer = null;}
    append html {\n\nfunction embedUrl(user)\{}
    append html {\n  return 'https://www.tiktok.com/embed/live/@' + encodeURIComponent(user);}
    append html {\n\}}
    append html {\n\n/* Player sofort einbetten — ohne jede Statusabfrage. */}
    append html {\nfunction mount(user)\{}
    append html {\n  const holder = \$('#player');}
    append html {\n  holder.querySelectorAll('iframe').forEach(f => f.remove());}
    append html {\n  const f = document.createElement('iframe');}
    append html {\n  f.src = embedUrl(user);}
    append html {\n  f.allow = 'autoplay; encrypted-media; picture-in-picture; fullscreen';}
    append html {\n  f.referrerPolicy = 'origin';}
    append html {\n  f.title = 'TikTok Live von @' + user;}
    append html {\n  holder.appendChild(f);}
    append html {\n  \$('#ph').style.display = 'none';}
    append html {\n  \$('#curUrl').textContent = 'tiktok.com/embed/live/@' + user;}
    append html {\n  \$('#links').innerHTML =}
    append html {\n    '<div class="strong">@' + esc(user) + '</div>' +}
    append html {\n    '<div style="margin-top:6px">' +}
    append html {\n    '<a href="https://www.tiktok.com/@' + esc(user) + '/live" target="_blank" rel="noopener">Live-Seite</a> · ' +}
    append html {\n    '<a href="https://www.tiktok.com/@' + esc(user) + '" target="_blank" rel="noopener">Profil</a> · ' +}
    append html {\n    '<a href="' + esc(embedUrl(user)) + '" target="_blank" rel="noopener">Player einzeln</a></div>';}
    append html {\n\}}
    append html {\n\nfunction setBadge(live)\{}
    append html {\n  \$('#badge').className = 'badge' + (live === true ? ' live' : '');}
    append html {\n  \$('#badgeText').textContent = live === true ? 'LIVE'}
    append html {\n    : (live === false ? 'offline' : 'Status unbekannt');}
    append html {\n\}}
    append html {\n\n/* Status nur, wenn ein Monitor eingetragen ist. */}
    append html {\nasync function fetchStatus(user)\{}
    append html {\n  const base = \$('#api').value.trim().replace(/\/+$/, '');}
    append html {\n  if(!base)\{ setBadge(null); return; \}}
    append html {\n  try\{}
    append html {\n    const r = await fetch(base + '/api/tiktok/status?users=' + encodeURIComponent(user),}
    append html {\n                          \{ cache: 'no-store' \});}
    append html {\n    if(!r.ok) throw new Error('HTTP ' + r.status);}
    append html {\n    const d = await r.json();}
    append html {\n    const st = (d.accounts || [])[0];}
    append html {\n    if(!st) throw new Error('keine Daten');}
    append html {\n    render(st);}
    append html {\n  \}catch(e)\{}
    append html {\n    setBadge(null);}
    append html {\n    \$('#status').innerHTML = '<span style="color:var(--warn)">Monitor nicht erreichbar (' +}
    append html {\n      esc(e.message) + ').</span><br>Der Player oben läuft davon unabhängig weiter.';}
    append html {\n  \}}
    append html {\n\}}
    append html {\n\nfunction render(st)\{}
    append html {\n  setBadge(st.live);}
    append html {\n  \$('#checked').textContent = st.checked_at}
    append html {\n    ? 'geprüft ' + new Date(st.checked_at).toLocaleTimeString('de-DE') : '';}
    append html {\n  \$('#status').innerHTML =}
    append html {\n    (st.title ? '<div class="strong">' + esc(st.title) + '</div>' : '') +}
    append html {\n    (st.started_at ? '<div>Beginn ' + esc(st.started_at.replace('T',' ')) +}
    append html {\n      (st.since ? ' · seit ca. ' + esc(st.since) : '') + '</div>' : '') +}
    append html {\n    (st.last_seen ? '<div>zuletzt gesehen ' + esc(st.last_seen) + '</div>' : '') +}
    append html {\n    (st.streams_total ? '<div>' + num(st.streams_total) + ' Sendungen · ' +}
    append html {\n      esc(st.airtime || '') + ' · ' + num(st.active_days) + ' aktive Tage</div>' : '');}
    append html {\n  \$('#streams').innerHTML = (st.streams || []).length}
    append html {\n    ? st.streams.slice(0, 12).map(s =>}
    append html {\n        '<div class="stream' + (s.is_live ? ' now' : '') + '">' +}
    append html {\n        '<span class="when">' + esc(String(s.day).slice(5)) + ' ' + esc(s.time || '') + '</span>' +}
    append html {\n        '<span class="t">' + esc(s.title || '(ohne Titel)') + '</span>' +}
    append html {\n        '<span class="when">' + esc(s.duration || '') + '</span></div>').join('')}
    append html {\n    : 'keine Daten';}
    append html {\n\}}
    append html {\n\nfunction start()\{}
    append html {\n  const user = clean(\$('#user').value);}
    append html {\n  if(!user)\{ \$('#user').focus(); return; \}}
    append html {\n  \$('#user').value = user;}
    append html {\n  try\{}
    append html {\n    localStorage.setItem('ttv.user', user);}
    append html {\n    localStorage.setItem('ttv.api', \$('#api').value.trim());}
    append html {\n  \}catch(e)\{\}}
    append html {\n  mount(user);}
    append html {\n  fetchStatus(user);}
    append html {\n  if(timer) clearInterval(timer);}
    append html {\n  const every = parseInt(\$('#every').value, 10);}
    append html {\n  if(every > 0) timer = setInterval(() => fetchStatus(user), every * 1000);}
    append html {\n\}}
    append html {\n\n\$('#go').onclick = start;}
    append html {\n\$('#user').addEventListener('keydown', e => \{ if(e.key === 'Enter') start(); \});}
    append html {\n\$('#every').addEventListener('change', start);}
    append html {\n\$('#clear').onclick = () => \{}
    append html {\n  if(timer) clearInterval(timer);}
    append html {\n  document.querySelectorAll('#player iframe').forEach(f => f.remove());}
    append html {\n  \$('#ph').style.display = '';}
    append html {\n  \$('#user').value = '';}
    append html {\n  \$('#links').textContent = 'noch kein Konto gewählt';}
    append html {\n  \$('#streams').textContent = '—';}
    append html {\n  \$('#curUrl').textContent = 'tiktok.com/embed/live/@name';}
    append html {\n  setBadge(null);}
    append html {\n  try\{ localStorage.removeItem('ttv.user'); \}catch(e)\{\}}
    append html {\n  \$('#user').focus();}
    append html {\n\};}
    append html {\n\n/* Nichts fest eingebaut — nur das zuletzt selbst eingegebene Konto. */}
    append html {\ntry\{}
    append html {\n  const savedApi = localStorage.getItem('ttv.api');}
    append html {\n  if(savedApi) \$('#api').value = savedApi;}
    append html {\n  const savedUser = localStorage.getItem('ttv.user');}
    append html {\n  if(savedUser)\{ \$('#user').value = savedUser; start(); \}}
    append html {\n\}catch(e)\{\}}
    append html {\n</script>}
    append html {\n</body>}
    append html {\n</html>}
    
    return $html
}

# Hauptprogramm
if {$argc != 1} {
    puts stderr "Verwendung: $argv0 <ausgabedatei>"
    exit 1
}

set output_file [lindex $argv 0]
set html_content [generate_html]

# Schreibe die HTML-Datei
if {[catch {open $output_file w} fid]} {
    puts stderr "Fehler beim Öffnen der Datei '$output_file': $fid"
    exit 1
}

puts -nonewline $fid $html_content
close $fid

puts "HTML-Datei erfolgreich erstellt: $output_file"
