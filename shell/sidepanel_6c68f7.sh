#!/bin/bash
# sidepanel.html — portiert nach shell
# Quelle: html, Projects@TikTok-Live-Companion:plugin-source/browser-extension/sidepanel.html
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/sidepanel.html
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/sidepanel.html
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/browser-extension/sidepanel.html
# Erzeugt: 2026-10-23 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Parameter: Ausgabedatei
if [[ $# -ne 1 ]]; then
  echo "Aufruf: $0 <ausgabedatei>" >&2
  exit 1
fi

output_file="$1"

# Erzeuge das HTML-Dokument
cat > "$output_file" << 'HTML_END'
<!doctype html>
<html lang="de">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>TikTok LIVE Companion</title>
  <link rel="stylesheet" href="sidepanel.css">
  <link rel="stylesheet" href="icon-controls.css">
</head>
<body>
  <header>
    <p id="page-title" class="muted">Kein TikTok-Tab ausgewählt</p>
  </header>

  <main>
    <section aria-labelledby="chat-heading">
      <div class="section-title">
        <h2 id="chat-heading">Chat</h2>
        <div class="title-actions">
          <span id="chat-led" class="status-led off" role="status" aria-label="Chat inaktiv" title="Chat inaktiv"></span>
          <button id="chat-count" class="count count-button" type="button" aria-haspopup="dialog" title="Gesammelte Chatzeilen öffnen">0</button>
          <button id="refresh-chat" class="secondary compact" title="Chatanzeige leeren">Reset</button>
          <button id="toggle-speech" class="secondary compact" aria-pressed="false" aria-label="Vorlesen">On</button>
          <span id="speech-led" class="status-led off" role="status" aria-label="Vorlesen inaktiv" title="Vorlesen inaktiv"></span>
        </div>
      </div>
      <div id="chat-list" class="chat-list empty" role="log" aria-live="polite" aria-relevant="additions" aria-label="Die letzten fünf bereinigten Chatnachrichten">Noch keine Chatnachrichten erkannt.</div>
      <p id="speech-status" role="status" class="inline-status">Vorlesen ist ausgeschaltet.</p>
      <div class="control-label"><label for="speech-volume">Vorleselautstärke</label><output id="speech-volume-output" for="speech-volume">100%</output></div>
      <input id="speech-volume" type="range" min="0" max="100" step="5" value="50">
      <div class="button-row">
        <button id="service-action" class="secondary">Sprachdienst</button>
        <button id="sherpa-action" class="secondary">Sherpa</button>
        <button id="open-speech-settings" class="secondary compact settings-button" type="button" aria-label="Erweiterte Einstellungen öffnen" aria-haspopup="dialog" title="Einstellungen"></button>
      </div>
      <p id="service-status" class="inline-status">Lokaler Sprachdienst noch nicht geprüft.</p>
      <div id="service-setup" class="inline-status" hidden>
        <button id="copy-service-setup" class="secondary compact">Installation abschließen!</button>
      </div>
    </section>

    <section aria-labelledby="stats-heading">
      <div class="section-title">
        <h2 id="stats-heading">LIVE-Information</h2>
        <span id="stats-live" class="live-indicator">warte</span>
      </div>
      <div id="live-stats" class="status-grid stats-grid"></div>
      <p id="stats-status" class="inline-status"></p>
    </section>

    <section id="page-info-section" aria-labelledby="page-info-heading">
      <div class="section-title">
        <h2 id="page-info-heading">PROFIL-Information</h2>
        <div class="title-actions">
          <span id="page-info-source" class="live-indicator">Metadaten</span>
          <button id="refresh-page-info" class="secondary compact" title="Refresh">Refresh</button>
          <button id="force-page-info" class="secondary compact danger-outline">Force</button>
        </div>
      </div>
      <div id="profile-info" class="profile-info" hidden></div>
      <div id="summary-info" class="summary-info"></div>
    </section>

    <section aria-labelledby="hook-heading">
      <div class="section-title header-controls">
        <h2 id="hook-heading">Connection</h2>
        <div class="title-actions">
          <button id="reset-tab" class="secondary compact danger-outline" title="Reset">Reset</button>
          <input id="hook-autostart" type="checkbox" aria-label="Hook dauerhaft" title="Hook dauerhaft: Off">
          <span class="status-led off" data-switch-status="hook-autostart" role="status"></span>
        </div>
      </div>
      <div class="button-row">
        <button id="toggle-hook" class="primary" aria-label="Connection" aria-pressed="false">On</button>
        <button id="open-connection-settings" class="secondary compact settings-button" type="button" aria-label="Connection-Einstellungen öffnen" aria-haspopup="dialog"></button>
        <button id="open-embed-live" class="secondary">Embed</button>
        <button id="open-normal-live" class="secondary">Browser</button>
        <button id="player-vlc-frame" class="secondary compact">Player</button>
      </div>
      <div class="connection-status"><span id="hook-led" class="status-led off" role="status" aria-label="Hook inaktiv" title="Hook inaktiv"></span><p id="hook-status" class="inline-status"></p></div>
      <p id="embed-startup-status" class="inline-status" role="status" aria-live="polite" hidden></p>
      <button id="cancel-embed-startup" class="secondary" hidden>Embed-Start abbrechen</button>
      <p id="hook-reconnect-status" class="inline-status" role="status">Hook-Reconnect: aus</p>
      <p id="player-recovery-status" class="inline-status" role="status">Player-Recovery: aus</p>
    </section>

    <section aria-labelledby="player-heading">
      <div class="section-title header-controls">
        <h2 id="player-heading">Player</h2>
        <div class="title-actions">
          <button id="player-replay" class="secondary compact" title="Neu laden">Neu laden</button>
          <input id="limiter-enabled" type="checkbox" aria-label="Pegelschutz" title="Pegelschutz: Off">
          <span class="status-led off" data-switch-status="limiter-enabled" role="status"></span>
        </div>
      </div>
      <div class="player-controls" role="group" aria-label="TikTok-Player steuern">
        <button id="player-play" class="secondary compact">Play</button>
        <button id="player-mute" class="secondary compact">Mute</button>
        <button id="player-pip" class="secondary compact">Bild-in-Bild</button>
        <button id="player-fullscreen" class="secondary compact">Vollbild</button>
        <button id="player-report" class="secondary compact danger-outline">Meldung</button>
      </div>
      <div class="audio-controls">
        <div class="control-label"><label for="player-volume">Lautstärke</label><output id="player-volume-output" for="player-volume">–</output></div>
        <input id="player-volume" type="range" min="0" max="100" step="1" value="100">
        <div class="audio-meter-row"><span>Spitzenpegel</span><strong id="player-peak">–</strong></div>
        <div class="control-label"><label for="limiter-strength">Schutzstärke</label><output id="limiter-strength-output" for="limiter-strength">30</output></div>
        <input id="limiter-strength" type="range" min="0" max="100" step="1" value="30">
      </div>
      <p id="multi-guest-status" class="inline-status">Verbundene Streams: noch nicht erkannt.</p>
      <p id="player-status" role="status" class="inline-status">Warte auf den TikTok-Player.</p>
      <span id="player-time" class="player-time" hidden>–</span>
    </section>

    <section aria-labelledby="top-chatters-heading">
      <div class="section-title">
        <h2 id="top-chatters-heading">Top-Chatter</h2>
        <button id="open-audience" class="secondary compact">Zuschauer*innen</button>
      </div>
      <p id="team-tag-status" class="inline-status">Teamkürzel: noch nicht erkannt.</p>
      <div id="top-chatters" class="top-chatters empty">Noch keine Personen im Chat beobachtet.</div>
      <div id="top-chatters-actions" class="top-chatters-actions" hidden>
        <button id="top-chatters-reset" class="top-chatter-link" type="button" hidden>Reset</button>
        <button id="top-chatters-more" class="top-chatter-link" type="button">mehr…</button>
      </div>
    </section>

    <section id="recommendations-section" aria-labelledby="recommendations-heading">
      <div class="section-title">
        <h2 id="recommendations-heading">LIVE-Empfehlungen</h2>
        <span id="recommendation-status" class="live-indicator">bereit</span>
      </div>
      <div class="recommendation-controls">
        <label><span>Anzahl</span><input id="recommendation-limit" type="number" min="1" max="300" step="1" value="20" inputmode="numeric"></label>
        <label><span>Sortierung</span><select id="recommendation-sort"><option value="tiktok">TikTok-Reihenfolge</option><option value="viewers">Zuschauer*innen</option></select></label>
      </div>
      <div class="button-row">
        <button id="scan-recommendations" class="primary">Empfehlungen scannen</button>
        <button id="cancel-recommendations" class="secondary" hidden>Abbrechen</button>
      </div>
      <p id="recommendation-progress" class="inline-status" aria-live="polite">Noch kein Scan gestartet.</p>
      <div id="recommendation-list" class="recommendation-list empty">Noch keine Empfehlungen erfasst.</div>
      <div id="recommendation-actions" class="top-chatters-actions" hidden>
        <button id="recommendation-more" class="top-chatter-link" type="button">mehr…</button>
      </div>
    </section>

    <section aria-labelledby="caption-heading">
      <div class="section-title">
        <h2 id="caption-heading">Titel</h2>
        <button id="scan" class="secondary">Status</button>
      </div>
      <div id="caption-status" class="status-grid"></div>
      <button id="enable-captions" class="primary">Untertitel</button>
      <p id="caption-action-status" role="status" class="inline-status action-status"></p>
    </section>

    <section aria-labelledby="song-heading">
      <div class="section-title header-controls">
        <h2 id="song-heading">Songs</h2>
        <div class="title-actions">
          <input id="song-enabled" type="checkbox" aria-label="Songerkennung" title="Songerkennung: Off">
          <span id="song-led" class="status-led off" data-switch-status="song-enabled" role="status" aria-label="Songerkennung inaktiv"></span>
        </div>
      </div>
      <button id="recognize-song" class="primary" disabled>Jetzt erkennen</button>
      <p id="song-status" class="inline-status"></p>
      <div id="song-result" class="song-result" hidden></div>
    </section>

    <section aria-labelledby="links-heading">
      <div class="section-title">
        <h2 id="links-heading">HAR-Logs</h2>
        <span id="media-count" class="count">0</span>
      </div>
      <div id="media-list" class="list empty">Noch keine FLV-/HLS-Links erkannt.</div>
    </section>

    <section aria-labelledby="log-heading">
      <div class="section-title header-controls">
        <h2 id="log-heading">LIVE-Logs</h2>
        <div class="title-actions">
          <span class="status-led off" data-counter-status="caption-count" role="status"></span>
          <span id="caption-count" class="count">0</span>
          <button id="clear" class="ghost compact" title="Reset">Reset</button>
          <input id="live-logs-enabled" type="checkbox" aria-label="LIVE-Logs" title="LIVE-Logs: Off">
          <span class="status-led off" data-switch-status="live-logs-enabled" role="status" aria-label="LIVE-Logs: deaktiviert"></span>
        </div>
      </div>
      <div class="button-row">
        <button id="export-log" class="secondary">JSON-L-Export</button>
        <button id="export-caption-raw" class="secondary">RAW-JSON-Export</button>
      </div>
      <div id="caption-list" class="list empty">Noch keine CaptionMessages empfangen.</div>
    </section>

    <section aria-labelledby="debug-heading">
      <div class="section-title header-controls">
        <h2 id="debug-heading">Debugmodus</h2>
        <div class="title-actions">
          <span class="status-led off" data-counter-status="debug-count" role="status"></span>
          <span id="debug-count" class="count">0</span>
          <button id="clear-debug" class="ghost compact" title="Reset">Reset</button>
          <input id="debug-enabled" type="checkbox" aria-label="Diagnoseereignisse für diesen Tab protokollieren" title="Diagnoseereignisse für diesen Tab protokollieren: Off">
          <span class="status-led off" data-switch-status="debug-enabled" role="status"></span>
        </div>
      </div>
      <div class="button-row">
        <button id="export-debug" class="secondary">Debug exportieren</button>
      </div>
      <p class="muted small"></p>
    </section>

    <div id="audience-modal" class="modal-backdrop" hidden>
      <section class="modal" role="dialog" aria-modal="true" aria-labelledby="audience-heading">
        <div class="section-title">
          <h2 id="audience-heading">Im Chat beobachtete Personen</h2>
          <button id="close-audience" class="secondary compact" aria-label="Übersicht schließen">Schließen</button>
        </div>
        <p id="audience-limit" class="inline-status"></p>
        <div id="audience-list" class="audience-list"></div>
      </section>
    </div>

    <div id="speech-settings-modal" class="modal-backdrop" hidden>
      <section class="modal" role="dialog" aria-modal="true" aria-labelledby="speech-settings-heading">
        <div class="section-title">
          <h2 id="speech-settings-heading">Erweiterte Einstellungen</h2>
          <button id="close-speech-settings" class="secondary compact" aria-label="Einstellungen schließen">Schließen</button>
        </div>
        <div class="settings-grid speech-integration-settings">
<label class="icon-style-setting"><span>Icon-Stil</span><select id="icon-style"><option value="plastisch">3D / Plastisch</option><option value="glass">Glass / Realistisch</option><option value="linear">Minimal / Linear</option></select></label>
          <label><span>Sprache</span><select id="speech-language"><option value="auto">Auto</option><option value="de-DE">Deutsch</option><option value="en-US">Englisch</option><option value="ru-RU">Russisch</option><option value="uk-UA">Ukrainisch</option><option value="bg-BG">Bulgarisch</option><option value="sr-RS">Serbisch</option><option value="kk-KZ">Kasachisch</option><option value="zh-CN">Chinesisch</option><option value="ja-JP">Japanisch</option><option value="ko-KR">Koreanisch</option><option value="ar-JO">Arabisch</option><option value="fa-IR">Persisch</option><option value="ur-PK">Urdu</option><option value="hi-IN">Hindi</option><option value="ne-NP">Nepali</option><option value="ml-IN">Malayalam</option></select></label>
          <label><span>Stimme</span><select id="speech-voice"><option value="">Standard</option></select></label>
          <label id="audd-token-setting"><span id="audd-token-label">AudD API-Token (optional - <a href="https://audd.io/" target="_blank" rel="noopener noreferrer">https://AudD.io</a> Trial/Paid)</span><input id="audd-token" type="password" autocomplete="off" spellcheck="false"></label>
          <label id="pairing-code-setting"><span>Pairing-Code</span><input id="pairing-code" type="password" autocomplete="off" spellcheck="false"></label>
          <label><span>Universal API-Key</span><input id="universal-caption-api-key" type="password" autocomplete="off" spellcheck="false"></label>
        </div>
        <label class="option-row"><input id="speak-names" type="checkbox" checked> Chatnamen sprechen</label>
        <label class="option-row"><input id="shorten-names" type="checkbox"> Chatnamen kürzen</label>
        <label class="option-row auto-chat-refresh"><input id="auto-chat-refresh" type="checkbox"> Auto-Chat Refresh <input id="auto-chat-refresh-minutes" type="number" min="1" max="60" step="1" value="5" inputmode="numeric" aria-label="Auto-Chat-Refresh in Minuten"><span>min.</span></label>
        <label class="option-row"><input id="game-mode" type="checkbox"> Game-Mode (Spam-, Emoji, usw. Chatfilter)</label>
        <div class="option-row external-speech-trigger-row"><label><input id="filter-external-speech-triggers" type="checkbox"> Trigger filtern (ext. Sprachdienste)</label><input id="external-speech-trigger-characters" type="text" value="." maxlength="10" aria-label="Triggerzeichen, maximal fünf Sonderzeichen" autocomplete="off" spellcheck="false"></div>
        <label class="option-row"><input id="keep-speech-active" type="checkbox" aria-label="Vorlesen dauerhaft" title="Vorlesen dauerhaft: Off"> Vorlesen dauerhaft</label>
      </section>
    </div>

    <div id="chat-history-modal" class="modal-backdrop" hidden>
      <section class="modal" role="dialog" aria-modal="true" aria-labelledby="chat-history-heading">
        <div class="section-title">
          <h2 id="chat-history-heading">Gesammelte Chatnachrichten</h2>
          <button id="close-chat-history" class="secondary compact" aria-label="Chatzeilen schließen">Schließen</button>
        </div>
        <p id="chat-history-limit" class="inline-status"></p>
        <div id="chat-history-list" class="chat-history-list"></div>
      </section>
    </div>

    <div id="recommendation-modal" class="modal-backdrop" hidden>
      <section class="modal" role="dialog" aria-modal="true" aria-labelledby="recommendation-modal-heading">
        <div class="section-title">
          <h2 id="recommendation-modal-heading">Gescannte LIVE-Empfehlungen</h2>
          <button id="close-recommendations" class="secondary compact" aria-label="Empfehlungen schließen">Schließen</button>
        </div>
        <div id="recommendation-modal-list" class="recommendation-list"></div>
      </section>
    </div>

    <p id="notice" role="alert" class="notice"></p>
  </main>
  <div id="connection-settings-modal" class="modal-backdrop" hidden>
    <section class="modal" role="dialog" aria-modal="true" aria-labelledby="connection-settings-heading">
      <div class="section-title"><h2 id="connection-settings-heading">Connection-Einstellungen</h2><button id="close-connection-settings" class="secondary compact">Schließen</button></div>
      <label class="option-row quick-recover-setting"><input id="hook-reconnect" type="checkbox"> Hook-Reconnect <input id="hook-reconnect-seconds" type="number" min="1" max="59" step="1" value="3" inputmode="numeric" aria-label="Hook-Reconnect-Wartezeit in Sekunden"><span>Sek.</span></label>
      <label class="option-row quick-recover-setting"><input id="quick-recover" type="checkbox"> Player-Recovery <input id="quick-recover-seconds" type="number" min="1" max="59" step="1" value="3" inputmode="numeric" aria-label="Player-Recovery-Bestätigungszeit in Sekunden"><span>Sek.</span></label>
    </section>
  </div>


  <script src="content-core.js"></script>
  <script src="sidepanel.js"></script>
  <script src="icon-controls.js"></script>
</body>
</html>
HTML_END

echo "HTML-Datei wurde erfolgreich erstellt: $output_file"
