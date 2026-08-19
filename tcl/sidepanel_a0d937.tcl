#!/usr/bin/env tclsh
# sidepanel.html — portiert nach tcl
# Quelle: html, Projects@TikTok-Live-Companion:plugin-source/browser-extension/sidepanel.html
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/sidepanel.html
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/sidepanel.html
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

# Generate sidepanel.html from Tcl script
# This script creates the HTML structure programmatically

proc generateSidePanel {} {
    set html ""

    # Add DOCTYPE and html tag
    append html "<!doctype html>\n"
    append html "<html lang=\"de\">\n"
    
    # Head section
    append html [generateHead]
    
    # Body section
    append html [generateBody]
    
    # Close html tag
    append html "</html>\n"
    
    return $html
}

proc generateHead {} {
    set head ""
    append head "<head>\n"
    append head "  <meta charset=\"utf-8\">\n"
    append head "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n"
    append head "  <title>TikTok LIVE Companion</title>\n"
    append head "  <link rel=\"stylesheet\" href=\"sidepanel.css\">\n"
    append head "</head>\n"
    return $head
}

proc generateBody {} {
    set body ""
    append body "<body>\n"
    
    # Header
    append body "  <header>\n"
    append body "    <p id=\"page-title\" class=\"muted\">Kein TikTok-Tab ausgewählt</p>\n"
    append body "  </header>\n\n"
    
    # Main content
    append body "  <main>\n"
    
    # Chat section
    append body [generateChatSection]
    
    # Top chatters section
    append body [generateTopChattersSection]
    
    # Page info section
    append body [generatePageInfoSection]
    
    # Stats section
    append body [generateStatsSection]
    
    # Hook section
    append body [generateHookSection]
    
    # Recommendations section
    append body [generateRecommendationsSection]
    
    # Caption section
    append body [generateCaptionSection]
    
    # Player section
    append body [generatePlayerSection]
    
    # Song section
    append body [generateSongSection]
    
    # Links section
    append body [generateLinksSection]
    
    # Log section
    append body [generateLogSection]
    
    # Debug section
    append body [generateDebugSection]
    
    # Modals
    append body [generateModals]
    
    # Notice
    append body "    <p id=\"notice\" role=\"alert\" class=\"notice\"></p>\n"
    
    # Close main
    append body "  </main>\n\n"
    
    # Scripts
    append body "  <script src=\"content-core.js\"></script>\n"
    append body "  <script src=\"sidepanel.js\"></script>\n"
    
    # Close body
    append body "</body>\n"
    
    return $body
}

proc generateChatSection {} {
    set section ""
    append section "    <section aria-labelledby=\"chat-heading\">\n"
    append section "      <div class=\"section-title\">\n"
    append section "        <h2 id=\"chat-heading\">Chatzeilen</h2>\n"
    append section "        <div class=\"title-actions\">\n"
    append section "          <span id=\"chat-led\" class=\"status-led off\" role=\"status\" aria-label=\"Chat inaktiv\" title=\"Chat inaktiv\"></span>\n"
    append section "          <button id=\"chat-count\" class=\"count count-button\" type=\"button\" aria-haspopup=\"dialog\" title=\"Gesammelte Chatzeilen öffnen\">0</button>\n"
    append section "          <button id=\"refresh-chat\" class=\"secondary compact\" title=\"Chatanzeige leeren\">Refresh</button>\n"
    append section "          <button id=\"toggle-speech\" class=\"secondary compact\" aria-pressed=\"false\">Vorlesen</button>\n"
    append section "          <span id=\"speech-led\" class=\"status-led off\" role=\"status\" aria-label=\"Vorlesen inaktiv\" title=\"Vorlesen inaktiv\"></span>\n"
    append section "        </div>\n"
    append section "      </div>\n"
    append section "      <div id=\"chat-list\" class=\"chat-list empty\" role=\"log\" aria-live=\"polite\" aria-relevant=\"additions\" aria-label=\"Die letzten fünf bereinigten Chatnachrichten\">Noch keine Chatnachrichten erkannt.</div>\n"
    append section "      <p id=\"speech-status\" role=\"status\" class=\"inline-status\">Vorlesen ist ausgeschaltet.</p>\n"
    append section "      <div class=\"control-label\"><label for=\"speech-volume\">Vorleselautstärke</label><output id=\"speech-volume-output\" for=\"speech-volume\">100%</output></div>\n"
    append section "      <input id=\"speech-volume\" type=\"range\" min=\"0\" max=\"100\" step=\"5\" value=\"50\">\n"
    append section "      <div class=\"button-row\">\n"
    append section "        <button id=\"service-action\" class=\"secondary\">Sprachdienst</button>\n"
    append section "        <button id=\"sherpa-action\" class=\"secondary\">Sherpa</button>\n"
    append section "        <button id=\"open-speech-settings\" class=\"secondary compact settings-button\" type=\"button\" aria-label=\"Sprach- und Chat-Einstellungen öffnen\" aria-haspopup=\"dialog\" title=\"Einstellungen\">⚙</button>\n"
    append section "      </div>\n"
    append section "      <p id=\"service-status\" class=\"inline-status\">Lokaler Sprachdienst noch nicht geprüft.</p>\n"
    append section "      <div id=\"service-setup\" class=\"inline-status\" hidden>\n"
    append section "        <button id=\"copy-service-setup\" class=\"secondary compact\">Installation abschließen!</button>\n"
    append section "      </div>\n"
    append section "      <label class=\"option-row auto-chat-refresh\"><input id=\"auto-chat-refresh\" type=\"checkbox\"> Auto-Chat Refresh <input id=\"auto-chat-refresh-minutes\" type=\"number\" min=\"1\" max=\"60\" step=\"1\" value=\"5\" inputmode=\"numeric\" aria-label=\"Auto-Chat-Refresh in Minuten\"><span>min.</span></label>\n"
    append section "      <label class=\"option-row\"><input id=\"keep-speech-active\" type=\"checkbox\"> Permanent aktiv</label>\n"
    append section "    </section>\n\n"
    
    return $section
}

proc generateTopChattersSection {} {
    set section ""
    append section "    <section aria-labelledby=\"top-chatters-heading\">\n"
    append section "      <div class=\"section-title\">\n"
    append section "        <h2 id=\"top-chatters-heading\">Top-Chatter</h2>\n"
    append section "        <button id=\"open-audience\" class=\"secondary compact\">Zuschauer*innen</button>\n"
    append section "      </div>\n"
    append section "      <p id=\"team-tag-status\" class=\"inline-status\">Teamkürzel: noch nicht erkannt.</p>\n"
    append section "      <div id=\"top-chatters\" class=\"top-chatters empty\">Noch keine Personen im Chat beobachtet.</div>\n"
    append section "      <div id=\"top-chatters-actions\" class=\"top-chatters-actions\" hidden>\n"
    append section "        <button id=\"top-chatters-reset\" class=\"top-chatter-link\" type=\"button\" hidden>Reset</button>\n"
    append section "        <button id=\"top-chatters-more\" class=\"top-chatter-link\" type=\"button\">mehr…</button>\n"
    append section "      </div>\n"
    append section "    </section>\n\n"
    
    return $section
}

proc generatePageInfoSection {} {
    set section ""
    append section "    <section id=\"page-info-section\" aria-labelledby=\"page-info-heading\">\n"
    append section "      <div class=\"section-title\">\n"
    append section "        <h2 id=\"page-info-heading\">Seiteninformationen</h2>\n"
    append section "        <div class=\"title-actions\">\n"
    append section "          <span id=\"page-info-source\" class=\"live-indicator\">Metadaten</span>\n"
    append section "          <button id=\"refresh-page-info\" class=\"secondary compact\">Refresh</button>\n"
    append section "          <button id=\"force-page-info\" class=\"secondary compact danger-outline\">Force</button>\n"
    append section "        </div>\n"
    append section "      </div>\n"
    append section "      <div id=\"profile-info\" class=\"profile-info\" hidden></div>\n"
    append section "      <div id=\"summary-info\" class=\"summary-info\"></div>\n"
    append section "    </section>\n\n"
    
    return $section
}

proc generateStatsSection {} {
    set section ""
    append section "    <section aria-labelledby=\"stats-heading\">\n"
    append section "      <div class=\"section-title\">\n"
    append section "        <h2 id=\"stats-heading\">LIVE-Informationen</h2>\n"
    append section "        <span id=\"stats-live\" class=\"live-indicator\">warte</span>\n"
    append section "      </div>\n"
    append section "      <div id=\"live-stats\" class=\"status-grid stats-grid\"></div>\n"
    append section "      <p id=\"stats-status\" class=\"inline-status\"></p>\n"
    append section "    </section>\n\n"
    
    return $section
}

proc generateHookSection {} {
    set section ""
    append section "    <section aria-labelledby=\"hook-heading\">\n"
    append section "      <div class=\"section-title\">\n"
    append section "        <h2 id=\"hook-heading\">WebSocket-Hook</h2>\n"
    append section "        <span id=\"hook-led\" class=\"status-led off\" role=\"status\" aria-label=\"Hook inaktiv\" title=\"Hook inaktiv\"></span>\n"
    append section "      </div>\n"
    append section "      <div class=\"button-row\">\n"
    append section "        <button id=\"enable-hook\" class=\"primary\">Hook setzen</button>\n"
    append section "        <button id=\"disable-hook\" class=\"secondary\">Hook deaktivieren</button>\n"
    append section "        <button id=\"reset-tab\" class=\"secondary danger-outline\">Refresh</button>\n"
    append section "        <button id=\"open-embed-live\" class=\"secondary\">Embed</button>\n"
    append section "        <button id=\"open-normal-live\" class=\"secondary\">Normal</button>\n"
    append section "        <button id=\"player-vlc-frame\" class=\"secondary compact\">VLC Ersatz</button>\n"
    append section "      </div>\n"
    append section "      <p id=\"hook-status\" class=\"inline-status\"></p>\n"
    append section "      <label class=\"option-row\"><input id=\"hook-autostart\" type=\"checkbox\"> Permanent Hook</label>\n"
    append section "      <label class=\"option-row quick-recover-setting\"><input id=\"quick-recover\" type=\"checkbox\"> Auto-Reconnect <input id=\"quick-recover-seconds\" type=\"number\" min=\"1\" max=\"59\" step=\"1\" value=\"3\" inputmode=\"numeric\" aria-label=\"Auto-Reconnect-Wartezeit in Sekunden\"><span>Sek.</span></label>\n"
    append section "    </section>\n\n"
    
    return $section
}

proc generateRecommendationsSection {} {
    set section ""
    append section "    <section id=\"recommendations-section\" aria-labelledby=\"recommendations-heading\">\n"
    append section "      <div class=\"section-title\">\n"
    append section "        <h2 id=\"recommendations-heading\">LIVE-Empfehlungen</h2>\n"
    append section "        <span id=\"recommendation-status\" class=\"live-indicator\">bereit</span>\n"
    append section "      </div>\n"
    append section "      <div class=\"recommendation-controls\">\n"
    append section "        <label><span>Anzahl</span><input id=\"recommendation-limit\" type=\"number\" min=\"1\" max=\"50\" step=\"1\" value=\"20\" inputmode=\"numeric\"></label>\n"
    append section "        <label><span>Sortierung</span><select id=\"recommendation-sort\"><option value=\"tiktok\">TikTok-Reihenfolge</option><option value=\"viewers\">Zuschauer*innen</option></select></label>\n"
    append section "      </div>\n"
    append section "      <div class=\"button-row\">\n"
    append section "        <button id=\"scan-recommendations\" class=\"primary\">Empfehlungen scannen</button>\n"
    append section "        <button id=\"cancel-recommendations\" class=\"secondary\" hidden>Abbrechen</button>\n"
    append section "      </div>\n"
    append section "      <p id=\"recommendation-progress\" class=\"inline-status\" aria-live=\"polite\">Noch kein Scan gestartet.</p>\n"
    append section "      <div id=\"recommendation-list\" class=\"recommendation-list empty\">Noch keine Empfehlungen erfasst.</div>\n"
    append section "      <div id=\"recommendation-actions\" class=\"top-chatters-actions\" hidden>\n"
    append section "        <button id=\"recommendation-more\" class=\"top-chatter-link\" type=\"button\">mehr…</button>\n"
    append section "      </div>\n"
    append section "    </section>\n\n"
    
    return $section
}

proc generateCaptionSection {} {
    set section ""
    append section "    <section aria-labelledby=\"caption-heading\">\n"
    append section "      <div class=\"section-title\">\n"
    append section "        <h2 id=\"caption-heading\">Untertitel</h2>\n"
    append section "        <button id=\"scan\" class=\"secondary\">Seite prüfen</button>\n"
    append section "      </div>\n"
    append section "      <div id=\"caption-status\" class=\"status-grid\"></div>\n"
    append section "      <button id=\"enable-captions\" class=\"primary\">Untertitel aktivieren</button>\n"
    append section "      <p id=\"caption-action-status\" role=\"status\" class=\"inline-status action-status\"></p>\n"
    append section "    </section>\n\n"
    
    return $section
}

proc generatePlayerSection {} {
    set section ""
    append section "    <section aria-labelledby=\"player-heading\">\n"
    append section "      <div class=\"section-title\">\n"
    append section "        <h2 id=\"player-heading\">Playersteuerung</h2>\n"
    append section "        <span id=\"player-time\" class=\"player-time\">–</span>\n"
    append section "      </div>\n"
    append section "      <div class=\"player-controls\" role=\"group\" aria-label=\"TikTok-Player steuern\">\n"
    append section "        <button id=\"player-play\" class=\"secondary compact\">Pause</button>\n"
    append section "        <button id=\"player-replay\" class=\"secondary compact\">Neu laden</button>\n"
    append section "        <button id=\"player-mute\" class=\"secondary compact\">Stumm</button>\n"
    append section "        <button id=\"player-pip\" class=\"secondary compact\">Bild-in-Bild</button>\n"
    append section "        <button id=\"player-fullscreen\" class=\"secondary compact\">Vollbild</button>\n"
    append section "        <button id=\"player-report\" class=\"secondary compact danger-outline\">Melden öffnen</button>\n"
    append section "      </div>\n"
    append section "      <div class=\"audio-controls\">\n"
    append section "        <div class=\"control-label\"><label for=\"player-volume\">Lautstärke</label><output id=\"player-volume-output\" for=\"player-volume\">–</output></div>\n"
    append section "        <input id=\"player-volume\" type=\"range\" min=\"0\" max=\"100\" step=\"1\" value=\"100\">\n"
    append section "        <div class=\"audio-meter-row\"><span>Spitzenpegel</span><strong id=\"player-peak\">–</strong></div>\n"
    append section "        <label class=\"option-row\"><input id=\"limiter-enabled\" type=\"checkbox\"> Pegelschutz aktivieren</label>\n"
    append section "        <div class=\"control-label\"><label for=\"limiter-strength\">Schutzstärke</label><output id=\"limiter-strength-output\" for=\"limiter-strength\">30</output></div>\n"
    append section "        <input id=\"limiter-strength\" type=\"range\" min=\"0\" max=\"100\" step=\"1\" value=\"30\">\n"
    append section "      </div>\n"
    append section "      <p id=\"multi-guest-status\" class=\"inline-status\">Verbundene Streams: noch nicht erkannt.</p>\n"
    append section "      <p id=\"player-status\" role=\"status\" class=\"inline-status\">Warte auf den TikTok-Player.</p>\n"
    append section "    </section>\n\n"
    
    return $section
}

proc generateSongSection {} {
    set section ""
    append section "    <section aria-labelledby=\"song-heading\">\n"
    append section "      <div class=\"section-title\">\n"
    append section "        <h2 id=\"song-heading\">Songerkennung</h2>\n"
    append section "        <span id=\"song-led\" class=\"status-led off\" role=\"status\" aria-label=\"Songerkennung inaktiv\"></span>\n"
    append section "      </div>\n"
    append section "      <label class=\"option-row\"><input id=\"song-enabled\" type=\"checkbox\"> Songerkennung aktivieren</label>\n"
    append section "      <button id=\"recognize-song\" class=\"primary\" disabled>Jetzt erkennen</button>\n"
    append section "      <p id=\"song-status\" class=\"inline-status\"></p>\n"
    append section "      <div id=\"song-result\" class=\"song-result\" hidden></div>\n"
    append section "    </section>\n\n"
    
    return $section
}

proc generateLinksSection {} {
    set section ""
    append section "    <section aria-labelledby=\"links-heading\">\n"
    append section "      <div class=\"section-title\">\n"
    append section "        <h2 id=\"links-heading\">VLC-Links</h2>\n"
    append section "        <span id=\"media-count\" class=\"count\">0</span>\n"
    append section "      </div>\n"
    append section "      <div id=\"media-list\" class=\"list empty\">Noch keine FLV-/HLS-Links erkannt.</div>\n"
    append section "    </section>\n\n"
    
    return $section
}

proc generateLogSection {} {
    set section ""
    append section "    <section aria-labelledby=\"log-heading\">\n"
    append section "      <div class=\"section-title\">\n"
    append section "        <h2 id=\"log-heading\">Caption-Protokoll</h2>\n"
    append section "        <span id=\"caption-count\" class=\"count\">0</span>\n"
    append section "      </div>\n"
    append section "      <div class=\"button-row\">\n"
    append section "        <button id=\"export-log\" class=\"secondary\">JSON-L-Export</button>\n"
    append section "        <button id=\"export-caption-raw\" class=\"secondary\">RAW-JSON-Export</button>\n"
    append section "        <button id=\"clear\" class=\"ghost\">Anzeige leeren</button>\n"
    append section "      </div>\n"
    append section "      <div id=\"caption-list\" class=\"list empty\">Noch keine CaptionMessages empfangen.</div>\n"
    append section "    </section>\n\n"
    
    return $section
}

proc generateDebugSection {} {
    set section ""
    append section "    <section aria-labelledby=\"debug-heading\">\n"
    append section "      <div class=\"section-title\">\n"
    append section "        <h2 id=\"debug-heading\">Debugmodus</h2>\n"
    append section "        <span id=\"debug-count\" class=\"count\">0</span>\n"
    append section "      </div>\n"
    append section "      <label class=\"option-row\"><input id=\"debug-enabled\" type=\"checkbox\"> Diagnoseereignisse für diesen Tab protokollieren</label>\n"
    append section "      <div class=\"button-row\">\n"
    append section "        <button id=\"export-debug\" class=\"secondary\">Debug exportieren</button>\n"
    append section "        <button id=\"clear-debug\" class=\"ghost\">Debug leeren</button>\n"
    append section "      </div>\n"
    append section "      <p class=\"muted small\"></p>\n"
    append section "    </section>\n\n"
    
    return $section
}

proc generateModals {} {
    set modals ""
    
    # Audience modal
    append modals "    <div id=\"audience-modal\" class=\"modal-backdrop\" hidden>\n"
    append modals "      <section class=\"modal\" role=\"dialog\" aria-modal=\"true\" aria-labelledby=\"audience-heading\">\n"
    append modals "        <div class=\"section-title\">\n"
    append modals "          <h2 id=\"audience-heading\">Im Chat beobachtete Personen</h2>\n"
    append modals "          <button id=\"close-audience\" class=\"secondary compact\" aria-label=\"Übersicht schließen\">Schließen</button>\n"
    append modals "        </div>\n"
    append modals "        <p id=\"audience-limit\" class=\"inline-status\"></p>\n"
    append modals "        <div id=\"audience-list\" class=\"audience-list\"></div>\n"
    append modals "      </section>\n"
    append modals "    </div>\n\n"
    
    # Speech settings modal
    append modals "    <div id=\"speech-settings-modal\" class=\"modal-backdrop\" hidden>\n"
    append modals "      <section class=\"modal\" role=\"dialog\" aria-modal=\"true\" aria-labelledby=\"speech-settings-heading\">\n"
    append modals "        <div class=\"section-title\">\n"
    append modals "          <h2 id=\"speech-settings-heading\">Sprach- und Chat-Einstellungen</h2>\n"
    append modals "          <button id=\"close-speech-settings\" class=\"secondary compact\" aria-label=\"Einstellungen schließen\">Schließen</button>\n"
    append modals "        </div>\n"
    append modals "        <div class=\"settings-grid speech-integration-settings\">\n"
    append modals "          <label><span>Sprache</span><select id=\"speech-language\"><option value=\"auto\">Auto</option><option value=\"de-DE\">Deutsch</option><option value=\"en-US\">Englisch</option><option value=\"ru-RU\">Russisch</option><option value=\"uk-UA\">Ukrainisch</option><option value=\"bg-BG\">Bulgarisch</option><option value=\"sr-RS\">Serbisch</option><option value=\"kk-KZ\">Kasachisch</option><option value=\"zh-CN\">Chinesisch</option><option value=\"ja-JP\">Japanisch</option><option value=\"ko-KR\">Koreanisch</option><option value=\"ar-JO\">Arabisch</option><option value=\"fa-IR\">Persisch</option><option value=\"ur-PK\">Urdu</option><option value=\"hi-IN\">Hindi</option><option value=\"ne-NP\">Nepali</option><option value=\"ml-IN\">Malayalam</option></select></label>\n"
    append modals "          <label><span>Stimme</span><select id=\"speech-voice\"><option value=\"\">Standard</option></select></label>\n"
    append modals "          <label id=\"audd-token-setting\"><span id=\"audd-token-label\">AudD API-Token (optional - <a href=\"https://audd.io/\" target=\"_blank\" rel=\"noopener noreferrer\">https://AudD.io</a> Trial/Paid)</span><input id=\"audd-token\" type=\"password\" autocomplete=\"off\" spellcheck=\"false\"></label>\n"
    append modals "          <label id=\"pairing-code-setting\"><span>Pairing-Code</span><input id=\"pairing-code\" type=\"password\" autocomplete=\"off\" spellcheck=\"false\"></label>\n"
    append modals "          <label><span>Universal API-Key für Untertitel</span><input id=\"universal-caption-api-key\" type=\"password\" autocomplete=\"off\" spellcheck=\"false\"></label>\n"
    append modals "        </div>\n"
    append modals "        <label class=\"option-row\"><input id=\"speak-names\" type=\"checkbox\" checked> Chatnamen sprechen</label>\n"
    append modals "        <label class=\"option-row\"><input id=\"shorten-names\" type=\"checkbox\"> Chatnamen kürzen</label>\n"
    append modals "        <label class=\"option-row\"><input id=\"game-mode\" type=\"checkbox\"> Game-Mode</label>\n"
    append modals "      </section>\n"
    append modals "    </div>\n\n"
    
    # Chat history modal
    append modals "    <div id=\"chat-history-modal\" class=\"modal-backdrop\" hidden>\n"
    append modals "      <section class=\"modal\" role=\"dialog\" aria-modal=\"true\" aria-labelledby=\"chat-history-heading\">\n"
    append modals "        <div class=\"section-title\">\n"
    append modals "          <h2 id=\"chat-history-heading\">Gesammelte Chatzeilen</h2>\n"
    append modals "          <button id=\"close-chat-history\" class=\"secondary compact\" aria-label=\"Chatzeilen schließen\">Schließen</button>\n"
    append modals "        </div>\n"
    append modals "        <p id=\"chat-history-limit\" class=\"inline-status\"></p>\n"
    append modals "        <div id=\"chat-history-list\" class=\"chat-history-list\"></div>\n"
    append modals "      </section>\n"
    append modals "    </div>\n\n"
    
    # Recommendation modal
    append modals "    <div id=\"recommendation-modal\" class=\"modal-backdrop\" hidden>\n"
    append modals "      <section class=\"modal\" role=\"dialog\" aria-modal=\"true\" aria-labelledby=\"recommendation-modal-heading\">\n"
    append modals "        <div class=\"section-title\">\n"
    append modals "          <h2 id=\"recommendation-modal-heading\">Gescannte LIVE-Empfehlungen</h2>\n"
    append modals "          <button id=\"close-recommendations\" class=\"secondary compact\" aria-label=\"Empfehlungen schließen\">Schließen</button>\n"
    append modals "        </div>\n"
    append modals "        <div id=\"recommendation-modal-list\" class=\"recommendation-list\"></div>\n"
    append modals "      </section>\n"
    append modals "    </div>\n\n"
    
    return $modals
}

# Main execution
if {[info exists argv] && [llength $argv] > 0} {
    set filename [lindex $argv 0]
    set fd [open $filename w]
    puts $fd [generateSidePanel]
    close $fd
    puts "Generated $filename"
} else {
    puts [generateSidePanel]
}
