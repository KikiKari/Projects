#!/usr/bin/env node
// sidepanel.css — portiert nach javascript
// Quelle: css, Projects@TikTok-Live-Companion:plugin-source/browser-extension/sidepanel.css
// auch in: Projects@TikTok-Live-Companion:release/0.7.1/tiktok-live-companion-extension-0.7.1/sidepanel.css
// auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/sidepanel.css
// auch in: Projects@TikTok-Live-Companion-Android:release/0.7.1/tiktok-live-companion-extension-0.7.1/sidepanel.css
// auch in: 2 weiteren Fundstellen
// Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

const fs = require('fs');
const path = require('path');

function generateCSS() {
  const cssRules = [
    {
      selector: ':root',
      declarations: [
        'color-scheme: light dark',
        'font-family: Inter, "Segoe UI", system-ui, sans-serif',
        '--accent: #fe2c55',
        '--accent-dark: #d91f46',
        '--surface: color-mix(in srgb, Canvas 94%, CanvasText 6%)',
        '--border: color-mix(in srgb, CanvasText 18%, transparent)',
        '--muted: color-mix(in srgb, CanvasText 65%, transparent)',
        '--good: #147d45',
        '--warn: #a65f00',
        '--bad: #b42318'
      ]
    },
    {
      selector: '*',
      declarations: ['box-sizing: border-box']
    },
    {
      selector: 'body',
      declarations: [
        'margin: 0',
        'background: Canvas',
        'color: CanvasText',
        'min-width: 300px'
      ]
    },
    {
      selector: 'header',
      declarations: [
        'padding: 11px 18px',
        'background: linear-gradient(135deg, color-mix(in srgb, var(--accent) 18%, Canvas), Canvas)',
        'border-bottom: 1px solid var(--border)'
      ]
    },
    {
      selector: 'h2',
      declarations: [
        'margin: 0',
        'font-size: 15px'
      ]
    },
    {
      selector: 'main',
      declarations: [
        'padding: 14px',
        'display: grid',
        'grid-template-columns: minmax(0, 1fr)',
        'gap: 12px'
      ]
    },
    {
      selector: 'section',
      declarations: [
        'min-width: 0',
        'padding: 14px',
        'background: var(--surface)',
        'border: 1px solid var(--border)',
        'border-radius: 13px',
        'box-shadow: 0 5px 20px color-mix(in srgb, CanvasText 6%, transparent)'
      ]
    },
    {
      selector: '.section-title, .button-row',
      declarations: [
        'display: flex',
        'align-items: center',
        'justify-content: space-between',
        'gap: 8px'
      ]
    },
    {
      selector: '.section-title',
      declarations: [
        'min-width: 0',
        'flex-wrap: wrap'
      ]
    },
    {
      selector: '.title-actions',
      declarations: [
        'display: flex',
        'min-width: 0',
        'max-width: 100%',
        'align-items: center',
        'justify-content: flex-end',
        'flex-wrap: wrap',
        'gap: 6px'
      ]
    },
    {
      selector: '.status-led',
      declarations: [
        'width: 11px',
        'height: 11px',
        'flex: 0 0 11px',
        'border-radius: 50%',
        'background: var(--bad)',
        'box-shadow: 0 0 0 3px color-mix(in srgb, var(--bad) 15%, transparent)'
      ]
    },
    {
      selector: '.status-led.on',
      declarations: [
        'background: var(--good)',
        'box-shadow: 0 0 0 3px color-mix(in srgb, var(--good) 17%, transparent)'
      ]
    },
    {
      selector: '.status-led.off',
      declarations: [
        'background: var(--bad)'
      ]
    },
    {
      selector: '.button-row',
      declarations: [
        'justify-content: flex-start',
        'flex-wrap: wrap',
        'margin-top: 10px'
      ]
    },
    {
      selector: 'button',
      declarations: [
        'border: 0',
        'border-radius: 9px',
        'padding: 9px 11px',
        'font: inherit',
        'font-size: 12px',
        'font-weight: 700',
        'cursor: pointer'
      ]
    },
    {
      selector: 'button:disabled',
      declarations: [
        'cursor: not-allowed',
        'opacity: .55'
      ]
    },
    {
      selector: '.compact',
      declarations: [
        'padding: 7px 9px'
      ]
    },
    {
      selector: '.primary',
      declarations: [
        'color: white',
        'background: var(--accent)'
      ]
    },
    {
      selector: '.primary:hover',
      declarations: [
        'background: var(--accent-dark)'
      ]
    },
    {
      selector: '.secondary',
      declarations: [
        'color: CanvasText',
        'background: color-mix(in srgb, CanvasText 9%, Canvas)',
        'border: 1px solid var(--border)'
      ]
    },
    {
      selector: '.ghost',
      declarations: [
        'color: var(--muted)',
        'background: transparent'
      ]
    },
    {
      selector: '.danger-outline',
      declarations: [
        'color: var(--bad)',
        'border-color: color-mix(in srgb, var(--bad) 45%, transparent)'
      ]
    },
    {
      selector: '#enable-captions',
      declarations: [
        'width: 100%',
        'margin-top: 11px'
      ]
    },
    {
      selector: '.muted',
      declarations: [
        'color: var(--muted)'
      ]
    },
    {
      selector: '.small',
      declarations: [
        'font-size: 12px',
        'line-height: 1.45'
      ]
    },
    {
      selector: '#page-title',
      declarations: [
        'margin: 0',
        'font-size: 12px',
        'white-space: nowrap',
        'overflow: hidden',
        'text-overflow: ellipsis'
      ]
    },
    {
      selector: '.status-grid',
      declarations: [
        'display: grid',
        'grid-template-columns: 1fr 1fr',
        'gap: 7px',
        'margin-top: 11px'
      ]
    },
    {
      selector: '.status',
      declarations: [
        'padding: 9px',
        'border: 1px solid var(--border)',
        'border-radius: 9px',
        'background: Canvas'
      ]
    },
    {
      selector: '.status-label',
      declarations: [
        'display: block',
        'color: var(--muted)',
        'font-size: 10px',
        'text-transform: uppercase',
        'letter-spacing: .06em'
      ]
    },
    {
      selector: '.status-value',
      declarations: [
        'display: block',
        'margin-top: 3px',
        'font-size: 12px',
        'font-weight: 750'
      ]
    },
    {
      selector: '.good .status-value',
      declarations: [
        'color: var(--good)'
      ]
    },
    {
      selector: '.warn .status-value',
      declarations: [
        'color: var(--warn)'
      ]
    },
    {
      selector: '.bad .status-value',
      declarations: [
        'color: var(--bad)'
      ]
    },
    {
      selector: '.count',
      declarations: [
        'min-width: 25px',
        'padding: 3px 7px',
        'border-radius: 999px',
        'background: color-mix(in srgb, var(--accent) 15%, Canvas)',
        'color: var(--accent)',
        'text-align: center',
        'font-size: 11px',
        'font-weight: 800'
      ]
    },
    {
      selector: '.count-button',
      declarations: [
        'border: 1px solid color-mix(in srgb, var(--accent) 30%, transparent)',
        'cursor: pointer'
      ]
    },
    {
      selector: '.count-button:hover, .count-button:focus-visible',
      declarations: [
        'background: color-mix(in srgb, var(--accent) 25%, Canvas)'
      ]
    },
    {
      selector: '.live-indicator',
      declarations: [
        'padding: 3px 7px',
        'border-radius: 999px',
        'background: color-mix(in srgb, var(--muted) 15%, Canvas)',
        'color: var(--muted)',
        'font-size: 10px',
        'font-weight: 800',
        'text-transform: uppercase'
      ]
    },
    {
      selector: '.live-indicator.active',
      declarations: [
        'background: color-mix(in srgb, var(--good) 16%, Canvas)',
        'color: var(--good)'
      ]
    },
    {
      selector: '.stats-grid .status-value',
      declarations: [
        'font-size: 16px',
        'font-variant-numeric: tabular-nums'
      ]
    },
    {
      selector: '.chat-list',
      declarations: [
        'display: grid',
        'gap: 6px',
        'margin-top: 11px'
      ]
    },
    {
      selector: '.chat-list.empty',
      declarations: [
        'color: var(--muted)',
        'font-size: 12px'
      ]
    },
    {
      selector: '.chat-line',
      declarations: [
        'margin: 0',
        'padding: 7px 8px',
        'border-left: 3px solid color-mix(in srgb, var(--accent) 45%, var(--border))',
        'border-radius: 6px',
        'background: Canvas',
        'font-size: 12px',
        'line-height: 1.4',
        'overflow-wrap: anywhere'
      ]
    },
    {
      selector: '.chat-author',
      declarations: [
        'font-weight: 800'
      ]
    },
    {
      selector: '.player-controls',
      declarations: [
        'display: grid',
        'grid-template-columns: repeat(2, minmax(0, 1fr))',
        'gap: 7px',
        'margin-top: 11px'
      ]
    },
    {
      selector: '.player-controls button',
      declarations: [
        'width: 100%'
      ]
    },
    {
      selector: '.player-time',
      declarations: [
        'font-size: 13px',
        'font-weight: 800',
        'font-variant-numeric: tabular-nums'
      ]
    },
    {
      selector: '.audio-controls',
      declarations: [
        'display: grid',
        'gap: 7px',
        'margin-top: 12px',
        'padding-top: 11px',
        'border-top: 1px solid var(--border)'
      ]
    },
    {
      selector: '.control-label, .audio-meter-row',
      declarations: [
        'display: flex',
        'align-items: center',
        'justify-content: space-between',
        'gap: 8px',
        'font-size: 11px'
      ]
    },
    {
      selector: '.control-label output, .audio-meter-row strong',
      declarations: [
        'font-variant-numeric: tabular-nums'
      ]
    },
    {
      selector: 'input[type="range"]',
      declarations: [
        'width: 100%',
        'accent-color: var(--accent)'
      ]
    },
    {
      selector: '.settings-grid',
      declarations: [
        'display: grid',
        'gap: 7px',
        'margin-top: 10px'
      ]
    },
    {
      selector: '.settings-grid label',
      declarations: [
        'display: grid',
        'gap: 4px',
        'color: var(--muted)',
        'font-size: 10px'
      ]
    },
    {
      selector: '.settings-grid label[hidden]',
      declarations: [
        'display: none'
      ]
    },
    {
      selector: 'input[type="url"], input[type="password"], select',
      declarations: [
        'width: 100%',
        'min-width: 0',
        'padding: 7px 8px',
        'border: 1px solid var(--border)',
        'border-radius: 7px',
        'background: Canvas',
        'color: CanvasText',
        'font: inherit',
        'font-size: 11px'
      ]
    },
    {
      selector: '.top-chatters',
      declarations: [
        'display: grid',
        'gap: 6px',
        'margin-top: 8px'
      ]
    },
    {
      selector: '.top-chatters.empty',
      declarations: [
        'color: var(--muted)',
        'font-size: 12px'
      ]
    },
    {
      selector: '.top-chatters-actions',
      declarations: [
        'display: flex',
        'justify-content: flex-end',
        'gap: 9px',
        'margin-top: 7px'
      ]
    },
    {
      selector: '.top-chatters-actions[hidden]',
      declarations: [
        'display: none'
      ]
    },
    {
      selector: '.top-chatter-link',
      declarations: [
        'padding: 0',
        'color: var(--accent)',
        'background: transparent',
        'border: 0',
        'border-radius: 0',
        'font-weight: 700'
      ]
    },
    {
      selector: '.top-chatter-link:hover',
      declarations: [
        'text-decoration: underline'
      ]
    },
    {
      selector: '.chatter-row',
      declarations: [
        'display: grid',
        'grid-template-columns: minmax(0, 1fr) auto auto',
        'align-items: center',
        'gap: 7px',
        'padding: 7px 8px',
        'border: 1px solid var(--border)',
        'border-radius: 8px',
        'background: Canvas'
      ]
    },
    {
      selector: '.chatter-name',
      declarations: [
        'min-width: 0',
        'overflow: hidden',
        'text-overflow: ellipsis',
        'white-space: nowrap',
        'font-size: 11px',
        'font-weight: 800'
      ]
    },
    {
      selector: '.chatter-metrics',
      declarations: [
        'color: var(--muted)',
        'font-size: 10px',
        'white-space: nowrap'
      ]
    },
    {
      selector: '.mute-toggle',
      declarations: [
        'display: flex',
        'align-items: center',
        'gap: 4px',
        'color: var(--muted)',
        'font-size: 10px'
      ]
    },
    {
      selector: '#recognize-song',
      declarations: [
        'width: 100%',
        'margin-top: 10px'
      ]
    },
    {
      selector: '.song-result',
      declarations: [
        'margin-top: 9px',
        'padding: 9px',
        'border: 1px solid var(--border)',
        'border-radius: 9px',
        'background: Canvas',
        'font-size: 11px',
        'line-height: 1.45'
      ]
    },
    {
      selector: '.song-result strong, .song-result span, .song-result a',
      declarations: [
        'display: block'
      ]
    },
    {
      selector: '.song-result a',
      declarations: [
        'margin-top: 4px',
        'color: var(--accent)',
        'overflow-wrap: anywhere'
      ]
    },
    {
      selector: '.modal-backdrop',
      declarations: [
        'position: fixed',
        'inset: 0',
        'z-index: 100',
        'padding: 14px',
        'background: color-mix(in srgb, CanvasText 42%, transparent)',
        'overflow: auto'
      ]
    },
    {
      selector: '.modal',
      declarations: [
        'width: min(520px, 100%)',
        'max-height: calc(100vh - 28px)',
        'margin: 0 auto',
        'overflow: auto',
        'background: Canvas'
      ]
    },
    {
      selector: '.audience-list, .chat-history-list',
      declarations: [
        'display: grid',
        'gap: 7px',
        'margin-top: 9px'
      ]
    },
    {
      selector: '.chat-history-row',
      declarations: [
        'padding: 8px 9px',
        'border: 1px solid var(--border)',
        'border-radius: 9px',
        'background: var(--surface)',
        'font-size: 11px',
        'line-height: 1.4',
        'overflow-wrap: anywhere'
      ]
    },
    {
      selector: '.chat-history-meta',
      declarations: [
        'display: block',
        'margin-bottom: 3px',
        'color: var(--muted)',
        'font-size: 10px'
      ]
    },
    {
      selector: '.audience-row',
      declarations: [
        'display: grid',
        'gap: 6px',
        'padding: 9px',
        'border: 1px solid var(--border)',
        'border-radius: 9px',
        'background: var(--surface)'
      ]
    },
    {
      selector: '.audience-row-head',
      declarations: [
        'display: flex',
        'align-items: center',
        'justify-content: space-between',
        'gap: 8px'
      ]
    },
    {
      selector: '.audience-row select',
      declarations: [
        'width: auto',
        'max-width: 170px'
      ]
    },
    {
      selector: '.audience-metrics',
      declarations: [
        'color: var(--muted)',
        'font-size: 10px',
        'line-height: 1.45'
      ]
    },
    {
      selector: '.option-row',
      declarations: [
        'display: flex',
        'align-items: flex-start',
        'gap: 7px',
        'margin-top: 8px',
        'color: var(--muted)',
        'font-size: 11px',
        'line-height: 1.35'
      ]
    },
    {
      selector: '.option-row input',
      declarations: [
        'margin: 1px 0 0',
        'accent-color: var(--accent)'
      ]
    },
    {
      selector: '.auto-chat-refresh',
      declarations: [
        'align-items: center'
      ]
    },
    {
      selector: '.auto-chat-refresh input[type="number"]',
      declarations: [
        'width: 48px',
        'margin-left: 3px',
        'padding: 3px 4px',
        'border: 1px solid var(--border)',
        'border-radius: 6px',
        'background: Canvas',
        'color: CanvasText',
        'font: inherit',
        'font-size: 11px'
      ]
    },
    {
      selector: '.audio-note',
      declarations: [
        'margin: 1px 0 0'
      ]
    },
    {
      selector: '.profile-info',
      declarations: [
        'display: grid',
        'gap: 8px',
        'margin-top: 11px'
      ]
    },
    {
      selector: '.profile-heading',
      declarations: [
        'margin: 0',
        'font-size: 14px',
        'font-weight: 800'
      ]
    },
    {
      selector: '.profile-handle, .profile-bio',
      declarations: [
        'margin: 0',
        'color: var(--muted)',
        'font-size: 11px',
        'line-height: 1.45',
        'white-space: pre-wrap'
      ]
    },
    {
      selector: '.profile-stats',
      declarations: [
        'display: grid',
        'grid-template-columns: repeat(3, minmax(0, 1fr))',
        'gap: 6px'
      ]
    },
    {
      selector: '.profile-stat',
      declarations: [
        'padding: 7px',
        'border: 1px solid var(--border)',
        'border-radius: 8px',
        'background: Canvas'
      ]
    },
    {
      selector: '.profile-stat strong, .profile-stat span',
      declarations: [
        'display: block'
      ]
    },
    {
      selector: '.profile-stat span',
      declarations: [
        'margin-top: 2px',
        'color: var(--muted)',
        'font-size: 9px',
        'text-transform: uppercase'
      ]
    },
    {
      selector: '.summary-info',
      declarations: [
        'margin-top: 10px',
        'padding-top: 9px',
        'border-top: 1px solid var(--border)',
        'font-size: 11px',
        'line-height: 1.45'
      ]
    },
    {
      selector: '.summary-text',
      declarations: [
        'margin: 6px 0 0',
        'white-space: pre-wrap'
      ]
    },
    {
      selector: '.list',
      declarations: [
        'display: grid',
        'gap: 8px',
        'margin-top: 11px',
        'max-height: 300px',
        'overflow: auto'
      ]
    },
    {
      selector: '.list.empty',
      declarations: [
        'display: block',
        'color: var(--muted)',
        'font-size: 12px'
      ]
    },
    {
      selector: '.item',
      declarations: [
        'padding: 10px',
        'border: 1px solid var(--border)',
        'border-radius: 9px',
        'background: Canvas'
      ]
    },
    {
      selector: '.item-head',
      declarations: [
        'display: flex',
        'align-items: center',
        'justify-content: space-between',
        'gap: 8px'
      ]
    },
    {
      selector: '.item-title',
      declarations: [
        'font-size: 12px',
        'font-weight: 800'
      ]
    },
    {
      selector: '.item-meta, .item-url, .caption-meta',
      declarations: [
        'color: var(--muted)',
        'font-size: 10px'
      ]
    },
    {
      selector: '.item-url',
      declarations: [
        'margin-top: 6px',
        'overflow-wrap: anywhere',
        'max-height: 42px',
        'overflow: hidden'
      ]
    },
    {
      selector: '.copy',
      declarations: [
        'flex: 0 0 auto',
        'padding: 6px 8px'
      ]
    },
    {
      selector: '.caption-text',
      declarations: [
        'margin: 5px 0 0',
        'white-space: pre-wrap',
        'font-size: 12px',
        'line-height: 1.4'
      ]
    },
    {
      selector: '.inline-status, .notice',
      declarations: [
        'min-height: 17px',
        'margin: 9px 0 0',
        'color: var(--muted)',
        'font-size: 11px'
      ]
    },
    {
      selector: '.action-status',
      declarations: [
        'line-height: 1.4'
      ]
    },
    {
      selector: '.reset-note',
      declarations: [
        'margin: 7px 0 0'
      ]
    },
    {
      selector: '.notice',
      declarations: [
        'margin: 0 3px 8px',
        'color: var(--bad)'
      ]
    },
    {
      selector: '@media (min-width: 430px)',
      nested: [
        {
          selector: '.speech-settings',
          declarations: [
            'grid-template-columns: 1fr 1fr'
          ]
        },
        {
          selector: '.speech-settings label:first-child',
          declarations: [
            'grid-column: 1 / -1'
          ]
        }
      ]
    },
    {
      selector: '@media (prefers-reduced-motion: reduce)',
      nested: [
        {
          selector: '*',
          declarations: [
            'scroll-behavior: auto !important'
          ]
        }
      ]
    }
  ];

  let cssContent = '';

  cssRules.forEach(rule => {
    if (rule.selector.startsWith('@media')) {
      cssContent += `${rule.selector} {\n`;
      rule.nested.forEach(nestedRule => {
        cssContent += `  ${nestedRule.selector} { ${nestedRule.declarations.join('; ')}; }\n`;
      });
      cssContent += '}\n\n';
    } else {
      cssContent += `${rule.selector} { ${rule.declarations.join('; ')}; }\n`;
    }
  });

  return cssContent;
}

function main() {
  const args = process.argv.slice(2);
  
  if (args.length === 0) {
    console.error('Usage: node script.js <output-file>');
    process.exit(1);
  }
  
  const outputFile = args[0];
  const cssContent = generateCSS();
  
  try {
    fs.writeFileSync(outputFile, cssContent);
    console.log(`CSS file generated successfully: ${path.resolve(outputFile)}`);
  } catch (error) {
    console.error('Error writing CSS file:', error.message);
    process.exit(1);
  }
}

main();
