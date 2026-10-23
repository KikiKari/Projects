#!/usr/bin/env tclsh
# sidepanel.html — portiert nach tcl
# Quelle: html, Projects@TikTok-Live-Companion:plugin-source/browser-extension/sidepanel.html
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/sidepanel.html
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/sidepanel.html
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/browser-extension/sidepanel.html
# Erzeugt: 2026-10-23 durch ABSTRACTIONS_MANAGER.py

# Generate sidepanel.html from Tcl script
# Usage: tclsh sidepanel.tcl output_file

proc generate_sidepanel {filename} {
    set fp [open $filename w]
    
    puts $fp {<!doctype html>}
    puts $fp {<html lang="de">}
    puts $fp {<head>}
    puts $fp {  <meta charset="utf-8">}
    puts $fp {  <meta name="viewport" content="width=device-width, initial-scale=1">}
    puts $fp {  <title>TikTok LIVE Companion</title>}
    puts $fp {  <link rel="stylesheet" href="sidepanel.css">}
    puts $fp {  <link rel="stylesheet" href="icon-controls.css">}
    puts $fp {</head>}
    puts $fp {<body>}
    puts $fp {  <header>}
    puts $fp {    <p id="page-title" class="muted">Kein TikTok-Tab ausgewählt</p>}
    puts $fp {  </header>}
    puts $fp {}
    puts $fp {  <main>}
    puts $fp {    <section aria-labelledby="chat-heading">}
    puts $fp {      <div class="section-title">}
    puts $fp {        <h2 id="chat-heading">Chat</h2>}
    puts $fp {        <div class="title-actions">}
    puts $fp {          <span id="chat-led" class="status-led off" role="status" aria-label="Chat inaktiv" title="Chat inaktiv"></span>}
    puts $fp {          <button id="chat-count" class="count count-button" type="button" aria-haspopup="dialog" title="Gesammelte Chatzeilen öffnen">0</button>}
    puts $fp {          <button id="refresh-chat" class="secondary compact" title="Chatanzeige leeren">Reset</button>}
    puts $fp {          <button id="toggle-speech" class="secondary compact" aria-pressed="false" aria-label="Vorlesen">On</button>}
    puts $fp {          <span id="speech-led" class="status-led off" role="status" aria-label="Vorlesen inaktiv" title="Vorlesen inaktiv"></span>}
    puts $fp {        </div>}
    puts $fp {      </div>}
    puts $fp {      <div id="chat-list" class="chat-list empty" role="log" aria-live="polite" aria-relevant="additions" aria-label="Die letzten fünf bereinigten Chatnachrichten">Noch keine Chatnachrichten erkannt.</div>}
    puts $fp {      <p id="speech-status" role="status" class="inline-status">Vorlesen ist ausgeschaltet.</p>}
    puts $fp {      <div class="control-label"><label for="speech-volume">Vorleselautstärke</label><output id="speech-volume-output" for="speech-volume">100%</output></div>}
    puts $fp {      <input id="speech-volume" type="range" min="0" max="100" step="5" value="50">}
    puts $fp {      <div class="button-row">}
    puts $fp {        <button id="service-action" class="secondary">Sprachdienst</button>}
    puts $fp {        <button id="sherpa-action" class="secondary">Sherpa</button>}
    puts $fp {        <button id="open-speech-settings" class="secondary compact settings-button" type="button" aria-label="Erweiterte Einstellungen öffnen" aria-haspopup="dialog" title="Einstellungen"></button>}
    puts $fp {      </div>}
    puts $fp {      <p id="service-status" class="inline-status">Lokaler Sprachdienst noch nicht geprüft.</p>}
    puts $fp {      <div id="service-setup" class="inline-status" hidden>}
    puts $fp {        <button id="copy-service-setup" class="secondary compact">Installation abschließen!</button>}
    puts $fp {      </div>}
    puts $fp {    </section>}
    puts $fp {}
    puts $fp {    <section aria-labelledby="stats-heading">}
    puts $fp {      <div class="section-title">}
    puts $fp {        <h2 id="stats-heading">LIVE-Information</h2>}
    puts $fp {        <span id="stats-live" class="live-indicator">warte</span>}
    puts $fp {      </div>}
    puts $fp {      <div id="live-stats" class="status-grid stats-grid"></div>}
    puts $fp {      <p id="stats-status" class="inline-status"></p>}
    puts $fp {    </section>}
    puts $fp {}
    puts $fp {    <section id="page-info-section" aria-labelledby="page-info-heading">}
    puts $fp {      <div class="section-title">}
    puts $fp {        <h2 id="page-info-heading">PROFIL-Information</h2>}
    puts $fp {        <div class="title-actions">}
    puts $fp {          <span id="page-info-source" class="live-indicator">Metadaten</span>}
    puts $fp {          <button id="refresh-page-info" class="secondary compact" title="Refresh">Refresh</button>}
    puts $fp {          <button id="force-page-info" class="secondary compact danger-outline">Force</button>}
    puts $fp {        </div>}
    puts $fp {      </div>}
    puts $fp {      <div id="profile-info" class="profile-info" hidden></div>}
    puts $fp {      <div id="summary-info" class="summary-info"></div>}
    puts $fp {    </section>}
    puts $fp {}
    puts $fp {    <section aria-labelledby="hook-heading">}
    puts $fp {      <div class="section-title header-controls">}
    puts $fp {        <h2 id="hook-heading">Connection</h2>}
    puts $fp {        <div class="title-actions">}
    puts $fp {          <button id="reset-tab" class="secondary compact danger-outline" title="Reset">Reset</button>}
    puts $fp {          <input id="hook-autostart" type="checkbox" aria-label="Hook dauerhaft" title="Hook dauerhaft: Off">}
    puts $fp {          <span class="status-led off" data-switch-status="hook-autostart" role="status"></span>}
    puts $fp {        </div>}
    puts $fp {      </div>}
    puts $fp {      <div class="button-row">}
    puts $fp {        <button id="toggle-hook" class="primary" aria-label="Connection" aria-pressed="false">On</button>}
    puts $fp {        <button id="open-connection-settings" class="secondary compact settings-button" type="button" aria-label="Connection-Einstellungen öffnen" aria-haspopup="dialog"></button>}
    puts $fp {        <button id="open-embed-live" class="secondary">Embed</button>}
    puts $fp {        <button id="open-normal-live" class="secondary">Browser</button>}
    puts $fp {        <button id="player-vlc-frame" class="secondary compact">Player</button>}
    puts $fp {      </div>}
    puts $fp {      <div class="connection-status"><span id="hook-led" class="status-led off" role="status" aria-label="Hook inaktiv" title="Hook inaktiv"></span><p id="hook-status" class="inline-status"></p></div>}
    puts $fp {      <p id="embed-startup-status" class="inline-status" role="status" aria-live="polite" hidden></p>}
    puts $fp {      <button id="cancel-embed-startup" class="secondary" hidden>Embed-Start abbrechen</button>}
    puts $fp {      <p id="hook-reconnect-status" class="inline-status" role="status">Hook-Reconnect: aus</p>}
    puts $fp {      <p id="player-recovery-status" class="inline-status" role="status">Player-Recovery: aus</p>}
    puts $fp {    </section>}
    puts $fp {}
    puts $fp {    <section aria-labelledby="player-heading">}
    puts $fp {      <div class="section-title header-controls">}
    puts $fp {        <h2 id="player-heading">Player</h2>}
    puts $fp {        <div class="title-actions">}
    puts $fp {          <button id="player-replay" class="secondary compact" title="Neu laden">Neu laden</button>}
    puts $fp {          <input id="limiter-enabled" type="checkbox" aria-label="Pegelschutz" title="Pegelschutz: Off">}
    puts $fp {          <span class="status-led off" data-switch-status="limiter-enabled" role="status"></span>}
    puts $fp {        </div>}
    puts $fp {      </div>}
    puts $fp {      <div class="player-controls" role="group" aria-label="TikTok-Player steuern">}
    puts $fp {        <button id="player-play" class="secondary compact">Play</button>}
    puts $fp {        <button id="player-mute" class="secondary compact">Mute</button>}
    puts $fp {        <button id="player-pip" class="secondary compact">Bild-in-Bild</button>}
    puts $fp {        <button id="player-fullscreen" class="secondary compact">Vollbild</button>}
    puts $fp {        <button id="player-report" class="secondary compact danger-outline">Meldung</button>}
    puts $fp {      </div>}
    puts $fp {      <div class="audio-controls">}
    puts $fp {        <div class="control-label"><label for="player-volume">Lautstärke</label><output id="player-volume-output" for="player-volume">–</output></div>}
    puts $fp {        <input id="player-volume" type="range" min="0" max="100" step="1" value="100">}
    puts $fp {        <div class="audio-meter-row"><span>Spitzenpegel</span><strong id="player-peak">–</strong></div>}
    puts $fp {        <div class="control-label"><label for="limiter-strength">Schutzstärke</label><output id="limiter-strength-output" for="limiter-strength">30</output></div>}
    puts $fp {        <input id="limiter-strength" type="range" min="0" max="100" step="1" value="30">}
    puts $fp {      </div>}
    puts $fp {      <p id="multi-guest-status" class="inline-status">Verbundene Streams: noch nicht erkannt.</p>}
    puts $fp {      <p id="player-status" role="status" class="inline-status">Warte auf den TikTok-Player.</p>}
    puts $fp {      <span id="player-time" class="player-time" hidden>–</span>}
    puts $fp {    </section>}
    puts $fp {}
    puts $fp {    <section aria-labelledby="top-chatters-heading">}
    puts $fp {      <div class="section-title">}
    puts $fp {        <h2 id="top-chatters-heading">Top-Chatter</h2>}
    puts $fp {        <button id="open-audience" class="secondary compact">Zuschauer*innen</button>}
    puts $fp {      </div>}
    puts $fp {      <p id="team-tag-status" class="inline-status">Teamkürzel: noch nicht erkannt.</p>}
    puts $fp {      <div id="top-chatters" class="top-chatters empty">Noch keine Personen im Chat beobachtet.</div>}
    puts $fp {      <div id="top-chatters-actions" class="top-chatters-actions" hidden>}
    puts $fp {        <button id="top-chatters-reset" class="top-chatter-link" type="button" hidden>Reset</button>}
    puts $fp {        <button id="top-chatters-more" class="top-chatter-link" type="button">mehr…</button>}
    puts $fp {      </div>}
    puts $fp {    </section>}
    puts $fp {}
    puts $fp {    <section id="recommendations-section" aria-labelledby="recommendations-heading">}
    puts $fp {      <div class="section-title">}
    puts $fp {        <h2 id="recommendations-heading">LIVE-Empfehlungen</h2>}
    puts $fp {        <span id="recommendation-status" class="live-indicator">bereit</span>}
    puts $fp {      </div>}
    puts $fp {      <div class="recommendation-controls">}
    puts $fp {        <label><span>Anzahl</span><input id="recommendation-limit" type="number" min="1" max="300" step="1" value="20" inputmode="numeric"></label>}
    puts $fp {        <label><span>Sortierung</span><select id="recommendation-sort"><option value="tiktok">TikTok-Reihenfolge</option><option value="viewers">Zuschauer*innen</option></select></label>}
    puts $fp {      </div>}
    puts $fp {      <div class="button-row">}
    puts $fp {        <button id="scan-recommendations" class="primary">Empfehlungen scannen</button>}
    puts $fp {        <button id="cancel-recommendations" class="secondary" hidden>Abbrechen</button>}
    puts $fp {      </div>}
    puts $fp {      <p id="recommendation-progress" class="inline-status" aria-live="polite">Noch kein Scan gestartet.</p>}
    puts $fp {      <div id="recommendation-list" class="recommendation-list empty">Noch keine Empfehlungen erfasst.</div>}
    puts $fp {      <div id="recommendation-actions" class="top-chatters-actions" hidden>}
    puts $fp {        <button id="recommendation-more" class="top-chatter-link" type="button">mehr…</button>}
    puts $fp {      </div>}
    puts $fp {    </section>}
    puts $fp {}
    puts $fp {    <section aria-labelledby="caption-heading">}
    puts $fp {      <div class="section-title">}
    puts $fp {        <h2 id="caption-heading">Titel</h2>}
    puts $fp {        <button id="scan" class="secondary">Status</button>}
    puts $fp {      </div>}
    puts $fp {      <div id="caption-status" class="status-grid"></div>}
    puts $fp {      <button id="enable-captions" class="primary">Untertitel</button>}
    puts $fp {      <p id="caption-action-status" role="status" class="inline-status action-status"></p>}
    puts $fp {    </section>}
    puts $fp {}
    puts $fp {    <section aria-labelledby="song-heading">}
    puts $fp {      <div class="section-title header-controls">}
    puts $fp {        <h2 id="song-heading">Songs</h2>}
    puts $fp {        <div class="title-actions">}
    puts $fp {          <input id="song-enabled" type="checkbox" aria-label="Songerkennung" title="Songerkennung: Off">}
    puts $fp {          <span id="song-led" class="status-led off" data-switch-status="song-enabled" role="status" aria-label="Songerkennung inaktiv"></span>}
    puts $fp {        </div>}
    puts $fp {      </div>}
    puts $fp {      <button id="recognize-song" class="primary" disabled>Jetzt erkennen</button>}
    puts $fp {      <p id="song-status" class="inline-status"></p>}
    puts $fp {      <div id="song-result" class="song-result" hidden></div>}
    puts $fp {    </section>}
    puts $fp {}
    puts $fp {    <section aria-labelledby="links-heading">}
    puts $fp {      <div class="section-title">}
    puts $fp {        <h2 id="links-heading">HAR-Logs</h2>}
    puts $fp {        <span id="media-count" class="count">0</span>}
    puts $fp {      </div>}
    puts $fp {      <div id="media-list" class="list empty">Noch keine FLV-/HLS-Links erkannt.</div>}
    puts $fp {    </section>}
    puts $fp {}
    puts $fp {    <section aria-labelledby="log-heading">}
    puts $fp {      <div class="section-title header-controls">}
    puts $fp {        <h2 id="log-heading">LIVE-Logs</h2>}
    puts $fp {        <div class="title-actions">}
    puts $fp {          <span class="status-led off" data-counter-status="caption-count" role="status"></span>}
    puts $fp {          <span id="caption-count" class="count">0</span>}
    puts $fp {          <button id="clear" class="ghost compact" title="Reset">Reset</button>}
    puts $fp {          <input id="live-logs-enabled" type="checkbox" aria-label="LIVE-Logs" title="LIVE-Logs: Off">}
    puts $fp {          <span class="status-led off" data-switch-status="live-logs-enabled" role="status" aria-label="LIVE-Logs: deaktiviert"></span>}
    puts $fp {        </div>}
    puts $fp {      </div>}
    puts $fp {      <div class="button-row">}
    puts $fp {        <button id="export-log" class="secondary">JSON-L-Export</button>}
    puts $fp {        <button id="export-caption-raw" class="secondary">RAW-JSON-Export</button>}
    puts $fp {      </div>}
    puts $fp {      <div id="caption-list" class="list empty">Noch keine CaptionMessages empfangen.</div>}
    puts $fp {    </section>}
    puts $fp {}
    puts $fp {    <section aria-labelledby="debug-heading">}
    puts $fp {      <div class="section-title header-controls">}
    puts $fp {        <h2 id="debug-heading">Debugmodus</h2>}
    puts $fp {        <div class="title-actions">}
    puts $fp {          <span class="status-led off" data-counter-status="debug-count" role="status"></span>}
    puts $fp {          <span id="debug-count" class="count">0</span>}
    puts $fp {          <button id="clear-debug" class="ghost compact" title="Reset">Reset</button>}
    puts $fp {          <input id="debug-enabled" type="checkbox" aria-label="Diagnoseereignisse für diesen Tab protokollieren" title="Diagnoseereignisse für diesen Tab protokollieren: Off">}
    puts $fp {          <span class="status-led off" data-switch-status="debug-enabled" role="status"></span>}
    puts $fp {        </div>}
    puts $fp {      </div>}
    puts $fp {      <div class="button-row">}
    puts $fp {        <button id="export-debug" class="secondary">Debug exportieren</button>}
    puts $fp {      </div>}
    puts $fp {      <p class="muted small"></p>}
    puts $fp {    </section>}
    puts $fp {}
    puts $fp {    <div id="audience-modal" class="modal-backdrop" hidden>}
    puts $fp {      <section class="modal" role="dialog" aria-modal="true" aria-labelledby="audience-heading">}
    puts $fp {        <div class="section-title">}
    puts $fp {          <h2 id="audience-heading">Im Chat beobachtete Personen</h2>}
    puts $fp {          <button id="close-audience" class="secondary compact" aria-label="Übersicht schließen">Schließen</button>}
    puts $fp {        </div>}
    puts $fp {        <p id="audience-limit" class="inline-status"></p>}
    puts $fp {        <div id="audience-list" class="audience-list"></div>}
    puts $fp {      </section>}
    puts $fp {    </div>}
    puts $fp {}
    puts $fp {    <div id="speech-settings-modal" class="modal-backdrop" hidden>}
    puts $fp {      <section class="modal" role="dialog" aria-modal="true" aria-labelledby="speech-settings-heading">}
    puts $fp {        <div class="section-title">}
    puts $fp {          <h2 id="speech-settings-heading">Erweiterte Einstellungen</h2>}
    puts $fp {          <button id="close-speech-settings" class="secondary compact" aria-label="Einstellungen schließen">Schließen</button>}
    puts $fp {        </div>}
    puts $fp {        <div class="settings-grid speech-integration-settings">}
    puts $fp {<label class="icon-style-setting"><span>Icon-Stil</span><select id="icon-style"><option value="plastisch">3D / Plastisch</option><option value="glass">Glass / Realistisch</option><option value="linear">Minimal / Linear</option></select></label>}
    puts $fp {          <label><span>Sprache</span><select id="speech-language"><option value="auto">Auto</option><option value="de-DE">Deutsch</option><option value="en-US">Englisch</option><option value="ru-RU">Russisch</option><option value="uk-UA">Ukrainisch</option><option value="bg-BG">Bulgarisch</option><option value="sr-RS">Serbisch</option><option value="kk-KZ">Kasachisch</option><option value="zh-CN">Chinesisch</option><option value="ja-JP">Japanisch</option><option value="ko-KR">Koreanisch</option><option value="ar-JO">Arabisch</option><option value="fa-IR">Persisch</option><option value="ur-PK">Urdu</option><option value="hi-IN">Hindi</option><option value="ne-NP">Nepali</option><option value="ml-IN">Malayalam</option></select></label>}
    puts $fp {          <label><span>Stimme</span><select id="speech-voice"><option value="">Standard</option></select></label>}
    puts $fp {          <label id="audd-token-setting"><span id="audd-token-label">AudD API-Token (optional - <a href="https://audd.io/" target="_blank" rel="noopener noreferrer">https://AudD.io</a> Trial/Paid)</span><input id="audd-token" type="password" autocomplete="off" spellcheck="false"></label>}
    puts $fp {          <label id="pairing-code-setting"><span>Pairing-Code</span><input id="pairing-code" type="password" autocomplete="off" spellcheck="false"></label>}
    puts $fp {          <label><span>Universal API-Key</span><input id="universal-caption-api-key" type="password" autocomplete="off" spellcheck="false"></label>}
    puts $fp {        </div>}
    puts $fp {        <label class="option-row"><input id="speak-names" type="checkbox" checked> Chatnamen sprechen</label>}
    puts $fp {        <label class="option-row"><input id="shorten-names" type="checkbox"> Chatnamen kürzen</label>}
    puts $fp {        <label class="option-row auto-chat-refresh"><input id="auto-chat-refresh" type="checkbox"> Auto-Chat Refresh <input id="auto-chat-refresh-minutes" type="number" min="1" max="60" step="1" value="5" inputmode="numeric" aria-label="Auto-Chat-Refresh in Minuten"><span>min.</span></label>}
    puts $fp {        <label class="option-row"><input id="game-mode" type="checkbox"> Game-Mode (Spam-, Emoji, usw. Chatfilter)</label>}
    puts $fp {        <div class="option-row external-speech-trigger-row"><label><input id="filter-external-speech-triggers" type="checkbox"> Trigger filtern (ext. Sprachdienste)</label><input id="external-speech-trigger-characters" type="text" value="." maxlength="10" aria-label="Triggerzeichen, maximal fünf Sonderzeichen" autocomplete="off" spellcheck="false"></div>}
    puts $fp {        <label class="option-row"><input id="keep-speech-active" type="checkbox" aria-label="Vorlesen dauerhaft" title="Vorlesen dauerhaft: Off"> Vorlesen dauerhaft</label>}
    puts $fp {      </section>}
    puts $fp {    </div>}
    puts $fp {}
    puts $fp {    <div id="chat-history-modal" class="modal-backdrop" hidden>}
    puts $fp {      <section class="modal" role="dialog" aria-modal="true" aria-labelledby="chat-history-heading">}
    puts $fp {        <div class="section-title">}
    puts $fp {          <h2 id="chat-history-heading">Gesammelte Chatnachrichten</h2>}
    puts $fp {          <button id="close-chat-history" class="secondary compact" aria-label="Chatzeilen schließen">Schließen</button>}
    puts $fp {        </div>}
    puts $fp {        <p id="chat-history-limit" class="inline-status"></p>}
    puts $fp {        <div id="chat-history-list" class="chat-history-list"></div>}
    puts $fp {      </section>}
    puts $fp {    </div>}
    puts $fp {}
    puts $fp {    <div id="recommendation-modal" class="modal-backdrop" hidden>}
    puts $fp {      <section class="modal" role="dialog" aria-modal="true" aria-labelledby="recommendation-modal-heading">}
    puts $fp {        <div class="section-title">}
    puts $fp {          <h2 id="recommendation-modal-heading">Gescannte LIVE-Empfehlungen</h2>}
    puts $fp {          <button id="close-recommendations" class="secondary compact" aria-label="Empfehlungen schließen">Schließen</button>}
    puts $fp {        </div>}
    puts $fp {        <div id="recommendation-modal-list" class="recommendation-list"></div>}
    puts $fp {      </section>}
    puts $fp {    </div>}
    puts $fp {}
    puts $fp {    <p id="notice" role="alert" class="notice"></p>}
    puts $fp {  </main>}
    puts $fp {  <div id="connection-settings-modal" class="modal-backdrop" hidden>}
    puts $fp {    <section class="modal" role="dialog" aria-modal="true" aria-labelledby="connection-settings-heading">}
    puts $fp {      <div class="section-title"><h2 id="connection-settings-heading">Connection-Einstellungen</h2><button id="close-connection-settings" class="secondary compact">Schließen</button></div>}
    puts $fp {      <label class="option-row quick-recover-setting"><input id="hook-reconnect" type="checkbox"> Hook-Reconnect <input id="hook-reconnect-seconds" type="number" min="1" max="59" step="1" value="3" inputmode="numeric" aria-label="Hook-Reconnect-Wartezeit in Sekunden"><span>Sek.</span></label>}
    puts $fp {      <label class="option-row quick-recover-setting"><input id="quick-recover" type="checkbox"> Player-Recovery <input id="quick-recover-seconds" type="number" min="1" max="59" step="1" value="3" inputmode="numeric" aria-label="Player-Recovery-Bestätigungszeit in Sekunden"><span>Sek.</span></label>}
    puts $fp {    </section>}
    puts $fp {  </div>}
    puts $fp {}
    puts $fp {}
    puts $fp {  <script src="content-core.js"></script>}
    puts $fp {  <script src="sidepanel.js"></script>}
    puts $fp {  <script src="icon-controls.js"></script>}
    puts $fp {</body>}
    puts $fp {</html>}
    
    close $fp
}

# Main execution
if {$argc != 1} {
    puts stderr "Usage: [info script] output_file"
    exit 1
}

generate_sidepanel [lindex $argv 0]
