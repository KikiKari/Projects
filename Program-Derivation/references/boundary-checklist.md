# Grenzschichten-Checkliste / Boundary Checklist

## Externe REST-APIs
- [ ] URL hardgecoded oder konfigurierbar?
- [ ] Authentifizierungstoken in Env-Variable oder Request-Body?
- [ ] Retry-Logik vorhanden (exponential backoff)?
- [ ] Timeout gesetzt (AbortSignal / axios timeout)?
- [ ] Fehlerformat strukturiert (kein raw HTTP-Status-Code an UI)?
- [ ] Rate-Limit-Handling (429)?

## Datenbanken
- [ ] Interface/Repository-Pattern vorhanden?
- [ ] Datenbanktypen lecken nicht in Interface-Signaturen?
- [ ] Nur eine Verbindung pro Datenbankdatei?
- [ ] DDL-Fehler werden behandelt?
- [ ] Migrations-Strategie vorhanden?

## Browser-APIs / Native APIs
- [ ] Feature-Detection vor Nutzung (`if ('vibrate' in navigator)`)?
- [ ] Plattform-spezifische Fallbacks (iOS `webkitCompassHeading` vs. Android)?
- [ ] Berechtigungsabfragen erklärt und im richtigen Kontext?
- [ ] Graceful degradation wenn API nicht verfügbar?

## Dateisystem
- [ ] Pfade konfigurierbar, nicht hardgecoded?
- [ ] Fehlerbehandlung bei fehlendem Verzeichnis?
- [ ] Keine relativen Pfade in Produktionscode?

## Umgebungsvariablen
- [ ] Fehlende Pflicht-Variablen erzeugen Startup-Fehler (nicht stille Fallbacks)?
- [ ] Validierung beim Start (zod / joi / envalid)?
