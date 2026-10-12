#!/usr/bin/env python3
# sidepanel.html — portiert nach python
# Quelle: html, Projects@codex/0pe-177-peak-protection:plugin-source/browser-extension/sidepanel.html
# Erzeugt: 2026-10-12 durch ABSTRACTIONS_MANAGER.py

import sys
from pathlib import Path
from html import escape


def generate_html():
    """Generate the complete HTML document as a string."""
    html_parts = []
    
    # Document type and root element
    html_parts.append('<!doctype html>')
    html_parts.append('<html lang="de">')
    
    # Head section
    html_parts.append('<head>')
    html_parts.append('  <meta charset="utf-8">')
    html_parts.append('  <meta name="viewport" content="width=device-width, initial-scale=1">')
    html_parts.append('  <title>TikTok LIVE Companion</title>')
    html_parts.append('  <link rel="stylesheet" href="sidepanel.css">')
    html_parts.append('</head>')
    
    # Body start
    html_parts.append('<body>')
    
    # Header
    html_parts.append('  <header>')
    html_parts.append('    <p id="page-title" class="muted">Kein TikTok-Tab ausgewählt</p>')
    html_parts.append('  </header>')
    
    # Main content
    html_parts.append('  <main>')
    
    # Chat section
    html_parts.append('    <section aria-labelledby="chat-heading">')
    html_parts.append('      <div class="section-title">')
    html_parts.append('        <h2 id="chat-heading">Chat</h2>')
    html_parts.append('        <div class="title-actions">')
    html_parts.append('          <span id="chat-led" class="status-led off" role="status" aria-label="Chat inaktiv" title="Chat inaktiv"></span>')
    html_parts.append('          <button id="chat-count" class="count count-button" type="button" aria-haspopup="dialog" title="Gesammelte Chatzeilen öffnen">0</button>')
    html_parts.append('          <button id="refresh-chat" class="secondary compact" title="Chatanzeige leeren">Refresh</button>')
    html_parts.append('          <button id="toggle-speech" class="secondary compact" aria-pressed="false" aria-label="Vorlesen">On</button>')
    html_parts.append('          <span id="speech-led" class="status-led off" role="status" aria-label="Vorlesen inaktiv" title="Vorlesen inaktiv"></span>')
    html_parts.append('        </div>')
    html_parts.append('      </div>')
    html_parts.append('      <div id="chat-list" class="chat-list empty" role="log" aria-live="polite" aria-relevant="additions" aria-label="Die letzten fünf bereinigten Chatnachrichten">Noch keine Chatnachrichten erkannt.</div>')
    html_parts.append('      <p id="speech-status" role="status" class="inline-status">Vorlesen ist ausgeschaltet.</p>')
    html_parts.append('      <div class="control-label"><label for="speech-volume">Vorleselautstärke</label><output id="speech-volume-output" for="speech-volume">100%</output></div>')
    html_parts.append('      <input id="speech-volume" type="range" min="0" max="100" step="5" value="50">')
    html_parts.append('      <div class="button-row">')
    html_parts.append('        <button id="service-action" class="secondary">Sprachdienst</button>')
    html_parts.append('        <button id="sherpa-action" class="secondary">Sherpa</button>')
    html_parts.append('        <button id="open-speech-settings" class="secondary compact settings-button" type="button" aria-label="Sprach- und Chat Einstellungen öffnen" aria-haspopup="dialog" title="Einstellungen">⚙</button>')
    html_parts.append('      </div>')
    html_parts.append('      <p id="service-status" class="inline-status">Lokaler Sprachdienst noch nicht geprüft.</p>')
    html_parts.append('      <div id="service-setup" class="inline-status" hidden>')
    html_parts.append('        <button id="copy-service-setup" class="secondary compact">Installation abschließen!</button>')
    html_parts.append('      </div>')
    html_parts.append('      <label class="option-row"><input id="keep-speech-active" type="checkbox"> Permanent aktiv</label>')
    html_parts.append('    </section>')
    
    # Top Chatters section
    html_parts.append('    <section aria-labelledby="top-chatters-heading">')
    html_parts.append('      <div class="section-title">')
    html_parts.append('        <h2 id="top-chatters-heading">Top-Chatter</h2>')
    html_parts.append('        <button id="open-audience" class="secondary compact">Zuschauer*innen</button>')
    html_parts.append('      </div>')
    html_parts.append('      <p id="team-tag-status" class="inline-status">Teamkürzel: noch nicht erkannt.</p>')
    html_parts.append('      <div id="top-chatters" class="top-chatters empty">Noch keine Personen im Chat beobachtet.</div>')
    html_parts.append('      <div id="top-chatters-actions" class="top-chatters-actions" hidden>')
    html_parts.append('        <button id="top-chatters-reset" class="top-chatter-link" type="button" hidden>Reset</button>')
    html_parts.append('        <button id="top-chatters-more" class="top-chatter-link" type="button">mehr…</button>')
    html_parts.append('      </div>')
    html_parts.append('    </section>')
    
    # Profile Information section
    html_parts.append('    <section id="page-info-section" aria-labelledby="page-info-heading">')
    html_parts.append('      <div class="section-title">')
    html_parts.append('        <h2 id="page-info-heading">PROFIL-Information</h2>')
    html_parts.append('        <div class="title-actions">')
    html_parts.append('          <span id="page-info-source" class="live-indicator">Metadaten</span>')
    html_parts.append('          <button id="refresh-page-info" class="secondary compact">Refresh</button>')
    html_parts.append('          <button id="force-page-info" class="secondary compact danger-outline">Force</button>')
    html_parts.append('        </div>')
    html_parts.append('      </div>')
    html_parts.append('      <div id="profile-info" class="profile-info" hidden></div>')
    html_parts.append('      <div id="summary-info" class="summary-info"></div>')
    html_parts.append('    </section>')
    
    # Live Information section
    html_parts.append('    <section aria-labelledby="stats-heading">')
    html_parts.append('      <div class="section-title">')
    html_parts.append('        <h2 id="stats-heading">LIVE-Information</h2>')
    html_parts.append('        <span id="stats-live" class="live-indicator">warte</span>')
    html_parts.append('      </div>')
    html_parts.append('      <div id="live-stats" class="status-grid stats-grid"></div>')
    html_parts.append('      <p id="stats-status" class="inline-status"></p>')
    html_parts.append('    </section>')
    
    # Connection section
    html_parts.append('    <section aria-labelledby="hook-heading">')
    html_parts.append('      <div class="section-title">')
    html_parts.append('        <h2 id="hook-heading">Connection</h2>')
    html_parts.append('        <span id="hook-led" class="status-led off" role="status" aria-label="Hook inaktiv" title="Hook inaktiv"></span>')
    html_parts.append('      </div>')
    html_parts.append('      <div class="button-row">')
    html_parts.append('        <button id="toggle-hook" class="primary" aria-label="Connection" aria-pressed="false">On</button>')
    html_parts.append('        <button id="reset-tab" class="secondary danger-outline">Refresh</button>')
    html_parts.append('        <button id="open-embed-live" class="secondary">Embed</button>')
    html_parts.append('        <button id="open-normal-live" class="secondary">Browser</button>')
    html_parts.append('        <button id="player-vlc-frame" class="secondary compact">Player</button>')
    html_parts.append('        <button id="open-connection-settings" class="secondary compact settings-button" type="button" aria-label="Connection-Einstellungen öffnen" aria-haspopup="dialog">⚙</button>')
    html_parts.append('      </div>')
    html_parts.append('      <p id="hook-status" class="inline-status"></p>')
    html_parts.append('      <p id="embed-startup-status" class="inline-status" role="status" aria-live="polite" hidden></p>')
    html_parts.append('      <button id="cancel-embed-startup" class="secondary" hidden>Embed-Start abbrechen</button>')
    html_parts.append('      <label class="option-row"><input id="hook-autostart" type="checkbox"> Permanent Hook</label>')
    html_parts.append('      <p id="hook-reconnect-status" class="inline-status" role="status">Hook-Reconnect: aus</p>')
    html_parts.append('      <p id="player-recovery-status" class="inline-status" role="status">Player-Recovery: aus</p>')
    html_parts.append('    </section>')
    
    # Recommendations section
    html_parts.append('    <section id="recommendations-section" aria-labelledby="recommendations-heading">')
    html_parts.append('      <div class="section-title">')
    html_parts.append('        <h2 id="recommendations-heading">LIVE-Empfehlungen</h2>')
    html_parts.append('        <span id="recommendation-status" class="live-indicator">bereit</span>')
    html_parts.append('      </div>')
    html_parts.append('      <div class="recommendation-controls">')
    html_parts.append('        <label><span>Anzahl</span><input id="recommendation-limit" type="number" min="1" max="50" step="1" value="20" inputmode="numeric"></label>')
    html_parts.append('        <label><span>Sortierung</span><select id="recommendation-sort"><option value="tiktok">TikTok-Reihenfolge</option><option value="viewers">Zuschauer*innen</option></select></label>')
    html_parts.append('      </div>')
    html_parts.append('      <div class="button-row">')
    html_parts.append('        <button id="scan-recommendations" class="primary">Empfehlungen scannen</button>')
    html_parts.append('        <button id="cancel-recommendations" class="secondary" hidden>Abbrechen</button>')
    html_parts.append('      </div>')
    html_parts.append('      <p id="recommendation-progress" class="inline-status" aria-live="polite">Noch kein Scan gestartet.</p>')
    html_parts.append('      <div id="recommendation-list" class="recommendation-list empty">Noch keine Empfehlungen erfasst.</div>')
    html_parts.append('      <div id="recommendation-actions" class="top-chatters-actions" hidden>')
    html_parts.append('        <button id="recommendation-more" class="top-chatter-link" type="button">mehr…</button>')
    html_parts.append('      </div>')
    html_parts.append('    </section>')
    
    # Title/Caption section
    html_parts.append('    <section aria-labelledby="caption-heading">')
    html_parts.append('      <div class="section-title">')
    html_parts.append('        <h2 id="caption-heading">Titel</h2>')
    html_parts.append('        <button id="scan" class="secondary">Seite prüfen</button>')
    html_parts.append('      </div>')
    html_parts.append('      <div id="caption-status" class="status-grid"></div>')
    html_parts.append('      <button id="enable-captions" class="primary">Untertitel aktivieren</button>')
    html_parts.append('      <p id="caption-action-status" role="status" class="inline-status action-status"></p>')
    html_parts.append('    </section>')
    
    # Player section
    html_parts.append('    <section aria-labelledby="player-heading">')
    html_parts.append('      <div class="section-title">')
    html_parts.append('        <h2 id="player-heading">Player</h2>')
    html_parts.append('        <span id="player-time" class="player-time">–</span>')
    html_parts.append('      </div>')
    html_parts.append('      <div class="player-controls" role="group" aria-label="TikTok-Player steuern">')
    html_parts.append('        <button id="player-play" class="secondary compact">Pause</button>')
    html_parts.append('        <button id="player-replay" class="secondary compact">Neu laden</button>')
    html_parts.append('        <button id="player-mute" class="secondary compact">Stumm</button>')
    html_parts.append('        <button id="player-pip" class="secondary compact">Bild-in-Bild</button>')
    html_parts.append('        <button id="player-fullscreen" class="secondary compact">Vollbild</button>')
    html_parts.append('        <button id="player-report" class="secondary compact danger-outline">Melden öffnen</button>')
    html_parts.append('      </div>')
    html_parts.append('      <div class="audio-controls">')
    html_parts.append('        <div class="control-label"><label for="player-volume">Lautstärke</label><output id="player-volume-output" for="player-volume">–</output></div>')
    html_parts.append('        <input id="player-volume" type="range" min="0" max="100" step="1" value="100">')
    html_parts.append('        <div class="audio-meter-row"><span>Spitzenpegel</span><strong id="player-peak">–</strong></div>')
    html_parts.append('        <label class="option-row"><input id="limiter-enabled" type="checkbox"> Pegelschutz aktivieren</label>')
    html_parts.append('        <div class="control-label"><label for="limiter-strength">Schutzstärke</label><output id="limiter-strength-output" for="limiter-strength">30</output></div>')
    html_parts.append('        <input id="limiter-strength" type="range" min="0" max="100" step="1" value="30">')
    html_parts.append('      </div>')
    html_parts.append('      <p id="multi-guest-status" class="inline-status">Verbundene Streams: noch nicht erkannt.</p>')
    html_parts.append('      <p id="player-status" role="status" class="inline-status">Warte auf den TikTok-Player.</p>')
    html_parts.append('    </section>')
    
    # Songs section
    html_parts.append('    <section aria-labelledby="song-heading">')
    html_parts.append('      <div class="section-title">')
    html_parts.append('        <h2 id="song-heading">Songs</h2>')
    html_parts.append('        <span id="song-led" class="status-led off" role="status" aria-label="Songerkennung inaktiv"></span>')
    html_parts.append('      </div>')
    html_parts.append('      <label class="option-row"><input id="song-enabled" type="checkbox"> Songerkennung aktivieren</label>')
    html_parts.append('      <button id="recognize-song" class="primary" disabled>Jetzt erkennen</button>')
    html_parts.append('      <p id="song-status" class="inline-status"></p>')
    html_parts.append('      <div id="song-result" class="song-result" hidden></div>')
    html_parts.append('    </section>')
    
    # HAR Logs section
    html_parts.append('    <section aria-labelledby="links-heading">')
    html_parts.append('      <div class="section-title">')
    html_parts.append('        <h2 id="links-heading">HAR-Logs</h2>')
    html_parts.append('        <span id="media-count" class="count">0</span>')
    html_parts.append('      </div>')
    html_parts.append('      <div id="media-list" class="list empty">Noch keine FLV-/HLS-Links erkannt.</div>')
    html_parts.append('      <p class="hint">Extern gestarteter VLC liegt außerhalb des Companion-Pegelschutzes.</p>')
    html_parts.append('    </section>')
    
    # Live Logs section
    html_parts.append('    <section aria-labelledby="log-heading">')
    html_parts.append('      <div class="section-title">')
    html_parts.append('        <h2 id="log-heading">LIVE-Logs</h2>')
    html_parts.append('        <span id="caption-count" class="count">0</span>')
    html_parts.append('      </div>')
    html_parts.append('      <div class="button-row">')
    html_parts.append('        <button id="export-log" class="secondary">JSON-L-Export</button>')
    html_parts.append('        <button id="export-caption-raw" class="secondary">RAW-JSON-Export</button>')
    html_parts.append('        <button id="clear" class="ghost">Anzeige leeren</button>')
    html_parts.append('      </div>')
    html_parts.append('      <div id="caption-list" class="list empty">Noch keine CaptionMessages empfangen.</div>')
    html_parts.append('    </section>')
    
    # Debug section
    html_parts.append('    <section aria-labelledby="debug-heading">')
    html_parts.append('      <div class="section-title">')
    html_parts.append('        <h2 id="debug-heading">Debugmodus</h2>')
    html_parts.append('        <span id="debug-count" class="count">0</span>')
    html_parts.append('      </div>')
    html_parts.append('      <label class="option-row"><input id="debug-enabled" type="checkbox"> Diagnoseereignisse für diesen Tab protokollieren</label>')
    html_parts.append('      <div class="button-row">')
    html_parts.append('        <button id="export-debug" class="secondary">Debug exportieren</button>')
    html_parts.append('        <button id="clear-debug" class="ghost">Debug leeren</button>')
    html_parts.append('      </div>')
    html_parts.append('      <p class="muted small"></p>')
    html_parts.append('    </section>')
    
    # Audience Modal
    html_parts.append('    <div id="audience-modal" class="modal-backdrop" hidden>')
    html_parts.append('      <section class="modal" role="dialog" aria-modal="true" aria-labelledby="audience-heading">')
    html_parts.append('        <div class="section-title">')
    html_parts.append('          <h2 id="audience-heading">Im Chat beobachtete Personen</h2>')
    html_parts.append('          <button id="close-audience" class="secondary compact" aria-label="Übersicht schließen">Schließen</button>')
    html_parts.append('        </div>')
    html_parts.append('        <p id="audience-limit" class="inline-status"></p>')
    html_parts.append('        <div id="audience-list" class="audience-list"></div>')
    html_parts.append('      </section>')
    html_parts.append('    </div>')
    
    # Speech Settings Modal
    html_parts.append('    <div id="speech-settings-modal" class="modal-backdrop" hidden>')
    html_parts.append('      <section class="modal" role="dialog" aria-modal="true" aria-labelledby="speech-settings-heading">')
    html_parts.append('        <div class="section-title">')
    html_parts.append('          <h2 id="speech-settings-heading">Sprach- und Chat Einstellungen</h2>')
    html_parts.append('          <button id="close-speech-settings" class="secondary compact" aria-label="Einstellungen schließen">Schließen</button>')
    html_parts.append('        </div>')
    html_parts.append('        <div class="settings-grid speech-integration-settings">')
    html_parts.append('          <label><span>Sprache</span><select id="speech-language"><option value="auto">Auto</option><option value="de-DE">Deutsch</option><option value="en-US">Englisch</option><option value="ru-RU">Russisch</option><option value="uk-UA">Ukrainisch</option><option value="bg-BG">Bulgarisch</option><option value="sr-RS">Serbisch</option><option value="kk-KZ">Kasachisch</option><option value="zh-CN">Chinesisch</option><option value="ja-JP">Japanisch</option><option value="ko-KR">Koreanisch</option><option value="ar-JO">Arabisch</option><option value="fa-IR">Persisch</option><option value="ur-PK">Urdu</option><option value="hi-IN">Hindi</option><option value="ne-NP">Nepali</option><option value="ml-IN">Malayalam</option></select></label>')
    html_parts.append('          <label><span>Stimme</span><select id="speech-voice"><option value="">Standard</option></select></label>')
    html_parts.append('          <label id="audd-token-setting"><span id="audd-token-label">AudD API-Token (optional - <a href="https://audd.io/" target="_blank" rel="noopener noreferrer">https://AudD.io</a> Trial/Paid)</span><input id="audd-token" type="password" autocomplete="off" spellcheck="false"></label>')
    html_parts.append('          <label id="pairing-code-setting"><span>Pairing-Code</span><input id="pairing-code" type="password" autocomplete="off" spellcheck="false"></label>')
    html_parts.append('          <label><span>Universal API-Key für Untertitel</span><input id="universal-caption-api-key" type="password" autocomplete="off" spellcheck="false"></label>')
    html_parts.append('        </div>')
    html_parts.append('        <label class="option-row"><input id="speak-names" type="checkbox" checked> Chatnamen sprechen</label>')
    html_parts.append('        <label class="option-row"><input id="shorten-names" type="checkbox"> Chatnamen kürzen</label>')
    html_parts.append('        <label class="option-row auto-chat-refresh"><input id="auto-chat-refresh" type="checkbox"> Auto-Chat Refresh <input id="auto-chat-refresh-minutes" type="number" min="1" max="60" step="1" value="5" inputmode="numeric" aria-label="Auto-Chat-Refresh in Minuten"><span>min.</span></label>')
    html_parts.append('        <label class="option-row"><input id="game-mode" type="checkbox"> Game-Mode</label>')
    html_parts.append('        <label class="option-row"><input id="filter-external-speech-triggers" type="checkbox"> Trigger externer Sprachdienste filtern</label>')
    html_parts.append('      </section>')
    html_parts.append('    </div>')
    
    # Chat History Modal
    html_parts.append('    <div id="chat-history-modal" class="modal-backdrop" hidden>')
    html_parts.append('      <section class="modal" role="dialog" aria-modal="true" aria-labelledby="chat-history-heading">')
    html_parts.append('        <div class="section-title">')
    html_parts.append('          <h2 id="chat-history-heading">Gesammelte Chatnachrichten</h2>')
    html_parts.append('          <button id="close-chat-history" class="secondary compact" aria-label="Chatzeilen schließen">Schließen</button>')
    html_parts.append('        </div>')
    html_parts.append('        <p id="chat-history-limit" class="inline-status"></p>')
    html_parts.append('        <div id="chat-history-list" class="chat-history-list"></div>')
    html_parts.append('      </section>')
    html_parts.append('    </div>')
    
    # Recommendation Modal
    html_parts.append('    <div id="recommendation-modal" class="modal-backdrop" hidden>')
    html_parts.append('      <section class="modal" role="dialog" aria-modal="true" aria-labelledby="recommendation-modal-heading">')
    html_parts.append('        <div class="section-title">')
    html_parts.append('          <h2 id="recommendation-modal-heading">Gescannte LIVE-Empfehlungen</h2>')
    html_parts.append('          <button id="close-recommendations" class="secondary compact" aria-label="Empfehlungen schließen">Schließen</button>')
    html_parts.append('        </div>')
    html_parts.append('        <div id="recommendation-modal-list" class="recommendation-list"></div>')
    html_parts.append('      </section>')
    html_parts.append('    </div>')
    
    # Notice
    html_parts.append('    <p id="notice" role="alert" class="notice"></p>')
    html_parts.append('  </main>')
    
    # Connection Settings Modal
    html_parts.append('  <div id="connection-settings-modal" class="modal-backdrop" hidden>')
    html_parts.append('    <section class="modal" role="dialog" aria-modal="true" aria-labelledby="connection-settings-heading">')
    html_parts.append('      <div class="section-title"><h2 id="connection-settings-heading">Connection-Einstellungen</h2><button id="close-connection-settings" class="secondary compact">Schließen</button></div>')
    html_parts.append('      <label class="option-row quick-recover-setting"><input id="hook-reconnect" type="checkbox"> Hook-Reconnect <input id="hook-reconnect-seconds" type="number" min="1" max="59" step="1" value="3" inputmode="numeric" aria-label="Hook-Reconnect-Wartezeit in Sekunden"><span>Sek.</span></label>')
    html_parts.append('      <label class="option-row quick-recover-setting"><input id="quick-recover" type="checkbox"> Player-Recovery <input id="quick-recover-seconds" type="number" min="1" max="59" step="1" value="3" inputmode="numeric" aria-label="Player-Recovery-Bestätigungszeit in Sekunden"><span>Sek.</span></label>')
    html_parts.append('    </section>')
    html_parts.append('  </div>')
    
    # Scripts
    html_parts.append('')
    html_parts.append('  <script src="content-core.js"></script>')
    html_parts.append('  <script src="sidepanel.js"></script>')
    html_parts.append('</body>')
    html_parts.append('</html>')
    
    return '\n'.join(html_parts)


def main():
    """Main function to write HTML to file or stdout."""
    if len(sys.argv) > 1:
        output_path = Path(sys.argv[1])
        try:
            with output_path.open('w', encoding='utf-8') as f:
                f.write(generate_html())
            print(f"HTML written to {output_path}")
        except Exception as e:
            print(f"Error writing to file: {e}", file=sys.stderr)
            sys.exit(1)
    else:
        print(generate_html())


if __name__ == "__main__":
    main()
