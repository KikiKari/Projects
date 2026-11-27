#!/usr/bin/env tclsh
# abstraction-provenance: {"artifact_sha256": "2ea82df4c08b0ccdfb6721674a965dc4d7a6622d59fb81167a58aaf49619ba2e", "source_sha256": "acf0fac539f0a8aaf291ce2cdb6ca15cda4a6a1087f02b8e0c2854bd81fa82b3", "target_language": "tcl"}
# tiktok-embed-viewer.html — portiert nach tcl
# Quelle: html, Projects@Telegram-Monitor:plugin/tiktok-embed-viewer.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

# TikTok Live Embed Viewer - Tcl Implementation
# Generates the HTML page dynamically and writes it to a file

proc generate_html {} {
    set html {}

    # Add DOCTYPE and opening html tag
    append html "<!DOCTYPE html>\n"
    append html "<html lang=\"de\">\n"

    # Head section
    append html "<head>\n"
    append html "<meta charset=\"utf-8\">\n"
    append html "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n"
    append html "<title>TikTok Live — Embed-Viewer</title>\n"
    
    # CSS Styles
    append html "<style>\n"
    append html "  :root{\n"
    append html "    --bg:#0f1115; --card:#171a21; --line:#262b36; --text:#f2f4f8; --muted:#9aa3b2;\n"
    append html "    --accent:#25f4ee; --accent2:#fe2c55; --ok:#22c55e; --off:#6b7280;\n"
    append html "    color-scheme: dark;\n"
    append html "  }\n"
    append html "  @media (prefers-color-scheme: light){\n"
    append html "    :root{ --bg:#f6f7f9; --card:#fff; --line:#e3e6ea; --text:#16191d; --muted:#6b7280; }\n"
    append html "  }\n"
    append html "  *{box-sizing:border-box}\n"
    append html "  body{margin:0;background:var(--bg);color:var(--text);\n"
    append html "       font:15px/1.5 -apple-system,BlinkMacSystemFont,\"Segoe UI\",Roboto,sans-serif}\n"
    append html "  .wrap{max-width:1120px;margin:0 auto;padding:16px}\n"
    append html "  header{display:flex;gap:12px;align-items:center;flex-wrap:wrap;margin-bottom:14px}\n"
    append html "  h1{font-size:17px;margin:0;font-weight:650}\n"
    append html "  .badge{display:inline-flex;align-items:center;gap:6px;font-size:12px;font-weight:700;\n"
    append html "         padding:3px 10px;border-radius:99px;background:#2a2f3a;color:var(--muted)}\n"
    append html "  .badge.live{background:var(--accent2);color:#fff}\n"
    append html "  .badge .dot{width:7px;height:7px;border-radius:50%;background:currentColor}\n"
    append html "  .badge.live .dot{animation:pulse 1.6s infinite}\n"
    append html "  @keyframes pulse{0%,100%{opacity:1}50%{opacity:.25}}\n"
    append html "  input,select,button{font:inherit;border-radius:8px;border:1px solid var(--line);\n"
    append html "                      background:var(--card);color:var(--text);padding:8px 11px}\n"
    append html "  button{cursor:pointer;font-weight:600}\n"
    append html "  button.primary{background:var(--accent2);border-color:var(--accent2);color:#fff}\n"
    append html "  .row{display:flex;gap:8px;flex-wrap:wrap;align-items:center;margin-bottom:12px}\n"
    append html "  .grid{display:grid;grid-template-columns:minmax(0,2fr) minmax(260px,1fr);gap:14px}\n"
    append html "  @media (max-width:860px){ .grid{grid-template-columns:1fr} }\n"
    append html "  .card{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:14px}\n"
    append html "  .player{position:relative;width:100%;aspect-ratio:9/16;max-height:78vh;background:#000;\n"
    append html "          border-radius:12px;overflow:hidden;border:1px solid var(--line)}\n"
    append html "  .player iframe{position:absolute;inset:0;width:100%;height:100%;border:0}\n"
    append html "  .placeholder{position:absolute;inset:0;display:flex;flex-direction:column;gap:8px;\n"
    append html "               align-items:center;justify-content:center;color:var(--muted);text-align:center;padding:24px}\n"
    append html "  h2{font-size:12px;text-transform:uppercase;letter-spacing:.05em;color:var(--muted);\n"
    append html "     margin:0 0 8px;font-weight:650}\n"
    append html "  .meta{color:var(--muted);font-size:13px}\n"
    append html "  .stream{display:flex;gap:10px;padding:7px 0;border-bottom:1px solid var(--line);font-size:13.5px}\n"
    append html "  .stream:last-child{border-bottom:0}\n"
    append html "  .stream .when{color:var(--muted);white-space:nowrap;font-variant-numeric:tabular-nums}\n"
    append html "  .stream .t{flex:1;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}\n"
    append html "  .stream.now{color:var(--accent2);font-weight:650}\n"
    append html "  .note{font-size:12.5px;color:var(--muted);margin-top:10px;line-height:1.45}\n"
    append html "  a{color:var(--accent2)} a:hover{text-decoration:underline}\n"
    append html "  .err{background:#3a1d22;border:1px solid #5c2a33;color:#ffb4c0;padding:9px 12px;\n"
    append html "       border-radius:8px;font-size:13px;margin-bottom:10px}\n"
    append html "  @media (prefers-color-scheme: light){ .err{background:#fdeceb;border-color:#f5c6c2;color:#b91c1c} }\n"
    append html "</style>\n"
    append html "</head>\n"

    # Body section
    append html "<body>\n"
    append html "<div class=\"wrap\">\n"
    append html "  <header>\n"
    append html "    <h1>TikTok Live — Embed-Viewer</h1>\n"
    append html "    <span class=\"badge\" id=\"badge\"><span class=\"dot\"></span><span id=\"badgeText\">unbekannt</span></span>\n"
    append html "    <span class=\"meta\" id=\"checked\"></span>\n"
    append html "  </header>\n\n"

    append html "  <div class=\"row\">\n"
    append html "    <input id=\"user\" placeholder=\"@name\" style=\"min-width:180px\">\n"
    append html "    <button class=\"primary\" id=\"go\">Anzeigen</button>\n"
    append html "    <select id=\"every\">\n"
    append html "      <option value=\"60\">Status alle 60 s</option>\n"
    append html "      <option value=\"120\" selected>alle 2 min</option>\n"
    append html "      <option value=\"300\">alle 5 min</option>\n"
    append html "      <option value=\"0\">nur manuell</option>\n"
    append html "    </select>\n"
    append html "    <label class=\"meta\"><input type=\"checkbox\" id=\"notify\"> bei Livegang benachrichtigen</label>\n"
    append html "    <label class=\"meta\"><input type=\"checkbox\" id=\"autoplay\" checked> Player automatisch laden</label>\n"
    append html "    <button id=\"force\">Player trotzdem laden</button>\n"
    append html "  </div>\n\n"

    append html "  <div id=\"error\"></div>\n\n"

    append html "  <div class=\"grid\">\n"
    append html "    <div>\n"
    append html "      <div class=\"player\" id=\"player\">\n"
    append html "        <div class=\"placeholder\" id=\"placeholder\">\n"
    append html "          <div style=\"font-size:34px\">&#x1F4FA;</div>\n"
    append html "          <div id=\"phText\">Konto eingeben und &#8222;Anzeigen&#8220; dr&#252;cken.</div>\n"
    append html "        </div>\n"
    append html "      </div>\n"
    append html "      <p class=\"note\">\n"
    append html "        Eingebettet wird der offizielle TikTok-Live-Player\n"
    append html "        (<code>tiktok.com/embed/live/@name</code>). Er ist auf reines Zuschauen\n"
    append html "        ausgelegt: <b>keine Anmeldung, keine Geschenk- oder Kauf-Oberfl&#228;che</b>.\n"
    append html "        Damit entfallen die kostenpflichtigen Aktionen, die im normalen Frontend\n"
    append html "        erreichbar w&#228;ren &#8212; brauchbar f&#252;r Mitschauen ohne Konto und ohne Kaufrisiko.\n"
    append html "      </p>\n"
    append html "    </div>\n\n"

    append html "    <div>\n"
    append html "      <div class=\"card\">\n"
    append html "        <h2>Status</h2>\n"
    append html "        <div id=\"status\" class=\"meta\">&#8212;</div>\n"
    append html "      </div>\n"
    append html "      <div class=\"card\" style=\"margin-top:12px\">\n"
    append html "        <h2>Letzte Sendungen</h2>\n"
    append html "        <div id=\"streams\" class=\"meta\">&#8212;</div>\n"
    append html "      </div>\n"
    append html "      <div class=\"card\" style=\"margin-top:12px\">\n"
    append html "        <h2>Datenquelle</h2>\n"
    append html "        <div class=\"meta\" id=\"source\">\n"
    append html "          Statusdaten &#252;ber den lokalen Monitor\n"
    append html "          (<code>/api/tiktok/status</code>) oder direkt von der &#246;ffentlichen\n"
    append html "          Profilseite eines Aufzeichnungsdienstes. Kein Konto, keine Umgehung\n"
    append html "          von Zugangskontrollen.\n"
    append html "        </div>\n"
    append html "      </div>\n"
    append html "    </div>\n"
    append html "  </div>\n"
    append html "</div>\n\n"

    # JavaScript section
    append html "<script src=\"./tiktok-companion.js\"></script>\n"
    append html "<script>\n"
    append html "  // Standalone-Betrieb: Parameter aus der URL (?user=creator&api=http://127.0.0.1:8765)\n"
    append html "  const params = new URLSearchParams(location.search);\n"
    append html "  window.TTC = new TikTokCompanion({\n"
    append html "    apiBase: params.get('api') || 'http://127.0.0.1:8765',\n"
    append html "    onState: renderState,\n"
    append html "    onError: msg => {\n"
    append html "      const box = document.getElementById('error');\n"
    append html "      if(!msg){ box.innerHTML = ''; return; }\n"
    append html "      const local = location.protocol === 'file:';\n"
    append html "      box.innerHTML = '<div class=\"err\"><b>Status nicht abrufbar.</b><br>' + esc(msg) +\n"
    append html "        '<br><br>Der Browser l&#228;sst aus dieser Seite heraus keinen direkten Abruf ' +\n"
    append html "        'fremder Server zu' + (local ? ' (lokale Datei, Herkunft &#8222;null&#8220;)' : '') + '. Zwei Wege:' +\n"
    append html "        '<br>&#8226; <b>Monitor starten</b> &#8212; im Projektordner <code>python server.py</code>, ' +\n"
    append html "        'dann hier neu laden. Er liefert den Status und erlaubt den Zugriff ausdr&#252;cklich.' +\n"
    append html "        '<br>&#8226; <b>Als Erweiterung laden</b> &#8212; mit <code>host_permissions</code> f&#252;r ' +\n"
    append html "        '<code>streamrecorder.io</code>, siehe plugin/README.md.' +\n"
    append html "        '<br><br>Der Player unten funktioniert unabh&#228;ngig davon: &#8222;Player trotzdem laden&#8220;.</div>';\n"
    append html "    }\n"
    append html "  });\n\n"

    append html "  const \\$ = s => document.querySelector(s);\n"
    append html "  const esc = s => String(s ?? '').replace(/[&<>\"\\]/g, c =>\n"
    append html "    ({'&':'&amp;','<':'&lt;','>':'&gt;','\"':'&quot;'}[c]));\n\n"

    append html "  function renderState(st){\n"
    append html "    const live = st.live === true;\n"
    append html "    \\$('#badge').className = 'badge' + (live ? ' live' : '');\n"
    append html "    \\$('#badgeText').textContent = live ? 'LIVE' : (st.live === false ? 'offline' : 'unbekannt');\n"
    append html "    \\$('#checked').textContent = st.checked_at\n"
    append html "      ? 'gepr&#252;ft ' + new Date(st.checked_at).toLocaleTimeString('de-DE') : '';\n\n"

    append html "    \\$('#status').innerHTML =\n"
    append html "      (st.title ? '<div style=\"color:var(--text);font-weight:600\">' + esc(st.title) + '</div>' : '') +\n"
    append html "      (st.started_at ? '<div>Beginn ' + esc(st.started_at.replace('T', ' ')) +\n"
    append html "        (st.since ? ' &#183; seit ca. ' + esc(st.since) : '') + '</div>' : '') +\n"
    append html "      (st.last_seen ? '<div>zuletzt gesehen ' + esc(st.last_seen) + '</div>' : '') +\n"
    append html "      (st.streams_total ? '<div>' + st.streams_total + ' Sendungen &#183; ' +\n"
    append html "        esc(st.airtime || '') + ' Sendezeit &#183; ' + (st.active_days || '?') + ' aktive Tage</div>' : '') +\n"
    append html "      '<div style=\"margin-top:8px\"><a href=\"' + esc(st.profile_url || '#') +\n"
    append html "        '\" target=\"_blank\" rel=\"noopener\">Profil</a> &#183; <a href=\"' +\n"
    append html "        esc(st.live_url || '#') + '\" target=\"_blank\" rel=\"noopener\">Live-Seite</a></div>';\n\n"

    append html "    \\$('#streams').innerHTML = (st.streams || []).length\n"
    append html "      ? st.streams.slice(0, 10).map(s =>\n"
    append html "          '<div class=\"stream' + (s.is_live ? ' now' : '') + '\">' +\n"
    append html "          '<span class=\"when\">' + esc(s.day.slice(5)) + ' ' + esc(s.time || '') + '</span>' +\n"
    append html "          '<span class=\"t\">' + esc(s.title || '(ohne Titel)') + '</span>' +\n"
    append html "          '<span class=\"when\">' + esc(s.duration || '') + '</span></div>').join('')\n"
    append html "      : 'keine Daten';\n\n"

    append html "    const wantPlayer = live && \\$('#autoplay').checked;\n"
    append html "    const holder = \\$('#player');\n"
    append html "    if(wantPlayer && !holder.querySelector('iframe')){\n"
    append html "      const f = document.createElement('iframe');\n"
    append html "      f.src = st.embed_url;\n"
    append html "      f.allow = 'autoplay; encrypted-media; picture-in-picture';\n"
    append html "      f.referrerPolicy = 'origin';\n"
    append html "      f.title = 'TikTok Live von @' + st.username;\n"
    append html "      holder.appendChild(f);\n"
    append html "      \\$('#placeholder').style.display = 'none';\n"
    append html "    } else if(!live){\n"
    append html "      holder.querySelectorAll('iframe').forEach(f => f.remove());\n"
    append html "      \\$('#placeholder').style.display = '';\n"
    append html "      \\$('#phText').textContent = st.username\n"
    append html "        ? '@' + st.username + ' ist gerade offline.'\n"
    append html "        : 'Konto eingeben und &#8222;Anzeigen&#8220; dr&#252;cken.';\n"
    append html "    }\n"
    append html "  }\n\n"

    append html "  \\$('#go').onclick = () => {\n"
    append html "    const u = \\$('#user').value.trim().replace(/^@/, '');\n"
    append html "    if(!u) return;\n"
    append html "    document.querySelectorAll('#player iframe').forEach(f => f.remove());\n"
    append html "    localStorage.setItem('ttc.user', u);\n"
    append html "    window.TTC.watch(u, parseInt(\\$('#every').value, 10));\n"
    append html "  };\n"
    append html "  \\$('#user').addEventListener('keydown', e => { if(e.key === 'Enter') \\$('#go').click(); });\n"
    append html "  \\$('#force').onclick = () => {\n"
    append html "    const u = \\$('#user').value.trim().replace(/^@/, '');\n"
    append html "    if(!u) return;\n"
    append html "    const holder = \\$('#player');\n"
    append html "    holder.querySelectorAll('iframe').forEach(f => f.remove());\n"
    append html "    const f = document.createElement('iframe');\n"
    append html "    f.src = TikTokCompanion.embedUrl(u);\n"
    append html "    f.allow = 'autoplay; encrypted-media; picture-in-picture';\n"
    append html "    f.referrerPolicy = 'origin';\n"
    append html "    f.title = 'TikTok Live von @' + u;\n"
    append html "    holder.appendChild(f);\n"
    append html "    \\$('#placeholder').style.display = 'none';\n"
    append html "  };\n"
    append html "  \\$('#every').addEventListener('change', () => \\$('#go').click());\n"
    append html "  \\$('#notify').addEventListener('change', async e => {\n"
    append html "    window.TTC.notifyOnLive = e.target.checked;\n"
    append html "    if(e.target.checked && 'Notification' in window && Notification.permission === 'default'){\n"
    append html "      await Notification.requestPermission();\n"
    append html "    }\n"
    append html "  });\n\n"

    append html "  const saved = params.get('user') || localStorage.getItem('ttc.user');\n"
    append html "  if(saved){ \\$('#user').value = saved; \\$('#go').click(); }\n"
    append html "</script>\n"
    append html "</body>\n"
    append html "</html>\n"

    return $html
}

# Main execution
if {$argc != 1} {
    puts stderr "Usage: $argv0 <output-file>"
    exit 1
}

set output_file [lindex $argv 0]

# Generate the HTML content
set html_content [generate_html]

# Write to file
if {[catch {open $output_file w} fid]} {
    puts stderr "Error: Could not open file '$output_file' for writing"
    exit 1
}

puts $fid $html_content
close $fid

puts "HTML file generated successfully: $output_file"
