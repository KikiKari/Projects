# Erweiterung laden — 4 Schritte

Dieser Ordner ist eine **vollständige, ladefertige** Chrome-/Edge-Erweiterung
(Manifest V3). Nichts muss gebaut oder installiert werden.

1. Im Browser `chrome://extensions` öffnen (Edge: `edge://extensions`)
2. Oben rechts **Entwicklermodus** einschalten
3. **Entpackte Erweiterung laden** klicken
4. **genau diesen Ordner** auswählen:

```
C:\Users\silve\Documents\Claude\Telegram-Monitor\plugin\extension
```

Wichtig: den Ordner `extension` auswählen, nicht `plugin` und nicht eine
einzelne Datei. Chrome erkennt eine Erweiterung nur an der `manifest.json`,
die genau dort liegt.

Danach erscheint das Symbol in der Werkzeugleiste (ggf. über das Puzzle-Symbol
anheften). Klick darauf → Konto eintragen, z. B. `creator` → **Anzeigen**.

---

## Was drin ist

| Datei | Zweck |
|---|---|
| `manifest.json` | Berechtigungen, CSP mit `frame-src https://www.tiktok.com` |
| `popup.html` / `popup.js` | Oberfläche: Player, Status, letzte Sendungen |
| `background.js` | Prüft im Turnus, meldet den Livegang, setzt „LIVE" ans Symbol |
| `tiktok-companion.js` | gemeinsame Logik für Popup und Hintergrund |
| `icons/` | Symbole in drei Größen |

## Warum es als Erweiterung funktioniert und als lose Datei nicht

Eine Seite, die als `file://` geöffnet wird, hat die Herkunft „null". Der Browser
verbietet ihr jeden Abruf fremder Server — deshalb kam dort „Failed to fetch".
Die Erweiterung läuft unter `chrome-extension://` und hat über
`host_permissions` ausdrücklich Zugriff auf die Statusquelle. Deshalb braucht
sie **keinen laufenden Monitor**.

Läuft der Monitor trotzdem (`python server.py` im Projektordner), nutzt die
Erweiterung ihn bevorzugt: ein Abruf statt vieler, Verlauf auf der Platte.

## Berechtigungen — und warum

| Berechtigung | wofür |
|---|---|
| `notifications` | Meldung beim Livegang |
| `storage` | gemerktes Konto und Intervall |
| `alarms` | Turnus-Prüfung ohne offenen Tab |
| `host_permissions: streamrecorder.io` | öffentliche Statusdaten lesen |
| `host_permissions: 127.0.0.1:8765` | optionaler lokaler Monitor |

Kein Zugriff auf `tiktok.com` selbst — die Erweiterung liest dort nichts und
verändert dort nichts. Der Stream läuft im offiziellen Embed-Rahmen, der
**keine Anmeldung und keine Geschenk- oder Kauf-Oberfläche** hat.

## Wenn etwas klemmt

- **„Manifest-Datei fehlt oder ist nicht lesbar"** — falscher Ordner gewählt.
  Es muss der Ordner sein, in dem `manifest.json` direkt liegt.
- **Popup bleibt leer** — auf `chrome://extensions` bei der Erweiterung auf
  **Fehler** bzw. **Service Worker** klicken; dort steht die Ursache.
- **Kein Player** — „Player" drücken; das lädt den Rahmen ohne Statusabfrage.
- **Keine Meldung beim Livegang** — Windows-Benachrichtigungen für den Browser
  in den Systemeinstellungen erlauben; Chrome liefert sonst still aus.
