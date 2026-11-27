// abstraction-provenance: {"artifact_sha256": "469e807fe9893946032b192bcc5084ba7ad230b20bb0e38181a1addc5a41a581", "source_sha256": "460df65e46318ad1986c44053aeaeda0d4be58e1787c4233154a42f92badec94", "target_language": "cpp"}
// popup.html — portiert nach cpp
// Quelle: html, Projects@Telegram-Monitor:plugin/extension/popup.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <fstream>
#include <string>

void writePopupHTML(const std::string& filename) {
    std::ofstream file(filename);
    if (!file.is_open()) {
        std::cerr << "Fehler beim Öffnen der Datei: " << filename << std::endl;
        return;
    }

    file << "<!DOCTYPE html>\n";
    file << "<html lang=\"de\">\n";
    file << "<head>\n";
    file << "<meta charset=\"utf-8\">\n";
    file << "<title>TikTok Live Companion</title>\n";
    file << "<style>\n";
    file << "  :root{\n";
    file << "    --bg:#0f1115; --card:#171a21; --line:#262b36; --text:#f2f4f8; --muted:#9aa3b2;\n";
    file << "    --accent:#fe2c55; --ok:#22c55e;\n";
    file << "    color-scheme: dark;\n";
    file << "  }\n";
    file << "  @media (prefers-color-scheme: light){\n";
    file << "    :root{ --bg:#fff; --card:#f6f7f9; --line:#e3e6ea; --text:#16191d; --muted:#6b7280; }\n";
    file << "  }\n";
    file << "  *{box-sizing:border-box}\n";
    file << "  body{margin:0;width:420px;max-height:600px;overflow:auto;background:var(--bg);color:var(--text);\n";
    file << "       font:14px/1.45 -apple-system,BlinkMacSystemFont,\"Segoe UI\",Roboto,sans-serif}\n";
    file << "  .wrap{padding:12px}\n";
    file << "  header{display:flex;gap:8px;align-items:center;margin-bottom:10px}\n";
    file << "  h1{font-size:14px;margin:0;font-weight:650;flex:1}\n";
    file << "  .badge{font-size:11px;font-weight:700;padding:3px 9px;border-radius:99px;\n";
    file << "         background:#2a2f3a;color:var(--muted);display:inline-flex;align-items:center;gap:5px}\n";
    file << "  .badge.live{background:var(--accent);color:#fff}\n";
    file << "  .badge .dot{width:6px;height:6px;border-radius:50%;background:currentColor}\n";
    file << "  .badge.live .dot{animation:pulse 1.6s infinite}\n";
    file << "  @keyframes pulse{0%,100%{opacity:1}50%{opacity:.25}}\n";
    file << "  .row{display:flex;gap:6px;flex-wrap:wrap;align-items:center;margin-bottom:8px}\n";
    file << "  input,select,button{font:inherit;border-radius:7px;border:1px solid var(--line);\n";
    file << "                      background:var(--card);color:var(--text);padding:6px 9px}\n";
    file << "  button{cursor:pointer;font-weight:600}\n";
    file << "  button.primary{background:var(--accent);border-color:var(--accent);color:#fff}\n";
    file << "  .player{position:relative;width:100%;aspect-ratio:9/16;max-height:360px;background:#000;\n";
    file << "          border-radius:10px;overflow:hidden;border:1px solid var(--line);margin:8px 0}\n";
    file << "  .player iframe{position:absolute;inset:0;width:100%;height:100%;border:0}\n";
    file << "  .placeholder{position:absolute;inset:0;display:flex;flex-direction:column;gap:6px;\n";
    file << "               align-items:center;justify-content:center;color:var(--muted);\n";
    file << "               text-align:center;padding:16px;font-size:13px}\n";
    file << "  .card{background:var(--card);border:1px solid var(--line);border-radius:10px;\n";
    file << "        padding:10px 12px;margin-bottom:8px}\n";
    file << "  h2{font-size:11px;text-transform:uppercase;letter-spacing:.05em;color:var(--muted);\n";
    file << "     margin:0 0 6px;font-weight:650}\n";
    file << "  .meta{color:var(--muted);font-size:12.5px}\n";
    file << "  .strong{color:var(--text);font-weight:600}\n";
    file << "  .stream{display:flex;gap:8px;padding:5px 0;border-bottom:1px solid var(--line);font-size:12.5px}\n";
    file << "  .stream:last-child{border-bottom:0}\n";
    file << "  .stream .when{color:var(--muted);white-space:nowrap;font-variant-numeric:tabular-nums}\n";
    file << "  .stream .t{flex:1;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}\n";
    file << "  .stream.now{color:var(--accent);font-weight:650}\n";
    file << "  .err{background:#3a1d22;border:1px solid #5c2a33;color:#ffb4c0;padding:8px 10px;\n";
    file << "       border-radius:8px;font-size:12.5px;margin-bottom:8px}\n";
    file << "  @media (prefers-color-scheme: light){ .err{background:#fdeceb;border-color:#f5c6c2;color:#b91c1c} }\n";
    file << "  .note{font-size:11.5px;color:var(--muted);line-height:1.4;margin-top:8px}\n";
    file << "  a{color:var(--accent)}\n";
    file << "</style>\n";
    file << "</head>\n";
    file << "<body>\n";
    file << "<div class=\"wrap\">\n";
    file << "  <header>\n";
    file << "    <h1>TikTok Live Companion</h1>\n";
    file << "    <span class=\"badge\" id=\"badge\"><span class=\"dot\"></span><span id=\"badgeText\">—</span></span>\n";
    file << "  </header>\n";
    file << "\n";
    file << "  <div class=\"row\">\n";
    file << "    <input id=\"user\" placeholder=\"@name\" style=\"flex:1;min-width:120px\">\n";
    file << "    <button class=\"primary\" id=\"go\">Anzeigen</button>\n";
    file << "    <button id=\"force\" title=\"Player ohne Statusabfrage laden\">Player</button>\n";
    file << "  </div>\n";
    file << "  <div class=\"row\">\n";
    file << "    <select id=\"every\" style=\"flex:1\">\n";
    file << "      <option value=\"1\">Prüfung jede Minute</option>\n";
    file << "      <option value=\"2\" selected>alle 2 Minuten</option>\n";
    file << "      <option value=\"5\">alle 5 Minuten</option>\n";
    file << "      <option value=\"0\">nur manuell</option>\n";
    file << "    </select>\n";
    file << "    <label class=\"meta\"><input type=\"checkbox\" id=\"notify\" checked> benachrichtigen</label>\n";
    file << "  </div>\n";
    file << "\n";
    file << "  <div id=\"error\"></div>\n";
    file << "\n";
    file << "  <div class=\"player\" id=\"player\">\n";
    file << "    <div class=\"placeholder\" id=\"placeholder\">\n";
    file << "      <div style=\"font-size:28px\">📺</div>\n";
    file << "      <div id=\"phText\">Konto eingeben und „Anzeigen“ drücken.</div>\n";
    file << "    </div>\n";
    file << "  </div>\n";
    file << "\n";
    file << "  <div class=\"card\">\n";
    file << "    <h2>Status</h2>\n";
    file << "    <div id=\"status\" class=\"meta\">—</div>\n";
    file << "  </div>\n";
    file << "\n";
    file << "  <div class=\"card\">\n";
    file << "    <h2>Letzte Sendungen</h2>\n";
    file << "    <div id=\"streams\" class=\"meta\">—</div>\n";
    file << "  </div>\n";
    file << "\n";
    file << "  <p class=\"note\">\n";
    file << "    Eingebettet wird der offizielle TikTok-Live-Player — <b>keine Anmeldung,\n";
    file << "    keine Geschenk- oder Kauf-Oberfläche</b>. Der Status kommt aus öffentlichen\n";
    file << "    Quellen; nichts davon umgeht eine Zugangskontrolle.\n";
    file << "  </p>\n";
    file << "</div>\n";
    file << "<script src=\"tiktok-companion.js\"></script>\n";
    file << "<script src=\"popup.js\"></script>\n";
    file << "</body>\n";
    file << "</html>\n";

    file.close();
}

int main(int argc, char* argv[]) {
    std::string filename = "popup.html";
    
    if (argc > 1) {
        filename = argv[1];
    }
    
    writePopupHTML(filename);
    
    return 0;
}
