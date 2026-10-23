#!/usr/bin/env node
// sidepanel.html — portiert nach javascript
// Quelle: html, Projects@vercel/install-and-configure-vercel-w-98sxlo:plugin-source/browser-extension/sidepanel.html
// Erzeugt: 2026-10-23 durch ABSTRACTIONS_MANAGER.py

import { writeFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

function createHTMLElement(tag, attributes = {}, children = []) {
  const element = { tag, attributes, children };
  return element;
}

function createText(text) {
  return { text };
}

function generateDocument() {
  const doctype = '<!doctype html>';
  
  const html = createHTMLElement('html', { lang: 'de' }, [
    createHTMLElement('head', {}, [
      createHTMLElement('meta', { charset: 'utf-8' }),
      createHTMLElement('meta', { name: 'viewport', content: 'width=device-width, initial-scale=1' }),
      createHTMLElement('title', {}, [createText('TikTok LIVE Companion')]),
      createHTMLElement('link', { rel: 'stylesheet', href: 'sidepanel.css' })
    ]),
    createHTMLElement('body', {}, [
      createHTMLElement('header', {}, [
        createHTMLElement('p', { id: 'page-title', class: 'muted' }, [createText('Kein TikTok-Tab ausgewählt')])
      ]),
      createHTMLElement('main', {}, [
        // Chat section
        createHTMLElement('section', { 'aria-labelledby': 'chat-heading' }, [
          createHTMLElement('div', { class: 'section-title' }, [
            createHTMLElement('h2', { id: 'chat-heading' }, [createText('Chat')]),
            createHTMLElement('div', { class: 'title-actions' }, [
              createHTMLElement('span', { id: 'chat-led', class: 'status-led off', role: 'status', 'aria-label': 'Chat inaktiv', title: 'Chat inaktiv' }),
              createHTMLElement('button', { id: 'chat-count', class: 'count count-button', type: 'button', 'aria-haspopup': 'dialog', title: 'Gesammelte Chatzeilen öffnen' }, [createText('0')]),
              createHTMLElement('button', { id: 'refresh-chat', class: 'secondary compact', title: 'Chatanzeige leeren' }, [createText('Refresh')]),
              createHTMLElement('button', { id: 'toggle-speech', class: 'secondary compact', 'aria-pressed': 'false', 'aria-label': 'Vorlesen' }, [createText('On')]),
              createHTMLElement('span', { id: 'speech-led', class: 'status-led off', role: 'status', 'aria-label': 'Vorlesen inaktiv', title: 'Vorlesen inaktiv' })
            ])
          ]),
          createHTMLElement('div', { id: 'chat-list', class: 'chat-list empty', role: 'log', 'aria-live': 'polite', 'aria-relevant': 'additions', 'aria-label': 'Die letzten fünf bereinigten Chatnachrichten' }, [createText('Noch keine Chatnachrichten erkannt.')]),
          createHTMLElement('p', { id: 'speech-status', role: 'status', class: 'inline-status' }, [createText('Vorlesen ist ausgeschaltet.')]),
          createHTMLElement('div', { class: 'control-label' }, [
            createHTMLElement('label', { for: 'speech-volume' }, [createText('Vorleselautstärke')]),
            createHTMLElement('output', { id: 'speech-volume-output', for: 'speech-volume' }, [createText('100%')])
          ]),
          createHTMLElement('input', { id: 'speech-volume', type: 'range', min: '0', max: '100', step: '5', value: '50' }),
          createHTMLElement('div', { class: 'button-row' }, [
            createHTMLElement('button', { id: 'service-action', class: 'secondary' }, [createText('Sprachdienst')]),
            createHTMLElement('button', { id: 'sherpa-action', class: 'secondary' }, [createText('Sherpa')]),
            createHTMLElement('button', { id: 'open-speech-settings', class: 'secondary compact settings-button', type: 'button', 'aria-label': 'Erweiterte Einstellungen öffnen', 'aria-haspopup': 'dialog', title: 'Einstellungen' }, [createText('⚙')])
          ]),
          createHTMLElement('p', { id: 'service-status', class: 'inline-status' }, [createText('Lokaler Sprachdienst noch nicht geprüft.')]),
          createHTMLElement('div', { id: 'service-setup', class: 'inline-status', hidden: '' }, [
            createHTMLElement('button', { id: 'copy-service-setup', class: 'secondary compact' }, [createText('Installation abschließen!')])
          ]),
          createHTMLElement('label', { class: 'option-row' }, [
            createHTMLElement('input', { id: 'keep-speech-active', type: 'checkbox' }),
            createText(' Permanent aktiv')
          ])
        ]),
        
        // Top chatters section
        createHTMLElement('section', { 'aria-labelledby': 'top-chatters-heading' }, [
          createHTMLElement('div', { class: 'section-title' }, [
            createHTMLElement('h2', { id: 'top-chatters-heading' }, [createText('Top-Chatter')]),
            createHTMLElement('button', { id: 'open-audience', class: 'secondary compact' }, [createText('Zuschauer*innen')])
          ]),
          createHTMLElement('p', { id: 'team-tag-status', class: 'inline-status' }, [createText('Teamkürzel: noch nicht erkannt.')]),
          createHTMLElement('div', { id: 'top-chatters', class: 'top-chatters empty' }, [createText('Noch keine Personen im Chat beobachtet.')]),
          createHTMLElement('div', { id: 'top-chatters-actions', class: 'top-chatters-actions', hidden: '' }, [
            createHTMLElement('button', { id: 'top-chatters-reset', class: 'top-chatter-link', type: 'button', hidden: '' }, [createText('Reset')]),
            createHTMLElement('button', { id: 'top-chatters-more', class: 'top-chatter-link', type: 'button' }, [createText('mehr…')])
          ])
        ]),
        
        // Page info section
        createHTMLElement('section', { id: 'page-info-section', 'aria-labelledby': 'page-info-heading' }, [
          createHTMLElement('div', { class: 'section-title' }, [
            createHTMLElement('h2', { id: 'page-info-heading' }, [createText('PROFIL-Information')]),
            createHTMLElement('div', { class: 'title-actions' }, [
              createHTMLElement('span', { id: 'page-info-source', class: 'live-indicator' }, [createText('Metadaten')]),
              createHTMLElement('button', { id: 'refresh-page-info', class: 'secondary compact' }, [createText('Refresh')]),
              createHTMLElement('button', { id: 'force-page-info', class: 'secondary compact danger-outline' }, [createText('Force')])
            ])
          ]),
          createHTMLElement('div', { id: 'profile-info', class: 'profile-info', hidden: '' }),
          createHTMLElement('div', { id: 'summary-info', class: 'summary-info' })
        ]),
        
        // Stats section
        createHTMLElement('section', { 'aria-labelledby': 'stats-heading' }, [
          createHTMLElement('div', { class: 'section-title' }, [
            createHTMLElement('h2', { id: 'stats-heading' }, [createText('LIVE-Information')]),
            createHTMLElement('span', { id: 'stats-live', class: 'live-indicator' }, [createText('warte')])
          ]),
          createHTMLElement('div', { id: 'live-stats', class: 'status-grid stats-grid' }),
          createHTMLElement('p', { id: 'stats-status', class: 'inline-status' })
        ]),
        
        // Hook section
        createHTMLElement('section', { 'aria-labelledby': 'hook-heading' }, [
          createHTMLElement('div', { class: 'section-title' }, [
            createHTMLElement('h2', { id: 'hook-heading' }, [createText('Connection')]),
            createHTMLElement('span', { id: 'hook-led', class: 'status-led off', role: 'status', 'aria-label': 'Hook inaktiv', title: 'Hook inaktiv' })
          ]),
          createHTMLElement('div', { class: 'button-row' }, [
            createHTMLElement('button', { id: 'toggle-hook', class: 'primary', 'aria-label': 'Connection', 'aria-pressed': 'false' }, [createText('On')]),
            createHTMLElement('button', { id: 'reset-tab', class: 'secondary danger-outline' }, [createText('Refresh')]),
            createHTMLElement('button', { id: 'open-embed-live', class: 'secondary' }, [createText('Embed')]),
            createHTMLElement('button', { id: 'open-normal-live', class: 'secondary' }, [createText('Browser')]),
            createHTMLElement('button', { id: 'player-vlc-frame', class: 'secondary compact' }, [createText('Player')]),
            createHTMLElement('button', { id: 'open-connection-settings', class: 'secondary compact settings-button', type: 'button', 'aria-label': 'Connection-Einstellungen öffnen', 'aria-haspopup': 'dialog' }, [createText('⚙')])
          ]),
          createHTMLElement('p', { id: 'hook-status', class: 'inline-status' }),
          createHTMLElement('p', { id: 'embed-startup-status', class: 'inline-status', role: 'status', 'aria-live': 'polite', hidden: '' }),
          createHTMLElement('button', { id: 'cancel-embed-startup', class: 'secondary', hidden: '' }, [createText('Embed-Start abbrechen')]),
          createHTMLElement('label', { class: 'option-row' }, [
            createHTMLElement('input', { id: 'hook-autostart', type: 'checkbox' }),
            createText(' Permanent Hook')
          ]),
          createHTMLElement('p', { id: 'hook-reconnect-status', class: 'inline-status', role: 'status' }, [createText('Hook-Reconnect: aus')]),
          createHTMLElement('p', { id: 'player-recovery-status', class: 'inline-status', role: 'status' }, [createText('Player-Recovery: aus')])
        ]),
        
        // Recommendations section
        createHTMLElement('section', { id: 'recommendations-section', 'aria-labelledby': 'recommendations-heading' }, [
          createHTMLElement('div', { class: 'section-title' }, [
            createHTMLElement('h2', { id: 'recommendations-heading' }, [createText('LIVE-Empfehlungen')]),
            createHTMLElement('span', { id: 'recommendation-status', class: 'live-indicator' }, [createText('bereit')])
          ]),
          createHTMLElement('div', { class: 'recommendation-controls' }, [
            createHTMLElement('label', {}, [
              createHTMLElement('span', {}, [createText('Anzahl')]),
              createHTMLElement('input', { id: 'recommendation-limit', type: 'number', min: '1', max: '50', step: '1', value: '20', inputmode: 'numeric' })
            ]),
            createHTMLElement('label', {}, [
              createHTMLElement('span', {}, [createText('Sortierung')]),
              createHTMLElement('select', { id: 'recommendation-sort' }, [
                createHTMLElement('option', { value: 'tiktok' }, [createText('TikTok-Reihenfolge')]),
                createHTMLElement('option', { value: 'viewers' }, [createText('Zuschauer*innen')])
              ])
            ])
          ]),
          createHTMLElement('div', { class: 'button-row' }, [
            createHTMLElement('button', { id: 'scan-recommendations', class: 'primary' }, [createText('Empfehlungen scannen')]),
            createHTMLElement('button', { id: 'cancel-recommendations', class: 'secondary', hidden: '' }, [createText('Abbrechen')])
          ]),
          createHTMLElement('p', { id: 'recommendation-progress', class: 'inline-status', 'aria-live': 'polite' }, [createText('Noch kein Scan gestartet.')]),
          createHTMLElement('div', { id: 'recommendation-list', class: 'recommendation-list empty' }, [createText('Noch keine Empfehlungen erfasst.')]),
          createHTMLElement('div', { id: 'recommendation-actions', class: 'top-chatters-actions', hidden: '' }, [
            createHTMLElement('button', { id: 'recommendation-more', class: 'top-chatter-link', type: 'button' }, [createText('mehr…')])
          ])
        ]),
        
        // Caption section
        createHTMLElement('section', { 'aria-labelledby': 'caption-heading' }, [
          createHTMLElement('div', { class: 'section-title' }, [
            createHTMLElement('h2', { id: 'caption-heading' }, [createText('Titel')]),
            createHTMLElement('button', { id: 'scan', class: 'secondary' }, [createText('Seite prüfen')])
          ]),
          createHTMLElement('div', { id: 'caption-status', class: 'status-grid' }),
          createHTMLElement('button', { id: 'enable-captions', class: 'primary' }, [createText('Untertitel aktivieren')]),
          createHTMLElement('p', { id: 'caption-action-status', role: 'status', class: 'inline-status action-status' })
        ]),
        
        // Player section
        createHTMLElement('section', { 'aria-labelledby': 'player-heading' }, [
          createHTMLElement('div', { class: 'section-title' }, [
            createHTMLElement('h2', { id: 'player-heading' }, [createText('Player')]),
            createHTMLElement('span', { id: 'player-time', class: 'player-time' }, [createText('–')])
          ]),
          createHTMLElement('div', { class: 'player-controls', role: 'group', 'aria-label': 'TikTok-Player steuern' }, [
            createHTMLElement('button', { id: 'player-play', class: 'secondary compact' }, [createText('Pause')]),
            createHTMLElement('button', { id: 'player-replay', class: 'secondary compact' }, [createText('Neu laden')]),
            createHTMLElement('button', { id: 'player-mute', class: 'secondary compact' }, [createText('Stumm')]),
            createHTMLElement('button', { id: 'player-pip', class: 'secondary compact' }, [createText('Bild-in-Bild')]),
            createHTMLElement('button', { id: 'player-fullscreen', class: 'secondary compact' }, [createText('Vollbild')]),
            createHTMLElement('button', { id: 'player-report', class: 'secondary compact danger-outline' }, [createText('Melden öffnen')])
          ]),
          createHTMLElement('div', { class: 'audio-controls' }, [
            createHTMLElement('div', { class: 'control-label' }, [
              createHTMLElement('label', { for: 'player-volume' }, [createText('Lautstärke')]),
              createHTMLElement('output', { id: 'player-volume-output', for: 'player-volume' }, [createText('–')])
            ]),
            createHTMLElement('input', { id: 'player-volume', type: 'range', min: '0', max: '100', step: '1', value: '100' }),
            createHTMLElement('div', { class: 'audio-meter-row' }, [
              createHTMLElement('span', {}, [createText('Spitzenpegel')]),
              createHTMLElement('strong', { id: 'player-peak' }, [createText('–')])
            ]),
            createHTMLElement('label', { class: 'option-row' }, [
              createHTMLElement('input', { id: 'limiter-enabled', type: 'checkbox' }),
              createText(' Pegelschutz aktivieren')
            ]),
            createHTMLElement('div', { class: 'control-label' }, [
              createHTMLElement('label', { for: 'limiter-strength' }, [createText('Schutzstärke')]),
              createHTMLElement('output', { id: 'limiter-strength-output', for: 'limiter-strength' }, [createText('30')])
            ]),
            createHTMLElement('input', { id: 'limiter-strength', type: 'range', min: '0', max: '100', step: '1', value: '30' })
          ]),
          createHTMLElement('p', { id: 'multi-guest-status', class: 'inline-status' }, [createText('Verbundene Streams: noch nicht erkannt.')]),
          createHTMLElement('p', { id: 'player-status', role: 'status', class: 'inline-status' }, [createText('Warte auf den TikTok-Player.')])
        ]),
        
        // Song section
        createHTMLElement('section', { 'aria-labelledby': 'song-heading' }, [
          createHTMLElement('div', { class: 'section-title' }, [
            createHTMLElement('h2', { id: 'song-heading' }, [createText('Songs')]),
            createHTMLElement('span', { id: 'song-led', class: 'status-led off', role: 'status', 'aria-label': 'Songerkennung inaktiv' })
          ]),
          createHTMLElement('label', { class: 'option-row' }, [
            createHTMLElement('input', { id: 'song-enabled', type: 'checkbox' }),
            createText(' Songerkennung aktivieren')
          ]),
          createHTMLElement('button', { id: 'recognize-song', class: 'primary', disabled: '' }, [createText('Jetzt erkennen')]),
          createHTMLElement('p', { id: 'song-status', class: 'inline-status' }),
          createHTMLElement('div', { id: 'song-result', class: 'song-result', hidden: '' })
        ]),
        
        // Links section
        createHTMLElement('section', { 'aria-labelledby': 'links-heading' }, [
          createHTMLElement('div', { class: 'section-title' }, [
            createHTMLElement('h2', { id: 'links-heading' }, [createText('HAR-Logs')]),
            createHTMLElement('span', { id: 'media-count', class: 'count' }, [createText('0')])
          ]),
          createHTMLElement('div', { id: 'media-list', class: 'list empty' }, [createText('Noch keine FLV-/HLS-Links erkannt.')]),
          createHTMLElement('p', { class: 'hint' }, [createText('Extern gestarteter VLC liegt außerhalb des Companion-Pegelschutzes.')])
        ]),
        
        // Log section
        createHTMLElement('section', { 'aria-labelledby': 'log-heading' }, [
          createHTMLElement('div', { class: 'section-title' }, [
            createHTMLElement('h2', { id: 'log-heading' }, [createText('LIVE-Logs')]),
            createHTMLElement('span', { id: 'caption-count', class: 'count' }, [createText('0')])
          ]),
          createHTMLElement('div', { class: 'button-row' }, [
            createHTMLElement('button', { id: 'export-log', class: 'secondary' }, [createText('JSON-L-Export')]),
            createHTMLElement('button', { id: 'export-caption-raw', class: 'secondary' }, [createText('RAW-JSON-Export')]),
            createHTMLElement('button', { id: 'clear', class: 'ghost' }, [createText('Anzeige leeren')])
          ]),
          createHTMLElement('div', { id: 'caption-list', class: 'list empty' }, [createText('Noch keine CaptionMessages empfangen.')])
        ]),
        
        // Debug section
        createHTMLElement('section', { 'aria-labelledby': 'debug-heading' }, [
          createHTMLElement('div', { class: 'section-title' }, [
            createHTMLElement('h2', { id: 'debug-heading' }, [createText('Debugmodus')]),
            createHTMLElement('span', { id: 'debug-count', class: 'count' }, [createText('0')])
          ]),
          createHTMLElement('label', { class: 'option-row' }, [
            createHTMLElement('input', { id: 'debug-enabled', type: 'checkbox' }),
            createText(' Diagnoseereignisse für diesen Tab protokollieren')
          ]),
          createHTMLElement('div', { class: 'button-row' }, [
            createHTMLElement('button', { id: 'export-debug', class: 'secondary' }, [createText('Debug exportieren')]),
            createHTMLElement('button', { id: 'clear-debug', class: 'ghost' }, [createText('Debug leeren')])
          ]),
          createHTMLElement('p', { class: 'muted small' })
        ]),
        
        // Audience modal
        createHTMLElement('div', { id: 'audience-modal', class: 'modal-backdrop', hidden: '' }, [
          createHTMLElement('section', { class: 'modal', role: 'dialog', 'aria-modal': 'true', 'aria-labelledby': 'audience-heading' }, [
            createHTMLElement('div', { class: 'section-title' }, [
              createHTMLElement('h2', { id: 'audience-heading' }, [createText('Im Chat beobachtete Personen')]),
              createHTMLElement('button', { id: 'close-audience', class: 'secondary compact', 'aria-label': 'Übersicht schließen' }, [createText('Schließen')])
            ]),
            createHTMLElement('p', { id: 'audience-limit', class: 'inline-status' }),
            createHTMLElement('div', { id: 'audience-list', class: 'audience-list' })
          ])
        ]),
        
        // Speech settings modal
        createHTMLElement('div', { id: 'speech-settings-modal', class: 'modal-backdrop', hidden: '' }, [
          createHTMLElement('section', { class: 'modal', role: 'dialog', 'aria-modal': 'true', 'aria-labelledby': 'speech-settings-heading' }, [
            createHTMLElement('div', { class: 'section-title' }, [
              createHTMLElement('h2', { id: 'speech-settings-heading' }, [createText('Erweiterte Einstellungen')]),
              createHTMLElement('button', { id: 'close-speech-settings', class: 'secondary compact', 'aria-label': 'Einstellungen schließen' }, [createText('Schließen')])
            ]),
            createHTMLElement('div', { class: 'settings-grid speech-integration-settings' }, [
              createHTMLElement('label', {}, [
                createHTMLElement('span', {}, [createText('Sprache')]),
                createHTMLElement('select', { id: 'speech-language' }, [
                  createHTMLElement('option', { value: 'auto' }, [createText('Auto')]),
                  createHTMLElement('option', { value: 'de-DE' }, [createText('Deutsch')]),
                  createHTMLElement('option', { value: 'en-US' }, [createText('Englisch')]),
                  createHTMLElement('option', { value: 'ru-RU' }, [createText('Russisch')]),
                  createHTMLElement('option', { value: 'uk-UA' }, [createText('Ukrainisch')]),
                  createHTMLElement('option', { value: 'bg-BG' }, [createText('Bulgarisch')]),
                  createHTMLElement('option', { value: 'sr-RS' }, [createText('Serbisch')]),
                  createHTMLElement('option', { value: 'kk-KZ' }, [createText('Kasachisch')]),
                  createHTMLElement('option', { value: 'zh-CN' }, [createText('Chinesisch')]),
                  createHTMLElement('option', { value: 'ja-JP' }, [createText('Japanisch')]),
                  createHTMLElement('option', { value: 'ko-KR' }, [createText('Koreanisch')]),
                  createHTMLElement('option', { value: 'ar-JO' }, [createText('Arabisch')]),
                  createHTMLElement('option', { value: 'fa-IR' }, [createText('Persisch')]),
                  createHTMLElement('option', { value: 'ur-PK' }, [createText('Urdu')]),
                  createHTMLElement('option', { value: 'hi-IN' }, [createText('Hindi')]),
                  createHTMLElement('option', { value: 'ne-NP' }, [createText('Nepali')]),
                  createHTMLElement('option', { value: 'ml-IN' }, [createText('Malayalam')])
                ])
              ]),
              createHTMLElement('label', {}, [
                createHTMLElement('span', {}, [createText('Stimme')]),
                createHTMLElement('select', { id: 'speech-voice' }, [
                  createHTMLElement('option', { value: '' }, [createText('Standard')])
                ])
              ]),
              createHTMLElement('label', { id: 'audd-token-setting' }, [
                createHTMLElement('span', { id: 'audd-token-label' }, [createText('AudD API-Token (optional - '), createHTMLElement('a', { href: 'https://audd.io/', target: '_blank', rel: 'noopener noreferrer' }, [createText('https://AudD.io')]), createText(' Trial/Paid)')]),
                createHTMLElement('input', { id: 'audd-token', type: 'password', autocomplete: 'off', spellcheck: 'false' })
              ]),
              createHTMLElement('label', { id: 'pairing-code-setting' }, [
                createHTMLElement('span', {}, [createText('Pairing-Code')]),
                createHTMLElement('input', { id: 'pairing-code', type: 'password', autocomplete: 'off', spellcheck: 'false' })
              ]),
              createHTMLElement('label', {}, [
                createHTMLElement('span', {}, [createText('Universal API-Key')]),
                createHTMLElement('input', { id: 'universal-caption-api-key', type: 'password', autocomplete: 'off', spellcheck: 'false' })
              ])
            ]),
            createHTMLElement('label', { class: 'option-row' }, [
              createHTMLElement('input', { id: 'speak-names', type: 'checkbox', checked: '' }),
              createText(' Chatnamen sprechen')
            ]),
            createHTMLElement('label', { class: 'option-row' }, [
              createHTMLElement('input', { id: 'shorten-names', type: 'checkbox' }),
              createText(' Chatnamen kürzen')
            ]),
            createHTMLElement('label', { class: 'option-row auto-chat-refresh' }, [
              createHTMLElement('input', { id: 'auto-chat-refresh', type: 'checkbox' }),
              createText(' Auto-Chat Refresh '),
              createHTMLElement('input', { id: 'auto-chat-refresh-minutes', type: 'number', min: '1', max: '60', step: '1', value: '5', inputmode: 'numeric', 'aria-label': 'Auto-Chat-Refresh in Minuten' }),
              createHTMLElement('span', {}, [createText('min.')])
            ]),
            createHTMLElement('label', { class: 'option-row' }, [
              createHTMLElement('input', { id: 'game-mode', type: 'checkbox' }),
              createText(' Game-Mode')
            ]),
            createHTMLElement('label', { class: 'option-row' }, [
              createHTMLElement('input', { id: 'filter-external-speech-triggers', type: 'checkbox' }),
              createText(' Trigger externer Sprachdienste filtern')
            ])
          ])
        ]),
        
        // Chat history modal
        createHTMLElement('div', { id: 'chat-history-modal', class: 'modal-backdrop', hidden: '' }, [
          createHTMLElement('section', { class: 'modal', role: 'dialog', 'aria-modal': 'true', 'aria-labelledby': 'chat-history-heading' }, [
            createHTMLElement('div', { class: 'section-title' }, [
              createHTMLElement('h2', { id: 'chat-history-heading' }, [createText('Gesammelte Chatnachrichten')]),
              createHTMLElement('button', { id: 'close-chat-history', class: 'secondary compact', 'aria-label': 'Chatzeilen schließen' }, [createText('Schließen')])
            ]),
            createHTMLElement('p', { id: 'chat-history-limit', class: 'inline-status' }),
            createHTMLElement('div', { id: 'chat-history-list', class: 'chat-history-list' })
          ])
        ]),
        
        // Recommendation modal
        createHTMLElement('div', { id: 'recommendation-modal', class: 'modal-backdrop', hidden: '' }, [
          createHTMLElement('section', { class: 'modal', role: 'dialog', 'aria-modal': 'true', 'aria-labelledby': 'recommendation-modal-heading' }, [
            createHTMLElement('div', { class: 'section-title' }, [
              createHTMLElement('h2', { id: 'recommendation-modal-heading' }, [createText('Gescannte LIVE-Empfehlungen')]),
              createHTMLElement('button', { id: 'close-recommendations', class: 'secondary compact', 'aria-label': 'Empfehlungen schließen' }, [createText('Schließen')])
            ]),
            createHTMLElement('div', { id: 'recommendation-modal-list', class: 'recommendation-list' })
          ])
        ]),
        
        // Notice
        createHTMLElement('p', { id: 'notice', role: 'alert', class: 'notice' })
      ]),
      
      // Connection settings modal
      createHTMLElement('div', { id: 'connection-settings-modal', class: 'modal-backdrop', hidden: '' }, [
        createHTMLElement('section', { class: 'modal', role: 'dialog', 'aria-modal': 'true', 'aria-labelledby': 'connection-settings-heading' }, [
          createHTMLElement('div', { class: 'section-title' }, [
            createHTMLElement('h2', { id: 'connection-settings-heading' }, [createText('Connection-Einstellungen')]),
            createHTMLElement('button', { id: 'close-connection-settings', class: 'secondary compact' }, [createText('Schließen')])
          ]),
          createHTMLElement('label', { class: 'option-row quick-recover-setting' }, [
            createHTMLElement('input', { id: 'hook-reconnect', type: 'checkbox' }),
            createText(' Hook-Reconnect '),
            createHTMLElement('input', { id: 'hook-reconnect-seconds', type: 'number', min: '1', max: '59', step: '1', value: '3', inputmode: 'numeric', 'aria-label': 'Hook-Reconnect-Wartezeit in Sekunden' }),
            createHTMLElement('span', {}, [createText('Sek.')])
          ]),
          createHTMLElement('label', { class: 'option-row quick-recover-setting' }, [
            createHTMLElement('input', { id: 'quick-recover', type: 'checkbox' }),
            createText(' Player-Recovery '),
            createHTMLElement('input', { id: 'quick-recover-seconds', type: 'number', min: '1', max: '59', step: '1', value: '3', inputmode: 'numeric', 'aria-label': 'Player-Recovery-Bestätigungszeit in Sekunden' }),
            createHTMLElement('span', {}, [createText('Sek.')])
          ])
        ])
      ]),
      
      // Scripts
      createHTMLElement('script', { src: 'content-core.js' }),
      createHTMLElement('script', { src: 'sidepanel.js' })
    ])
  ]);
  
  return { doctype, html };
}

function renderElement(element) {
  if (element.text !== undefined) {
    return element.text;
  }
  
  let html = `<${element.tag}`;
  
  for (const [key, value] of Object.entries(element.attributes)) {
    if (value === '') {
      html += ` ${key}`;
    } else {
      html += ` ${key}="${value}"`;
    }
  }
  
  if (element.children.length === 0) {
    html += '></' + element.tag + '>';
  } else {
    html += '>';
    for (const child of element.children) {
      html += renderElement(child);
    }
    html += '</' + element.tag + '>';
  }
  
  return html;
}

function renderDocument(document) {
  let html = document.doctype + '\n';
  html += renderElement(document.html);
  return html;
}

// Main execution
const outputFile = process.argv[2] || join(__dirname, 'sidepanel-generated.html');
const document = generateDocument();
const htmlContent = renderDocument(document);

writeFileSync(outputFile, htmlContent);
console.log(`HTML file generated: ${outputFile}`);
