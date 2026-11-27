// abstraction-provenance: {"artifact_sha256": "8513d78095707c5f9f2ec2885cfcdd04c707d2a0d60f7fa4ee008364a1167367", "source_sha256": "6c68f7375733776fa70f0fd1e48fe739ffdf7c38b6444a8ef7c36fd50e4d08e9", "target_language": "cpp"}
// sidepanel.html — portiert nach cpp
// Quelle: html, Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/sidepanel.html
// auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/sidepanel.html
// auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/browser-extension/sidepanel.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <fstream>
#include <string>

void generateHTML(const std::string& filename) {
    std::ofstream file(filename);
    if (!file.is_open()) {
        std::cerr << "Fehler beim Öffnen der Datei: " << filename << std::endl;
        return;
    }

    file << "<!doctype html>\n";
    file << "<html lang=\"de\">\n";
    file << "<head>\n";
    file << "  <meta charset=\"utf-8\">\n";
    file << "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n";
    file << "  <title>TikTok LIVE Companion</title>\n";
    file << "  <link rel=\"stylesheet\" href=\"sidepanel.css\">\n";
    file << "  <link rel=\"stylesheet\" href=\"icon-controls.css\">\n";
    file << "</head>\n";
    file << "<body>\n";
    file << "  <header>\n";
    file << "    <p id=\"page-title\" class=\"muted\">Kein TikTok-Tab ausgewählt</p>\n";
    file << "  </header>\n\n";
    file << "  <main>\n";
    
    // Chat Section
    file << "    <section aria-labelledby=\"chat-heading\">\n";
    file << "      <div class=\"section-title\">\n";
    file << "        <h2 id=\"chat-heading\">Chat</h2>\n";
    file << "        <div class=\"title-actions\">\n";
    file << "          <span id=\"chat-led\" class=\"status-led off\" role=\"status\" aria-label=\"Chat inaktiv\" title=\"Chat inaktiv\"></span>\n";
    file << "          <button id=\"chat-count\" class=\"count count-button\" type=\"button\" aria-haspopup=\"dialog\" title=\"Gesammelte Chatzeilen öffnen\">0</button>\n";
    file << "          <button id=\"refresh-chat\" class=\"secondary compact\" title=\"Chatanzeige leeren\">Reset</button>\n";
    file << "          <button id=\"toggle-speech\" class=\"secondary compact\" aria-pressed=\"false\" aria-label=\"Vorlesen\">On</button>\n";
    file << "          <span id=\"speech-led\" class=\"status-led off\" role=\"status\" aria-label=\"Vorlesen inaktiv\" title=\"Vorlesen inaktiv\"></span>\n";
    file << "        </div>\n";
    file << "      </div>\n";
    file << "      <div id=\"chat-list\" class=\"chat-list empty\" role=\"log\" aria-live=\"polite\" aria-relevant=\"additions\" aria-label=\"Die letzten fünf bereinigten Chatnachrichten\">Noch keine Chatnachrichten erkannt.</div>\n";
    file << "      <p id=\"speech-status\" role=\"status\" class=\"inline-status\">Vorlesen ist ausgeschaltet.</p>\n";
    file << "      <div class=\"control-label\"><label for=\"speech-volume\">Vorleselautstärke</label><output id=\"speech-volume-output\" for=\"speech-volume\">100%</output></div>\n";
    file << "      <input id=\"speech-volume\" type=\"range\" min=\"0\" max=\"100\" step=\"5\" value=\"50\">\n";
    file << "      <div class=\"button-row\">\n";
    file << "        <button id=\"service-action\" class=\"secondary\">Sprachdienst</button>\n";
    file << "        <button id=\"sherpa-action\" class=\"secondary\">Sherpa</button>\n";
    file << "        <button id=\"open-speech-settings\" class=\"secondary compact settings-button\" type=\"button\" aria-label=\"Erweiterte Einstellungen öffnen\" aria-haspopup=\"dialog\" title=\"Einstellungen\"></button>\n";
    file << "      </div>\n";
    file << "      <p id=\"service-status\" class=\"inline-status\">Lokaler Sprachdienst noch nicht geprüft.</p>\n";
    file << "      <div id=\"service-setup\" class=\"inline-status\" hidden>\n";
    file << "        <button id=\"copy-service-setup\" class=\"secondary compact\">Installation abschließen!</button>\n";
    file << "      </div>\n";
    file << "    </section>\n\n";
    
    // Stats Section
    file << "    <section aria-labelledby=\"stats-heading\">\n";
    file << "      <div class=\"section-title\">\n";
    file << "        <h2 id=\"stats-heading\">LIVE-Information</h2>\n";
    file << "        <span id=\"stats-live\" class=\"live-indicator\">warte</span>\n";
    file << "      </div>\n";
    file << "      <div id=\"live-stats\" class=\"status-grid stats-grid\"></div>\n";
    file << "      <p id=\"stats-status\" class=\"inline-status\"></p>\n";
    file << "    </section>\n\n";
    
    // Page Info Section
    file << "    <section id=\"page-info-section\" aria-labelledby=\"page-info-heading\">\n";
    file << "      <div class=\"section-title\">\n";
    file << "        <h2 id=\"page-info-heading\">PROFIL-Information</h2>\n";
    file << "        <div class=\"title-actions\">\n";
    file << "          <span id=\"page-info-source\" class=\"live-indicator\">Metadaten</span>\n";
    file << "          <button id=\"refresh-page-info\" class=\"secondary compact\" title=\"Refresh\">Refresh</button>\n";
    file << "          <button id=\"force-page-info\" class=\"secondary compact danger-outline\">Force</button>\n";
    file << "        </div>\n";
    file << "      </div>\n";
    file << "      <div id=\"profile-info\" class=\"profile-info\" hidden></div>\n";
    file << "      <div id=\"summary-info\" class=\"summary-info\"></div>\n";
    file << "    </section>\n\n";
    
    // Connection Section
    file << "    <section aria-labelledby=\"hook-heading\">\n";
    file << "      <div class=\"section-title header-controls\">\n";
    file << "        <h2 id=\"hook-heading\">Connection</h2>\n";
    file << "        <div class=\"title-actions\">\n";
    file << "          <button id=\"reset-tab\" class=\"secondary compact danger-outline\" title=\"Reset\">Reset</button>\n";
    file << "          <input id=\"hook-autostart\" type=\"checkbox\" aria-label=\"Hook dauerhaft\" title=\"Hook dauerhaft: Off\">\n";
    file << "          <span class=\"status-led off\" data-switch-status=\"hook-autostart\" role=\"status\"></span>\n";
    file << "        </div>\n";
    file << "      </div>\n";
    file << "      <div class=\"button-row\">\n";
    file << "        <button id=\"toggle-hook\" class=\"primary\" aria-label=\"Connection\" aria-pressed=\"false\">On</button>\n";
    file << "        <button id=\"open-connection-settings\" class=\"secondary compact settings-button\" type=\"button\" aria-label=\"Connection-Einstellungen öffnen\" aria-haspopup=\"dialog\"></button>\n";
    file << "        <button id=\"open-embed-live\" class=\"secondary\">Embed</button>\n";
    file << "        <button id=\"open-normal-live\" class=\"secondary\">Browser</button>\n";
    file << "        <button id=\"player-vlc-frame\" class=\"secondary compact\">Player</button>\n";
    file << "      </div>\n";
    file << "      <div class=\"connection-status\"><span id=\"hook-led\" class=\"status-led off\" role=\"status\" aria-label=\"Hook inaktiv\" title=\"Hook inaktiv\"></span><p id=\"hook-status\" class=\"inline-status\"></p></div>\n";
    file << "      <p id=\"embed-startup-status\" class=\"inline-status\" role=\"status\" aria-live=\"polite\" hidden></p>\n";
    file << "      <button id=\"cancel-embed-startup\" class=\"secondary\" hidden>Embed-Start abbrechen</button>\n";
    file << "      <p id=\"hook-reconnect-status\" class=\"inline-status\" role=\"status\">Hook-Reconnect: aus</p>\n";
    file << "      <p id=\"player-recovery-status\" class=\"inline-status\" role=\"status\">Player-Recovery: aus</p>\n";
    file << "    </section>\n\n";
    
    // Player Section
    file << "    <section aria-labelledby=\"player-heading\">\n";
    file << "      <div class=\"section-title header-controls\">\n";
    file << "        <h2 id=\"player-heading\">Player</h2>\n";
    file << "        <div class=\"title-actions\">\n";
    file << "          <button id=\"player-replay\" class=\"secondary compact\" title=\"Neu laden\">Neu laden</button>\n";
    file << "          <input id=\"limiter-enabled\" type=\"checkbox\" aria-label=\"Pegelschutz\" title=\"Pegelschutz: Off\">\n";
    file << "          <span class=\"status-led off\" data-switch-status=\"limiter-enabled\" role=\"status\"></span>\n";
    file << "        </div>\n";
    file << "      </div>\n";
    file << "      <div class=\"player-controls\" role=\"group\" aria-label=\"TikTok-Player steuern\">\n";
    file << "        <button id=\"player-play\" class=\"secondary compact\">Play</button>\n";
    file << "        <button id=\"player-mute\" class=\"secondary compact\">Mute</button>\n";
    file << "        <button id=\"player-pip\" class=\"secondary compact\">Bild-in-Bild</button>\n";
    file << "        <button id=\"player-fullscreen\" class=\"secondary compact\">Vollbild</button>\n";
    file << "        <button id=\"player-report\" class=\"secondary compact danger-outline\">Meldung</button>\n";
    file << "      </div>\n";
    file << "      <div class=\"audio-controls\">\n";
    file << "        <div class=\"control-label\"><label for=\"player-volume\">Lautstärke</label><output id=\"player-volume-output\" for=\"player-volume\">–</output></div>\n";
    file << "        <input id=\"player-volume\" type=\"range\" min=\"0\" max=\"100\" step=\"1\" value=\"100\">\n";
    file << "        <div class=\"audio-meter-row\"><span>Spitzenpegel</span><strong id=\"player-peak\">–</strong></div>\n";
    file << "        <div class=\"control-label\"><label for=\"limiter-strength\">Schutzstärke</label><output id=\"limiter-strength-output\" for=\"limiter-strength\">30</output></div>\n";
    file << "        <input id=\"limiter-strength\" type=\"range\" min=\"0\" max=\"100\" step=\"1\" value=\"30\">\n";
    file << "      </div>\n";
    file << "      <p id=\"multi-guest-status\" class=\"inline-status\">Verbundene Streams: noch nicht erkannt.</p>\n";
    file << "      <p id=\"player-status\" role=\"status\" class=\"inline-status\">Warte auf den TikTok-Player.</p>\n";
    file << "      <span id=\"player-time\" class=\"player-time\" hidden>–</span>\n";
    file << "    </section>\n\n";
    
    // Top Chatters Section
    file << "    <section aria-labelledby=\"top-chatters-heading\">\n";
    file << "      <div class=\"section-title\">\n";
    file << "        <h2 id=\"top-chatters-heading\">Top-Chatter</h2>\n";
    file << "        <button id=\"open-audience\" class=\"secondary compact\">Zuschauer*innen</button>\n";
    file << "      </div>\n";
    file << "      <p id=\"team-tag-status\" class=\"inline-status\">Teamkürzel: noch nicht erkannt.</p>\n";
    file << "      <div id=\"top-chatters\" class=\"top-chatters empty\">Noch keine Personen im Chat beobachtet.</div>\n";
    file << "      <div id=\"top-chatters-actions\" class=\"top-chatters-actions\" hidden>\n";
    file << "        <button id=\"top-chatters-reset\" class=\"top-chatter-link\" type=\"button\" hidden>Reset</button>\n";
    file << "        <button id=\"top-chatters-more\" class=\"top-chatter-link\" type=\"button\">mehr…</button>\n";
    file << "      </div>\n";
    file << "    </section>\n\n";
    
    // Recommendations Section
    file << "    <section id=\"recommendations-section\" aria-labelledby=\"recommendations-heading\">\n";
    file << "      <div class=\"section-title\">\n";
    file << "        <h2 id=\"recommendations-heading\">LIVE-Empfehlungen</h2>\n";
    file << "        <span id=\"recommendation-status\" class=\"live-indicator\">bereit</span>\n";
    file << "      </div>\n";
    file << "      <div class=\"recommendation-controls\">\n";
    file << "        <label><span>Anzahl</span><input id=\"recommendation-limit\" type=\"number\" min=\"1\" max=\"300\" step=\"1\" value=\"20\" inputmode=\"numeric\"></label>\n";
    file << "        <label><span>Sortierung</span><select id=\"recommendation-sort\"><option value=\"tiktok\">TikTok-Reihenfolge</option><option value=\"viewers\">Zuschauer*innen</option></select></label>\n";
    file << "      </div>\n";
    file << "      <div class=\"button-row\">\n";
    file << "        <button id=\"scan-recommendations\" class=\"primary\">Empfehlungen scannen</button>\n";
    file << "        <button id=\"cancel-recommendations\" class=\"secondary\" hidden>Abbrechen</button>\n";
    file << "      </div>\n";
    file << "      <p id=\"recommendation-progress\" class=\"inline-status\" aria-live=\"polite\">Noch kein Scan gestartet.</p>\n";
    file << "      <div id=\"recommendation-list\" class=\"recommendation-list empty\">Noch keine Empfehlungen erfasst.</div>\n";
    file << "      <div id=\"recommendation-actions\" class=\"top-chatters-actions\" hidden>\n";
    file << "        <button id=\"recommendation-more\" class=\"top-chatter-link\" type=\"button\">mehr…</button>\n";
    file << "      </div>\n";
    file << "    </section>\n\n";
    
    // Caption Section
    file << "    <section aria-labelledby=\"caption-heading\">\n";
    file << "      <div class=\"section-title\">\n";
    file << "        <h2 id=\"caption-heading\">Titel</h2>\n";
    file << "        <button id=\"scan\" class=\"secondary\">Status</button>\n";
    file << "      </div>\n";
    file << "      <div id=\"caption-status\" class=\"status-grid\"></div>\n";
    file << "      <button id=\"enable-captions\" class=\"primary\">Untertitel</button>\n";
    file << "      <p id=\"caption-action-status\" role=\"status\" class=\"inline-status action-status\"></p>\n";
    file << "    </section>\n\n";
    
    // Song Section
    file << "    <section aria-labelledby=\"song-heading\">\n";
    file << "      <div class=\"section-title header-controls\">\n";
    file << "        <h2 id=\"song-heading\">Songs</h2>\n";
    file << "        <div class=\"title-actions\">\n";
    file << "          <input id=\"song-enabled\" type=\"checkbox\" aria-label=\"Songerkennung\" title=\"Songerkennung: Off\">\n";
    file << "          <span id=\"song-led\" class=\"status-led off\" data-switch-status=\"song-enabled\" role=\"status\" aria-label=\"Songerkennung inaktiv\"></span>\n";
    file << "        </div>\n";
    file << "      </div>\n";
    file << "      <button id=\"recognize-song\" class=\"primary\" disabled>Jetzt erkennen</button>\n";
    file << "      <p id=\"song-status\" class=\"inline-status\"></p>\n";
    file << "      <div id=\"song-result\" class=\"song-result\" hidden></div>\n";
    file << "    </section>\n\n";
    
    // Links Section
    file << "    <section aria-labelledby=\"links-heading\">\n";
    file << "      <div class=\"section-title\">\n";
    file << "        <h2 id=\"links-heading\">HAR-Logs</h2>\n";
    file << "        <span id=\"media-count\" class=\"count\">0</span>\n";
    file << "      </div>\n";
    file << "      <div id=\"media-list\" class=\"list empty\">Noch keine FLV-/HLS-Links erkannt.</div>\n";
    file << "    </section>\n\n";
    
    // Log Section
    file << "    <section aria-labelledby=\"log-heading\">\n";
    file << "      <div class=\"section-title header-controls\">\n";
    file << "        <h2 id=\"log-heading\">LIVE-Logs</h2>\n";
    file << "        <div class=\"title-actions\">\n";
    file << "          <span class=\"status-led off\" data-counter-status=\"caption-count\" role=\"status\"></span>\n";
    file << "          <span id=\"caption-count\" class=\"count\">0</span>\n";
    file << "          <button id=\"clear\" class=\"ghost compact\" title=\"Reset\">Reset</button>\n";
    file << "          <input id=\"live-logs-enabled\" type=\"checkbox\" aria-label=\"LIVE-Logs\" title=\"LIVE-Logs: Off\">\n";
    file << "          <span class=\"status-led off\" data-switch-status=\"live-logs-enabled\" role=\"status\" aria-label=\"LIVE-Logs: deaktiviert\"></span>\n";
    file << "        </div>\n";
    file << "      </div>\n";
    file << "      <div class=\"button-row\">\n";
    file << "        <button id=\"export-log\" class=\"secondary\">JSON-L-Export</button>\n";
    file << "        <button id=\"export-caption-raw\" class=\"secondary\">RAW-JSON-Export</button>\n";
    file << "      </div>\n";
    file << "      <div id=\"caption-list\" class=\"list empty\">Noch keine CaptionMessages empfangen.</div>\n";
    file << "    </section>\n\n";
    
    // Debug Section
    file << "    <section aria-labelledby=\"debug-heading\">\n";
    file << "      <div class=\"section-title header-controls\">\n";
    file << "        <h2 id=\"debug-heading\">Debugmodus</h2>\n";
    file << "        <div class=\"title-actions\">\n";
    file << "          <span class=\"status-led off\" data-counter-status=\"debug-count\" role=\"status\"></span>\n";
    file << "          <span id=\"debug-count\" class=\"count\">0</span>\n";
    file << "          <button id=\"clear-debug\" class=\"ghost compact\" title=\"Reset\">Reset</button>\n";
    file << "          <input id=\"debug-enabled\" type=\"checkbox\" aria-label=\"Diagnoseereignisse für diesen Tab protokollieren\" title=\"Diagnoseereignisse für diesen Tab protokollieren: Off\">\n";
    file << "          <span class=\"status-led off\" data-switch-status=\"debug-enabled\" role=\"status\"></span>\n";
    file << "        </div>\n";
    file << "      </div>\n";
    file << "      <div class=\"button-row\">\n";
    file << "        <button id=\"export-debug\" class=\"secondary\">Debug exportieren</button>\n";
    file << "      </div>\n";
    file << "      <p class=\"muted small\"></p>\n";
    file << "    </section>\n\n";
    
    // Audience Modal
    file << "    <div id=\"audience-modal\" class=\"modal-backdrop\" hidden>\n";
    file << "      <section class=\"modal\" role=\"dialog\" aria-modal=\"true\" aria-labelledby=\"audience-heading\">\n";
    file << "        <div class=\"section-title\">\n";
    file << "          <h2 id=\"audience-heading\">Im Chat beobachtete Personen</h2>\n";
    file << "          <button id=\"close-audience\" class=\"secondary compact\" aria-label=\"Übersicht schließen\">Schließen</button>\n";
    file << "        </div>\n";
    file << "        <p id=\"audience-limit\" class=\"inline-status\"></p>\n";
    file << "        <div id=\"audience-list\" class=\"audience-list\"></div>\n";
    file << "      </section>\n";
    file << "    </div>\n\n";
    
    // Speech Settings Modal
    file << "    <div id=\"speech-settings-modal\" class=\"modal-backdrop\" hidden>\n";
    file << "      <section class=\"modal\" role=\"dialog\" aria-modal=\"true\" aria-labelledby=\"speech-settings-heading\">\n";
    file << "        <div class=\"section-title\">\n";
    file << "          <h2 id=\"speech-settings-heading\">Erweiterte Einstellungen</h2>\n";
    file << "          <button id=\"close-speech-settings\" class=\"secondary compact\" aria-label=\"Einstellungen schließen\">Schließen</button>\n";
    file << "        </div>\n";
    file << "        <div class=\"settings-grid speech-integration-settings\">\n";
    file << "<label class=\"icon-style-setting\"><span>Icon-Stil</span><select id=\"icon-style\"><option value=\"plastisch\">3D / Plastisch</option><option value=\"glass\">Glass / Realistisch</option><option value=\"linear\">Minimal / Linear</option></select></label>\n";
    file << "          <label><span>Sprache</span><select id=\"speech-language\"><option value=\"auto\">Auto</option><option value=\"de-DE\">Deutsch</option><option value=\"en-US\">Englisch</option><option value=\"ru-RU\">Russisch</option><option value=\"uk-UA\">Ukrainisch</option><option value=\"bg-BG\">Bulgarisch</option><option value=\"sr-RS\">Serbisch</option><option value=\"kk-KZ\">Kasachisch</option><option value=\"zh-CN\">Chinesisch</option><option value=\"ja-JP\">Japanisch</option><option value=\"ko-KR\">Koreanisch</option><option value=\"ar-JO\">Arabisch</option><option value=\"fa-IR\">Persisch</option><option value=\"ur-PK\">Urdu</option><option value=\"hi-IN\">Hindi</option><option value=\"ne-NP\">Nepali</option><option value=\"ml-IN\">Malayalam</option></select></label>\n";
    file << "          <label><span>Stimme</span><select id=\"speech-voice\"><option value=\"\">Standard</option></select></label>\n";
    file << "          <label id=\"audd-token-setting\"><span id=\"audd-token-label\">AudD API-Token (optional - <a href=\"https://audd.io/\" target=\"_blank\" rel=\"noopener noreferrer\">https://AudD.io</a> Trial/Paid)</span><input id=\"audd-token\" type=\"password\" autocomplete=\"off\" spellcheck=\"false\"></label>\n";
    file << "          <label id=\"pairing-code-setting\"><span>Pairing-Code</span><input id=\"pairing-code\" type=\"password\" autocomplete=\"off\" spellcheck=\"false\"></label>\n";
    file << "          <label><span>Universal API-Key</span><input id=\"universal-caption-api-key\" type=\"password\" autocomplete=\"off\" spellcheck=\"false\"></label>\n";
    file << "        </div>\n";
    file << "        <label class=\"option-row\"><input id=\"speak-names\" type=\"checkbox\" checked> Chatnamen sprechen</label>\n";
    file << "        <label class=\"option-row\"><input id=\"shorten-names\" type=\"checkbox\"> Chatnamen kürzen</label>\n";
    file << "        <label class=\"option-row auto-chat-refresh\"><input id=\"auto-chat-refresh\" type=\"checkbox\"> Auto-Chat Refresh <input id=\"auto-chat-refresh-minutes\" type=\"number\" min=\"1\" max=\"60\" step=\"1\" value=\"5\" inputmode=\"numeric\" aria-label=\"Auto-Chat-Refresh in Minuten\"><span>min.</span></label>\n";
    file << "        <label class=\"option-row\"><input id=\"game-mode\" type=\"checkbox\"> Game-Mode (Spam-, Emoji, usw. Chatfilter)</label>\n";
    file << "        <div class=\"option-row external-speech-trigger-row\"><label><input id=\"filter-external-speech-triggers\" type=\"checkbox\"> Trigger filtern (ext. Sprachdienste)</label><input id=\"external-speech-trigger-characters\" type=\"text\" value=\".\" maxlength=\"10\" aria-label=\"Triggerzeichen, maximal fünf Sonderzeichen\" autocomplete=\"off\" spellcheck=\"false\"></div>\n";
    file << "        <label class=\"option-row\"><input id=\"keep-speech-active\" type=\"checkbox\" aria-label=\"Vorlesen dauerhaft\" title=\"Vorlesen dauerhaft: Off\"> Vorlesen dauerhaft</label>\n";
    file << "      </section>\n";
    file << "    </div>\n\n";
    
    // Chat History Modal
    file << "    <div id=\"chat-history-modal\" class=\"modal-backdrop\" hidden>\n";
    file << "      <section class=\"modal\" role=\"dialog\" aria-modal=\"true\" aria-labelledby=\"chat-history-heading\">\n";
    file << "        <div class=\"section-title\">\n";
    file << "          <h2 id=\"chat-history-heading\">Gesammelte Chatnachrichten</h2>\n";
    file << "          <button id=\"close-chat-history\" class=\"secondary compact\" aria-label=\"Chatzeilen schließen\">Schließen</button>\n";
    file << "        </div>\n";
    file << "        <p id=\"chat-history-limit\" class=\"inline-status\"></p>\n";
    file << "        <div id=\"chat-history-list\" class=\"chat-history-list\"></div>\n";
    file << "      </section>\n";
    file << "    </div>\n\n";
    
    // Recommendation Modal
    file << "    <div id=\"recommendation-modal\" class=\"modal-backdrop\" hidden>\n";
    file << "      <section class=\"modal\" role=\"dialog\" aria-modal=\"true\" aria-labelledby=\"recommendation-modal-heading\">\n";
    file << "        <div class=\"section-title\">\n";
    file << "          <h2 id=\"recommendation-modal-heading\">Gescannte LIVE-Empfehlungen</h2>\n";
    file << "          <button id=\"close-recommendations\" class=\"secondary compact\" aria-label=\"Empfehlungen schließen\">Schließen</button>\n";
    file << "        </div>\n";
    file << "        <div id=\"recommendation-modal-list\" class=\"recommendation-list\"></div>\n";
    file << "      </section>\n";
    file << "    </div>\n\n";
    
    // Notice
    file << "    <p id=\"notice\" role=\"alert\" class=\"notice\"></p>\n";
    file << "  </main>\n";
    
    // Connection Settings Modal
    file << "  <div id=\"connection-settings-modal\" class=\"modal-backdrop\" hidden>\n";
    file << "    <section class=\"modal\" role=\"dialog\" aria-modal=\"true\" aria-labelledby=\"connection-settings-heading\">\n";
    file << "      <div class=\"section-title\"><h2 id=\"connection-settings-heading\">Connection-Einstellungen</h2><button id=\"close-connection-settings\" class=\"secondary compact\">Schließen</button></div>\n";
    file << "      <label class=\"option-row quick-recover-setting\"><input id=\"hook-reconnect\" type=\"checkbox\"> Hook-Reconnect <input id=\"hook-reconnect-seconds\" type=\"number\" min=\"1\" max=\"59\" step=\"1\" value=\"3\" inputmode=\"numeric\" aria-label=\"Hook-Reconnect-Wartezeit in Sekunden\"><span>Sek.</span></label>\n";
    file << "      <label class=\"option-row quick-recover-setting\"><input id=\"quick-recover\" type=\"checkbox\"> Player-Recovery <input id=\"quick-recover-seconds\" type=\"number\" min=\"1\" max=\"59\" step=\"1\" value=\"3\" inputmode=\"numeric\" aria-label=\"Player-Recovery-Bestätigungszeit in Sekunden\"><span>Sek.</span></label>\n";
    file << "    </section>\n";
    file << "  </div>\n\n";
    
    file << "  <script src=\"content-core.js\"></script>\n";
    file << "  <script src=\"sidepanel.js\"></script>\n";
    file << "  <script src=\"icon-controls.js\"></script>\n";
    file << "</body>\n";
    file << "</html>\n";

    file.close();
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::cerr << "Verwendung: " << argv[0] << " <ausgabedatei.html>" << std::endl;
        return 1;
    }
    
    generateHTML(argv[1]);
    std::cout << "HTML-Datei erfolgreich generiert: " << argv[1] << std::endl;
    
    return 0;
}
