#!/usr/bin/env tclsh
# popup.html — portiert nach tcl
# Quelle: html, Projects@Telegram-Monitor:plugin/extension/popup.html
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

# Tcl/Tk port of popup.html
# Generates the HTML structure programmatically

proc generatePopup {} {
    set html {}

    # Start with DOCTYPE and html tag
    append html "<!DOCTYPE html>\n"
    append html "<html lang=\"de\">\n"
    append html "<head>\n"
    append html "<meta charset=\"utf-8\">\n"
    append html "<title>TikTok Live Companion</title>\n"
    
    # Add CSS styles
    append html "<style>\n"
    append html "  :root{\n"
    append html "    --bg:#0f1115; --card:#171a21; --line:#262b36; --text:#f2f4f8; --muted:#9aa3b2;\n"
    append html "    --accent:#fe2c55; --ok:#22c55e;\n"
    append html "    color-scheme: dark;\n"
    append html "  }\n"
    append html "  @media (prefers-color-scheme: light){\n"
    append html "    :root{ --bg:#fff; --card:#f6f7f9; --line:#e3e6ea; --text:#16191d; --muted:#6b7280; }\n"
    append html "  }\n"
    append html "  *{box-sizing:border-box}\n"
    append html "  body{margin:0;width:420px;max-height:600px;overflow:auto;background:var(--bg);color:var(--text);\n"
    append html "       font:14px/1.45 -apple-system,BlinkMacSystemFont,\"Segoe UI\",Roboto,sans-serif}\n"
    append html "  .wrap{padding:12px}\n"
    append html "  header{display:flex;gap:8px;align-items:center;margin-bottom:10px}\n"
    append html "  h1{font-size:14px;margin:0;font-weight:650;flex:1}\n"
    append html "  .badge{font-size:11px;font-weight:700;padding:3px 9px;border-radius:99px;\n"
    append html "         background:#2a2f3a;color:var(--muted);display:inline-flex;align-items:center;gap:5px}\n"
    append html "  .badge.live{background:var(--accent);color:#fff}\n"
    append html "  .badge .dot{width:6px;height:6px;border-radius:50%;background:currentColor}\n"
    append html "  .badge.live .dot{animation:pulse 1.6s infinite}\n"
    append html "  @keyframes pulse{0%,100%{opacity:1}50%{opacity:.25}}\n"
    append html "  .row{display:flex;gap:6px;flex-wrap:wrap;align-items:center;margin-bottom:8px}\n"
    append html "  input,select,button{font:inherit;border-radius:7px;border:1px solid var(--line);\n"
    append html "                      background:var(--card);color:var(--text);padding:6px 9px}\n"
    append html "  button{cursor:pointer;font-weight:600}\n"
    append html "  button.primary{background:var(--accent);border-color:var(--accent);color:#fff}\n"
    append html "  .player{position:relative;width:100%;aspect-ratio:9/16;max-height:360px;background:#000;\n"
    append html "          border-radius:10px;overflow:hidden;border:1px solid var(--line);margin:8px 0}\n"
    append html "  .player iframe{position:absolute;inset:0;width:100%;height:100%;border:0}\n"
    append html "  .placeholder{position:absolute;inset:0;display:flex;flex-direction:column;gap:6px;\n"
    append html "               align-items:center;justify-content:center;color:var(--muted);\n"
    append html "               text-align:center;padding:16px;font-size:13px}\n"
    append html "  .card{background:var(--card);border:1px solid var(--line);border-radius:10px;\n"
    append html "        padding:10px 12px;margin-bottom:8px}\n"
    append html "  h2{font-size:11px;text-transform:uppercase;letter-spacing:.05em;color:var(--muted);\n"
    append html "     margin:0 0 6px;font-weight:650}\n"
    append html "  .meta{color:var(--muted);font-size:12.5px}\n"
    append html "  .strong{color:var(--text);font-weight:600}\n"
    append html "  .stream{display:flex;gap:8px;padding:5px 0;border-bottom:1px solid var(--line);font-size:12.5px}\n"
    append html "  .stream:last-child{border-bottom:0}\n"
    append html "  .stream .when{color:var(--muted);white-space:nowrap;font-variant-numeric:tabular-nums}\n"
    append html "  .stream .t{flex:1;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}\n"
    append html "  .stream.now{color:var(--accent);font-weight:650}\n"
    append html "  .err{background:#3a1d22;border:1px solid #5c2a33;color:#ffb4c0;padding:8px 10px;\n"
    append html "       border-radius:8px;font-size:12.5px;margin-bottom:8px}\n"
    append html "  @media (prefers-color-scheme: light){ .err{background:#fdeceb;border-color:#f5c6c2;color:#b91c1c} }\n"
    append html "  .note{font-size:11.5px;color:var(--muted);line-height:1.4;margin-top:8px}\n"
    append html "  a{color:var(--accent)}\n"
    append html "</style>\n"
    append html "</head>\n"
    append html "<body>\n"
    append html "<div class=\"wrap\">\n"
    append html "  <header>\n"
    append html "    <h1>TikTok Live Companion</h1>\n"
    append html "    <span class=\"badge\" id=\"badge\"><span class=\"dot\"></span><span id=\"badgeText\">—</span></span>\n"
    append html "  </header>\n"
    append html "\n"
    append html "  <div class=\"row\">\n"
    append html "    <input id=\"user\" placeholder=\"@name\" style=\"flex:1;min-width:120px\">\n"
    append html "    <button class=\"primary\" id=\"go\">Anzeigen</button>\n"
    append html "    <button id=\"force\" title=\"Player ohne Statusabfrage laden\">Player</button>\n"
    append html "  </div>\n"
    append html "  <div class=\"row\">\n"
    append html "    <select id=\"every\" style=\"flex:1\">\n"
    append html "      <option value=\"1\">Prüfung jede Minute</option>\n"
    append html "      <option value=\"2\" selected>alle 2 Minuten</option>\n"
    append html "      <option value=\"5\">alle 5 Minuten</option>\n"
    append html "      <option value=\"0\">nur manuell</option>\n"
    append html "    </select>\n"
    append html "    <label class=\"meta\"><input type=\"checkbox\" id=\"notify\" checked> benachrichtigen</label>\n"
    append html "  </div>\n"
    append html "\n"
    append html "  <div id=\"error\"></div>\n"
    append html "\n"
    append html "  <div class=\"player\" id=\"player\">\n"
    append html "    <div class=\"placeholder\" id=\"placeholder\">\n"
    append html "      <div style=\"font-size:28px\">📺</div>\n"
    append html "      <div id=\"phText\">Konto eingeben und „Anzeigen“ drücken.</div>\n"
    append html "    </div>\n"
    append html "  </div>\n"
    append html "\n"
    append html "  <div class=\"card\">\n"
    append html "    <h2>Status</h2>\n"
    append html "    <div id=\"status\" class=\"meta\">—</div>\n"
    append html "  </div>\n"
    append html "\n"
    append html "  <div class=\"card\">\n"
    append html "    <h2>Letzte Sendungen</h2>\n"
    append html "    <div id=\"streams\" class=\"meta\">—</div>\n"
    append html "  </div>\n"
    append html "\n"
    append html "  <p class=\"note\">\n"
    append html "    Eingebettet wird der offizielle TikTok-Live-Player — <b>keine Anmeldung,\n"
    append html "    keine Geschenk- oder Kauf-Oberfläche</b>. Der Status kommt aus öffentlichen\n"
    append html "    Quellen; nichts davon umgeht eine Zugangskontrolle.\n"
    append html "  </p>\n"
    append html "</div>\n"
    append html "<script src=\"tiktok-companion.js\"></script>\n"
    append html "<script src=\"popup.js\"></script>\n"
    append html "</body>\n"
    append html "</html>\n"
    
    return $html
}

# Main execution
if {$argc > 0} {
    set filename [lindex $argv 0]
    set fh [open $filename w]
    puts $fh [generatePopup]
    close $fh
    puts "HTML file generated: $filename"
} else {
    puts [generatePopup]
}
