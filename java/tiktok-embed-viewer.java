// abstraction-provenance: {"artifact_sha256": "7913b8df24e55410add2deaf72c0e449ab43df149aabfcce47fbc2cd476e70a5", "source_sha256": "acf0fac539f0a8aaf291ce2cdb6ca15cda4a6a1087f02b8e0c2854bd81fa82b3", "target_language": "java"}
// tiktok-embed-viewer.html — portiert nach java
// Quelle: html, Projects@Telegram-Monitor:plugin/tiktok-embed-viewer.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

import java.io.*;
import java.nio.charset.StandardCharsets;
import java.util.*;

public class TikTokEmbedViewer {
    
    public static void main(String[] args) {
        if (args.length != 1) {
            System.err.println("Usage: java TikTokEmbedViewer <output-file>");
            System.exit(1);
        }
        
        String outputFile = args[0];
        
        try {
            String htmlContent = generateHtml();
            writeToFile(htmlContent, outputFile);
            System.out.println("HTML file generated successfully: " + outputFile);
        } catch (IOException e) {
            System.err.println("Error generating HTML file: " + e.getMessage());
            System.exit(1);
        }
    }
    
    private static String generateHtml() {
        StringBuilder html = new StringBuilder();
        
        // DOCTYPE and html tag
        html.append("<!DOCTYPE html>\n");
        html.append("<html lang=\"de\">\n");
        html.append("<head>\n");
        html.append("<meta charset=\"utf-8\">\n");
        html.append("<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n");
        html.append("<title>TikTok Live — Embed-Viewer</title>\n");
        html.append("<style>\n");
        html.append("  :root{\n");
        html.append("    --bg:#0f1115; --card:#171a21; --line:#262b36; --text:#f2f4f8; --muted:#9aa3b2;\n");
        html.append("    --accent:#25f4ee; --accent2:#fe2c55; --ok:#22c55e; --off:#6b7280;\n");
        html.append("    color-scheme: dark;\n");
        html.append("  }\n");
        html.append("  @media (prefers-color-scheme: light){\n");
        html.append("    :root{ --bg:#f6f7f9; --card:#fff; --line:#e3e6ea; --text:#16191d; --muted:#6b7280; }\n");
        html.append("  }\n");
        html.append("  *{box-sizing:border-box}\n");
        html.append("  body{margin:0;background:var(--bg);color:var(--text);\n");
        html.append("       font:15px/1.5 -apple-system,BlinkMacSystemFont,\"Segoe UI\",Roboto,sans-serif}\n");
        html.append("  .wrap{max-width:1120px;margin:0 auto;padding:16px}\n");
        html.append("  header{display:flex;gap:12px;align-items:center;flex-wrap:wrap;margin-bottom:14px}\n");
        html.append("  h1{font-size:17px;margin:0;font-weight:650}\n");
        html.append("  .badge{display:inline-flex;align-items:center;gap:6px;font-size:12px;font-weight:700;\n");
        html.append("         padding:3px 10px;border-radius:99px;background:#2a2f3a;color:var(--muted)}\n");
        html.append("  .badge.live{background:var(--accent2);color:#fff}\n");
        html.append("  .badge .dot{width:7px;height:7px;border-radius:50%;background:currentColor}\n");
        html.append("  .badge.live .dot{animation:pulse 1.6s infinite}\n");
        html.append("  @keyframes pulse{0%,100%{opacity:1}50%{opacity:.25}}\n");
        html.append("  input,select,button{font:inherit;border-radius:8px;border:1px solid var(--line);\n");
        html.append("                      background:var(--card);color:var(--text);padding:8px 11px}\n");
        html.append("  button{cursor:pointer;font-weight:600}\n");
        html.append("  button.primary{background:var(--accent2);border-color:var(--accent2);color:#fff}\n");
        html.append("  .row{display:flex;gap:8px;flex-wrap:wrap;align-items:center;margin-bottom:12px}\n");
        html.append("  .grid{display:grid;grid-template-columns:minmax(0,2fr) minmax(260px,1fr);gap:14px}\n");
        html.append("  @media (max-width:860px){ .grid{grid-template-columns:1fr} }\n");
        html.append("  .card{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:14px}\n");
        html.append("  .player{position:relative;width:100%;aspect-ratio:9/16;max-height:78vh;background:#000;\n");
        html.append("          border-radius:12px;overflow:hidden;border:1px solid var(--line)}\n");
        html.append("  .player iframe{position:absolute;inset:0;width:100%;height:100%;border:0}\n");
        html.append("  .placeholder{position:absolute;inset:0;display:flex;flex-direction:column;gap:8px;\n");
        html.append("               align-items:center;justify-content:center;color:var(--muted);text-align:center;padding:24px}\n");
        html.append("  h2{font-size:12px;text-transform:uppercase;letter-spacing:.05em;color:var(--muted);\n");
        html.append("     margin:0 0 8px;font-weight:650}\n");
        html.append("  .meta{color:var(--muted);font-size:13px}\n");
        html.append("  .stream{display:flex;gap:10px;padding:7px 0;border-bottom:1px solid var(--line);font-size:13.5px}\n");
        html.append("  .stream:last-child{border-bottom:0}\n");
        html.append("  .stream .when{color:var(--muted);white-space:nowrap;font-variant-numeric:tabular-nums}\n");
        html.append("  .stream .t{flex:1;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}\n");
        html.append("  .stream.now{color:var(--accent2);font-weight:650}\n");
        html.append("  .note{font-size:12.5px;color:var(--muted);margin-top:10px;line-height:1.45}\n");
        html.append("  a{color:var(--accent2)} a:hover{text-decoration:underline}\n");
        html.append("  .err{background:#3a1d22;border:1px solid #5c2a33;color:#ffb4c0;padding:9px 12px;\n");
        html.append("       border-radius:8px;font-size:13px;margin-bottom:10px}\n");
        html.append("  @media (prefers-color-scheme: light){ .err{background:#fdeceb;border-color:#f5c6c2;color:#b91c1c} }\n");
        html.append("</style>\n");
        html.append("</head>\n");
        html.append("<body>\n");
        html.append("<div class=\"wrap\">\n");
        html.append("  <header>\n");
        html.append("    <h1>TikTok Live — Embed-Viewer</h1>\n");
        html.append("    <span class=\"badge\" id=\"badge\"><span class=\"dot\"></span><span id=\"badgeText\">unbekannt</span></span>\n");
        html.append("    <span class=\"meta\" id=\"checked\"></span>\n");
        html.append("  </header>\n\n");
        html.append("  <div class=\"row\">\n");
        html.append("    <input id=\"user\" placeholder=\"@name\" style=\"min-width:180px\">\n");
        html.append("    <button class=\"primary\" id=\"go\">Anzeigen</button>\n");
        html.append("    <select id=\"every\">\n");
        html.append("      <option value=\"60\">Status alle 60 s</option>\n");
        html.append("      <option value=\"120\" selected>alle 2 min</option>\n");
        html.append("      <option value=\"300\">alle 5 min</option>\n");
        html.append("      <option value=\"0\">nur manuell</option>\n");
        html.append("    </select>\n");
        html.append("    <label class=\"meta\"><input type=\"checkbox\" id=\"notify\"> bei Livegang benachrichtigen</label>\n");
        html.append("    <label class=\"meta\"><input type=\"checkbox\" id=\"autoplay\" checked> Player automatisch laden</label>\n");
        html.append("    <button id=\"force\">Player trotzdem laden</button>\n");
        html.append("  </div>\n\n");
        html.append("  <div id=\"error\"></div>\n\n");
        html.append("  <div class=\"grid\">\n");
        html.append("    <div>\n");
        html.append("      <div class=\"player\" id=\"player\">\n");
        html.append("        <div class=\"placeholder\" id=\"placeholder\">\n");
        html.append("          <div style=\"font-size:34px\">📺</div>\n");
        html.append("          <div id=\"phText\">Konto eingeben und „Anzeigen“ drücken.</div>\n");
        html.append("        </div>\n");
        html.append("      </div>\n");
        html.append("      <p class=\"note\">\n");
        html.append("        Eingebettet wird der offizielle TikTok-Live-Player\n");
        html.append("        (<code>tiktok.com/embed/live/@name</code>). Er ist auf reines Zuschauen\n");
        html.append("        ausgelegt: <b>keine Anmeldung, keine Geschenk- oder Kauf-Oberfläche</b>.\n");
        html.append("        Damit entfallen die kostenpflichtigen Aktionen, die im normalen Frontend\n");
        html.append("        erreichbar wären — brauchbar für Mitschauen ohne Konto und ohne Kaufrisiko.\n");
        html.append("      </p>\n");
        html.append("    </div>\n\n");
        html.append("    <div>\n");
        html.append("      <div class=\"card\">\n");
        html.append("        <h2>Status</h2>\n");
        html.append("        <div id=\"status\" class=\"meta\">—</div>\n");
        html.append("      </div>\n");
        html.append("      <div class=\"card\" style=\"margin-top:12px\">\n");
        html.append("        <h2>Letzte Sendungen</h2>\n");
        html.append("        <div id=\"streams\" class=\"meta\">—</div>\n");
        html.append("      </div>\n");
        html.append("      <div class=\"card\" style=\"margin-top:12px\">\n");
        html.append("        <h2>Datenquelle</h2>\n");
        html.append("        <div class=\"meta\" id=\"source\">\n");
        html.append("          Statusdaten über den lokalen Monitor\n");
        html.append("          (<code>/api/tiktok/status</code>) oder direkt von der öffentlichen\n");
        html.append("          Profilseite eines Aufzeichnungsdienstes. Kein Konto, keine Umgehung\n");
        html.append("          von Zugangskontrollen.\n");
        html.append("        </div>\n");
        html.append("      </div>\n");
        html.append("    </div>\n");
        html.append("  </div>\n");
        html.append("</div>\n\n");
        html.append("<script src=\"./tiktok-companion.js\"></script>\n");
        html.append("<script>\n");
        html.append("  // Standalone-Betrieb: Parameter aus der URL (?user=creator&api=http://127.0.0.1:8765)\n");
        html.append("  const params = new URLSearchParams(location.search);\n");
        html.append("  window.TTC = new TikTokCompanion({\n");
        html.append("    apiBase: params.get('api') || 'http://127.0.0.1:8765',\n");
        html.append("    onState: renderState,\n");
        html.append("    onError: msg => {\n");
        html.append("      const box = document.getElementById('error');\n");
        html.append("      if(!msg){ box.innerHTML = ''; return; }\n");
        html.append("      const local = location.protocol === 'file:';\n");
        html.append("      box.innerHTML = '<div class=\"err\"><b>Status nicht abrufbar.</b><br>' + esc(msg) +\n");
        html.append("        '<br><br>Der Browser lässt aus dieser Seite heraus keinen direkten Abruf ' +\n");
        html.append("        (local ? ' (lokale Datei, Herkunft „null“)' : '') + '. Zwei Wege:' +\n");
        html.append("        '<br>• <b>Monitor starten</b> — im Projektordner <code>python server.py</code>, ' +\n");
        html.append("        'dann hier neu laden. Er liefert den Status und erlaubt den Zugriff ausdrücklich.' +\n");
        html.append("        '<br>• <b>Als Erweiterung laden</b> — mit <code>host_permissions</code> für ' +\n");
        html.append("        '<code>streamrecorder.io</code>, siehe plugin/README.md.' +\n");
        html.append("        '<br><br>Der Player unten funktioniert unabhängig davon: „Player trotzdem laden“.</div>';\n");
        html.append("    }\n");
        html.append("  });\n\n");
        html.append("  const $ = s => document.querySelector(s);\n");
        html.append("  const esc = s => String(s ?? '').replace(/[&<>]/g, c =>\n");
        html.append("    ({'&':'&amp;','<':'&lt;','>':'&gt;','\"':'&quot;'}[c]));\n\n");
        html.append("  function renderState(st){\n");
        html.append("    const live = st.live === true;\n");
        html.append("    $('#badge').className = 'badge' + (live ? ' live' : '');\n");
        html.append("    $('#badgeText').textContent = live ? 'LIVE' : (st.live === false ? 'offline' : 'unbekannt');\n");
        html.append("    $('#checked').textContent = st.checked_at\n");
        html.append("      ? 'geprüft ' + new Date(st.checked_at).toLocaleTimeString('de-DE') : '';\n\n");
        html.append("    $('#status').innerHTML =\n");
        html.append("      (st.title ? '<div style=\"color:var(--text);font-weight:600\">' + esc(st.title) + '</div>' : '') +\n");
        html.append("      (st.started_at ? '<div>Beginn ' + esc(st.started_at.replace('T', ' ')) +\n");
        html.append("        (st.since ? ' · seit ca. ' + esc(st.since) : '') + '</div>' : '') +\n");
        html.append("      (st.last_seen ? '<div>zuletzt gesehen ' + esc(st.last_seen) + '</div>' : '') +\n");
        html.append("      (st.streams_total ? '<div>' + st.streams_total + ' Sendungen · ' +\n");
        html.append("        esc(st.airtime || '') + ' Sendezeit · ' + (st.active_days || '?') + ' aktive Tage</div>' : '') +\n");
        html.append("      '<div style=\"margin-top:8px\"><a href=\"' + esc(st.profile_url || '#') +\n");
        html.append("        '\" target=\"_blank\" rel=\"noopener\">Profil</a> · <a href=\"' +\n");
        html.append("        esc(st.live_url || '#') + '\" target=\"_blank\" rel=\"noopener\">Live-Seite</a></div>';\n\n");
        html.append("    $('#streams').innerHTML = (st.streams || []).length\n");
        html.append("      ? st.streams.slice(0, 10).map(s =>\n");
        html.append("          '<div class=\"stream' + (s.is_live ? ' now' : '') + '\">' +\n");
        html.append("          '<span class=\"when\">' + esc(s.day.slice(5)) + ' ' + esc(s.time || '') + '</span>' +\n");
        html.append("          '<span class=\"t\">' + esc(s.title || '(ohne Titel)') + '</span>' +\n");
        html.append("          '<span class=\"when\">' + esc(s.duration || '') + '</span></div>').join('')\n");
        html.append("      : 'keine Daten';\n\n");
        html.append("    const wantPlayer = live && $('#autoplay').checked;\n");
        html.append("    const holder = $('#player');\n");
        html.append("    if(wantPlayer && !holder.querySelector('iframe')){\n");
        html.append("      const f = document.createElement('iframe');\n");
        html.append("      f.src = st.embed_url;\n");
        html.append("      f.allow = 'autoplay; encrypted-media; picture-in-picture';\n");
        html.append("      f.referrerPolicy = 'origin';\n");
        html.append("      f.title = 'TikTok Live von @' + st.username;\n");
        html.append("      holder.appendChild(f);\n");
        html.append("      $('#placeholder').style.display = 'none';\n");
        html.append("    } else if(!live){\n");
        html.append("      holder.querySelectorAll('iframe').forEach(f => f.remove());\n");
        html.append("      $('#placeholder').style.display = '';\n");
        html.append("      $('#phText').textContent = st.username\n");
        html.append("        ? '@' + st.username + ' ist gerade offline.'\n");
        html.append("        : 'Konto eingeben und „Anzeigen“ drücken.';\n");
        html.append("    }\n");
        html.append("  }\n\n");
        html.append("  $('#go').onclick = () => {\n");
        html.append("    const u = $('#user').value.trim().replace(/^@/, '');\n");
        html.append("    if(!u) return;\n");
        html.append("    document.querySelectorAll('#player iframe').forEach(f => f.remove());\n");
        html.append("    localStorage.setItem('ttc.user', u);\n");
        html.append("    window.TTC.watch(u, parseInt($('#every').value, 10));\n");
        html.append("  };\n");
        html.append("  $('#user').addEventListener('keydown', e => { if(e.key === 'Enter') $('#go').click(); });\n");
        html.append("  $('#force').onclick = () => {\n");
        html.append("    const u = $('#user').value.trim().replace(/^@/, '');\n");
        html.append("    if(!u) return;\n");
        html.append("    const holder = $('#player');\n");
        html.append("    holder.querySelectorAll('iframe').forEach(f => f.remove());\n");
        html.append("    const f = document.createElement('iframe');\n");
        html.append("    f.src = TikTokCompanion.embedUrl(u);\n");
        html.append("    f.allow = 'autoplay; encrypted-media; picture-in-picture';\n");
        html.append("    f.referrerPolicy = 'origin';\n");
        html.append("    f.title = 'TikTok Live von @' + u;\n");
        html.append("    holder.appendChild(f);\n");
        html.append("    $('#placeholder').style.display = 'none';\n");
        html.append("  };\n");
        html.append("  $('#every').addEventListener('change', () => $('#go').click());\n");
        html.append("  $('#notify').addEventListener('change', async e => {\n");
        html.append("    window.TTC.notifyOnLive = e.target.checked;\n");
        html.append("    if(e.target.checked && 'Notification' in window && Notification.permission === 'default'){\n");
        html.append("      await Notification.requestPermission();\n");
        html.append("    }\n");
        html.append("  });\n\n");
        html.append("  const saved = params.get('user') || localStorage.getItem('ttc.user');\n");
        html.append("  if(saved){ $('#user').value = saved; $('#go').click(); }\n");
        html.append("</script>\n");
        html.append("</body>\n");
        html.append("</html>\n");
        
        return html.toString();
    }
    
    private static void writeToFile(String content, String filename) throws IOException {
        try (BufferedWriter writer = new BufferedWriter(new OutputStreamWriter(
                new FileOutputStream(filename), StandardCharsets.UTF_8))) {
            writer.write(content);
        }
    }
}
