# `abstractions-manager` lokal neu bauen und neu starten

Die folgenden Befehle betreffen nur den Compose-Service `app` im Projekt
`abstractions-manager`. Andere Container werden weder neu gebaut noch neu gestartet.

## Voraussetzungen

- Docker Desktop laeuft.
- Git ist installiert.
- Internetzugang zu GitHub ist vorhanden.

## Kompletter kopierbarer PowerShell-Block

Der Block kann direkt in einer neu geoeffneten PowerShell ausgefuehrt werden. Das
aktuelle PowerShell-Verzeichnis ist dabei egal. Das Repository wird fest unter
`%USERPROFILE%\Projects-abstractions` verwendet und bei Bedarf zuerst geklont.

```powershell
$AbstractionsDir = Join-Path $env:USERPROFILE 'Projects-abstractions'
$ComposeFile = Join-Path $AbstractionsDir 'compose.yaml'

if (-not (Test-Path -LiteralPath $AbstractionsDir)) {
    git clone --branch abstractions --single-branch `
        https://github.com/KikiKari/Projects.git $AbstractionsDir
    if ($LASTEXITCODE -ne 0) { throw 'Klonen des Repositorys fehlgeschlagen' }
}

if (-not (Test-Path -LiteralPath (Join-Path $AbstractionsDir '.git'))) {
    throw "Kein Git-Repository unter $AbstractionsDir"
}

git -C $AbstractionsDir switch abstractions
if ($LASTEXITCODE -ne 0) { throw 'Wechsel auf Branch abstractions fehlgeschlagen' }
git -C $AbstractionsDir pull --ff-only origin abstractions
if ($LASTEXITCODE -ne 0) { throw 'Aktualisierung des Branches fehlgeschlagen' }

docker compose --project-directory $AbstractionsDir -f $ComposeFile `
    build --no-cache app
if ($LASTEXITCODE -ne 0) { throw 'Docker-Build fehlgeschlagen' }
docker compose --project-directory $AbstractionsDir -f $ComposeFile `
    up -d --no-deps --force-recreate app
if ($LASTEXITCODE -ne 0) { throw 'Container-Neustart fehlgeschlagen' }

docker compose --project-directory $AbstractionsDir -f $ComposeFile ps app
docker compose --project-directory $AbstractionsDir -f $ComposeFile `
    logs --tail 50 app
```

`--no-deps` verhindert, dass andere Services gestartet werden. `--force-recreate`
ersetzt nur den Container `abstractions-manager`; das benannte Volume
`abstractions-manager_abstractions-state` bleibt erhalten.

## Ergebnis pruefen

Die Status- und Log-Befehle sind bereits am Ende des kopierbaren Blocks enthalten.

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
$AbstractionsDir = Join-Path $env:USERPROFILE 'Projects-abstractions'
$ComposeFile = Join-Path $AbstractionsDir 'compose.yaml'

docker compose --project-directory $AbstractionsDir -f $ComposeFile stop app
docker compose --project-directory $AbstractionsDir -f $ComposeFile restart app
```

Kein `docker compose down` verwenden, wenn die anderen Ressourcen des Compose-Projekts
unveraendert bleiben sollen.
