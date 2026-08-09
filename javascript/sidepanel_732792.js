#!/usr/bin/env node
// sidepanel.html — portiert nach javascript
// Quelle: html, Projects@TikTok-Live-Companion:plugin-source/browser-extension/sidepanel.html
// auch in: Projects@TikTok-Live-Companion:release/0.7.1/tiktok-live-companion-extension-0.7.1/sidepanel.html
// auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/sidepanel.html
// auch in: Projects@TikTok-Live-Companion-Android:release/0.7.1/tiktok-live-companion-extension-0.7.1/sidepanel.html
// auch in: 2 weiteren Fundstellen
// Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

import { writeFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

function createSidepanelHTML() {
  const doc = {
    doctype: '<!doctype html>',
    html: {
      attributes: { lang: 'de' },
      head: {
        meta: [
          { charset: 'utf-8' },
          { name: 'viewport', content: 'width=device-width, initial-scale=1' }
        ],
        title: 'TikTok LIVE Companion',
        link: { rel: 'stylesheet', href: 'sidepanel.css' }
      },
      body: {
        header: {
          p: {
            attributes: { id: 'page-title', class: 'muted' },
            content: 'Kein TikTok-Tab ausgewählt'
          }
        },
        main: {
          section: [
            {
              attributes: { 'aria-labelledby': 'chat-heading' },
              content: [
                {
                  div: {
                    attributes: { class: 'section-title' },
                    content: [
                      { h2: { attributes: { id: 'chat-heading' }, content: 'Chatzeilen' } },
                      {
                        div: {
                          attributes: { class: 'title-actions' },
                          content: [
                            { span: { attributes: { id: 'chat-led', class: 'status-led off', role: 'status', 'aria-label': 'Chat inaktiv', title: 'Chat inaktiv' } } },
                            { button: { attributes: { id: 'chat-count', class: 'count count-button', type: 'button', 'aria-haspopup': 'dialog', title: 'Gesammelte Chatzeilen öffnen' }, content: '0' } },
                            { button: { attributes: { id: 'refresh-chat', class: 'secondary compact', title: 'Chatanzeige leeren' }, content: 'Refresh' } },
                            { button: { attributes: { id: 'toggle-speech', class: 'secondary compact', 'aria-pressed': 'false' }, content: 'Vorlesen an' } },
                            { span: { attributes: { id: 'speech-led', class: 'status-led off', role: 'status', 'aria-label': 'Vorlesen inaktiv', title: 'Vorlesen inaktiv' } } }
                          ]
                        }
                      }
                    ]
                  }
                },
                { div: { attributes: { id: 'chat-list', class: 'chat-list empty', role: 'log', 'aria-live': 'polite', 'aria-relevant': 'additions', 'aria-label': 'Die letzten fünf bereinigten Chatnachrichten' }, content: 'Noch keine Chatnachrichten erkannt.' } },
                { p: { attributes: { id: 'speech-status', role: 'status', class: 'inline-status' }, content: 'Vorlesen ist ausgeschaltet.' } },
                { div: { attributes: { class: 'control-label' }, content: [
                  { label: { attributes: { for: 'speech-volume' }, content: 'Vorleselautstärke' } },
                  { output: { attributes: { id: 'speech-volume-output', for: 'speech-volume' }, content: '100%' } }
                ] } },
                { input: { attributes: { id: 'speech-volume', type: 'range', min: '0', max: '100', step: '5', value: '50' } } },
                {
                  div: { attributes: { class: 'settings-grid speech-settings' },
                    content: [
                      {
                        label: {
                          content: [
                            { span: { content: 'Sprache' } },
                            {
                              select: {
                                attributes: { id: 'speech-language' },
                                option: [
                                  { attributes: { value: 'auto' }, content: 'Auto' },
                                  { attributes: { value: 'de-DE' }, content: 'Deutsch' },
                                  { attributes: { value: 'en-US' }, content: 'Englisch' },
                                  { attributes: { value: 'ru-RU' }, content: 'Russisch' },
                                  { attributes: { value: 'uk-UA' }, content: 'Ukrainisch' },
                                  { attributes: { value: 'bg-BG' }, content: 'Bulgarisch' },
                                  { attributes: { value: 'sr-RS' }, content: 'Serbisch' },
                                  { attributes: { value: 'kk-KZ' }, content: 'Kasachisch' },
                                  { attributes: { value: 'zh-CN' }, content: 'Chinesisch' },
                                  { attributes: { value: 'ja-JP' }, content: 'Japanisch' },
                                  { attributes: { value: 'ko-KR' }, content: 'Koreanisch' },
                                  { attributes: { value: 'ar-JO' }, content: 'Arabisch' },
                                  { attributes: { value: 'fa-IR' }, content: 'Persisch' },
                                  { attributes: { value: 'ur-PK' }, content: 'Urdu' },
                                  { attributes: { value: 'hi-IN' }, content: 'Hindi' },
                                  { attributes: { value: 'ne-NP' }, content: 'Nepali' },
                                  { attributes: { value: 'ml-IN' }, content: 'Malayalam' }
                                ]
                              }
                            }
                          ]
                        }
                      },
                      {
                        label: {
                          content: [
                            { span: { content: 'Stimme' } },
                            {
                              select: {
                                attributes: { id: 'speech-voice' },
                                option: { attributes: { value: '' }, content: 'Standard' }
                              }
                            }
                          ]
                        }
                      },
                      {
                        label: {
                          attributes: { id: 'audd-token-setting' },
                          content: [
                            {
                              span: {
                                attributes: { id: 'audd-token-label' },
                                content: [
                                  'AudD API-Token (optional - ',
                                  { a: { attributes: { href: 'https://audd.io/', target: '_blank', rel: 'noopener noreferrer' }, content: 'https://AudD.io' } },
                                  ' Trial/Paid )'
                                ]
                              }
                            },
                            { input: { attributes: { id: 'audd-token', type: 'password', autocomplete: 'off', spellcheck: 'false' } } }
                          ]
                        }
                      },
                      {
                        label: {
                          attributes: { id: 'pairing-code-setting' },
                          content: [
                            { span: { content: 'Pairing-Code' } },
                            { input: { attributes: { id: 'pairing-code', type: 'password', autocomplete: 'off', spellcheck: 'false' } } }
                          ]
                        }
                      }
                    ]
                  }
                },
                {
                  div: { attributes: { class: 'button-row' },
                    content: [
                      { button: { attributes: { id: 'service-action', class: 'secondary' }, content: 'Sprachdienst installieren' } },
                      { button: { attributes: { id: 'sherpa-action', class: 'secondary' }, content: 'Sherpa installieren' } }
                    ]
                  }
                },
                { p: { attributes: { id: 'service-status', class: 'inline-status' }, content: 'Lokaler Sprachdienst noch nicht geprüft.' } },
                { div: { attributes: { id: 'service-setup', class: 'inline-status', hidden: true }, content: { button: { attributes: { id: 'copy-service-setup', class: 'secondary compact' }, content: 'Installation abschließen!' } } } },
                { label: { attributes: { class: 'option-row' }, content: [{ input: { attributes: { id: 'speak-names', type: 'checkbox', checked: true } } }, ' Chatnamen sprechen'] } },
                { label: { attributes: { class: 'option-row' }, content: [{ input: { attributes: { id: 'shorten-names', type: 'checkbox' } } }, ' Chatnamen kürzen'] } },
                { label: { attributes: { class: 'option-row' }, content: [{ input: { attributes: { id: 'game-mode', type: 'checkbox' } } }, ' Game-Mode'] } },
                {
                  label: {
                    attributes: { class: 'option-row auto-chat-refresh' },
                    content: [
                      { input: { attributes: { id: 'auto-chat-refresh', type: 'checkbox' } } },
                      ' Auto-Chat Refresh ',
                      { input: { attributes: { id: 'auto-chat-refresh-minutes', type: 'number', min: '1', max: '60', step: '1', value: '5', inputmode: 'numeric', 'aria-label': 'Auto-Chat-Refresh in Minuten' } } },
                      { span: { content: 'min.' } }
                    ]
                  }
                },
                { label: { attributes: { class: 'option-row' }, content: [{ input: { attributes: { id: 'keep-speech-active', type: 'checkbox' } } }, ' Permanent aktiv'] } }
              ]
            },
            {
              attributes: { 'aria-labelledby': 'top-chatters-heading' },
              content: [
                {
                  div: {
                    attributes: { class: 'section-title' },
                    content: [
                      { h2: { attributes: { id: 'top-chatters-heading' }, content: 'Top-Chatter' } },
                      { button: { attributes: { id: 'open-audience', class: 'secondary compact' }, content: 'Zuschauer*innen' } }
                    ]
                  }
                },
                { p: { attributes: { id: 'team-tag-status', class: 'inline-status' }, content: 'Teamkürzel: noch nicht erkannt.' } },
                { div: { attributes: { id: 'top-chatters', class: 'top-chatters empty' }, content: 'Noch keine Personen im Chat beobachtet.' } },
                { div: { attributes: { id: 'top-chatters-actions', class: 'top-chatters-actions', hidden: true }, content: [
                  { button: { attributes: { id: 'top-chatters-reset', class: 'top-chatter-link', type: 'button', hidden: true }, content: 'Reset' } },
                  { button: { attributes: { id: 'top-chatters-more', class: 'top-chatter-link', type: 'button' }, content: 'mehr…' } }
                ] } }
              ]
            },
            {
              attributes: { id: 'page-info-section', 'aria-labelledby': 'page-info-heading' },
              content: [
                {
                  div: {
                    attributes: { class: 'section-title' },
                    content: [
                      { h2: { attributes: { id: 'page-info-heading' }, content: 'Seiteninformationen' } },
                      {
                        div: {
                          attributes: { class: 'title-actions' },
                          content: [
                            { span: { attributes: { id: 'page-info-source', class: 'live-indicator' }, content: 'Metadaten' } },
                            { button: { attributes: { id: 'refresh-page-info', class: 'secondary compact' }, content: 'Refresh' } },
                            { button: { attributes: { id: 'force-page-info', class: 'secondary compact danger-outline' }, content: 'Force' } }
                          ]
                        }
                      }
                    ]
                  }
                },
                { div: { attributes: { id: 'profile-info', class: 'profile-info', hidden: true } } },
                { div: { attributes: { id: 'summary-info', class: 'summary-info' } } }
              ]
            },
            {
              attributes: { 'aria-labelledby': 'stats-heading' },
              content: [
                {
                  div: {
                    attributes: { class: 'section-title' },
                    content: [
                      { h2: { attributes: { id: 'stats-heading' }, content: 'LIVE-Informationen' } },
                      { span: { attributes: { id: 'stats-live', class: 'live-indicator' }, content: 'warte' } }
                    ]
                  }
                },
                { div: { attributes: { id: 'live-stats', class: 'status-grid stats-grid' } } },
                { p: { attributes: { id: 'stats-status', class: 'inline-status' } } }
              ]
            },
            {
              attributes: { 'aria-labelledby': 'hook-heading' },
              content: [
                {
                  div: {
                    attributes: { class: 'section-title' },
                    content: [
                      { h2: { attributes: { id: 'hook-heading' }, content: 'WebSocket-Hook' } },
                      { span: { attributes: { id: 'hook-led', class: 'status-led off', role: 'status', 'aria-label': 'Hook inaktiv', title: 'Hook inaktiv' } } }
                    ]
                  }
                },
                {
                  div: {
                    attributes: { class: 'button-row' },
                    content: [
                      { button: { attributes: { id: 'enable-hook', class: 'primary' }, content: 'Hook setzen' } },
                      { button: { attributes: { id: 'disable-hook', class: 'secondary' }, content: 'Hook deaktivieren' } },
                      { button: { attributes: { id: 'reset-tab', class: 'secondary danger-outline' }, content: 'Refresh' } },
                      { button: { attributes: { id: 'open-embed-live', class: 'secondary' }, content: 'Embed' } },
                      { button: { attributes: { id: 'open-normal-live', class: 'secondary' }, content: 'Normal' } },
                      { button: { attributes: { id: 'player-vlc-frame', class: 'secondary compact' }, content: 'VLC Ersatz' } }
                    ]
                  }
                },
                { p: { attributes: { id: 'hook-status', class: 'inline-status' } } },
                { label: { attributes: { class: 'option-row' }, content: [{ input: { attributes: { id: 'hook-autostart', type: 'checkbox' } } }, ' Permanent Hook'] } },
                { label: { attributes: { class: 'option-row' }, content: [{ input: { attributes: { id: 'quick-recover', type: 'checkbox' } } }, ' Auto-Reconnect'] } }
              ]
            },
            {
              attributes: { 'aria-labelledby': 'caption-heading' },
              content: [
                {
                  div: {
                    attributes: { class: 'section-title' },
                    content: [
                      { h2: { attributes: { id: 'caption-heading' }, content: 'Untertitel' } },
                      { button: { attributes: { id: 'scan', class: 'secondary' }, content: 'Seite prüfen' } }
                    ]
                  }
                },
                { div: { attributes: { id: 'caption-status', class: 'status-grid' } } },
                { button: { attributes: { id: 'enable-captions', class: 'primary' }, content: 'Untertitel aktivieren' } },
                { p: { attributes: { id: 'caption-action-status', role: 'status', class: 'inline-status action-status' } } }
              ]
            },
            {
              attributes: { 'aria-labelledby': 'player-heading' },
              content: [
                {
                  div: {
                    attributes: { class: 'section-title' },
                    content: [
                      { h2: { attributes: { id: 'player-heading' }, content: 'Playersteuerung' } },
                      { span: { attributes: { id: 'player-time', class: 'player-time' }, content: '–' } }
                    ]
                  }
                },
                {
                  div: {
                    attributes: { class: 'player-controls', role: 'group', 'aria-label': 'TikTok-Player steuern' },
                    content: [
                      { button: { attributes: { id: 'player-play', class: 'secondary compact' }, content: 'Pause' } },
                      { button: { attributes: { id: 'player-replay', class: 'secondary compact' }, content: 'Neu laden' } },
                      { button: { attributes: { id: 'player-mute', class: 'secondary compact' }, content: 'Stumm' } },
                      { button: { attributes: { id: 'player-pip', class: 'secondary compact' }, content: 'Bild-in-Bild' } },
                      { button: { attributes: { id: 'player-fullscreen', class: 'secondary compact' }, content: 'Vollbild' } },
                      { button: { attributes: { id: 'player-report', class: 'secondary compact danger-outline' }, content: 'Melden öffnen' } }
                    ]
                  }
                },
                {
                  div: {
                    attributes: { class: 'audio-controls' },
                    content: [
                      {
                        div: {
                          attributes: { class: 'control-label' },
                          content: [
                            { label: { attributes: { for: 'player-volume' }, content: 'Lautstärke' } },
                            { output: { attributes: { id: 'player-volume-output', for: 'player-volume' }, content: '–' } }
                          ]
                        }
                      },
                      { input: { attributes: { id: 'player-volume', type: 'range', min: '0', max: '100', step: '1', value: '100' } } },
                      { div: { attributes: { class: 'audio-meter-row' }, content: [{ span: { content: 'Spitzenpegel' } }, { strong: { attributes: { id: 'player-peak' }, content: '–' } }] } },
                      { label: { attributes: { class: 'option-row' }, content: [{ input: { attributes: { id: 'limiter-enabled', type: 'checkbox' } } }, ' Pegelschutz aktivieren'] } },
                      {
                        div: {
                          attributes: { class: 'control-label' },
                          content: [
                            { label: { attributes: { for: 'limiter-strength' }, content: 'Schutzstärke' } },
                            { output: { attributes: { id: 'limiter-strength-output', for: 'limiter-strength' }, content: '30' } }
                          ]
                        }
                      },
                      { input: { attributes: { id: 'limiter-strength', type: 'range', min: '0', max: '100', step: '1', value: '30' } } }
                    ]
                  }
                },
                { p: { attributes: { id: 'multi-guest-status', class: 'inline-status' }, content: 'Verbundene Streams: noch nicht erkannt.' } },
                { p: { attributes: { id: 'player-status', role: 'status', class: 'inline-status' }, content: 'Warte auf den TikTok-Player.' } }
              ]
            },
            {
              attributes: { 'aria-labelledby': 'song-heading' },
              content: [
                {
                  div: {
                    attributes: { class: 'section-title' },
                    content: [
                      { h2: { attributes: { id: 'song-heading' }, content: 'Songerkennung' } },
                      { span: { attributes: { id: 'song-led', class: 'status-led off', role: 'status', 'aria-label': 'Songerkennung inaktiv' } } }
                    ]
                  }
                },
                { label: { attributes: { class: 'option-row' }, content: [{ input: { attributes: { id: 'song-enabled', type: 'checkbox' } } }, ' Songerkennung aktivieren'] } },
                { button: { attributes: { id: 'recognize-song', class: 'primary', disabled: true }, content: 'Jetzt erkennen' } },
                { p: { attributes: { id: 'song-status', class: 'inline-status' } } },
                { div: { attributes: { id: 'song-result', class: 'song-result', hidden: true } } }
              ]
            },
            {
              attributes: { 'aria-labelledby': 'links-heading' },
              content: [
                {
                  div: {
                    attributes: { class: 'section-title' },
                    content: [
                      { h2: { attributes: { id: 'links-heading' }, content: 'VLC-Links' } },
                      { span: { attributes: { id: 'media-count', class: 'count' }, content: '0' } }
                    ]
                  }
                },
                { div: { attributes: { id: 'media-list', class: 'list empty' }, content: 'Noch keine FLV-/HLS-Links erkannt.' } }
              ]
            },
            {
              attributes: { 'aria-labelledby': 'log-heading' },
              content: [
                {
                  div: {
                    attributes: { class: 'section-title' },
                    content: [
                      { h2: { attributes: { id: 'log-heading' }, content: 'Caption-Protokoll' } },
                      { span: { attributes: { id: 'caption-count', class: 'count' }, content: '0' } }
                    ]
                  }
                },
                {
                  div: {
                    attributes: { class: 'button-row' },
                    content: [
                      { button: { attributes: { id: 'export-log', class: 'secondary' }, content: 'JSONL exportieren' } },
                      { button: { attributes: { id: 'clear', class: 'ghost' }, content: 'Anzeige leeren' } }
                    ]
                  }
                },
                { div: { attributes: { id: 'caption-list', class: 'list empty' }, content: 'Noch keine CaptionMessages empfangen.' } }
              ]
            },
            {
              attributes: { 'aria-labelledby': 'debug-heading' },
              content: [
                {
                  div: {
                    attributes: { class: 'section-title' },
                    content: [
                      { h2: { attributes: { id: 'debug-heading' }, content: 'Debugmodus' } },
                      { span: { attributes: { id: 'debug-count', class: 'count' }, content: '0' } }
                    ]
                  }
                },
                { label: { attributes: { class: 'option-row' }, content: [{ input: { attributes: { id: 'debug-enabled', type: 'checkbox' } } }, ' Diagnoseereignisse für diesen Tab protokollieren'] } },
                {
                  div: {
                    attributes: { class: 'button-row' },
                    content: [
                      { button: { attributes: { id: 'export-debug', class: 'secondary' }, content: 'Debug exportieren' } },
                      { button: { attributes: { id: 'clear-debug', class: 'ghost' }, content: 'Debug leeren' } }
                    ]
                  }
                },
                { p: { attributes: { class: 'muted small' } } }
              ]
            },
            {
              div: {
                attributes: { id: 'audience-modal', class: 'modal-backdrop', hidden: true },
                content: {
                  section: {
                    attributes: { class: 'modal', role: 'dialog', 'aria-modal': 'true', 'aria-labelledby': 'audience-heading' },
                    content: [
                      {
                        div: {
                          attributes: { class: 'section-title' },
                          content: [
                            { h2: { attributes: { id: 'audience-heading' }, content: 'Im Chat beobachtete Personen' } },
                            { button: { attributes: { id: 'close-audience', class: 'secondary compact', 'aria-label': 'Übersicht schließen' }, content: 'Schließen' } }
                          ]
                        }
                      },
                      { p: { attributes: { id: 'audience-limit', class: 'inline-status' } } },
                      { div: { attributes: { id: 'audience-list', class: 'audience-list' } } }
                    ]
                  }
                }
              }
            },
            {
              div: {
                attributes: { id: 'chat-history-modal', class: 'modal-backdrop', hidden: true },
                content: {
                  section: {
                    attributes: { class: 'modal', role: 'dialog', 'aria-modal': 'true', 'aria-labelledby': 'chat-history-heading' },
                    content: [
                      {
                        div: {
                          attributes: { class: 'section-title' },
                          content: [
                            { h2: { attributes: { id: 'chat-history-heading' }, content: 'Gesammelte Chatzeilen' } },
                            { button: { attributes: { id: 'close-chat-history', class: 'secondary compact', 'aria-label': 'Chatzeilen schließen' }, content: 'Schließen' } }
                          ]
                        }
                      },
                      { p: { attributes: { id: 'chat-history-limit', class: 'inline-status' } } },
                      { div: { attributes: { id: 'chat-history-list', class: 'chat-history-list' } } }
                    ]
                  }
                }
              }
            },
            { p: { attributes: { id: 'notice', role: 'alert', class: 'notice' } } }
          ]
        },
        script: [
          { attributes: { src: 'content-core.js' } },
          { attributes: { src: 'sidepanel.js' } }
        ]
      }
    }
  };

  return generateHTML(doc);
}

function generateHTML(doc) {
  let html = doc.doctype + '\n';
  html += generateElement('html', doc.html, 0);
  return html;
}

function generateElement(tag, element, indentLevel) {
  if (typeof element === 'string') {
    return '  '.repeat(indentLevel) + element + '\n';
  }

  if (element === null || element === undefined) {
    return '';
  }

  let html = '';
  const indent = '  '.repeat(indentLevel);
  
  if (Array.isArray(element)) {
    for (const item of element) {
      html += generateElement(tag, item, indentLevel);
    }
    return html;
  }

  html += indent + '<' + tag;
  
  if (element.attributes) {
    for (const [key, value] of Object.entries(element.attributes)) {
      if (value === true) {
        html += ' ' + key;
      } else if (value !== false && value !== null && value !== undefined) {
        html += ' ' + key + '="' + value + '"';
      }
    }
  }
  
  if (element.content === undefined && !['input', 'br', 'hr', 'img', 'meta', 'link'].includes(tag)) {
    html += '></' + tag + '>\n';
    return html;
  }
  
  html += '>';
  
  if (element.content !== undefined) {
    if (typeof element.content === 'string') {
      html += element.content;
      html += '</' + tag + '>\n';
    } else if (Array.isArray(element.content)) {
      html += '\n';
      for (const item of element.content) {
        if (typeof item === 'string') {
          html += '  '.repeat(indentLevel + 1) + item + '\n';
        } else {
          for (const [childTag, childElement] of Object.entries(item)) {
            html += generateElement(childTag, childElement, indentLevel + 1);
          }
        }
      }
      html += indent + '</' + tag + '>\n';
    } else {
      html += '\n';
      for (const [childTag, childElement] of Object.entries(element.content)) {
        html += generateElement(childTag, childElement, indentLevel + 1);
      }
      html += indent + '</' + tag + '>\n';
    }
  } else {
    html += '</' + tag + '>\n';
  }
  
  return html;
}

function main() {
  const outputPath = process.argv[2] || join(__dirname, 'sidepanel.html');
  const htmlContent = createSidepanelHTML();
  writeFileSync(outputPath, htmlContent);
  console.log(`HTML file generated at: ${outputPath}`);
}

main();
