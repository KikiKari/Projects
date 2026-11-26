#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "0563b89c4997e8ea569317db3d4a93ae1eb917fd2578115f44a9f853b091f66e", "source_sha256": "58ad2830d3e11b79c54044cfe5a82e7e3fd2a9b1ca1f65c546ff6e92e821c6f3", "target_language": "javascript"}
// index.html — portiert nach javascript
// Quelle: html, Projects@Telegram-Monitor:public/index.html
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

const fs = require('fs');
const path = require('path');

function createHtmlDocument() {
  const doc = {
    doctype: '<!DOCTYPE html>',
    html: {
      attrs: { lang: 'de' },
      head: {
        meta: [
          { charset: 'utf-8' },
          { name: 'viewport', content: 'width=device-width, initial-scale=1' },
          { 'http-equiv': 'Content-Type', content: 'text/html; charset=utf-8' }
        ],
        title: 'Telegram Monitor — lokaler Beobachtungs-Companion',
        metaDescription: {
          name: 'description',
          content: 'Beobachtet öffentliche Telegram-Kanäle und TikTok-Konten auf dem eigenen Rechner und meldet den Livegang. Keine Cloud, keine Anmeldung.'
        },
        metaThemeColor: { name: 'theme-color', content: '#2481cc' },
        ogTitle: { property: 'og:title', content: 'Telegram Monitor' },
        ogDescription: { property: 'og:description', content: 'Lokaler Beobachtungs-Companion. Docker, PWA, Meldung beim Livegang.' },
        ogType: { property: 'og:type', content: 'website' },
        style: `:root{
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
         font-size:13.5px;color:var(--muted)}`
      },
      body: {
        divWrap: {
          attrs: { class: 'wrap' },
          header: {
            h1: 'Telegram Monitor',
            pLede: {
              attrs: { class: 'lede' },
              text: 'Beobachtet öffentliche Telegram-Kanäle und TikTok-Konten auf deinem eigenen Rechner und meldet sich, wenn jemand live geht. Keine Cloud, kein Konto, keine App-Installation auf dem Telefon nötig.'
            },
            badges: {
              attrs: { class: 'badges' },
              badgeItems: [
                { class: 'badge on', text: 'Standardbibliothek' },
                { class: 'badge on', text: 'Docker' },
                { class: 'badge on', text: 'installierbar als App' },
                { class: 'badge on', text: 'Browser-Erweiterung' },
                { class: 'badge', text: 'Windows · macOS · Linux' }
              ]
            },
            cta: {
              attrs: { class: 'cta' },
              buttons: [
                { class: 'btn primary', href: 'https://github.com/KikiKari/Projects/tree/Telegram-Monitor', text: 'Quelltext auf GitHub' },
                { class: 'btn', href: '/viewer', text: 'Live-Viewer öffnen' }
              ]
            }
          },
          h2WasTut: { text: 'Was es tut' },
          gridCards: {
            attrs: { class: 'grid' },
            cards: [
              {
                class: 'card',
                h3: 'Beobachten',
                p: 'Fragt jeden Kanal im eingestellten Turnus ab und sammelt den Verlauf auf der Platte — neueste Beiträge oben, anders als in Telegram selbst.'
              },
              {
                class: 'card',
                h3: 'Erkennen',
                p: 'Vergleicht den Zustand mit dem letzten Durchlauf. Gemeldet wird nur ein echter Wechsel; ein fehlgeschlagener Abruf gilt nicht als „offline".'
              },
              {
                class: 'card',
                h3: 'Melden',
                p: 'Drei Wege gleichzeitig: Ereignisprotokoll, Systemmeldung und Webhook. Fällt einer aus, steht der Wechsel trotzdem mit Zeitstempel fest.'
              }
            ]
          },
          h2Zugange: { text: 'Drei Zugänge, ein Monitor' },
          tableZugange: {
            attrs: { class: '' },
            rows: [
              ['Zugang', 'wofür'],
              ['Installierte App', 'Vollständige Oberfläche mit allen Reitern, eigenes Fenster ohne Adressleiste, Symbol im Startmenü'],
              ['Browser-Erweiterung', 'Meldung beim Livegang, ohne dass ein Tab offen sein muss'],
              ['Live-Viewer', 'Bettet den offiziellen Player ein — ohne Anmeldung, ohne Geschenk- oder Kauf-Oberfläche. <a href="/viewer">Hier direkt ausprobieren.</a>']
            ]
          },
          h2Einrichten: { text: 'Einrichten' },
          olSteps: {
            attrs: { class: 'steps' },
            steps: [
              {
                b: 'Repository holen',
                p: 'Branch <code>Telegram-Monitor</code> auschecken.',
                pre: `<code>git clone -b Telegram-Monitor https://github.com/KikiKari/Projects.git
cd Projects</code>`
              },
              {
                b: 'Dauerhaft starten',
                p: 'Bindet an <code>127.0.0.1:8765</code>, der Verlauf liegt im Volume <code>monitor-data</code> und überlebt jedes Neubauen. Unter Windows genügt ein Doppelklick auf <code>Telegram Monitor - Docker.cmd</code>.',
                pre: '<code>docker compose up -d --build</code>'
              },
              {
                b: 'Ohne Docker',
                p: 'Der Kern braucht nur die Standardbibliothek — nichts zu installieren.',
                pre: '<code>python server.py --poll-interval 120</code>'
              },
              {
                b: 'Als App einrichten',
                p: 'In der geöffneten Oberfläche auf <b>Als App installieren</b> klicken. Danach liegt der Monitor als eigenes Programm im Startmenü.'
              },
              {
                b: 'Aufs Telefon bringen',
                p: 'Über das eigene VPN freigeben, dann die <code>https</code>-Adresse auf dem Telefon öffnen und dort installieren. Eine <code>.apk</code> gibt es nicht und wird auch nicht gebraucht.',
                pre: '<code>tailscale serve --bg 8765</code>'
              }
            ]
          },
          h2NichtLaeuft: { text: 'Was hier nicht läuft' },
          note: {
            attrs: { class: 'note' },
            b: 'Diese Seite ist nur die Visitenkarte.',
            text: 'Der Monitor selbst läuft <i>nicht</i> im Web. Sein Kern ist ein Hintergrundprozess, der dauerhaft abfragt und Zustand auf die Platte schreibt — beides gibt es in einer serverlosen Umgebung nicht. Ausgeliefert werden hier nur diese Seite und der Viewer, der ohnehin ohne Server auskommt. Beobachtet wird auf deinem Rechner.'
          },
          h2Grenzen: { text: 'Grenzen' },
          pGrenzen1: 'Gelesen wird ausschließlich, was öffentlich abrufbar ist. Anmeldeschranken und Zugriffssperren werden nicht umgangen — wo es offizielle Einbettungen gibt, werden die genommen. Private Telegram-Konten liefern nur Name und Bio; das ist eine Einschränkung von Telegram, kein Fehler.',
          pGrenzen2: 'Der Turnus bleibt höflich: ein bis fünf Minuten. Sekundentakt bringt selten mehr Information und handelt eine Sperre ein.',
          footer: {
            attrs: { class: '' },
            text: 'Läuft lokal, gehört dir. Das wiederverwendbare Muster dahinter steckt im Skill <code>lokaler-companion</code>.'
          }
        }
      }
    }
  };

  return doc;
}

function renderElement(tag, attrs = {}, content = '') {
  let attrString = '';
  for (const [key, value] of Object.entries(attrs)) {
    if (value !== undefined && value !== null) {
      attrString += ` ${key}="${value}"`;
    }
  }
  
  if (typeof content === 'string') {
    return `<${tag}${attrString}>${content}</${tag}>`;
  } else if (Array.isArray(content)) {
    return `<${tag}${attrString}>${content.join('')}</${tag}>`;
  } else {
    return `<${tag}${attrString}></${tag}>`;
  }
}

function generateHtml(doc) {
  let html = doc.doctype + '\n';
  
  // Build head section
  let headContent = '';
  headContent += renderElement('meta', { charset: 'utf-8' }) + '\n';
  headContent += renderElement('meta', { name: 'viewport', content: 'width=device-width, initial-scale=1' }) + '\n';
  headContent += renderElement('title', {}, doc.html.head.title) + '\n';
  headContent += renderElement('meta', doc.html.head.metaDescription) + '\n';
  headContent += renderElement('meta', doc.html.head.metaThemeColor) + '\n';
  headContent += renderElement('meta', doc.html.head.ogTitle) + '\n';
  headContent += renderElement('meta', doc.html.head.ogDescription) + '\n';
  headContent += renderElement('meta', doc.html.head.ogType) + '\n';
  headContent += renderElement('style', {}, doc.html.head.style);

  // Build body section
  let bodyContent = '';
  
  // Header section
  const header = doc.html.body.divWrap.header;
  bodyContent += renderElement('header', {}, 
    renderElement('h1', {}, header.h1) +
    renderElement('p', header.pLede.attrs, header.pLede.text) +
    renderElement('div', header.badges.attrs,
      header.badges.badgeItems.map(badge => renderElement('span', { class: badge.class }, badge.text)).join('')
    ) +
    renderElement('div', header.cta.attrs,
      header.cta.buttons.map(btn => renderElement('a', { class: btn.class, href: btn.href }, btn.text)).join('')
    )
  );
  
  // What it does section
  bodyContent += renderElement('h2', {}, doc.html.body.divWrap.h2WasTut.text);
  const gridCards = doc.html.body.divWrap.gridCards;
  bodyContent += renderElement('div', gridCards.attrs,
    gridCards.cards.map(card => 
      renderElement('div', { class: card.class }, 
        renderElement('h3', {}, card.h3) + 
        renderElement('p', {}, card.p)
      )
    ).join('')
  );
  
  // Access methods section
  bodyContent += renderElement('h2', {}, doc.html.body.divWrap.h2Zugange.text);
  const tableRows = doc.html.body.divWrap.tableZugange.rows;
  let tableContent = '';
  tableRows.forEach((row, index) => {
    if (index === 0) {
      tableContent += renderElement('tr', {}, 
        renderElement('th', {}, row[0]) + 
        renderElement('th', {}, row[1])
      );
    } else {
      tableContent += renderElement('tr', {}, 
        renderElement('td', {}, renderElement('b', {}, row[0])) + 
        renderElement('td', {}, row[1])
      );
    }
  });
  bodyContent += renderElement('table', {}, tableContent);
  
  // Setup section
  bodyContent += renderElement('h2', {}, doc.html.body.divWrap.h2Einrichten.text);
  const steps = doc.html.body.divWrap.olSteps.steps;
  let stepsContent = '';
  steps.forEach(step => {
    stepsContent += renderElement('li', {},
      renderElement('b', {}, step.b) +
      renderElement('p', {}, step.p) +
      (step.pre ? renderElement('pre', {}, step.pre) : '')
    );
  });
  bodyContent += renderElement('ol', doc.html.body.divWrap.olSteps.attrs, stepsContent);
  
  // What doesn't run section
  const noteSection = doc.html.body.divWrap.note;
  bodyContent += renderElement('h2', {}, doc.html.body.divWrap.h2NichtLaeuft.text);
  bodyContent += renderElement('div', noteSection.attrs,
    renderElement('b', {}, noteSection.b) + noteSection.text
  );
  
  // Limitations section
  bodyContent += renderElement('h2', {}, doc.html.body.divWrap.h2Grenzen.text);
  bodyContent += renderElement('p', {}, doc.html.body.divWrap.pGrenzen1);
  bodyContent += renderElement('p', {}, doc.html.body.divWrap.pGrenzen2);
  
  // Footer
  bodyContent += renderElement('footer', doc.html.body.divWrap.footer.attrs, doc.html.body.divWrap.footer.text);
  
  // Wrap content in div.wrap
  const wrapContent = bodyContent;
  
  // Complete HTML document
  html += renderElement('html', doc.html.attrs,
    renderElement('head', {}, headContent) +
    renderElement('body', {}, renderElement('div', { class: 'wrap' }, wrapContent))
  );
  
  return html;
}

function main() {
  const outputFile = process.argv[2];
  
  if (!outputFile) {
    console.error('Bitte geben Sie eine Ausgabedatei als Parameter an.');
    process.exit(1);
  }
  
  const doc = createHtmlDocument();
  const html = generateHtml(doc);
  
  fs.writeFileSync(outputFile, html, 'utf8');
  console.log(`HTML-Dokument wurde erfolgreich in ${outputFile} geschrieben.`);
}

main();
