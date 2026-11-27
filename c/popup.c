// abstraction-provenance: {"artifact_sha256": "8acefbfe5d484040fb1950bcc012473bee0fcd6b20f043609bb96361c04fcffa", "source_sha256": "460df65e46318ad1986c44053aeaeda0d4be58e1787c4233154a42f92badec94", "target_language": "c"}
// popup.html — portiert nach c
// Quelle: html, Projects@Telegram-Monitor:plugin/extension/popup.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void write_html_document(FILE* file) {
    fprintf(file, "<!DOCTYPE html>\n");
    fprintf(file, "<html lang=\"de\">\n");
    fprintf(file, "<head>\n");
    fprintf(file, "<meta charset=\"utf-8\">\n");
    fprintf(file, "<title>TikTok Live Companion</title>\n");
    fprintf(file, "<style>\n");
    fprintf(file, "  :root{\n");
    fprintf(file, "    --bg:#0f1115; --card:#171a21; --line:#262b36; --text:#f2f4f8; --muted:#9aa3b2;\n");
    fprintf(file, "    --accent:#fe2c55; --ok:#22c55e;\n");
    fprintf(file, "    color-scheme: dark;\n");
    fprintf(file, "  }\n");
    fprintf(file, "  @media (prefers-color-scheme: light){\n");
    fprintf(file, "    :root{ --bg:#fff; --card:#f6f7f9; --line:#e3e6ea; --text:#16191d; --muted:#6b7280; }\n");
    fprintf(file, "  }\n");
    fprintf(file, "  *{box-sizing:border-box}\n");
    fprintf(file, "  body{margin:0;width:420px;max-height:600px;overflow:auto;background:var(--bg);color:var(--text);\n");
    fprintf(file, "       font:14px/1.45 -apple-system,BlinkMacSystemFont,\"Segoe UI\",Roboto,sans-serif}\n");
    fprintf(file, "  .wrap{padding:12px}\n");
    fprintf(file, "  header{display:flex;gap:8px;align-items:center;margin-bottom:10px}\n");
    fprintf(file, "  h1{font-size:14px;margin:0;font-weight:650;flex:1}\n");
    fprintf(file, "  .badge{font-size:11px;font-weight:700;padding:3px 9px;border-radius:99px;\n");
    fprintf(file, "         background:#2a2f3a;color:var(--muted);display:inline-flex;align-items:center;gap:5px}\n");
    fprintf(file, "  .badge.live{background:var(--accent);color:#fff}\n");
    fprintf(file, "  .badge .dot{width:6px;height:6px;border-radius:50%;background:currentColor}\n");
    fprintf(file, "  .badge.live .dot{animation:pulse 1.6s infinite}\n");
    fprintf(file, "  @keyframes pulse{0%%,100%%{opacity:1}50%%{opacity:.25}}\n");
    fprintf(file, "  .row{display:flex;gap:6px;flex-wrap:wrap;align-items:center;margin-bottom:8px}\n");
    fprintf(file, "  input,select,button{font:inherit;border-radius:7px;border:1px solid var(--line);\n");
    fprintf(file, "                      background:var(--card);color:var(--text);padding:6px 9px}\n");
    fprintf(file, "  button{cursor:pointer;font-weight:600}\n");
    fprintf(file, "  button.primary{background:var(--accent);border-color:var(--accent);color:#fff}\n");
    fprintf(file, "  .player{position:relative;width:100%%;aspect-ratio:9/16;max-height:360px;background:#000;\n");
    fprintf(file, "          border-radius:10px;overflow:hidden;border:1px solid var(--line);margin:8px 0}\n");
    fprintf(file, "  .player iframe{position:absolute;inset:0;width:100%%;height:100%%;border:0}\n");
    fprintf(file, "  .placeholder{position:absolute;inset:0;display:flex;flex-direction:column;gap:6px;\n");
    fprintf(file, "               align-items:center;justify-content:center;color:var(--muted);\n");
    fprintf(file, "               text-align:center;padding:16px;font-size:13px}\n");
    fprintf(file, "  .card{background:var(--card);border:1px solid var(--line);border-radius:10px;\n");
    fprintf(file, "        padding:10px 12px;margin-bottom:8px}\n");
    fprintf(file, "  h2{font-size:11px;text-transform:uppercase;letter-spacing:.05em;color:var(--muted);\n");
    fprintf(file, "     margin:0 0 6px;font-weight:650}\n");
    fprintf(file, "  .meta{color:var(--muted);font-size:12.5px}\n");
    fprintf(file, "  .strong{color:var(--text);font-weight:600}\n");
    fprintf(file, "  .stream{display:flex;gap:8px;padding:5px 0;border-bottom:1px solid var(--line);font-size:12.5px}\n");
    fprintf(file, "  .stream:last-child{border-bottom:0}\n");
    fprintf(file, "  .stream .when{color:var(--muted);white-space:nowrap;font-variant-numeric:tabular-nums}\n");
    fprintf(file, "  .stream .t{flex:1;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}\n");
    fprintf(file, "  .stream.now{color:var(--accent);font-weight:650}\n");
    fprintf(file, "  .err{background:#3a1d22;border:1px solid #5c2a33;color:#ffb4c0;padding:8px 10px;\n");
    fprintf(file, "       border-radius:8px;font-size:12.5px;margin-bottom:8px}\n");
    fprintf(file, "  @media (prefers-color-scheme: light){ .err{background:#fdeceb;border-color:#f5c6c2;color:#b91c1c} }\n");
    fprintf(file, "  .note{font-size:11.5px;color:var(--muted);line-height:1.4;margin-top:8px}\n");
    fprintf(file, "  a{color:var(--accent)}\n");
    fprintf(file, "</style>\n");
    fprintf(file, "</head>\n");
    fprintf(file, "<body>\n");
    fprintf(file, "<div class=\"wrap\">\n");
    fprintf(file, "  <header>\n");
    fprintf(file, "    <h1>TikTok Live Companion</h1>\n");
    fprintf(file, "    <span class=\"badge\" id=\"badge\"><span class=\"dot\"></span><span id=\"badgeText\">—</span></span>\n");
    fprintf(file, "  </header>\n\n");
    fprintf(file, "  <div class=\"row\">\n");
    fprintf(file, "    <input id=\"user\" placeholder=\"@name\" style=\"flex:1;min-width:120px\">\n");
    fprintf(file, "    <button class=\"primary\" id=\"go\">Anzeigen</button>\n");
    fprintf(file, "    <button id=\"force\" title=\"Player ohne Statusabfrage laden\">Player</button>\n");
    fprintf(file, "  </div>\n");
    fprintf(file, "  <div class=\"row\">\n");
    fprintf(file, "    <select id=\"every\" style=\"flex:1\">\n");
    fprintf(file, "      <option value=\"1\">Prüfung jede Minute</option>\n");
    fprintf(file, "      <option value=\"2\" selected>alle 2 Minuten</option>\n");
    fprintf(file, "      <option value=\"5\">alle 5 Minuten</option>\n");
    fprintf(file, "      <option value=\"0\">nur manuell</option>\n");
    fprintf(file, "    </select>\n");
    fprintf(file, "    <label class=\"meta\"><input type=\"checkbox\" id=\"notify\" checked> benachrichtigen</label>\n");
    fprintf(file, "  </div>\n\n");
    fprintf(file, "  <div id=\"error\"></div>\n\n");
    fprintf(file, "  <div class=\"player\" id=\"player\">\n");
    fprintf(file, "    <div class=\"placeholder\" id=\"placeholder\">\n");
    fprintf(file, "      <div style=\"font-size:28px\">&#x1F4FA;</div>\n");
    fprintf(file, "      <div id=\"phText\">Konto eingeben und „Anzeigen“ drücken.</div>\n");
    fprintf(file, "    </div>\n");
    fprintf(file, "  </div>\n\n");
    fprintf(file, "  <div class=\"card\">\n");
    fprintf(file, "    <h2>Status</h2>\n");
    fprintf(file, "    <div id=\"status\" class=\"meta\">—</div>\n");
    fprintf(file, "  </div>\n\n");
    fprintf(file, "  <div class=\"card\">\n");
    fprintf(file, "    <h2>Letzte Sendungen</h2>\n");
    fprintf(file, "    <div id=\"streams\" class=\"meta\">—</div>\n");
    fprintf(file, "  </div>\n\n");
    fprintf(file, "  <p class=\"note\">\n");
    fprintf(file, "    Eingebettet wird der offizielle TikTok-Live-Player — <b>keine Anmeldung,\n");
    fprintf(file, "    keine Geschenk- oder Kauf-Oberfläche</b>. Der Status kommt aus öffentlichen\n");
    fprintf(file, "    Quellen; nichts davon umgeht eine Zugangskontrolle.\n");
    fprintf(file, "  </p>\n");
    fprintf(file, "</div>\n");
    fprintf(file, "<script src=\"tiktok-companion.js\"></script>\n");
    fprintf(file, "<script src=\"popup.js\"></script>\n");
    fprintf(file, "</body>\n");
    fprintf(file, "</html>\n");
}

int main(int argc, char* argv[]) {
    FILE* output_file;
    
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <output_file>\n", argv[0]);
        return 1;
    }
    
    output_file = fopen(argv[1], "w");
    if (output_file == NULL) {
        fprintf(stderr, "Error: Could not open file %s for writing\n", argv[1]);
        return 1;
    }
    
    write_html_document(output_file);
    
    fclose(output_file);
    return 0;
}
