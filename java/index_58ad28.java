// abstraction-provenance: {"artifact_sha256": "91575eef8a9bf4bda5aa85b59234c5cbca496f137196e2d04ed1baf74af762bd", "source_sha256": "58ad2830d3e11b79c54044cfe5a82e7e3fd2a9b1ca1f65c546ff6e92e821c6f3", "target_language": "java"}
// index.html — portiert nach java
// Quelle: html, Projects@Telegram-Monitor:public/index.html
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import java.io.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;

public class IndexGenerator {
    
    public static void main(String[] args) {
        if (args.length != 1) {
            System.err.println("Usage: java IndexGenerator <output-file>");
            System.exit(1);
        }
        
        String outputFile = args[0];
        
        try {
            String htmlContent = generateHTML();
            Files.write(Paths.get(outputFile), htmlContent.getBytes(StandardCharsets.UTF_8));
            System.out.println("HTML file generated successfully: " + outputFile);
        } catch (IOException e) {
            System.err.println("Error writing file: " + e.getMessage());
            System.exit(1);
        }
    }
    
    private static String generateHTML() {
        StringBuilder html = new StringBuilder();
        
        // DOCTYPE and opening html tag
        html.append("<!DOCTYPE html>\n");
        html.append("<html lang=\"de\">\n");
        
        // Head section
        appendHead(html);
        
        // Body section
        appendBody(html);
        
        // Closing tags
        html.append("\n</html>");
        
        return html.toString();
    }
    
    private static void appendHead(StringBuilder html) {
        html.append("<head>\n");
        html.append("<meta charset=\"utf-8\">\n");
        html.append("<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n");
        html.append("<title>Telegram Monitor — lokaler Beobachtungs-Companion</title>\n");
        html.append("<meta name=\"description\" content=\"Beobachtet öffentliche Telegram-Kanäle und TikTok-Konten auf dem eigenen Rechner und meldet den Livegang. Keine Cloud, keine Anmeldung.\">\n");
        html.append("<meta name=\"theme-color\" content=\"#2481cc\">\n");
        html.append("<meta property=\"og:title\" content=\"Telegram Monitor\">\n");
        html.append("<meta property=\"og:description\" content=\"Lokaler Beobachtungs-Companion. Docker, PWA, Meldung beim Livegang.\">\n");
        html.append("<meta property=\"og:type\" content=\"website\">\n");
        appendStyle(html);
        html.append("</head>\n");
    }
    
    private static void appendStyle(StringBuilder html) {
        html.append("<style>\n");
        html.append("  :root{\n");
        html.append("    --bg:#ffffff; --soft:#f6f7f9; --line:#e3e6ea; --text:#16191d; --muted:#5f6773;\n");
        html.append("    --tg:#2481cc; --tg-soft:#e8f2fb; --tt:#fe2c55;\n");
        html.append("    --ok:#15803d; --ok-soft:#e7f6ec; --warn:#b45309; --warn-soft:#fdf3e3;\n");
        html.append("    color-scheme: light;\n");
        html.append("  }\n");
        html.append("  @media (prefers-color-scheme: dark){\n");
        html.append("    :root{ --bg:#0f1115; --soft:#171a21; --line:#262b36; --text:#f2f4f8; --muted:#9aa3b2;\n");
        html.append("           --tg-soft:#132a3d; --ok-soft:#12261a; --warn-soft:#2c2110; color-scheme: dark; }\n");
        html.append("  }\n");
        html.append("  *{box-sizing:border-box}\n");
        html.append("  body{margin:0;background:var(--bg);color:var(--text);\n");
        html.append("       font:16px/1.6 -apple-system,BlinkMacSystemFont,\"Segoe UI\",Roboto,sans-serif}\n");
        html.append("  .wrap{max-width:820px;margin:0 auto;padding:0 20px 72px}\n");
        html.append("  header{padding:64px 0 40px;border-bottom:1px solid var(--line);margin-bottom:8px}\n");
        html.append("  h1{font-size:34px;line-height:1.2;margin:0 0 12px;letter-spacing:-.02em}\n");
        html.append("  .lede{font-size:18px;color:var(--muted);margin:0 0 22px;max-width:60ch}\n");
        html.append("  h2{font-size:13px;margin:44px 0 14px;text-transform:uppercase;letter-spacing:.06em;\n");
        html.append("     color:var(--muted);font-weight:650}\n");
        html.append("  h3{font-size:17px;margin:26px 0 6px}\n");
        html.append("  p{margin:0 0 14px;max-width:68ch}\n");
        html.append("  .badges{display:flex;gap:7px;flex-wrap:wrap;margin-bottom:22px}\n");
        html.append("  .badge{font-size:12px;font-weight:650;padding:4px 11px;border-radius:99px;\n");
        html.append("         background:var(--soft);color:var(--muted);border:1px solid var(--line)}\n");
        html.append("  .badge.on{background:var(--ok-soft);color:var(--ok);border-color:transparent}\n");
        html.append("  .cta{display:flex;gap:10px;flex-wrap:wrap}\n");
        html.append("  .btn{display:inline-block;font-weight:650;font-size:15px;padding:11px 20px;\n");
        html.append("       border-radius:9px;text-decoration:none;border:1px solid var(--line);\n");
        html.append("       background:var(--bg);color:var(--text)}\n");
        html.append("  .btn.primary{background:var(--tg);border-color:var(--tg);color:#fff}\n");
        html.append("  .btn:hover{border-color:var(--tg)}\n");
        html.append("  .grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(230px,1fr));gap:14px}\n");
        html.append("  .card{border:1px solid var(--line);border-radius:12px;padding:16px 18px;background:var(--bg)}\n");
        html.append("  .card h3{margin-top:0;font-size:15.5px}\n");
        html.append("  .card p{font-size:14px;color:var(--muted);margin:0}\n");
        html.append("  ol.steps{list-style:none;counter-reset:s;padding:0;margin:0}\n");
        html.append("  ol.steps li{counter-increment:s;position:relative;padding:0 0 20px 40px;\n");
        html.append("              border-left:2px solid var(--line);margin-left:11px}\n");
        html.append("  ol.steps li:last-child{border-left-color:transparent;padding-bottom:0}\n");
        html.append("  ol.steps li::before{content:counter(s);position:absolute;left:-13px;top:0;\n");
        html.append("       width:24px;height:24px;border-radius:50%;background:var(--tg);color:#fff;\n");
        html.append("       display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:700}\n");
        html.append("  ol.steps b{display:block;margin-bottom:3px}\n");
        html.append("  ol.steps p{font-size:14.5px;color:var(--muted);margin:0 0 8px}\n");
        html.append("  code{background:var(--soft);padding:2px 7px;border-radius:5px;font-size:13.5px;\n");
        html.append("       font-family:ui-monospace,SFMono-Regular,Menlo,monospace;word-break:break-word}\n");
        html.append("  pre{background:var(--soft);border:1px solid var(--line);border-radius:10px;\n");
        html.append("      padding:13px 15px;overflow-x:auto;margin:0 0 14px}\n");
        html.append("  pre code{background:none;padding:0;font-size:13.5px;line-height:1.7}\n");
        html.append("  table{width:100%;border-collapse:collapse;font-size:14.5px;margin:0 0 16px}\n");
        html.append("  th,td{text-align:left;padding:9px 11px;border-bottom:1px solid var(--line);vertical-align:top}\n");
        html.append("  th{color:var(--muted);font-size:12px;text-transform:uppercase;letter-spacing:.04em;font-weight:650}\n");
        html.append("  .note{border-left:3px solid var(--warn);background:var(--warn-soft);\n");
        html.append("        border-radius:0 9px 9px 0;padding:13px 16px;margin:0 0 16px;font-size:14.5px}\n");
        html.append("  .note b{display:block;margin-bottom:3px}\n");
        html.append("  a{color:var(--tg)}\n");
        html.append("  footer{margin-top:52px;padding-top:22px;border-top:1px solid var(--line);\n");
        html.append("         font-size:13.5px;color:var(--muted)}\n");
        html.append("</style>\n");
    }
    
    private static void appendBody(StringBuilder html) {
        html.append("<body>\n");
        html.append("<div class=\"wrap\">\n\n");
        
        appendHeader(html);
        appendWhatItDoes(html);
        appendAccessPoints(html);
        appendSetup(html);
        appendLimitations(html);
        appendBoundaries(html);
        appendFooter(html);
        
        html.append("\n</div>\n");
        html.append("</body>\n");
    }
    
    private static void appendHeader(StringBuilder html) {
        html.append("<header>\n");
        html.append("  <h1>Telegram Monitor</h1>\n");
        html.append("  <p class=\"lede\">Beobachtet öffentliche Telegram-Kanäle und TikTok-Konten auf\n");
        html.append("     deinem eigenen Rechner und meldet sich, wenn jemand live geht. Keine Cloud,\n");
        html.append("     kein Konto, keine App-Installation auf dem Telefon nötig.</p>\n");
        html.append("  <div class=\"badges\">\n");
        html.append("    <span class=\"badge on\">Standardbibliothek</span>\n");
        html.append("    <span class=\"badge on\">Docker</span>\n");
        html.append("    <span class=\"badge on\">installierbar als App</span>\n");
        html.append("    <span class=\"badge on\">Browser-Erweiterung</span>\n");
        html.append("    <span class=\"badge\">Windows · macOS · Linux</span>\n");
        html.append("  </div>\n");
        html.append("  <div class=\"cta\">\n");
        html.append("    <a class=\"btn primary\" href=\"https://github.com/KikiKari/Projects/tree/Telegram-Monitor\">Quelltext auf GitHub</a>\n");
        html.append("    <a class=\"btn\" href=\"/viewer\">Live-Viewer öffnen</a>\n");
        html.append("  </div>\n");
        html.append("</header>\n\n");
    }
    
    private static void appendWhatItDoes(StringBuilder html) {
        html.append("<h2>Was es tut</h2>\n");
        html.append("<div class=\"grid\">\n");
        html.append("  <div class=\"card\">\n");
        html.append("    <h3>Beobachten</h3>\n");
        html.append("    <p>Fragt jeden Kanal im eingestellten Turnus ab und sammelt den Verlauf auf\n");
        html.append("       der Platte — neueste Beiträge oben, anders als in Telegram selbst.</p>\n");
        html.append("  </div>\n");
        html.append("  <div class=\"card\">\n");
        html.append("    <h3>Erkennen</h3>\n");
        html.append("    <p>Vergleicht den Zustand mit dem letzten Durchlauf. Gemeldet wird nur ein\n");
        html.append("       echter Wechsel; ein fehlgeschlagener Abruf gilt nicht als „offline\".</p>\n");
        html.append("  </div>\n");
        html.append("  <div class=\"card\">\n");
        html.append("    <h3>Melden</h3>\n");
        html.append("    <p>Drei Wege gleichzeitig: Ereignisprotokoll, Systemmeldung und Webhook.\n");
        html.append("       Fällt einer aus, steht der Wechsel trotzdem mit Zeitstempel fest.</p>\n");
        html.append("  </div>\n");
        html.append("</div>\n\n");
    }
    
    private static void appendAccessPoints(StringBuilder html) {
        html.append("<h2>Drei Zugänge, ein Monitor</h2>\n");
        html.append("<table>\n");
        html.append("  <tr><th>Zugang</th><th>wofür</th></tr>\n");
        html.append("  <tr><td><b>Installierte App</b></td>\n");
        html.append("      <td>Vollständige Oberfläche mit allen Reitern, eigenes Fenster ohne\n");
        html.append("          Adressleiste, Symbol im Startmenü</td></tr>\n");
        html.append("  <tr><td><b>Browser-Erweiterung</b></td>\n");
        html.append("      <td>Meldung beim Livegang, ohne dass ein Tab offen sein muss</td></tr>\n");
        html.append("  <tr><td><b>Live-Viewer</b></td>\n");
        html.append("      <td>Bettet den offiziellen Player ein — ohne Anmeldung, ohne Geschenk-\n");
        html.append("          oder Kauf-Oberfläche. <a href=\"/viewer\">Hier direkt ausprobieren.</a></td></tr>\n");
        html.append("</table>\n\n");
    }
    
    private static void appendSetup(StringBuilder html) {
        html.append("<h2>Einrichten</h2>\n");
        html.append("<ol class=\"steps\">\n");
        
        // Step 1
        html.append("  <li>\n");
        html.append("    <b>Repository holen</b>\n");
        html.append("    <p>Branch <code>Telegram-Monitor</code> auschecken.</p>\n");
        html.append("<pre><code>git clone -b Telegram-Monitor https://github.com/KikiKari/Projects.git\n");
        html.append("cd Projects</code></pre>\n");
        html.append("  </li>\n");
        
        // Step 2
        html.append("  <li>\n");
        html.append("    <b>Dauerhaft starten</b>\n");
        html.append("    <p>Bindet an <code>127.0.0.1:8765</code>, der Verlauf liegt im Volume\n");
        html.append("       <code>monitor-data</code> und überlebt jedes Neubauen. Unter Windows\n");
        html.append("       genügt ein Doppelklick auf <code>Telegram Monitor - Docker.cmd</code>.</p>\n");
        html.append("<pre><code>docker compose up -d --build</code></pre>\n");
        html.append("  </li>\n");
        
        // Step 3
        html.append("  <li>\n");
        html.append("    <b>Ohne Docker</b>\n");
        html.append("    <p>Der Kern braucht nur die Standardbibliothek — nichts zu installieren.</p>\n");
        html.append("<pre><code>python server.py --poll-interval 120</code></pre>\n");
        html.append("  </li>\n");
        
        // Step 4
        html.append("  <li>\n");
        html.append("    <b>Als App einrichten</b>\n");
        html.append("    <p>In der geöffneten Oberfläche auf <b>Als App installieren</b> klicken.\n");
        html.append("       Danach liegt der Monitor als eigenes Programm im Startmenü.</p>\n");
        html.append("  </li>\n");
        
        // Step 5
        html.append("  <li>\n");
        html.append("    <b>Aufs Telefon bringen</b>\n");
        html.append("    <p>Über das eigene VPN freigeben, dann die <code>https</code>-Adresse auf\n");
        html.append("       dem Telefon öffnen und dort installieren. Eine <code>.apk</code> gibt es\n");
        html.append("       nicht und wird auch nicht gebraucht.</p>\n");
        html.append("<pre><code>tailscale serve --bg 8765</code></pre>\n");
        html.append("  </li>\n");
        
        html.append("</ol>\n\n");
    }
    
    private static void appendLimitations(StringBuilder html) {
        html.append("<h2>Was hier nicht läuft</h2>\n");
        html.append("<div class=\"note\">\n");
        html.append("  <b>Diese Seite ist nur die Visitenkarte.</b>\n");
        html.append("  Der Monitor selbst läuft <i>nicht</i> im Web. Sein Kern ist ein\n");
        html.append("  Hintergrundprozess, der dauerhaft abfragt und Zustand auf die Platte\n");
        html.append("  schreibt — beides gibt es in einer serverlosen Umgebung nicht. Ausgeliefert\n");
        html.append("  werden hier nur diese Seite und der Viewer, der ohnehin ohne Server\n");
        html.append("  auskommt. Beobachtet wird auf deinem Rechner.\n");
        html.append("</div>\n\n");
    }
    
    private static void appendBoundaries(StringBuilder html) {
        html.append("<h2>Grenzen</h2>\n");
        html.append("<p>Gelesen wird ausschließlich, was öffentlich abrufbar ist. Anmeldeschranken\n");
        html.append("   und Zugriffssperren werden nicht umgangen — wo es offizielle Einbettungen\n");
        html.append("   gibt, werden die genommen. Private Telegram-Konten liefern nur Name und Bio;\n");
        html.append("   das ist eine Einschränkung von Telegram, kein Fehler.</p>\n");
        html.append("<p>Der Turnus bleibt höflich: ein bis fünf Minuten. Sekundentakt bringt selten\n");
        html.append("   mehr Information und handelt eine Sperre ein.</p>\n\n");
    }
    
    private static void appendFooter(StringBuilder html) {
        html.append("<footer>\n");
        html.append("  Läuft lokal, gehört dir. Das wiederverwendbare Muster dahinter steckt im Skill\n");
        html.append("  <code>lokaler-companion</code>.\n");
        html.append("</footer>\n");
    }
}
