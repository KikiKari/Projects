#!/usr/bin/env node
// telegram-monitor-uebersicht.html — portiert nach javascript
// Quelle: html, Projects@Telegram-Monitor:telegram-monitor-uebersicht.html
// Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

import fs from 'fs';
import path from 'path';

function createHtmlDocument() {
  const doc = {
    doctype: '<!DOCTYPE html>',
    html: {
      attrs: { lang: 'de' },
      head: {
        meta: [
          { charset: 'utf-8' },
          { name: 'viewport', content: 'width=device-width, initial-scale=1.0' }
        ],
        title: 'Telegram Monitor - Live',
        style: `
  :root{
    --bg:#ffffff; --soft:#f6f7f9; --line:#e3e6ea; --text:#16191d; --muted:#6b7280;
    --accent:#2481cc; --accent-soft:#e8f2fb; --discord:#5865f2; --discord-soft:#eceefe;
    --ok:#15803d; --ok-soft:#e7f6ec; --err:#b91c1c; --err-soft:#fdeceb;
    --warn:#b45309; --warn-soft:#fdf3e3;
    color-scheme: light;
  }
  *{box-sizing:border-box}
  body{margin:0;background:var(--bg);color:var(--text);
       font:15px/1.55 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif}
  .wrap{max-width:940px;margin:0 auto;padding:4px 2px 40px}
  h1{font-size:20px;margin:0 0 4px}
  h2{font-size:14px;margin:26px 0 10px;text-transform:uppercase;letter-spacing:.05em;
     color:var(--muted);font-weight:650}
  .sub{color:var(--muted);font-size:13px;margin:0 0 12px}
  .bar{display:flex;gap:8px;flex-wrap:wrap;align-items:center;margin:12px 0 6px}
  select,input{font:inherit;border:1px solid var(--line);border-radius:8px;padding:7px 10px;
               background:var(--bg);color:var(--text)}
  button{font:inherit;font-weight:600;border:1px solid var(--line);background:var(--bg);
         color:var(--text);border-radius:8px;padding:7px 13px;cursor:pointer}
  button.primary{background:var(--accent);border-color:var(--accent);color:#fff}
  button:disabled{opacity:.55;cursor:default}
  .live{display:inline-flex;align-items:center;gap:7px;font-size:12.5px;color:var(--muted);
        font-weight:600}
  .dot{width:9px;height:9px;border-radius:50%;background:var(--ok);
       animation:pulse 1.8s infinite}
  .dot.paused{background:var(--muted);animation:none}
  .dot.err{background:var(--err);animation:none}
  @keyframes pulse{0%,100%{opacity:1}50%{opacity:.3}}
  .chips{display:flex;gap:6px;flex-wrap:wrap;margin:8px 0 4px}
  .chip{font-size:11.5px;padding:3px 9px;border-radius:99px;background:var(--ok-soft);
        color:var(--ok);font-weight:650}
  .chip.off{background:var(--soft);color:var(--muted)}
  .chip.mode{background:var(--accent-soft);color:var(--accent)}
  .chip.warn{background:var(--warn-soft);color:var(--warn)}
  .card{border:1px solid var(--line);border-radius:12px;padding:14px 16px;margin-bottom:10px}
  .head{display:flex;gap:11px;align-items:flex-start}
  .avatar{width:38px;height:38px;border-radius:50%;object-fit:cover;background:var(--soft);flex:none}
  .title{font-weight:650;font-size:15px;display:flex;gap:7px;align-items:center;flex-wrap:wrap}
  .meta{color:var(--muted);font-size:12.5px;margin-top:2px}
  .desc{font-size:13.5px;margin-top:7px;white-space:pre-wrap}
  .tag{font-size:11px;padding:2px 7px;border-radius:5px;background:var(--soft);
       color:var(--muted);font-weight:650}
  .tag.tg{background:var(--accent-soft);color:var(--accent)}
  .tag.dc{background:var(--discord-soft);color:var(--discord)}
  .tag.ok{background:var(--ok-soft);color:var(--ok)}
  .tag.no{background:var(--err-soft);color:var(--err)}
  .score{font-variant-numeric:tabular-nums;font-size:11.5px;color:var(--muted);
         border:1px solid var(--line);border-radius:5px;padding:1px 6px}
  .stream{max-height:430px;overflow:auto;border:1px solid var(--line);border-radius:10px;
          padding:4px 12px;margin-top:11px;background:var(--soft)}
  .post{border-left:3px solid var(--accent-soft);padding:6px 0 6px 11px;margin:9px 0;
        background:var(--bg);border-radius:0 6px 6px 0;padding-right:8px}
  .post.fresh{border-left-color:var(--ok);background:#f3fbf5}
  .when{color:var(--muted);font-size:12px}
  .txt{font-size:13.5px;white-space:pre-wrap;margin-top:3px;word-break:break-word}
  .reac{font-size:12px;color:var(--muted);margin-top:4px}
  .new-badge{background:var(--ok);color:#fff;font-size:10.5px;font-weight:700;
             padding:1px 6px;border-radius:4px;margin-left:6px}
  .empty{color:var(--muted);border:1px dashed var(--line);border-radius:10px;
         padding:16px;text-align:center;font-size:13.5px}
  .errbox{background:var(--err-soft);border:1px solid #f5c6c2;color:var(--err);
          padding:9px 12px;border-radius:8px;font-size:13px;margin-top:8px}
  .note{background:var(--soft);border:1px solid var(--line);border-radius:10px;
        padding:12px 14px;font-size:13.5px;color:var(--muted);margin-top:18px}
  .note b{color:var(--text)}
  code{background:var(--soft);padding:1px 5px;border-radius:4px;font-size:12.5px;
       font-family:ui-monospace,SFMono-Regular,Menlo,monospace}
  a{color:var(--accent);text-decoration:none} a:hover{text-decoration:underline}
  details{margin-top:20px;border:1px solid var(--line);border-radius:12px;padding:12px 14px}
  summary{cursor:pointer;font-weight:650;font-size:14px}
`
      },
      body: {
        div: {
          attrs: { class: 'wrap' },
          children: [
            { h1: 'Telegram Monitor' },
            { p: { attrs: { class: 'sub', id: 'stand' }, text: '' } },
            {
              div: {
                attrs: { class: 'bar' },
                children: [
                  {
                    span: {
                      attrs: { class: 'live' },
                      children: [
                        { span: { attrs: { class: 'dot', id: 'dot' }, text: '' } },
                        { span: { attrs: { id: 'liveLabel' }, text: 'bereit' } }
                      ]
                    }
                  },
                  {
                    select: {
                      attrs: { id: 'every' },
                      children: [
                        { option: { attrs: { value: '30' }, text: 'alle 30 s' } },
                        { option: { attrs: { value: '60', selected: true }, text: 'alle 60 s' } },
                        { option: { attrs: { value: '180' }, text: 'alle 3 min' } },
                        { option: { attrs: { value: '600' }, text: 'alle 10 min' } },
                        { option: { attrs: { value: '0' }, text: 'nur manuell' } }
                      ]
                    }
                  },
                  { button: { attrs: { class: 'primary', id: 'now' }, text: 'Jetzt abrufen' } },
                  { button: { attrs: { id: 'pause' }, text: 'Pause' } },
                  { span: { attrs: { class: 'chips', id: 'modeChips' }, text: '' } }
                ]
              }
            },
            { h2: 'Beobachtete Kanäle' },
            {
              div: {
                attrs: { class: 'bar', style: 'margin-top:0' },
                children: [
                  { input: { attrs: { id: 'addName', placeholder: '@name eines öffentlichen Kanals', style: 'flex:1;min-width:200px' } } },
                  { button: { attrs: { id: 'add' }, text: 'Beobachten' } }
                ]
              }
            },
            { div: { attrs: { id: 'live' }, text: '' } },
            { h2: 'Suchtreffer' },
            { p: { attrs: { class: 'sub', id: 'searchmeta' }, text: '' } },
            { div: { attrs: { id: 'search' }, text: '' } },
            { h2: 'Zugangsmethoden' },
            { div: { attrs: { class: 'chips', id: 'chips' }, text: '' } },
            {
              details: {
                children: [
                  { summary: 'Wie die Live-Abfrage funktioniert' },
                  { p: { attrs: { class: 'sub', style: 'margin-top:10px' }, text: 'Diese Ansicht fragt jeden beobachteten Kanal im eingestellten Turnus selbst ab. Zwei Wege, automatisch in dieser Reihenfolge:' } },
                  {
                    ol: {
                      attrs: { class: 'sub' },
                      children: [
                        { li: { children: [{ b: 'Lokales Werkzeug' }, ' (bevorzugt) — führt ', { code: 'cli.py --json live <kanal> --once' }, ' im Projektordner aus. Liefert exakte Zeitstempel, Aufrufzahlen und einen dauerhaften Verlauf auf der Festplatte.'] } },
                        { li: { children: [{ b: 'Direktabruf der Web-Vorschau' }, ' — liest ', { code: 't.me/s/<kanal>' }, ' und wertet den Text aus. Funktioniert ohne das lokale Werkzeug, kennt aber nur die Uhrzeit, nicht das Datum eines Beitrags.'] } }
                      ]
                    }
                  },
                  { p: { attrs: { class: 'sub' }, text: 'Der gesammelte Verlauf bleibt in dieser Ansicht gespeichert und wächst mit jedem Durchlauf. Neue Beiträge werden grün markiert. Für Dauerbetrieb im Hintergrund: ', code: 'python server.py --poll-interval 120', '.' } },
                  {
                    div: {
                      attrs: { class: 'bar' },
                      children: [
                        { button: { attrs: { id: 'reset' }, text: 'Verlauf in dieser Ansicht löschen' } }
                      ]
                    }
                  }
                ]
              }
            },
            {
              div: {
                attrs: { class: 'note' },
                children: [
                  { b: 'Reichweite:' },
                  ' Öffentliche Kanäle sind vollständig lesbar. Private Nutzerkonten liefern nur Name und Bio — dort bleibt der Verlauf leer, das ist eine Telegram-Einschränkung. Für nicht-öffentliche Kanäle wird Methode ',
                  { code: 'mtproto' },
                  ' benötigt, für Discord-Nachrichten ein Bot-Token.'
                ]
              }
            }
          ]
        }
      }
    }
  };

  return doc;
}

function escapeHtml(text) {
  if (text == null) return '';
  return String(text)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

function formatNumber(n) {
  if (n == null) return '?';
  return Number(n).toLocaleString('de-DE');
}

function formatDate(d) {
  if (!d) return '';
  const t = new Date(d);
  return isNaN(t) ? String(d) : t.toLocaleString('de-DE', { dateStyle: 'medium', timeStyle: 'short' });
}

function buildHtmlElement(tag, element) {
  if (typeof element === 'string') {
    return element;
  }

  if (element === undefined || element === null) {
    return '';
  }

  if (Array.isArray(element)) {
    return element.map(item => {
      if (typeof item === 'string') {
        return item;
      }
      const tagName = Object.keys(item)[0];
      return buildHtmlElement(tagName, item[tagName]);
    }).join('');
  }

  const attrs = element.attrs || {};
  const attrString = Object.entries(attrs)
    .map(([key, value]) => {
      if (value === true) {
        return key;
      } else if (value !== false && value !== null && value !== undefined) {
        return `${key}="${escapeHtml(value)}"`;
      }
      return '';
    })
    .filter(Boolean)
    .join(' ');

  const openingTag = attrString ? `<${tag} ${attrString}>` : `<${tag}>`;
  const closingTag = `</${tag}>`;

  if (element.text !== undefined) {
    return `${openingTag}${escapeHtml(element.text)}${closingTag}`;
  }

  if (element.children) {
    const content = Array.isArray(element.children) 
      ? element.children.map(child => {
          if (typeof child === 'string') {
            return child;
          }
          const childTag = Object.keys(child)[0];
          return buildHtmlElement(childTag, child[childTag]);
        }).join('')
      : element.children;
    return `${openingTag}${content}${closingTag}`;
  }

  return `${openingTag}${closingTag}`;
}

function generateHtml(doc) {
  let html = doc.doctype + '\n';
  html += buildHtmlElement('html', doc.html);
  return html;
}

function addScript(html) {
  const scriptContent = `
const BAKED = {"generated_at": "2026-07-25T14:59:25+00:00", "search": {"query": "creator", "methods_used": ["web", "discord"], "errors": [], "count": 2, "results": [{"platform": "telegram", "kind": "channel", "id": null, "username": "creator", "title": "✨creator Lounge ✨", "description": "• Aktuelle Livestream-Updates & Ankündigungen 📣\\t• Immer up to date: News & Highlights ✨\\t• Authentische Einblicke: Behind-the-Scenes nur für meine Community 🎭\\t\\thttps://linktr.ee/creator\\t\\tWillkommen im inner Circle von Luisa Amour 👑", "url": "https://t.me/creator", "members": 747, "online": null, "avatar_url": "https://cdn4.telesco.pe/file/h3VNXVClJ7Cj62wfayaWRyeOFgDu-yrttFww8TBdvFCAp-YEm8P88zgFaz16qOBH5GiQc6pIfIMWcPHpsEfwbws1wtURRXdFxGVVIC2up0VKPiOAzRkhsRfN-On9QPzcSVWbiZWFhE2gknW_nSeGD6Prrfch97qNp9Rd27Zj7smgx7xX6kttCNBWps8pDiZGgWefmKi7LQPJNCO52oKNukG6iwOxKVy2fio7KSNTGNR4RGrLRbRiPSeCL0Ey2f51QJ6IiCMeHHoH-K5QS-tv2z0xShRcPkFWHCykIvWTcxWdoiq-sRFdHkelJeTtSkvpYXbMy7JEkULkydl7FJaW7w.jpg", "public": true, "readable": true, "verified": false, "source": "telegram-web", "confidence": 0.8, "fetched_at": "2026-07-25T14:59:25+00:00", "extra": {"page_extra": "747 subscribers", "counters": {"subscribers": 747, "photos": 32, "videos": 6, "links": 22}, "preview_url": "https://t.me/s/creator"}}, {"platform": "telegram", "kind": "user", "id": null, "username": "creator", "title": "Luisa", "description": "Wir alle wollen nur etwas, das bleibt, das länger da ist, als heute 💕", "url": "https://t.me/creator", "members": null, "online": null, "avatar_url": null, "public": false, "readable": false, "verified": false, "source": "telegram-web", "confidence": 0.6, "fetched_at": "2026-07-25T14:59:25+00:00", "extra": {"page_extra": "@creator", "note": "Keine oeffentliche Verlaufs-Vorschau. Entweder privates Nutzerkonto, private Gruppe oder Kanal mit deaktivierter Vorschau."}}]}, "overview": {"entries": [{"platform": "telegram", "target": "creator", "note": "Testkanal", "channel": {"platform": "telegram", "kind": "channel", "id": null, "username": "creator", "title": "✨creator Lounge ✨", "description": "• Aktuelle Livestream-Updates & Ankündigungen 📣\\t• Immer up to date: News & Highlights ✨\\t• Authentische Einblicke: Behind-the-Scenes nur für meine Community 🎭\\t\\thttps://linktr.ee/creator\\t\\tWillkommen im inner Circle von Luisa Amour 👑", "url": "https://t.me/creator", "members": 747, "online": null, "avatar_url": "https://cdn4.telesco.pe/file/h3VNXVClJ7Cj62wfayaWRyeOFgDu-yrttFww8TBdvFCAp-YEm8P88zgFaz16qOBH5GiQc6pIfIMWcPHpsEfwbws1wtURRXdFxGVVIC2up0VKPiOAzRkhsRfN-On9QPzcSVWbiZWFhE2gknW_nSeGD6Prrfch97qNp9Rd27Zj7smgx7xX6kttCNBWps8pDiZGgWefmKi7LQPJNCO52oKNukG6iwOxKVy2fio7KSNTGNR4RGrLRbRiPSeCL0Ey2f51QJ6IiCMeHHoH-K5QS-tv2z0xShRcPkFWHCykIvWTcxWdoiq-sRFdHkelJeTtSkvpYXbMy7JEkULkydl7FJaW7w.jpg", "public": true, "readable": true, "verified": false, "source": "telegram-web", "confidence": 1.0, "fetched_at": "2026-07-25T14:59:29+00:00", "extra": {"page_extra": "747 subscribers", "counters": {"subscribers": 747, "photos": 32, "videos": 6, "links": 22}, "preview_url": "https://t.me/s/creator"}}, "posts": [{"platform": "telegram", "channel": "creator", "id": "creator/280", "url": "https://t.me/creator/280", "date": "2025-09-26T16:12:52+00:00", "author": "", "text": "https://vm.tiktok.com/ZNHWA5cEHWgjN-TVDmY", "views": 1670, "media": [], "source": "telegram-web", "extra": {}, "seen_at": "2026-07-25T14:37:52+00:00"}, {"platform": "telegram", "channel": "creator", "id": "creator/279", "url": "https://t.me/creator/279", "date": "2025-09-26T07:31:05+00:00", "author": "", "text": "Guten Morgen. ☀️ Wir sind auf WhatsApp bereits über 1k Follower. Daher machen wir diesen Channel am Sonntag zu. Alle nochmal rüber wechseln zu WhatsApp. Der Channel ist ebenfalls anonym.. keine Nummern, keine Namen, 100% kostenlos. \\n\\nRein da: 👉🏼 \\n\\nhttps://whatsapp.com/channel/0029VbB68PU8KMqeo5pYLB0H", "views": 1720, "media": [], "source": "telegram-web", "extra": {}, "seen_at": "2026-07-25T14:37:52+00:00"}, {"platform": "telegram", "channel": "creator", "id": "creator/278", "url": "https://t.me/creator/278", "date": "2025-09-25T07:42:50+00:00", "author": "", "text": "https://vm.tiktok.com/ZNHWM5ng8X1ss-QC6hZ", "views": 1390, "media": [], "source": "telegram-web", "extra": {}, "seen_at": "2026-07-25T14:37:52+00:00"}, {"platform": "telegram", "channel": "creator", "id": "creator/277", "url": "https://t.me/creator/277", "date": "2025-09-24T18:08:00+00:00", "author": "", "text": "ALLE REIN IN DEN WHATSAPP CHANNEL ODER ICH BLOCKE EUCH AUF TIKOTK 🤣 https://whatsapp.com/channel/0029VbB68PU8KMqeo5pYLB0H", "views": 1270, "media": [], "source": "telegram-web", "extra": {}, "seen_at": "2026-07-25T14:37:52+00:00"}, {"platform": "telegram", "channel": "creator", "id": "creator/276", "url": "https://t.me/creator/276", "date": "2025-09-24T14:46:29+00:00", "author": "", "text": "https://vm.tiktok.com/ZNHW2SGKbTgoH-jefyG", "views": 965, "media": [], "source": "telegram-web", "extra": {}, "seen_at": "2026-07-25T14:37:52+00:00"}, {"platform": "telegram", "channel": "creator", "id": "creator/275", "url": "https://t.me/creator/275", "date": "2025-09-24T12:45:48+00:00", "author": "", "text": "Geht alle in den WhatsApp Kanal! Der ist genau so anonym wie telegram. 🥰\\n\\nNach nem verpackten Ranglisten Start heute Nacht hatten wir echt einen mega Stream heute Mittag ihr lieben. Chillen einfach wieder in der top 20. 😎 \\n\\nWir sehen uns ca. 16:30 Uhr wieder. Erholt euch erstmal von den Chaoten 😂 \\n\\nBis gleich 🤍", "views": 868, "media": [], "source": "telegram-web", "extra": {}, "seen_at": "2026-07-25T14:37:52+00:00"}, {"platform": "telegram", "channel": "creator", "id": "creator/274", "url": "https://t.me/creator/274", "date": "2025-09-24T11:21:04+00:00", "author": "", "text": "Alle rein da in den Chanel! 😎", "views": 793, "media": [], "source": "telegram-web", "extra": {}, "seen_at": "2026-07-25T14:37:52+00:00"}, {"platform": "telegram", "channel": "creator", "id": "creator/273", "url": "https://t.me/creator/273", "date": "2025-09-24T11:13:01+00:00", "author": "", "text": "https://whatsapp.com/channel/0029VbB68PU8KMqeo5pYLB0H", "views": 824, "media": [], "source": "telegram-web", "extra": {}, "seen_at": "2026-07-25T14:37:52+00:00"}, {"platform": "telegram", "channel": "creator", "id": "creator/272", "url": "https://t.me/creator/272", "date": "2025-09-24T11:12:58+00:00", "author": "", "text": "Eyyyy hab voll viele Nachrichten bekommen, dass ihr lieber den Kanal auf WhatsApp hättet .. hab jetzt einen erstellt, wenn wir da schneller auf 1k Mitglieder sind. Gehen wir zu WhatsApp! Ansonsten bleiben wir hier", "views": 797, "media": [], "source": "telegram-web", "extra": {}, "seen_at": "2026-07-25T14:37:52+00:00"}, {"platform": "telegram", "channel": "creator", "id": "creator/271", "url": "https://t.me/creator/271", "date": "2025-09-24T08:33:10+00:00", "author": "", "text": "", "views": 792, "media": [], "source": "telegram-web", "extra": {}, "seen_at": "2026-07-25T14:37:52+00:00"}, {"platform": "telegram", "channel": "creator", "id": "creator/270", "url": "https://t.me/creator/270", "date": "2025-09-24T07:50:58+00:00", "author": "", "text": "https://vm.tiktok.com/ZNHWYdPSoVABF-1lZd3", "views": 742, "media": [], "source": "telegram-web", "extra": {}, "seen_at": "2026-07-25T14:38:45+00:00"}, {"platform": "telegram", "channel": "creator", "id": "creator/269", "url": "https://t.me/creator/269", "date": "2025-09-23T21:35:49+00:00", "author": "", "text": "https://vm.tiktok.com/ZNHWNYBQ6dGjH-fiplg", "views": 713, "media": [], "source": "telegram-web", "extra": {}, "seen_at": "2026-07-25T14:38:45+00:00"}, {"platform": "telegram", "channel": "creator", "id": "creator/268", "url": "https://t.me/creator/268", "date": "2025-09-23T20:53:02+00:00", "author": "", "text": "😎😎😎", "views": 750, "media": [{"type": "photo", "url": "https://cdn4.telesco.pe/file/sa5ZEPwOGR5ZUkhz3gjvwZS1jPsrl3epC8L_6ND1-tHRhoFW33W8Bt6dU3p2bKue6IvBYoXtNq2rSwC9lJ9Al3eorbvfb8NtwLAlLvehGqItaLpGlZZ8HmURHqOd-p6m6O5id_Sh0Ugc3M14Cof4dZrCVc_oUZT-WMwN-VyOXsuUVRhGCzodkZXJhb6U6ojcxE9-TAG8SsGfWZ6PB3EwN9WFHSsfs_Qx6Czl5ZuadrR6lF7RWySEq_dN3mKFOr0EonYs3E1m8OEGhsm2Zy5w9BFlH0pBu-wh7IcuQ_2vgv8WCPPPUUaaUSZF75XARC9ooypSiLUD2rKhGWgnZoD7xA.jpg"}], "source": "telegram-web", "extra": {}, "seen_at": "2026-07-25T14:38:45+00:00"}, {"platform": "telegram", "channel": "creator", "id": "creator/267", "url": "https://t.me/creator/267", "date": "2025-09-23T19:53:03+00:00", "author": "", "text": "Mega starker Abend Stream ihr Lieben🙏🏼 krass, wie wir als Team zusammen gehalten haben und Cesur am Ende offline geschickt haben 😎 \\nDanke an jeden einzelnen 🥰 aktuell sind wir auf top 5 und ich bin mir sicher, dass wir heute sogar in der Top 10 abschließen werden. 🥰 Weil ihr einfach krass seid.\\n\\nWir sind heute Abend gegen 23:30 Uhr wieder am Start und kämpfen uns in die neue Rangliste in einer geilen 4er konstellation 😎 \\n\\nGenießt den Abend und bis später 🤍", "views": 778, "media": [], "source": "telegram-web", "extra": {}, "seen_at": "2026-07-25T14:38:45+00:00"}, {"platform": "telegram", "channel": "creator", "id": "creator/265", "url": "https://t.me/creator/265", "date": "2025-09-23T12:19:07+00:00", "author": "", "text": "", "views": 783, "media": [], "source": "telegram-web", "extra": {}, "seen_at": "2026-07-25T14:38:45+00:00"}, {"platform": "telegram", "channel": "creator", "id": "creator/264", "url": "https://t.me/creator/264", "date": "2025-09-23T12:16:52+00:00", "author": "", "text": "Heute.. der Untergang des Dr.Markus. 🧘🏼‍♀️ die Genugtuung meines Lebens das kleine blondiere Hühnchen schlafen gelegt gu haben 😌", "views": 795, "media": [{"type": "video", "url": "https://cdn4.telesco.pe/file/179047640b.mp4?token=qY2cvk46odtiKkdZf1a6zimWXhjjsboA99_Xw1_8FJJZcLtpmSxWUiN0mEAlGRA47eJ3_tJibiAOSb_7kZdOOjhpkleIjVKXa2_Ffk-IrNve1x710_EyfiMxjyNFwf2IUbuK8ov-eDbAjPwNzR7GMR-J8nS7bWa5bfpDcTYcJHDtdIR1dYyEKcZohy_LbutEgpixrEnwazGqcuB1gsvRvIwQ_l_IxW2Y_ss-OTCg2PqI6013PDdCMCcOAzSedqzU9TzSIH
