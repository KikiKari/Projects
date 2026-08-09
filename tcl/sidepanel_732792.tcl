#!/usr/bin/env tclsh
# sidepanel.html — portiert nach tcl
# Quelle: html, Projects@TikTok-Live-Companion:plugin-source/browser-extension/sidepanel.html
# auch in: Projects@TikTok-Live-Companion:release/0.7.1/tiktok-live-companion-extension-0.7.1/sidepanel.html
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/sidepanel.html
# auch in: Projects@TikTok-Live-Companion-Android:release/0.7.1/tiktok-live-companion-extension-0.7.1/sidepanel.html
# auch in: 2 weiteren Fundstellen
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

# sidepanel.tcl - Erzeugt sidepanel.html aus Tcl
# Portierung von sidepanel.html nach Tcl 8.6

proc write_sidepanel {filename} {
    set fp [open $filename w]
    fconfigure $fp -encoding utf-8

    puts $fp {<!doctype html>}
    puts $fp {<html lang="de">}
    puts $fp {<head>}
    puts $fp {  <meta charset="utf-8">}
    puts $fp {  <meta name="viewport" content="width=device-width, initial-scale=1">}
    puts $fp {  <title>TikTok LIVE Companion</title>}
    puts $fp {  <link rel="stylesheet" href="sidepanel.css">}
    puts $fp {</head>}
    puts $fp {<body>}
    puts $fp {  <header>}
    puts $fp {    <p id="page-title" class="muted">Kein TikTok-Tab ausgewählt</p>}
    puts $fp {  </header>}
    puts $fp {}
    puts $fp {  <main>}
    puts $fp {    <section aria-labelledby="chat-heading">}
    puts $fp {      <div class="section-title">}
    puts $fp {        <h2 id="chat-heading">Chatzeilen</h2>}
    puts $fp {        <div class="title-actions">}
    puts $fp {          <span id="chat-led" class="status-led off" role="status" aria-label="Chat inaktiv" title="Chat inaktiv"></span>}
    puts $fp {          <button id="chat-count" class="count count-button" type="button" aria-haspopup="dialog" title="Gesammelte Chatzeilen öffnen">0</button>}
    puts $fp {          <button id="refresh-chat" class="secondary compact" title="Chatanzeige leeren">Refresh</button>}
    puts $fp {          <button id="toggle-speech" class="secondary compact" aria-pressed="false">Vorlesen an</button>}
    puts $fp {          <span id="speech-led" class="status-led off" role="status" aria-label="Vorlesen inaktiv" title="Vorlesen inaktiv"></span>}
    puts $fp {        </div>}
    puts $fp {      </div>}
    puts $fp {      <div id="chat-list" class="chat-list empty" role="log" aria-live="polite" aria-relevant="additions" aria-label="Die letzten fünf bereinigten Chatnachrichten">Noch keine Chatnachrichten erkannt.</div>}
    puts $fp {      <p id="speech-status" role="status" class="inline-status">Vorlesen ist ausgeschaltet.</p>}
    puts $fp {      <div class="control-label"><label for="speech-volume">Vorleselautstärke</label><output id="speech-volume-output" for="speech-volume">100%</output></div>}
    puts $fp {      <input id="speech-volume" type="range" min="0" max="100" step="5" value="50">}
    puts $fp {      <div class="settings-grid speech-settings">}
    puts $fp {        <label><span>Sprache</span><select id="speech-language"><option value="auto">Auto</option><option value="de-DE">Deutsch</option><option value="en-US">Englisch</option><option value="ru-RU">Russisch</option><option value="uk-UA">Ukrainisch</option><option value="bg-BG">Bulgarisch</option><option value="sr-RS">Serbisch</option><option value="kk-KZ">Kasachisch</option><option value="zh-CN">Chinesisch</option><option value="ja-JP">Japanisch</option><option value="ko-KR">Koreanisch</option><option value="ar-JO">Arabisch</option><option value="fa-IR">Persisch</option><option value="ur-PK">Urdu</option><option value="hi-IN">Hindi</option><option value="ne-NP">Nepali</option><option value="ml-IN">Malayalam</option></select></label>}
    puts $fp {        <label><span>Stimme</span><select id="speech-voice"><option value="">Standard</option></select></label>}
    puts $fp {        <label id="audd-token-setting"><span id="audd-token-label">AudD API-Token (optional - <a href="https://audd.io/" target="_blank" rel="noopener noreferrer">https://AudD.io</a> Trial/Paid )</span><input id="audd-token" type="password" autocomplete="off" spellcheck="false"></label>}
    puts $fp {        <label id="pairing-code-setting"><span>Pairing-Code</span><input id="pairing-code" type="password" autocomplete="off" spellcheck="false"></label>}
    puts $fp {      </div>}
    puts $fp {      <div class="button-row">}
    puts $fp {        <button id="service-action" class="secondary">Sprachdienst installieren</button>}
    puts $fp {        <button id="sherpa-action" class="secondary">Sherpa installieren</button>}
    puts $fp {      </div>}
    puts $fp {      <p id="service-status" class="inline-status">Lokaler Sprachdienst noch nicht geprüft.</p>}
    puts $fp {      <div id="service-setup" class="inline-status" hidden>}
    puts $fp {        <button id="copy-service-setup" class="secondary compact">Installation abschließen!</button>}
    puts $fp {      </div>}
    puts $fp {      <label class="option-row"><input id="speak-names" type="checkbox" checked> Chatnamen sprechen</label>}
    puts $fp {      <label class="option-row"><input id="shorten-names" type="checkbox"> Chatnamen kürzen</label>}
    puts $fp {      <label class="option-row"><input id="game-mode" type="checkbox"> Game-Mode</label>}
    puts $fp {      <label class="option-row auto-chat-refresh"><input id="auto-chat-refresh" type="checkbox"> Auto-Chat Refresh <input id="auto-chat-refresh-minutes" type="number" min="1" max="60" step="1" value="5" inputmode="numeric" aria-label="Auto-Chat-Refresh in Minuten"><span>min.</span></label>}
    puts $fp {      <label class="option-row"><input id="keep-speech-active" type="checkbox"> Permanent aktiv</label>}
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
    puts $fp {    <section id="page-info-section" aria-labelledby="page-info-heading">}
    puts $fp {      <div class="section-title">}
    puts $fp {        <h2 id="page-info-heading">Seiteninformationen</h2>}
    puts $fp {        <div class="title-actions">}
    puts $fp {          <span id="page-info-source" class="live-indicator">Metadaten</span>}
    puts $fp {          <button id="refresh-page-info" class="secondary compact">Refresh</button>}
    puts $fp {          <button id="force-page-info" class="secondary compact danger-outline">Force</button>}
    puts $fp {        </div>}
    puts $fp {      </div>}
    puts $fp {      <div id="profile-info" class="profile-info" hidden></div>}
    puts $fp {      <div id="summary-info" class="summary-info"></div>}
    puts $fp {    </section>}
    puts $fp {}
    puts $fp {    <section aria-labelledby="stats-heading">}
    puts $fp {      <div class="section-title">}
    puts $fp {        <h2 id="stats-heading">LIVE-Informationen</h2>}
    puts $fp {        <span id="stats-live" class="live-indicator">warte</span>}
    puts $fp {      </div>}
    puts $fp {      <div id="live-stats" class="status-grid stats-grid"></div>}
    puts $fp {      <p id="stats-status" class="inline-status"></p>}
    puts $fp {    </section>}
    puts $fp {}
    puts $fp {    <section aria-labelledby="hook-heading">}
    puts $fp {      <div class="section-title">}
    puts $fp {        <h2 id="hook-heading">WebSocket-Hook</h2>}
    puts $fp {        <span id="hook-led" class="status-led off" role="status" aria-label="Hook inaktiv" title="Hook inaktiv"></span>}
    puts $fp {      </div>}
    puts $fp {      <div class="button-row">}
    puts $fp {        <button id="enable-hook" class="primary">Hook setzen</button>}
    puts $fp {        <button id="disable-hook" class="secondary">Hook deaktivieren</button>}
    puts $fp {        <button id="reset-tab" class="secondary danger-outline">Refresh</button>}
    puts $fp {        <button id="open-embed-live" class="secondary">Embed</button>}
    puts $fp {        <button id="open-normal-live" class="secondary">Normal</button>}
    puts $fp {        <button id="player-vlc-frame" class="secondary compact">VLC Ersatz</button>}
    puts $fp {      </div>}
    puts $fp {      <p id="hook-status" class="inline-status"></p>}
    puts $fp {      <label class="option-row"><input id="hook-autostart" type="checkbox"> Permanent Hook</label>}
    puts $fp {      <label class="option-row"><input id="quick-recover" type="checkbox"> Auto-Reconnect</label>}
    puts $fp {    </section>}
    puts $fp {}
    puts $fp {    <section aria-labelledby="caption-heading">}
    puts $fp {      <div class="section-title">}
    puts $fp {        <h2 id="caption-heading">Untertitel</h2>}
    puts $fp {        <button id="scan" class="secondary">Seite prüfen</button>}
    puts $fp {      </div>}
    puts $fp {      <div id="caption-status" class="status-grid"></div>}
    puts $fp {      <button id="enable-captions" class="primary">Untertitel aktivieren</button>}
    puts $fp {      <p id="caption-action-status" role="status" class="inline-status action-status"></p>}
    puts $fp {    </section>}
    puts $fp {}
    puts $fp {    <section aria-labelledby="player-heading">}
    puts $fp {      <div class="section-title">}
    puts $fp {        <h2 id="player-heading">Playersteuerung</h2>}
    puts $fp {        <span id="player-time" class="player-time">–</span>}
    puts $fp {      </div>}
    puts $fp {      <div class="player-controls" role="group" aria-label="TikTok-Player steuern">}
    puts $fp {        <button id="player-play" class="secondary compact">Pause</button>}
    puts $fp {        <button id="player-replay" class="secondary compact">Neu laden</button>}
    puts $fp {        <button id="player-mute" class="secondary compact">Stumm</button>}
    puts $fp {        <button id="player-pip" class="secondary compact">Bild-in-Bild</button>}
    puts $fp {        <button id="player-fullscreen" class="secondary compact">Vollbild</button>}
    puts $fp {        <button id="player-report" class="secondary compact danger-outline">Melden öffnen</button>}
    puts $fp {      </div>}
    puts $fp {      <div class="audio-controls">}
    puts $fp {        <div class="control-label"><label for="player-volume">Lautstärke</label><output id="player-volume-output" for="player-volume">–</output></div>}
    puts $fp {        <input id="player-volume" type="range" min="0" max="100" step="1" value="100">}
    puts $fp {        <div class="audio-meter-row"><span>Spitzenpegel</span><strong id="player-peak">–</strong></div>}
    puts $fp {        <label class="option-row"><input id="limiter-enabled" type="checkbox"> Pegelschutz aktivieren</label>}
    puts $fp {        <div class="control-label"><label for="limiter-strength">Schutzstärke</label><output id="limiter-strength-output" for="limiter-strength">30</output></div>}
    puts $fp {        <input id="limiter-strength" type="range" min="0" max="100" step="1" value="30">}
    puts $fp {      </div>}
    puts $fp {      <p id="multi-guest-status" class="inline-status">Verbundene Streams: noch nicht erkannt.</p>}
    puts $fp {      <p id="player-status" role="status" class="inline-status">Warte auf den TikTok-Player.</p>}
    puts $fp {    </section>}
    puts $fp {}
    puts $fp {    <section aria-labelledby="song-heading">}
    puts $fp {      <div class="section-title">}
    puts $fp {        <h2 id="song-heading">Songerkennung</h2>}
    puts $fp {        <span id="song-led" class="status-led off" role="status" aria-label="Songerkennung inaktiv"></span>}
    puts $fp {      </div>}
    puts $fp {      <label class="option-row"><input id="song-enabled" type="checkbox"> Songerkennung aktivieren</label>}
    puts $fp {      <button id="recognize-song" class="primary" disabled>Jetzt erkennen</button>}
    puts $fp {      <p id="song-status" class="inline-status"></p>}
    puts $fp {      <div id="song-result" class="song-result" hidden></div>}
    puts $fp {    </section>}
    puts $fp {}
    puts $fp {    <section aria-labelledby="links-heading">}
    puts $fp {      <div class="section-title">}
    puts $fp {        <h2 id="links-heading">VLC-Links</h2>}
    puts $fp {        <span id="media-count" class="count">0</span>}
    puts $fp {      </div>}
    puts $fp {      <div id="media-list" class="list empty">Noch keine FLV-/HLS-Links erkannt.</div>}
    puts $fp {    </section>}
    puts $fp {}
    puts $fp {    <section aria-labelledby="log-heading">}
    puts $fp {      <div class="section-title">}
    puts $fp {        <h2 id="log-heading">Caption-Protokoll</h2>}
    puts $fp {        <span id="caption-count" class="count">0</span>}
    puts $fp {      </div>}
    puts $fp {      <div class="button-row">}
    puts $fp {        <button id="export-log" class="secondary">JSONL exportieren</button>}
    puts $fp {        <button id="clear" class="ghost">Anzeige leeren</button>}
    puts $fp {      </div>}
    puts $fp {      <div id="caption-list" class="list empty">Noch keine CaptionMessages empfangen.</div>}
    puts $fp {    </section>}
    puts $fp {}
    puts $fp {    <section aria-labelledby="debug-heading">}
    puts $fp {      <div class="section-title">}
    puts $fp {        <h2 id="debug-heading">Debugmodus</h2>}
    puts $fp {        <span id="debug-count" class="count">0</span>}
    puts $fp {      </div>}
    puts $fp {      <label class="option-row"><input id="debug-enabled" type="checkbox"> Diagnoseereignisse für diesen Tab protokollieren</label>}
    puts $fp {      <div class="button-row">}
    puts $fp {        <button id="export-debug" class="secondary">Debug exportieren</button>}
    puts $fp {        <button id="clear-debug" class="ghost">Debug leeren</button>}
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
    puts $fp {    <div id="chat-history-modal" class="modal-backdrop" hidden>}
    puts $fp {      <section class="modal" role="dialog" aria-modal="true" aria-labelledby="chat-history-heading">}
    puts $fp {        <div class="section-title">}
    puts $fp {          <h2 id="chat-history-heading">Gesammelte Chatzeilen</h2>}
    puts $fp {          <button id="close-chat-history" class="secondary compact" aria-label="Chatzeilen schließen">Schließen</button>}
    puts $fp {        </div>}
    puts $fp {        <p id="chat-history-limit" class="inline-status"></p>}
    puts $fp {        <div id="chat-history-list" class="chat-history-list"></div>}
    puts $fp {      </section>}
    puts $fp {    </div>}
    puts $fp {}
    puts $fp {    <p id="notice" role="alert" class="notice"></p>}
    puts $fp {  </main>}
    puts $fp {}
    puts $fp {  <script src="content-core.js"></script>}
    puts $fp {  <script src="sidepanel.js"></script>}
    puts $fp {</body>}
    puts $fp {</html>}

    close $fp
}

# Hauptprogramm: Erzeuge die HTML-Datei
if {$argc != 1} {
    puts stderr "Aufruf: [info script] <ausgabedatei>"
    exit 1
}

set output_file [lindex $argv 0]
write_sidepanel $output_file
