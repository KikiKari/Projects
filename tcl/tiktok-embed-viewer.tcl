#!/usr/bin/env tclsh
# tiktok-embed-viewer.html — portiert nach tcl
# Quelle: html, Projects@Telegram-Monitor:plugin/tiktok-embed-viewer.html
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

# Portierung von tiktok-embed-viewer.html nach Tcl 8.6
# Erzeugt das HTML-Dokument und schreibt es in eine Datei

proc main {args} {
    if {[llength $args] != 1} {
        puts stderr "Aufruf: [info script] <ausgabedatei>"
        exit 1
    }
    
    set outfile [lindex $args 0]
    set html [generate_html]
    
    set fh [open $outfile w]
    puts -nonewline $fh $html
    close $fh
    
    puts "HTML-Dokument erzeugt: $outfile"
}

proc generate_html {} {
    set html {}
    
    append html {<!DOCTYPE html>}
    append html "\n" {<html lang="de">}
    append html "\n" {<head>}
    append html "\n" {<meta charset="utf-8">}
    append html "\n" {<meta name="viewport" content="width=device-width, initial-scale=1">}
    append html "\n" {<title>TikTok Live — Embed-Viewer</title>}
    append html "\n" {<style>}
    append html "\n" {  :root\{}
    append html "\n" {    --bg:#0f1115; --card:#171a21; --line:#262b36; --text:#f2f4f8; --muted:#9aa3b2;}
    append html "\n" {    --accent:#25f4ee; --accent2:#fe2c55; --ok:#22c55e; --off:#6b7280;}
    append html "\n" {    color-scheme: dark;}
    append html "\n" {  \}}
    append html "\n" {  @media (prefers-color-scheme: light)\{}
    append html "\n" {    :root\{ --bg:#f6f7f9; --card:#fff; --line:#e3e6ea; --text:#16191d; --muted:#6b7280; \}}
    append html "\n" {  \}}
    append html "\n" {  *{box-sizing:border-box\}}
    append html "\n" {  body{margin:0;background:var(--bg);color:var(--text);}
    append html "\n" {       font:15px/1.5 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif\}}
    append html "\n" {  .wrap{max-width:1120px;margin:0 auto;padding:16px\}}
    append html "\n" {  header{display:flex;gap:12px;align-items:center;flex-wrap:wrap;margin-bottom:14px\}}
    append html "\n" {  h1{font-size:17px;margin:0;font-weight:650\}}
    append html "\n" {  .badge{display:inline-flex;align-items:center;gap:6px;font-size:12px;font-weight:700;}
    append html "\n" {         padding:3px 10px;border-radius:99px;background:#2a2f3a;color:var(--muted)\}}
    append html "\n" {  .badge.live{background:var(--accent2);color:#fff\}}
    append html "\n" {  .badge .dot{width:7px;height:7px;border-radius:50%;background:currentColor\}}
    append html "\n" {  .badge.live .dot{animation:pulse 1.6s infinite\}}
    append html "\n" {  @keyframes pulse{0%,100%{opacity:1\}50%{opacity:.25\}\}}
    append html "\n" {  input,select,button{font:inherit;border-radius:8px;border:1px solid var(--line);}
    append html "\n" {                      background:var(--card);color:var(--text);padding:8px 11px\}}
    append html "\n" {  button{cursor:pointer;font-weight:600\}}
    append html "\n" {  button.primary{background:var(--accent2);border-color:var(--accent2);color:#fff\}}
    append html "\n" {  .row{display:flex;gap:8px;flex-wrap:wrap;align-items:center;margin-bottom:12px\}}
    append html "\n" {  .grid{display:grid;grid-template-columns:minmax(0,2fr) minmax(260px,1fr);gap:14px\}}
    append html "\n" {  @media (max-width:860px){ .grid{grid-template-columns:1fr\} \}}
    append html "\n" {  .card{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:14px\}}
    append html "\n" {  .player{position:relative;width:100%;aspect-ratio:9/16;max-height:78vh;background:#000;}
    append html "\n" {          border-radius:12px;overflow:hidden;border:1px solid var(--line)\}}
    append html "\n" {  .player iframe{position:absolute;inset:0;width:100%;height:100%;border:0\}}
    append html "\n" {  .placeholder{position:absolute;inset:0;display:flex;flex-direction:column;gap:8px;}
    append html "\n" {               align-items:center;justify-content:center;color:var(--muted);text-align:center;padding:24px\}}
    append html "\n" {  h2{font-size:12px;text-transform:uppercase;letter-spacing:.05em;color:var(--muted);}
    append html "\n" {     margin:0 0 8px;font-weight:650\}}
    append html "\n" {  .meta{color:var(--muted);font-size:13px\}}
    append html "\n" {  .stream{display:flex;gap:10px;padding:7px 0;border-bottom:1px solid var(--line);font-size:13.5px\}}
    append html "\n" {  .stream:last-child{border-bottom:0\}}
    append html "\n" {  .stream .when{color:var(--muted);white-space:nowrap;font-variant-numeric:tabular-nums\}}
    append html "\n" {  .stream .t{flex:1;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap\}}
    append html "\n" {  .stream.now{color:var(--accent2);font-weight:650\}}
    append html "\n" {  .note{font-size:12.5px;color:var(--muted);margin-top:10px;line-height:1.45\}}
    append html "\n" {  a{color:var(--accent2)\} a:hover{text-decoration:underline\}}
    append html "\n" {  .err{background:#3a1d22;border:1px solid #5c2a33;color:#ffb4c0;padding:9px 12px;}
    append html "\n" {       border-radius:8px;font-size:13px;margin-bottom:10px\}}
    append html "\n" {  @media (prefers-color-scheme: light){ .err{background:#fdeceb;border-color:#f5c6c2;color:#b91c1c\} \}}
    append html "\n" {</style>}
    append html "\n" {</head>}
    append html "\n" {<body>}
    append html "\n" {<div class="wrap">}
    append html "\n" {  <header>}"
    append html "\n" {    <h1>TikTok Live — Embed-Viewer</h1>}"
    append html "\n" {    <span class=\"badge\" id=\"badge\"><span class=\"dot\"></span><span id=\"badgeText\">unbekannt</span></span>}"
    append html "\n" {    <span class=\"meta\" id=\"checked\"></span>}"
    append html "\n" {  </header>}"
    append html "\n" ""
    append html "\n" {  <div class=\"row\">}"
    append html "\n" {    <input id=\"user\" placeholder=\"@name\" style=\"min-width:180px\">}"
    append html "\n" {    <button class=\"primary\" id=\"go\">Anzeigen</button>}"
    append html "\n" {    <select id=\"every\">}"
    append html "\n" {      <option value=\"60\">Status alle 60 s</option>}"
    append html "\n" {      <option value=\"120\" selected>alle 2 min</option>}"
    append html "\n" {      <option value=\"300\">alle 5 min</option>}"
    append html "\n" {      <option value=\"0\">nur manuell</option>}"
    append html "\n" {    </select>}"
    append html "\n" {    <label class=\"meta\"><input type=\"checkbox\" id=\"notify\"> bei Livegang benachrichtigen</label>}"
    append html "\n" {    <label class=\"meta\"><input type=\"checkbox\" id=\"autoplay\" checked> Player automatisch laden</label>}"
    append html "\n" {    <button id=\"force\">Player trotzdem laden</button>}"
    append html "\n" {  </div>}"
    append html "\n" ""
    append html "\n" {  <div id=\"error\"></div>}"
    append html "\n" ""
    append html "\n" {  <div class=\"grid\">}"
    append html "\n" {    <div>}"
    append html "\n" {      <div class=\"player\" id=\"player\">}"
    append html "\n" {        <div class=\"placeholder\" id=\"placeholder\">}"
    append html "\n" {          <div style=\"font-size:34px\">📺</div>}"
    append html "\n" {          <div id=\"phText\">Konto eingeben und „Anzeigen“ drücken.</div>}"
    append html "\n" {        </div>}"
    append html "\n" {      </div>}"
    append html "\n" {      <p class=\"note\">}"
    append html "\n" {        Eingebettet wird der offizielle TikTok-Live-Player}"
    append html "\n" {        (<code>tiktok.com/embed/live/@name</code>). Er ist auf reines Zuschauen}"
    append html "\n" {        ausgelegt: <b>keine Anmeldung, keine Geschenk- oder Kauf-Oberfläche</b>.}"
    append html "\n" {        Damit entfallen die kostenpflichtigen Aktionen, die im normalen Frontend}"
    append html "\n" {        erreichbar wären — brauchbar für Mitschauen ohne Konto und ohne Kaufrisiko.}"
    append html "\n" {      </p>}"
    append html "\n" {    </div>}"
    append html "\n" ""
    append html "\n" {    <div>}"
    append html "\n" {      <div class=\"card\">}"
    append html "\n" {        <h2>Status</h2>}"
    append html "\n" {        <div id=\"status\" class=\"meta\">—</div>}"
    append html "\n" {      </div>}"
    append html "\n" {      <div class=\"card\" style=\"margin-top:12px\">}"
    append html "\n" {        <h2>Letzte Sendungen</h2>}"
    append html "\n" {        <div id=\"streams\" class=\"meta\">—</div>}"
    append html "\n" {      </div>}"
    append html "\n" {      <div class=\"card\" style=\"margin-top:12px\">}"
    append html "\n" {        <h2>Datenquelle</h2>}"
    append html "\n" {        <div class=\"meta\" id=\"source\">}"
    append html "\n" {          Statusdaten über den lokalen Monitor}"
    append html "\n" {          (<code>/api/tiktok/status</code>) oder direkt von der öffentlichen}"
    append html "\n" {          Profilseite eines Aufzeichnungsdienstes. Kein Konto, keine Umgehung}"
    append html "\n" {          von Zugangskontrollen.}"
    append html "\n" {        </div>}"
    append html "\n" {      </div>}"
    append html "\n" {    </div>}"
    append html "\n" {  </div>}"
    append html "\n" {</div>}"
    append html "\n" ""
    append html "\n" {<script src=\"./tiktok-companion.js\"></script>}"
    append html "\n" {<script>}"
    append html "\n" {  // Standalone-Betrieb: Parameter aus der URL (?user=creator&api=http://127.0.0.1:8765)}"
    append html "\n" {  const params = new URLSearchParams(location.search);}"
    append html "\n" {  window.TTC = new TikTokCompanion({}"
    append html "\n" {    apiBase: params.get('api') || 'http://127.0.0.1:8765',}"
    append html "\n" {    onState: renderState,}"
    append html "\n" {    onError: msg => {"
    append html "\n" {      const box = document.getElementById('error');"
    append html "\n" {      if(!msg){ box.innerHTML = ''; return; \}}"
    append html "\n" {      const local = location.protocol === 'file:';"
    append html "\n" {      box.innerHTML = '<div class=\"err\"><b>Status nicht abrufbar.</b><br>' + esc(msg) +"
    append html "\n" {        '<br><br>Der Browser lässt aus dieser Seite heraus keinen direkten Abruf ' +"
    append html "\n" {        'fremder Server zu' + (local ? ' (lokale Datei, Herkunft „null“)' : '') + '. Zwei Wege:' +"
    append html "\n" {        '<br>• <b>Monitor starten</b> — im Projektordner <code>python server.py</code>, ' +"
    append html "\n" {        'dann hier neu laden. Er liefert den Status und erlaubt den Zugriff ausdrücklich.' +"
    append html "\n" {        '<br>• <b>Als Erweiterung laden</b> — mit <code>host_permissions</code> für ' +"
    append html "\n" {        '<code>streamrecorder.io</code>, siehe plugin/README.md.' +"
    append html "\n" {        '<br><br>Der Player unten funktioniert unabhängig davon: „Player trotzdem laden“.</div>';}"
    append html "\n" {    \}}"
    append html "\n" {  });}"
    append html "\n" ""
    append html "\n" {  const \$ = s => document.querySelector(s);}"
    append html "\n" {  const esc = s => String(s ?? '').replace(/[&<>]/g, c =>"
    append html "\n" {    ({'&':'&amp;','<':'&lt;','>':'&gt;','':''\}[c]));}"
    append html "\n" ""
    append html "\n" {  function renderState(st){}"
    append html "\n" {    const live = st.live === true;"
    append html "\n" {    \$('#badge').className = 'badge' + (live ? ' live' : '');"
    append html "\n" {    \$('#badgeText').textContent = live ? 'LIVE' : (st.live === false ? 'offline' : 'unbekannt');"
    append html "\n" {    \$('#checked').textContent = st.checked_at"
    append html "\n" {      ? 'geprüft ' + new Date(st.checked_at).toLocaleTimeString('de-DE') : '';}"
    append html "\n" ""
    append html "\n" {    \$('#status').innerHTML ="
    append html "\n" {      (st.title ? '<div style=\"color:var(--text);font-weight:600\">' + esc(st.title) + '</div>' : '') +"
    append html "\n" {      (st.started_at ? '<div>Beginn ' + esc(st.started_at.replace('T', ' ')) +"
    append html "\n" {        (st.since ? ' · seit ca. ' + esc(st.since) : '') + '</div>' : '') +"
    append html "\n" {      (st.last_seen ? '<div>zuletzt gesehen ' + esc(st.last_seen) + '</div>' : '') +"
    append html "\n" {      (st.streams_total ? '<div>' + st.streams_total + ' Sendungen · ' +"
    append html "\n" {        esc(st.airtime || '') + ' Sendezeit · ' + (st.active_days || '?') + ' aktive Tage</div>' : '') +"
    append html "\n" {      '<div style=\"margin-top:8px\"><a href=\"' + esc(st.profile_url || '#') +"
    append html "\n" {        '\" target=\"_blank\" rel=\"noopener\">Profil</a> · <a href=\"' +"
    append html "\n" {        esc(st.live_url || '#') + '\" target=\"_blank\" rel=\"noopener\">Live-Seite</a></div>';}"
    append html "\n" ""
    append html "\n" {    \$('#streams').innerHTML = (st.streams || []).length"
    append html "\n" {      ? st.streams.slice(0, 10).map(s =>"
    append html "\n" {          '<div class=\"stream' + (s.is_live ? ' now' : '') + '\">' +"
    append html "\n" {          '<span class=\"when\">' + esc(s.day.slice(5)) + ' ' + esc(s.time || '') + '</span>' +"
    append html "\n" {          '<span class=\"t\">' + esc(s.title || '(ohne Titel)') + '</span>' +"
    append html "\n" {          '<span class=\"when\">' + esc(s.duration || '') + '</span></div>').join('')"
    append html "\n" {      : 'keine Daten';}"
    append html "\n" ""
    append html "\n" {    const wantPlayer = live && \$('#autoplay').checked;"
    append html "\n" {    const holder = \$('#player');"
    append html "\n" {    if(wantPlayer && !holder.querySelector('iframe')){"
    append html "\n" {      const f = document.createElement('iframe');"
    append html "\n" {      f.src = st.embed_url;"
    append html "\n" {      f.allow = 'autoplay; encrypted-media; picture-in-picture';"
    append html "\n" {      f.referrerPolicy = 'origin';"
    append html "\n" {      f.title = 'TikTok Live von @' + st.username;"
    append html "\n" {      holder.appendChild(f);"
    append html "\n" {      \$('#placeholder').style.display = 'none';"
    append html "\n" {    \} else if(!live){"
    append html "\n" {      holder.querySelectorAll('iframe').forEach(f => f.remove());"
    append html "\n" {      \$('#placeholder').style.display = '';"
    append html "\n" {      \$('#phText').textContent = st.username"
    append html "\n" {        ? '@' + st.username + ' ist gerade offline.'"
    append html "\n" {        : 'Konto eingeben und „Anzeigen“ drücken.';"
    append html "\n" {    \}}"
    append html "\n" {  \}}"
    append html "\n" ""
    append html "\n" {  \$('#go').onclick = () => {"
    append html "\n" {    const u = \$('#user').value.trim().replace(/^@/, '');"
    append html "\n" {    if(!u) return;"
    append html "\n" {    document.querySelectorAll('#player iframe').forEach(f => f.remove());"
    append html "\n" {    localStorage.setItem('ttc.user', u);"
    append html "\n" {    window.TTC.watch(u, parseInt(\$('#every').value, 10));"
    append html "\n" {  \};"
    append html "\n" {  \$('#user').addEventListener('keydown', e => { if(e.key === 'Enter') \$('#go').click(); \});"
    append html "\n" {  \$('#force').onclick = () => {"
    append html "\n" {    const u = \$('#user').value.trim().replace(/^@/, '');"
    append html "\n" {    if(!u) return;"
    append html "\n" {    const holder = \$('#player');"
    append html "\n" {    holder.querySelectorAll('iframe').forEach(f => f.remove());"
    append html "\n" {    const f = document.createElement('iframe');"
    append html "\n" {    f.src = TikTokCompanion.embedUrl(u);"
    append html "\n" {    f.allow = 'autoplay; encrypted-media; picture-in-picture';"
    append html "\n" {    f.referrerPolicy = 'origin';"
    append html "\n" {    f.title = 'TikTok Live von @' + u;"
    append html "\n" {    holder.appendChild(f);"
    append html "\n" {    \$('#placeholder').style.display = 'none';"
    append html "\n" {  \};"
    append html "\n" {  \$('#every').addEventListener('change', () => \$('#go').click());"
    append html "\n" {  \$('#notify').addEventListener('change', async e => {"
    append html "\n" {    window.TTC.notifyOnLive = e.target.checked;"
    append html "\n" {    if(e.target.checked && 'Notification' in window && Notification.permission === 'default'){"
    append html "\n" {      await Notification.requestPermission();"
    append html "\n" {    \}"
    append html "\n" {  });"
    append html "\n" ""
    append html "\n" {  const saved = params.get('user') || localStorage.getItem('ttc.user');"
    append html "\n" {  if(saved){ \$('#user').value = saved; \$('#go').click(); \}}"
    append html "\n" {</script>}"
    append html "\n" {</body>}"
    append html "\n" {</html>}"
    
    return $html
}

main {*}$argv
