// abstraction-provenance: {"artifact_sha256": "3825c4035f2c9c7634a26a35da3c21d8630fb04539172988fa7b115841fbdde5", "source_sha256": "83117e76f05b08bc4554d3f4feb0f928c62429bbccc6f556ec336643a33b2a1a", "target_language": "c"}
// TikTok-Live-Viewer.html — portiert nach c
// Quelle: html, Projects@Telegram-Monitor:TikTok-Live-Viewer.html
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void write_html_header(FILE *file) {
    fprintf(file, "<!DOCTYPE html>\n");
    fprintf(file, "<html lang=\"de\">\n");
    fprintf(file, "<head>\n");
    fprintf(file, "<meta charset=\"utf-8\">\n");
    fprintf(file, "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n");
    fprintf(file, "<title>TikTok Live Companion — Viewer</title>\n");
    fprintf(file, "<style>\n");
    fprintf(file, "  :root{\n");
    fprintf(file, "    --bg:#0f1115; --card:#171a21; --line:#262b36; --text:#f2f4f8; --muted:#9aa3b2;\n");
    fprintf(file, "    --tt:#fe2c55; --ok:#22c55e; --warn:#f59e0b;\n");
    fprintf(file, "    color-scheme: dark;\n");
    fprintf(file, "  }\n");
    fprintf(file, "  @media (prefers-color-scheme: light){\n");
    fprintf(file, "    :root{ --bg:#f6f7f9; --card:#fff; --line:#e3e6ea; --text:#16191d; --muted:#6b7280; }\n");
    fprintf(file, "  }\n");
    fprintf(file, "  *{box-sizing:border-box}\n");
    fprintf(file, "  body{margin:0;background:var(--bg);color:var(--text);\n");
    fprintf(file, "       font:15px/1.5 -apple-system,BlinkMacSystemFont,\"Segoe UI\",Roboto,sans-serif}\n");
    fprintf(file, "  .wrap{max-width:1180px;margin:0 auto;padding:16px}\n");
    fprintf(file, "  header{display:flex;gap:12px;align-items:center;flex-wrap:wrap;margin-bottom:12px}\n");
    fprintf(file, "  h1{font-size:17px;margin:0;font-weight:650}\n");
    fprintf(file, "  .badge{display:inline-flex;align-items:center;gap:6px;font-size:11.5px;font-weight:700;\n");
    fprintf(file, "         padding:3px 10px;border-radius:99px;background:#2a2f3a;color:var(--muted)}\n");
    fprintf(file, "  .badge.live{background:var(--tt);color:#fff}\n");
    fprintf(file, "  .badge .dot{width:6px;height:6px;border-radius:50%;background:currentColor}\n");
    fprintf(file, "  .badge.live .dot{animation:pulse 1.6s infinite}\n");
    fprintf(file, "  @keyframes pulse{0%%,100%%{opacity:1}50%%{opacity:.25}}\n");
    fprintf(file, "  input,select,button{font:inherit;border-radius:8px;border:1px solid var(--line);\n");
    fprintf(file, "                      background:var(--card);color:var(--text);padding:9px 12px}\n");
    fprintf(file, "  input{min-width:220px}\n");
    fprintf(file, "  button{cursor:pointer;font-weight:600}\n");
    fprintf(file, "  button.primary{background:var(--tt);border-color:var(--tt);color:#fff}\n");
    fprintf(file, "  .row{display:flex;gap:8px;flex-wrap:wrap;align-items:center;margin-bottom:10px}\n");
    fprintf(file, "  .grid{display:grid;grid-template-columns:minmax(0,2fr) minmax(280px,1fr);gap:14px}\n");
    fprintf(file, "  @media (max-width:900px){ .grid{grid-template-columns:1fr} }\n");
    fprintf(file, "  .card{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:14px}\n");
    fprintf(file, "  .player{position:relative;width:100%%;aspect-ratio:9/16;max-height:80vh;background:#000;\n");
    fprintf(file, "          border-radius:12px;overflow:hidden;border:1px solid var(--line)}\n");
    fprintf(file, "  .player iframe{position:absolute;inset:0;width:100%%;height:100%%;border:0}\n");
    fprintf(file, "  .ph{position:absolute;inset:0;display:flex;flex-direction:column;gap:10px;\n");
    fprintf(file, "      align-items:center;justify-content:center;color:var(--muted);text-align:center;padding:26px}\n");
    fprintf(file, "  h2{font-size:11.5px;text-transform:uppercase;letter-spacing:.05em;color:var(--muted);\n");
    fprintf(file, "     margin:0 0 8px;font-weight:650}\n");
    fprintf(file, "  .meta{color:var(--muted);font-size:13px}\n");
    fprintf(file, "  .strong{color:var(--text);font-weight:600}\n");
    fprintf(file, "  .stream{display:flex;gap:10px;padding:6px 0;border-bottom:1px solid var(--line);font-size:13px}\n");
    fprintf(file, "  .stream:last-child{border-bottom:0}\n");
    fprintf(file, "  .stream .when{color:var(--muted);white-space:nowrap;font-variant-numeric:tabular-nums}\n");
    fprintf(file, "  .stream .t{flex:1;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}\n");
    fprintf(file, "  .stream.now{color:var(--tt);font-weight:650}\n");
    fprintf(file, "  .hint{font-size:12.5px;color:var(--muted);line-height:1.45;margin-top:10px}\n");
    fprintf(file, "  a{color:var(--tt)} a:hover{text-decoration:underline}\n");
    fprintf(file, "  code{background:rgba(127,127,127,.15);padding:1px 5px;border-radius:4px;font-size:12.5px;\n");
    fprintf(file, "       font-family:ui-monospace,SFMono-Regular,Menlo,monospace}\n");
    fprintf(file, "</style>\n");
    fprintf(file, "</head>\n");
    fprintf(file, "<body>\n");
}

void write_html_body(FILE *file) {
    fprintf(file, "<div class=\"wrap\">\n");
    fprintf(file, "  <header>\n");
    fprintf(file, "    <h1>TikTok Live Companion — Viewer</h1>\n");
    fprintf(file, "    <span class=\"badge\" id=\"badge\"><span class=\"dot\"></span><span id=\"badgeText\">bereit</span></span>\n");
    fprintf(file, "    <span class=\"meta\" id=\"checked\"></span>\n");
    fprintf(file, "  </header>\n\n");
    
    fprintf(file, "  <div class=\"row\">\n");
    fprintf(file, "    <input id=\"user\" placeholder=\"@name eingeben — beliebiges öffentliches Konto\" autofocus>\n");
    fprintf(file, "    <button class=\"primary\" id=\"go\">Anzeigen</button>\n");
    fprintf(file, "    <button id=\"clear\">Leeren</button>\n");
    fprintf(file, "    <select id=\"every\">\n");
    fprintf(file, "      <option value=\"0\" selected>Status: nur manuell</option>\n");
    fprintf(file, "      <option value=\"60\">Status alle 60 s</option>\n");
    fprintf(file, "      <option value=\"120\">alle 2 min</option>\n");
    fprintf(file, "      <option value=\"300\">alle 5 min</option>\n");
    fprintf(file, "    </select>\n");
    fprintf(file, "    <input id=\"api\" value=\"http://127.0.0.1:8765\" placeholder=\"Monitor-Adresse\" style=\"min-width:250px\">\n");
    fprintf(file, "  </div>\n\n");
    
    fprintf(file, "  <div class=\"grid\">\n");
    fprintf(file, "    <div>\n");
    fprintf(file, "      <div class=\"player\" id=\"player\">\n");
    fprintf(file, "        <div class=\"ph\" id=\"ph\">\n");
    fprintf(file, "          <div style=\"font-size:34px\">📺</div>\n");
    fprintf(file, "          <div id=\"phText\">Namen eintragen und „Anzeigen“ drücken —<br>der Player startet sofort.</div>\n");
    fprintf(file, "        </div>\n");
    fprintf(file, "      </div>\n");
    fprintf(file, "      <p class=\"hint\">\n");
    fprintf(file, "        Eingebettet wird der offizielle TikTok-Live-Player\n");
    fprintf(file, "        <code id=\"curUrl\">tiktok.com/embed/live/@name</code> — <b>keine Anmeldung,\n");
    fprintf(file, "        keine Geschenk- oder Kauf-Oberfläche</b>. Ist das Konto offline, zeigt der\n");
    fprintf(file, "        Rahmen eine Fehlerseite von TikTok; das ist das Offline-Zeichen.\n");
    fprintf(file, "      </p>\n");
    fprintf(file, "    </div>\n\n");
    
    fprintf(file, "    <div>\n");
    fprintf(file, "      <div class=\"card\">\n");
    fprintf(file, "        <h2>Aufruf</h2>\n");
    fprintf(file, "        <div class=\"meta\" id=\"links\">noch kein Konto gewählt</div>\n");
    fprintf(file, "      </div>\n\n");
    
    fprintf(file, "      <div class=\"card\" style=\"margin-top:12px\">\n");
    fprintf(file, "        <h2>Status</h2>\n");
    fprintf(file, "        <div class=\"meta\" id=\"status\">\n");
    fprintf(file, "          Läuft gerade / seit wann / letzte Sendungen kommen aus dem lokalen Monitor.\n");
    fprintf(file, "          Ohne ihn zeigt diese Seite nur den Player — eine lokale Datei darf im\n");
    fprintf(file, "          Browser keine fremden Server abfragen.\n");
    fprintf(file, "        </div>\n");
    fprintf(file, "        <div class=\"hint\">\n");
    fprintf(file, "          Monitor starten: <code>python server.py --poll-interval 120</code> im\n");
    fprintf(file, "          Projektordner, dann oben <code>http://127.0.0.1:8765</code> eintragen\n");
    fprintf(file, "          und „Anzeigen“ drücken.\n");
    fprintf(file, "        </div>\n");
    fprintf(file, "      </div>\n\n");
    
    fprintf(file, "      <div class=\"card\" style=\"margin-top:12px\">\n");
    fprintf(file, "        <h2>Letzte Sendungen</h2>\n");
    fprintf(file, "        <div class=\"meta\" id=\"streams\">—</div>\n");
    fprintf(file, "      </div>\n");
    fprintf(file, "    </div>\n");
    fprintf(file, "  </div>\n");
    fprintf(file, "</div>\n\n");
}

void write_javascript(FILE *file) {
    fprintf(file, "<script>\n");
    fprintf(file, "const $ = s => document.querySelector(s);\n");
    fprintf(file, "const esc = s => String(s ?? '').replace(/[&<>\"/g, c =>\n");
    fprintf(file, "  ({'&':'&amp;','<':'&lt;','>':'&gt;','\"':'&quot;'}[c]));\n");
    fprintf(file, "const num = n => n == null ? '?' : Number(n).toLocaleString('de-DE');\n");
    fprintf(file, "const clean = s => String(s || '').trim()\n");
    fprintf(file, "  .replace(/^https?:\\/\\/(www\\.)?tiktok\\.com\\/@@?/i, '')\n");
    fprintf(file, "  .replace(/\\/live.*$/i, '').replace(/^@/, '').trim();\n\n");
    
    fprintf(file, "let timer = null;\n\n");
    
    fprintf(file, "function embedUrl(user){\n");
    fprintf(file, "  return 'https://www.tiktok.com/embed/live/@' + encodeURIComponent(user);\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, "/* Player sofort einbetten — ohne jede Statusabfrage. */\n");
    fprintf(file, "function mount(user){\n");
    fprintf(file, "  const holder = $('#player');\n");
    fprintf(file, "  holder.querySelectorAll('iframe').forEach(f => f.remove());\n");
    fprintf(file, "  const f = document.createElement('iframe');\n");
    fprintf(file, "  f.src = embedUrl(user);\n");
    fprintf(file, "  f.allow = 'autoplay; encrypted-media; picture-in-picture; fullscreen';\n");
    fprintf(file, "  f.referrerPolicy = 'origin';\n");
    fprintf(file, "  f.title = 'TikTok Live von @' + user;\n");
    fprintf(file, "  holder.appendChild(f);\n");
    fprintf(file, "  $('#ph').style.display = 'none';\n");
    fprintf(file, "  $('#curUrl').textContent = 'tiktok.com/embed/live/@' + user;\n");
    fprintf(file, "  $('#links').innerHTML =\n");
    fprintf(file, "    '<div class=\"strong\">@' + esc(user) + '</div>' +\n");
    fprintf(file, "    '<div style=\"margin-top:6px\">' +\n");
    fprintf(file, "    '<a href=\"https://www.tiktok.com/@' + esc(user) + '/live\" target=\"_blank\" rel=\"noopener\">Live-Seite</a> · ' +\n");
    fprintf(file, "    '<a href=\"https://www.tiktok.com/@' + esc(user) + '\" target=\"_blank\" rel=\"noopener\">Profil</a> · ' +\n");
    fprintf(file, "    '<a href=\"' + esc(embedUrl(user)) + '\" target=\"_blank\" rel=\"noopener\">Player einzeln</a></div>';\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, "function setBadge(live){\n");
    fprintf(file, "  $('#badge').className = 'badge' + (live === true ? ' live' : '');\n");
    fprintf(file, "  $('#badgeText').textContent = live === true ? 'LIVE'\n");
    fprintf(file, "    : (live === false ? 'offline' : 'Status unbekannt');\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, "/* Status nur, wenn ein Monitor eingetragen ist. */\n");
    fprintf(file, "async function fetchStatus(user){\n");
    fprintf(file, "  const base = $('#api').value.trim().replace(/\\/+$, '');\n");
    fprintf(file, "  if(!base){ setBadge(null); return; }\n");
    fprintf(file, "  try{\n");
    fprintf(file, "    const r = await fetch(base + '/api/tiktok/status?users=' + encodeURIComponent(user),\n");
    fprintf(file, "                          { cache: 'no-store' });\n");
    fprintf(file, "    if(!r.ok) throw new Error('HTTP ' + r.status);\n");
    fprintf(file, "    const d = await r.json();\n");
    fprintf(file, "    const st = (d.accounts || [])[0];\n");
    fprintf(file, "    if(!st) throw new Error('keine Daten');\n");
    fprintf(file, "    render(st);\n");
    fprintf(file, "  }catch(e){\n");
    fprintf(file, "    setBadge(null);\n");
    fprintf(file, "    $('#status').innerHTML = '<span style=\"color:var(--warn)\">Monitor nicht erreichbar (' +\n");
    fprintf(file, "      esc(e.message) + ').</span><br>Der Player oben läuft davon unabhängig weiter.';\n");
    fprintf(file, "  }\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, "function render(st){\n");
    fprintf(file, "  setBadge(st.live);\n");
    fprintf(file, "  $('#checked').textContent = st.checked_at\n");
    fprintf(file, "    ? 'geprüft ' + new Date(st.checked_at).toLocaleTimeString('de-DE') : '';\n");
    fprintf(file, "  $('#status').innerHTML =\n");
    fprintf(file, "    (st.title ? '<div class=\"strong\">' + esc(st.title) + '</div>' : '') +\n");
    fprintf(file, "    (st.started_at ? '<div>Beginn ' + esc(st.started_at.replace('T',' ')) +\n");
    fprintf(file, "      (st.since ? ' · seit ca. ' + esc(st.since) : '') + '</div>' : '') +\n");
    fprintf(file, "    (st.last_seen ? '<div>zuletzt gesehen ' + esc(st.last_seen) + '</div>' : '') +\n");
    fprintf(file, "    (st.streams_total ? '<div>' + num(st.streams_total) + ' Sendungen · ' +\n");
    fprintf(file, "      esc(st.airtime || '') + ' · ' + num(st.active_days) + ' aktive Tage</div>' : '');\n");
    fprintf(file, "  $('#streams').innerHTML = (st.streams || []).length\n");
    fprintf(file, "    ? st.streams.slice(0, 12).map(s =>\n");
    fprintf(file, "        '<div class=\"stream' + (s.is_live ? ' now' : '') + '\">' +\n");
    fprintf(file, "        '<span class=\"when\">' + esc(String(s.day).slice(5)) + ' ' + esc(s.time || '') + '</span>' +\n");
    fprintf(file, "        '<span class=\"t\">' + esc(s.title || '(ohne Titel)') + '</span>' +\n");
    fprintf(file, "        '<span class=\"when\">' + esc(s.duration || '') + '</span></div>').join('')\n");
    fprintf(file, "    : 'keine Daten';\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, "function start(){\n");
    fprintf(file, "  const user = clean($('#user').value);\n");
    fprintf(file, "  if(!user){ $('#user').focus(); return; }\n");
    fprintf(file, "  $('#user').value = user;\n");
    fprintf(file, "  try{\n");
    fprintf(file, "    localStorage.setItem('ttv.user', user);\n");
    fprintf(file, "    localStorage.setItem('ttv.api', $('#api').value.trim());\n");
    fprintf(file, "  }catch(e){}\n");
    fprintf(file, "  mount(user);\n");
    fprintf(file, "  fetchStatus(user);\n");
    fprintf(file, "  if(timer) clearInterval(timer);\n");
    fprintf(file, "  const every = parseInt($('#every').value, 10);\n");
    fprintf(file, "  if(every > 0) timer = setInterval(() => fetchStatus(user), every * 1000);\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, "$('#go').onclick = start;\n");
    fprintf(file, "$('#user').addEventListener('keydown', e => { if(e.key === 'Enter') start(); });\n");
    fprintf(file, "$('#every').addEventListener('change', start);\n");
    fprintf(file, "$('#clear').onclick = () => {\n");
    fprintf(file, "  if(timer) clearInterval(timer);\n");
    fprintf(file, "  document.querySelectorAll('#player iframe').forEach(f => f.remove());\n");
    fprintf(file, "  $('#ph').style.display = '';\n");
    fprintf(file, "  $('#user').value = '';\n");
    fprintf(file, "  $('#links').textContent = 'noch kein Konto gewählt';\n");
    fprintf(file, "  $('#streams').textContent = '—';\n");
    fprintf(file, "  $('#curUrl').textContent = 'tiktok.com/embed/live/@name';\n");
    fprintf(file, "  setBadge(null);\n");
    fprintf(file, "  try{ localStorage.removeItem('ttv.user'); }catch(e){}\n");
    fprintf(file, "  $('#user').focus();\n");
    fprintf(file, "};\n\n");
    
    fprintf(file, "/* Nichts fest eingebaut — nur das zuletzt selbst eingegebene Konto. */\n");
    fprintf(file, "try{\n");
    fprintf(file, "  const savedApi = localStorage.getItem('ttv.api');\n");
    fprintf(file, "  if(savedApi) $('#api').value = savedApi;\n");
    fprintf(file, "  const savedUser = localStorage.getItem('ttv.user');\n");
    fprintf(file, "  if(savedUser){ $('#user').value = savedUser; start(); }\n");
    fprintf(file, "}catch(e){}\n");
    fprintf(file, "</script>\n");
}

void write_html_footer(FILE *file) {
    fprintf(file, "</body>\n");
    fprintf(file, "</html>\n");
}

int main(int argc, char *argv[]) {
    FILE *output_file;
    const char *filename = "TikTok-Live-Viewer.html";
    
    if (argc > 1) {
        filename = argv[1];
    }
    
    output_file = fopen(filename, "w");
    if (output_file == NULL) {
        fprintf(stderr, "Fehler: Kann Datei %s nicht erstellen\n", filename);
        return 1;
    }
    
    write_html_header(output_file);
    write_html_body(output_file);
    write_javascript(output_file);
    write_html_footer(output_file);
    
    fclose(output_file);
    printf("HTML-Datei erfolgreich erstellt: %s\n", filename);
    
    return 0;
}
