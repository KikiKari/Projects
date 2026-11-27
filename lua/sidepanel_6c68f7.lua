#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "a90e1444cee51cbea2bf2077efaa1b2645dc6a9a8deff5032730c91b73e21c77", "source_sha256": "6c68f7375733776fa70f0fd1e48fe739ffdf7c38b6444a8ef7c36fd50e4d08e9", "target_language": "lua"}
-- sidepanel.html — portiert nach lua
-- Quelle: html, Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/sidepanel.html
-- auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/sidepanel.html
-- auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/browser-extension/sidepanel.html
-- Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

local function create_html_document()
    local html = {}
    
    -- Helper functions for building HTML structure
    local function add(tag, attrs, content)
        local attr_str = ""
        if attrs then
            for k, v in pairs(attrs) do
                attr_str = attr_str .. string.format(' %s="%s"', k, v)
            end
        end
        
        if content == nil then
            table.insert(html, string.format("<%s%s>", tag, attr_str))
        elseif type(content) == "table" then
            table.insert(html, string.format("<%s%s>", tag, attr_str))
            for _, item in ipairs(content) do
                table.insert(html, item)
            end
            table.insert(html, string.format("</%s>", tag))
        else
            table.insert(html, string.format("<%s%s>%s</%s>", tag, attr_str, content, tag))
        end
    end
    
    -- Document structure
    table.insert(html, '<!doctype html>')
    table.insert(html, '<html lang="de">')
    
    -- Head section
    table.insert(html, '<head>')
    table.insert(html, '  <meta charset="utf-8">')
    table.insert(html, '  <meta name="viewport" content="width=device-width, initial-scale=1">')
    table.insert(html, '  <title>TikTok LIVE Companion</title>')
    table.insert(html, '  <link rel="stylesheet" href="sidepanel.css">')
    table.insert(html, '  <link rel="stylesheet" href="icon-controls.css">')
    table.insert(html, '</head>')
    
    -- Body start
    table.insert(html, '<body>')
    
    -- Header
    table.insert(html, '  <header>')
    add("p", {id="page-title", class="muted"}, "Kein TikTok-Tab ausgewählt")
    table.insert(html, '  </header>')
    
    -- Main content
    table.insert(html, '  <main>')
    
    -- Chat section
    table.insert(html, '    <section aria-labelledby="chat-heading">')
    table.insert(html, '      <div class="section-title">')
    add("h2", {id="chat-heading"}, "Chat")
    table.insert(html, '        <div class="title-actions">')
    add("span", {id="chat-led", class="status-led off", role="status", ["aria-label"]="Chat inaktiv", title="Chat inaktiv"})
    add("button", {id="chat-count", class="count count-button", type="button", ["aria-haspopup"]="dialog", title="Gesammelte Chatzeilen öffnen"}, "0")
    add("button", {id="refresh-chat", class="secondary compact", title="Chatanzeige leeren"}, "Reset")
    add("button", {id="toggle-speech", class="secondary compact", ["aria-pressed"]="false", ["aria-label"]="Vorlesen"}, "On")
    add("span", {id="speech-led", class="status-led off", role="status", ["aria-label"]="Vorlesen inaktiv", title="Vorlesen inaktiv"})
    table.insert(html, '        </div>')
    table.insert(html, '      </div>')
    add("div", {id="chat-list", class="chat-list empty", role="log", ["aria-live"]="polite", ["aria-relevant"]="additions", ["aria-label"]="Die letzten fünf bereinigten Chatnachrichten"}, "Noch keine Chatnachrichten erkannt.")
    add("p", {id="speech-status", role="status", class="inline-status"}, "Vorlesen ist ausgeschaltet.")
    table.insert(html, '      <div class="control-label"><label for="speech-volume">Vorleselautstärke</label><output id="speech-volume-output" for="speech-volume">100%</output></div>')
    add("input", {id="speech-volume", type="range", min="0", max="100", step="5", value="50"})
    table.insert(html, '      <div class="button-row">')
    add("button", {id="service-action", class="secondary"}, "Sprachdienst")
    add("button", {id="sherpa-action", class="secondary"}, "Sherpa")
    add("button", {id="open-speech-settings", class="secondary compact settings-button", type="button", ["aria-label"]="Erweiterte Einstellungen öffnen", ["aria-haspopup"]="dialog", title="Einstellungen"})
    table.insert(html, '      </div>')
    add("p", {id="service-status", class="inline-status"}, "Lokaler Sprachdienst noch nicht geprüft.")
    table.insert(html, '      <div id="service-setup" class="inline-status" hidden>')
    add("button", {id="copy-service-setup", class="secondary compact"}, "Installation abschließen!")
    table.insert(html, '      </div>')
    table.insert(html, '    </section>')
    
    -- Stats section
    table.insert(html, '    <section aria-labelledby="stats-heading">')
    table.insert(html, '      <div class="section-title">')
    add("h2", {id="stats-heading"}, "LIVE-Information")
    add("span", {id="stats-live", class="live-indicator"}, "warte")
    table.insert(html, '      </div>')
    add("div", {id="live-stats", class="status-grid stats-grid"})
    add("p", {id="stats-status", class="inline-status"})
    table.insert(html, '    </section>')
    
    -- Page info section
    table.insert(html, '    <section id="page-info-section" aria-labelledby="page-info-heading">')
    table.insert(html, '      <div class="section-title">')
    add("h2", {id="page-info-heading"}, "PROFIL-Information")
    table.insert(html, '        <div class="title-actions">')
    add("span", {id="page-info-source", class="live-indicator"}, "Metadaten")
    add("button", {id="refresh-page-info", class="secondary compact", title="Refresh"}, "Refresh")
    add("button", {id="force-page-info", class="secondary compact danger-outline"}, "Force")
    table.insert(html, '        </div>')
    table.insert(html, '      </div>')
    add("div", {id="profile-info", class="profile-info", hidden=""})
    add("div", {id="summary-info", class="summary-info"})
    table.insert(html, '    </section>')
    
    -- Hook section
    table.insert(html, '    <section aria-labelledby="hook-heading">')
    table.insert(html, '      <div class="section-title header-controls">')
    add("h2", {id="hook-heading"}, "Connection")
    table.insert(html, '        <div class="title-actions">')
    add("button", {id="reset-tab", class="secondary compact danger-outline", title="Reset"}, "Reset")
    add("input", {id="hook-autostart", type="checkbox", ["aria-label"]="Hook dauerhaft", title="Hook dauerhaft: Off"})
    add("span", {class="status-led off", ["data-switch-status"]="hook-autostart", role="status"})
    table.insert(html, '        </div>')
    table.insert(html, '      </div>')
    table.insert(html, '      <div class="button-row">')
    add("button", {id="toggle-hook", class="primary", ["aria-label"]="Connection", ["aria-pressed"]="false"}, "On")
    add("button", {id="open-connection-settings", class="secondary compact settings-button", type="button", ["aria-label"]="Connection-Einstellungen öffnen", ["aria-haspopup"]="dialog"})
    add("button", {id="open-embed-live", class="secondary"}, "Embed")
    add("button", {id="open-normal-live", class="secondary"}, "Browser")
    add("button", {id="player-vlc-frame", class="secondary compact"}, "Player")
    table.insert(html, '      </div>')
    table.insert(html, '      <div class="connection-status"><span id="hook-led" class="status-led off" role="status" aria-label="Hook inaktiv" title="Hook inaktiv"></span><p id="hook-status" class="inline-status"></p></div>')
    add("p", {id="embed-startup-status", class="inline-status", role="status", ["aria-live"]="polite", hidden=""})
    add("button", {id="cancel-embed-startup", class="secondary", hidden=""}, "Embed-Start abbrechen")
    add("p", {id="hook-reconnect-status", class="inline-status", role="status"}, "Hook-Reconnect: aus")
    add("p", {id="player-recovery-status", class="inline-status", role="status"}, "Player-Recovery: aus")
    table.insert(html, '    </section>')
    
    -- Player section
    table.insert(html, '    <section aria-labelledby="player-heading">')
    table.insert(html, '      <div class="section-title header-controls">')
    add("h2", {id="player-heading"}, "Player")
    table.insert(html, '        <div class="title-actions">')
    add("button", {id="player-replay", class="secondary compact", title="Neu laden"}, "Neu laden")
    add("input", {id="limiter-enabled", type="checkbox", ["aria-label"]="Pegelschutz", title="Pegelschutz: Off"})
    add("span", {class="status-led off", ["data-switch-status"]="limiter-enabled", role="status"})
    table.insert(html, '        </div>')
    table.insert(html, '      </div>')
    add("div", {class="player-controls", role="group", ["aria-label"]="TikTok-Player steuern"})
    table.insert(html, '        <button id="player-play" class="secondary compact">Play</button>')
    table.insert(html, '        <button id="player-mute" class="secondary compact">Mute</button>')
    table.insert(html, '        <button id="player-pip" class="secondary compact">Bild-in-Bild</button>')
    table.insert(html, '        <button id="player-fullscreen" class="secondary compact">Vollbild</button>')
    table.insert(html, '        <button id="player-report" class="secondary compact danger-outline">Meldung</button>')
    table.insert(html, '      </div>')
    table.insert(html, '      <div class="audio-controls">')
    table.insert(html, '        <div class="control-label"><label for="player-volume">Lautstärke</label><output id="player-volume-output" for="player-volume">–</output></div>')
    add("input", {id="player-volume", type="range", min="0", max="100", step="1", value="100"})
    table.insert(html, '        <div class="audio-meter-row"><span>Spitzenpegel</span><strong id="player-peak">–</strong></div>')
    table.insert(html, '        <div class="control-label"><label for="limiter-strength">Schutzstärke</label><output id="limiter-strength-output" for="limiter-strength">30</output></div>')
    add("input", {id="limiter-strength", type="range", min="0", max="100", step="1", value="30"})
    table.insert(html, '      </div>')
    add("p", {id="multi-guest-status", class="inline-status"}, "Verbundene Streams: noch nicht erkannt.")
    add("p", {id="player-status", role="status", class="inline-status"}, "Warte auf den TikTok-Player.")
    add("span", {id="player-time", class="player-time", hidden=""}, "–")
    table.insert(html, '    </section>')
    
    -- Top chatters section
    table.insert(html, '    <section aria-labelledby="top-chatters-heading">')
    table.insert(html, '      <div class="section-title">')
    add("h2", {id="top-chatters-heading"}, "Top-Chatter")
    add("button", {id="open-audience", class="secondary compact"}, "Zuschauer*innen")
    table.insert(html, '      </div>')
    add("p", {id="team-tag-status", class="inline-status"}, "Teamkürzel: noch nicht erkannt.")
    add("div", {id="top-chatters", class="top-chatters empty"}, "Noch keine Personen im Chat beobachtet.")
    table.insert(html, '      <div id="top-chatters-actions" class="top-chatters-actions" hidden>')
    add("button", {id="top-chatters-reset", class="top-chatter-link", type="button", hidden=""}, "Reset")
    add("button", {id="top-chatters-more", class="top-chatter-link", type="button"}, "mehr…")
    table.insert(html, '      </div>')
    table.insert(html, '    </section>')
    
    -- Recommendations section
    table.insert(html, '    <section id="recommendations-section" aria-labelledby="recommendations-heading">')
    table.insert(html, '      <div class="section-title">')
    add("h2", {id="recommendations-heading"}, "LIVE-Empfehlungen")
    add("span", {id="recommendation-status", class="live-indicator"}, "bereit")
    table.insert(html, '      </div>')
    table.insert(html, '      <div class="recommendation-controls">')
    table.insert(html, '        <label><span>Anzahl</span><input id="recommendation-limit" type="number" min="1" max="300" step="1" value="20" inputmode="numeric"></label>')
    table.insert(html, '        <label><span>Sortierung</span><select id="recommendation-sort"><option value="tiktok">TikTok-Reihenfolge</option><option value="viewers">Zuschauer*innen</option></select></label>')
    table.insert(html, '      </div>')
    table.insert(html, '      <div class="button-row">')
    add("button", {id="scan-recommendations", class="primary"}, "Empfehlungen scannen")
    add("button", {id="cancel-recommendations", class="secondary", hidden=""}, "Abbrechen")
    table.insert(html, '      </div>')
    add("p", {id="recommendation-progress", class="inline-status", ["aria-live"]="polite"}, "Noch kein Scan gestartet.")
    add("div", {id="recommendation-list", class="recommendation-list empty"}, "Noch keine Empfehlungen erfasst.")
    table.insert(html, '      <div id="recommendation-actions" class="top-chatters-actions" hidden>')
    add("button", {id="recommendation-more", class="top-chatter-link", type="button"}, "mehr…")
    table.insert(html, '      </div>')
    table.insert(html, '    </section>')
    
    -- Caption section
    table.insert(html, '    <section aria-labelledby="caption-heading">')
    table.insert(html, '      <div class="section-title">')
    add("h2", {id="caption-heading"}, "Titel")
    add("button", {id="scan", class="secondary"}, "Status")
    table.insert(html, '      </div>')
    add("div", {id="caption-status", class="status-grid"})
    add("button", {id="enable-captions", class="primary"}, "Untertitel")
    add("p", {id="caption-action-status", role="status", class="inline-status action-status"})
    table.insert(html, '    </section>')
    
    -- Song section
    table.insert(html, '    <section aria-labelledby="song-heading">')
    table.insert(html, '      <div class="section-title header-controls">')
    add("h2", {id="song-heading"}, "Songs")
    table.insert(html, '        <div class="title-actions">')
    add("input", {id="song-enabled", type="checkbox", ["aria-label"]="Songerkennung", title="Songerkennung: Off"})
    add("span", {id="song-led", class="status-led off", ["data-switch-status"]="song-enabled", role="status", ["aria-label"]="Songerkennung inaktiv"})
    table.insert(html, '        </div>')
    table.insert(html, '      </div>')
    add("button", {id="recognize-song", class="primary", disabled=""}, "Jetzt erkennen")
    add("p", {id="song-status", class="inline-status"})
    add("div", {id="song-result", class="song-result", hidden=""})
    table.insert(html, '    </section>')
    
    -- Links section
    table.insert(html, '    <section aria-labelledby="links-heading">')
    table.insert(html, '      <div class="section-title">')
    add("h2", {id="links-heading"}, "HAR-Logs")
    add("span", {id="media-count", class="count"}, "0")
    table.insert(html, '      </div>')
    add("div", {id="media-list", class="list empty"}, "Noch keine FLV-/HLS-Links erkannt.")
    table.insert(html, '    </section>')
    
    -- Log section
    table.insert(html, '    <section aria-labelledby="log-heading">')
    table.insert(html, '      <div class="section-title header-controls">')
    add("h2", {id="log-heading"}, "LIVE-Logs")
    table.insert(html, '        <div class="title-actions">')
    add("span", {class="status-led off", ["data-counter-status"]="caption-count", role="status"})
    add("span", {id="caption-count", class="count"}, "0")
    add("button", {id="clear", class="ghost compact", title="Reset"}, "Reset")
    add("input", {id="live-logs-enabled", type="checkbox", ["aria-label"]="LIVE-Logs", title="LIVE-Logs: Off"})
    add("span", {class="status-led off", ["data-switch-status"]="live-logs-enabled", role="status", ["aria-label"]="LIVE-Logs: deaktiviert"})
    table.insert(html, '        </div>')
    table.insert(html, '      </div>')
    table.insert(html, '      <div class="button-row">')
    add("button", {id="export-log", class="secondary"}, "JSON-L-Export")
    add("button", {id="export-caption-raw", class="secondary"}, "RAW-JSON-Export")
    table.insert(html, '      </div>')
    add("div", {id="caption-list", class="list empty"}, "Noch keine CaptionMessages empfangen.")
    table.insert(html, '    </section>')
    
    -- Debug section
    table.insert(html, '    <section aria-labelledby="debug-heading">')
    table.insert(html, '      <div class="section-title header-controls">')
    add("h2", {id="debug-heading"}, "Debugmodus")
    table.insert(html, '        <div class="title-actions">')
    add("span", {class="status-led off", ["data-counter-status"]="debug-count", role="status"})
    add("span", {id="debug-count", class="count"}, "0")
    add("button", {id="clear-debug", class="ghost compact", title="Reset"}, "Reset")
    add("input", {id="debug-enabled", type="checkbox", ["aria-label"]="Diagnoseereignisse für diesen Tab protokollieren", title="Diagnoseereignisse für diesen Tab protokollieren: Off"})
    add("span", {class="status-led off", ["data-switch-status"]="debug-enabled", role="status"})
    table.insert(html, '        </div>')
    table.insert(html, '      </div>')
    table.insert(html, '      <div class="button-row">')
    add("button", {id="export-debug", class="secondary"}, "Debug exportieren")
    table.insert(html, '      </div>')
    table.insert(html, '      <p class="muted small"></p>')
    table.insert(html, '    </section>')
    
    -- Audience modal
    table.insert(html, '    <div id="audience-modal" class="modal-backdrop" hidden>')
    table.insert(html, '      <section class="modal" role="dialog" aria-modal="true" aria-labelledby="audience-heading">')
    table.insert(html, '        <div class="section-title">')
    add("h2", {id="audience-heading"}, "Im Chat beobachtete Personen")
    add("button", {id="close-audience", class="secondary compact", ["aria-label"]="Übersicht schließen"}, "Schließen")
    table.insert(html, '        </div>')
    add("p", {id="audience-limit", class="inline-status"})
    add("div", {id="audience-list", class="audience-list"})
    table.insert(html, '      </section>')
    table.insert(html, '    </div>')
    
    -- Speech settings modal
    table.insert(html, '    <div id="speech-settings-modal" class="modal-backdrop" hidden>')
    table.insert(html, '      <section class="modal" role="dialog" aria-modal="true" aria-labelledby="speech-settings-heading">')
    table.insert(html, '        <div class="section-title">')
    add("h2", {id="speech-settings-heading"}, "Erweiterte Einstellungen")
    add("button", {id="close-speech-settings", class="secondary compact", ["aria-label"]="Einstellungen schließen"}, "Schließen")
    table.insert(html, '        </div>')
    table.insert(html, '        <div class="settings-grid speech-integration-settings">')
    table.insert(html, '<label class="icon-style-setting"><span>Icon-Stil</span><select id="icon-style"><option value="plastisch">3D / Plastisch</option><option value="glass">Glass / Realistisch</option><option value="linear">Minimal / Linear</option></select></label>')
    table.insert(html, '          <label><span>Sprache</span><select id="speech-language"><option value="auto">Auto</option><option value="de-DE">Deutsch</option><option value="en-US">Englisch</option><option value="ru-RU">Russisch</option><option value="uk-UA">Ukrainisch</option><option value="bg-BG">Bulgarisch</option><option value="sr-RS">Serbisch</option><option value="kk-KZ">Kasachisch</option><option value="zh-CN">Chinesisch</option><option value="ja-JP">Japanisch</option><option value="ko-KR">Koreanisch</option><option value="ar-JO">Arabisch</option><option value="fa-IR">Persisch</option><option value="ur-PK">Urdu</option><option value="hi-IN">Hindi</option><option value="ne-NP">Nepali</option><option value="ml-IN">Malayalam</option></select></label>')
    table.insert(html, '          <label><span>Stimme</span><select id="speech-voice"><option value="">Standard</option></select></label>')
    table.insert(html, '          <label id="audd-token-setting"><span id="audd-token-label">AudD API-Token (optional - <a href="https://audd.io/" target="_blank" rel="noopener noreferrer">https://AudD.io</a> Trial/Paid)</span><input id="audd-token" type="password" autocomplete="off" spellcheck="false"></label>')
    table.insert(html, '          <label id="pairing-code-setting"><span>Pairing-Code</span><input id="pairing-code" type="password" autocomplete="off" spellcheck="false"></label>')
    table.insert(html, '          <label><span>Universal API-Key</span><input id="universal-caption-api-key" type="password" autocomplete="off" spellcheck="false"></label>')
    table.insert(html, '        </div>')
    table.insert(html, '        <label class="option-row"><input id="speak-names" type="checkbox" checked> Chatnamen sprechen</label>')
    table.insert(html, '        <label class="option-row"><input id="shorten-names" type="checkbox"> Chatnamen kürzen</label>')
    table.insert(html, '        <label class="option-row auto-chat-refresh"><input id="auto-chat-refresh" type="checkbox"> Auto-Chat Refresh <input id="auto-chat-refresh-minutes" type="number" min="1" max="60" step="1" value="5" inputmode="numeric" aria-label="Auto-Chat-Refresh in Minuten"><span>min.</span></label>')
    table.insert(html, '        <label class="option-row"><input id="game-mode" type="checkbox"> Game-Mode (Spam-, Emoji, usw. Chatfilter)</label>')
    table.insert(html, '        <div class="option-row external-speech-trigger-row"><label><input id="filter-external-speech-triggers" type="checkbox"> Trigger filtern (ext. Sprachdienste)</label><input id="external-speech-trigger-characters" type="text" value="." maxlength="10" aria-label="Triggerzeichen, maximal fünf Sonderzeichen" autocomplete="off" spellcheck="false"></div>')
    table.insert(html, '        <label class="option-row"><input id="keep-speech-active" type="checkbox" aria-label="Vorlesen dauerhaft" title="Vorlesen dauerhaft: Off"> Vorlesen dauerhaft</label>')
    table.insert(html, '      </section>')
    table.insert(html, '    </div>')
    
    -- Chat history modal
    table.insert(html, '    <div id="chat-history-modal" class="modal-backdrop" hidden>')
    table.insert(html, '      <section class="modal" role="dialog" aria-modal="true" aria-labelledby="chat-history-heading">')
    table.insert(html, '        <div class="section-title">')
    add("h2", {id="chat-history-heading"}, "Gesammelte Chatnachrichten")
    add("button", {id="close-chat-history", class="secondary compact", ["aria-label"]="Chatzeilen schließen"}, "Schließen")
    table.insert(html, '        </div>')
    add("p", {id="chat-history-limit", class="inline-status"})
    add("div", {id="chat-history-list", class="chat-history-list"})
    table.insert(html, '      </section>')
    table.insert(html, '    </div>')
    
    -- Recommendation modal
    table.insert(html, '    <div id="recommendation-modal" class="modal-backdrop" hidden>')
    table.insert(html, '      <section class="modal" role="dialog" aria-modal="true" aria-labelledby="recommendation-modal-heading">')
    table.insert(html, '        <div class="section-title">')
    add("h2", {id="recommendation-modal-heading"}, "Gescannte LIVE-Empfehlungen")
    add("button", {id="close-recommendations", class="secondary compact", ["aria-label"]="Empfehlungen schließen"}, "Schließen")
    table.insert(html, '        </div>')
    add("div", {id="recommendation-modal-list", class="recommendation-list"})
    table.insert(html, '      </section>')
    table.insert(html, '    </div>')
    
    -- Notice
    add("p", {id="notice", role="alert", class="notice"})
    
    table.insert(html, '  </main>')
    
    -- Connection settings modal
    table.insert(html, '  <div id="connection-settings-modal" class="modal-backdrop" hidden>')
    table.insert(html, '    <section class="modal" role="dialog" aria-modal="true" aria-labelledby="connection-settings-heading">')
    table.insert(html, '      <div class="section-title"><h2 id="connection-settings-heading">Connection-Einstellungen</h2><button id="close-connection-settings" class="secondary compact">Schließen</button></div>')
    table.insert(html, '      <label class="option-row quick-recover-setting"><input id="hook-reconnect" type="checkbox"> Hook-Reconnect <input id="hook-reconnect-seconds" type="number" min="1" max="59" step="1" value="3" inputmode="numeric" aria-label="Hook-Reconnect-Wartezeit in Sekunden"><span>Sek.</span></label>')
    table.insert(html, '      <label class="option-row quick-recover-setting"><input id="quick-recover" type="checkbox"> Player-Recovery <input id="quick-recover-seconds" type="number" min="1" max="59" step="1" value="3" inputmode="numeric" aria-label="Player-Recovery-Bestätigungszeit in Sekunden"><span>Sek.</span></label>')
    table.insert(html, '    </section>')
    table.insert(html, '  </div>')
    
    -- Scripts
    table.insert(html, '  <script src="content-core.js"></script>')
    table.insert(html, '  <script src="sidepanel.js"></script>')
    table.insert(html, '  <script src="icon-controls.js"></script>')
    
    -- Body and HTML closing tags
    table.insert(html, '</body>')
    table.insert(html, '</html>')
    
    return table.concat(html, "\n")
end

-- Main execution
local output_file = arg[1] or "sidepanel.html"
local file = io.open(output_file, "w")
if not file then
    print("Error: Could not open file " .. output_file .. " for writing")
    os.exit(1)
end

file:write(create_html_document())
file:close()

print("HTML document created successfully: " .. output_file)
