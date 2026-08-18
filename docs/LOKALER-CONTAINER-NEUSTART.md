# `abstractions-manager` lokal neu bauen und neu starten

Die folgenden Befehle betreffen nur den Compose-Service `app` im Projekt
`abstractions-manager`. Andere Container werden weder neu gebaut noch neu gestartet.

## Voraussetzungen

- Docker Desktop laeuft.
- Git ist installiert.
- Der Branch `abstractions` ist lokal ausgecheckt.

## Einmalig klonen

```powershell
git clone --branch abstractions --single-branch https://github.com/KikiKari/Projects.git Projects-abstractions
Set-Location Projects-abstractions
```

## Vorhandene Arbeitskopie aktualisieren

Nur in einer sauberen Arbeitskopie ausfuehren:

```powershell
git switch abstractions
git pull --ff-only origin abstractions
```

## Nur diesen Container korrigiert neu erstellen

```powershell
docker compose build --no-cache app
docker compose up -d --no-deps --force-recreate app
```

`--no-deps` verhindert, dass andere Services gestartet werden. `--force-recreate`
ersetzt nur den Container `abstractions-manager`; das benannte Volume
`abstractions-manager_abstractions-state` bleibt erhalten.

## Ergebnis pruefen

```powershell
docker compose ps app
docker compose logs --tail 50 app
```

Im Log sollen unter anderem diese Meldungen erscheinen:

```text
abgleich | Start, Takt 43200s
abgleich | Stand <commit>, <anzahl> Erzeugnisse
```

Nicht mehr erscheinen duerfen:

```text
: not found
set: line 15: illegal option -
PermissionError: /home/openclaw
```

## Nur diesen Container anhalten oder erneut starten

```powershell
docker compose stop app
docker compose restart app
```

Kein `docker compose down` verwenden, wenn die anderen Ressourcen des Compose-Projekts
unveraendert bleiben sollen.
