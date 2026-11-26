#!/usr/bin/env tclsh
# abstraction-provenance: {"artifact_sha256": "d5ec43324e460a89caf88b43ff72d940ba2de22ae8dc118a20c4acefbcfdedc9", "source_sha256": "58ad2830d3e11b79c54044cfe5a82e7e3fd2a9b1ca1f65c546ff6e92e821c6f3", "target_language": "tcl"}
# index.html — portiert nach tcl
# Quelle: html, Projects@Telegram-Monitor:public/index.html
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# Tcl 8.6 script to generate the Telegram Monitor HTML page
# Usage: tclsh telegram_monitor.tcl > output.html

proc generate_html {} {
    set html {}

    # Helper procedures for building HTML structure
    proc tag {name attrs content} {
        set attr_str ""
        foreach {key value} $attrs {
            append attr_str " $key=\"$value\""
        }
        if {$content eq ""} {
            return "<$name$attr_str>"
        } else {
            return "<$name$attr_str>$content</$name>"
        }
    }

    proc self_closing_tag {name attrs} {
        set attr_str ""
        foreach {key value} $attrs {
            append attr_str " $key=\"$value\""
        }
        return "<$name$attr_str>"
    }

    # Build the complete HTML document
    append html [self_closing_tag "!DOCTYPE" "html"]\n
    append html "<html lang=\"de\">\n"
    append html "<head>\n"
    append html [self_closing_tag "meta" "charset utf-8"]\n
    append html [self_closing_tag "meta" "name viewport content \"width=device-width, initial-scale=1\""]\n
    append html [tag "title" {} "Telegram Monitor — lokaler Beobachtungs-Companion"]\n
    append html [self_closing_tag "meta" "name description content \"Beobachtet öffentliche Telegram-Kanäle und TikTok-Konten auf dem eigenen Rechner und meldet den Livegang. Keine Cloud, keine Anmeldung.\""]\n
    append html [self_closing_tag "meta" "name theme-color content \"#2481cc\""]\n
    append html [self_closing_tag "meta" "property og:title content \"Telegram Monitor\""]\n
    append html [self_closing_tag "meta" "property og:description content \"Lokaler Beobachtungs-Companion. Docker, PWA, Meldung beim Livegang.\""]\n
    append html [self_closing_tag "meta" "property og:type content \"website\""]\n
    
    # CSS Styles
    append html "<style>\n"
    append html "  :root{\n"
    append html "    --bg:#ffffff; --soft:#f6f7f9; --line:#e3e6ea; --text:#16191d; --muted:#5f6773;\n"
    append html "    --tg:#2481cc; --tg-soft:#e8f2fb; --tt:#fe2c55;\n"
    append html "    --ok:#15803d; --ok-soft:#e7f6ec; --warn:#b45309; --warn-soft:#fdf3e3;\n"
    append html "    color-scheme: light;\n"
    append html "  }\n"
    append html "  @media (prefers-color-scheme: dark){\n"
    append html "    :root{ --bg:#0f1115; --soft:#171a21; --line:#262b36; --text:#f2f4f8; --muted:#9aa3b2;\n"
    append html "           --tg-soft:#132a3d; --ok-soft:#12261a; --warn-soft:#2c2110; color-scheme: dark; }\n"
    append html "  }\n"
    append html "  *{box-sizing:border-box}\n"
    append html "  body{margin:0;background:var(--bg);color:var(--text);\n"
    append html "       font:16px/1.6 -apple-system,BlinkMacSystemFont,\"Segoe UI\",Roboto,sans-serif}\n"
    append html "  .wrap{max-width:820px;margin:0 auto;padding:0 20px 72px}\n"
    append html "  header{padding:64px 0 40px;border-bottom:1px solid var(--line);margin-bottom:8px}\n"
    append html "  h1{font-size:34px;line-height:1.2;margin:0 0 12px;letter-spacing:-.02em}\n"
    append html "  .lede{font-size:18px;color:var(--muted);margin:0 0 22px;max-width:60ch}\n"
    append html "  h2{font-size:13px;margin:44px 0 14px;text-transform:uppercase;letter-spacing:.06em;\n"
    append html "     color:var(--muted);font-weight:650}\n"
    append html "  h3{font-size:17px;margin:26px 0 6px}\n"
    append html "  p{margin:0 0 14px;max-width:68ch}\n"
    append html "  .badges{display:flex;gap:7px;flex-wrap:wrap;margin-bottom:22px}\n"
    append html "  .badge{font-size:12px;font-weight:650;padding:4px 11px;border-radius:99px;\n"
    append html "         background:var(--soft);color:var(--muted);border:1px solid var(--line)}\n"
    append html "  .badge.on{background:var(--ok-soft);color:var(--ok);border-color:transparent}\n"
    append html "  .cta{display:flex;gap:10px;flex-wrap:wrap}\n"
    append html "  .btn{display:inline-block;font-weight:650;font-size:15px;padding:11px 20px;\n"
    append html "       border-radius:9px;text-decoration:none;border:1px solid var(--line);\n"
    append html "       background:var(--bg);color:var(--text)}\n"
    append html "  .btn.primary{background:var(--tg);border-color:var(--tg);color:#fff}\n"
    append html "  .btn:hover{border-color:var(--tg)}\n"
    append html "  .grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(230px,1fr));gap:14px}\n"
    append html "  .card{border:1px solid var(--line);border-radius:12px;padding:16px 18px;background:var(--bg)}\n"
    append html "  .card h3{margin-top:0;font-size:15.5px}\n"
    append html "  .card p{font-size:14px;color:var(--muted);margin:0}\n"
    append html "  ol.steps{list-style:none;counter-reset:s;padding:0;margin:0}\n"
    append html "  ol.steps li{counter-increment:s;position:relative;padding:0 0 20px 40px;\n"
    append html "              border-left:2px solid var(--line);margin-left:11px}\n"
    append html "  ol.steps li:last-child{border-left-color:transparent;padding-bottom:0}\n"
    append html "  ol.steps li::before{content:counter(s);position:absolute;left:-13px;top:0;\n"
    append html "       width:24px;height:24px;border-radius:50%;background:var(--tg);color:#fff;\n"
    append html "       display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:700}\n"
    append html "  ol.steps b{display:block;margin-bottom:3px}\n"
    append html "  ol.steps p{font-size:14.5px;color:var(--muted);margin:0 0 8px}\n"
    append html "  code{background:var(--soft);padding:2px 7px;border-radius:5px;font-size:13.5px;\n"
    append html "       font-family:ui-monospace,SFMono-Regular,Menlo,monospace;word-break:break-word}\n"
    append html "  pre{background:var(--soft);border:1px solid var(--line);border-radius:10px;\n"
    append html "      padding:13px 15px;overflow-x:auto;margin:0 0 14px}\n"
    append html "  pre code{background:none;padding:0;font-size:13.5px;line-height:1.7}\n"
    append html "  table{width:100%;border-collapse:collapse;font-size:14.5px;margin:0 0 16px}\n"
    append html "  th,td{text-align:left;padding:9px 11px;border-bottom:1px solid var(--line);vertical-align:top}\n"
    append html "  th{color:var(--muted);font-size:12px;text-transform:uppercase;letter-spacing:.04em;font-weight:650}\n"
    append html "  .note{border-left:3px solid var(--warn);background:var(--warn-soft);\n"
    append html "        border-radius:0 9px 9px 0;padding:13px 16px;margin:0 0 16px;font-size:14.5px}\n"
    append html "  .note b{display:block;margin-bottom:3px}\n"
    append html "  a{color:var(--tg)}\n"
    append html "  footer{margin-top:52px;padding-top:22px;border-top:1px solid var(--line);\n"
    append html "         font-size:13.5px;color:var(--muted)}\n"
    append html "</style>\n"
    append html "</head>\n"
    append html "<body>\n"
    append html "<div class=\"wrap\">\n\n"

    # Header section
    append html "<header>\n"
    append html "  <h1>Telegram Monitor</h1>\n"
    append html "  <p class=\"lede\">Beobachtet öffentliche Telegram-Kanäle und TikTok-Konten auf\n"
    append html "     deinem eigenen Rechner und meldet sich, wenn jemand live geht. Keine Cloud,\n"
    append html "     kein Konto, keine App-Installation auf dem Telefon nötig.</p>\n"
    append html "  <div class=\"badges\">\n"
    append html "    <span class=\"badge on\">Standardbibliothek</span>\n"
    append html "    <span class=\"badge on\">Docker</span>\n"
    append html "    <span class=\"badge on\">installierbar als App</span>\n"
    append html "    <span class=\"badge on\">Browser-Erweiterung</span>\n"
    append html "    <span class=\"badge\">Windows · macOS · Linux</span>\n"
    append html "  </div>\n"
    append html "  <div class=\"cta\">\n"
    append html "    <a class=\"btn primary\" href=\"https://github.com/KikiKari/Projects/tree/Telegram-Monitor\">Quelltext auf GitHub</a>\n"
    append html "    <a class=\"btn\" href=\"/viewer\">Live-Viewer öffnen</a>\n"
    append html "  </div>\n"
    append html "</header>\n\n"

    # What it does section
    append html "<h2>Was es tut</h2>\n"
    append html "<div class=\"grid\">\n"
    append html "  <div class=\"card\">\n"
    append html "    <h3>Beobachten</h3>\n"
    append html "    <p>Fragt jeden Kanal im eingestellten Turnus ab und sammelt den Verlauf auf\n"
    append html "       der Platte — neueste Beiträge oben, anders als in Telegram selbst.</p>\n"
    append html "  </div>\n"
    append html "  <div class=\"card\">\n"
    append html "    <h3>Erkennen</h3>\n"
    append html "    <p>Vergleicht den Zustand mit dem letzten Durchlauf. Gemeldet wird nur ein\n"
    append html "       echter Wechsel; ein fehlgeschlagener Abruf gilt nicht als „offline\".</p>\n"
    append html "  </div>\n"
    append html "  <div class=\"card\">\n"
    append html "    <h3>Melden</h3>\n"
    append html "    <p>Drei Wege gleichzeitig: Ereignisprotokoll, Systemmeldung und Webhook.\n"
    append html "       Fällt einer aus, steht der Wechsel trotzdem mit Zeitstempel fest.</p>\n"
    append html "  </div>\n"
    append html "</div>\n\n"

    # Three access points section
    append html "<h2>Drei Zugänge, ein Monitor</h2>\n"
    append html "<table>\n"
    append html "  <tr><th>Zugang</th><th>wofür</th></tr>\n"
    append html "  <tr><td><b>Installierte App</b></td>\n"
    append html "      <td>Vollständige Oberfläche mit allen Reitern, eigenes Fenster ohne\n"
    append html "          Adressleiste, Symbol im Startmenü</td></tr>\n"
    append html "  <tr><td><b>Browser-Erweiterung</b></td>\n"
    append html "      <td>Meldung beim Livegang, ohne dass ein Tab offen sein muss</td></tr>\n"
    append html "  <tr><td><b>Live-Viewer</b></td>\n"
    append html "      <td>Bettet den offiziellen Player ein — ohne Anmeldung, ohne Geschenk-\n"
    append html "          oder Kauf-Oberfläche. <a href=\"/viewer\">Hier direkt ausprobieren.</a></td></tr>\n"
    append html "</table>\n\n"

    # Setup section
    append html "<h2>Einrichten</h2>\n"
    append html "<ol class=\"steps\">\n"
    append html "  <li>\n"
    append html "    <b>Repository holen</b>\n"
    append html "    <p>Branch <code>Telegram-Monitor</code> auschecken.</p>\n"
    append html "<pre><code>git clone -b Telegram-Monitor https://github.com/KikiKari/Projects.git\n"
    append html "cd Projects</code></pre>\n"
    append html "  </li>\n"
    append html "  <li>\n"
    append html "    <b>Dauerhaft starten</b>\n"
    append html "    <p>Bindet an <code>127.0.0.1:8765</code>, der Verlauf liegt im Volume\n"
    append html "       <code>monitor-data</code> und überlebt jedes Neubauen. Unter Windows\n"
    append html "       genügt ein Doppelklick auf <code>Telegram Monitor - Docker.cmd</code>.</p>\n"
    append html "<pre><code>docker compose up -d --build</code></pre>\n"
    append html "  </li>\n"
    append html "  <li>\n"
    append html "    <b>Ohne Docker</b>\n"
    append html "    <p>Der Kern braucht nur die Standardbibliothek — nichts zu installieren.</p>\n"
    append html "<pre><code>python server.py --poll-interval 120</code></pre>\n"
    append html "  </li>\n"
    append html "  <li>\n"
    append html "    <b>Als App einrichten</b>\n"
    append html "    <p>In der geöffneten Oberfläche auf <b>Als App installieren</b> klicken.\n"
    append html "       Danach liegt der Monitor als eigenes Programm im Startmenü.</p>\n"
    append html "  </li>\n"
    append html "  <li>\n"
    append html "    <b>Aufs Telefon bringen</b>\n"
    append html "    <p>Über das eigene VPN freigeben, dann die <code>https</code>-Adresse auf\n"
    append html "       dem Telefon öffnen und dort installieren. Eine <code>.apk</code> gibt es\n"
    append html "       nicht und wird auch nicht gebraucht.</p>\n"
    append html "<pre><code>tailscale serve --bg 8765</code></pre>\n"
    append html "  </li>\n"
    append html "</ol>\n\n"

    # What doesn't run here section
    append html "<h2>Was hier nicht läuft</h2>\n"
    append html "<div class=\"note\">\n"
    append html "  <b>Diese Seite ist nur die Visitenkarte.</b>\n"
    append html "  Der Monitor selbst läuft <i>nicht</i> im Web. Sein Kern ist ein\n"
    append html "  Hintergrundprozess, der dauerhaft abfragt und Zustand auf die Platte\n"
    append html "  schreibt — beides gibt es in einer serverlosen Umgebung nicht. Ausgeliefert\n"
    append html "  werden hier nur diese Seite und der Viewer, der ohnehin ohne Server\n"
    append html "  auskommt. Beobachtet wird auf deinem Rechner.\n"
    append html "</div>\n\n"

    # Limitations section
    append html "<h2>Grenzen</h2>\n"
    append html "<p>Gelesen wird ausschließlich, was öffentlich abrufbar ist. Anmeldeschranken\n"
    append html "   und Zugriffssperren werden nicht umgangen — wo es offizielle Einbettungen\n"
    append html "   gibt, werden die genommen. Private Telegram-Konten liefern nur Name und Bio;\n"
    append html "   das ist eine Einschränkung von Telegram, kein Fehler.</p>\n"
    append html "<p>Der Turnus bleibt höflich: ein bis fünf Minuten. Sekundentakt bringt selten\n"
    append html "   mehr Information und handelt eine Sperre ein.</p>\n\n"

    # Footer
    append html "<footer>\n"
    append html "  Läuft lokal, gehört dir. Das wiederverwendbare Muster dahinter steckt im Skill\n"
    append html "  <code>lokaler-companion</code>.\n"
    append html "</footer>\n\n"

    append html "</div>\n"
    append html "</body>\n"
    append html "</html>\n"

    return $html
}

# Main execution
if {[info exists argv] && [llength $argv] > 0} {
    set filename [lindex $argv 0]
    set file [open $filename "w"]
    puts $file [generate_html]
    close $file
    puts "HTML content written to $filename"
} else {
    puts [generate_html]
}
