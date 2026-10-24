#!/usr/bin/env python3
# sidepanel.html — portiert nach python
# Quelle: html, Projects@TikTok-Live-Companion:plugin-source/browser-extension/sidepanel.html
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/sidepanel.html
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/sidepanel.html
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/browser-extension/sidepanel.html
# Erzeugt: 2026-10-24 durch ABSTRACTIONS_MANAGER.py

import sys
from html import escape
from typing import TextIO

def generate_html(output_file: TextIO) -> None:
    """Generate the complete HTML document for TikTok LIVE Companion sidepanel."""
    
    # Start of HTML document
    output_file.write('<!doctype html>\n')
    output_file.write('<html lang="de">\n')
    output_file.write('<head>\n')
    output_file.write('  <meta charset="utf-8">\n')
    output_file.write('  <meta name="viewport" content="width=device-width, initial-scale=1">\n')
    output_file.write('  <title>TikTok LIVE Companion</title>\n')
    output_file.write('  <link rel="stylesheet" href="sidepanel.css">\n')
    output_file.write('  <link rel="stylesheet" href="icon-controls.css">\n')
    output_file.write('</head>\n')
    output_file.write('<body>\n')
    
    # Header section
    output_file.write('  <header>\n')
    output_file.write('    <p id="page-title" class="muted">Kein TikTok-Tab ausgewählt</p>\n')
    output_file.write('  </header>\n\n')
    
    # Main content area
    output_file.write('  <main>\n')
    
    # Chat section
    output_file.write('    <section aria-labelledby="chat-heading">\n')
    output_file.write('      <div class="section-title">\n')
    output_file.write('        <h2 id="chat-heading">Chat</h2>\n')
    output_file.write('        <div class="title-actions">\n')
    output_file.write('          <span id="chat-led" class="status-led off" role="status" aria-label="Chat inaktiv" title="Chat inaktiv"></span>\n')
    output_file.write('          <button id="chat-count" class="count count-button" type="button" aria-haspopup="dialog" title="Gesammelte Chatzeilen öffnen">0</button>\n')
    output_file.write('          <button id="refresh-chat" class="secondary compact" title="Chatanzeige leeren">Reset</button>\n')
    output_file.write('          <button id="toggle-speech" class="secondary compact" aria-pressed="false" aria-label="Vorlesen">On</button>\n')
    output_file.write('          <span id="speech-led" class="status-led off" role="status" aria-label="Vorlesen inaktiv" title="Vorlesen inaktiv"></span>\n')
    output_file.write('        </div>\n')
    output_file.write('      </div>\n')
    output_file.write('      <div id="chat-list" class="chat-list empty" role="log" aria-live="polite" aria-relevant="additions" aria-label="Die letzten fünf bereinigten Chatnachrichten">Noch keine Chatnachrichten erkannt.</div>\n')
    output_file.write('      <p id="speech-status" role="status" class="inline-status">Vorlesen ist ausgeschaltet.</p>\n')
    output_file.write('      <div class="control-label"><label for="speech-volume">Vorleselautstärke</label><output id="speech-volume-output" for="speech-volume">100%</output></div>\n')
    output_file.write('      <input id="speech-volume" type="range" min="0" max="100" step="5" value="50">\n')
    output_file.write('      <div class="button-row">\n')
    output_file.write('        <button id="service-action" class="secondary">Sprachdienst</button>\n')
    output_file.write('        <button id="sherpa-action" class="secondary">Sherpa</button>\n')
    output_file.write('        <button id="open-speech-settings" class="secondary compact settings-button" type="button" aria-label="Erweiterte Einstellungen öffnen" aria-haspopup="dialog" title="Einstellungen"></button>\n')
    output_file.write('      </div>\n')
    output_file.write('      <p id="service-status" class="inline-status">Lokaler Sprachdienst noch nicht geprüft.</p>\n')
    output_file.write('      <div id="service-setup" class="inline-status" hidden>\n')
    output_file.write('        <button id="copy-service-setup" class="secondary compact">Installation abschließen!</button>\n')
    output_file.write('      </div>\n')
    output_file.write('    </section>\n\n')
    
    # Stats section
    output_file.write('    <section aria-labelledby="stats-heading">\n')
    output_file.write('      <div class="section-title">\n')
    output_file.write('        <h2 id="stats-heading">LIVE-Information</h2>\n')
    output_file.write('        <span id="stats-live" class="live-indicator">warte</span>\n')
    output_file.write('      </div>\n')
    output_file.write('      <div id="live-stats" class="status-grid stats-grid"></div>\n')
    output_file.write('      <p id="stats-status" class="inline-status"></p>\n')
    output_file.write('    </section>\n\n')
    
    # Page info section
    output_file.write('    <section id="page-info-section" aria-labelledby="page-info-heading">\n')
    output_file.write('      <div class="section-title">\n')
    output_file.write('        <h2 id="page-info-heading">PROFIL-Information</h2>\n')
    output_file.write('        <div class="title-actions">\n')
    output_file.write('          <span id="page-info-source" class="live-indicator">Metadaten</span>\n')
    output_file.write('          <button id="refresh-page-info" class="secondary compact" title="Refresh">Refresh</button>\n')
    output_file.write('          <button id="force-page-info" class="secondary compact danger-outline">Force</button>\n')
    output_file.write('        </div>\n')
    output_file.write('      </div>\n')
    output_file.write('      <div id="profile-info" class="profile-info" hidden></div>\n')
    output_file.write('      <div id="summary-info" class="summary-info"></div>\n')
    output_file.write('    </section>\n\n')
    
    # Connection section
    output_file.write('    <section aria-labelledby="hook-heading">\n')
    output_file.write('      <div class="section-title header-controls">\n')
    output_file.write('        <h2 id="hook-heading">Connection</h2>\n')
    output_file.write('        <div class="title-actions">\n')
    output_file.write('          <button id="reset-tab" class="secondary compact danger-outline" title="Reset">Reset</button>\n')
    output_file.write('          <input id="hook-autostart" type="checkbox" aria-label="Hook dauerhaft" title="Hook dauerhaft: Off">\n')
    output_file.write('          <span class="status-led off" data-switch-status="hook-autostart" role="status"></span>\n')
    output_file.write('        </div>\n')
    output_file.write('      </div>\n')
    output_file.write('      <div class="button-row">\n')
    output_file.write('        <button id="toggle-hook" class="primary" aria-label="Connection" aria-pressed="false">On</button>\n')
    output_file.write('        <button id="open-connection-settings" class="secondary compact settings-button" type="button" aria-label="Connection-Einstellungen öffnen" aria-haspopup="dialog"></button>\n')
    output_file.write('        <button id="open-embed-live" class="secondary">Embed</button>\n')
    output_file.write('        <button id="open-normal-live" class="secondary">Browser</button>\n')
    output_file.write('        <button id="player-vlc-frame" class="secondary compact">Player</button>\n')
    output_file.write('      </div>\n')
    output_file.write('      <div class="connection-status"><span id="hook-led" class="status-led off" role="status" aria-label="Hook inaktiv" title="Hook inaktiv"></span><p id="hook-status" class="inline-status"></p></div>\n')
    output_file.write('      <p id="embed-startup-status" class="inline-status" role="status" aria-live="polite" hidden></p>\n')
    output_file.write('      <button id="cancel-embed-startup" class="secondary" hidden>Embed-Start abbrechen</button>\n')
    output_file.write('      <p id="hook-reconnect-status" class="inline-status" role="status">Hook-Reconnect: aus</p>\n')
    output_file.write('      <p id="player-recovery-status" class="inline-status" role="status">Player-Recovery: aus</p>\n')
    output_file.write('    </section>\n\n')
    
    # Player section
    output_file.write('    <section aria-labelledby="player-heading">\n')
    output_file.write('      <div class="section-title header-controls">\n')
    output_file.write('        <h2 id="player-heading">Player</h2>\n')
    output_file.write('        <div class="title-actions">\n')
    output_file.write('          <button id="player-replay" class="secondary compact" title="Neu laden">Neu laden</button>\n')
    output_file.write('          <input id="limiter-enabled" type="checkbox" aria-label="Pegelschutz" title="Pegelschutz: Off">\n')
    output_file.write('          <span class="status-led off" data-switch-status="limiter-enabled" role="status"></span>\n')
    output_file.write('        </div>\n')
    output_file.write('      </div>\n')
    output_file.write('      <div class="player-controls" role="group" aria-label="TikTok-Player steuern">\n')
    output_file.write('        <button id="player-play" class="secondary compact">Play</button>\n')
    output_file.write('        <button id="player-mute" class="secondary compact">Mute</button>\n')
    output_file.write('        <button id="player-pip" class="secondary compact">Bild-in-Bild</button>\n')
    output_file.write('        <button id="player-fullscreen" class="secondary compact">Vollbild</button>\n')
    output_file.write('        <button id="player-report" class="secondary compact danger-outline">Meldung</button>\n')
    output_file.write('      </div>\n')
    output_file.write('      <div class="audio-controls">\n')
    output_file.write('        <div class="control-label"><label for="player-volume">Lautstärke</label><output id="player-volume-output" for="player-volume">–</output></div>\n')
    output_file.write('        <input id="player-volume" type="range" min="0" max="100" step="1" value="100">\n')
    output_file.write('        <div class="audio-meter-row"><span>Spitzenpegel</span><strong id="player-peak">–</strong></div>\n')
    output_file.write('        <div class="control-label"><label for="limiter-strength">Schutzstärke</label><output id="limiter-strength-output" for="limiter-strength">30</output></div>\n')
    output_file.write('        <input id="limiter-strength" type="range" min="0" max="100" step="1" value="30">\n')
    output_file.write('      </div>\n')
    output_file.write('      <p id="multi-guest-status" class="inline-status">Verbundene Streams: noch nicht erkannt.</p>\n')
    output_file.write('      <p id="player-status" role="status" class="inline-status">Warte auf den TikTok-Player.</p>\n')
    output_file.write('      <span id="player-time" class="player-time" hidden>–</span>\n')
    output_file.write('    </section>\n\n')
    
    # Top chatters section
    output_file.write('    <section aria-labelledby="top-chatters-heading">\n')
    output_file.write('      <div class="section-title">\n')
    output_file.write('        <h2 id="top-chatters-heading">Top-Chatter</h2>\n')
    output_file.write('        <button id="open-audience" class="secondary compact">Zuschauer*innen</button>\n')
    output_file.write('      </div>\n')
    output_file.write('      <p id="team-tag-status" class="inline-status">Teamkürzel: noch nicht erkannt.</p>\n')
    output_file.write('      <div id="top-chatters" class="top-chatters empty">Noch keine Personen im Chat beobachtet.</div>\n')
    output_file.write('      <div id="top-chatters-actions" class="top-chatters-actions" hidden>\n')
    output_file.write('        <button id="top-chatters-reset" class="top-chatter-link" type="button" hidden>Reset</button>\n')
    output_file.write('        <button id="top-chatters-more" class="top-chatter-link" type="button">mehr…</button>\n')
    output_file.write('      </div>\n')
    output_file.write('    </section>\n\n')
    
    # Recommendations section
    output_file.write('    <section id="recommendations-section" aria-labelledby="recommendations-heading">\n')
    output_file.write('      <div class="section-title">\n')
    output_file.write('        <h2 id="recommendations-heading">LIVE-Empfehlungen</h2>\n')
    output_file.write('        <span id="recommendation-status" class="live-indicator">bereit</span>\n')
    output_file.write('      </div>\n')
    output_file.write('      <div class="recommendation-controls">\n')
    output_file.write('        <label><span>Anzahl</span><input id="recommendation-limit" type="number" min="1" max="300" step="1" value="20" inputmode="numeric"></label>\n')
    output_file.write('        <label><span>Sortierung</span><select id="recommendation-sort"><option value="tiktok">TikTok-Reihenfolge</option><option value="viewers">Zuschauer*innen</option></select></label>\n')
    output_file.write('      </div>\n')
    output_file.write('      <div class="button-row">\n')
    output_file.write('        <button id="scan-recommendations" class="primary">Empfehlungen scannen</button>\n')
    output_file.write('        <button id="cancel-recommendations" class="secondary" hidden>Abbrechen</button>\n')
    output_file.write('      </div>\n')
    output_file.write('      <p id="recommendation-progress" class="inline-status" aria-live="polite">Noch kein Scan gestartet.</p>\n')
    output_file.write('      <div id="recommendation-list" class="recommendation-list empty">Noch keine Empfehlungen erfasst.</div>\n')
    output_file.write('      <div id="recommendation-actions" class="top-chatters-actions" hidden>\n')
    output_file.write('        <button id="recommendation-more" class="top-chatter-link" type="button">mehr…</button>\n')
    output_file.write('      </div>\n')
    output_file.write('    </section>\n\n')
    
    # Caption section
    output_file.write('    <section aria-labelledby="caption-heading">\n')
    output_file.write('      <div class="section-title">\n')
    output_file.write('        <h2 id="caption-heading">Titel</h2>\n')
    output_file.write('        <button id="scan" class="secondary">Status</button>\n')
    output_file.write('      </div>\n')
    output_file.write('      <div id="caption-status" class="status-grid"></div>\n')
    output_file.write('      <button id="enable-captions" class="primary">Untertitel</button>\n')
    output_file.write('      <p id="caption-action-status" role="status" class="inline-status action-status"></p>\n')
    output_file.write('    </section>\n\n')
    
    # Song section
    output_file.write('    <section aria-labelledby="song-heading">\n')
    output_file.write('      <div class="section-title header-controls">\n')
    output_file.write('        <h2 id="song-heading">Songs</h2>\n')
    output_file.write('        <div class="title-actions">\n')
    output_file.write('          <input id="song-enabled" type="checkbox" aria-label="Songerkennung" title="Songerkennung: Off">\n')
    output_file.write('          <span id="song-led" class="status-led off" data-switch-status="song-enabled" role="status" aria-label="Songerkennung inaktiv"></span>\n')
    output_file.write('        </div>\n')
    output_file.write('      </div>\n')
    output_file.write('      <button id="recognize-song" class="primary" disabled>Jetzt erkennen</button>\n')
    output_file.write('      <p id="song-status" class="inline-status"></p>\n')
    output_file.write('      <div id="song-result" class="song-result" hidden></div>\n')
    output_file.write('    </section>\n\n')
    
    # Links section
    output_file.write('    <section aria-labelledby="links-heading">\n')
    output_file.write('      <div class="section-title">\n')
    output_file.write('        <h2 id="links-heading">HAR-Logs</h2>\n')
    output_file.write('        <span id="media-count" class="count">0</span>\n')
    output_file.write('      </div>\n')
    output_file.write('      <div id="media-list" class="list empty">Noch keine FLV-/HLS-Links erkannt.</div>\n')
    output_file.write('    </section>\n\n')
    
    # Log section
    output_file.write('    <section aria-labelledby="log-heading">\n')
    output_file.write('      <div class="section-title header-controls">\n')
    output_file.write('        <h2 id="log-heading">LIVE-Logs</h2>\n')
    output_file.write('        <div class="title-actions">\n')
    output_file.write('          <span class="status-led off" data-counter-status="caption-count" role="status"></span>\n')
    output_file.write('          <span id="caption-count" class="count">0</span>\n')
    output_file.write('          <button id="clear" class="ghost compact" title="Reset">Reset</button>\n')
    output_file.write('          <input id="live-logs-enabled" type="checkbox" aria-label="LIVE-Logs" title="LIVE-Logs: Off">\n')
    output_file.write('          <span class="status-led off" data-switch-status="live-logs-enabled" role="status" aria-label="LIVE-Logs: deaktiviert"></span>\n')
    output_file.write('        </div>\n')
    output_file.write('      </div>\n')
    output_file.write('      <div class="button-row">\n')
    output_file.write('        <button id="export-log" class="secondary">JSON-L-Export</button>\n')
    output_file.write('        <button id="export-caption-raw" class="secondary">RAW-JSON-Export</button>\n')
    output_file.write('      </div>\n')
    output_file.write('      <div id="caption-list" class="list empty">Noch keine CaptionMessages empfangen.</div>\n')
    output_file.write('    </section>\n\n')
    
    # Debug section
    output_file.write('    <section aria-labelledby="debug-heading">\n')
    output_file.write('      <div class="section-title header-controls">\n')
    output_file.write('        <h2 id="debug-heading">Debugmodus</h2>\n')
    output_file.write('        <div class="title-actions">\n')
    output_file.write('          <span class="status-led off" data-counter-status="debug-count" role="status"></span>\n')
    output_file.write('          <span id="debug-count" class="count">0</span>\n')
    output_file.write('          <button id="clear-debug" class="ghost compact" title="Reset">Reset</button>\n')
    output_file.write('          <input id="debug-enabled" type="checkbox" aria-label="Diagnoseereignisse für diesen Tab protokollieren" title="Diagnoseereignisse für diesen Tab protokollieren: Off">\n')
    output_file.write('          <span class="status-led off" data-switch-status="debug-enabled" role="status"></span>\n')
    output_file.write('        </div>\n')
    output_file.write('      </div>\n')
    output_file.write('      <div class="button-row">\n')
    output_file.write('        <button id="export-debug" class="secondary">Debug exportieren</button>\n')
    output_file.write('      </div>\n')
    output_file.write('      <p class="muted small"></p>\n')
    output_file.write('    </section>\n\n')
    
    # Audience modal
    output_file.write('    <div id="audience-modal" class="modal-backdrop" hidden>\n')
    output_file.write('      <section class="modal" role="dialog" aria-modal="true" aria-labelledby="audience-heading">\n')
    output_file.write('        <div class="section-title">\n')
    output_file.write('          <h2 id="audience-heading">Im Chat beobachtete Personen</h2>\n')
    output_file.write('          <button id="close-audience" class="secondary compact" aria-label="Übersicht schließen">Schließen</button>\n')
    output_file.write('        </div>\n')
    output_file.write('        <p id="audience-limit" class="inline-status"></p>\n')
    output_file.write('        <div id="audience-list" class="audience-list"></div>\n')
    output_file.write('      </section>\n')
    output_file.write('    </div>\n\n')
    
    # Speech settings modal
    output_file.write('    <div id="speech-settings-modal" class="modal-backdrop" hidden>\n')
    output_file.write('      <section class="modal" role="dialog" aria-modal="true" aria-labelledby="speech-settings-heading">\n')
    output_file.write('        <div class="section-title">\n')
    output_file.write('          <h2 id="speech-settings-heading">Erweiterte Einstellungen</h2>\n')
    output_file.write('          <button id="close-speech-settings" class="secondary compact" aria-label="Einstellungen schließen">Schließen</button>\n')
    output_file.write('        </div>\n')
    output_file.write('        <div class="settings-grid speech-integration-settings">\n')
    output_file.write('<label class="icon-style-setting"><span>Icon-Stil</span><select id="icon-style"><option value="plastisch">3D / Plastisch</option><option value="glass">Glass / Realistisch</option><option value="linear">Minimal / Linear</option></select></label>\n')
    output_file.write('          <label><span>Sprache</span><select id="speech-language"><option value="auto">Auto</option><option value="de-DE">Deutsch</option><option value="en-US">Englisch</option><option value="ru-RU">Russisch</option><option value="uk-UA">Ukrainisch</option><option value="bg-BG">Bulgarisch</option><option value="sr-RS">Serbisch</option><option value="kk-KZ">Kasachisch</option><option value="zh-CN">Chinesisch</option><option value="ja-JP">Japanisch</option><option value="ko-KR">Koreanisch</option><option value="ar-JO">Arabisch</option><option value="fa-IR">Persisch</option><option value="ur-PK">Urdu</option><option value="hi-IN">Hindi</option><option value="ne-NP">Nepali</option><option value="ml-IN">Malayalam</option></select></label>\n')
    output_file.write('          <label><span>Stimme</span><select id="speech-voice"><option value="">Standard</option></select></label>\n')
    output_file.write('          <label id="audd-token-setting"><span id="audd-token-label">AudD API-Token (optional - <a href="https://audd.io/" target="_blank" rel="noopener noreferrer">https://AudD.io</a> Trial/Paid)</span><input id="audd-token" type="password" autocomplete="off" spellcheck="false"></label>\n')
    output_file.write('          <label id="pairing-code-setting"><span>Pairing-Code</span><input id="pairing-code" type="password" autocomplete="off" spellcheck="false"></label>\n')
    output_file.write('          <label><span>Universal API-Key</span><input id="universal-caption-api-key" type="password" autocomplete="off" spellcheck="false"></label>\n')
    output_file.write('        </div>\n')
    output_file.write('        <label class="option-row"><input id="speak-names" type="checkbox" checked> Chatnamen sprechen</label>\n')
    output_file.write('        <label class="option-row"><input id="shorten-names" type="checkbox"> Chatnamen kürzen</label>\n')
    output_file.write('        <label class="option-row auto-chat-refresh"><input id="auto-chat-refresh" type="checkbox"> Auto-Chat Refresh <input id="auto-chat-refresh-minutes" type="number" min="1" max="60" step="1" value="5" inputmode="numeric" aria-label="Auto-Chat-Refresh in Minuten"><span>min.</span></label>\n')
    output_file.write('        <label class="option-row"><input id="game-mode" type="checkbox"> Game-Mode (Spam-, Emoji, usw. Chatfilter)</label>\n')
    output_file.write('        <div class="option-row external-speech-trigger-row"><label><input id="filter-external-speech-triggers" type="checkbox"> Trigger filtern (ext. Sprachdienste)</label><input id="external-speech-trigger-characters" type="text" value="." maxlength="10" aria-label="Triggerzeichen, maximal fünf Sonderzeichen" autocomplete="off" spellcheck="false"></div>\n')
    output_file.write('        <label class="option-row"><input id="keep-speech-active" type="checkbox" aria-label="Vorlesen dauerhaft" title="Vorlesen dauerhaft: Off"> Vorlesen dauerhaft</label>\n')
    output_file.write('      </section>\n')
    output_file.write('    </div>\n\n')
    
    # Chat history modal
    output_file.write('    <div id="chat-history-modal" class="modal-backdrop" hidden>\n')
    output_file.write('      <section class="modal" role="dialog" aria-modal="true" aria-labelledby="chat-history-heading">\n')
    output_file.write('        <div class="section-title">\n')
    output_file.write('          <h2 id="chat-history-heading">Gesammelte Chatnachrichten</h2>\n')
    output_file.write('          <button id="close-chat-history" class="secondary compact" aria-label="Chatzeilen schließen">Schließen</button>\n')
    output_file.write('        </div>\n')
    output_file.write('        <p id="chat-history-limit" class="inline-status"></p>\n')
    output_file.write('        <div id="chat-history-list" class="chat-history-list"></div>\n')
    output_file.write('      </section>\n')
    output_file.write('    </div>\n\n')
    
    # Recommendation modal
    output_file.write('    <div id="recommendation-modal" class="modal-backdrop" hidden>\n')
    output_file.write('      <section class="modal" role="dialog" aria-modal="true" aria-labelledby="recommendation-modal-heading">\n')
    output_file.write('        <div class="section-title">\n')
    output_file.write('          <h2 id="recommendation-modal-heading">Gescannte LIVE-Empfehlungen</h2>\n')
    output_file.write('          <button id="close-recommendations" class="secondary compact" aria-label="Empfehlungen schließen">Schließen</button>\n')
    output_file.write('        </div>\n')
    output_file.write('        <div id="recommendation-modal-list" class="recommendation-list"></div>\n')
    output_file.write('      </section>\n')
    output_file.write('    </div>\n\n')
    
    # Notice paragraph
    output_file.write('    <p id="notice" role="alert" class="notice"></p>\n')
    output_file.write('  </main>\n')
    
    # Connection settings modal
    output_file.write('  <div id="connection-settings-modal" class="modal-backdrop" hidden>\n')
    output_file.write('    <section class="modal" role="dialog" aria-modal="true" aria-labelledby="connection-settings-heading">\n')
    output_file.write('      <div class="section-title"><h2 id="connection-settings-heading">Connection-Einstellungen</h2><button id="close-connection-settings" class="secondary compact">Schließen</button></div>\n')
    output_file.write('      <label class="option-row quick-recover-setting"><input id="hook-reconnect" type="checkbox"> Hook-Reconnect <input id="hook-reconnect-seconds" type="number" min="1" max="59" step="1" value="3" inputmode="numeric" aria-label="Hook-Reconnect-Wartezeit in Sekunden"><span>Sek.</span></label>\n')
    output_file.write('      <label class="option-row quick-recover-setting"><input id="quick-recover" type="checkbox"> Player-Recovery <input id="quick-recover-seconds" type="number" min="1" max="59" step="1" value="3" inputmode="numeric" aria-label="Player-Recovery-Bestätigungszeit in Sekunden"><span>Sek.</span></label>\n')
    output_file.write('    </section>\n')
    output_file.write('  </div>\n\n')
    
    # Script tags
    output_file.write('  <script src="content-core.js"></script>\n')
    output_file.write('  <script src="sidepanel.js"></script>\n')
    output_file.write('  <script src="icon-controls.js"></script>\n')
    
    # End of HTML document
    output_file.write('</body>\n')
    output_file.write('</html>\n')

def main() -> None:
    """Main function to write HTML to file or stdout."""
    if len(sys.argv) > 1:
        with open(sys.argv[1], 'w', encoding='utf-8') as f:
            generate_html(f)
    else:
        generate_html(sys.stdout)

if __name__ == '__main__':
    main()
