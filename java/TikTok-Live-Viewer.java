// abstraction-provenance: {"artifact_sha256": "632bfb5f2cf0cc0184d459c6bc4072648ddc2b17a1e197e4c2e4268cdfb90df1", "source_sha256": "83117e76f05b08bc4554d3f4feb0f928c62429bbccc6f556ec336643a33b2a1a", "target_language": "java"}
// TikTok-Live-Viewer.html — portiert nach java
// Quelle: html, Projects@Telegram-Monitor:TikTok-Live-Viewer.html
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import java.io.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.regex.Pattern;

public class TikTokLiveViewer {
    
    public static void main(String[] args) {
        if (args.length != 1) {
            System.err.println("Verwendung: java TikTokLiveViewer <ausgabedatei>");
            System.exit(1);
        }
        
        String outputFile = args[0];
        
        try {
            String htmlContent = generateHTML();
            Files.write(Paths.get(outputFile), htmlContent.getBytes(StandardCharsets.UTF_8));
            System.out.println("HTML-Datei erfolgreich erstellt: " + outputFile);
        } catch (IOException e) {
            System.err.println("Fehler beim Schreiben der Datei: " + e.getMessage());
            System.exit(1);
        }
    }
    
    private static String generateHTML() {
        StringBuilder html = new StringBuilder();
        
        // DOCTYPE und HTML-Grundstruktur
        html.append("<!DOCTYPE html>\n");
        html.append("<html lang=\"de\">\n");
        html.append("<head>\n");
        html.append("<meta charset=\"utf-8\">\n");
        html.append("<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n");
        html.append("<title>TikTok Live Companion — Viewer</title>\n");
        
        // CSS Styles
        appendStyles(html);
        
        html.append("</head>\n");
        html.append("<body>\n");
        
        // Hauptinhalt
        appendBodyContent(html);
        
        // JavaScript
        appendJavaScript(html);
        
        html.append("</body>\n");
        html.append("</html>\n");
        
        return html.toString();
    }
    
    private static void appendStyles(StringBuilder html) {
        html.append("<style>\n");
        html.append("  :root{\n");
        html.append("    --bg:#0f1115; --card:#171a21; --line:#262b36; --text:#f2f4f8; --muted:#9aa3b2;\n");
        html.append("    --tt:#fe2c55; --ok:#22c55e; --warn:#f59e0b;\n");
        html.append("    color-scheme: dark;\n");
        html.append("  }\n");
        html.append("  @media (prefers-color-scheme: light){\n");
        html.append("    :root{ --bg:#f6f7f9; --card:#fff; --line:#e3e6ea; --text:#16191d; --muted:#6b7280; }\n");
        html.append("  }\n");
        html.append("  *{box-sizing:border-box}\n");
        html.append("  body{margin:0;background:var(--bg);color:var(--text);\n");
        html.append("       font:15px/1.5 -apple-system,BlinkMacSystemFont,\"Segoe UI\",Roboto,sans-serif}\n");
        html.append("  .wrap{max-width:1180px;margin:0 auto;padding:16px}\n");
        html.append("  header{display:flex;gap:12px;align-items:center;flex-wrap:wrap;margin-bottom:12px}\n");
        html.append("  h1{font-size:17px;margin:0;font-weight:650}\n");
        html.append("  .badge{display:inline-flex;align-items:center;gap:6px;font-size:11.5px;font-weight:700;\n");
        html.append("         padding:3px 10px;border-radius:99px;background:#2a2f3a;color:var(--muted)}\n");
        html.append("  .badge.live{background:var(--tt);color:#fff}\n");
        html.append("  .badge .dot{width:6px;height:6px;border-radius:50%;background:currentColor}\n");
        html.append("  .badge.live .dot{animation:pulse 1.6s infinite}\n");
        html.append("  @keyframes pulse{0%,100%{opacity:1}50%{opacity:.25}}\n");
        html.append("  input,select,button{font:inherit;border-radius:8px;border:1px solid var(--line);\n");
        html.append("                      background:var(--card);color:var(--text);padding:9px 12px}\n");
        html.append("  input{min-width:220px}\n");
        html.append("  button{cursor:pointer;font-weight:600}\n");
        html.append("  button.primary{background:var(--tt);border-color:var(--tt);color:#fff}\n");
        html.append("  .row{display:flex;gap:8px;flex-wrap:wrap;align-items:center;margin-bottom:10px}\n");
        html.append("  .grid{display:grid;grid-template-columns:minmax(0,2fr) minmax(280px,1fr);gap:14px}\n");
        html.append("  @media (max-width:900px){ .grid{grid-template-columns:1fr} }\n");
        html.append("  .card{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:14px}\n");
        html.append("  .player{position:relative;width:100%;aspect-ratio:9/16;max-height:80vh;background:#000;\n");
        html.append("          border-radius:12px;overflow:hidden;border:1px solid var(--line)}\n");
        html.append("  .player iframe{position:absolute;inset:0;width:100%;height:100%;border:0}\n");
        html.append("  .ph{position:absolute;inset:0;display:flex;flex-direction:column;gap:10px;\n");
        html.append("      align-items:center;justify-content:center;color:var(--muted);text-align:center;padding:26px}\n");
        html.append("  h2{font-size:11.5px;text-transform:uppercase;letter-spacing:.05em;color:var(--muted);\n");
        html.append("     margin:0 0 8px;font-weight:650}\n");
        html.append("  .meta{color:var(--muted);font-size:13px}\n");
        html.append("  .strong{color:var(--text);font-weight:600}\n");
        html.append("  .stream{display:flex;gap:10px;padding:6px 0;border-bottom:1px solid var(--line);font-size:13px}\n");
        html.append("  .stream:last-child{border-bottom:0}\n");
        html.append("  .stream .when{color:var(--muted);white-space:nowrap;font-variant-numeric:tabular-nums}\n");
        html.append("  .stream .t{flex:1;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}\n");
        html.append("  .stream.now{color:var(--tt);font-weight:650}\n");
        html.append("  .hint{font-size:12.5px;color:var(--muted);line-height:1.45;margin-top:10px}\n");
        html.append("  a{color:var(--tt)} a:hover{text-decoration:underline}\n");
        html.append("  code{background:rgba(127,127,127,.15);padding:1px 5px;border-radius:4px;font-size:12.5px;\n");
        html.append("       font-family:ui-monospace,SFMono-Regular,Menlo,monospace}\n");
        html.append("</style>\n");
    }
    
    private static void appendBodyContent(StringBuilder html) {
        html.append("<div class=\"wrap\">\n");
        html.append("  <header>\n");
        html.append("    <h1>TikTok Live Companion — Viewer</h1>\n");
        html.append("    <span class=\"badge\" id=\"badge\"><span class=\"dot\"></span><span id=\"badgeText\">bereit</span></span>\n");
        html.append("    <span class=\"meta\" id=\"checked\"></span>\n");
        html.append("  </header>\n");
        html.append("\n");
        html.append("  <div class=\"row\">\n");
        html.append("    <input id=\"user\" placeholder=\"@name eingeben — beliebiges öffentliches Konto\" autofocus>\n");
        html.append("    <button class=\"primary\" id=\"go\">Anzeigen</button>\n");
        html.append("    <button id=\"clear\">Leeren</button>\n");
        html.append("    <select id=\"every\">\n");
        html.append("      <option value=\"0\" selected>Status: nur manuell</option>\n");
        html.append("      <option value=\"60\">Status alle 60 s</option>\n");
        html.append("      <option value=\"120\">alle 2 min</option>\n");
        html.append("      <option value=\"300\">alle 5 min</option>\n");
        html.append("    </select>\n");
        html.append("    <input id=\"api\" value=\"http://127.0.0.1:8765\" placeholder=\"Monitor-Adresse\" style=\"min-width:250px\">\n");
        html.append("  </div>\n");
        html.append("\n");
        html.append("  <div class=\"grid\">\n");
        html.append("    <div>\n");
        html.append("      <div class=\"player\" id=\"player\">\n");
        html.append("        <div class=\"ph\" id=\"ph\">\n");
        html.append("          <div style=\"font-size:34px\">📺</div>\n");
        html.append("          <div id=\"phText\">Namen eintragen und „Anzeigen“ drücken —<br>der Player startet sofort.</div>\n");
        html.append("        </div>\n");
        html.append("      </div>\n");
        html.append("      <p class=\"hint\">\n");
        html.append("        Eingebettet wird der offizielle TikTok-Live-Player\n");
        html.append("        <code id=\"curUrl\">tiktok.com/embed/live/@name</code> — <b>keine Anmeldung,\n");
        html.append("        keine Geschenk- oder Kauf-Oberfläche</b>. Ist das Konto offline, zeigt der\n");
        html.append("        Rahmen eine Fehlerseite von TikTok; das ist das Offline-Zeichen.\n");
        html.append("      </p>\n");
        html.append("    </div>\n");
        html.append("\n");
        html.append("    <div>\n");
        html.append("      <div class=\"card\">\n");
        html.append("        <h2>Aufruf</h2>\n");
        html.append("        <div class=\"meta\" id=\"links\">noch kein Konto gewählt</div>\n");
        html.append("      </div>\n");
        html.append("\n");
        html.append("      <div class=\"card\" style=\"margin-top:12px\">\n");
        html.append("        <h2>Status</h2>\n");
        html.append("        <div class=\"meta\" id=\"status\">\n");
        html.append("          Läuft gerade / seit wann / letzte Sendungen kommen aus dem lokalen Monitor.\n");
        html.append("          Ohne ihn zeigt diese Seite nur den Player — eine lokale Datei darf im\n");
        html.append("          Browser keine fremden Server abfragen.\n");
        html.append("        </div>\n");
        html.append("        <div class=\"hint\">\n");
        html.append("          Monitor starten: <code>python server.py --poll-interval 120</code> im\n");
        html.append("          Projektordner, dann oben <code>http://127.0.0.1:8765</code> eintragen\n");
        html.append("          und „Anzeigen“ drücken.\n");
        html.append("        </div>\n");
        html.append("      </div>\n");
        html.append("\n");
        html.append("      <div class=\"card\" style=\"margin-top:12px\">\n");
        html.append("        <h2>Letzte Sendungen</h2>\n");
        html.append("        <div class=\"meta\" id=\"streams\">—</div>\n");
        html.append("      </div>\n");
        html.append("    </div>\n");
        html.append("  </div>\n");
        html.append("</div>\n");
    }
    
    private static void appendJavaScript(StringBuilder html) {
        html.append("<script>\n");
        html.append("const $ = s => document.querySelector(s);\n");
        html.append("const esc = s => String(s ?? '').replace(/[&<>\"].*/g, c =>\n");
        html.append("  ({'&':'&amp;','<':'&lt;','>':'&gt;','\"':'&quot;'}[c]));\n");
        html.append("const num = n => n == null ? '?' : Number(n).toLocaleString('de-DE');\n");
        html.append("const clean = s => String(s || '').trim()\n");
        html.append("  .replace(/^https?:\\/\\/(www\\.)?tiktok\\.com\\/@@?/i, '')\n");
        html.append("  .replace(/\\/live.*$/i, '').replace(/^@@/, '').trim();\n");
        html.append("\n");
        html.append("let timer = null;\n");
        html.append("\n");
        html.append("function embedUrl(user){\n");
        html.append("  return 'https://www.tiktok.com/embed/live/@' + encodeURIComponent(user);\n");
        html.append("}\n");
        html.append("\n");
        html.append("/* Player sofort einbetten — ohne jede Statusabfrage. */\n");
        html.append("function mount(user){\n");
        html.append("  const holder = $('#player');\n");
        html.append("  holder.querySelectorAll('iframe').forEach(f => f.remove());\n");
        html.append("  const f = document.createElement('iframe');\n");
        html.append("  f.src = embedUrl(user);\n");
        html.append("  f.allow = 'autoplay; encrypted-media; picture-in-picture; fullscreen';\n");
        html.append("  f.referrerPolicy = 'origin';\n");
        html.append("  f.title = 'TikTok Live von @' + user;\n");
        html.append("  holder.appendChild(f);\n");
        html.append("  $('#ph').style.display = 'none';\n");
        html.append("  $('#curUrl').textContent = 'tiktok.com/embed/live/@' + user;\n");
        html.append("  $('#links').innerHTML =\n");
        html.append("    '<div class=\"strong\">@' + esc(user) + '</div>' +\n");
        html.append("    '<div style=\"margin-top:6px\">' +\n");
        html.append("    '<a href=\"https://www.tiktok.com/@' + esc(user) + '/live\" target=\"_blank\" rel=\"noopener\">Live-Seite</a> · ' +\n");
        html.append("    '<a href=\"https://www.tiktok.com/@' + esc(user) + '\" target=\"_blank\" rel=\"noopener\">Profil</a> · ' +\n");
        html.append("    '<a href=\"' + esc(embedUrl(user)) + '\" target=\"_blank\" rel=\"noopener\">Player einzeln</a></div>';\n");
        html.append("}\n");
        html.append("\n");
        html.append("function setBadge(live){\n");
        html.append("  $('#badge').className = 'badge' + (live === true ? ' live' : '');\n");
        html.append("  $('#badgeText').textContent = live === true ? 'LIVE'\n");
        html.append("    : (live === false ? 'offline' : 'Status unbekannt');\n");
        html.append("}\n");
        html.append("\n");
        html.append("/* Status nur, wenn ein Monitor eingetragen ist. */\n");
        html.append("async function fetchStatus(user){\n");
        html.append("  const base = $('#api').value.trim().replace(/\\/\\/+$/, '');\n");
        html.append("  if(!base){ setBadge(null); return; }\n");
        html.append("  try{\n");
        html.append("    const r = await fetch(base + '/api/tiktok/status?users=' + encodeURIComponent(user),\n");
        html.append("                          { cache: 'no-store' });\n");
        html.append("    if(!r.ok) throw new Error('HTTP ' + r.status);\n");
        html.append("    const d = await r.json();\n");
        html.append("    const st = (d.accounts || [])[0];\n");
        html.append("    if(!st) throw new Error('keine Daten');\n");
        html.append("    render(st);\n");
        html.append("  }catch(e){\n");
        html.append("    setBadge(null);\n");
        html.append("    $('#status').innerHTML = '<span style=\"color:var(--warn)\">Monitor nicht erreichbar (' +\n");
        html.append("      esc(e.message) + ').</span><br>Der Player oben läuft davon unabhängig weiter.';\n");
        html.append("  }\n");
        html.append("}\n");
        html.append("\n");
        html.append("function render(st){\n");
        html.append("  setBadge(st.live);\n");
        html.append("  $('#checked').textContent = st.checked_at\n");
        html.append("    ? 'geprüft ' + new Date(st.checked_at).toLocaleTimeString('de-DE') : '';\n");
        html.append("  $('#status').innerHTML =\n");
        html.append("    (st.title ? '<div class=\"strong\">' + esc(st.title) + '</div>' : '') +\n");
        html.append("    (st.started_at ? '<div>Beginn ' + esc(st.started_at.replace('T',' ')) +\n");
        html.append("      (st.since ? ' · seit ca. ' + esc(st.since) : '') + '</div>' : '') +\n");
        html.append("    (st.last_seen ? '<div>zuletzt gesehen ' + esc(st.last_seen) + '</div>' : '') +\n");
        html.append("    (st.streams_total ? '<div>' + num(st.streams_total) + ' Sendungen · ' +\n");
        html.append("      esc(st.airtime || '') + ' · ' + num(st.active_days) + ' aktive Tage</div>' : '');\n");
        html.append("  $('#streams').innerHTML = (st.streams || []).length\n");
        html.append("    ? st.streams.slice(0, 12).map(s =>\n");
        html.append("        '<div class=\"stream' + (s.is_live ? ' now' : '') + '\">');\n");
        html.append("}</script>\n");
    }
}
