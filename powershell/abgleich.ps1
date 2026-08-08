#!/usr/bin/env pwsh
# abgleich.sh — portiert nach powershell
# Quelle: shell, Projects@abstractions:abstractions/abgleich.sh
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# Haelt den Abstraktions-Bestand im Container aktuell.
#
# Alle zwoelf Stunden wird der oeffentliche Branch Projects@abstractions nach
# /home/openclaw/.openclaw/workspace/git/Abstraktionen geholt. Das Repository
# ist oeffentlich, es wird kein Token gebraucht — der Container liest nur.
#
# Erzeugt wird hier nichts: das Portieren laeuft in GitHub Actions, weil dort
# der Schluessel liegt und der Lauf auch dann stattfindet, wenn dieser Rechner
# aus ist. Ein Lauf von Hand ist trotzdem moeglich:
#
#   docker exec -e OPENROUTER_API_KEY=... abstractions-manager `
#       python abstractions/ABSTRACTIONS_MANAGER.py --anzahl 5

$ErrorActionPreference = "Stop"

$WURZEL = if ($env:ABSTRACTIONS_WORKSPACE) { $env:ABSTRACTIONS_WORKSPACE } else { "/home/openclaw/.openclaw/workspace" }
$ZIEL = "$WURZEL/git/Abstraktionen"
$HERKUNFT = "https://github.com/KikiKari/Projects.git"
$BRANCH = "abstractions"
$TAKT = if ($env:ABGLEICH_TAKT) { [int]$env:ABGLEICH_TAKT } else { 43200 }  # zwoelf Stunden

function melde($message) {
    $timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss")
    Write-Host "$timestamp | abgleich | $message"
}

function abgleichen() {
    if (-not (Test-Path "$ZIEL/.git")) {
        melde "Erstabgleich nach $ZIEL"
        New-Item -ItemType Directory -Path $ZIEL -Force | Out-Null
        git init -q $ZIEL
        git -C $ZIEL remote add herkunft $HERKUNFT
    }
    if (git -C $ZIEL fetch -q --depth 1 herkunft $BRANCH 2>$null) {
        git -C $ZIEL checkout -q -f -B $BRANCH FETCH_HEAD
        $stand = git -C $ZIEL rev-parse --short HEAD
        $anzahl = (Get-ChildItem -Path $ZIEL -Recurse -File -Include *.js,*.pl,*.ps1,*.py,*.sh,*.tcl -Exclude .git).Count
        melde "Stand $stand, $anzahl Erzeugnisse"
    } else {
        melde "Abgleich fehlgeschlagen — vorheriger Stand bleibt bestehen"
    }
}

melde "Start, Takt ${TAKT}s"
while ($true) {
    abgleichen
    Start-Sleep -Seconds $TAKT
}
