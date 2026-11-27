#!/usr/bin/env tclsh
# abstraction-provenance: {"artifact_sha256": "fb02710eec0b1c97d14c1a233b24da0d27343e667f595719d116daaacb4ff916", "source_sha256": "6c68f7375733776fa70f0fd1e48fe739ffdf7c38b6444a8ef7c36fd50e4d08e9", "target_language": "tcl"}
# sidepanel.html — portiert nach tcl
# Quelle: html, Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/sidepanel.html
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/sidepanel.html
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/browser-extension/sidepanel.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

# Tcl/Tk port of sidepanel.html
# Generates the HTML structure programmatically

proc generate_sidepanel_html {} {
    set html {}
    
    # Start with DOCTYPE and basic structure
    append html {<!doctype html>}
    append html "\n" {<html lang="de">}
    append html "\n" {<head>}
    append html "\n  " {<meta charset="utf-8">}
    append html "\n  " {<meta name="viewport" content="width=device-width, initial-scale=1">}
    append html "\n  " {<title>TikTok LIVE Companion</title>}
    append html "\n  " {<link rel="stylesheet" href="sidepanel.css">}
    append html "\n  " {<link rel="stylesheet" href="icon-controls.css">}
    append html "\n" {</head>}
    append html "\n" {<body>}
    
    # Header section
    append html "\n  " {<header>}
    append html "\n    " {<p id="page-title" class="muted">Kein TikTok-Tab ausgewählt</p>}
    append html "\n  " {</header>}
    
    # Main content
    append html "\n  " {<main>}
    
    # Chat section
    append html "\n    " {<section aria-labelledby="chat-heading">}
    append html "\n      " {<div class="section-title">}
    append html "\n        " {<h2 id="chat-heading">Chat</h2>}
    append html "\n        " {<div class="title-actions">}
    append html "\n          " {<span id="chat-led" class="status-led off" role="status" aria-label="Chat inaktiv" title="Chat inaktiv"></span>}
    append html "\n          " {<button id="chat-count" class="count count-button" type="button" aria-haspopup="dialog" title="Gesammelte Chatzeilen öffnen">0</button>}
    append html "\n          " {<button id="refresh-chat" class="secondary compact" title="Chatanzeige leeren">Reset</button>}
    append html "\n          " {<button id="toggle-speech" class="secondary compact" aria-pressed="false" aria-label="Vorlesen">On</button>}
    append html "\n          " {<span id="speech-led" class="status-led off" role="status" aria-label="Vorlesen inaktiv" title="Vorlesen inaktiv"></span>}
    append html "\n        " {</div>}
    append html "\n      " {</div>}
    append html "\n      " {<div id="chat-list" class="chat-list empty" role="log" aria-live="polite" aria-relevant="additions" aria-label="Die letzten fünf bereinigten Chatnachrichten">Noch keine Chatnachrichten erkannt.</div>}
    append html "\n      " {<p id="speech-status" role="status" class="inline-status">Vorlesen ist ausgeschaltet.</p>}
    append html "\n      " {<div class="control-label"><label for="speech-volume">Vorleselautstärke</label><output id="speech-volume-output" for="speech-volume">100%</output></div>}
    append html "\n      " {<input id="speech-volume" type="range" min="0" max="100" step="5" value="50">}
    append html "\n      " {<div class="button-row">}
    append html "\n        " {<button id="service-action" class="secondary">Sprachdienst</button>}
    append html "\n        " {<button id="sherpa-action" class="secondary">Sherpa</button>}
    append html "\n        " {<button id="open-speech-settings" class="secondary compact settings-button" type="button" aria-label="Erweiterte Einstellungen öffnen" aria-haspopup="dialog" title="Einstellungen"></button>}
    append html "\n      " {</div>}
    append html "\n      " {<p id="service-status" class="inline-status">Lokaler Sprachdienst noch nicht geprüft.</p>}
    append html "\n      " {<div id="service-setup" class="inline-status" hidden>}
    append html "\n        " {<button id="copy-service-setup" class="secondary compact">Installation abschließen!</button>}
    append html "\n      " {</div>}
    append html "\n    " {</section>}
    
    # Stats section
    append html "\n    " {<section aria-labelledby="stats-heading">}
    append html "\n      " {<div class="section-title">}
    append html "\n        " {<h2 id="stats-heading">LIVE-Information</h2>}
    append html "\n        " {<span id="stats-live" class="live-indicator">warte</span>}
    append html "\n      " {</div>}
    append html "\n      " {<div id="live-stats" class="status-grid stats-grid"></div>}
    append html "\n      " {<p id="stats-status" class="inline-status"></p>}
    append html "\n    " {</section>}
    
    # Page info section
    append html "\n    " {<section id="page-info-section" aria-labelledby="page-info-heading">}
    append html "\n      " {<div class="section-title">}
    append html "\n        " {<h2 id="page-info-heading">PROFIL-Information</h2>}
    append html "\n        " {<div class="title-actions">}
    append html "\n          " {<span id="page-info-source" class="live-indicator">Metadaten</span>}
    append html "\n          " {<button id="refresh-page-info" class="secondary compact" title="Refresh">Refresh</button>}
    append html "\n          " {<button id="force-page-info" class="secondary compact danger-outline">Force</button>}
    append html "\n        " {</div>}
    append html "\n      " {</div>}
    append html "\n      " {<div id="profile-info" class="profile-info" hidden></div>}
    append html "\n      " {<div id="summary-info" class="summary-info"></div>}
    append html "\n    " {</section>}
    
    # Connection section
    append html "\n    " {<section aria-labelledby="hook-heading">}
    append html "\n      " {<div class="section-title header-controls">}
    append html "\n        " {<h2 id="hook-heading">Connection</h2>}
    append html "\n        " {<div class="title-actions">}
    append html "\n          " {<button id="reset-tab" class="secondary compact danger-outline" title="Reset">Reset</button>}
    append html "\n          " {<input id="hook-autostart" type="checkbox" aria-label="Hook dauerhaft" title="Hook dauerhaft: Off">}
    append html "\n          " {<span class="status-led off" data-switch-status="hook-autostart" role="status"></span>}
    append html "\n        " {</div>}
    append html "\n      " {</div>}
    append html "\n      " {<div class="button-row">}
    append html "\n        " {<button id="toggle-hook" class="primary" aria-label="Connection" aria-pressed="false">On</button>}
    append html "\n        " {<button id="open-connection-settings" class="secondary compact settings-button" type="button" aria-label="Connection-Einstellungen öffnen" aria-haspopup="dialog"></button>}
    append html "\n        " {<button id="open-embed-live" class="secondary">Embed</button>}
    append html "\n        " {<button id="open-normal-live" class="secondary">Browser</button>}
    append html "\n        " {<button id="player-vlc-frame" class="secondary compact">Player</button>}
    append html "\n      " {</div>}
    append html "\n      " {<div class="connection-status"><span id="hook-led" class="status-led off" role="status" aria-label="Hook inaktiv" title="Hook inaktiv"></span><p id="hook-status" class="inline-status"></p></div>}
    append html "\n      " {<p id="embed-startup-status" class="inline-status" role="status" aria-live="polite" hidden></p>}
    append html "\n      " {<button id="cancel-embed-startup" class="secondary" hidden>Embed-Start abbrechen</button>}
    append html "\n      " {<p id="hook-reconnect-status" class="inline-status" role="status">Hook-Reconnect: aus</p>}
    append html "\n      " {<p id="player-recovery-status" class="inline-status" role="status">Player-Recovery: aus</p>}
    append html "\n    " {</section>}
    
    # Player section
    append html "\n    " {<section aria-labelledby="player-heading">}
    append html "\n      " {<div class="section-title header-controls">}
    append html "\n        " {<h2 id="player-heading">Player</h2>}
    append html "\n        " {<div class="title-actions">}
    append html "\n          " {<button id="player-replay" class="secondary compact" title="Neu laden">Neu laden</button>}
    append html "\n          " {<input id="limiter-enabled" type="checkbox" aria-label="Pegelschutz" title="Pegelschutz: Off">}
    append html "\n          " {<span class="status-led off" data-switch-status="limiter-enabled" role="status"></span>}
    append html "\n        " {</div>}
    append html "\n      " {</div>}
    append html "\n      " {<div class="player-controls" role="group" aria-label="TikTok-Player steuern">}
    append html "\n        " {<button id="player-play" class="secondary compact">Play</button>}
    append html "\n        " {<button id="player-mute" class="secondary compact">Mute</button>}
    append html "\n        " {<button id="player-pip" class="secondary compact">Bild-in-Bild</button>}
    append html "\n        " {<button id="player-fullscreen" class="secondary compact">Vollbild</button>}
    append html "\n        " {<button id="player-report" class="secondary compact danger-outline">Meldung</button>}
    append html "\n      " {</div>}
    append html "\n      " {<div class="audio-controls">}
    append html "\n        " {<div class="control-label"><label for="player-volume">Lautstärke</label><output id="player-volume-output" for="player-volume">–</output></div>}
    append html "\n        " {<input id="player-volume" type="range" min="0" max="100" step="1" value="100">}
    append html "\n        " {<div class="audio-meter-row"><span>Spitzenpegel</span><strong id="player-peak">–</strong></div>}
    append html "\n        " {<div class="control-label"><label for="limiter-strength">Schutzstärke</label><output id="limiter-strength-output" for="limiter-strength">30</output></div>}
    append html "\n        " {<input id="limiter-strength" type="range" min="0" max="100" step="1" value="30">}
    append html "\n      " {</div>}
    append html "\n      " {<p id="multi-guest-status" class="inline-status">Verbundene Streams: noch nicht erkannt.</p>}
    append html "\n      " {<p id="player-status" role="status" class="inline-status">Warte auf den TikTok-Player.</p>}
    append html "\n      " {<span id="player-time" class="player-time" hidden>–</span>}
    append html "\n    " {</section>}
    
    # Top chatters section
    append html "\n    " {<section aria-labelledby="top-chatters-heading">}
    append html "\n      " {<div class="section-title">}
    append html "\n        " {<h2 id="top-chatters-heading">Top-Chatter</h2>}
    append html "\n        " {<button id="open-audience" class="secondary compact">Zuschauer*innen</button>}
    append html "\n      " {</div>}
    append html "\n      " {<p id="team-tag-status" class="inline-status">Teamkürzel: noch nicht erkannt.</p>}
    append html "\n      " {<div id="top-chatters" class="top-chatters empty">Noch keine Personen im Chat beobachtet.</div>}
    append html "\n      " {<div id="top-chatters-actions" class="top-chatters-actions" hidden>}
    append html "\n        " {<button id="top-chatters-reset" class="top-chatter-link" type="button" hidden>Reset</button>}
    append html "\n        " {<button id="top-chatters-more" class="top-chatter-link" type="button">mehr…</button>}
    append html "\n      " {</div>}
    append html "\n    " {</section>}
    
    # Recommendations section
    append html "\n    " {<section id="recommendations-section" aria-labelledby="recommendations-heading">}
    append html "\n      " {<div class="section-title">}
    append html "\n        " {<h2 id="recommendations-heading">LIVE-Empfehlungen</h2>}
    append html "\n        " {<span id="recommendation-status" class="live-indicator">bereit</span>}
    append html "\n      " {</div>}
    append html "\n      " {<div class="recommendation-controls">}
    append html "\n        " {<label><span>Anzahl</span><input id="recommendation-limit" type="number" min="1" max="300" step="1" value="20" inputmode="numeric"></label>}
    append html "\n        " {<label><span>Sortierung</span><select id="recommendation-sort"><option value="tiktok">TikTok-Reihenfolge</option><option value="viewers">Zuschauer*innen</option></select></label>}
    append html "\n      " {</div>}
    append html "\n      " {<div class="button-row">}
    append html "\n        " {<button id="scan-recommendations" class="primary">Empfehlungen scannen</button>}
    append html "\n        " {<button id="cancel-recommendations" class="secondary" hidden>Abbrechen</button>}
    append html "\n      " {</div>}
    append html "\n      " {<p id="recommendation-progress" class="inline-status" aria-live="polite">Noch kein Scan gestartet.</p>}
    append html "\n      " {<div id="recommendation-list" class="recommendation-list empty">Noch keine Empfehlungen erfasst.</div>}
    append html "\n      " {<div id="recommendation-actions" class="top-chatters-actions" hidden>}
    append html "\n        " {<button id="recommendation-more" class="top-chatter-link" type="button">mehr…</button>}
    append html "\n      " {</div>}
    append html "\n    " {</section>}
    
    # Caption section
    append html "\n    " {<section aria-labelledby="caption-heading">}
    append html "\n      " {<div class="section-title">}
    append html "\n        " {<h2 id="caption-heading">Titel</h2>}
    append html "\n        " {<button id="scan" class="secondary">Status</button>}
    append html "\n      " {</div>}
    append html "\n      " {<div id="caption-status" class="status-grid"></div>}
    append html "\n      " {<button id="enable-captions" class="primary">Untertitel</button>}
    append html "\n      " {<p id="caption-action-status" role="status" class="inline-status action-status"></p>}
    append html "\n    " {</section>}
    
    # Song section
    append html "\n    " {<section aria-labelledby="song-heading">}
    append html "\n      " {<div class="section-title header-controls">}
    append html "\n        " {<h2 id="song-heading">Songs</h2>}
    append html "\n        " {<div class="title-actions">}
    append html "\n          " {<input id="song-enabled" type="checkbox" aria-label="Songerkennung" title="Songerkennung: Off">}
    append html "\n          " {<span id="song-led" class="status-led off" data-switch-status="song-enabled" role="status" aria-label="Songerkennung inaktiv"></span>}
    append html "\n        " {</div>}
    append html "\n      " {</div>}
    append html "\n      " {<button id="recognize-song" class="primary" disabled>Jetzt erkennen</button>}
    append html "\n      " {<p id="song-status" class="inline-status"></p>}
    append html "\n      " {<div id="song-result" class="song-result" hidden></div>}
    append html "\n    " {</section>}
    
    # Links section
    append html "\n    " {<section aria-labelledby="links-heading">}
    append html "\n      " {<div class="section-title">}
    append html "\n        " {<h2 id="links-heading">HAR-Logs</h2>}
    append html "\n        " {<span id="media-count" class="count">0</span>}
    append html "\n      " {</div>}
    append html "\n      " {<div id="media-list" class="list empty">Noch keine FLV-/HLS-Links erkannt.</div>}
    append html "\n    " {</section>}
    
    # Log section
    append html "\n    " {<section aria-labelledby="log-heading">}
    append html "\n      " {<div class="section-title header-controls">}
    append html "\n        " {<h2 id="log-heading">LIVE-Logs</h2>}
    append html "\n        " {<div class="title-actions">}
    append html "\n          " {<span class="status-led off" data-counter-status="caption-count" role="status"></span>}
    append html "\n          " {<span id="caption-count" class="count">0</span>}
    append html "\n          " {<button id="clear" class="ghost compact" title="Reset">Reset</button>}
    append html "\n          " {<input id="live-logs-enabled" type="checkbox" aria-label="LIVE-Logs" title="LIVE-Logs: Off">}
    append html "\n          " {<span class="status-led off" data-switch-status="live-logs-enabled" role="status" aria-label="LIVE-Logs: deaktiviert"></span>}
    append html "\n        " {</div>}
    append html "\n      " {</div>}
    append html "\n      " {<div class="button-row">}
    append html "\n        " {<button id="export-log" class="secondary">JSON-L-Export</button>}
    append html "\n        " {<button id="export-caption-raw" class="secondary">RAW-JSON-Export</button>}
    append html "\n      " {</div>}
    append html "\n      " {<div id="caption-list" class="list empty">Noch keine CaptionMessages empfangen.</div>}
    append html "\n    " {</section>}
    
    # Debug section
    append html "\n    " {<section aria-labelledby="debug-heading">}
    append html "\n      " {<div class="section-title header-controls">}
    append html "\n        " {<h2 id="debug-heading">Debugmodus</h2>}
    append html "\n        " {<div class="title-actions">}
    append html "\n          " {<span class="status-led off" data-counter-status="debug-count" role="status"></span>}
    append html "\n          " {<span id="debug-count" class="count">0</span>}
    append html "\n          " {<button id="clear-debug" class="ghost compact" title="Reset">Reset</button>}
    append html "\n          " {<input id="debug-enabled" type="checkbox" aria-label="Diagnoseereignisse für diesen Tab protokollieren" title="Diagnoseereignisse für diesen Tab protokollieren: Off">}
    append html "\n          " {<span class="status-led off" data-switch-status="debug-enabled" role="status"></span>}
    append html "\n        " {</div>}
    append html "\n      " {</div>}
    append html "\n      " {<div class="button-row">}
    append html "\n        " {<button id="export-debug" class="secondary">Debug exportieren</button>}
    append html "\n      " {</div>}
    append html "\n      " {<p class="muted small"></p>}
    append html "\n    " {</section>}
    
    # Audience modal
    append html "\n    " {<div id="audience-modal" class="modal-backdrop" hidden>}
    append html "\n      " {<section class="modal" role="dialog" aria-modal="true" aria-labelledby="audience-heading">}
    append html "\n        " {<div class="section-title">}
    append html "\n          " {<h2 id="audience-heading">Im Chat beobachtete Personen</h2>}
    append html "\n          " {<button id="close-audience" class="secondary compact" aria-label="Übersicht schließen">Schließen</button>}
    append html "\n        " {</div>}
    append html "\n        " {<p id="audience-limit" class="inline-status"></p>}
    append html "\n        " {<div id="audience-list" class="audience-list"></div>}
    append html "\n      " {</section>}
    append html "\n    " {</div>}
    
    # Speech settings modal
    append html "\n    " {<div id="speech-settings-modal" class="modal-backdrop" hidden>}
    append html "\n      " {<section class="modal" role="dialog" aria-modal="true" aria-labelledby="speech-settings-heading">}
    append html "\n        " {<div class="section-title">}
    append html "\n          " {<h2 id="speech-settings-heading">Erweiterte Einstellungen</h2>}
    append html "\n          " {<button id="close-speech-settings" class="secondary compact" aria-label="Einstellungen schließen">Schließen</button>}
    append html "\n        " {</div>}
    append html "\n        " {<div class="settings-grid speech-integration-settings">}
    append html "\n" {<label class="icon-style-setting"><span>Icon-Stil</span><select id="icon-style"><option value="plastisch">3D / Plastisch</option><option value="glass">Glass / Realistisch</option><option value="linear">Minimal / Linear</option></select></label>}
    append html "\n          " {<label><span>Sprache</span><select id="speech-language"><option value="auto">Auto</option><option value="de-DE">Deutsch</option><option value="en-US">Englisch</option><option value="ru-RU">Russisch</option><option value="uk-UA">Ukrainisch</option><option value="bg-BG">Bulgarisch</option><option value="sr-RS">Serbisch</option><option value="kk-KZ">Kasachisch</option><option value="zh-CN">Chinesisch</option><option value="ja-JP">Japanisch</option><option value="ko-KR">Koreanisch</option><option value="ar-JO">Arabisch</option><option value="fa-IR">Persisch</option><option value="ur-PK">Urdu</option><option value="hi-IN">Hindi</option><option value="ne-NP">Nepali</option><option value="ml-IN">Malayalam</option></select></label>}
    append html "\n          " {<label><span>Stimme</span><select id="speech-voice"><option value="">Standard</option></select></label>}
    append html "\n          " {<label id="audd-token-setting"><span id="audd-token-label">AudD API-Token (optional - <a href="https://audd.io/" target="_blank" rel="noopener noreferrer">https://AudD.io</a> Trial/Paid)</span><input id="audd-token" type="password" autocomplete="off" spellcheck="false"></label>}
    append html "\n          " {<label id="pairing-code-setting"><span>Pairing-Code</span><input id="pairing-code" type="password" autocomplete="off" spellcheck="false"></label>}
    append html "\n          " {<label><span>Universal API-Key</span><input id="universal-caption-api-key" type="password" autocomplete="off" spellcheck="false"></label>}
    append html "\n        " {</div>}
    append html "\n        " {<label class="option-row"><input id="speak-names" type="checkbox" checked> Chatnamen sprechen</label>}
    append html "\n        " {<label class="option-row"><input id="shorten-names" type="checkbox"> Chatnamen kürzen</label>}
    append html "\n        " {<label class="option-row auto-chat-refresh"><input id="auto-chat-refresh" type="checkbox"> Auto-Chat Refresh <input id="auto-chat-refresh-minutes" type="number" min="1" max="60" step="1" value="5" inputmode="numeric" aria-label="Auto-Chat-Refresh in Minuten"><span>min.</span></label>}
    append html "\n        " {<label class="option-row"><input id="game-mode" type="checkbox"> Game-Mode (Spam-, Emoji, usw. Chatfilter)</label>}
    append html "\n        " {<div class="option-row external-speech-trigger-row"><label><input id="filter-external-speech-triggers" type="checkbox"> Trigger filtern (ext. Sprachdienste)</label><input id="external-speech-trigger-characters" type="text" value="." maxlength="10" aria-label="Triggerzeichen, maximal fünf Sonderzeichen" autocomplete="off" spellcheck="false"></div>}
    append html "\n        " {<label class="option-row"><input id="keep-speech-active" type="checkbox" aria-label="Vorlesen dauerhaft" title="Vorlesen dauerhaft: Off"> Vorlesen dauerhaft</label>}
    append html "\n      " {</section>}
    append html "\n    " {</div>}
    
    # Chat history modal
    append html "\n    " {<div id="chat-history-modal" class="modal-backdrop" hidden>}
    append html "\n      " {<section class="modal" role="dialog" aria-modal="true" aria-labelledby="chat-history-heading">}
    append html "\n        " {<div class="section-title">}
    append html "\n          " {<h2 id="chat-history-heading">Gesammelte Chatnachrichten</h2>}
    append html "\n          " {<button id="close-chat-history" class="secondary compact" aria-label="Chatzeilen schließen">Schließen</button>}
    append html "\n        " {</div>}
    append html "\n        " {<p id="chat-history-limit" class="inline-status"></p>}
    append html "\n        " {<div id="chat-history-list" class="chat-history-list"></div>}
    append html "\n      " {</section>}
    append html "\n    " {</div>}
    
    # Recommendation modal
    append html "\n    " {<div id="recommendation-modal" class="modal-backdrop" hidden>}
    append html "\n      " {<section class="modal" role="dialog" aria-modal="true" aria-labelledby="recommendation-modal-heading">}
    append html "\n        " {<div class="section-title">}
    append html "\n          " {<h2 id="recommendation-modal-heading">Gescannte LIVE-Empfehlungen</h2>}
    append html "\n          " {<button id="close-recommendations" class="secondary compact" aria-label="Empfehlungen schließen">Schließen</button>}
    append html "\n        " {</div>}
    append html "\n        " {<div id="recommendation-modal-list" class="recommendation-list"></div>}
    append html "\n      " {</section>}
    append html "\n    " {</div>}
    
    # Notice
    append html "\n    " {<p id="notice" role="alert" class="notice"></p>}
    append html "\n  " {</main>}
    
    # Connection settings modal
    append html "\n  " {<div id="connection-settings-modal" class="modal-backdrop" hidden>}
    append html "\n    " {<section class="modal" role="dialog" aria-modal="true" aria-labelledby="connection-settings-heading">}
    append html "\n      " {<div class="section-title"><h2 id="connection-settings-heading">Connection-Einstellungen</h2><button id="close-connection-settings" class="secondary compact">Schließen</button></div>}
    append html "\n      " {<label class="option-row quick-recover-setting"><input id="hook-reconnect" type="checkbox"> Hook-Reconnect <input id="hook-reconnect-seconds" type="number" min="1" max="59" step="1" value="3" inputmode="numeric" aria-label="Hook-Reconnect-Wartezeit in Sekunden"><span>Sek.</span></label>}
    append html "\n      " {<label class="option-row quick-recover-setting"><input id="quick-recover" type="checkbox"> Player-Recovery <input id="quick-recover-seconds" type="number" min="1" max="59" step="1" value="3" inputmode="numeric" aria-label="Player-Recovery-Bestätigungszeit in Sekunden"><span>Sek.</span></label>}
    append html "\n    " {</section>}
    append html "\n  " {</div>}
    
    # Scripts
    append html "\n  " {<script src="content-core.js"></script>}
    append html "\n  " {<script src="sidepanel.js"></script>}
    append html "\n  " {<script src="icon-controls.js"></script>}
    
    # Close body and html
    append html "\n" {</body>}
    append html "\n" {</html>}
    
    return $html
}

# Main execution
if {$argc != 1} {
    puts stderr "Usage: $argv0 <output-file>"
    exit 1
}

set output_file [lindex $argv 0]
set html_content [generate_sidepanel_html]

if {[catch {open $output_file w} file_handle]} {
    puts stderr "Error: Could not open file '$output_file' for writing"
    exit 1
}

puts $file_handle $html_content
close $file_handle

puts "HTML file generated successfully: $output_file"
