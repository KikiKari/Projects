#!/usr/bin/env pwsh
# sidepanel.html — portiert nach powershell
# Quelle: html, Projects@TikTok-Live-Companion:plugin-source/browser-extension/sidepanel.html
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/sidepanel.html
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/sidepanel.html
# Erzeugt: 2026-10-12 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
    Generates the sidepanel.html file for the TikTok LIVE Companion application.
.DESCRIPTION
    This script creates an HTML document representing the user interface of the TikTok LIVE Companion's side panel.
    It builds the structure programmatically using PowerShell 7 features and outputs it to a specified file.
.PARAMETER OutputPath
    The path where the generated HTML file will be saved.
.EXAMPLE
    .\Generate-SidePanel.ps1 -OutputPath "C:\temp\sidepanel.html"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$OutputPath
)

# Create the root HTML document
$html = @"
<!DOCTYPE html>
<html lang="de">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>TikTok LIVE Companion</title>
  <link rel="stylesheet" href="sidepanel.css">
</head>
<body>
  <header>
    <p id="page-title" class="muted">Kein TikTok-Tab ausgewählt</p>
  </header>

  <main>
"@

# Function to generate sections with consistent structure
function Add-HtmlSection {
    param (
        [string]$Id,
        [string]$HeadingText,
        [hashtable[]]$TitleActions = @(),
        [string]$Content = ""
    )

    $sectionHtml = "<section"
    if ($Id) { $sectionHtml += " id=`"$Id`"" }
    $sectionHtml += " aria-labelledby=`"$($Id)-heading`">"

    # Section Title Block
    $sectionHtml += "<div class=`"section-title`">"
    $sectionHtml += "<h2 id=`"$($Id)-heading`">$HeadingText</h2>"
    
    if ($TitleActions.Count -gt 0) {
        $sectionHtml += "<div class=`"title-actions`">"
        foreach ($action in $TitleActions) {
            switch ($action.Type) {
                'Button' {
                    $sectionHtml += "<button id=`"$($action.Id)`" class=`"$($action.Classes)`" type=`"$($action.Type.ToLower())`" title=`"$($action.Title)`">$($action.Text)</button>"
                }
                'Span' {
                    $sectionHtml += "<span id=`"$($action.Id)`" class=`"$($action.Classes)`" role=`"$($action.Role)`" aria-label=`"$($action.AriaLabel)`" title=`"$($action.Title)`"></span>"
                }
                default {
                    $sectionHtml += "<$($action.Tag) id=`"$($action.Id)`" class=`"$($action.Classes)`">$($action.Content)</$($action.Tag)>"
                }
            }
        }
        $sectionHtml += "</div>"
    }

    $sectionHtml += "</div>"

    # Append additional content if provided
    if ($Content) {
        $sectionHtml += $Content
    }

    $sectionHtml += "</section>"
    return $sectionHtml
}

# Chat Section
$html += Add-HtmlSection -Id "chat" -HeadingText "Chat" -TitleActions @(
    @{ Type='Span'; Id='chat-led'; Classes='status-led off'; Role='status'; AriaLabel='Chat inaktiv'; Title='Chat inaktiv' },
    @{ Type='Button'; Id='chat-count'; Classes='count count-button'; Text='0'; Title='Gesammelte Chatzeilen öffnen' },
    @{ Type='Button'; Id='refresh-chat'; Classes='secondary compact'; Text='Refresh'; Title='Chatanzeige leeren' },
    @{ Type='Button'; Id='toggle-speech'; Classes='secondary compact'; Text='On'; AriaPressed='false'; AriaLabel='Vorlesen' },
    @{ Type='Span'; Id='speech-led'; Classes='status-led off'; Role='status'; AriaLabel='Vorlesen inaktiv'; Title='Vorlesen inaktiv' }
) -Content @"
<div id="chat-list" class="chat-list empty" role="log" aria-live="polite" aria-relevant="additions" aria-label="Die letzten fünf bereinigten Chatnachrichten">Noch keine Chatnachrichten erkannt.</div>
<p id="speech-status" role="status" class="inline-status">Vorlesen ist ausgeschaltet.</p>
<div class="control-label"><label for="speech-volume">Vorleselautstärke</label><output id="speech-volume-output" for="speech-volume">100%</output></div>
<input id="speech-volume" type="range" min="0" max="100" step="5" value="50">
<div class="button-row">
  <button id="service-action" class="secondary">Sprachdienst</button>
  <button id="sherpa-action" class="secondary">Sherpa</button>
  <button id="open-speech-settings" class="secondary compact settings-button" type="button" aria-label="Erweiterte Einstellungen öffnen" aria-haspopup="dialog" title="Einstellungen">⚙</button>
</div>
<p id="service-status" class="inline-status">Lokaler Sprachdienst noch nicht geprüft.</p>
<div id="service-setup" class="inline-status" hidden>
  <button id="copy-service-setup" class="secondary compact">Installation abschließen!</button>
</div>
<label class="option-row"><input id="keep-speech-active" type="checkbox"> Permanent aktiv</label>
"@

# Top Chatters Section
$html += Add-HtmlSection -Id "top-chatters" -HeadingText "Top-Chatter" -TitleActions @(
    @{ Type='Button'; Id='open-audience'; Classes='secondary compact'; Text='Zuschauer*innen' }
) -Content @"
<p id="team-tag-status" class="inline-status">Teamkürzel: noch nicht erkannt.</p>
<div id="top-chatters" class="top-chatters empty">Noch keine Personen im Chat beobachtet.</div>
<div id="top-chatters-actions" class="top-chatters-actions" hidden>
  <button id="top-chatters-reset" class="top-chatter-link" type="button" hidden>Reset</button>
  <button id="top-chatters-more" class="top-chatter-link" type="button">mehr…</button>
</div>
"@

# Profile Info Section
$html += Add-HtmlSection -Id "page-info-section" -HeadingText "PROFIL-Information" -TitleActions @(
    @{ Type='Span'; Id='page-info-source'; Classes='live-indicator'; Content='Metadaten' },
    @{ Type='Button'; Id='refresh-page-info'; Classes='secondary compact'; Text='Refresh' },
    @{ Type='Button'; Id='force-page-info'; Classes='secondary compact danger-outline'; Text='Force' }
) -Content @"
<div id="profile-info" class="profile-info" hidden></div>
<div id="summary-info" class="summary-info"></div>
"@

# Live Stats Section
$html += Add-HtmlSection -Id "stats" -HeadingText "LIVE-Information" -TitleActions @(
    @{ Type='Span'; Id='stats-live'; Classes='live-indicator'; Content='warte' }
) -Content @"
<div id="live-stats" class="status-grid stats-grid"></div>
<p id="stats-status" class="inline-status"></p>
"@

# Connection Hook Section
$html += Add-HtmlSection -Id "hook" -HeadingText "Connection" -TitleActions @(
    @{ Type='Span'; Id='hook-led'; Classes='status-led off'; Role='status'; AriaLabel='Hook inaktiv'; Title='Hook inaktiv' }
) -Content @"
<div class="button-row">
  <button id="toggle-hook" class="primary" aria-label="Connection" aria-pressed="false">On</button>
  <button id="reset-tab" class="secondary danger-outline">Refresh</button>
  <button id="open-embed-live" class="secondary">Embed</button>
  <button id="open-normal-live" class="secondary">Browser</button>
  <button id="player-vlc-frame" class="secondary compact">Player</button>
  <button id="open-connection-settings" class="secondary compact settings-button" type="button" aria-label="Connection-Einstellungen öffnen" aria-haspopup="dialog">⚙</button>
</div>
<p id="hook-status" class="inline-status"></p>
<p id="embed-startup-status" class="inline-status" role="status" aria-live="polite" hidden></p>
<button id="cancel-embed-startup" class="secondary" hidden>Embed-Start abbrechen</button>
<label class="option-row"><input id="hook-autostart" type="checkbox"> Permanent Hook</label>
<p id="hook-reconnect-status" class="inline-status" role="status">Hook-Reconnect: aus</p>
<p id="player-recovery-status" class="inline-status" role="status">Player-Recovery: aus</p>
"@

# Recommendations Section
$html += Add-HtmlSection -Id "recommendations-section" -HeadingText "LIVE-Empfehlungen" -TitleActions @(
    @{ Type='Span'; Id='recommendation-status'; Classes='live-indicator'; Content='bereit' }
) -Content @"
<div class="recommendation-controls">
  <label><span>Anzahl</span><input id="recommendation-limit" type="number" min="1" max="50" step="1" value="20" inputmode="numeric"></label>
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
"@

# Caption Section
$html += Add-HtmlSection -Id "caption" -HeadingText "Titel" -TitleActions @(
    @{ Type='Button'; Id='scan'; Classes='secondary'; Text='Seite prüfen' }
) -Content @"
<div id="caption-status" class="status-grid"></div>
<button id="enable-captions" class="primary">Untertitel aktivieren</button>
<p id="caption-action-status" role="status" class="inline-status action-status"></p>
"@

# Player Section
$html += Add-HtmlSection -Id "player" -HeadingText "Player" -TitleActions @(
    @{ Type='Span'; Id='player-time'; Classes='player-time'; Content='–' }
) -Content @"
<div class="player-controls" role="group" aria-label="TikTok-Player steuern">
  <button id="player-play" class="secondary compact">Pause</button>
  <button id="player-replay" class="secondary compact">Neu laden</button>
  <button id="player-mute" class="secondary compact">Stumm</button>
  <button id="player-pip" class="secondary compact">Bild-in-Bild</button>
  <button id="player-fullscreen" class="secondary compact">Vollbild</button>
  <button id="player-report" class="secondary compact danger-outline">Melden öffnen</button>
</div>
<div class="audio-controls">
  <div class="control-label"><label for="player-volume">Lautstärke</label><output id="player-volume-output" for="player-volume">–</output></div>
  <input id="player-volume" type="range" min="0" max="100" step="1" value="100">
  <div class="audio-meter-row"><span>Spitzenpegel</span><strong id="player-peak">–</strong></div>
  <label class="option-row"><input id="limiter-enabled" type="checkbox"> Pegelschutz aktivieren</label>
  <div class="control-label"><label for="limiter-strength">Schutzstärke</label><output id="limiter-strength-output" for="limiter-strength">30</output></div>
  <input id="limiter-strength" type="range" min="0" max="100" step="1" value="30">
</div>
<p id="multi-guest-status" class="inline-status">Verbundene Streams: noch nicht erkannt.</p>
<p id="player-status" role="status" class="inline-status">Warte auf den TikTok-Player.</p>
"@

# Songs Section
$html += Add-HtmlSection -Id "song" -HeadingText "Songs" -TitleActions @(
    @{ Type='Span'; Id='song-led'; Classes='status-led off'; Role='status'; AriaLabel='Songerkennung inaktiv' }
) -Content @"
<label class="option-row"><input id="song-enabled" type="checkbox"> Songerkennung aktivieren</label>
<button id="recognize-song" class="primary" disabled>Jetzt erkennen</button>
<p id="song-status" class="inline-status"></p>
<div id="song-result" class="song-result" hidden></div>
"@

# HAR Logs Section
$html += Add-HtmlSection -Id "links" -HeadingText "HAR-Logs" -TitleActions @(
    @{ Type='Span'; Id='media-count'; Classes='count'; Content='0' }
) -Content @"
<div id="media-list" class="list empty">Noch keine FLV-/HLS-Links erkannt.</div>
<p class="hint">Extern gestarteter VLC liegt außerhalb des Companion-Pegelschutzes.</p>
"@

# Live Logs Section
$html += Add-HtmlSection -Id "log" -HeadingText "LIVE-Logs" -TitleActions @(
    @{ Type='Span'; Id='caption-count'; Classes='count'; Content='0' }
) -Content @"
<div class="button-row">
  <button id="export-log" class="secondary">JSON-L-Export</button>
  <button id="export-caption-raw" class="secondary">RAW-JSON-Export</button>
  <button id="clear" class="ghost">Anzeige leeren</button>
</div>
<div id="caption-list" class="list empty">Noch keine CaptionMessages empfangen.</div>
"@

# Debug Mode Section
$html += Add-HtmlSection -Id "debug" -HeadingText "Debugmodus" -TitleActions @(
    @{ Type='Span'; Id='debug-count'; Classes='count'; Content='0' }
) -Content @"
<label class="option-row"><input id="debug-enabled" type="checkbox"> Diagnoseereignisse für diesen Tab protokollieren</label>
<div class="button-row">
  <button id="export-debug" class="secondary">Debug exportieren</button>
  <button id="clear-debug" class="ghost">Debug leeren</button>
</div>
<p class="muted small"></p>
"@

# Modals
$html += @"
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
          <label><span>Sprache</span><select id="speech-language"><option value="auto">Auto</option><option value="de-DE">Deutsch</option><option value="en-US">Englisch</option><option value="ru-RU">Russisch</option><option value="uk-UA">Ukrainisch</option><option value="bg-BG">Bulgarisch</option><option value="sr-RS">Serbisch</option><option value="kk-KZ">Kasachisch</option><option value="zh-CN">Chinesisch</option><option value="ja-JP">Japanisch</option><option value="ko-KR">Koreanisch</option><option value="ar-JO">Arabisch</option><option value="fa-IR">Persisch</option><option value="ur-PK">Urdu</option><option value="hi-IN">Hindi</option><option value="ne-NP">Nepali</option><option value="ml-IN">Malayalam</option></select></label>
          <label><span>Stimme</span><select id="speech-voice"><option value="">Standard</option></select></label>
          <label id="audd-token-setting"><span id="audd-token-label">AudD API-Token (optional - <a href="https://audd.io/" target="_blank" rel="noopener noreferrer">https://AudD.io</a> Trial/Paid)</span><input id="audd-token" type="password" autocomplete="off" spellcheck="false"></label>
          <label id="pairing-code-setting"><span>Pairing-Code</span><input id="pairing-code" type="password" autocomplete="off" spellcheck="false"></label>
          <label><span>Universal API-Key</span><input id="universal-caption-api-key" type="password" autocomplete="off" spellcheck="false"></label>
        </div>
        <label class="option-row"><input id="speak-names" type="checkbox" checked> Chatnamen sprechen</label>
        <label class="option-row"><input id="shorten-names" type="checkbox"> Chatnamen kürzen</label>
        <label class="option-row auto-chat-refresh"><input id="auto-chat-refresh" type="checkbox"> Auto-Chat Refresh <input id="auto-chat-refresh-minutes" type="number" min="1" max="60" step="1" value="5" inputmode="numeric" aria-label="Auto-Chat-Refresh in Minuten"><span>min.</span></label>
        <label class="option-row"><input id="game-mode" type="checkbox"> Game-Mode</label>
        <label class="option-row"><input id="filter-external-speech-triggers" type="checkbox"> Trigger externer Sprachdienste filtern</label>
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
</body>
</html>
"@

# Write the complete HTML to output file
Set-Content -Path $OutputPath -Value $html -Encoding Utf8

Write-Host "HTML file successfully written to: $OutputPath"
