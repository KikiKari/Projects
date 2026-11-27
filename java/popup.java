// abstraction-provenance: {"artifact_sha256": "d568b8fbcb1f53e2b6e8b55563d5249220b2174b929bda611af371b9d60e9fc8", "source_sha256": "460df65e46318ad1986c44053aeaeda0d4be58e1787c4233154a42f92badec94", "target_language": "java"}
// popup.html — portiert nach java
// Quelle: html, Projects@Telegram-Monitor:plugin/extension/popup.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;

public class PopupGenerator {
    
    public static void main(String[] args) {
        if (args.length != 1) {
            System.err.println("Bitte geben Sie einen Dateinamen als Parameter an.");
            System.exit(1);
        }
        
        String filename = args[0];
        generatePopupHtml(filename);
    }
    
    public static void generatePopupHtml(String filename) {
        StringBuilder html = new StringBuilder();
        
        // DOCTYPE und HTML-Grundstruktur
        html.append("<!DOCTYPE html>\n");
        html.append("<html lang=\"de\">\n");
        html.append("<head>\n");
        html.append("<meta charset=\"utf-8\">\n");
        html.append("<title>TikTok Live Companion</title>\n");
        
        // CSS Styles
        appendStyles(html);
        
        html.append("</head>\n");
        html.append("<body>\n");
        html.append("<div class=\"wrap\">\n");
        
        // Header
        html.append("  <header>\n");
        html.append("    <h1>TikTok Live Companion</h1>\n");
        html.append("    <span class=\"badge\" id=\"badge\"><span class=\"dot\"></span><span id=\"badgeText\">—</span></span>\n");
        html.append("  </header>\n");
        
        // Eingabebereich
        html.append("\n  <div class=\"row\">\n");
        html.append("    <input id=\"user\" placeholder=\"@name\" style=\"flex:1;min-width:120px\">\n");
        html.append("    <button class=\"primary\" id=\"go\">Anzeigen</button>\n");
        html.append("    <button id=\"force\" title=\"Player ohne Statusabfrage laden\">Player</button>\n");
        html.append("  </div>\n");
        
        html.append("  <div class=\"row\">\n");
        html.append("    <select id=\"every\" style=\"flex:1\">\n");
        html.append("      <option value=\"1\">Prüfung jede Minute</option>\n");
        html.append("      <option value=\"2\" selected>alle 2 Minuten</option>\n");
        html.append("      <option value=\"5\">alle 5 Minuten</option>\n");
        html.append("      <option value=\"0\">nur manuell</option>\n");
        html.append("    </select>\n");
        html.append("    <label class=\"meta\"><input type=\"checkbox\" id=\"notify\" checked> benachrichtigen</label>\n");
        html.append("  </div>\n");
        
        // Fehlermeldungsbereich
        html.append("\n  <div id=\"error\"></div>\n");
        
        // Player-Bereich
        html.append("\n  <div class=\"player\" id=\"player\">\n");
        html.append("    <div class=\"placeholder\" id=\"placeholder\">\n");
        html.append("      <div style=\"font-size:28px\">📺</div>\n");
        html.append("      <div id=\"phText\">Konto eingeben und „Anzeigen“ drücken.</div>\n");
        html.append("    </div>\n");
        html.append("  </div>\n");
        
        // Status-Karte
        html.append("\n  <div class=\"card\">\n");
        html.append("    <h2>Status</h2>\n");
        html.append("    <div id=\"status\" class=\"meta\">—</div>\n");
        html.append("  </div>\n");
        
        // Stream-Karte
        html.append("\n  <div class=\"card\">\n");
        html.append("    <h2>Letzte Sendungen</h2>\n");
        html.append("    <div id=\"streams\" class=\"meta\">—</div>\n");
        html.append("  </div>\n");
        
        // Hinweis
        html.append("\n  <p class=\"note\">\n");
        html.append("    Eingebettet wird der offizielle TikTok-Live-Player — <b>keine Anmeldung,\n");
        html.append("    keine Geschenk- oder Kauf-Oberfläche</b>. Der Status kommt aus öffentlichen\n");
        html.append("    Quellen; nichts davon umgeht eine Zugangskontrolle.\n");
        html.append("  </p>\n");
        
        html.append("</div>\n");
        
        // JavaScript-Einbindungen
        html.append("<script src=\"tiktok-companion.js\"></script>\n");
        html.append("<script src=\"popup.js\"></script>\n");
        
        html.append("</body>\n");
        html.append("</html>\n");
        
        // In Datei schreiben
        try (FileWriter writer = new FileWriter(filename)) {
            writer.write(html.toString());
            System.out.println("HTML-Datei erfolgreich erstellt: " + filename);
        } catch (IOException e) {
            System.err.println("Fehler beim Schreiben der Datei: " + e.getMessage());
            System.exit(1);
        }
    }
    
    private static void appendStyles(StringBuilder html) {
        html.append("<style>\n");
        html.append("  :root{\n");
        html.append("    --bg:#0f1115; --card:#171a21; --line:#262b36; --text:#f2f4f8; --muted:#9aa3b2;\n");
        html.append("    --accent:#fe2c55; --ok:#22c55e;\n");
        html.append("    color-scheme: dark;\n");
        html.append("  }\n");
        html.append("  @media (prefers-color-scheme: light){\n");
        html.append("    :root{ --bg:#fff; --card:#f6f7f9; --line:#e3e6ea; --text:#16191d; --muted:#6b7280; }\n");
        html.append("  }\n");
        html.append("  *{box-sizing:border-box}\n");
        html.append("  body{margin:0;width:420px;max-height:600px;overflow:auto;background:var(--bg);color:var(--text);\n");
        html.append("       font:14px/1.45 -apple-system,BlinkMacSystemFont,\"Segoe UI\",Roboto,sans-serif}\n");
        html.append("  .wrap{padding:12px}\n");
        html.append("  header{display:flex;gap:8px;align-items:center;margin-bottom:10px}\n");
        html.append("  h1{font-size:14px;margin:0;font-weight:650;flex:1}\n");
        html.append("  .badge{font-size:11px;font-weight:700;padding:3px 9px;border-radius:99px;\n");
        html.append("         background:#2a2f3a;color:var(--muted);display:inline-flex;align-items:center;gap:5px}\n");
        html.append("  .badge.live{background:var(--accent);color:#fff}\n");
        html.append("  .badge .dot{width:6px;height:6px;border-radius:50%;background:currentColor}\n");
        html.append("  .badge.live .dot{animation:pulse 1.6s infinite}\n");
        html.append("  @keyframes pulse{0%,100%{opacity:1}50%{opacity:.25}}\n");
        html.append("  .row{display:flex;gap:6px;flex-wrap:wrap;align-items:center;margin-bottom:8px}\n");
        html.append("  input,select,button{font:inherit;border-radius:7px;border:1px solid var(--line);\n");
        html.append("                      background:var(--card);color:var(--text);padding:6px 9px}\n");
        html.append("  button{cursor:pointer;font-weight:600}\n");
        html.append("  button.primary{background:var(--accent);border-color:var(--accent);color:#fff}\n");
        html.append("  .player{position:relative;width:100%;aspect-ratio:9/16;max-height:360px;background:#000;\n");
        html.append("          border-radius:10px;overflow:hidden;border:1px solid var(--line);margin:8px 0}\n");
        html.append("  .player iframe{position:absolute;inset:0;width:100%;height:100%;border:0}\n");
        html.append("  .placeholder{position:absolute;inset:0;display:flex;flex-direction:column;gap:6px;\n");
        html.append("               align-items:center;justify-content:center;color:var(--muted);\n");
        html.append("               text-align:center;padding:16px;font-size:13px}\n");
        html.append("  .card{background:var(--card);border:1px solid var(--line);border-radius:10px;\n");
        html.append("        padding:10px 12px;margin-bottom:8px}\n");
        html.append("  h2{font-size:11px;text-transform:uppercase;letter-spacing:.05em;color:var(--muted);\n");
        html.append("     margin:0 0 6px;font-weight:650}\n");
        html.append("  .meta{color:var(--muted);font-size:12.5px}\n");
        html.append("  .strong{color:var(--text);font-weight:600}\n");
        html.append("  .stream{display:flex;gap:8px;padding:5px 0;border-bottom:1px solid var(--line);font-size:12.5px}\n");
        html.append("  .stream:last-child{border-bottom:0}\n");
        html.append("  .stream .when{color:var(--muted);white-space:nowrap;font-variant-numeric:tabular-nums}\n");
        html.append("  .stream .t{flex:1;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}\n");
        html.append("  .stream.now{color:var(--accent);font-weight:650}\n");
        html.append("  .err{background:#3a1d22;border:1px solid #5c2a33;color:#ffb4c0;padding:8px 10px;\n");
        html.append("       border-radius:8px;font-size:12.5px;margin-bottom:8px}\n");
        html.append("  @media (prefers-color-scheme: light){ .err{background:#fdeceb;border-color:#f5c6c2;color:#b91c1c} }\n");
        html.append("  .note{font-size:11.5px;color:var(--muted);line-height:1.4;margin-top:8px}\n");
        html.append("  a{color:var(--accent)}\n");
        html.append("</style>\n");
    }
}
