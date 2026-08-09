#!/usr/bin/env node
// index.html — portiert nach javascript
// Quelle: html, Projects@Telegram-Monitor:public/index.html
// Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

import { writeFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

// Helper function to create HTML elements
function createElement(tag, attributes = {}, children = []) {
  const attrs = Object.entries(attributes)
    .map(([key, value]) => `${key}="${value}"`)
    .join(' ');
  
  const openingTag = attrs ? `<${tag} ${attrs}>` : `<${tag}>`;
  const content = Array.isArray(children) ? children.join('') : children;
  
  return `${openingTag}${content}</${tag}>`;
}

// Helper function to create meta tags
function createMeta(attrs) {
  return createElement('meta', attrs);
}

// Helper function to create badges
function createBadge(text, active = false) {
  const className = active ? 'badge on' : 'badge';
  return createElement('span', { class: className }, text);
}

// Helper function to create buttons
function createButton(text, href, primary = false) {
  const className = primary ? 'btn primary' : 'btn';
  return createElement('a', { class: className, href }, text);
}

// Helper function to create cards
function createCard(title, content) {
  return createElement('div', { class: 'card' }, [
    createElement('h3', {}, title),
    createElement('p', {}, content)
  ]);
}

// Helper function to create table rows
function createTableRow(cells) {
  return createElement('tr', {}, cells.map(cell => createElement('td', {}, cell)));
}

// Generate the complete HTML document
function generateHTML() {
  const doctype = '<!DOCTYPE html>';
  
  // Head section
  const metaTags = [
    createMeta({ charset: 'utf-8' }),
    createMeta({ name: 'viewport', content: 'width=device-width, initial-scale=1' }),
    createElement('title', {}, 'Telegram Monitor — lokaler Beobachtungs-Companion'),
    createMeta({ name: 'description', content: 'Beobachtet öffentliche Telegram-Kanäle und TikTok-Konten auf dem eigenen Rechner und meldet den Livegang. Keine Cloud, keine Anmeldung.' }),
    createMeta({ name: 'theme-color', content: '#2481cc' }),
    createMeta({ property: 'og:title', content: 'Telegram Monitor' }),
    createMeta({ property: 'og:description', content: 'Lokaler Beobachtungs-Companion. Docker, PWA, Meldung beim Livegang.' }),
    createMeta({ property: 'og:type', content: 'website' })
  ];

  const style = `
  :root{
    --bg:#ffffff; --soft:#f6f7f9; --line:#e3e6ea; --text:#16191d; --muted:#5f6773;
    --tg:#2481cc; --tg-soft:#e8f2fb; --tt:#fe2c55;
    --ok:#15803d; --ok-soft:#e7f6ec; --warn:#b45309; --warn-soft:#fdf3e3;
    color-scheme: light;
  }
  @media (prefers-color-scheme: dark){
    :root{ --bg:#0f1115; --soft:#171a21; --line:#262b36; --text:#f2f4f8; --muted:#9aa3b2;
           --tg-soft:#132a3d; --ok-soft:#12261a; --warn-soft:#2c2110; color-scheme: dark; }
  }
  *{box-sizing:border-box}
  body{margin:0;background:var(--bg);color:var(--text);
       font:16px/1.6 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif}
  .wrap{max-width:820px;margin:0 auto;padding:0 20px 72px}
  header{padding:64px 0 40px;border-bottom:1px solid var(--line);margin-bottom:8px}
  h1{font-size:34px;line-height:1.2;margin:0 0 12px;letter-spacing:-.02em}
  .lede{font-size:18px;color:var(--muted);margin:0 0 22px;max-width:60ch}
  h2{font-size:13px;margin:44px 0 14px;text-transform:uppercase;letter-spacing:.06em;
     color:var(--muted);font-weight:650}
  h3{font-size:17px;margin:26px 0 6px}
  p{margin:0 0 14px;max-width:68ch}
  .badges{display:flex;gap:7px;flex-wrap:wrap;margin-bottom:22px}
  .badge{font-size:12px;font-weight:650;padding:4px 11px;border-radius:99px;
         background:var(--soft);color:var(--muted);border:1px solid var(--line)}
  .badge.on{background:var(--ok-soft);color:var(--ok);border-color:transparent}
  .cta{display:flex;gap:10px;flex-wrap:wrap}
  .btn{display:inline-block;font-weight:650;font-size:15px;padding:11px 20px;
       border-radius:9px;text-decoration:none;border:1px solid var(--line);
       background:var(--bg);color:var(--text)}
  .btn.primary{background:var(--tg);border-color:var(--tg);color:#fff}
  .btn:hover{border-color:var(--tg)}
  .grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(230px,1fr));gap:14px}
  .card{border:1px solid var(--line);border-radius:12px;padding:16px 18px;background:var(--bg)}
  .card h3{margin-top:0;font-size:15.5px}
  .card p{font-size:14px;color:var(--muted);margin:0}
  ol.steps{list-style:none;counter-reset:s;padding:0;margin:0}
  ol.steps li{counter-increment:s;position:relative;padding:0 0 20px 40px;
              border-left:2px solid var(--line);margin-left:11px}
  ol.steps li:last-child{border-left-color:transparent;padding-bottom:0}
  ol.steps li::before{content:counter(s);position:absolute;left:-13px;top:0;
       width:24px;height:24px;border-radius:50%;background:var(--tg);color:#fff;
       display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:700}
  ol.steps b{display:block;margin-bottom:3px}
  ol.steps p{font-size:14.5px;color:var(--muted);margin:0 0 8px}
  code{background:var(--soft);padding:2px 7px;border-radius:5px;font-size:13.5px;
       font-family:ui-monospace,SFMono-Regular,Menlo,monospace;word-break:break-word}
  pre{background:var(--soft);border:1px solid var(--line);border-radius:10px;
      padding:13px 15px;overflow-x:auto;margin:0 0 14px}
  pre code{background:none;padding:0;font-size:13.5px;line-height:1.7}
  table{width:100%;border-collapse:collapse;font-size:14.5px;margin:0 0 16px}
  th,td{text-align:left;padding:9px 11px;border-bottom:1px solid var(--line);vertical-align:top}
  th{color:var(--muted);font-size:12px;text-transform:uppercase;letter-spacing:.04em;font-weight:650}
  .note{border-left:3px solid var(--warn);background:var(--warn-soft);
        border-radius:0 9px 9px 0;padding:13px 16px;margin:0 0 16px;font-size:14.5px}
  .note b{display:block;margin-bottom:3px}
  a{color:var(--tg)}
  footer{margin-top:52px;padding-top:22px;border-top:1px solid var(--line);
         font-size:13.5px;color:var(--muted)}
`;

  const head = createElement('head', {}, [...metaTags, createElement('style', {}, style)]);

  // Body content
  const header = createElement('header', {}, [
    createElement('h1', {}, 'Telegram Monitor'),
    createElement('p', { class: 'lede' }, 'Beobachtet öffentliche Telegram-Kanäle und TikTok-Konten auf deinem eigenen Rechner und meldet sich, wenn jemand live geht. Keine Cloud, kein Konto, keine App-Installation auf dem Telefon nötig.'),
    createElement('div', { class: 'badges' }, [
      createBadge('Standardbibliothek', true),
      createBadge('Docker', true),
      createBadge('installierbar als App', true),
      createBadge('Browser-Erweiterung', true),
      createBadge('Windows · macOS · Linux')
    ]),
    createElement('div', { class: 'cta' }, [
      createButton('Quelltext auf GitHub', 'https://github.com/KikiKari/Projects/tree/Telegram-Monitor', true),
      createButton('Live-Viewer öffnen', '/viewer')
    ])
  ]);

  const whatItDoes = [
    createElement('h2', {}, 'Was es tut'),
    createElement('div', { class: 'grid' }, [
      createCard('Beobachten', 'Fragt jeden Kanal im eingestellten Turnus ab und sammelt den Verlauf auf der Platte — neueste Beiträge oben, anders als in Telegram selbst.'),
      createCard('Erkennen', 'Vergleicht den Zustand mit dem letzten Durchlauf. Gemeldet wird nur ein echter Wechsel; ein fehlgeschlagener Abruf gilt nicht als „offline".'),
      createCard('Melden', 'Drei Wege gleichzeitig: Ereignisprotokoll, Systemmeldung und Webhook. Fällt einer aus, steht der Wechsel trotzdem mit Zeitstempel fest.')
    ])
  ];

  const accessTable = [
    createElement('h2', {}, 'Drei Zugänge, ein Monitor'),
    createElement('table', {}, [
      createElement('tr', {}, [
        createElement('th', {}, 'Zugang'),
        createElement('th', {}, 'wofür')
      ]),
      createElement('tr', {}, [
        createElement('td', {}, createElement('b', {}, 'Installierte App')),
        createElement('td', {}, 'Vollständige Oberfläche mit allen Reitern, eigenes Fenster ohne Adressleiste, Symbol im Startmenü')
      ]),
      createElement('tr', {}, [
        createElement('td', {}, createElement('b', {}, 'Browser-Erweiterung')),
        createElement('td', {}, 'Meldung beim Livegang, ohne dass ein Tab offen sein muss')
      ]),
      createElement('tr', {}, [
        createElement('td', {}, createElement('b', {}, 'Live-Viewer')),
        createElement('td', {}, 'Bettet den offiziellen Player ein — ohne Anmeldung, ohne Geschenk- oder Kauf-Oberfläche. ' + createElement('a', { href: '/viewer' }, 'Hier direkt ausprobieren.'))
      ])
    ])
  ];

  const setupSteps = [
    createElement('h2', {}, 'Einrichten'),
    createElement('ol', { class: 'steps' }, [
      createElement('li', {}, [
        createElement('b', {}, 'Repository holen'),
        createElement('p', {}, 'Branch ' + createElement('code', {}, 'Telegram-Monitor') + ' auschecken.'),
        createElement('pre', {}, createElement('code', {}, 'git clone -b Telegram-Monitor https://github.com/KikiKari/Projects.git\ncd Projects'))
      ]),
      createElement('li', {}, [
        createElement('b', {}, 'Dauerhaft starten'),
        createElement('p', {}, 'Bindet an ' + createElement('code', {}, '127.0.0.1:8765') + ', der Verlauf liegt im Volume ' + createElement('code', {}, 'monitor-data') + ' und überlebt jedes Neubauen. Unter Windows genügt ein Doppelklick auf ' + createElement('code', {}, 'Telegram Monitor - Docker.cmd') + '.'),
        createElement('pre', {}, createElement('code', {}, 'docker compose up -d --build'))
      ]),
      createElement('li', {}, [
        createElement('b', {}, 'Ohne Docker'),
        createElement('p', {}, 'Der Kern braucht nur die Standardbibliothek — nichts zu installieren.'),
        createElement('pre', {}, createElement('code', {}, 'python server.py --poll-interval 120'))
      ]),
      createElement('li', {}, [
        createElement('b', {}, 'Als App einrichten'),
        createElement('p', {}, 'In der geöffneten Oberfläche auf ' + createElement('b', {}, 'Als App installieren') + ' klicken. Danach liegt der Monitor als eigenes Programm im Startmenü.')
      ]),
      createElement('li', {}, [
        createElement('b', {}, 'Aufs Telefon bringen'),
        createElement('p', {}, 'Über das eigene VPN freigeben, dann die ' + createElement('code', {}, 'https') + '-Adresse auf dem Telefon öffnen und dort installieren. Eine ' + createElement('code', {}, '.apk') + ' gibt es nicht und wird auch nicht gebraucht.'),
        createElement('pre', {}, createElement('code', {}, 'tailscale serve --bg 8765'))
      ])
    ])
  ];

  const limitationsNote = [
    createElement('h2', {}, 'Was hier nicht läuft'),
    createElement('div', { class: 'note' }, [
      createElement('b', {}, 'Diese Seite ist nur die Visitenkarte.'),
      ' Der Monitor selbst läuft ',
      createElement('i', {}, 'nicht'),
      ' im Web. Sein Kern ist ein Hintergrundprozess, der dauerhaft abfragt und Zustand auf die Platte schreibt — beides gibt es in einer serverlosen Umgebung nicht. Ausgeliefert werden hier nur diese Seite und der Viewer, der ohnehin ohne Server auskommt. Beobachtet wird auf deinem Rechner.'
    ])
  ];

  const limitations = [
    createElement('h2', {}, 'Grenzen'),
    createElement('p', {}, 'Gelesen wird ausschließlich, was öffentlich abrufbar ist. Anmeldeschranken und Zugriffssperren werden nicht umgangen — wo es offizielle Einbettungen gibt, werden die genommen. Private Telegram-Konten liefern nur Name und Bio; das ist eine Einschränkung von Telegram, kein Fehler.'),
    createElement('p', {}, 'Der Turnus bleibt höflich: ein bis fünf Minuten. Sekundentakt bringt selten mehr Information und handelt eine Sperre ein.')
  ];

  const footer = createElement('footer', {}, 'Läuft lokal, gehört dir. Das wiederverwendbare Muster dahinter steckt im Skill ' + createElement('code', {}, 'lokaler-companion') + '.');

  const bodyContent = [
    header,
    ...whatItDoes,
    ...accessTable,
    ...setupSteps,
    ...limitationsNote,
    ...limitations,
    footer
  ];

  const body = createElement('body', {}, [
    createElement('div', { class: 'wrap' }, bodyContent)
  ]);

  const html = createElement('html', { lang: 'de' }, [head, body]);
  
  return doctype + html;
}

// Main execution
function main() {
  const outputFile = process.argv[2] || 'index.html';
  const htmlContent = generateHTML();
  
  try {
    writeFileSync(outputFile, htmlContent);
    console.log(`Successfully generated ${outputFile}`);
  } catch (error) {
    console.error(`Error writing file: ${error.message}`);
    process.exit(1);
  }
}

main();
