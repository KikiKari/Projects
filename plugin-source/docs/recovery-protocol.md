# Hook-Reconnect: Prüfkandidat, 7. Oktober 2026

Hook-Reconnect ist tablokal, standardmäßig aus (3 Sekunden). Bestehende
quickRecover-Werte bleiben Player-Recovery zugeordnet. Die Hook-Zustandsmaschine
hat ausschließlich Zugriff auf extensioneigene WebSockets, keine Player- oder
Navigationsfunktionen. Das Intervall bezeichnet den Versuchsbeginn, nicht eine
zugesicherte vollständige Wiederverbindung.

## Protokollgrenze

Verbindungsargumente werden nur von regulär angelegten nativen WebSockets
übernommen und ausschließlich im Dokument-Arbeitsspeicher gehalten. Unterstützt
werden wss-Endpunkte unter tiktok.com und tiktokv.com. Vor einem eigenen Versuch
müssen qualifizierte Live-Daten, ein passendes natives ACK und zwei native
Heartbeat-Nachrichten beobachtet worden sein. Der Abstand der Heartbeats wird
übernommen. Ohne diese Beobachtungen lautet der Status protocol-unverified;
es werden keine Verbindungsparameter erraten und keine Anwendungsframes wiederholt.

Der unterstützte Protobuf-Transport verwendet Feld 2 (ID), 7 (Typ) und 8
(optionaler ACK-Inhalt). ACKs werden nur bei needAck gesendet. Dieser Dialekt ist
mit synthetischen Fixtures geprüft, nicht mit einem aktuellen Live-Lauf bestätigt.
Andere Dialekte bleiben nicht unterstützt. Die Zehn-Sekunden-Frist endet erst
beim ersten qualifizierten dekodierten Empfang, nicht bei socket-open. Nur ein
Versuch gleichzeitig; Fehler-Backoff maximal 30 Sekunden. Native Übernahme,
Deaktivierung und Streamwechsel machen frühere Generationen ungültig.

## Diagnose

Schema tiktok-live-companion-diagnostic-v3 enthält bereinigte hookRecovery-Daten.
Socket-Ereignisse tragen Dokument-/Socket-ID, Eigentümer und Hook-Versuchs-ID.
Nicht beobachtete Empfangs-/Abschlussmesspunkte sind null. Der allgemeine Export
enthält keine Captiontexte oder WebSocket-Verbindungsargumente. Captiontexte
gehören ausschließlich zu ausdrücklich gewählten Captionexporten.

## Nutzerabnahme am 7. Oktober 2026

Der Nutzer hat die Live-Abnahme ausdrücklich als erfolgreich bestätigt und
0PE-167 bis 0PE-173 zum Abschluss freigegeben. Der ergänzende Diagnoseexport
enthält native Verbindungen und protocol-unverified, keine eigenen Socketversuche;
der Captionzähler beträgt null. Diese Nachweisgrenzen bleiben dokumentiert.
Version 0.8.1 konsolidiert die freigegebene Browserimplementierung und die
Komponentenversionen. Einzelheiten und Beleg-Hashes stehen im Releasebericht
unter docs/releases/0.8.1.md im GitHub-Repository. Roh-HAR und Debugpayload
werden nicht veröffentlicht.
