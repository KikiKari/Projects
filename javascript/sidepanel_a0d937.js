#!/usr/bin/env node
// sidepanel.html — portiert nach javascript
// Quelle: html, Projects@TikTok-Live-Companion:plugin-source/browser-extension/sidepanel.html
// auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/sidepanel.html
// auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/sidepanel.html
// Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

import { writeFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

function createDocument() {
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
            id: 'page-title', 
            class: 'muted', 
            text: 'Kein TikTok-Tab ausgewählt' 
          }
        },
        main: {
          section: [
            // Chatzeilen Section
            {
              attributes: { 'aria-labelledby': 'chat-heading' },
              div: [
                {
                  class: 'section-title',
                  h2: { id: 'chat-heading', text: 'Chatzeilen' },
                  div: {
                    class: 'title-actions',
                    span: [
                      { 
                        id: 'chat-led', 
                        class: 'status-led off', 
                        role: 'status', 
                        'aria-label': 'Chat inaktiv', 
                        title: 'Chat inaktiv' 
                      },
                      { 
                        id: 'speech-led', 
                        class: 'status-led off', 
                        role: 'status', 
                        'aria-label': 'Vorlesen inaktiv', 
                        title: 'Vorlesen inaktiv' 
                      }
                    ],
                    button: [
                      { 
                        id: 'chat-count', 
                        class: 'count count-button', 
                        type: 'button', 
                        'aria-haspopup': 'dialog', 
                        title: 'Gesammelte Chatzeilen öffnen', 
                        text: '0' 
                      },
                      { 
                        id: 'refresh-chat', 
                        class: 'secondary compact', 
                        title: 'Chatanzeige leeren', 
                        text: 'Refresh' 
                      },
                      { 
                        id: 'toggle-speech', 
                        class: 'secondary compact', 
                        'aria-pressed': 'false', 
                        text: 'Vorlesen' 
                      }
                    ]
                  }
                },
                { 
                  id: 'chat-list', 
                  class: 'chat-list empty', 
                  role: 'log', 
                  'aria-live': 'polite', 
                  'aria-relevant': 'additions', 
                  'aria-label': 'Die letzten fünf bereinigten Chatnachrichten', 
                  text: 'Noch keine Chatnachrichten erkannt.' 
                },
                { 
                  id: 'speech-status', 
                  role: 'status', 
                  class: 'inline-status', 
                  text: 'Vorlesen ist ausgeschaltet.' 
                }
              ],
              div_control_label_1: {
                class: 'control-label',
                label: { 
                  for: 'speech-volume', 
                  text: 'Vorleselautstärke' 
                },
                output: { 
                  id: 'speech-volume-output', 
                  for: 'speech-volume', 
                  text: '100%' 
                }
              },
              input: { 
                id: 'speech-volume', 
                type: 'range', 
                min: '0', 
                max: '100', 
                step: '5', 
                value: '50' 
              },
              div_button_row: {
                class: 'button-row',
                button: [
                  { 
                    id: 'service-action', 
                    class: 'secondary', 
                    text: 'Sprachdienst' 
                  },
                  { 
                    id: 'sherpa-action', 
                    class: 'secondary', 
                    text: 'Sherpa' 
                  },
                  { 
                    id: 'open-speech-settings', 
                    class: 'secondary compact settings-button', 
                    type: 'button', 
                    'aria-label': 'Sprach- und Chat-Einstellungen öffnen', 
                    'aria-haspopup': 'dialog', 
                    title: 'Einstellungen', 
                    text: '⚙' 
                  }
                ]
              },
              p_service_status: { 
                id: 'service-status', 
                class: 'inline-status', 
                text: 'Lokaler Sprachdienst noch nicht geprüft.' 
              },
              div_service_setup: { 
                id: 'service-setup', 
                class: 'inline-status', 
                hidden: true,
                button: { 
                  id: 'copy-service-setup', 
                  class: 'secondary compact', 
                  text: 'Installation abschließen!' 
                }
              },
              label_option_auto_chat: {
                class: 'option-row auto-chat-refresh',
                input: { 
                  id: 'auto-chat-refresh', 
                  type: 'checkbox' 
                },
                text: ' Auto-Chat Refresh ',
                input_minutes: { 
                  id: 'auto-chat-refresh-minutes', 
                  type: 'number', 
                  min: '1', 
                  max: '60', 
                  step: '1', 
                  value: '5', 
                  inputmode: 'numeric', 
                  'aria-label': 'Auto-Chat-Refresh in Minuten' 
                },
                span: { text: 'min.' }
              },
              label_option_keep_speech: {
                class: 'option-row',
                input: { 
                  id: 'keep-speech-active', 
                  type: 'checkbox' 
                },
                text: ' Permanent aktiv'
              }
            },

            // Top-Chatter Section
            {
              attributes: { 'aria-labelledby': 'top-chatters-heading' },
              div: {
                class: 'section-title',
                h2: { id: 'top-chatters-heading', text: 'Top-Chatter' },
                button: { 
                  id: 'open-audience', 
                  class: 'secondary compact', 
                  text: 'Zuschauer*innen' 
                }
              },
              p_team_tag: { 
                id: 'team-tag-status', 
                class: 'inline-status', 
                text: 'Teamkürzel: noch nicht erkannt.' 
              },
              div_top_chatters: { 
                id: 'top-chatters', 
                class: 'top-chatters empty', 
                text: 'Noch keine Personen im Chat beobachtet.' 
              },
              div_top_chatters_actions: { 
                id: 'top-chatters-actions', 
                class: 'top-chatters-actions', 
                hidden: true,
                button: [
                  { 
                    id: 'top-chatters-reset', 
                    class: 'top-chatter-link', 
                    type: 'button', 
                    hidden: true, 
                    text: 'Reset' 
                  },
                  { 
                    id: 'top-chatters-more', 
                    class: 'top-chatter-link', 
                    type: 'button', 
                    text: 'mehr…' 
                  }
                ]
              }
            },

            // Seiteninformationen Section
            {
              id: 'page-info-section',
              attributes: { 'aria-labelledby': 'page-info-heading' },
              div: {
                class: 'section-title',
                h2: { id: 'page-info-heading', text: 'Seiteninformationen' },
                div: {
                  class: 'title-actions',
                  span: { 
                    id: 'page-info-source', 
                    class: 'live-indicator', 
                    text: 'Metadaten' 
                  },
                  button: [
                    { 
                      id: 'refresh-page-info', 
                      class: 'secondary compact', 
                      text: 'Refresh' 
                    },
                    { 
                      id: 'force-page-info', 
                      class: 'secondary compact danger-outline', 
                      text: 'Force' 
                    }
                  ]
                }
              },
              div_profile_info: { 
                id: 'profile-info', 
                class: 'profile-info', 
                hidden: true 
              },
              div_summary_info: { 
                id: 'summary-info', 
                class: 'summary-info' 
              }
            },

            // LIVE-Informationen Section
            {
              attributes: { 'aria-labelledby': 'stats-heading' },
              div: {
                class: 'section-title',
                h2: { id: 'stats-heading', text: 'LIVE-Informationen' },
                span: { 
                  id: 'stats-live', 
                  class: 'live-indicator', 
                  text: 'warte' 
                }
              },
              div_live_stats: { 
                id: 'live-stats', 
                class: 'status-grid stats-grid' 
              },
              p_stats_status: { 
                id: 'stats-status', 
                class: 'inline-status' 
              }
            },

            // WebSocket-Hook Section
            {
              attributes: { 'aria-labelledby': 'hook-heading' },
              div_section_title: {
                class: 'section-title',
                h2: { id: 'hook-heading', text: 'WebSocket-Hook' },
                span: { 
                  id: 'hook-led', 
                  class: 'status-led off', 
                  role: 'status', 
                  'aria-label': 'Hook inaktiv', 
                  title: 'Hook inaktiv' 
                }
              },
              div_button_row: {
                class: 'button-row',
                button: [
                  { 
                    id: 'enable-hook', 
                    class: 'primary', 
                    text: 'Hook setzen' 
                  },
                  { 
                    id: 'disable-hook', 
                    class: 'secondary', 
                    text: 'Hook deaktivieren' 
                  },
                  { 
                    id: 'reset-tab', 
                    class: 'secondary danger-outline', 
                    text: 'Refresh' 
                  },
                  { 
                    id: 'open-embed-live', 
                    class: 'secondary', 
                    text: 'Embed' 
                  },
                  { 
                    id: 'open-normal-live', 
                    class: 'secondary', 
                    text: 'Normal' 
                  },
                  { 
                    id: 'player-vlc-frame', 
                    class: 'secondary compact', 
                    text: 'VLC Ersatz' 
                  }
                ]
              },
              p_hook_status: { 
                id: 'hook-status', 
                class: 'inline-status' 
              },
              label_hook_autostart: {
                class: 'option-row',
                input: { 
                  id: 'hook-autostart', 
                  type: 'checkbox' 
                },
                text: ' Permanent Hook'
              },
              label_quick_recover: {
                class: 'option-row quick-recover-setting',
                input: { 
                  id: 'quick-recover', 
                  type: 'checkbox' 
                },
                text: ' Auto-Reconnect ',
                input_seconds: { 
                  id: 'quick-recover-seconds', 
                  type: 'number', 
                  min: '1', 
                  max: '59', 
                  step: '1', 
                  value: '3', 
                  inputmode: 'numeric', 
                  'aria-label': 'Auto-Reconnect-Wartezeit in Sekunden' 
                },
                span: { text: 'Sek.' }
              }
            },

            // LIVE-Empfehlungen Section
            {
              id: 'recommendations-section',
              attributes: { 'aria-labelledby': 'recommendations-heading' },
              div_section_title: {
                class: 'section-title',
                h2: { id: 'recommendations-heading', text: 'LIVE-Empfehlungen' },
                span: { 
                  id: 'recommendation-status', 
                  class: 'live-indicator', 
                  text: 'bereit' 
                }
              },
              div_recommendation_controls: {
                class: 'recommendation-controls',
                label_count: {
                  span: { text: 'Anzahl' },
                  input: { 
                    id: 'recommendation-limit', 
                    type: 'number', 
                    min: '1', 
                    max: '50', 
                    step: '1', 
                    value: '20', 
                    inputmode: 'numeric' 
                  }
                },
                label_sort: {
                  span: { text: 'Sortierung' },
                  select: {
                    id: 'recommendation-sort',
                    option: [
                      { value: 'tiktok', text: 'TikTok-Reihenfolge' },
                      { value: 'viewers', text: 'Zuschauer*innen' }
                    ]
                  }
                }
              },
              div_button_row: {
                class: 'button-row',
                button: [
                  { 
                    id: 'scan-recommendations', 
                    class: 'primary', 
                    text: 'Empfehlungen scannen' 
                  },
                  { 
                    id: 'cancel-recommendations', 
                    class: 'secondary', 
                    hidden: true, 
                    text: 'Abbrechen' 
                  }
                ]
              },
              p_recommendation_progress: { 
                id: 'recommendation-progress', 
                class: 'inline-status', 
                'aria-live': 'polite', 
                text: 'Noch kein Scan gestartet.' 
              },
              div_recommendation_list: { 
                id: 'recommendation-list', 
                class: 'recommendation-list empty', 
                text: 'Noch keine Empfehlungen erfasst.' 
              },
              div_recommendation_actions: { 
                id: 'recommendation-actions', 
                class: 'top-chatters-actions', 
                hidden: true,
                button: { 
                  id: 'recommendation-more', 
                  class: 'top-chatter-link', 
                  type: 'button', 
                  text: 'mehr…' 
                }
              }
            },

            // Untertitel Section
            {
              attributes: { 'aria-labelledby': 'caption-heading' },
              div_section_title: {
                class: 'section-title',
                h2: { id: 'caption-heading', text: 'Untertitel' },
                button: { 
                  id: 'scan', 
                  class: 'secondary', 
                  text: 'Seite prüfen' 
                }
              },
              div_caption_status: { 
                id: 'caption-status', 
                class: 'status-grid' 
              },
              button_enable_captions: { 
                id: 'enable-captions', 
                class: 'primary', 
                text: 'Untertitel aktivieren' 
              },
              p_caption_action_status: { 
                id: 'caption-action-status', 
                role: 'status', 
                class: 'inline-status action-status' 
              }
            },

            // Playersteuerung Section
            {
              attributes: { 'aria-labelledby': 'player-heading' },
              div_section_title: {
                class: 'section-title',
                h2: { id: 'player-heading', text: 'Playersteuerung' },
                span: { 
                  id: 'player-time', 
                  class: 'player-time', 
                  text: '–' 
                }
              },
              div_player_controls: {
                class: 'player-controls',
                role: 'group',
                'aria-label': 'TikTok-Player steuern',
                button: [
                  { 
                    id: 'player-play', 
                    class: 'secondary compact', 
                    text: 'Pause' 
                  },
                  { 
                    id: 'player-replay', 
                    class: 'secondary compact', 
                    text: 'Neu laden' 
                  },
                  { 
                    id: 'player-mute', 
                    class: 'secondary compact', 
                    text: 'Stumm' 
                  },
                  { 
                    id: 'player-pip', 
                    class: 'secondary compact', 
                    text: 'Bild-in-Bild' 
                  },
                  { 
                    id: 'player-fullscreen', 
                    class: 'secondary compact', 
                    text: 'Vollbild' 
                  },
                  { 
                    id: 'player-report', 
                    class: 'secondary compact danger-outline', 
                    text: 'Melden öffnen' 
                  }
                ]
              },
              div_audio_controls: {
                class: 'audio-controls',
                div_control_label_volume: {
                  class: 'control-label',
                  label: { 
                    for: 'player-volume', 
                    text: 'Lautstärke' 
                  },
                  output: { 
                    id: 'player-volume-output', 
                    for: 'player-volume', 
                    text: '–' 
                  }
                },
                input_player_volume: { 
                  id: 'player-volume', 
                  type: 'range', 
                  min: '0', 
                  max: '100', 
                  step: '1', 
                  value: '100' 
                },
                div_audio_meter_row: {
                  class: 'audio-meter-row',
                  span: { text: 'Spitzenpegel' },
                  strong: { 
                    id: 'player-peak', 
                    text: '–' 
                  }
                },
                label_limiter_enabled: {
                  class: 'option-row',
                  input: { 
                    id: 'limiter-enabled', 
                    type: 'checkbox' 
                  },
                  text: ' Pegelschutz aktivieren'
                },
                div_control_label_limiter: {
                  class: 'control-label',
                  label: { 
                    for: 'limiter-strength', 
                    text: 'Schutzstärke' 
                  },
                  output: { 
                    id: 'limiter-strength-output', 
                    for: 'limiter-strength', 
                    text: '30' 
                  }
                },
                input_limiter_strength: { 
                  id: 'limiter-strength', 
                  type: 'range', 
                  min: '0', 
                  max: '100', 
                  step: '1', 
                  value: '30' 
                }
              },
              p_multi_guest_status: { 
                id: 'multi-guest-status', 
                class: 'inline-status', 
                text: 'Verbundene Streams: noch nicht erkannt.' 
              },
              p_player_status: { 
                id: 'player-status', 
                role: 'status', 
                class: 'inline-status', 
                text: 'Warte auf den TikTok-Player.' 
              }
            },

            // Songerkennung Section
            {
              attributes: { 'aria-labelledby': 'song-heading' },
              div_section_title: {
                class: 'section-title',
                h2: { id: 'song-heading', text: 'Songerkennung' },
                span: { 
                  id: 'song-led', 
                  class: 'status-led off', 
                  role: 'status', 
                  'aria-label': 'Songerkennung inaktiv' 
                }
              },
              label_song_enabled: {
                class: 'option-row',
                input: { 
                  id: 'song-enabled', 
                  type: 'checkbox' 
                },
                text: ' Songerkennung aktivieren'
              },
              button_recognize_song: { 
                id: 'recognize-song', 
                class: 'primary', 
                disabled: true, 
                text: 'Jetzt erkennen' 
              },
              p_song_status: { 
                id: 'song-status', 
                class: 'inline-status' 
              },
              div_song_result: { 
                id: 'song-result', 
                class: 'song-result', 
                hidden: true 
              }
            },

            // VLC-Links Section
            {
              attributes: { 'aria-labelledby': 'links-heading' },
              div_section_title: {
                class: 'section-title',
                h2: { id: 'links-heading', text: 'VLC-Links' },
                span: { 
                  id: 'media-count', 
                  class: 'count', 
                  text: '0' 
                }
              },
              div_media_list: { 
                id: 'media-list', 
                class: 'list empty', 
                text: 'Noch keine FLV-/HLS-Links erkannt.' 
              }
            },

            // Caption-Protokoll Section
            {
              attributes: { 'aria-labelledby': 'log-heading' },
              div_section_title: {
                class: 'section-title',
                h2: { id: 'log-heading', text: 'Caption-Protokoll' },
                span: { 
                  id: 'caption-count', 
                  class: 'count', 
                  text: '0' 
                }
              },
              div_button_row: {
                class: 'button-row',
                button: [
                  { 
                    id: 'export-log', 
                    class: 'secondary', 
                    text: 'JSON-L-Export' 
                  },
                  { 
                    id: 'export-caption-raw', 
                    class: 'secondary', 
                    text: 'RAW-JSON-Export' 
                  },
                  { 
                    id: 'clear', 
                    class: 'ghost', 
                    text: 'Anzeige leeren' 
                  }
                ]
              },
              div_caption_list: { 
                id: 'caption-list', 
                class: 'list empty', 
                text: 'Noch keine CaptionMessages empfangen.' 
              }
            },

            // Debugmodus Section
            {
              attributes: { 'aria-labelledby': 'debug-heading' },
              div_section_title: {
                class: 'section-title',
                h2: { id: 'debug-heading', text: 'Debugmodus' },
                span: { 
                  id: 'debug-count', 
                  class: 'count', 
                  text: '0' 
                }
              },
              label_debug_enabled: {
                class: 'option-row',
                input: { 
                  id: 'debug-enabled', 
                  type: 'checkbox' 
                },
                text: ' Diagnoseereignisse für diesen Tab protokollieren'
              },
              div_button_row: {
                class: 'button-row',
                button: [
                  { 
                    id: 'export-debug', 
                    class: 'secondary', 
                    text: 'Debug exportieren' 
                  },
                  { 
                    id: 'clear-debug', 
                    class: 'ghost', 
                    text: 'Debug leeren' 
                  }
                ]
              },
              p_muted_small: { 
                class: 'muted small' 
              }
            },

            // Audience Modal
            {
              id: 'audience-modal',
              class: 'modal-backdrop',
              hidden: true,
              section: {
                class: 'modal',
                role: 'dialog',
                'aria-modal': 'true',
                'aria-labelledby': 'audience-heading',
                div: {
                  class: 'section-title',
                  h2: { id: 'audience-heading', text: 'Im Chat beobachtete Personen' },
                  button: { 
                    id: 'close-audience', 
                    class: 'secondary compact', 
                    'aria-label': 'Übersicht schließen', 
                    text: 'Schließen' 
                  }
                },
                p: { 
                  id: 'audience-limit', 
                  class: 'inline-status' 
                },
                div: { 
                  id: 'audience-list', 
                  class: 'audience-list' 
                }
              }
            },

            // Speech Settings Modal
            {
              id: 'speech-settings-modal',
              class: 'modal-backdrop',
              hidden: true,
              section: {
                class: 'modal',
                role: 'dialog',
                'aria-modal': 'true',
                'aria-labelledby': 'speech-settings-heading',
                div: {
                  class: 'section-title',
                  h2: { id: 'speech-settings-heading', text: 'Sprach- und Chat-Einstellungen' },
                  button: { 
                    id: 'close-speech-settings', 
                    class: 'secondary compact', 
                    'aria-label': 'Einstellungen schließen', 
                    text: 'Schließen' 
                  }
                },
                div_settings_grid: {
                  class: 'settings-grid speech-integration-settings',
                  label_language: {
                    span: { text: 'Sprache' },
                    select: {
                      id: 'speech-language',
                      option: [
                        { value: 'auto', text: 'Auto' },
                        { value: 'de-DE', text: 'Deutsch' },
                        { value: 'en-US', text: 'Englisch' },
                        { value: 'ru-RU', text: 'Russisch' },
                        { value: 'uk-UA', text: 'Ukrainisch' },
                        { value: 'bg-BG', text: 'Bulgarisch' },
                        { value: 'sr-RS', text: 'Serbisch' },
                        { value: 'kk-KZ', text: 'Kasachisch' },
                        { value: 'zh-CN', text: 'Chinesisch' },
                        { value: 'ja-JP', text: 'Japanisch' },
                        { value: 'ko-KR', text: 'Koreanisch' },
                        { value: 'ar-JO', text: 'Arabisch' },
                        { value: 'fa-IR', text: 'Persisch' },
                        { value: 'ur-PK', text: 'Urdu' },
                        { value: 'hi-IN', text: 'Hindi' },
                        { value: 'ne-NP', text: 'Nepali' },
                        { value: 'ml-IN', text: 'Malayalam' }
                      ]
                    }
                  },
                  label_voice: {
                    span: { text: 'Stimme' },
                    select: {
                      id: 'speech-voice',
                      option: { 
                        value: '', 
                        text: 'Standard' 
                      }
                    }
                  },
                  label_audd_token: {
                    id: 'audd-token-setting',
                    span: { 
                      id: 'audd-token-label', 
                      text: 'AudD API-Token (optional - https://AudD.io Trial/Paid)' 
                    },
                    input: { 
                      id: 'audd-token', 
                      type: 'password', 
                      autocomplete: 'off', 
                      spellcheck: 'false' 
                    }
                  },
                  label_pairing_code: {
                    span: { text: 'Pairing-Code' },
                    input: { 
                      id: 'pairing-code', 
                      type: 'password', 
                      autocomplete: 'off', 
                      spellcheck: 'false' 
                    }
                  },
                  label_universal_caption_api_key: {
                    span: { text: 'Universal API-Key für Untertitel' },
                    input: { 
                      id: 'universal-caption-api-key', 
                      type: 'password', 
                      autocomplete: 'off', 
                      spellcheck: 'false' 
                    }
                  }
                },
                label_speak_names: {
                  class: 'option-row',
                  input: { 
                    id: 'speak-names', 
                    type: 'checkbox', 
                    checked: true 
                  },
                  text: ' Chatnamen sprechen'
                },
                label_shorten_names: {
                  class: 'option-row',
                  input: { 
                    id: 'shorten-names', 
                    type: 'checkbox' 
                  },
                  text: ' Chatnamen kürzen'
                },
                label_game_mode: {
                  class: 'option-row',
                  input: { 
                    id: 'game-mode', 
                    type: 'checkbox' 
                  },
                  text: ' Game-Mode'
                }
              }
            },

            // Chat History Modal
            {
              id: 'chat-history-modal',
              class: 'modal-backdrop',
              hidden: true,
              section: {
                class: 'modal',
                role: 'dialog',
                'aria-modal': 'true',
                'aria-labelledby': 'chat-history-heading',
                div: {
                  class: 'section-title',
                  h2: { id: 'chat-history-heading', text: 'Gesammelte Chatzeilen' },
                  button: { 
                    id: 'close-chat-history', 
                    class: 'secondary compact', 
                    'aria-label': 'Chatzeilen schließen', 
                    text: 'Schließen' 
                  }
                },
                p: { 
                  id: 'chat-history-limit', 
                  class: 'inline-status' 
                },
                div: { 
                  id: 'chat-history-list', 
                  class: 'chat-history-list' 
                }
              }
            },

            // Recommendation Modal
            {
              id: 'recommendation-modal',
              class: 'modal-backdrop',
              hidden: true,
              section: {
                class: 'modal',
                role: 'dialog',
                'aria-modal': 'true',
                'aria-labelledby': 'recommendation-modal-heading',
                div: {
                  class: 'section-title',
                  h2: { id: 'recommendation-modal-heading', text: 'Gescannte LIVE-Empfehlungen' },
                  button: { 
                    id: 'close-recommendations', 
                    class: 'secondary compact', 
                    'aria-label': 'Empfehlungen schließen', 
                    text: 'Schließen' 
                  }
                },
                div: { 
                  id: 'recommendation-modal-list', 
                  class: 'recommendation-list' 
                }
              }
            },

            // Notice
            { 
              id: 'notice', 
              role: 'alert', 
              class: 'notice' 
            }
          ],
          
          script: [
            { src: 'content-core.js' },
            { src: 'sidepanel.js' }
          ]
        }
      }
    }
  };

  return doc;
}

function renderElement(tag, element) {
  if (element === null || element === undefined) return '';
  
  if (typeof element === 'string') {
    return element;
  }

  if (Array.isArray(element)) {
    return element.map(item => renderElement(tag, item)).join('');
  }

  let attrs = '';
  let content = '';
  let text = '';

  for (const [key, value] of Object.entries(element)) {
    if (key === 'text') {
      text = value;
    } else if (key === 'attributes') {
      for (const [attrKey, attrValue] of Object.entries(value)) {
        attrs += ` ${attrKey}="${attrValue}"`;
      }
    } else if (key !== 'text') {
      if (typeof value === 'object') {
        content += renderElement(key, value);
      } else {
        attrs += ` ${key}="${value}"`;
      }
    }
  }

  if (content || text) {
    return `<${tag}${attrs}>${text}${content}</${tag}>`;
  } else {
    return `<${tag}${attrs}>`;
  }
}

function renderDocument(doc) {
  let html = `${doc.doctype}\n`;
  html += `<html lang="${doc.html.attributes.lang}">\n`;
  html += `<head>\n`;
  
  for (const meta of doc.html.head.meta) {
    if (meta.charset) {
      html += `  <meta charset="${meta.charset}">\n`;
    } else {
      html += `  <meta name="${meta.name}" content="${meta.content}">\n`;
    }
  }
  
  html += `  <title>${doc.html.head.title}</title>\n`;
  html += `  <link rel="${doc.html.head.link.rel}" href="${doc.html.head.link.href}">\n`;
  html += `</head>\n`;
  html += `<body>\n`;
  
  // Render header
  html += `  <header>\n`;
  html += `    <p id="${doc.html.body.header.p.id}" class="${doc.html.body.header.p.class}">${doc.html.body.header.p.text}</p>\n`;
  html += `  </header>\n\n`;
  
  // Render main sections
  html += `  <main>\n`;
  
  for (const section of doc.html.body.main.section) {
    if (section.id === 'audience-modal' || 
        section.id === 'speech-settings-modal' || 
        section.id === 'chat-history-modal' || 
        section.id === 'recommendation-modal') {
      // Modal sections have special structure
      html += `    <div id="${section.id}" class="${section.class}"${section.hidden ? ' hidden' : ''}>\n`;
      html += `      <section class="${section.section.class}" role="${section.section.role}" aria-modal="${section.section['aria-modal']}" aria-labelledby="${section.section['aria-labelledby']}">\n`;
      html += `        <div class="${section.section.div.class}">\n`;
      
      if (section.id === 'audience-modal') {
        html += `          <h2 id="${section.section.div.h2.id}">${section.section.div.h2.text}</h2>\n`;
        html += `          <button id="${section.section.div.button.id}" class="${section.section.div.button.class}" aria-label="${section.section.div.button['aria-label']}">${section.section.div.button.text}</button>\n`;
        html += `        </div>\n`;
        html += `        <p id="${section.section.p.id}" class="${section.section.p.class}"></p>\n`;
        html += `        <div id="${section.section.div.div.id}" class="${section.section.div.div.class}"></div>\n`;
      } else if (section.id === 'speech-settings-modal') {
        html += `          <h2 id="${section.section.div.h2.id}">${section.section.div.h2.text}</h2>\n`;
        html += `          <button id="${section.section.div.button.id}" class="${section.section.div.button.class}" aria-label="${section.section.div.button['aria-label']}">${section.section.div.button.text}</button>\n`;
        html += `        </div>\n`;
        html += `        <div class="${section.section.div_settings_grid.class}">\n`;
        
        // Language select
        html += `          <label><span>${section.section.div_settings_grid.label_language.span.text}</span>`;
        html += `<select id="${section.section.div_settings_grid.label_language.select.id}">`;
        for (const option of section.section.div_settings_grid.label_language.select.option) {
          html += `<option value="${option.value}">${option.text}</option>`;
        }
        html += `</select></label>\n`;
        
        // Voice select
        html += `          <label><span>${section.section.div_settings_grid.label_voice.span.text}</span>`;
        html += `<select id="${section.section.div_settings_grid.label_voice.select.id}">`;
        for (const option of section.section.div_settings_grid.label_voice.select.option) {
          html += `<option value="${option.value}">${option.text}</option>`;
        }
        html += `</select></label>\n`;
        
        // AudD token
        html += `          <label id="${section.section.div_settings_grid.label_audd_token.id}">`;
        html += `<span id="${section.section.div_settings_grid.label_audd_token.span.id}">${section.section.div_settings_grid.label_audd_token.span.text}</span>`;
        html += `<input id="${section.section.div_settings_grid.label_audd_token.input.id}" type="${section.section.div_settings_grid.label_audd_token.input.type}" autocomplete="${section.section.div_settings_grid.label_audd_token.input.autocomplete}" spellcheck="${section.section.div_settings_grid.label_audd_token.input.spellcheck}">`;
        html += `</label>\n`;
        
        // Pairing code
        html += `          <label><span>${section.section.div_settings_grid.label_pairing_code.span.text}</span>`;
        html += `<input id="${section.section.div_settings_grid.label_pairing_code.input.id}" type="${section.section.div_settings_grid.label_pairing_code.input.type}" autocomplete="${section.section.div_settings_grid.label_pairing_code.input.autocomplete}" spellcheck="${section.section.div_settings_grid.label_pairing_code.input.spellcheck}">`;
        html += `</label>\n`;
        
        // Universal API key
        html += `          <label><span>${section.section.div_settings_grid.label_universal_caption_api_key.span.text}</span>`;
        html += `<input id="${section.section.div_settings_grid.label_universal_caption_api_key.input.id}" type="${section.section.div_settings_grid.label_universal_caption_api_key.input.type}" autocomplete="${section.section.div_settings_grid.label_universal_caption_api_key.input.autocomplete}" spellcheck="${section.section.div_settings_grid.label_universal_caption_api_key.input.spellcheck}">`;
        html += `</label>\n`;
        
        html += `        </div>\n`;
        
        // Checkboxes
        html += `        <label class="${section.section.label_speak_names.class}">`;
        html += `<input id="${section.section.label_speak_names.input.id}" type="${section.section.label_speak_names.input.type}"${section.section.label_speak_names.input.checked ? ' checked' : ''}>`;
        html += `${section.section.label_speak_names.text}</label>\n`;
        
        html += `        <label class="${section.section.label_short
