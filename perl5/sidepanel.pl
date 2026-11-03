#!/usr/bin/perl
# sidepanel.html — portiert nach perl5
# Quelle: html, Projects@TikTok-Live-Companion:plugin-source/browser-extension/sidepanel.html
# Erzeugt: 2026-11-03 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;

# Function to generate the HTML document
sub generate_html {
    my $html = '';

    # Doctype and html tag
    $html .= "<!doctype html>\n";
    $html .= "<html lang=\"de\">\n";
    $html .= "<head>\n";
    $html .= "  <meta charset=\"utf-8\">\n";
    $html .= "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n";
    $html .= "  <title>TikTok LIVE Companion</title>\n";
    $html .= "  <link rel=\"stylesheet\" href=\"sidepanel.css\">\n";
    $html .= "  <link rel=\"stylesheet\" href=\"icon-controls.css\">\n";
    $html .= "  <link rel=\"stylesheet\" href=\"status-overview-panel.css\">\n";
    $html .= "</head>\n";
    $html .= "<body>\n";
    $html .= "  <p id=\"page-title\" hidden></p>\n\n";
    $html .= "  <main>\n";

    # Chat section
    $html .= "    <section aria-labelledby=\"chat-heading\">\n";
    $html .= "      <div class=\"section-title\">\n";
    $html .= "        <h2 id=\"chat-heading\">Chat</h2>\n";
    $html .= "        <div class=\"title-actions\">\n";
    $html .= "          <span id=\"chat-led\" class=\"status-led off\" role=\"status\" aria-label=\"Chat inaktiv\" title=\"Chat inaktiv\"></span>\n";
    $html .= "          <button id=\"chat-count\" class=\"count count-button\" type=\"button\" aria-haspopup=\"dialog\" title=\"Gesammelte Chatzeilen öffnen\">0</button>\n";
    $html .= "          <button id=\"refresh-chat\" class=\"secondary compact\" title=\"Chatanzeige leeren\">Reset</button>\n";
    $html .= "          <button id=\"toggle-speech\" class=\"secondary compact\" aria-pressed=\"false\" aria-label=\"Vorlesen\">On</button>\n";
    $html .= "          <span id=\"speech-led\" class=\"status-led off\" role=\"status\" aria-label=\"Vorlesen inaktiv\" title=\"Vorlesen inaktiv\"></span>\n";
    $html .= "        </div>\n";
    $html .= "      </div>\n";
    $html .= "      <div id=\"chat-list\" class=\"chat-list empty\" role=\"log\" aria-live=\"polite\" aria-relevant=\"additions\" aria-label=\"Die letzten fünf bereinigten Chatnachrichten\">Noch keine Chatnachrichten erkannt.</div>\n";
    $html .= "      <p id=\"speech-status\" role=\"status\" class=\"inline-status\">Vorlesen ist ausgeschaltet.</p>\n";
    $html .= "      <div class=\"control-label\"><label for=\"speech-volume\">Vorleselautstärke</label><output id=\"speech-volume-output\" for=\"speech-volume\">100%</output></div>\n";
    $html .= "      <input id=\"speech-volume\" type=\"range\" min=\"0\" max=\"100\" step=\"5\" value=\"50\">\n";
    $html .= "      <div class=\"button-row\">\n";
    $html .= "        <button id=\"service-action\" class=\"secondary\">Sprachdienst</button>\n";
    $html .= "        <button id=\"sherpa-action\" class=\"secondary\">Sherpa</button>\n";
    $html .= "        <button id=\"open-speech-settings\" class=\"secondary compact settings-button\" type=\"button\" aria-label=\"Erweiterte Einstellungen öffnen\" aria-haspopup=\"dialog\" title=\"Einstellungen\"></button>\n";
    $html .= "      </div>\n";
    $html .= "      <p id=\"service-status\" class=\"inline-status\">Lokaler Sprachdienst noch nicht geprüft.</p>\n";
    $html .= "      <div id=\"service-setup\" class=\"inline-status\" hidden>\n";
    $html .= "        <button id=\"copy-service-setup\" class=\"secondary compact\">Installation abschließen!</button>\n";
    $html .= "      </div>\n";
    $html .= "    </section>\n\n";

    # Stats section
    $html .= "    <section aria-labelledby=\"stats-heading\">\n";
    $html .= "      <div class=\"section-title\">\n";
    $html .= "        <h2 id=\"stats-heading\">LIVE-Information</h2>\n";
    $html .= "        <span id=\"stats-live\" class=\"live-indicator\">warte</span>\n";
    $html .= "      </div>\n";
    $html .= "      <div id=\"live-stats\" class=\"status-grid stats-grid\"></div>\n";
    $html .= "      <p id=\"stats-status\" class=\"inline-status\"></p>\n";
    $html .= "    </section>\n\n";

    # Page info section
    $html .= "    <section id=\"page-info-section\" aria-labelledby=\"page-info-heading\">\n";
    $html .= "      <div class=\"section-title\">\n";
    $html .= "        <h2 id=\"page-info-heading\">PROFIL-Information</h2>\n";
    $html .= "        <div class=\"title-actions\">\n";
    $html .= "          <span id=\"page-info-source\" class=\"live-indicator\">Metadaten</span>\n";
    $html .= "          <button id=\"refresh-page-info\" class=\"secondary compact\" title=\"Refresh\">Refresh</button>\n";
    $html .= "          <button id=\"force-page-info\" class=\"secondary compact danger-outline\">Force</button>\n";
    $html .= "        </div>\n";
    $html .= "      </div>\n";
    $html .= "      <div id=\"profile-info\" class=\"profile-info\" hidden></div>\n";
    $html .= "      <div id=\"summary-info\" class=\"summary-info\"></div>\n";
    $html .= "    </section>\n\n";

    # Hook section
    $html .= "    <section aria-labelledby=\"hook-heading\">\n";
    $html .= "      <div class=\"section-title header-controls\">\n";
    $html .= "        <h2 id=\"hook-heading\">Connection</h2>\n";
    $html .= "        <div class=\"title-actions\">\n";
    $html .= "          <button id=\"reset-tab\" class=\"secondary compact danger-outline\" title=\"Reset\">Reset</button>\n";
    $html .= "          <input id=\"hook-autostart\" type=\"checkbox\" aria-label=\"Hook dauerhaft\" title=\"Hook dauerhaft: Off\">\n";
    $html .= "          <span class=\"status-led off\" data-switch-status=\"hook-autostart\" role=\"status\"></span>\n";
    $html .= "        </div>\n";
    $html .= "      </div>\n";
    $html .= "      <div class=\"button-row\">\n";
    $html .= "        <button id=\"toggle-hook\" class=\"primary\" aria-label=\"Connection\" aria-pressed=\"false\">On</button>\n";
    $html .= "        <button id=\"open-connection-settings\" class=\"secondary compact settings-button\" type=\"button\" aria-label=\"Connection-Einstellungen öffnen\" aria-haspopup=\"dialog\"></button>\n";
    $html .= "        <button id=\"open-embed-live\" class=\"secondary\">Embed</button>\n";
    $html .= "        <button id=\"open-normal-live\" class=\"secondary\">Browser</button>\n";
    $html .= "        <button id=\"player-vlc-frame\" class=\"secondary compact\">Player</button>\n";
    $html .= "      </div>\n";
    $html .= "      <div class=\"connection-status\"><span id=\"hook-led\" class=\"status-led off\" role=\"status\" aria-label=\"Hook inaktiv\" title=\"Hook inaktiv\"></span><p id=\"hook-status\" class=\"inline-status\"></p></div>\n";
    $html .= "      <p id=\"embed-startup-status\" class=\"inline-status\" role=\"status\" aria-live=\"polite\" hidden></p>\n";
    $html .= "      <button id=\"cancel-embed-startup\" class=\"secondary\" hidden>Embed-Start abbrechen</button>\n";
    $html .= "      <p id=\"hook-reconnect-status\" class=\"inline-status\" role=\"status\">Hook-Reconnect: aus</p>\n";
    $html .= "      <p id=\"player-recovery-status\" class=\"inline-status\" role=\"status\">Player-Recovery: aus</p>\n";
    $html .= "    </section>\n\n";

    # Player section
    $html .= "    <section aria-labelledby=\"player-heading\">\n";
    $html .= "      <div class=\"section-title header-controls\">\n";
    $html .= "        <h2 id=\"player-heading\">Player</h2>\n";
    $html .= "        <div class=\"title-actions\">\n";
    $html .= "          <button id=\"player-replay\" class=\"secondary compact\" title=\"Neu laden\">Neu laden</button>\n";
    $html .= "          <input id=\"limiter-enabled\" type=\"checkbox\" aria-label=\"Pegelschutz\" title=\"Pegelschutz: Off\">\n";
    $html .= "          <span class=\"status-led off\" data-switch-status=\"limiter-enabled\" role=\"status\"></span>\n";
    $html .= "        </div>\n";
    $html .= "      </div>\n";
    $html .= "      <div class=\"player-controls\" role=\"group\" aria-label=\"TikTok-Player steuern\">\n";
    $html .= "        <button id=\"player-play\" class=\"secondary compact\">Play</button>\n";
    $html .= "        <button id=\"player-mute\" class=\"secondary compact\">Mute</button>\n";
    $html .= "        <button id=\"player-pip\" class=\"secondary compact\">Bild-in-Bild</button>\n";
    $html .= "        <button id=\"player-fullscreen\" class=\"secondary compact\">Vollbild</button>\n";
    $html .= "        <button id=\"player-report\" class=\"secondary compact danger-outline\">Meldung</button>\n";
    $html .= "      </div>\n";
    $html .= "      <div class=\"audio-controls\">\n";
    $html .= "        <div class=\"control-label\"><label for=\"player-volume\">Lautstärke</label><output id=\"player-volume-output\" for=\"player-volume\">–</output></div>\n";
    $html .= "        <input id=\"player-volume\" type=\"range\" min=\"0\" max=\"100\" step=\"1\" value=\"100\">\n";
    $html .= "        <div class=\"audio-meter-row\"><span>Spitzenpegel</span><strong id=\"player-peak\">–</strong></div>\n";
    $html .= "        <div class=\"control-label\"><label for=\"limiter-strength\">Schutzstärke</label><output id=\"limiter-strength-output\" for=\"limiter-strength\">30</output></div>\n";
    $html .= "        <input id=\"limiter-strength\" type=\"range\" min=\"0\" max=\"100\" step=\"1\" value=\"30\">\n";
    $html .= "      </div>\n";
    $html .= "      <p id=\"multi-guest-status\" class=\"inline-status\">Verbundene Streams: noch nicht erkannt.</p>\n";
    $html .= "      <p id=\"player-status\" role=\"status\" class=\"inline-status\">Warte auf den TikTok-Player.</p>\n";
    $html .= "      <span id=\"player-time\" class=\"player-time\" hidden>–</span>\n";
    $html .= "    </section>\n\n";

    # Top chatters section
    $html .= "    <section aria-labelledby=\"top-chatters-heading\">\n";
    $html .= "      <div class=\"section-title\">\n";
    $html .= "        <h2 id=\"top-chatters-heading\">Top-Chatter</h2>\n";
    $html .= "        <button id=\"open-audience\" class=\"secondary compact\">Zuschauer*innen</button>\n";
    $html .= "      </div>\n";
    $html .= "      <p id=\"team-tag-status\" class=\"inline-status\">Teamkürzel: noch nicht erkannt.</p>\n";
    $html .= "      <div id=\"top-chatters\" class=\"top-chatters empty\">Noch keine Personen im Chat beobachtet.</div>\n";
    $html .= "      <div id=\"top-chatters-actions\" class=\"top-chatters-actions\" hidden>\n";
    $html .= "        <button id=\"top-chatters-reset\" class=\"top-chatter-link\" type=\"button\" hidden>Reset</button>\n";
    $html .= "        <button id=\"top-chatters-more\" class=\"top-chatter-link\" type=\"button\">mehr…</button>\n";
    $html .= "      </div>\n";
    $html .= "    </section>\n\n";

    # Recommendations section
    $html .= "    <section id=\"recommendations-section\" aria-labelledby=\"recommendations-heading\">\n";
    $html .= "      <div class=\"section-title\">\n";
    $html .= "        <h2 id=\"recommendations-heading\">LIVE-Empfehlungen</h2>\n";
    $html .= "        <span id=\"recommendation-status\" class=\"live-indicator\">bereit</span>\n";
    $html .= "      </div>\n";
    $html .= "      <div class=\"recommendation-controls\">\n";
    $html .= "        <label><span>Anzahl</span><input id=\"recommendation-limit\" type=\"number\" min=\"1\" max=\"300\" step=\"1\" value=\"20\" inputmode=\"numeric\"></label>\n";
    $html .= "        <label><span>Sortierung</span><select id=\"recommendation-sort\"><option value=\"tiktok\">TikTok-Reihenfolge</option><option value=\"viewers\">Zuschauer*innen</option></select></label>\n";
    $html .= "      </div>\n";
    $html .= "      <div class=\"button-row\">\n";
    $html .= "        <button id=\"scan-recommendations\" class=\"primary\">Empfehlungen scannen</button>\n";
    $html .= "        <button id=\"cancel-recommendations\" class=\"secondary\" hidden>Abbrechen</button>\n";
    $html .= "      </div>\n";
    $html .= "      <p id=\"recommendation-progress\" class=\"inline-status\" aria-live=\"polite\">Noch kein Scan gestartet.</p>\n";
    $html .= "      <div id=\"recommendation-list\" class=\"recommendation-list empty\">Noch keine Empfehlungen erfasst.</div>\n";
    $html .= "      <div id=\"recommendation-actions\" class=\"top-chatters-actions\" hidden>\n";
    $html .= "        <button id=\"recommendation-more\" class=\"top-chatter-link\" type=\"button\">mehr…</button>\n";
    $html .= "      </div>\n";
    $html .= "    </section>\n\n";

    # Overview section
    $html .= "    <section aria-labelledby=\"overview-heading\">\n";
    $html .= "      <div class=\"section-title header-controls\"><h2 id=\"overview-heading\">STATUS-Monitor</h2><div class=\"title-actions\"><button id=\"overview-settings\" class=\"secondary compact\" type=\"button\" aria-label=\"Monitor Einstellungen\">Monitor Einstellungen</button><button id=\"overview-reset\" class=\"secondary compact\" type=\"button\" aria-label=\"Streamnamen leeren\">Streamnamen leeren</button><input id=\"overview-enabled\" type=\"checkbox\" aria-label=\"LIVE-Prüfung\"><span class=\"status-led off\" data-switch-status=\"overview-enabled\" role=\"status\"></span></div></div>\n";
    $html .= "      <div id=\"overview-rows\"></div>\n";
    $html .= "      <div class=\"button-row overview-actions\"><button id=\"overview-check\" class=\"secondary\" type=\"button\" aria-label=\"Jetzt prüfen\" title=\"Jetzt prüfen\"></button><button id=\"overview-copy\" class=\"secondary\">Alle kopieren</button><button id=\"overview-open\" class=\"primary\">Overview</button></div>\n";
    $html .= "      <div class=\"top-chatters-actions\"><button id=\"overview-collapse\" class=\"top-chatter-link\" type=\"button\" hidden>Reset</button><button id=\"overview-more\" class=\"top-chatter-link\" type=\"button\">mehr…</button></div>\n";
    $html .= "      <p id=\"overview-message\" class=\"overview-visually-hidden\" role=\"status\"></p>\n";
    $html .= "    </section>\n\n";

    # Caption section
    $html .= "    <section aria-labelledby=\"caption-heading\">\n";
    $html .= "      <div class=\"section-title\">\n";
    $html .= "        <h2 id=\"caption-heading\">Titel</h2>\n";
    $html .= "        <button id=\"scan\" class=\"secondary\">Status</button>\n";
    $html .= "      </div>\n";
    $html .= "      <div id=\"caption-status\" class=\"status-grid\"></div>\n";
    $html .= "      <button id=\"enable-captions\" class=\"primary\">Untertitel</button>\n";
    $html .= "      <p id=\"caption-action-status\" role=\"status\" class=\"inline-status action-status\"></p>\n";
    $html .= "    </section>\n\n";

    # Song section
    $html .= "    <section aria-labelledby=\"song-heading\">\n";
    $html .= "      <div class=\"section-title header-controls\">\n";
    $html .= "        <h2 id=\"song-heading\">Songs</h2>\n";
    $html .= "        <div class=\"title-actions\">\n";
    $html .= "          <input id=\"song-enabled\" type=\"checkbox\" aria-label=\"Songerkennung\" title=\"Songerkennung: Off\">\n";
    $html .= "          <span id=\"song-led\" class=\"status-led off\" data-switch-status=\"song-enabled\" role=\"status\" aria-label=\"Songerkennung inaktiv\"></span>\n";
    $html .= "        </div>\n";
    $html .= "      </div>\n";
    $html .= "      <button id=\"recognize-song\" class=\"primary\" disabled>Jetzt erkennen</button>\n";
    $html .= "      <p id=\"song-status\" class=\"inline-status\"></p>\n";
    $html .= "      <div id=\"song-result\" class=\"song-result\" hidden></div>\n";
    $html .= "    </section>\n\n";

    # Links section
    $html .= "    <section aria-labelledby=\"links-heading\">\n";
    $html .= "      <div class=\"section-title\">\n";
    $html .= "        <h2 id=\"links-heading\">HAR-Logs</h2>\n";
    $html .= "        <span id=\"media-count\" class=\"count\">0</span>\n";
    $html .= "      </div>\n";
    $html .= "      <div id=\"media-list\" class=\"list empty\">Noch keine FLV-/HLS-Links erkannt.</div>\n";
    $html .= "    </section>\n\n";

    # Log section
    $html .= "    <section aria-labelledby=\"log-heading\">\n";
    $html .= "      <div class=\"section-title header-controls\">\n";
    $html .= "        <h2 id=\"log-heading\">LIVE-Logs</h2>\n";
    $html .= "        <div class=\"title-actions\">\n";
    $html .= "          <span class=\"status-led off\" data-counter-status=\"caption-count\" role=\"status\"></span>\n";
    $html .= "          <span id=\"caption-count\" class=\"count\">0</span>\n";
    $html .= "          <button id=\"clear\" class=\"ghost compact\" title=\"Reset\">Reset</button>\n";
    $html .= "          <input id=\"live-logs-enabled\" type=\"checkbox\" aria-label=\"LIVE-Logs\" title=\"LIVE-Logs: Off\">\n";
    $html .= "          <span class=\"status-led off\" data-switch-status=\"live-logs-enabled\" role=\"status\" aria-label=\"LIVE-Logs: deaktiviert\"></span>\n";
    $html .= "        </div>\n";
    $html .= "      </div>\n";
    $html .= "      <div class=\"button-row\">\n";
    $html .= "        <button id=\"export-log\" class=\"secondary\">JSON-L-Export</button>\n";
    $html .= "        <button id=\"export-caption-raw\" class=\"secondary\">RAW-JSON-Export</button>\n";
    $html .= "      </div>\n";
    $html .= "      <div id=\"caption-list\" class=\"list empty\">Noch keine CaptionMessages empfangen.</div>\n";
    $html .= "    </section>\n\n";

    # Debug section
    $html .= "    <section aria-labelledby=\"debug-heading\">\n";
    $html .= "      <div class=\"section-title header-controls\">\n";
    $html .= "        <h2 id=\"debug-heading\">Debugmodus</h2>\n";
    $html .= "        <div class=\"title-actions\">\n";
    $html .= "          <span class=\"status-led off\" data-counter-status=\"debug-count\" role=\"status\"></span>\n";
    $html .= "          <span id=\"debug-count\" class=\"count\">0</span>\n";
    $html .= "          <button id=\"clear-debug\" class=\"ghost compact\" title=\"Reset\">Reset</button>\n";
    $html .= "          <input id=\"debug-enabled\" type=\"checkbox\" aria-label=\"Diagnoseereignisse für diesen Tab protokollieren\" title=\"Diagnoseereignisse für diesen Tab protokollieren: Off\">\n";
    $html .= "          <span class=\"status-led off\" data-switch-status=\"debug-enabled\" role=\"status\"></span>\n";
    $html .= "        </div>\n";
    $html .= "      </div>\n";
    $html .= "      <div class=\"button-row\">\n";
    $html .= "        <button id=\"export-debug\" class=\"secondary\">Debug exportieren</button>\n";
    $html .= "      </div>\n";
    $html .= "      <p class=\"muted small\"></p>\n";
    $html .= "    </section>\n\n";

    # Audience modal
    $html .= "    <div id=\"audience-modal\" class=\"modal-backdrop\" hidden>\n";
    $html .= "      <section class=\"modal\" role=\"dialog\" aria-modal=\"true\" aria-labelledby=\"audience-heading\">\n";
    $html .= "        <div class=\"section-title\">\n";
    $html .= "          <h2 id=\"audience-heading\">Im Chat beobachtete Personen</h2>\n";
    $html .= "          <button id=\"close-audience\" class=\"secondary compact\" aria-label=\"Übersicht schließen\">Schließen</button>\n";
    $html .= "        </div>\n";
    $html .= "        <p id=\"audience-limit\" class=\"inline-status\"></p>\n";
    $html .= "        <div id=\"audience-list\" class=\"audience-list\"></div>\n";
    $html .= "      </section>\n";
    $html .= "    </div>\n\n";

    # Speech settings modal
    $html .= "    <div id=\"speech-settings-modal\" class=\"modal-backdrop\" hidden>\n";
    $html .= "      <section class=\"modal\" role=\"dialog\" aria-modal=\"true\" aria-labelledby=\"speech-settings-heading\">\n";
    $html .= "        <div class=\"section-title\">\n";
    $html .= "          <h2 id=\"speech-settings-heading\">Erweiterte Einstellungen</h2>\n";
    $html .= "          <button id=\"close-speech-settings\" class=\"secondary compact\" aria-label=\"Einstellungen schließen\">Schließen</button>\n";
    $html .= "        </div>\n";
    $html .= "        <div class=\"settings-grid speech-integration-settings\">\n";
    $html .= "<label class=\"icon-style-setting\"><span>Icon-Stil</span><select id=\"icon-style\"><option value=\"plastisch\">3D / Plastisch</option><option value=\"glass\">Glass / Realistisch</option><option value=\"linear\">Minimal / Linear</option></select></label>\n";
    $html .= "          <label><span>Sprache</span><select id=\"speech-language\"><option value=\"auto\">Auto</option><option value=\"de-DE\">Deutsch</option><option value=\"en-US\">Englisch</option><option value=\"ru-RU\">Russisch</option><option value=\"uk-UA\">Ukrainisch</option><option value=\"bg-BG\">Bulgarisch</option><option value=\"sr-RS\">Serbisch</option><option value=\"kk-KZ\">Kasachisch</option><option value=\"zh-CN\">Chinesisch</option><option value=\"ja-JP\">Japanisch</option><option value=\"ko-KR\">Koreanisch</option><option value=\"ar-JO\">Arabisch</option><option value=\"fa-IR\">Persisch</option><option value=\"ur-PK\">Urdu</option><option value=\"hi-IN\">Hindi</option><option value=\"ne-NP\">Nepali</option><option value=\"ml-IN\">Malayalam</option></select></label>\n";
    $html .= "          <label><span>Stimme</span><select id=\"speech-voice\"><option value=\"\">Standard</option></select></label>\n";
    $html .= "          <label id=\"audd-token-setting\"><span id=\"audd-token-label\">AudD API-Token (optional - <a href=\"https://audd.io/\" target=\"_blank\" rel=\"noopener noreferrer\">https://AudD.io</a> Trial/Paid)</span><input id=\"audd-token\" type=\"password\" autocomplete=\"off\" spellcheck=\"false\"></label>\n";
    $html .= "          <label id=\"pairing-code-setting\"><span>Pairing-Code</span><input id=\"pairing-code\" type=\"password\" autocomplete=\"off\" spellcheck=\"false\"></label>\n";
    $html .= "          <label><span>Universal API-Key</span><input id=\"universal-caption-api-key\" type=\"password\" autocomplete=\"off\" spellcheck=\"false\"></label>\n";
    $html .= "        </div>\n";
    $html .= "        <label class=\"option-row\"><input id=\"speak-names\" type=\"checkbox\" checked> Chatnamen sprechen</label>\n";
    $html .= "        <label class=\"option-row\"><input id=\"shorten-names\" type=\"checkbox\"> Chatnamen kürzen</label>\n";
    $html .= "        <label class=\"option-row auto-chat-refresh\"><input id=\"auto-chat-refresh\" type=\"checkbox\"> Auto-Chat Refresh <input id=\"auto-chat-refresh-minutes\" type=\"number\" min=\"1\" max=\"60\" step=\"1\" value=\"5\" inputmode=\"numeric\" aria-label=\"Auto-Chat-Refresh in Minuten\"><span>min.</span></label>\n";
    $html .= "        <label class=\"option-row\"><input id=\"game-mode\" type=\"checkbox\"> Game-Mode (Spam-, Emoji, usw. Chatfilter)</label>\n";
    $html .= "        <div class=\"option-row external-speech-trigger-row\"><label><input id=\"filter-external-speech-triggers\" type=\"checkbox\"> Trigger filtern (ext. Sprachdienste)</label><input id=\"external-speech-trigger-characters\" type=\"text\" value=\".\" maxlength=\"10\" aria-label=\"Triggerzeichen, maximal fünf Sonderzeichen\" autocomplete=\"off\" spellcheck=\"false\"></div>\n";
    $html .= "        <label class=\"option-row\"><input id=\"keep-speech-active\" type=\"checkbox\" aria-label=\"Vorlesen dauerhaft\" title=\"Vorlesen dauerhaft: Off\"> Vorlesen dauerhaft</label>\n";
    $html .= "      </section>\n";
    $html .= "    </div>\n\n";

    # Chat history modal
    $html .= "    <div id=\"chat-history-modal\" class=\"modal-backdrop\" hidden>\n";
    $html .= "      <section class=\"modal\" role=\"dialog\" aria-modal=\"true\" aria-labelledby=\"chat-history-heading\">\n";
    $html .= "        <div class=\"section-title\">\n";
    $html .= "          <h2 id=\"chat-history-heading\">Gesammelte Chatnachrichten</h2>\n";
    $html .= "          <button id=\"close-chat-history\" class=\"secondary compact\" aria-label=\"Chatzeilen schließen\">Schließen</button>\n";
    $html .= "        </div>\n";
    $html .= "        <p id=\"chat-history-limit\" class=\"inline-status\"></p>\n";
    $html .= "        <div id=\"chat-history-list\" class=\"chat-history-list\"></div>\n";
    $html .= "      </section>\n";
    $html .= "    </div>\n\n";

    # Recommendation modal
    $html .= "    <div id=\"recommendation-modal\" class=\"modal-backdrop\" hidden>\n";
    $html .= "      <section class=\"modal\" role=\"dialog\" aria-modal=\"true\" aria-labelledby=\"recommendation-modal-heading\">\n";
    $html .= "        <div class=\"section-title\">\n";
    $html .= "          <h2 id=\"recommendation-modal-heading\">Gescannte LIVE-Empfehlungen</h2>\n";
    $html .= "          <button id=\"close-recommendations\" class=\"secondary compact\" aria-label=\"Empfehlungen schließen\">Schließen</button>\n";
    $html .= "        </div>\n";
    $html .= "        <div id=\"recommendation-modal-list\" class=\"recommendation-list\"></div>\n";
    $html .= "      </section>\n";
    $html .= "    </div>\n\n";

    # Notice
    $html .= "    <p id=\"notice\" role=\"alert\" class=\"notice\"></p>\n";
    $html .= "  </main>\n";

    # Connection settings modal
    $html .= "  <div id=\"connection-settings-modal\" class=\"modal-backdrop\" hidden>\n";
    $html .= "    <section class=\"modal\" role=\"dialog\" aria-modal=\"true\" aria-labelledby=\"connection-settings-heading\">\n";
    $html .= "      <div class=\"section-title\"><h2 id=\"connection-settings-heading\">Connection-Einstellungen</h2><button id=\"close-connection-settings\" class=\"secondary compact\">Schließen</button></div>\n";
    $html .= "      <label class=\"option-row top-setting\"><input id=\"connection-top\" type=\"checkbox\"> Connection @ Top</label>\n";
    $html .= "      <label class=\"option-row quick-recover-setting\"><input id=\"hook-reconnect\" type=\"checkbox\"> Hook-Reconnect <input id=\"hook-reconnect-seconds\" type=\"number\" min=\"1\" max=\"59\" step=\"1\" value=\"3\" inputmode=\"numeric\" aria-label=\"Hook-Reconnect-Wartezeit in Sekunden\"><span>Sek.</span></label>\n";
    $html .= "      <label class=\"option-row quick-recover-setting\"><input id=\"quick-recover\" type=\"checkbox\"> Player-Recovery <input id=\"quick-recover-seconds\" type=\"number\" min=\"1\" max=\"59\" step=\"1\" value=\"3\" inputmode=\"numeric\" aria-label=\"Player-Recovery-Bestätigungszeit in Sekunden\"><span>Sek.</span></label>\n";
    $html .= "    </section>\n";
    $html .= "  </div>\n\n";

    # Overview settings modal
    $html .= "  <div id=\"overview-settings-modal\" class=\"modal-backdrop\" hidden>\n";
    $html .= "    <section class=\"modal monitor-settings\" role=\"dialog\" aria-modal=\"true\" aria-labelledby=\"overview-settings-heading\">\n";
    $html .= "      <div class=\"section-title\"><h2 id=\"overview-settings-heading\">Monitor Einstellungen</h2><button id=\"overview-settings-close\" class=\"secondary compact\">Schließen</button></div>\n";
    $html .= "      <label>Prüfintervall (Minuten) <input id=\"overview-interval\" type=\"number\" min=\"1\" max=\"60\" value=\"5\"></label>\n";
    $html .= "      <label>Maximale Links pro Stream <input id=\"overview-max-links\" type=\"number\" min=\"5\" max=\"30\" value=\"5\"></label>\n";
    $html .= "      <label class=\"option-row\"><input id=\"overview-top\" type=\"checkbox\"> Monitor @ Top</label>\n";
    $html .= "      <label class=\"option-row\"><input id=\"overview-show-links\" type=\"checkbox\"> Streamlinks anzeigen</label>\n";
    $html .= "      <label class=\"option-row\"><input id=\"overview-auto-sort\" type=\"checkbox\"> Online-Streams automatisch sortieren</label>\n";
    $html .= "      <label class=\"option-row\"><input id=\"overview-reverse\" type=\"checkbox\"> Übersicht von unten nach oben</label>\n";
    $html .= "      <label class=\"option-row\"><input id=\"overview-grid2\" type=\"checkbox\"> Übersicht 2×2</label>\n";
    $html .= "      <label class=\"option-row\"><input id=\"overview-skip-online\" type=\"checkbox\"> Online-Streams nicht erneut prüfen</label>\n";
    $html .= "    </section>\n";
    $html .= "  </div>\n";

    # Overview links modal
    $html .= "  <div id=\"overview-links-modal\" class=\"modal-backdrop\" hidden>\n";
    $html .= "    <section class=\"modal\" role=\"dialog\" aria-modal=\"true\" aria-labelledby=\"overview-links-heading\">\n";
    $html .= "      <div class=\"section-title\"><h2 id=\"overview-links-heading\">Streamlinks</h2><button id=\"overview-links-close\" class=\"secondary compact\">Schließen</button></div>\n";
    $html .= "      <div id=\"overview-links-list\"></div>\n";
    $html .= "    </section>\n";
    $html .= "  </div>\n\n";

    # Scripts
    $html .= "  <script src=\"content-core.js\"></script>\n";
    $html .= "  <script src=\"sidepanel.js\"></script>\n";
    $html .= "  <script src=\"status-overview-panel.js\"></script>\n";
    $html .= "  <script src=\"icon-controls.js\"></script>\n";
    $html .= "</body>\n";
    $html .= "</html>\n";

    return $html;
}

# Main execution
if (@ARGV != 1) {
    print STDERR "Usage: $0 <output_file>\n";
    exit 1;
}

my $output_file = $ARGV[0];

#
