// abstraction-provenance: {"artifact_sha256": "879952cb7083a412148fdfa09a45ff37b5e98dc8db4a67ace9f67707831ff0b1", "source_sha256": "6c68f7375733776fa70f0fd1e48fe739ffdf7c38b6444a8ef7c36fd50e4d08e9", "target_language": "c"}
// sidepanel.html — portiert nach c
// Quelle: html, Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/sidepanel.html
// auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/sidepanel.html
// auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/browser-extension/sidepanel.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void write_html_header(FILE *file) {
    fprintf(file, "<!doctype html>\n");
    fprintf(file, "<html lang=\"de\">\n");
    fprintf(file, "<head>\n");
    fprintf(file, "  <meta charset=\"utf-8\">\n");
    fprintf(file, "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n");
    fprintf(file, "  <title>TikTok LIVE Companion</title>\n");
    fprintf(file, "  <link rel=\"stylesheet\" href=\"sidepanel.css\">\n");
    fprintf(file, "  <link rel=\"stylesheet\" href=\"icon-controls.css\">\n");
    fprintf(file, "</head>\n");
    fprintf(file, "<body>\n");
}

void write_html_footer(FILE *file) {
    fprintf(file, "  <script src=\"content-core.js\"></script>\n");
    fprintf(file, "  <script src=\"sidepanel.js\"></script>\n");
    fprintf(file, "  <script src=\"icon-controls.js\"></script>\n");
    fprintf(file, "</body>\n");
    fprintf(file, "</html>\n");
}

void write_header_section(FILE *file) {
    fprintf(file, "  <header>\n");
    fprintf(file, "    <p id=\"page-title\" class=\"muted\">Kein TikTok-Tab ausgewählt</p>\n");
    fprintf(file, "  </header>\n\n");
}

void write_main_section(FILE *file) {
    fprintf(file, "  <main>\n");
    
    // Chat section
    fprintf(file, "    <section aria-labelledby=\"chat-heading\">\n");
    fprintf(file, "      <div class=\"section-title\">\n");
    fprintf(file, "        <h2 id=\"chat-heading\">Chat</h2>\n");
    fprintf(file, "        <div class=\"title-actions\">\n");
    fprintf(file, "          <span id=\"chat-led\" class=\"status-led off\" role=\"status\" aria-label=\"Chat inaktiv\" title=\"Chat inaktiv\"></span>\n");
    fprintf(file, "          <button id=\"chat-count\" class=\"count count-button\" type=\"button\" aria-haspopup=\"dialog\" title=\"Gesammelte Chatzeilen öffnen\">0</button>\n");
    fprintf(file, "          <button id=\"refresh-chat\" class=\"secondary compact\" title=\"Chatanzeige leeren\">Reset</button>\n");
    fprintf(file, "          <button id=\"toggle-speech\" class=\"secondary compact\" aria-pressed=\"false\" aria-label=\"Vorlesen\">On</button>\n");
    fprintf(file, "          <span id=\"speech-led\" class=\"status-led off\" role=\"status\" aria-label=\"Vorlesen inaktiv\" title=\"Vorlesen inaktiv\"></span>\n");
    fprintf(file, "        </div>\n");
    fprintf(file, "      </div>\n");
    fprintf(file, "      <div id=\"chat-list\" class=\"chat-list empty\" role=\"log\" aria-live=\"polite\" aria-relevant=\"additions\" aria-label=\"Die letzten fünf bereinigten Chatnachrichten\">Noch keine Chatnachrichten erkannt.</div>\n");
    fprintf(file, "      <p id=\"speech-status\" role=\"status\" class=\"inline-status\">Vorlesen ist ausgeschaltet.</p>\n");
    fprintf(file, "      <div class=\"control-label\"><label for=\"speech-volume\">Vorleselautstärke</label><output id=\"speech-volume-output\" for=\"speech-volume\">100%%</output></div>\n");
    fprintf(file, "      <input id=\"speech-volume\" type=\"range\" min=\"0\" max=\"100\" step=\"5\" value=\"50\">\n");
    fprintf(file, "      <div class=\"button-row\">\n");
    fprintf(file, "        <button id=\"service-action\" class=\"secondary\">Sprachdienst</button>\n");
    fprintf(file, "        <button id=\"sherpa-action\" class=\"secondary\">Sherpa</button>\n");
    fprintf(file, "        <button id=\"open-speech-settings\" class=\"secondary compact settings-button\" type=\"button\" aria-label=\"Erweiterte Einstellungen öffnen\" aria-haspopup=\"dialog\" title=\"Einstellungen\"></button>\n");
    fprintf(file, "      </div>\n");
    fprintf(file, "      <p id=\"service-status\" class=\"inline-status\">Lokaler Sprachdienst noch nicht geprüft.</p>\n");
    fprintf(file, "      <div id=\"service-setup\" class=\"inline-status\" hidden>\n");
    fprintf(file, "        <button id=\"copy-service-setup\" class=\"secondary compact\">Installation abschließen!</button>\n");
    fprintf(file, "      </div>\n");
    fprintf(file, "    </section>\n\n");

    // Stats section
    fprintf(file, "    <section aria-labelledby=\"stats-heading\">\n");
    fprintf(file, "      <div class=\"section-title\">\n");
    fprintf(file, "        <h2 id=\"stats-heading\">LIVE-Information</h2>\n");
    fprintf(file, "        <span id=\"stats-live\" class=\"live-indicator\">warte</span>\n");
    fprintf(file, "      </div>\n");
    fprintf(file, "      <div id=\"live-stats\" class=\"status-grid stats-grid\"></div>\n");
    fprintf(file, "      <p id=\"stats-status\" class=\"inline-status\"></p>\n");
    fprintf(file, "    </section>\n\n");

    // Page info section
    fprintf(file, "    <section id=\"page-info-section\" aria-labelledby=\"page-info-heading\">\n");
    fprintf(file, "      <div class=\"section-title\">\n");
    fprintf(file, "        <h2 id=\"page-info-heading\">PROFIL-Information</h2>\n");
    fprintf(file, "        <div class=\"title-actions\">\n");
    fprintf(file, "          <span id=\"page-info-source\" class=\"live-indicator\">Metadaten</span>\n");
    fprintf(file, "          <button id=\"refresh-page-info\" class=\"secondary compact\" title=\"Refresh\">Refresh</button>\n");
    fprintf(file, "          <button id=\"force-page-info\" class=\"secondary compact danger-outline\">Force</button>\n");
    fprintf(file, "        </div>\n");
    fprintf(file, "      </div>\n");
    fprintf(file, "      <div id=\"profile-info\" class=\"profile-info\" hidden></div>\n");
    fprintf(file, "      <div id=\"summary-info\" class=\"summary-info\"></div>\n");
    fprintf(file, "    </section>\n\n");

    // Connection section
    fprintf(file, "    <section aria-labelledby=\"hook-heading\">\n");
    fprintf(file, "      <div class=\"section-title header-controls\">\n");
    fprintf(file, "        <h2 id=\"hook-heading\">Connection</h2>\n");
    fprintf(file, "        <div class=\"title-actions\">\n");
    fprintf(file, "          <button id=\"reset-tab\" class=\"secondary compact danger-outline\" title=\"Reset\">Reset</button>\n");
    fprintf(file, "          <input id=\"hook-autostart\" type=\"checkbox\" aria-label=\"Hook dauerhaft\" title=\"Hook dauerhaft: Off\">\n");
    fprintf(file, "          <span class=\"status-led off\" data-switch-status=\"hook-autostart\" role=\"status\"></span>\n");
    fprintf(file, "        </div>\n");
    fprintf(file, "      </div>\n");
    fprintf(file, "      <div class=\"button-row\">\n");
    fprintf(file, "        <button id=\"toggle-hook\" class=\"primary\" aria-label=\"Connection\" aria-pressed=\"false\">On</button>\n");
    fprintf(file, "        <button id=\"open-connection-settings\" class=\"secondary compact settings-button\" type=\"button\" aria-label=\"Connection-Einstellungen öffnen\" aria-haspopup=\"dialog\"></button>\n");
    fprintf(file, "        <button id=\"open-embed-live\" class=\"secondary\">Embed</button>\n");
    fprintf(file, "        <button id=\"open-normal-live\" class=\"secondary\">Browser</button>\n");
    fprintf(file, "        <button id=\"player-vlc-frame\" class=\"secondary compact\">Player</button>\n");
    fprintf(file, "      </div>\n");
    fprintf(file, "      <div class=\"connection-status\"><span id=\"hook-led\" class=\"status-led off\" role=\"status\" aria-label=\"Hook inaktiv\" title=\"Hook inaktiv\"></span><p id=\"hook-status\" class=\"inline-status\"></p></div>\n");
    fprintf(file, "      <p id=\"embed-startup-status\" class=\"inline-status\" role=\"status\" aria-live=\"polite\" hidden></p>\n");
    fprintf(file, "      <button id=\"cancel-embed-startup\" class=\"secondary\" hidden>Embed-Start abbrechen</button>\n");
    fprintf(file, "      <p id=\"hook-reconnect-status\" class=\"inline-status\" role=\"status\">Hook-Reconnect: aus</p>\n");
    fprintf(file, "      <p id=\"player-recovery-status\" class=\"inline-status\" role=\"status\">Player-Recovery: aus</p>\n");
    fprintf(file, "    </section>\n\n");

    // Player section
    fprintf(file, "    <section aria-labelledby=\"player-heading\">\n");
    fprintf(file, "      <div class=\"section-title header-controls\">\n");
    fprintf(file, "        <h2 id=\"player-heading\">Player</h2>\n");
    fprintf(file, "        <div class=\"title-actions\">\n");
    fprintf(file, "          <button id=\"player-replay\" class=\"secondary compact\" title=\"Neu laden\">Neu laden</button>\n");
    fprintf(file, "          <input id=\"limiter-enabled\" type=\"checkbox\" aria-label=\"Pegelschutz\" title=\"Pegelschutz: Off\">\n");
    fprintf(file, "          <span class=\"status-led off\" data-switch-status=\"limiter-enabled\" role=\"status\"></span>\n");
    fprintf(file, "        </div>\n");
    fprintf(file, "      </div>\n");
    fprintf(file, "      <div class=\"player-controls\" role=\"group\" aria-label=\"TikTok-Player steuern\">\n");
    fprintf(file, "        <button id=\"player-play\" class=\"secondary compact\">Play</button>\n");
    fprintf(file, "        <button id=\"player-mute\" class=\"secondary compact\">Mute</button>\n");
    fprintf(file, "        <button id=\"player-pip\" class=\"secondary compact\">Bild-in-Bild</button>\n");
    fprintf(file, "        <button id=\"player-fullscreen\" class=\"secondary compact\">Vollbild</button>\n");
    fprintf(file, "        <button id=\"player-report\" class=\"secondary compact danger-outline\">Meldung</button>\n");
    fprintf(file, "      </div>\n");
    fprintf(file, "      <div class=\"audio-controls\">\n");
    fprintf(file, "        <div class=\"control-label\"><label for=\"player-volume\">Lautstärke</label><output id=\"player-volume-output\" for=\"player-volume\">–</output></div>\n");
    fprintf(file, "        <input id=\"player-volume\" type=\"range\" min=\"0\" max=\"100\" step=\"1\" value=\"100\">\n");
    fprintf(file, "        <div class=\"audio-meter-row\"><span>Spitzenpegel</span><strong id=\"player-peak\">–</strong></div>\n");
    fprintf(file, "        <div class=\"control-label\"><label for=\"limiter-strength\">Schutzstärke</label><output id=\"limiter-strength-output\" for=\"limiter-strength\">30</output></div>\n");
    fprintf(file, "        <input id=\"limiter-strength\" type=\"range\" min=\"0\" max=\"100\" step=\"1\" value=\"30\">\n");
    fprintf(file, "      </div>\n");
    fprintf(file, "      <p id=\"multi-guest-status\" class=\"inline-status\">Verbundene Streams: noch nicht erkannt.</p>\n");
    fprintf(file, "      <p id=\"player-status\" role=\"status\" class=\"inline-status\">Warte auf den TikTok-Player.</p>\n");
    fprintf(file, "      <span id=\"player-time\" class=\"player-time\" hidden>–</span>\n");
    fprintf(file, "    </section>\n\n");

    // Top chatters section
    fprintf(file, "    <section aria-labelledby=\"top-chatters-heading\">\n");
    fprintf(file, "      <div class=\"section-title\">\n");
    fprintf(file, "        <h2 id=\"top-chatters-heading\">Top-Chatter</h2>\n");
    fprintf(file, "        <button id=\"open-audience\" class=\"secondary compact\">Zuschauer*innen</button>\n");
    fprintf(file, "      </div>\n");
    fprintf(file, "      <p id=\"team-tag-status\" class=\"inline-status\">Teamkürzel: noch nicht erkannt.</p>\n");
    fprintf(file, "      <div id=\"top-chatters\" class=\"top-chatters empty\">Noch keine Personen im Chat beobachtet.</div>\n");
    fprintf(file, "      <div id=\"top-chatters-actions\" class=\"top-chatters-actions\" hidden>\n");
    fprintf(file, "        <button id=\"top-chatters-reset\" class=\"top-chatter-link\" type=\"button\" hidden>Reset</button>\n");
    fprintf(file, "        <button id=\"top-chatters-more\" class=\"top-chatter-link\" type=\"button\">mehr…</button>\n");
    fprintf(file, "      </div>\n");
    fprintf(file, "    </section>\n\n");

    // Recommendations section
    fprintf(file, "    <section id=\"recommendations-section\" aria-labelledby=\"recommendations-heading\">\n");
    fprintf(file, "      <div class=\"section-title\">\n");
    fprintf(file, "        <h2 id=\"recommendations-heading\">LIVE-Empfehlungen</h2>\n");
    fprintf(file, "        <span id=\"recommendation-status\" class=\"live-indicator\">bereit</span>\n");
    fprintf(file, "      </div>\n");
    fprintf(file, "      <div class=\"recommendation-controls\">\n");
    fprintf(file, "        <label><span>Anzahl</span><input id=\"recommendation-limit\" type=\"number\" min=\"1\" max=\"300\" step=\"1\" value=\"20\" inputmode=\"numeric\"></label>\n");
    fprintf(file, "        <label><span>Sortierung</span><select id=\"recommendation-sort\"><option value=\"tiktok\">TikTok-Reihenfolge</option><option value=\"viewers\">Zuschauer*innen</option></select></label>\n");
    fprintf(file, "      </div>\n");
    fprintf(file, "      <div class=\"button-row\">\n");
    fprintf(file, "        <button id=\"scan-recommendations\" class=\"primary\">Empfehlungen scannen</button>\n");
    fprintf(file, "        <button id=\"cancel-recommendations\" class=\"secondary\" hidden>Abbrechen</button>\n");
    fprintf(file, "      </div>\n");
    fprintf(file, "      <p id=\"recommendation-progress\" class=\"inline-status\" aria-live=\"polite\">Noch kein Scan gestartet.</p>\n");
    fprintf(file, "      <div id=\"recommendation-list\" class=\"recommendation-list empty\">Noch keine Empfehlungen erfasst.</div>\n");
    fprintf(file, "      <div id=\"recommendation-actions\" class=\"top-chatters-actions\" hidden>\n");
    fprintf(file, "        <button id=\"recommendation-more\" class=\"top-chatter-link\" type=\"button\">mehr…</button>\n");
    fprintf(file, "      </div>\n");
    fprintf(file, "    </section>\n\n");

    // Caption section
    fprintf(file, "    <section aria-labelledby=\"caption-heading\">\n");
    fprintf(file, "      <div class=\"section-title\">\n");
    fprintf(file, "        <h2 id=\"caption-heading\">Titel</h2>\n");
    fprintf(file, "        <button id=\"scan\" class=\"secondary\">Status</button>\n");
    fprintf(file, "      </div>\n");
    fprintf(file, "      <div id=\"caption-status\" class=\"status-grid\"></div>\n");
    fprintf(file, "      <button id=\"enable-captions\" class=\"primary\">Untertitel</button>\n");
    fprintf(file, "      <p id=\"caption-action-status\" role=\"status\" class=\"inline-status action-status\"></p>\n");
    fprintf(file, "    </section>\n\n");

    // Song section
    fprintf(file, "    <section aria-labelledby=\"song-heading\">\n");
    fprintf(file, "      <div class=\"section-title header-controls\">\n");
    fprintf(file, "        <h2 id=\"song-heading\">Songs</h2>\n");
    fprintf(file, "        <div class=\"title-actions\">\n");
    fprintf(file, "          <input id=\"song-enabled\" type=\"checkbox\" aria-label=\"Songerkennung\" title=\"Songerkennung: Off\">\n");
    fprintf(file, "          <span id=\"song-led\" class=\"status-led off\" data-switch-status=\"song-enabled\" role=\"status\" aria-label=\"Songerkennung inaktiv\"></span>\n");
    fprintf(file, "        </div>\n");
    fprintf(file, "      </div>\n");
    fprintf(file, "      <button id=\"recognize-song\" class=\"primary\" disabled>Jetzt erkennen</button>\n");
    fprintf(file, "      <p id=\"song-status\" class=\"inline-status\"></p>\n");
    fprintf(file, "      <div id=\"song-result\" class=\"song-result\" hidden></div>\n");
    fprintf(file, "    </section>\n\n");

    // Links section
    fprintf(file, "    <section aria-labelledby=\"links-heading\">\n");
    fprintf(file, "      <div class=\"section-title\">\n");
    fprintf(file, "        <h2 id=\"links-heading\">HAR-Logs</h2>\n");
    fprintf(file, "        <span id=\"media-count\" class=\"count\">0</span>\n");
    fprintf(file, "      </div>\n");
    fprintf(file, "      <div id=\"media-list\" class=\"list empty\">Noch keine FLV-/HLS-Links erkannt.</div>\n");
    fprintf(file, "    </section>\n\n");

    // Log section
    fprintf(file, "    <section aria-labelledby=\"log-heading\">\n");
    fprintf(file, "      <div class=\"section-title header-controls\">\n");
    fprintf(file, "        <h2 id=\"log-heading\">LIVE-Logs</h2>\n");
    fprintf(file, "        <div class=\"title-actions\">\n");
    fprintf(file, "          <span class=\"status-led off\" data-counter-status=\"caption-count\" role=\"status\"></span>\n");
    fprintf(file, "          <span id=\"caption-count\" class=\"count\">0</span>\n");
    fprintf(file, "          <button id=\"clear\" class=\"ghost compact\" title=\"Reset\">Reset</button>\n");
    fprintf(file, "          <input id=\"live-logs-enabled\" type=\"checkbox\" aria-label=\"LIVE-Logs\" title=\"LIVE-Logs: Off\">\n");
    fprintf(file, "          <span class=\"status-led off\" data-switch-status=\"live-logs-enabled\" role=\"status\" aria-label=\"LIVE-Logs: deaktiviert\"></span>\n");
    fprintf(file, "        </div>\n");
    fprintf(file, "      </div>\n");
    fprintf(file, "      <div class=\"button-row\">\n");
    fprintf(file, "        <button id=\"export-log\" class=\"secondary\">JSON-L-Export</button>\n");
    fprintf(file, "        <button id=\"export-caption-raw\" class=\"secondary\">RAW-JSON-Export</button>\n");
    fprintf(file, "      </div>\n");
    fprintf(file, "      <div id=\"caption-list\" class=\"list empty\">Noch keine CaptionMessages empfangen.</div>\n");
    fprintf(file, "    </section>\n\n");

    // Debug section
    fprintf(file, "    <section aria-labelledby=\"debug-heading\">\n");
    fprintf(file, "      <div class=\"section-title header-controls\">\n");
    fprintf(file, "        <h2 id=\"debug-heading\">Debugmodus</h2>\n");
    fprintf(file, "        <div class=\"title-actions\">\n");
    fprintf(file, "          <span class=\"status-led off\" data-counter-status=\"debug-count\" role=\"status\"></span>\n");
    fprintf(file, "          <span id=\"debug-count\" class=\"count\">0</span>\n");
    fprintf(file, "          <button id=\"clear-debug\" class=\"ghost compact\" title=\"Reset\">Reset</button>\n");
    fprintf(file, "          <input id=\"debug-enabled\" type=\"checkbox\" aria-label=\"Diagnoseereignisse für diesen Tab protokollieren\" title=\"Diagnoseereignisse für diesen Tab protokollieren: Off\">\n");
    fprintf(file, "          <span class=\"status-led off\" data-switch-status=\"debug-enabled\" role=\"status\"></span>\n");
    fprintf(file, "        </div>\n");
    fprintf(file, "      </div>\n");
    fprintf(file, "      <div class=\"button-row\">\n");
    fprintf(file, "        <button id=\"export-debug\" class=\"secondary\">Debug exportieren</button>\n");
    fprintf(file, "      </div>\n");
    fprintf(file, "      <p class=\"muted small\"></p>\n");
    fprintf(file, "    </section>\n\n");

    // Audience modal
    fprintf(file, "    <div id=\"audience-modal\" class=\"modal-backdrop\" hidden>\n");
    fprintf(file, "      <section class=\"modal\" role=\"dialog\" aria-modal=\"true\" aria-labelledby=\"audience-heading\">\n");
    fprintf(file, "        <div class=\"section-title\">\n");
    fprintf(file, "          <h2 id=\"audience-heading\">Im Chat beobachtete Personen</h2>\n");
    fprintf(file, "          <button id=\"close-audience\" class=\"secondary compact\" aria-label=\"Übersicht schließen\">Schließen</button>\n");
    fprintf(file, "        </div>\n");
    fprintf(file, "        <p id=\"audience-limit\" class=\"inline-status\"></p>\n");
    fprintf(file, "        <div id=\"audience-list\" class=\"audience-list\"></div>\n");
    fprintf(file, "      </section>\n");
    fprintf(file, "    </div>\n\n");

    // Speech settings modal
    fprintf(file, "    <div id=\"speech-settings-modal\" class=\"modal-backdrop\" hidden>\n");
    fprintf(file, "      <section class=\"modal\" role=\"dialog\" aria-modal=\"true\" aria-labelledby=\"speech-settings-heading\">\n");
    fprintf(file, "        <div class=\"section-title\">\n");
    fprintf(file, "          <h2 id=\"speech-settings-heading\">Erweiterte Einstellungen</h2>\n");
    fprintf(file, "          <button id=\"close-speech-settings\" class=\"secondary compact\" aria-label=\"Einstellungen schließen\">Schließen</button>\n");
    fprintf(file, "        </div>\n");
    fprintf(file, "        <div class=\"settings-grid speech-integration-settings\">\n");
    fprintf(file, "<label class=\"icon-style-setting\"><span>Icon-Stil</span><select id=\"icon-style\"><option value=\"plastisch\">3D / Plastisch</option><option value=\"glass\">Glass / Realistisch</option><option value=\"linear\">Minimal / Linear</option></select></label>\n");
    fprintf(file, "          <label><span>Sprache</span><select id=\"speech-language\"><option value=\"auto\">Auto</option><option value=\"de-DE\">Deutsch</option><option value=\"en-US\">Englisch</option><option value=\"ru-RU\">Russisch</option><option value=\"uk-UA\">Ukrainisch</option><option value=\"bg-BG\">Bulgarisch</option><option value=\"sr-RS\">Serbisch</option><option value=\"kk-KZ\">Kasachisch</option><option value=\"zh-CN\">Chinesisch</option><option value=\"ja-JP\">Japanisch</option><option value=\"ko-KR\">Koreanisch</option><option value=\"ar-JO\">Arabisch</option><option value=\"fa-IR\">Persisch</option><option value=\"ur-PK\">Urdu</option><option value=\"hi-IN\">Hindi</option><option value=\"ne-NP\">Nepali</option><option value=\"ml-IN\">Malayalam</option></select></label>\n");
    fprintf(file, "          <label><span>Stimme</span><select id=\"speech-voice\"><option value=\"\">Standard</option></select></label>\n");
    fprintf(file, "          <label id=\"audd-token-setting\"><span id=\"audd-token-label\">AudD API-Token (optional - <a href=\"https://audd.io/\" target=\"_blank\" rel=\"noopener noreferrer\">https://AudD.io</a> Trial/Paid)</span><input id=\"audd-token\" type=\"password\" autocomplete=\"off\" spellcheck=\"false\"></label>\n");
    fprintf(file, "          <label id=\"pairing-code-setting\"><span>Pairing-Code</span><input id=\"pairing-code\" type=\"password\" autocomplete=\"off\" spellcheck=\"false\"></label>\n");
    fprintf(file, "          <label><span>Universal API-Key</span><input id=\"universal-caption-api-key\" type=\"password\" autocomplete=\"off\" spellcheck=\"false\"></label>\n");
    fprintf(file, "        </div>\n");
    fprintf(file, "        <label class=\"option-row\"><input id=\"speak-names\" type=\"checkbox\" checked> Chatnamen sprechen</label>\n");
    fprintf(file, "        <label class=\"option-row\"><input id=\"shorten-names\" type=\"checkbox\"> Chatnamen kürzen</label>\n");
    fprintf(file, "        <label class=\"option-row auto-chat-refresh\"><input id=\"auto-chat-refresh\" type=\"checkbox\"> Auto-Chat Refresh <input id=\"auto-chat-refresh-minutes\" type=\"number\" min=\"1\" max=\"60\" step=\"1\" value=\"5\" inputmode=\"numeric\" aria-label=\"Auto-Chat-Refresh in Minuten\"><span>min.</span></label>\n");
    fprintf(file, "        <label class=\"option-row\"><input id=\"game-mode\" type=\"checkbox\"> Game-Mode (Spam-, Emoji, usw. Chatfilter)</label>\n");
    fprintf(file, "        <div class=\"option-row external-speech-trigger-row\"><label><input id=\"filter-external-speech-triggers\" type=\"checkbox\"> Trigger filtern (ext. Sprachdienste)</label><input id=\"external-speech-trigger-characters\" type=\"text\" value=\".\" maxlength=\"10\" aria-label=\"Triggerzeichen, maximal fünf Sonderzeichen\" autocomplete=\"off\" spellcheck=\"false\"></div>\n");
    fprintf(file, "        <label class=\"option-row\"><input id=\"keep-speech-active\" type=\"checkbox\" aria-label=\"Vorlesen dauerhaft\" title=\"Vorlesen dauerhaft: Off\"> Vorlesen dauerhaft</label>\n");
    fprintf(file, "      </section>\n");
    fprintf(file, "    </div>\n\n");

    // Chat history modal
    fprintf(file, "    <div id=\"chat-history-modal\" class=\"modal-backdrop\" hidden>\n");
    fprintf(file, "      <section class=\"modal\" role=\"dialog\" aria-modal=\"true\" aria-labelledby=\"chat-history-heading\">\n");
    fprintf(file, "        <div class=\"section-title\">\n");
    fprintf(file, "          <h2 id=\"chat-history-heading\">Gesammelte Chatnachrichten</h2>\n");
    fprintf(file, "          <button id=\"close-chat-history\" class=\"secondary compact\" aria-label=\"Chatzeilen schließen\">Schließen</button>\n");
    fprintf(file, "        </div>\n");
    fprintf(file, "        <p id=\"chat-history-limit\" class=\"inline-status\"></p>\n");
    fprintf(file, "        <div id=\"chat-history-list\" class=\"chat-history-list\"></div>\n");
    fprintf(file, "      </section>\n");
    fprintf(file, "    </div>\n\n");

    // Recommendation modal
    fprintf(file, "    <div id=\"recommendation-modal\" class=\"modal-backdrop\" hidden>\n");
    fprintf(file, "      <section class=\"modal\" role=\"dialog\" aria-modal=\"true\" aria-labelledby=\"recommendation-modal-heading\">\n");
    fprintf(file, "        <div class=\"section-title\">\n");
    fprintf(file, "          <h2 id=\"recommendation-modal-heading\">Gescannte LIVE-Empfehlungen</h2>\n");
    fprintf(file, "          <button id=\"close-recommendations\" class=\"secondary compact\" aria-label=\"Empfehlungen schließen\">Schließen</button>\n");
    fprintf(file, "        </div>\n");
    fprintf(file, "        <div id=\"recommendation-modal-list\" class=\"recommendation-list\"></div>\n");
    fprintf(file, "      </section>\n");
    fprintf(file, "    </div>\n\n");

    // Notice
    fprintf(file, "    <p id=\"notice\" role=\"alert\" class=\"notice\"></p>\n");
    fprintf(file, "  </main>\n");
    
    // Connection settings modal
    fprintf(file, "  <div id=\"connection-settings-modal\" class=\"modal-backdrop\" hidden>\n");
    fprintf(file, "    <section class=\"modal\" role=\"dialog\" aria-modal=\"true\" aria-labelledby=\"connection-settings-heading\">\n");
    fprintf(file, "      <div class=\"section-title\"><h2 id=\"connection-settings-heading\">Connection-Einstellungen</h2><button id=\"close-connection-settings\" class=\"secondary compact\">Schließen</button></div>\n");
    fprintf(file, "      <label class=\"option-row quick-recover-setting\"><input id=\"hook-reconnect\" type=\"checkbox\"> Hook-Reconnect <input id=\"hook-reconnect-seconds\" type=\"number\" min=\"1\" max=\"59\" step=\"1\" value=\"3\" inputmode=\"numeric\" aria-label=\"Hook-Reconnect-Wartezeit in Sekunden\"><span>Sek.</span></label>\n");
    fprintf(file, "      <label class=\"option-row quick-recover-setting\"><input id=\"quick-recover\" type=\"checkbox\"> Player-Recovery <input id=\"quick-recover-seconds\" type=\"number\" min=\"1\" max=\"59\" step=\"1\" value=\"3\" inputmode=\"numeric\" aria-label=\"Player-Recovery-Bestätigungszeit in Sekunden\"><span>Sek.</span></label>\n");
    fprintf(file, "    </section>\n");
    fprintf(file, "  </div>\n\n");
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <output_file>\n", argv[0]);
        return 1;
    }

    FILE *file = fopen(argv[1], "w");
    if (!file) {
        perror("Error opening file");
        return 1;
    }

    write_html_header(file);
    write_header_section(file);
    write_main_section(file);
    write_html_footer(file);

    fclose(file);
    return 0;
}
