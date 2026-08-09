#!/usr/bin/env tclsh
# TikTok-Live-Viewer.html — portiert nach tcl
# Quelle: html, Projects@Telegram-Monitor:TikTok-Live-Viewer.html
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

# Tcl/Tk port of TikTok-Live-Viewer.html
# Generates HTML file that matches the original functionality

package require Tcl 8.6

proc generate_html {} {
    set html {}

    # DOCTYPE and html tag
    append html {<!DOCTYPE html>} \n
    append html {<html lang="de">} \n

    # Head section
    append html {<head>} \n
    append html {<meta charset="utf-8">} \n
    append html {<meta name="viewport" content="width=device-width, initial-scale=1">} \n
    append html {<title>TikTok Live Companion — Viewer</title>} \n
    append html {<style>} \n

    # CSS styles
    append html {
  :root{
    --bg:#0f1115; --card:#171a21; --line:#262b36; --text:#f2f4f8; --muted:#9aa3b2;
    --tt:#fe2c55; --ok:#22c55e; --warn:#f59e0b;
    color-scheme: dark;
  }
  @media (prefers-color-scheme: light){
    :root{ --bg:#f6f7f9; --card:#fff; --line:#e3e6ea; --text:#16191d; --muted:#6b7280; }
  }
  *{box-sizing:border-box}
  body{margin:0;background:var(--bg);color:var(--text);
       font:15px/1.5 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif}
  .wrap{max-width:1180px;margin:0 auto;padding:16px}
  header{display:flex;gap:12px;align-items:center;flex-wrap:wrap;margin-bottom:12px}
  h1{font-size:17px;margin:0;font-weight:650}
  .badge{display:inline-flex;align-items:center;gap:6px;font-size:11.5px;font-weight:700;
         padding:3px 10px;border-radius:99px;background:#2a2f3a;color:var(--muted)}
  .badge.live{background:var(--tt);color:#fff}
  .badge .dot{width:6px;height:6px;border-radius:50%;background:currentColor}
  .badge.live .dot{animation:pulse 1.6s infinite}
  @keyframes pulse{0%,100%{opacity:1}50%{opacity:.25}}
  input,select,button{font:inherit;border-radius:8px;border:1px solid var(--line);
                      background:var(--card);color:var(--text);padding:9px 12px}
  input{min-width:220px}
  button{cursor:pointer;font-weight:600}
  button.primary{background:var(--tt);border-color:var(--tt);color:#fff}
  .row{display:flex;gap:8px;flex-wrap:wrap;align-items:center;margin-bottom:10px}
  .grid{display:grid;grid-template-columns:minmax(0,2fr) minmax(280px,1fr);gap:14px}
  @media (max-width:900px){ .grid{grid-template-columns:1fr} }
  .card{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:14px}
  .player{position:relative;width:100%;aspect-ratio:9/16;max-height:80vh;background:#000;
          border-radius:12px;overflow:hidden;border:1px solid var(--line)}
  .player iframe{position:absolute;inset:0;width:100%;height:100%;border:0}
  .ph{position:absolute;inset:0;display:flex;flex-direction:column;gap:10px;
      align-items:center;justify-content:center;color:var(--muted);text-align:center;padding:26px}
  h2{font-size:11.5px;text-transform:uppercase;letter-spacing:.05em;color:var(--muted);
     margin:0 0 8px;font-weight:600}
  .meta{color:var(--muted);font-size:13px}
  .strong{color:var(--text);font-weight:600}
  .stream{display:flex;gap:10px;padding:6px 0;border-bottom:1px solid var(--line);font-size:13px}
  .stream:last-child{border-bottom:0}
  .stream .when{color:var(--muted);white-space:nowrap;font-variant-numeric:tabular-nums}
  .stream .t{flex:1;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
  .stream.now{color:var(--tt);font-weight:650}
  .hint{font-size:12.5px;color:var(--muted);line-height:1.45;margin-top:10px}
  a{color:var(--tt)} a:hover{text-decoration:underline}
  code{background:rgba(127,127,127,.15);padding:1px 5px;border-radius:4px;font-size:12.5px;
       font-family:ui-monospace,SFMono-Regular,Menlo,monospace}
} \n

    append html {</style>} \n
    append html {</head>} \n

    # Body section
    append html {<body>} \n
    append html {<div class="wrap">} \n

    # Header
    append html {<header>} \n
    append html {<h1>TikTok Live Companion — Viewer</h1>} \n
    append html {<span class="badge" id="badge"><span class="dot"></span><span id="badgeText">bereit</span></span>} \n
    append html {<span class="meta" id="checked"></span>} \n
    append html {</header>} \n

    # Input row
    append html {<div class="row">} \n
    append html {<input id="user" placeholder="@name eingeben — beliebiges öffentliches Konto" autofocus>} \n
    append html {<button class="primary" id="go">Anzeigen</button>} \n
    append html {<button id="clear">Leeren</button>} \n
    append html {<select id="every">} \n
    append html {<option value="0" selected>Status: nur manuell</option>} \n
    append html {<option value="60">Status alle 60 s</option>} \n
    append html {<option value="120">alle 2 min</option>} \n
    append html {<option value="300">alle 5 min</option>} \n
    append html {</select>} \n
    append html {<input id="api" value="http://127.0.0.1:8765" placeholder="Monitor-Adresse" style="min-width:250px">} \n
    append html {</div>} \n

    # Grid layout
    append html {<div class="grid">} \n
    append html {<div>} \n

    # Player section
    append html {<div class="player" id="player">} \n
    append html {<div class="ph" id="ph">} \n
    append html {<div style="font-size:34px">📺</div>} \n
    append html {<div id="phText">Namen eintragen und „Anzeigen“ drücken —<br>der Player startet sofort.</div>} \n
    append html {</div>} \n
    append html {</div>} \n

    # Hint paragraph
    append html {<p class="hint">} \n
    append html {Eingebettet wird der offizielle TikTok-Live-Player} \n
    append html {<code id="curUrl">tiktok.com/embed/live/@name</code> — <b>keine Anmeldung,} \n
    append html {keine Geschenk- oder Kauf-Oberfläche</b>. Ist das Konto offline, zeigt der} \n
    append html {Rahmen eine Fehlerseite von TikTok; das ist das Offline-Zeichen.} \n
    append html {</p>} \n
    append html {</div>} \n

    # Right column
    append html {<div>} \n

    # Links card
    append html {<div class="card">} \n
    append html {<h2>Aufruf</h2>} \n
    append html {<div class="meta" id="links">noch kein Konto gewählt</div>} \n
    append html {</div>} \n

    # Status card
    append html {<div class="card" style="margin-top:12px">} \n
    append html {<h2>Status</h2>} \n
    append html {<div class="meta" id="status">} \n
    append html {Läuft gerade / seit wann / letzte Sendungen kommen aus dem lokalen Monitor.} \n
    append html {Ohne ihn zeigt diese Seite nur den Player — eine lokale Datei darf im} \n
    append html {Browser keine fremden Server abfragen.} \n
    append html {</div>} \n
    append html {<div class="hint">} \n
    append html {Monitor starten: <code>python server.py --poll-interval 120</code> im} \n
    append html {Projektordner, dann oben <code>http://127.0.0.1:8765</code> eintragen} \n
    append html {und „Anzeigen“ drücken.} \n
    append html {</div>} \n
    append html {</div>} \n

    # Streams card
    append html {<div class="card" style="margin-top:12px">} \n
    append html {<h2>Letzte Sendungen</h2>} \n
    append html {<div class="meta" id="streams">—</div>} \n
    append html {</div>} \n

    append html {</div>} \n
    append html {</div>} \n
    append html {</div>} \n

    # JavaScript section
    append html {<script>} \n
    append html {
const \$ = s => document.querySelector(s);
const esc = s => String(s ?? '').replace(/[&<>"]/g, c =>
  ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
const num = n => n == null ? '?' : Number(n).toLocaleString('de-DE');
const clean = s => String(s || '').trim()
  .replace(/^https?:\/\/(www\.)?tiktok\.com\/@?/i, '')
  .replace(/\/live.*$/i, '').replace(/^@/, '').trim();

let timer = null;

function embedUrl(user){
  return 'https://www.tiktok.com/embed/live/@' + encodeURIComponent(user);
}

/* Player sofort einbetten — ohne jede Statusabfrage. */
function mount(user){
  const holder = \$('#player');
  holder.querySelectorAll('iframe').forEach(f => f.remove());
  const f = document.createElement('iframe');
  f.src = embedUrl(user);
  f.allow = 'autoplay; encrypted-media; picture-in-picture; fullscreen';
  f.referrerPolicy = 'origin';
  f.title = 'TikTok Live von @' + user;
  holder.appendChild(f);
  \$('#ph').style.display = 'none';
  \$('#curUrl').textContent = 'tiktok.com/embed/live/@' + user;
  \$('#links').innerHTML =
    '<div class="strong">@' + esc(user) + '</div>' +
    '<div style="margin-top:6px">' +
    '<a href="https://www.tiktok.com/@' + esc(user) + '/live" target="_blank" rel="noopener">Live-Seite</a> · ' +
    '<a href="https://www.tiktok.com/@' + esc(user) + '" target="_blank" rel="noopener">Profil</a> · ' +
    '<a href="' + esc(embedUrl(user)) + '" target="_blank" rel="noopener">Player einzeln</a></div>';
}

function setBadge(live){
  \$('#badge').className = 'badge' + (live === true ? ' live' : '');
  \$('#badgeText').textContent = live === true ? 'LIVE'
    : (live === false ? 'offline' : 'Status unbekannt');
}

/* Status nur, wenn ein Monitor eingetragen ist. */
async function fetchStatus(user){
  const base = \$('#api').value.trim().replace(/\/+$/, '');
  if(!base){ setBadge(null); return; }
  try{
    const r = await fetch(base + '/api/tiktok/status?users=' + encodeURIComponent(user),
                          { cache: 'no-store' });
    if(!r.ok) throw new Error('HTTP ' + r.status);
    const d = await r.json();
    const st = (d.accounts || [])[0];
    if(!st) throw new Error('keine Daten');
    render(st);
  }catch(e){
    setBadge(null);
    \$('#status').innerHTML = '<span style="color:var(--warn)">Monitor nicht erreichbar (' +
      esc(e.message) + ').</span><br>Der Player oben läuft davon unabhängig weiter.';
  }
}

function render(st){
  setBadge(st.live);
  \$('#checked').textContent = st.checked_at
    ? 'geprüft ' + new Date(st.checked_at).toLocaleTimeString('de-DE') : '';
  \$('#status').innerHTML =
    (st.title ? '<div class="strong">' + esc(st.title) + '</div>' : '') +
    (st.started_at ? '<div>Beginn ' + esc(st.started_at.replace('T',' ')) +
      (st.since ? ' · seit ca. ' + esc(st.since) : '') + '</div>' : '') +
    (st.last_seen ? '<div>zuletzt gesehen ' + esc(st.last_seen) + '</div>' : '') +
    (st.streams_total ? '<div>' + num(st.streams_total) + ' Sendungen · ' +
      esc(st.airtime || '') + ' · ' + num(st.active_days) + ' aktive Tage</div>' : '');
  \$('#streams').innerHTML = (st.streams || []).length
    ? st.streams.slice(0, 12).map(s =>
        '<div class="stream' + (s.is_live ? ' now' : '') + '">' +
        '<span class="when">' + esc(String(s.day).slice(5)) + ' ' + esc(s.time || '') + '</span>' +
        '<span class="t">' + esc(s.title || '(ohne Titel)') + '</span>' +
        '<span class="when">' + esc(s.duration || '') + '</span></div>').join('')
    : 'keine Daten';
}

function start(){
  const user = clean(\$('#user').value);
  if(!user){ \$('#user').focus(); return; }
  \$('#user').value = user;
  try{
    localStorage.setItem('ttv.user', user);
    localStorage.setItem('ttv.api', \$('#api').value.trim());
  }catch(e){}
  mount(user);
  fetchStatus(user);
  if(timer) clearInterval(timer);
  const every = parseInt(\$('#every').value, 10);
  if(every > 0) timer = setInterval(() => fetchStatus(user), every * 1000);
}

\$('#go').onclick = start;
\$('#user').addEventListener('keydown', e => { if(e.key === 'Enter') start(); });
\$('#every').addEventListener('change', start);
\$('#clear').onclick = () => {
  if(timer) clearInterval(timer);
  document.querySelectorAll('#player iframe').forEach(f => f.remove());
  \$('#ph').style.display = '';
  \$('#user').value = '';
  \$('#links').textContent = 'noch kein Konto gewählt';
  \$('#streams').textContent = '—';
  \$('#curUrl').textContent = 'tiktok.com/embed/live/@name';
  setBadge(null);
  try{ localStorage.removeItem('ttv.user'); }catch(e){}
  \$('#user').focus();
};

/* Nichts fest eingebaut — nur das zuletzt selbst eingegebene Konto. */
try{
  const savedApi = localStorage.getItem('ttv.api');
  if(savedApi) \$('#api').value = savedApi;
  const savedUser = localStorage.getItem('ttv.user');
  if(savedUser){ \$('#user').value = savedUser; start(); }
}catch(e){}
} \n
    append html {</script>} \n
    append html {</body>} \n
    append html {</html>} \n

    return $html
}

# Main execution
if {$argc != 1} {
    puts stderr "Usage: $argv0 <output-file>"
    exit 1
}

set output_file [lindex $argv 0]
set html_content [generate_html]

if {[catch {open $output_file w} fd]} {
    puts stderr "Error: Could not write to file '$output_file': $fd"
    exit 1
}

puts $fd $html_content
close $fd

puts "Successfully generated '$output_file'"
