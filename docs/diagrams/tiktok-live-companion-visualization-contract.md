# Visualisierungsvertrag – TikTok LIVE Companion 0.7.0

## Zweck und Evidenz

- **Zweck:** Browser-, iOS- und Android-/HyperOS-Laufzeitpfade sowie die getrennten Songerkennungswege in einer gemeinsamen Architekturansicht erklären.
- **Quelle:** Versionierte Projektquellen unter `plugin-source/`, `mobile/` und `site/api/`.
- **Wahrheitsinvarianten:** Browser verwendet AudD; iOS und Android/HyperOS verwenden ShazamKit; Audio startet nur nach Nutzeraktion; Android erhält ein kurzlebiges ES256-Token; WebView-Bridges akzeptieren nur den erlaubten TikTok-Hauptframe.
- **Schematische Ebene:** Position und Höhe der Boxen sind erklärend, keine gemessenen Größen oder Laufzeiten.

## Renderer-Verantwortung

- **Primär:** eine projektspezifische Three.js-Szene mit Orbit, Zoom, Auswahl und Reset. Tiefe codiert die drei Plattformpfade und trägt damit fachliche Bedeutung.
- **Fallback:** deterministisch erzeugtes SVG; das erzeugte GIF zeigt die räumliche Struktur ohne Interaktion.
- **HTML:** Titel, Legende, Status, Auswahltext und Bedienelemente.
- **WebGL:** Boxen, Plattformebenen und gerichtete Verbindungen.
- **Keine Doppelansicht:** SVG wird ausgeblendet, sobald die WebGL-Szene ihr erstes gültiges Frame meldet; bei Context Loss erscheint es wieder.
- **Export:** `assets/gen_tiktok_live_companion_flow.py` erzeugt SVG; `assets/gen_tiktok_live_companion_flow_gif.py` erzeugt GIF.

## Koordinaten

| Ebene | Koordinatensystem | Bedeutung |
|---|---|---|
| Browser | Welt-Y negativ | Manifest-V3-Erweiterung, lokaler Dienst und AudD |
| iOS | Welt-Y null | WKWebView, SwiftUI und ShazamKit-Capability |
| Android/HyperOS | Welt-Y positiv | AndroidX WebKit, Compose, Token-Dienst und ShazamKit-AAR |
| X-Achse | links nach rechts | Quelle → Bridge/Laufzeit → Ausgabe/Katalog |
| Z-Achse | Boxhöhe | visuelle Gruppierung, keine Messgröße |

## Kodierungsledger

| Zustand | Darstellung | Darf nicht bedeuten |
|---|---|---|
| passive öffentliche Beobachtung | Cyan, durchgezogen | Eingriff in TikTok oder Request-Blocking |
| nutzergestartetes Audio | Korallrot, durchgezogen | automatische Dauerüberwachung |
| Android-Developer-Token | Amber, gestrichelt | Übertragung des privaten Schlüssels an die App |
| Browserpfad | Cyanfarbene Plattformfläche | Cloud-Verarbeitung aller Browserdaten |
| iOS-Pfad | rosafarbene Plattformfläche | Verfügbarkeit ohne Apple-Capability |
| Android-/HyperOS-Pfad | grüne Plattformfläche | Google-Play-Services-Abhängigkeit |

## Interaktion und Barrierefreiheit

- Maus/Touch: Orbit, Zwei-Finger-Zoom und Auswahl; ein Finger bleibt auf Mobilgeräten dem Seitenscrollen vorbehalten, bis die Szene fokussiert ist.
- Tastatur: Pfeiltasten drehen, `+`/`-` zoomen, `R` oder Escape setzt zurück.
- Große Schaltflächen: Reset, Zoom und Schritt vor/zurück mindestens 44 CSS-Pixel.
- Kein essentielles Detail nur per Hover; Auswahltext und Legende bleiben als HTML sichtbar.
- `prefers-reduced-motion` deaktiviert automatische Kamerabewegung; GIF ist ergänzend und nicht der einzige Informationsweg.
- Mobile Portrait startet mit fokussierter Übersicht und statischem SVG; die interaktive Szene kann bewusst geöffnet werden. Mobile Landscape zeigt die vollständige Szene.

## Laufzeit- und QA-Vertrag

- genau eine WebGL-Szene;
- DPR auf Mobilgeräten höchstens 1,5;
- Renderloop pausiert bei unsichtbarem Tab;
- kein Remote-Datensatz, keine Telemetrie und keine Berechtigungsabfrage;
- Context-Loss zeigt den SVG-Fallback;
- Desktop-, Mobile-Portrait-, Reduced-Motion- und statischer Fallback-Screenshot;
- Generatoren müssen aus demselben `flow_model.py` identische Node-IDs und Kantenrollen lesen.
