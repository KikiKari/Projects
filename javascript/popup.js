#!/usr/bin/env node
// popup.html — portiert nach javascript
// Quelle: html, Projects@Telegram-Monitor:plugin/extension/popup.html
// Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

const fs = require('fs');
const path = require('path');

function createPopupHTML() {
  const dom = {
    createElement: (tag, attrs = {}, children = []) => {
      const el = { tag, attrs, children };
      if (attrs.id) el.id = attrs.id;
      return el;
    },
    
    createTextNode: (text) => ({ type: 'text', text }),
    
    getElementById: (root, id) => {
      if (root.id === id) return root;
      for (const child of root.children || []) {
        const found = dom.getElementById(child, id);
        if (found) return found;
      }
      return null;
    }
  };

  // Create document structure
  const html = dom.createElement('html', { lang: 'de' });
  const head = dom.createElement('head');
  const body = dom.createElement('body');
  
  html.children = [head, body];

  // Build head section
  head.children = [
    dom.createElement('meta', { charset: 'utf-8' }),
    dom.createElement('title', {}, [dom.createTextNode('TikTok Live Companion')]),
    dom.createElement('style', {}, [dom.createTextNode(`
  :root{
    --bg:#0f1115; --card:#171a21; --line:#262b36; --text:#f2f4f8; --muted:#9aa3b2;
    --accent:#fe2c55; --ok:#22c55e;
    color-scheme: dark;
  }
  @media (prefers-color-scheme: light){
    :root{ --bg:#fff; --card:#f6f7f9; --line:#e3e6ea; --text:#16191d; --muted:#6b7280; }
  }
  *{box-sizing:border-box}
  body{margin:0;width:420px;max-height:600px;overflow:auto;background:var(--bg);color:var(--text);
       font:14px/1.45 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif}
  .wrap{padding:12px}
  header{display:flex;gap:8px;align-items:center;margin-bottom:10px}
  h1{font-size:14px;margin:0;font-weight:650;flex:1}
  .badge{font-size:11px;font-weight:700;padding:3px 9px;border-radius:99px;
         background:#2a2f3a;color:var(--muted);display:inline-flex;align-items:center;gap:5px}
  .badge.live{background:var(--accent);color:#fff}
  .badge .dot{width:6px;height:6px;border-radius:50%;background:currentColor}
  .badge.live .dot{animation:pulse 1.6s infinite}
  @keyframes pulse{0%,100%{opacity:1}50%{opacity:.25}}
  .row{display:flex;gap:6px;flex-wrap:wrap;align-items:center;margin-bottom:8px}
  input,select,button{font:inherit;border-radius:7px;border:1px solid var(--line);
                      background:var(--card);color:var(--text);padding:6px 9px}
  button{cursor:pointer;font-weight:600}
  button.primary{background:var(--accent);border-color:var(--accent);color:#fff}
  .player{position:relative;width:100%;aspect-ratio:9/16;max-height:360px;background:#000;
          border-radius:10px;overflow:hidden;border:1px solid var(--line);margin:8px 0}
  .player iframe{position:absolute;inset:0;width:100%;height:100%;border:0}
  .placeholder{position:absolute;inset:0;display:flex;flex-direction:column;gap:6px;
               align-items:center;justify-content:center;color:var(--muted);
               text-align:center;padding:16px;font-size:13px}
  .card{background:var(--card);border:1px solid var(--line);border-radius:10px;
        padding:10px 12px;margin-bottom:8px}
  h2{font-size:11px;text-transform:uppercase;letter-spacing:.05em;color:var(--muted);
     margin:0 0 6px;font-weight:650}
  .meta{color:var(--muted);font-size:12.5px}
  .strong{color:var(--text);font-weight:600}
  .stream{display:flex;gap:8px;padding:5px 0;border-bottom:1px solid var(--line);font-size:12.5px}
  .stream:last-child{border-bottom:0}
  .stream .when{color:var(--muted);white-space:nowrap;font-variant-numeric:tabular-nums}
  .stream .t{flex:1;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
  .stream.now{color:var(--accent);font-weight:650}
  .err{background:#3a1d22;border:1px solid #5c2a33;color:#ffb4c0;padding:8px 10px;
       border-radius:8px;font-size:12.5px;margin-bottom:8px}
  @media (prefers-color-scheme: light){ .err{background:#fdeceb;border-color:#f5c6c2;color:#b91c1c} }
  .note{font-size:11.5px;color:var(--muted);line-height:1.4;margin-top:8px}
  a{color:var(--accent)}
`)])
  ];

  // Build body section
  const wrap = dom.createElement('div', { class: 'wrap' });
  
  // Header
  const header = dom.createElement('header');
  const h1 = dom.createElement('h1', {}, [dom.createTextNode('TikTok Live Companion')]);
  const badge = dom.createElement('span', { class: 'badge', id: 'badge' });
  const badgeDot = dom.createElement('span', { class: 'dot' });
  const badgeText = dom.createElement('span', { id: 'badgeText' }, [dom.createTextNode('—')]);
  
  badge.children = [badgeDot, badgeText];
  header.children = [h1, badge];
  
  // Input row
  const row1 = dom.createElement('div', { class: 'row' });
  const userInput = dom.createElement('input', { 
    id: 'user', 
    placeholder: '@name', 
    style: 'flex:1;min-width:120px' 
  });
  const goButton = dom.createElement('button', { 
    class: 'primary', 
    id: 'go' 
  }, [dom.createTextNode('Anzeigen')]);
  const forceButton = dom.createElement('button', { 
    id: 'force', 
    title: 'Player ohne Statusabfrage laden' 
  }, [dom.createTextNode('Player')]);
  
  row1.children = [userInput, goButton, forceButton];
  
  // Options row
  const row2 = dom.createElement('div', { class: 'row' });
  const select = dom.createElement('select', { id: 'every', style: 'flex:1' });
  const opt1 = dom.createElement('option', { value: '1' }, [dom.createTextNode('Prüfung jede Minute')]);
  const opt2 = dom.createElement('option', { value: '2', selected: '' }, [dom.createTextNode('alle 2 Minuten')]);
  const opt3 = dom.createElement('option', { value: '5' }, [dom.createTextNode('alle 5 Minuten')]);
  const opt4 = dom.createElement('option', { value: '0' }, [dom.createTextNode('nur manuell')]);
  
  select.children = [opt1, opt2, opt3, opt4];
  
  const label = dom.createElement('label', { class: 'meta' });
  const checkbox = dom.createElement('input', { type: 'checkbox', id: 'notify', checked: '' });
  label.children = [checkbox, dom.createTextNode(' benachrichtigen')];
  
  row2.children = [select, label];
  
  // Error container
  const errorDiv = dom.createElement('div', { id: 'error' });
  
  // Player container
  const playerDiv = dom.createElement('div', { class: 'player', id: 'player' });
  const placeholderDiv = dom.createElement('div', { class: 'placeholder', id: 'placeholder' });
  const placeholderIcon = dom.createElement('div', { style: 'font-size:28px' }, [dom.createTextNode('📺')]);
  const phText = dom.createElement('div', { id: 'phText' }, [dom.createTextNode('Konto eingeben und „Anzeigen“ drücken.')]);
  
  placeholderDiv.children = [placeholderIcon, phText];
  playerDiv.children = [placeholderDiv];
  
  // Status card
  const statusCard = dom.createElement('div', { class: 'card' });
  const statusH2 = dom.createElement('h2', {}, [dom.createTextNode('Status')]);
  const statusDiv = dom.createElement('div', { id: 'status', class: 'meta' }, [dom.createTextNode('—')]);
  
  statusCard.children = [statusH2, statusDiv];
  
  // Streams card
  const streamsCard = dom.createElement('div', { class: 'card' });
  const streamsH2 = dom.createElement('h2', {}, [dom.createTextNode('Letzte Sendungen')]);
  const streamsDiv = dom.createElement('div', { id: 'streams', class: 'meta' }, [dom.createTextNode('—')]);
  
  streamsCard.children = [streamsH2, streamsDiv];
  
  // Note
  const noteP = dom.createElement('p', { class: 'note' }, [
    dom.createTextNode('Eingebettet wird der offizielle TikTok-Live-Player — '),
    dom.createElement('b', {}, [dom.createTextNode('keine Anmeldung, keine Geschenk- oder Kauf-Oberfläche')]),
    dom.createTextNode('. Der Status kommt aus öffentlichen Quellen; nichts davon umgeht eine Zugangskontrolle.')
  ]);
  
  // Scripts
  const script1 = dom.createElement('script', { src: 'tiktok-companion.js' });
  const script2 = dom.createElement('script', { src: 'popup.js' });
  
  // Assemble body
  wrap.children = [header, row1, row2, errorDiv, playerDiv, statusCard, streamsCard, noteP];
  body.children = [wrap, script1, script2];
  
  // Render to HTML string
  function renderElement(el) {
    if (el.type === 'text') {
      return el.text;
    }
    
    const attrs = Object.entries(el.attrs || {})
      .map(([k, v]) => `${k}="${v}"`)
      .join(' ');
    
    if (el.children && el.children.length > 0) {
      const content = el.children.map(renderElement).join('');
      return `<${el.tag}${attrs ? ' ' + attrs : ''}>${content}</${el.tag}>`;
    }
    
    return `<${el.tag}${attrs ? ' ' + attrs : ''}>`;
  }
  
  return `<!DOCTYPE html>
${renderElement(html)}`;
}

// Write to file if argument provided
if (process.argv[2]) {
  const outputPath = path.resolve(process.argv[2]);
  fs.writeFileSync(outputPath, createPopupHTML(), 'utf8');
  console.log(`Popup HTML written to ${outputPath}`);
} else {
  console.log(createPopupHTML());
}
