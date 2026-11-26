// abstraction-provenance: {"artifact_sha256": "e27462f4ef129e26f584251dc69fc738567c48d6265fa68a1b4671efa3558623", "source_sha256": "58ad2830d3e11b79c54044cfe5a82e7e3fd2a9b1ca1f65c546ff6e92e821c6f3", "target_language": "c"}
// index.html — portiert nach c
// Quelle: html, Projects@Telegram-Monitor:public/index.html
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void write_html_header(FILE *file) {
    fprintf(file, "<!DOCTYPE html>\n");
    fprintf(file, "<html lang=\"de\">\n<head>\n");
    fprintf(file, "<meta charset=\"utf-8\">\n");
    fprintf(file, "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n");
    fprintf(file, "<title>Telegram Monitor — lokaler Beobachtungs-Companion</title>\n");
    fprintf(file, "<meta name=\"description\" content=\"Beobachtet öffentliche Telegram-Kanäle und TikTok-Konten auf dem eigenen Rechner und meldet den Livegang. Keine Cloud, keine Anmeldung.\">\n");
    fprintf(file, "<meta name=\"theme-color\" content=\"#2481cc\">\n");
    fprintf(file, "<meta property=\"og:title\" content=\"Telegram Monitor\">\n");
    fprintf(file, "<meta property=\"og:description\" content=\"Lokaler Beobachtungs-Companion. Docker, PWA, Meldung beim Livegang.\">\n");
    fprintf(file, "<meta property=\"og:type\" content=\"website\">\n");
    fprintf(file, "<style>\n");
    fprintf(file, "  :root{\n");
    fprintf(file, "    --bg:#ffffff; --soft:#f6f7f9; --line:#e3e6ea; --text:#16191d; --muted:#5f6773;\n");
    fprintf(file, "    --tg:#2481cc; --tg-soft:#e8f2fb; --tt:#fe2c55;\n");
    fprintf(file, "    --ok:#15803d; --ok-soft:#e7f6ec; --warn:#b45309; --warn-soft:#fdf3e3;\n");
    fprintf(file, "    color-scheme: light;\n");
    fprintf(file, "  }\n");
    fprintf(file, "  @media (prefers-color-scheme: dark){\n");
    fprintf(file, "    :root{ --bg:#0f1115; --soft:#171a21; --line:#262b36; --text:#f2f4f8; --muted:#9aa3b2;\n");
    fprintf(file, "           --tg-soft:#132a3d; --ok-soft:#12261a; --warn-soft:#2c2110; color-scheme: dark; }\n");
    fprintf(file, "  }\n");
    fprintf(file, "  *{box-sizing:border-box}\n");
    fprintf(file, "  body{margin:0;background:var(--bg);color:var(--text);\n");
    fprintf(file, "       font:16px/1.6 -apple-system,BlinkMacSystemFont,\"Segoe UI\",Roboto,sans-serif}\n");
    fprintf(file, "  .wrap{max-width:820px;margin:0 auto;padding:0 20px 72px}\n");
    fprintf(file, "  header{padding:64px 0 40px;border-bottom:1px solid var(--line);margin-bottom:8px}\n");
    fprintf(file, "  h1{font-size:34px;line-height:1.2;margin:0 0 12px;letter-spacing:-.02em}\n");
    fprintf(file, "  .lede{font-size:18px;color:var(--muted);margin:0 0 22px;max-width:60ch}\n");
    fprintf(file, "  h2{font-size:13px;margin:44px 0 14px;text-transform:uppercase;letter-spacing:.06em;\n");
    fprintf(file, "     color:var(--muted);font-weight:650}\n");
    fprintf(file, "  h3{font-size:17px;margin:26px 0 6px}\n");
    fprintf(file, "  p{margin:0 0 14px;max-width:68ch}\n");
    fprintf(file, "  .badges{display:flex;gap:7px;flex-wrap:wrap;margin-bottom:22px}\n");
    fprintf(file, "  .badge{font-size:12px;font-weight:650;padding:4px 11px;border-radius:99px;\n");
    fprintf(file, "         background:var(--soft);color:var(--muted);border:1px solid var(--line)}\n");
    fprintf(file, "  .badge.on{background:var(--ok-soft);color:var(--ok);border-color:transparent}\n");
    fprintf(file, "  .cta{display:flex;gap:10px;flex-wrap:wrap}\n");
    fprintf(file, "  .btn{display:inline-block;font-weight:650;font-size:15px;padding:11px 20px;\n");
    fprintf(file, "       border-radius:9px;text-decoration:none;border:1px solid var(--line);\n");
    fprintf(file, "       background:var(--bg);color:var(--text)}\n");
    fprintf(file, "  .btn.primary{background:var(--tg);border-color:var(--tg);color:#fff}\n");
    fprintf(file, "  .btn:hover{border-color:var(--tg)}\n");
    fprintf(file, "  .grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(230px,1fr));gap:14px}\n");
    fprintf(file, "  .card{border:1px solid var(--line);border-radius:12px;padding:16px 18px;background:var(--bg)}\n");
    fprintf(file, "  .card h3{margin-top:0;font-size:15.5px}\n");
    fprintf(file, "  .card p{font-size:14px;color:var(--muted);margin:0}\n");
    fprintf(file, "  ol.steps{list-style:none;counter-reset:s;padding:0;margin:0}\n");
    fprintf(file, "  ol.steps li{counter-increment:s;position:relative;padding:0 0 20px 40px;\n");
    fprintf(file, "              border-left:2px solid var(--line);margin-left:11px}\n");
    fprintf(file, "  ol.steps li:last-child{border-left-color:transparent;padding-bottom:0}\n");
    fprintf(file, "  ol.steps li::before{content:counter(s);position:absolute;left:-13px;top:0;\n");
    fprintf(file, "       width:24px;height:24px;border-radius:50%%;background:var(--tg);color:#fff;\n");
    fprintf(file, "       display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:700}\n");
    fprintf(file, "  ol.steps b{display:block;margin-bottom:3px}\n");
    fprintf(file, "  ol.steps p{font-size:14.5px;color:var(--muted);margin:0 0 8px}\n");
    fprintf(file, "  code{background:var(--soft);padding:2px 7px;border-radius:5px;font-size:13.5px;\n");
    fprintf(file, "       font-family:ui-monospace,SFMono-Regular,Menlo,monospace;word-break:break-word}\n");
    fprintf(file, "  pre{background:var(--soft);border:1px solid var(--line);border-radius:10px;\n");
    fprintf(file, "      padding:13px 15px;overflow-x:auto;margin:0 0 14px}\n");
    fprintf(file, "  pre code{background:none;padding:0;font-size:13.5px;line-height:1.7}\n");
    fprintf(file, "  table{width:100%%;border-collapse:collapse;font-size:14.5px;margin:0 0 16px}\n");
    fprintf(file, "  th,td{text-align:left;padding:9px 11px;border-bottom:1px solid var(--line);vertical-align:top}\n");
    fprintf(file, "  th{color:var(--muted);font-size:12px;text-transform:uppercase;letter-spacing:.04em;font-weight:650}\n");
    fprintf(file, "  .note{border-left:3px solid var(--warn);background:var(--warn-soft);\n");
    fprintf(file, "        border-radius:0 9px 9px 0;padding:13px 16px;margin:0 0 16px;font-size:14.5px}\n");
    fprintf(file, "  .note b{display:block;margin-bottom:3px}\n");
    fprintf(file, "  a{color:var(--tg)}\n");
    fprintf(file, "  footer{margin-top:52px;padding-top:22px;border-top:1px solid var(--line);\n");
    fprintf(file, "         font-size:13.5px;color:var(--muted)}\n");
    fprintf(file, "</style>\n");
    fprintf(file, "</head>\n<body>\n<div class=\"wrap\">\n\n");
}

void write_html_footer(FILE *file) {
    fprintf(file, "\n</div>\n</body>\n</html>\n");
}

void write_header_section(FILE *file) {
    fprintf(file, "<header>\n");
    fprintf(file, "  <h1>Telegram Monitor</h1>\n");
    fprintf(file, "  <p class=\"lede\">Beobachtet öffentliche Telegram-Kanäle und TikTok-Konten auf\n");
    fprintf(file, "     deinem eigenen Rechner und meldet sich, wenn jemand live geht. Keine Cloud,\n");
    fprintf(file, "     kein Konto, keine App-Installation auf dem Telefon nötig.</p>\n");
    fprintf(file, "  <div class=\"badges\">\n");
    fprintf(file, "    <span class=\"badge on\">Standardbibliothek</span>\n");
    fprintf(file, "    <span class=\"badge on\">Docker</span>\n");
    fprintf(file, "    <span class=\"badge on\">installierbar als App</span>\n");
    fprintf(file, "    <span class=\"badge on\">Browser-Erweiterung</span>\n");
    fprintf(file, "    <span class=\"badge\">Windows · macOS · Linux</span>\n");
    fprintf(file, "  </div>\n");
    fprintf(file, "  <div class=\"cta\">\n");
    fprintf(file, "    <a class=\"btn primary\" href=\"https://github.com/KikiKari/Projects/tree/Telegram-Monitor\">Quelltext auf GitHub</a>\n");
    fprintf(file, "    <a class=\"btn\" href=\"/viewer\">Live-Viewer öffnen</a>\n");
    fprintf(file, "  </div>\n");
    fprintf(file, "</header>\n\n");
}

void write_features_section(FILE *file) {
    fprintf(file, "<h2>Was es tut</h2>\n");
    fprintf(file, "<div class=\"grid\">\n");
    fprintf(file, "  <div class=\"card\">\n");
    fprintf(file, "    <h3>Beobachten</h3>\n");
    fprintf(file, "    <p>Fragt jeden Kanal im eingestellten Turnus ab und sammelt den Verlauf auf\n");
    fprintf(file, "       der Platte — neueste Beiträge oben, anders als in Telegram selbst.</p>\n");
    fprintf(file, "  </div>\n");
    fprintf(file, "  <div class=\"card\">\n");
    fprintf(file, "    <h3>Erkennen</h3>\n");
    fprintf(file, "    <p>Vergleicht den Zustand mit dem letzten Durchlauf. Gemeldet wird nur ein\n");
    fprintf(file, "       echter Wechsel; ein fehlgeschlagener Abruf gilt nicht als „offline\".</p>\n");
    fprintf(file, "  </div>\n");
    fprintf(file, "  <div class=\"card\">\n");
    fprintf(file, "    <h3>Melden</h3>\n");
    fprintf(file, "    <p>Drei Wege gleichzeitig: Ereignisprotokoll, Systemmeldung und Webhook.\n");
    fprintf(file, "       Fällt einer aus, steht der Wechsel trotzdem mit Zeitstempel fest.</p>\n");
    fprintf(file, "  </div>\n");
    fprintf(file, "</div>\n\n");
}

void write_access_modes_section(FILE *file) {
    fprintf(file, "<h2>Drei Zugänge, ein Monitor</h2>\n");
    fprintf(file, "<table>\n");
    fprintf(file, "  <tr><th>Zugang</th><th>wofür</th></tr>\n");
    fprintf(file, "  <tr><td><b>Installierte App</b></td>\n");
    fprintf(file, "      <td>Vollständige Oberfläche mit allen Reitern, eigenes Fenster ohne\n");
    fprintf(file, "          Adressleiste, Symbol im Startmenü</td></tr>\n");
    fprintf(file, "  <tr><td><b>Browser-Erweiterung</b></td>\n");
    fprintf(file, "      <td>Meldung beim Livegang, ohne dass ein Tab offen sein muss</td></tr>\n");
    fprintf(file, "  <tr><td><b>Live-Viewer</b></td>\n");
    fprintf(file, "      <td>Bettet den offiziellen Player ein — ohne Anmeldung, ohne Geschenk-\n");
    fprintf(file, "          oder Kauf-Oberfläche. <a href=\"/viewer\">Hier direkt ausprobieren.</a></td></tr>\n");
    fprintf(file, "</table>\n\n");
}

void write_setup_section(FILE *file) {
    fprintf(file, "<h2>Einrichten</h2>\n");
    fprintf(file, "<ol class=\"steps\">\n");
    fprintf(file, "  <li>\n");
    fprintf(file, "    <b>Repository holen</b>\n");
    fprintf(file, "    <p>Branch <code>Telegram-Monitor</code> auschecken.</p>\n");
    fprintf(file, "<pre><code>git clone -b Telegram-Monitor https://github.com/KikiKari/Projects.git\n");
    fprintf(file, "cd Projects</code></pre>\n");
    fprintf(file, "  </li>\n");
    fprintf(file, "  <li>\n");
    fprintf(file, "    <b>Dauerhaft starten</b>\n");
    fprintf(file, "    <p>Bindet an <code>127.0.0.1:8765</code>, der Verlauf liegt im Volume\n");
    fprintf(file, "       <code>monitor-data</code> und überlebt jedes Neubauen. Unter Windows\n");
    fprintf(file, "       genügt ein Doppelklick auf <code>Telegram Monitor - Docker.cmd</code>.</p>\n");
    fprintf(file, "<pre><code>docker compose up -d --build</code></pre>\n");
    fprintf(file, "  </li>\n");
    fprintf(file, "  <li>\n");
    fprintf(file, "    <b>Ohne Docker</b>\n");
    fprintf(file, "    <p>Der Kern braucht nur die Standardbibliothek — nichts zu installieren.</p>\n");
    fprintf(file, "<pre><code>python server.py --poll-interval 120</code></pre>\n");
    fprintf(file, "  </li>\n");
    fprintf(file, "  <li>\n");
    fprintf(file, "    <b>Als App einrichten</b>\n");
    fprintf(file, "    <p>In der geöffneten Oberfläche auf <b>Als App installieren</b> klicken.\n");
    fprintf(file, "       Danach liegt der Monitor als eigenes Programm im Startmenü.</p>\n");
    fprintf(file, "  </li>\n");
    fprintf(file, "  <li>\n");
    fprintf(file, "    <b>Aufs Telefon bringen</b>\n");
    fprintf(file, "    <p>Über das eigene VPN freigeben, dann die <code>https</code>-Adresse auf\n");
    fprintf(file, "       dem Telefon öffnen und dort installieren. Eine <code>.apk</code> gibt es\n");
    fprintf(file, "       nicht und wird auch nicht gebraucht.</p>\n");
    fprintf(file, "<pre><code>tailscale serve --bg 8765</code></pre>\n");
    fprintf(file, "  </li>\n");
    fprintf(file, "</ol>\n\n");
}

void write_limitations_section(FILE *file) {
    fprintf(file, "<h2>Was hier nicht läuft</h2>\n");
    fprintf(file, "<div class=\"note\">\n");
    fprintf(file, "  <b>Diese Seite ist nur die Visitenkarte.</b>\n");
    fprintf(file, "  Der Monitor selbst läuft <i>nicht</i> im Web. Sein Kern ist ein\n");
    fprintf(file, "  Hintergrundprozess, der dauerhaft abfragt und Zustand auf die Platte\n");
    fprintf(file, "  schreibt — beides gibt es in einer serverlosen Umgebung nicht. Ausgeliefert\n");
    fprintf(file, "  werden hier nur diese Seite und der Viewer, der ohnehin ohne Server\n");
    fprintf(file, "  auskommt. Beobachtet wird auf deinem Rechner.\n");
    fprintf(file, "</div>\n\n");
    
    fprintf(file, "<h2>Grenzen</h2>\n");
    fprintf(file, "<p>Gelesen wird ausschließlich, was öffentlich abrufbar ist. Anmeldeschranken\n");
    fprintf(file, "   und Zugriffssperren werden nicht umgangen — wo es offizielle Einbettungen\n");
    fprintf(file, "   gibt, werden die genommen. Private Telegram-Konten liefern nur Name und Bio;\n");
    fprintf(file, "   das ist eine Einschränkung von Telegram, kein Fehler.</p>\n");
    fprintf(file, "<p>Der Turnus bleibt höflich: ein bis fünf Minuten. Sekundentakt bringt selten\n");
    fprintf(file, "   mehr Information und handelt eine Sperre ein.</p>\n\n");
}

void write_footer_section(FILE *file) {
    fprintf(file, "<footer>\n");
    fprintf(file, "  Läuft lokal, gehört dir. Das wiederverwendbare Muster dahinter steckt im Skill\n");
    fprintf(file, "  <code>lokaler-companion</code>.\n");
    fprintf(file, "</footer>\n\n");
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Verwendung: %s <ausgabedatei>\n", argv[0]);
        return 1;
    }
    
    FILE *output_file = fopen(argv[1], "w");
    if (!output_file) {
        perror("Fehler beim Öffnen der Ausgabedatei");
        return 1;
    }
    
    write_html_header(output_file);
    write_header_section(output_file);
    write_features_section(output_file);
    write_access_modes_section(output_file);
    write_setup_section(output_file);
    write_limitations_section(output_file);
    write_footer_section(output_file);
    write_html_footer(output_file);
    
    fclose(output_file);
    return 0;
}
