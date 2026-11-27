// abstraction-provenance: {"artifact_sha256": "b06a0a65d1757df009393b989e796d53a67c496f45f472f252d8ad8b88bb881f", "source_sha256": "6f0520ae03891dc25c6d08a38907c3c9c1c5f8bb7d8a33172bd65cf6a1d074d9", "target_language": "java"}
// sidepanel.html — portiert nach java
// Quelle: html, Projects@vercel/install-and-configure-vercel-w-98sxlo:plugin-source/browser-extension/sidepanel.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Paths;

public class SidePanelGenerator {

    public static void main(String[] args) {
        if (args.length != 1) {
            System.err.println("Bitte geben Sie den Pfad zur Ausgabedatei an.");
            System.exit(1);
        }

        String outputPath = args[0];
        generateSidePanel(outputPath);
    }

    private static void generateSidePanel(String outputPath) {
        try (FileWriter writer = new FileWriter(Paths.get(outputPath).toFile())) {
            writer.write("<!doctype html>\n");
            writer.write("<html lang=\"de\">\n");
            writer.write("<head>\n");
            writer.write("  <meta charset=\"utf-8\">\n");
            writer.write("  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n");
            writer.write("  <title>TikTok LIVE Companion</title>\n");
            writer.write("  <link rel=\"stylesheet\" href=\"sidepanel.css\">\n");
            writer.write("</head>\n");
            writer.write("<body>\n");
            writer.write("  <header>\n");
            writer.write("    <p id=\"page-title\" class=\"muted\">Kein TikTok-Tab ausgewählt</p>\n");
            writer.write("  </header>\n\n");

            writeMainContent(writer);

            writer.write("\n  <script src=\"content-core.js\"></script>\n");
            writer.write("  <script src=\"sidepanel.js\"></script>\n");
            writer.write("</body>\n");
            writer.write("</html>\n");

        } catch (IOException e) {
            System.err.println("Fehler beim Schreiben der Datei: " + e.getMessage());
            System.exit(1);
        }
    }

    private static void writeMainContent(FileWriter writer) throws IOException {
        writer.write("  <main>\n");

        // Chat Section
        writer.write("    <section aria-labelledby=\"chat-heading\">\n");
        writer.write("      <div class=\"section-title\">\n");
        writer.write("        <h2 id=\"chat-heading\">Chat</h2>\n");
        writer.write("        <div class=\"title-actions\">\n");
        writer.write("          <span id=\"chat-led\" class=\"status-led off\" role=\"status\" aria-label=\"Chat inaktiv\" title=\"Chat inaktiv\"></span>\n");
        writer.write("          <button id=\"chat-count\" class=\"count count-button\" type=\"button\" aria-haspopup=\"dialog\" title=\"Gesammelte Chatzeilen öffnen\">0</button>\n");
        writer.write("          <button id=\"refresh-chat\" class=\"secondary compact\" title=\"Chatanzeige leeren\">Refresh</button>\n");
        writer.write("          <button id=\"toggle-speech\" class=\"secondary compact\" aria-pressed=\"false\" aria-label=\"Vorlesen\">On</button>\n");
        writer.write("          <span id=\"speech-led\" class=\"status-led off\" role=\"status\" aria-label=\"Vorlesen inaktiv\" title=\"Vorlesen inaktiv\"></span>\n");
        writer.write("        </div>\n");
        writer.write("      </div>\n");
        writer.write("      <div id=\"chat-list\" class=\"chat-list empty\" role=\"log\" aria-live=\"polite\" aria-relevant=\"additions\" aria-label=\"Die letzten fünf bereinigten Chatnachrichten\">Noch keine Chatnachrichten erkannt.</div>\n");
        writer.write("      <p id=\"speech-status\" role=\"status\" class=\"inline-status\">Vorlesen ist ausgeschaltet.</p>\n");
        writer.write("      <div class=\"control-label\"><label for=\"speech-volume\">Vorleselautstärke</label><output id=\"speech-volume-output\" for=\"speech-volume\">100%</output></div>\n");
        writer.write("      <input id=\"speech-volume\" type=\"range\" min=\"0\" max=\"100\" step=\"5\" value=\"50\">\n");
        writer.write("      <div class=\"button-row\">\n");
        writer.write("        <button id=\"service-action\" class=\"secondary\">Sprachdienst</button>\n");
        writer.write("        <button id=\"sherpa-action\" class=\"secondary\">Sherpa</button>\n");
        writer.write("        <button id=\"open-speech-settings\" class=\"secondary compact settings-button\" type=\"button\" aria-label=\"Erweiterte Einstellungen öffnen\" aria-haspopup=\"dialog\" title=\"Einstellungen\">⚙</button>\n");
        writer.write("      </div>\n");
        writer.write("      <p id=\"service-status\" class=\"inline-status\">Lokaler Sprachdienst noch nicht geprüft.</p>\n");
        writer.write("      <div id=\"service-setup\" class=\"inline-status\" hidden>\n");
        writer.write("        <button id=\"copy-service-setup\" class=\"secondary compact\">Installation abschließen!</button>\n");
        writer.write("      </div>\n");
        writer.write("      <label class=\"option-row\"><input id=\"keep-speech-active\" type=\"checkbox\"> Permanent aktiv</label>\n");
        writer.write("    </section>\n\n");

        // Top Chatters Section
        writer.write("    <section aria-labelledby=\"top-chatters-heading\">\n");
        writer.write("      <div class=\"section-title\">\n");
        writer.write("        <h2 id=\"top-chatters-heading\">Top-Chatter</h2>\n");
        writer.write("        <button id=\"open-audience\" class=\"secondary compact\">Zuschauer*innen</button>\n");
        writer.write("      </div>\n");
        writer.write("      <p id=\"team-tag-status\" class=\"inline-status\">Teamkürzel: noch nicht erkannt.</p>\n");
        writer.write("      <div id=\"top-chatters\" class=\"top-chatters empty\">Noch keine Personen im Chat beobachtet.</div>\n");
        writer.write("      <div id=\"top-chatters-actions\" class=\"top-chatters-actions\" hidden>\n");
        writer.write("        <button id=\"top-chatters-reset\" class=\"top-chatter-link\" type=\"button\" hidden>Reset</button>\n");
        writer.write("        <button id=\"top-chatters-more\" class=\"top-chatter-link\" type=\"button\">mehr…</button>\n");
        writer.write("      </div>\n");
        writer.write("    </section>\n\n");

        // Page Info Section
        writer.write("    <section id=\"page-info-section\" aria-labelledby=\"page-info-heading\">\n");
        writer.write("      <div class=\"section-title\">\n");
        writer.write("        <h2 id=\"page-info-heading\">PROFIL-Information</h2>\n");
        writer.write("        <div class=\"title-actions\">\n");
        writer.write("          <span id=\"page-info-source\" class=\"live-indicator\">Metadaten</span>\n");
        writer.write("          <button id=\"refresh-page-info\" class=\"secondary compact\">Refresh</button>\n");
        writer.write("          <button id=\"force-page-info\" class=\"secondary compact danger-outline\">Force</button>\n");
        writer.write("        </div>\n");
        writer.write("      </div>\n");
        writer.write("      <div id=\"profile-info\" class=\"profile-info\" hidden></div>\n");
        writer.write("      <div id=\"summary-info\" class=\"summary-info\"></div>\n");
        writer.write("    </section>\n\n");

        // Stats Section
        writer.write("    <section aria-labelledby=\"stats-heading\">\n");
        writer.write("      <div class=\"section-title\">\n");
        writer.write("        <h2 id=\"stats-heading\">LIVE-Information</h2>\n");
        writer.write("        <span id=\"stats-live\" class=\"live-indicator\">warte</span>\n");
        writer.write("      </div>\n");
        writer.write("      <div id=\"live-stats\" class=\"status-grid stats-grid\"></div>\n");
        writer.write("      <p id=\"stats-status\" class=\"inline-status\"></p>\n");
        writer.write("    </section>\n\n");

        // Hook Section
        writer.write("    <section aria-labelledby=\"hook-heading\">\n");
        writer.write("      <div class=\"section-title\">\n");
        writer.write("        <h2 id=\"hook-heading\">Connection</h2>\n");
        writer.write("        <span id=\"hook-led\" class=\"status-led off\" role=\"status\" aria-label=\"Hook inaktiv\" title=\"Hook inaktiv\"></span>\n");
        writer.write("      </div>\n");
        writer.write("      <div class=\"button-row\">\n");
        writer.write("        <button id=\"toggle-hook\" class=\"primary\" aria-label=\"Connection\" aria-pressed=\"false\">On</button>\n");
        writer.write("        <button id=\"reset-tab\" class=\"secondary danger-outline\">Refresh</button>\n");
        writer.write("        <button id=\"open-embed-live\" class=\"secondary\">Embed</button>\n");
        writer.write("        <button id=\"open-normal-live\" class=\"secondary\">Browser</button>\n");
        writer.write("        <button id=\"player-vlc-frame\" class=\"secondary compact\">Player</button>\n");
        writer.write("        <button id=\"open-connection-settings\" class=\"secondary compact settings-button\" type=\"button\" aria-label=\"Connection-Einstellungen öffnen\" aria-haspopup=\"dialog\">⚙</button>\n");
        writer.write("      </div>\n");
        writer.write("      <p id=\"hook-status\" class=\"inline-status\"></p>\n");
        writer.write("      <p id=\"embed-startup-status\" class=\"inline-status\" role=\"status\" aria-live=\"polite\" hidden></p>\n");
        writer.write("      <button id=\"cancel-embed-startup\" class=\"secondary\" hidden>Embed-Start abbrechen</button>\n");
        writer.write("      <label class=\"option-row\"><input id=\"hook-autostart\" type=\"checkbox\"> Permanent Hook</label>\n");
        writer.write("      <p id=\"hook-reconnect-status\" class=\"inline-status\" role=\"status\">Hook-Reconnect: aus</p>\n");
        writer.write("      <p id=\"player-recovery-status\" class=\"inline-status\" role=\"status\">Player-Recovery: aus</p>\n");
        writer.write("    </section>\n\n");

        // Recommendations Section
        writer.write("    <section id=\"recommendations-section\" aria-labelledby=\"recommendations-heading\">\n");
        writer.write("      <div class=\"section-title\">\n");
        writer.write("        <h2 id=\"recommendations-heading\">LIVE-Empfehlungen</h2>\n");
        writer.write("        <span id=\"recommendation-status\" class=\"live-indicator\">bereit</span>\n");
        writer.write("      </div>\n");
        writer.write("      <div class=\"recommendation-controls\">\n");
        writer.write("        <label><span>Anzahl</span><input id=\"recommendation-limit\" type=\"number\" min=\"1\" max=\"50\" step=\"1\" value=\"20\" inputmode=\"numeric\"></label>\n");
        writer.write("        <label><span>Sortierung</span><select id=\"recommendation-sort\"><option value=\"tiktok\">TikTok-Reihenfolge</option><option value=\"viewers\">Zuschauer*innen</option></select></label>\n");
        writer.write("      </div>\n");
        writer.write("      <div class=\"button-row\">\n");
        writer.write("        <button id=\"scan-recommendations\" class=\"primary\">Empfehlungen scannen</button>\n");
        writer.write("        <button id=\"cancel-recommendations\" class=\"secondary\" hidden>Abbrechen</button>\n");
        writer.write("      </div>\n");
        writer.write("      <p id=\"recommendation-progress\" class=\"inline-status\" aria-live=\"polite\">Noch kein Scan gestartet.</p>\n");
        writer.write("      <div id=\"recommendation-list\" class=\"recommendation-list empty\">Noch keine Empfehlungen erfasst.</div>\n");
        writer.write("      <div id=\"recommendation-actions\" class=\"top-chatters-actions\" hidden>\n");
        writer.write("        <button id=\"recommendation-more\" class=\"top-chatter-link\" type=\"button\">mehr…</button>\n");
        writer.write("      </div>\n");
        writer.write("    </section>\n\n");

        // Caption Section
        writer.write("    <section aria-labelledby=\"caption-heading\">\n");
        writer.write("      <div class=\"section-title\">\n");
        writer.write("        <h2 id=\"caption-heading\">Titel</h2>\n");
        writer.write("        <button id=\"scan\" class=\"secondary\">Seite prüfen</button>\n");
        writer.write("      </div>\n");
        writer.write("      <div id=\"caption-status\" class=\"status-grid\"></div>\n");
        writer.write("      <button id=\"enable-captions\" class=\"primary\">Untertitel aktivieren</button>\n");
        writer.write("      <p id=\"caption-action-status\" role=\"status\" class=\"inline-status action-status\"></p>\n");
        writer.write("    </section>\n\n");

        // Player Section
        writer.write("    <section aria-labelledby=\"player-heading\">\n");
        writer.write("      <div class=\"section-title\">\n");
        writer.write("        <h2 id=\"player-heading\">Player</h2>\n");
        writer.write("        <span id=\"player-time\" class=\"player-time\">–</span>\n");
        writer.write("      </div>\n");
        writer.write("      <div class=\"player-controls\" role=\"group\" aria-label=\"TikTok-Player steuern\">\n");
        writer.write("        <button id=\"player-play\" class=\"secondary compact\">Pause</button>\n");
        writer.write("        <button id=\"player-replay\" class=\"secondary compact\">Neu laden</button>\n");
        writer.write("        <button id=\"player-mute\" class=\"secondary compact\">Stumm</button>\n");
        writer.write("        <button id=\"player-pip\" class=\"secondary compact\">Bild-in-Bild</button>\n");
        writer.write("        <button id=\"player-fullscreen\" class=\"secondary compact\">Vollbild</button>\n");
        writer.write("        <button id=\"player-report\" class=\"secondary compact danger-outline\">Melden öffnen</button>\n");
        writer.write("      </div>\n");
        writer.write("      <div class=\"audio-controls\">\n");
        writer.write("        <div class=\"control-label\"><label for=\"player-volume\">Lautstärke</label><output id=\"player-volume-output\" for=\"player-volume\">–</output></div>\n");
        writer.write("        <input id=\"player-volume\" type=\"range\" min=\"0\" max=\"100\" step=\"1\" value=\"100\">\n");
        writer.write("        <div class=\"audio-meter-row\"><span>Spitzenpegel</span><strong id=\"player-peak\">–</strong></div>\n");
        writer.write("        <label class=\"option-row\"><input id=\"limiter-enabled\" type=\"checkbox\"> Pegelschutz aktivieren</label>\n");
        writer.write("        <div class=\"control-label\"><label for=\"limiter-strength\">Schutzstärke</label><output id=\"limiter-strength-output\" for=\"limiter-strength\">30</output></div>\n");
        writer.write("        <input id=\"limiter-strength\" type=\"range\" min=\"0\" max=\"100\" step=\"1\" value=\"30\">\n");
        writer.write("      </div>\n");
        writer.write("      <p id=\"multi-guest-status\" class=\"inline-status\">Verbundene Streams: noch nicht erkannt.</p>\n");
        writer.write("      <p id=\"player-status\" role=\"status\" class=\"inline-status\">Warte auf den TikTok-Player.</p>\n");
        writer.write("    </section>\n\n");

        // Song Section
        writer.write("    <section aria-labelledby=\"song-heading\">\n");
        writer.write("      <div class=\"section-title\">\n");
        writer.write("        <h2 id=\"song-heading\">Songs</h2>\n");
        writer.write("        <span id=\"song-led\" class=\"status-led off\" role=\"status\" aria-label=\"Songerkennung inaktiv\"></span>\n");
        writer.write("      </div>\n");
        writer.write("      <label class=\"option-row\"><input id=\"song-enabled\" type=\"checkbox\"> Songerkennung aktivieren</label>\n");
        writer.write("      <button id=\"recognize-song\" class=\"primary\" disabled>Jetzt erkennen</button>\n");
        writer.write("      <p id=\"song-status\" class=\"inline-status\"></p>\n");
        writer.write("      <div id=\"song-result\" class=\"song-result\" hidden></div>\n");
        writer.write("    </section>\n\n");

        // Links Section
        writer.write("    <section aria-labelledby=\"links-heading\">\n");
        writer.write("      <div class=\"section-title\">\n");
        writer.write("        <h2 id=\"links-heading\">HAR-Logs</h2>\n");
        writer.write("        <span id=\"media-count\" class=\"count\">0</span>\n");
        writer.write("      </div>\n");
        writer.write("      <div id=\"media-list\" class=\"list empty\">Noch keine FLV-/HLS-Links erkannt.</div>\n");
        writer.write("      <p class=\"hint\">Extern gestarteter VLC liegt außerhalb des Companion-Pegelschutzes.</p>\n");
        writer.write("    </section>\n\n");

        // Log Section
        writer.write("    <section aria-labelledby=\"log-heading\">\n");
        writer.write("      <div class=\"section-title\">\n");
        writer.write("        <h2 id=\"log-heading\">LIVE-Logs</h2>\n");
        writer.write("        <span id=\"caption-count\" class=\"count\">0</span>\n");
        writer.write("      </div>\n");
        writer.write("      <div class=\"button-row\">\n");
        writer.write("        <button id=\"export-log\" class=\"secondary\">JSON-L-Export</button>\n");
        writer.write("        <button id=\"export-caption-raw\" class=\"secondary\">RAW-JSON-Export</button>\n");
        writer.write("        <button id=\"clear\" class=\"ghost\">Anzeige leeren</button>\n");
        writer.write("      </div>\n");
        writer.write("      <div id=\"caption-list\" class=\"list empty\">Noch keine CaptionMessages empfangen.</div>\n");
        writer.write("    </section>\n\n");

        // Debug Section
        writer.write("    <section aria-labelledby=\"debug-heading\">\n");
        writer.write("      <div class=\"section-title\">\n");
        writer.write("        <h2 id=\"debug-heading\">Debugmodus</h2>\n");
        writer.write("        <span id=\"debug-count\" class=\"count\">0</span>\n");
        writer.write("      </div>\n");
        writer.write("      <label class=\"option-row\"><input id=\"debug-enabled\" type=\"checkbox\"> Diagnoseereignisse für diesen Tab protokollieren</label>\n");
        writer.write("      <div class=\"button-row\">\n");
        writer.write("        <button id=\"export-debug\" class=\"secondary\">Debug exportieren</button>\n");
        writer.write("        <button id=\"clear-debug\" class=\"ghost\">Debug leeren</button>\n");
        writer.write("      </div>\n");
        writer.write("      <p class=\"muted small\"></p>\n");
        writer.write("    </section>\n\n");

        // Audience Modal
        writer.write("    <div id=\"audience-modal\" class=\"modal-backdrop\" hidden>\n");
        writer.write("      <section class=\"modal\" role=\"dialog\" aria-modal=\"true\" aria-labelledby=\"audience-heading\">\n");
        writer.write("        <div class=\"section-title\">\n");
        writer.write("          <h2 id=\"audience-heading\">Im Chat beobachtete Personen</h2>\n");
        writer.write("          <button id=\"close-audience\" class=\"secondary compact\" aria-label=\"Übersicht schließen\">Schließen</button>\n");
        writer.write("        </div>\n");
        writer.write("        <p id=\"audience-limit\" class=\"inline-status\"></p>\n");
        writer.write("        <div id=\"audience-list\" class=\"audience-list\"></div>\n");
        writer.write("      </section>\n");
        writer.write("    </div>\n\n");

        // Speech Settings Modal
        writer.write("    <div id=\"speech-settings-modal\" class=\"modal-backdrop\" hidden>\n");
        writer.write("      <section class=\"modal\" role=\"dialog\" aria-modal=\"true\" aria-labelledby=\"speech-settings-heading\">\n");
        writer.write("        <div class=\"section-title\">\n");
        writer.write("          <h2 id=\"speech-settings-heading\">Erweiterte Einstellungen</h2>\n");
        writer.write("          <button id=\"close-speech-settings\" class=\"secondary compact\" aria-label=\"Einstellungen schließen\">Schließen</button>\n");
        writer.write("        </div>\n");
        writer.write("        <div class=\"settings-grid speech-integration-settings\">\n");
        writer.write("          <label><span>Sprache</span><select id=\"speech-language\"><option value=\"auto\">Auto</option><option value=\"de-DE\">Deutsch</option><option value=\"en-US\">Englisch</option><option value=\"ru-RU\">Russisch</option><option value=\"uk-UA\">Ukrainisch</option><option value=\"bg-BG\">Bulgarisch</option><option value=\"sr-RS\">Serbisch</option><option value=\"kk-KZ\">Kasachisch</option><option value=\"zh-CN\">Chinesisch</option><option value=\"ja-JP\">Japanisch</option><option value=\"ko-KR\">Koreanisch</option><option value=\"ar-JO\">Arabisch</option><option value=\"fa-IR\">Persisch</option><option value=\"ur-PK\">Urdu</option><option value=\"hi-IN\">Hindi</option><option value=\"ne-NP\">Nepali</option><option value=\"ml-IN\">Malayalam</option></select></label>\n");
        writer.write("          <label><span>Stimme</span><select id=\"speech-voice\"><option value=\"\">Standard</option></select></label>\n");
        writer.write("          <label id=\"audd-token-setting\"><span id=\"audd-token-label\">AudD API-Token (optional - <a href=\"https://audd.io/\" target=\"_blank\" rel=\"noopener noreferrer\">https://AudD.io</a> Trial/Paid)</span><input id=\"audd-token\" type=\"password\" autocomplete=\"off\" spellcheck=\"false\"></label>\n");
        writer.write("          <label id=\"pairing-code-setting\"><span>Pairing-Code</span><input id=\"pairing-code\" type=\"password\" autocomplete=\"off\" spellcheck=\"false\"></label>\n");
        writer.write("          <label><span>Universal API-Key</span><input id=\"universal-caption-api-key\" type=\"password\" autocomplete=\"off\" spellcheck=\"false\"></label>\n");
        writer.write("        </div>\n");
        writer.write("        <label class=\"option-row\"><input id=\"speak-names\" type=\"checkbox\" checked> Chatnamen sprechen</label>\n");
        writer.write("        <label class=\"option-row\"><input id=\"shorten-names\" type=\"checkbox\"> Chatnamen kürzen</label>\n");
        writer.write("        <label class=\"option-row auto-chat-refresh\"><input id=\"auto-chat-refresh\" type=\"checkbox\"> Auto-Chat Refresh <input id=\"auto-chat-refresh-minutes\" type=\"number\" min=\"1\" max=\"60\" step=\"1\" value=\"5\" inputmode=\"numeric\" aria-label=\"Auto-Chat-Refresh in Minuten\"><span>min.</span></label>\n");
        writer.write("        <label class=\"option-row\"><input id=\"game-mode\" type=\"checkbox\"> Game-Mode</label>\n");
        writer.write("        <label class=\"option-row\"><input id=\"filter-external-speech-triggers\" type=\"checkbox\"> Trigger externer Sprachdienste filtern</label>\n");
        writer.write("      </section>\n");
        writer.write("    </div>\n\n");

        // Chat History Modal
        writer.write("    <div id=\"chat-history-modal\" class=\"modal-backdrop\" hidden>\n");
        writer.write("      <section class=\"modal\" role=\"dialog\" aria-modal=\"true\" aria-labelledby=\"chat-history-heading\">\n");
        writer.write("        <div class=\"section-title\">\n");
        writer.write("          <h2 id=\"chat-history-heading\">Gesammelte Chatnachrichten</h2>\n");
        writer.write("          <button id=\"close-chat-history\" class=\"secondary compact\" aria-label=\"Chatzeilen schließen\">Schließen</button>\n");
        writer.write("        </div>\n");
        writer.write("        <p id=\"chat-history-limit\" class=\"inline-status\"></p>\n");
        writer.write("        <div id=\"chat-history-list\" class=\"chat-history-list\"></div>\n");
        writer.write("      </section>\n");
        writer.write("    </div>\n\n");

        // Recommendation Modal
        writer.write("    <div id=\"recommendation-modal\" class=\"modal-backdrop\" hidden>\n");
        writer.write("      <section class=\"modal\" role=\"dialog\" aria-modal=\"true\" aria-labelledby=\"recommendation-modal-heading\">\n");
        writer.write("        <div class=\"section-title\">\n");
        writer.write("          <h2 id=\"recommendation-modal-heading\">Gescannte LIVE-Empfehlungen</h2>\n");
        writer.write("          <button id=\"close-recommendations\" class=\"secondary compact\" aria-label=\"Empfehlungen schließen\">Schließen</button>\n");
        writer.write("        </div>\n");
        writer.write("        <div id=\"recommendation-modal-list\" class=\"recommendation-list\"></div>\n");
        writer.write("      </section>\n");
        writer.write("    </div>\n\n");

        // Notice and Connection Settings Modal
        writer.write("    <p id=\"notice\" role=\"alert\" class=\"notice\"></p>\n");
        writer.write("  </main>\n");
        writer.write("  <div id=\"connection-settings-modal\" class=\"modal-backdrop\" hidden>\n");
        writer.write("    <section class=\"modal\" role=\"dialog\" aria-modal=\"true\" aria-labelledby=\"connection-settings-heading\">\n");
        writer.write("      <div class=\"section-title\"><h2 id=\"connection-settings-heading\">Connection-Einstellungen</h2><button id=\"close-connection-settings\" class=\"secondary compact\">Schließen</button></div>\n");
        writer.write("      <label class=\"option-row quick-recover-setting\"><input id=\"hook-reconnect\" type=\"checkbox\"> Hook-Reconnect <input id=\"hook-reconnect-seconds\" type=\"number\" min=\"1\" max=\"59\" step=\"1\" value=\"3\" inputmode=\"numeric\" aria-label=\"Hook-Reconnect-Wartezeit in Sekunden\"><span>Sek.</span></label>\n");
        writer.write("      <label class=\"option-row quick-recover-setting\"><input id=\"quick-recover\" type=\"checkbox\"> Player-Recovery <input id=\"quick-recover-seconds\" type=\"number\" min=\"1\" max=\"59\" step=\"1\" value=\"3\" inputmode=\"numeric\" aria-label=\"Player-Recovery-Bestätigungszeit in Sekunden\"><span>Sek.</span></label>\n");
        writer.write("    </section>\n");
        writer.write("  </div>\n");
    }
}
