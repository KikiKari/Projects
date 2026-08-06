# TikTok-Live-Companion — Embed-Viewer

Schreibgeschützte Ansicht für öffentliche TikTok-Livestreams, gebaut auf dem
**offiziellen Embed-Player** (`tiktok.com/embed/live/@name`, dokumentiert unter
developers.tiktok.com/doc/embed-live).

Warum dieser Weg statt eines Eingriffs ins normale Frontend:

- **Keine Anmeldung nötig** — der Embed ist für fremde Seiten gedacht.
- **Keine Geschenk- und Kauf-Oberfläche** — genau die Aktionen, die später Geld
  kosten und für Kinder oder aufsichtspflichtige Personen problematisch sind,
  existieren im Embed gar nicht.
- **Keine Umgehung von Zugangskontrollen** — nichts, was bei einer
  Store-Prüfung oder einer Änderung an TikToks Frontend zusammenbricht.

---

## Dateien

| Datei | Zweck |
|---|---|
| `tiktok-companion.js` | Logik: Live/Offline-Erkennung, Statusabruf, Benachrichtigung. Ohne DOM-Abhängigkeit, in Node testbar |
| `tiktok-embed-viewer.html` | Fertige Oberfläche: Player, Status, letzte Sendungen |

Sofort ausprobieren — Datei im Browser öffnen:

```
tiktok-embed-viewer.html?user=creator&api=http://127.0.0.1:8765
```

Ohne laufenden Monitor den `api`-Parameter weglassen; die Komponente liest den
Status dann direkt von der öffentlichen Profilseite.

---

## Einbau in die Erweiterung

### 1. Dateien übernehmen

`tiktok-companion.js` und `tiktok-embed-viewer.html` ins Erweiterungsverzeichnis
kopieren.

### 2. Manifest ergänzen (Manifest V3)

```jsonc
{
  "manifest_version": 3,
  "name": "TikTok Live Companion",
  "version": "1.0",
  "permissions": ["notifications", "storage", "alarms"],
  "host_permissions": [
    "https://streamrecorder.io/*",     // nur nötig ohne lokalen Monitor
    "http://127.0.0.1:8765/*"          // nur nötig mit lokalem Monitor
  ],
  "action": { "default_popup": "tiktok-embed-viewer.html" },
  "background": { "service_worker": "background.js" },
  "content_security_policy": {
    "extension_pages": "script-src 'self'; frame-src https://www.tiktok.com;"
  }
}
```

`frame-src https://www.tiktok.com` ist der entscheidende Eintrag — ohne ihn
blockiert die Erweiterung ihren eigenen Player-Rahmen.

### 3. Hintergrunddienst für Benachrichtigungen

```js
// background.js
importScripts('tiktok-companion.js');

const ACCOUNTS = ['creator'];
const ttc = new TikTokCompanion({
  apiBase: 'http://127.0.0.1:8765',       // leer lassen für den Direktabruf
  notifyOnLive: true,
  onGoLive: st => chrome.notifications.create({
    type: 'basic', iconUrl: 'icon128.png',
    title: '@' + st.username + ' ist live',
    message: st.title || 'Die Sendung läuft.'
  })
});

chrome.runtime.onInstalled.addListener(() =>
  chrome.alarms.create('tt-check', { periodInMinutes: 2 }));

chrome.alarms.onAlarm.addListener(async alarm => {
  if (alarm.name !== 'tt-check') return;
  for (const user of ACCOUNTS) { ttc.user = user; await ttc.refresh(); }
});
```

Kürzer als zwei Minuten ist weder nötig noch höflich — der Statusabruf trifft
eine fremde Seite.

---

## Schnittstelle

```js
const ttc = new TikTokCompanion({
  apiBase: 'http://127.0.0.1:8765',   // optional
  onState: st => { /* bei jedem Abruf */ },
  onGoLive: st => { /* nur beim Wechsel offline -> live */ },
  onError: msg => { /* leerer String = Fehler behoben */ },
  notifyOnLive: false
});

ttc.watch('creator', 120);   // Intervall in Sekunden, 0 = einmalig
ttc.stop();
await ttc.refresh();            // manuell

TikTokCompanion.embedUrl('creator');
TikTokCompanion.parsePublicPage(html, 'creator');   // reiner Parser, testbar
```

### Statusobjekt

```jsonc
{
  "platform": "tiktok",
  "username": "creator",
  "live": true,                       // true | false | null (nicht ermittelbar)
  "title": "Super Mario auf die 1",
  "started_at": "2026-07-25T12:13:00",
  "since": "6h 12m",                  // nur wenn live, ca.-Angabe
  "last_seen": "Jul 25, 2026",
  "streams_total": 81,
  "airtime": "198h 55m",
  "active_days": 42,
  "embed_url": "https://www.tiktok.com/embed/live/@creator",
  "live_url":  "https://www.tiktok.com/@creator/live",
  "profile_url": "https://www.tiktok.com/@creator",
  "streams": [ { "day": "2026-07-25", "time": "12:13", "title": "...",
                 "duration": "3h 2m", "is_live": true } ]
}
```

---

## Woher der Status kommt

1. **Lokaler Monitor** (bevorzugt): `GET /api/tiktok/status?users=<name>` aus dem
   Projekt nebenan. Vorteil: ein Abruf für beliebig viele Nutzer der Erweiterung,
   Verlauf liegt auf der Platte, Benachrichtigung läuft auch ohne offenen Browser.
2. **Direktabruf** der öffentlichen Profilseite eines Aufzeichnungsdienstes. Die
   Seite trägt ihre Daten als JSON (`window.ALT_DAILY_DATA`) aus: Sendungen je Tag
   mit Titel, Uhrzeit, Dauer und `is_live`-Kennzeichen.

Beide Parser — Python im Monitor, JavaScript hier — wurden gegen dieselbe echte
Seite geprüft und liefern identische Werte.

---

## Grenzen, offen gesagt

- **Kein Live-Chat.** Der offizielle Embed liefert ihn nicht. Wer ihn braucht,
  geht über TikToks Entwicklerprogramm — nicht über einen Umweg am Frontend vorbei.
- **`since` ist eine Näherung.** Die Zeitzone der Quelle ist nicht ausgewiesen;
  die Angabe stimmt auf die Stunde, nicht auf die Minute.
- **Der Statusdienst ist Dritt-Infrastruktur.** Fällt er aus, steht `live: null`
  statt einer falschen Aussage. Für Dauerbetrieb ist der lokale Monitor die
  robustere Variante.
- **Verzögerung.** Der Livegang wird beim nächsten Abruf erkannt, nicht in
  Echtzeit — bei 2 Minuten Intervall also innerhalb von 2 Minuten.
