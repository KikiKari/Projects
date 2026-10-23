#!/usr/bin/env node
// sidepanel.html — portiert nach javascript
// Quelle: html, Projects@TikTok-Live-Companion:plugin-source/browser-extension/sidepanel.html
// auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/sidepanel.html
// auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/sidepanel.html
// auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/browser-extension/sidepanel.html
// Erzeugt: 2026-10-23 durch ABSTRACTIONS_MANAGER.py

import { writeFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

function createDocument() {
  const doc = {
    doctype: '<!DOCTYPE html>',
    html: {
      attributes: { lang: 'de' },
      head: {
        children: [
          { tag: 'meta', attributes: { charset: 'utf-8' } },
          { tag: 'meta', attributes: { name: 'viewport', content: 'width=device-width, initial-scale=1' } },
          { tag: 'title', text: 'TikTok LIVE Companion' },
          { tag: 'link', attributes: { rel: 'stylesheet', href: 'sidepanel.css' } },
          { tag: 'link', attributes: { rel: 'stylesheet', href: 'icon-controls.css' } }
        ]
      },
      body: {
        children: [
          // Header
          {
            tag: 'header',
            children: [
              { tag: 'p', attributes: { id: 'page-title', class: 'muted' }, text: 'Kein TikTok-Tab ausgewählt' }
            ]
          },
          
          // Main content
          {
            tag: 'main',
            children: [
              // Chat section
              {
                tag: 'section',
                attributes: { 'aria-labelledby': 'chat-heading' },
                children: [
                  {
                    tag: 'div',
                    attributes: { class: 'section-title' },
                    children: [
                      { tag: 'h2', attributes: { id: 'chat-heading' }, text: 'Chat' },
                      {
                        tag: 'div',
                        attributes: { class: 'title-actions' },
                        children: [
                          { tag: 'span', attributes: { id: 'chat-led', class: 'status-led off', role: 'status', 'aria-label': 'Chat inaktiv', title: 'Chat inaktiv' } },
                          { tag: 'button', attributes: { id: 'chat-count', class: 'count count-button', type: 'button', 'aria-haspopup': 'dialog', title: 'Gesammelte Chatzeilen öffnen' }, text: '0' },
                          { tag: 'button', attributes: { id: 'refresh-chat', class: 'secondary compact', title: 'Chatanzeige leeren' }, text: 'Reset' },
                          { tag: 'button', attributes: { id: 'toggle-speech', class: 'secondary compact', 'aria-pressed': 'false', 'aria-label': 'Vorlesen' }, text: 'On' },
                          { tag: 'span', attributes: { id: 'speech-led', class: 'status-led off', role: 'status', 'aria-label': 'Vorlesen inaktiv', title: 'Vorlesen inaktiv' } }
                        ]
                      }
                    ]
                  },
                  { tag: 'div', attributes: { id: 'chat-list', class: 'chat-list empty', role: 'log', 'aria-live': 'polite', 'aria-relevant': 'additions', 'aria-label': 'Die letzten fünf bereinigten Chatnachrichten' }, text: 'Noch keine Chatnachrichten erkannt.' },
                  { tag: 'p', attributes: { id: 'speech-status', role: 'status', class: 'inline-status' }, text: 'Vorlesen ist ausgeschaltet.' },
                  { tag: 'div', attributes: { class: 'control-label' }, children: [
                    { tag: 'label', attributes: { for: 'speech-volume' }, text: 'Vorleselautstärke' },
                    { tag: 'output', attributes: { id: 'speech-volume-output', for: 'speech-volume' }, text: '100%' }
                  ]},
                  { tag: 'input', attributes: { id: 'speech-volume', type: 'range', min: '0', max: '100', step: '5', value: '50' } },
                  {
                    tag: 'div',
                    attributes: { class: 'button-row' },
                    children: [
                      { tag: 'button', attributes: { id: 'service-action', class: 'secondary' }, text: 'Sprachdienst' },
                      { tag: 'button', attributes: { id: 'sherpa-action', class: 'secondary' }, text: 'Sherpa' },
                      { tag: 'button', attributes: { id: 'open-speech-settings', class: 'secondary compact settings-button', type: 'button', 'aria-label': 'Erweiterte Einstellungen öffnen', 'aria-haspopup': 'dialog', title: 'Einstellungen' } }
                    ]
                  },
                  { tag: 'p', attributes: { id: 'service-status', class: 'inline-status' }, text: 'Lokaler Sprachdienst noch nicht geprüft.' },
                  { tag: 'div', attributes: { id: 'service-setup', class: 'inline-status', hidden: true }, children: [
                    { tag: 'button', attributes: { id: 'copy-service-setup', class: 'secondary compact' }, text: 'Installation abschließen!' }
                  ]}
                ]
              },

              // Stats section
              {
                tag: 'section',
                attributes: { 'aria-labelledby': 'stats-heading' },
                children: [
                  {
                    tag: 'div',
                    attributes: { class: 'section-title' },
                    children: [
                      { tag: 'h2', attributes: { id: 'stats-heading' }, text: 'LIVE-Information' },
                      { tag: 'span', attributes: { id: 'stats-live', class: 'live-indicator' }, text: 'warte' }
                    ]
                  },
                  { tag: 'div', attributes: { id: 'live-stats', class: 'status-grid stats-grid' } },
                  { tag: 'p', attributes: { id: 'stats-status', class: 'inline-status' } }
                ]
              },

              // Page info section
              {
                tag: 'section',
                attributes: { id: 'page-info-section', 'aria-labelledby': 'page-info-heading' },
                children: [
                  {
                    tag: 'div',
                    attributes: { class: 'section-title' },
                    children: [
                      { tag: 'h2', attributes: { id: 'page-info-heading' }, text: 'PROFIL-Information' },
                      {
                        tag: 'div',
                        attributes: { class: 'title-actions' },
                        children: [
                          { tag: 'span', attributes: { id: 'page-info-source', class: 'live-indicator' }, text: 'Metadaten' },
                          { tag: 'button', attributes: { id: 'refresh-page-info', class: 'secondary compact', title: 'Refresh' }, text: 'Refresh' },
                          { tag: 'button', attributes: { id: 'force-page-info', class: 'secondary compact danger-outline' }, text: 'Force' }
                        ]
                      }
                    ]
                  },
                  { tag: 'div', attributes: { id: 'profile-info', class: 'profile-info', hidden: true } },
                  { tag: 'div', attributes: { id: 'summary-info', class: 'summary-info' } }
                ]
              },

              // Connection section
              {
                tag: 'section',
                attributes: { 'aria-labelledby': 'hook-heading' },
                children: [
                  {
                    tag: 'div',
                    attributes: { class: 'section-title header-controls' },
                    children: [
                      { tag: 'h2', attributes: { id: 'hook-heading' }, text: 'Connection' },
                      {
                        tag: 'div',
                        attributes: { class: 'title-actions' },
                        children: [
                          { tag: 'button', attributes: { id: 'reset-tab', class: 'secondary compact danger-outline', title: 'Reset' }, text: 'Reset' },
                          { tag: 'input', attributes: { id: 'hook-autostart', type: 'checkbox', 'aria-label': 'Hook dauerhaft', title: 'Hook dauerhaft: Off' } },
                          { tag: 'span', attributes: { class: 'status-led off', 'data-switch-status': 'hook-autostart', role: 'status' } }
                        ]
                      }
                    ]
                  },
                  {
                    tag: 'div',
                    attributes: { class: 'button-row' },
                    children: [
                      { tag: 'button', attributes: { id: 'toggle-hook', class: 'primary', 'aria-label': 'Connection', 'aria-pressed': 'false' }, text: 'On' },
                      { tag: 'button', attributes: { id: 'open-connection-settings', class: 'secondary compact settings-button', type: 'button', 'aria-label': 'Connection-Einstellungen öffnen', 'aria-haspopup': 'dialog' } },
                      { tag: 'button', attributes: { id: 'open-embed-live', class: 'secondary' }, text: 'Embed' },
                      { tag: 'button', attributes: { id: 'open-normal-live', class: 'secondary' }, text: 'Browser' },
                      { tag: 'button', attributes: { id: 'player-vlc-frame', class: 'secondary compact' }, text: 'Player' }
                    ]
                  },
                  { tag: 'div', attributes: { class: 'connection-status' }, children: [
                    { tag: 'span', attributes: { id: 'hook-led', class: 'status-led off', role: 'status', 'aria-label': 'Hook inaktiv', title: 'Hook inaktiv' } },
                    { tag: 'p', attributes: { id: 'hook-status', class: 'inline-status' } }
                  ]},
                  { tag: 'p', attributes: { id: 'embed-startup-status', class: 'inline-status', role: 'status', 'aria-live': 'polite', hidden: true } },
                  { tag: 'button', attributes: { id: 'cancel-embed-startup', class: 'secondary', hidden: true }, text: 'Embed-Start abbrechen' },
                  { tag: 'p', attributes: { id: 'hook-reconnect-status', class: 'inline-status', role: 'status' }, text: 'Hook-Reconnect: aus' },
                  { tag: 'p', attributes: { id: 'player-recovery-status', class: 'inline-status', role: 'status' }, text: 'Player-Recovery: aus' }
                ]
              },

              // Player section
              {
                tag: 'section',
                attributes: { 'aria-labelledby': 'player-heading' },
                children: [
                  {
                    tag: 'div',
                    attributes: { class: 'section-title header-controls' },
                    children: [
                      { tag: 'h2', attributes: { id: 'player-heading' }, text: 'Player' },
                      {
                        tag: 'div',
                        attributes: { class: 'title-actions' },
                        children: [
                          { tag: 'button', attributes: { id: 'player-replay', class: 'secondary compact', title: 'Neu laden' }, text: 'Neu laden' },
                          { tag: 'input', attributes: { id: 'limiter-enabled', type: 'checkbox', 'aria-label': 'Pegelschutz', title: 'Pegelschutz: Off' } },
                          { tag: 'span', attributes: { class: 'status-led off', 'data-switch-status': 'limiter-enabled', role: 'status' } }
                        ]
                      }
                    ]
                  },
                  { tag: 'div', attributes: { class: 'player-controls', role: 'group', 'aria-label': 'TikTok-Player steuern' }, children: [
                    { tag: 'button', attributes: { id: 'player-play', class: 'secondary compact' }, text: 'Play' },
                    { tag: 'button', attributes: { id: 'player-mute', class: 'secondary compact' }, text: 'Mute' },
                    { tag: 'button', attributes: { id: 'player-pip', class: 'secondary compact' }, text: 'Bild-in-Bild' },
                    { tag: 'button', attributes: { id: 'player-fullscreen', class: 'secondary compact' }, text: 'Vollbild' },
                    { tag: 'button', attributes: { id: 'player-report', class: 'secondary compact danger-outline' }, text: 'Meldung' }
                  ]},
                  { tag: 'div', attributes: { class: 'audio-controls' }, children: [
                    { tag: 'div', attributes: { class: 'control-label' }, children: [
                      { tag: 'label', attributes: { for: 'player-volume' }, text: 'Lautstärke' },
                      { tag: 'output', attributes: { id: 'player-volume-output', for: 'player-volume' }, text: '–' }
                    ]},
                    { tag: 'input', attributes: { id: 'player-volume', type: 'range', min: '0', max: '100', step: '1', value: '100' } },
                    { tag: 'div', attributes: { class: 'audio-meter-row' }, children: [
                      { tag: 'span', text: 'Spitzenpegel' },
                      { tag: 'strong', attributes: { id: 'player-peak' }, text: '–' }
                    ]},
                    { tag: 'div', attributes: { class: 'control-label' }, children: [
                      { tag: 'label', attributes: { for: 'limiter-strength' }, text: 'Schutzstärke' },
                      { tag: 'output', attributes: { id: 'limiter-strength-output', for: 'limiter-strength' }, text: '30' }
                    ]},
                    { tag: 'input', attributes: { id: 'limiter-strength', type: 'range', min: '0', max: '100', step: '1', value: '30' } }
                  ]},
                  { tag: 'p', attributes: { id: 'multi-guest-status', class: 'inline-status' }, text: 'Verbundene Streams: noch nicht erkannt.' },
                  { tag: 'p', attributes: { id: 'player-status', role: 'status', class: 'inline-status' }, text: 'Warte auf den TikTok-Player.' },
                  { tag: 'span', attributes: { id: 'player-time', class: 'player-time', hidden: true }, text: '–' }
                ]
              },

              // Top chatters section
              {
                tag: 'section',
                attributes: { 'aria-labelledby': 'top-chatters-heading' },
                children: [
                  {
                    tag: 'div',
                    attributes: { class: 'section-title' },
                    children: [
                      { tag: 'h2', attributes: { id: 'top-chatters-heading' }, text: 'Top-Chatter' },
                      { tag: 'button', attributes: { id: 'open-audience', class: 'secondary compact' }, text: 'Zuschauer*innen' }
                    ]
                  },
                  { tag: 'p', attributes: { id: 'team-tag-status', class: 'inline-status' }, text: 'Teamkürzel: noch nicht erkannt.' },
                  { tag: 'div', attributes: { id: 'top-chatters', class: 'top-chatters empty' }, text: 'Noch keine Personen im Chat beobachtet.' },
                  { tag: 'div', attributes: { id: 'top-chatters-actions', class: 'top-chatters-actions', hidden: true }, children: [
                    { tag: 'button', attributes: { id: 'top-chatters-reset', class: 'top-chatter-link', type: 'button', hidden: true }, text: 'Reset' },
                    { tag: 'button', attributes: { id: 'top-chatters-more', class: 'top-chatter-link', type: 'button' }, text: 'mehr…' }
                  ]}
                ]
              },

              // Recommendations section
              {
                tag: 'section',
                attributes: { id: 'recommendations-section', 'aria-labelledby': 'recommendations-heading' },
                children: [
                  {
                    tag: 'div',
                    attributes: { class: 'section-title' },
                    children: [
                      { tag: 'h2', attributes: { id: 'recommendations-heading' }, text: 'LIVE-Empfehlungen' },
                      { tag: 'span', attributes: { id: 'recommendation-status', class: 'live-indicator' }, text: 'bereit' }
                    ]
                  },
                  { tag: 'div', attributes: { class: 'recommendation-controls' }, children: [
                    { tag: 'label', children: [
                      { tag: 'span', text: 'Anzahl' },
                      { tag: 'input', attributes: { id: 'recommendation-limit', type: 'number', min: '1', max: '300', step: '1', value: '20', inputmode: 'numeric' } }
                    ]},
                    { tag: 'label', children: [
                      { tag: 'span', text: 'Sortierung' },
                      { tag: 'select', attributes: { id: 'recommendation-sort' }, children: [
                        { tag: 'option', attributes: { value: 'tiktok' }, text: 'TikTok-Reihenfolge' },
                        { tag: 'option', attributes: { value: 'viewers' }, text: 'Zuschauer*innen' }
                      ]}
                    ]}
                  ]},
                  {
                    tag: 'div',
                    attributes: { class: 'button-row' },
                    children: [
                      { tag: 'button', attributes: { id: 'scan-recommendations', class: 'primary' }, text: 'Empfehlungen scannen' },
                      { tag: 'button', attributes: { id: 'cancel-recommendations', class: 'secondary', hidden: true }, text: 'Abbrechen' }
                    ]
                  },
                  { tag: 'p', attributes: { id: 'recommendation-progress', class: 'inline-status', 'aria-live': 'polite' }, text: 'Noch kein Scan gestartet.' },
                  { tag: 'div', attributes: { id: 'recommendation-list', class: 'recommendation-list empty' }, text: 'Noch keine Empfehlungen erfasst.' },
                  { tag: 'div', attributes: { id: 'recommendation-actions', class: 'top-chatters-actions', hidden: true }, children: [
                    { tag: 'button', attributes: { id: 'recommendation-more', class: 'top-chatter-link', type: 'button' }, text: 'mehr…' }
                  ]}
                ]
              },

              // Caption section
              {
                tag: 'section',
                attributes: { 'aria-labelledby': 'caption-heading' },
                children: [
                  {
                    tag: 'div',
                    attributes: { class: 'section-title' },
                    children: [
                      { tag: 'h2', attributes: { id: 'caption-heading' }, text: 'Titel' },
                      { tag: 'button', attributes: { id: 'scan', class: 'secondary' }, text: 'Status' }
                    ]
                  },
                  { tag: 'div', attributes: { id: 'caption-status', class: 'status-grid' } },
                  { tag: 'button', attributes: { id: 'enable-captions', class: 'primary' }, text: 'Untertitel' },
                  { tag: 'p', attributes: { id: 'caption-action-status', role: 'status', class: 'inline-status action-status' } }
                ]
              },

              // Song section
              {
                tag: 'section',
                attributes: { 'aria-labelledby': 'song-heading' },
                children: [
                  {
                    tag: 'div',
                    attributes: { class: 'section-title header-controls' },
                    children: [
                      { tag: 'h2', attributes: { id: 'song-heading' }, text: 'Songs' },
                      {
                        tag: 'div',
                        attributes: { class: 'title-actions' },
                        children: [
                          { tag: 'input', attributes: { id: 'song-enabled', type: 'checkbox', 'aria-label': 'Songerkennung', title: 'Songerkennung: Off' } },
                          { tag: 'span', attributes: { id: 'song-led', class: 'status-led off', 'data-switch-status': 'song-enabled', role: 'status', 'aria-label': 'Songerkennung inaktiv' } }
                        ]
                      }
                    ]
                  },
                  { tag: 'button', attributes: { id: 'recognize-song', class: 'primary', disabled: true }, text: 'Jetzt erkennen' },
                  { tag: 'p', attributes: { id: 'song-status', class: 'inline-status' } },
                  { tag: 'div', attributes: { id: 'song-result', class: 'song-result', hidden: true } }
                ]
              },

              // Links section
              {
                tag: 'section',
                attributes: { 'aria-labelledby': 'links-heading' },
                children: [
                  {
                    tag: 'div',
                    attributes: { class: 'section-title' },
                    children: [
                      { tag: 'h2', attributes: { id: 'links-heading' }, text: 'HAR-Logs' },
                      { tag: 'span', attributes: { id: 'media-count', class: 'count' }, text: '0' }
                    ]
                  },
                  { tag: 'div', attributes: { id: 'media-list', class: 'list empty' }, text: 'Noch keine FLV-/HLS-Links erkannt.' }
                ]
              },

              // Log section
              {
                tag: 'section',
                attributes: { 'aria-labelledby': 'log-heading' },
                children: [
                  {
                    tag: 'div',
                    attributes: { class: 'section-title header-controls' },
                    children: [
                      { tag: 'h2', attributes: { id: 'log-heading' }, text: 'LIVE-Logs' },
                      {
                        tag: 'div',
                        attributes: { class: 'title-actions' },
                        children: [
                          { tag: 'span', attributes: { class: 'status-led off', 'data-counter-status': 'caption-count', role: 'status' } },
                          { tag: 'span', attributes: { id: 'caption-count', class: 'count' }, text: '0' },
                          { tag: 'button', attributes: { id: 'clear', class: 'ghost compact', title: 'Reset' }, text: 'Reset' },
                          { tag: 'input', attributes: { id: 'live-logs-enabled', type: 'checkbox', 'aria-label': 'LIVE-Logs', title: 'LIVE-Logs: Off' } },
                          { tag: 'span', attributes: { class: 'status-led off', 'data-switch-status': 'live-logs-enabled', role: 'status', 'aria-label': 'LIVE-Logs: deaktiviert' } }
                        ]
                      }
                    ]
                  },
                  {
                    tag: 'div',
                    attributes: { class: 'button-row' },
                    children: [
                      { tag: 'button', attributes: { id: 'export-log', class: 'secondary' }, text: 'JSON-L-Export' },
                      { tag: 'button', attributes: { id: 'export-caption-raw', class: 'secondary' }, text: 'RAW-JSON-Export' }
                    ]
                  },
                  { tag: 'div', attributes: { id: 'caption-list', class: 'list empty' }, text: 'Noch keine CaptionMessages empfangen.' }
                ]
              },

              // Debug section
              {
                tag: 'section',
                attributes: { 'aria-labelledby': 'debug-heading' },
                children: [
                  {
                    tag: 'div',
                    attributes: { class: 'section-title header-controls' },
                    children: [
                      { tag: 'h2', attributes: { id: 'debug-heading' }, text: 'Debugmodus' },
                      {
                        tag: 'div',
                        attributes: { class: 'title-actions' },
                        children: [
                          { tag: 'span', attributes: { class: 'status-led off', 'data-counter-status': 'debug-count', role: 'status' } },
                          { tag: 'span', attributes: { id: 'debug-count', class: 'count' }, text: '0' },
                          { tag: 'button', attributes: { id: 'clear-debug', class: 'ghost compact', title: 'Reset' }, text: 'Reset' },
                          { tag: 'input', attributes: { id: 'debug-enabled', type: 'checkbox', 'aria-label': 'Diagnoseereignisse für diesen Tab protokollieren', title: 'Diagnoseereignisse für diesen Tab protokollieren: Off' } },
                          { tag: 'span', attributes: { class: 'status-led off', 'data-switch-status': 'debug-enabled', role: 'status' } }
                        ]
                      }
                    ]
                  },
                  {
                    tag: 'div',
                    attributes: { class: 'button-row' },
                    children: [
                      { tag: 'button', attributes: { id: 'export-debug', class: 'secondary' }, text: 'Debug exportieren' }
                    ]
                  },
                  { tag: 'p', attributes: { class: 'muted small' } }
                ]
              },

              // Audience modal
              {
                tag: 'div',
                attributes: { id: 'audience-modal', class: 'modal-backdrop', hidden: true },
                children: [
                  {
                    tag: 'section',
                    attributes: { class: 'modal', role: 'dialog', 'aria-modal': 'true', 'aria-labelledby': 'audience-heading' },
                    children: [
                      {
                        tag: 'div',
                        attributes: { class: 'section-title' },
                        children: [
                          { tag: 'h2', attributes: { id: 'audience-heading' }, text: 'Im Chat beobachtete Personen' },
                          { tag: 'button', attributes: { id: 'close-audience', class: 'secondary compact', 'aria-label': 'Übersicht schließen' }, text: 'Schließen' }
                        ]
                      },
                      { tag: 'p', attributes: { id: 'audience-limit', class: 'inline-status' } },
                      { tag: 'div', attributes: { id: 'audience-list', class: 'audience-list' } }
                    ]
                  }
                ]
              },

              // Speech settings modal
              {
                tag: 'div',
                attributes: { id: 'speech-settings-modal', class: 'modal-backdrop', hidden: true },
                children: [
                  {
                    tag: 'section',
                    attributes: { class: 'modal', role: 'dialog', 'aria-modal': 'true', 'aria-labelledby': 'speech-settings-heading' },
                    children: [
                      {
                        tag: 'div',
                        attributes: { class: 'section-title' },
                        children: [
                          { tag: 'h2', attributes: { id: 'speech-settings-heading' }, text: 'Erweiterte Einstellungen' },
                          { tag: 'button', attributes: { id: 'close-speech-settings', class: 'secondary compact', 'aria-label': 'Einstellungen schließen' }, text: 'Schließen' }
                        ]
                      },
                      {
                        tag: 'div',
                        attributes: { class: 'settings-grid speech-integration-settings' },
                        children: [
                          {
                            tag: 'label',
                            attributes: { class: 'icon-style-setting' },
                            children: [
                              { tag: 'span', text: 'Icon-Stil' },
                              {
                                tag: 'select',
                                attributes: { id: 'icon-style' },
                                children: [
                                  { tag: 'option', attributes: { value: 'plastisch' }, text: '3D / Plastisch' },
                                  { tag: 'option', attributes: { value: 'glass' }, text: 'Glass / Realistisch' },
                                  { tag: 'option', attributes: { value: 'linear' }, text: 'Minimal / Linear' }
                                ]
                              }
                            ]
                          },
                          {
                            tag: 'label',
                            children: [
                              { tag: 'span', text: 'Sprache' },
                              {
                                tag: 'select',
                                attributes: { id: 'speech-language' },
                                children: [
                                  { tag: 'option', attributes: { value: 'auto' }, text: 'Auto' },
                                  { tag: 'option', attributes: { value: 'de-DE' }, text: 'Deutsch' },
                                  { tag: 'option', attributes: { value: 'en-US' }, text: 'Englisch' },
                                  { tag: 'option', attributes: { value: 'ru-RU' }, text: 'Russisch' },
                                  { tag: 'option', attributes: { value: 'uk-UA' }, text: 'Ukrainisch' },
                                  { tag: 'option', attributes: { value: 'bg-BG' }, text: 'Bulgarisch' },
                                  { tag: 'option', attributes: { value: 'sr-RS' }, text: 'Serbisch' },
                                  { tag: 'option', attributes: { value: 'kk-KZ' }, text: 'Kasachisch' },
                                  { tag: 'option', attributes: { value: 'zh-CN' }, text: 'Chinesisch' },
                                  { tag: 'option', attributes: { value: 'ja-JP' }, text: 'Japanisch' },
                                  { tag: 'option', attributes: { value: 'ko-KR' }, text: 'Koreanisch' },
                                  { tag: 'option', attributes: { value: 'ar-JO' }, text: 'Arabisch' },
                                  { tag: 'option', attributes: { value: 'fa-IR' }, text: 'Persisch' },
                                  { tag: 'option', attributes: { value: 'ur-PK' }, text: 'Urdu' },
                                  { tag: 'option', attributes: { value: 'hi-IN' }, text: 'Hindi' },
                                  { tag: 'option', attributes: { value: 'ne-NP' }, text: 'Nepali' },
                                  { tag: 'option', attributes: { value: 'ml-IN' }, text: 'Malayalam' }
                                ]
                              }
                            ]
                          },
                          {
                            tag: 'label',
                            children: [
                              { tag: 'span', text: 'Stimme' },
                              {
                                tag: 'select',
                                attributes: { id: 'speech-voice' },
                                children: [
                                  { tag: 'option', attributes: { value: '' }, text: 'Standard' }
                                ]
                              }
                            ]
                          },
                          {
                            tag: 'label',
                            attributes: { id: 'audd-token-setting' },
                            children: [
                              { tag: 'span', attributes: { id: 'audd-token-label' }, text: 'AudD API-Token (optional - ' },
                              { tag: 'a', attributes: { href: 'https://audd.io/', target: '_blank', rel: 'noopener noreferrer' }, text: 'https://AudD.io' },
                              { tag: 'span', text: ' Trial/Paid)' },
                              { tag: 'input', attributes: { id: 'audd-token', type: 'password', autocomplete: 'off', spellcheck: 'false' } }
                            ]
                          },
                          {
                            tag: 'label',
                            attributes: { id: 'pairing-code-setting' },
                            children: [
                              { tag: 'span', text: 'Pairing-Code' },
                              { tag: 'input', attributes: { id: 'pairing-code', type: 'password', autocomplete: 'off', spellcheck: 'false' } }
                            ]
                          },
                          {
                            tag: 'label',
                            children: [
                              { tag: 'span', text: 'Universal API-Key' },
                              { tag: 'input', attributes: { id: 'universal-caption-api-key', type: 'password', autocomplete: 'off', spellcheck: 'false' } }
                            ]
                          }
                        ]
                      },
                      { tag: 'label', attributes: { class: 'option-row' }, children: [
                        { tag: 'input', attributes: { id: 'speak-names', type: 'checkbox', checked: true } },
                        { tag: 'span', text: ' Chatnamen sprechen' }
                      ]},
                      { tag: 'label', attributes: { class: 'option-row' }, children: [
                        { tag: 'input', attributes: { id: 'shorten-names', type: 'checkbox' } },
                        { tag: 'span', text: ' Chatnamen kürzen' }
                      ]},
                      { tag: 'label', attributes: { class: 'option-row auto-chat-refresh' }, children: [
                        { tag: 'input', attributes: { id: 'auto-chat-refresh', type: 'checkbox' } },
                        { tag: 'span', text: ' Auto-Chat Refresh ' },
                        { tag: 'input', attributes: { id: 'auto-chat-refresh-minutes', type: 'number', min: '1', max: '60', step: '1', value: '5', inputmode: 'numeric', 'aria-label': 'Auto-Chat-Refresh in Minuten' } },
                        { tag: 'span', text: 'min.' }
                      ]},
                      { tag: 'label', attributes: { class: 'option-row' }, children: [
                        { tag: 'input', attributes: { id: 'game-mode', type: 'checkbox' } },
                        { tag: 'span', text: ' Game-Mode (Spam-, Emoji, usw. Chatfilter)' }
                      ]},
                      { tag: 'div', attributes: { class: 'option-row external-speech-trigger-row' }, children: [
                        { tag: 'label', children: [
                          { tag: 'input', attributes: { id: 'filter-external-speech-triggers', type: 'checkbox' } },
                          { tag: 'span', text: ' Trigger filtern (ext. Sprachdienste)' }
                        ]},
                        { tag: 'input', attributes: { id: 'external-speech-trigger-characters', type: 'text', value: '.', maxlength: '10', 'aria-label': 'Triggerzeichen, maximal fünf Sonderzeichen', autocomplete: 'off', spellcheck: 'false' } }
                      ]},
                      { tag: 'label', attributes: { class: 'option-row' }, children: [
                        { tag: 'input', attributes: { id: 'keep-speech-active', type: 'checkbox', 'aria-label': 'Vorlesen dauerhaft', title: 'Vorlesen dauerhaft: Off' } },
                        { tag: 'span', text: ' Vorlesen dauerhaft' }
                      ]}
                    ]
                  }
                ]
              },

              // Chat history modal
              {
                tag: 'div',
                attributes: { id: 'chat-history-modal', class: 'modal-backdrop', hidden: true },
                children: [
                  {
                    tag: 'section',
                    attributes: { class: 'modal', role: 'dialog', 'aria-modal': 'true', 'aria-labelledby': 'chat-history-heading' },
                    children: [
                      {
                        tag: 'div',
                        attributes: { class: 'section-title' },
                        children: [
                          { tag: 'h2', attributes: { id: 'chat-history-heading' }, text: 'Gesammelte Chatnachrichten' },
                          { tag: 'button', attributes: { id: 'close-chat-history', class: 'secondary compact', 'aria-label': 'Chatzeilen schließen' }, text: 'Schließen' }
                        ]
                      },
                      { tag: 'p', attributes: { id: 'chat-history-limit', class: 'inline-status' } },
                      { tag: 'div', attributes: { id: 'chat-history-list', class: 'chat-history-list' } }
                    ]
                  }
                ]
              },

              // Recommendation modal
              {
                tag: 'div',
                attributes: { id: 'recommendation-modal', class: 'modal-backdrop', hidden: true },
                children: [
                  {
                    tag: 'section',
                    attributes: { class: 'modal', role: 'dialog', 'aria-modal': 'true', 'aria-labelledby': 'recommendation-modal-heading' },
                    children: [
                      {
                        tag: 'div',
                        attributes: { class: 'section-title' },
