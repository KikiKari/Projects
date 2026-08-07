#!/bin/sh
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
#   docker exec -e OPENROUTER_API_KEY=... abstractions-manager \
#       python abstractions/ABSTRACTIONS_MANAGER.py --anzahl 5

set -eu

WURZEL="${ABSTRACTIONS_WORKSPACE:-/home/openclaw/.openclaw/workspace}"
ZIEL="$WURZEL/git/Abstraktionen"
HERKUNFT="https://github.com/KikiKari/Projects.git"
BRANCH="abstractions"
TAKT="${ABGLEICH_TAKT:-43200}"   # zwoelf Stunden

melde() { echo "$(date -u '+%Y-%m-%d %H:%M:%S') | abgleich | $*"; }

abgleichen() {
    if [ ! -d "$ZIEL/.git" ]; then
        melde "Erstabgleich nach $ZIEL"
        mkdir -p "$ZIEL"
        git init -q "$ZIEL"
        git -C "$ZIEL" remote add herkunft "$HERKUNFT"
    fi
    if git -C "$ZIEL" fetch -q --depth 1 herkunft "$BRANCH" 2>/dev/null; then
        git -C "$ZIEL" checkout -q -f -B "$BRANCH" FETCH_HEAD
        stand=$(git -C "$ZIEL" rev-parse --short HEAD)
        anzahl=$(find "$ZIEL" -type f \
            \( -name '*.js' -o -name '*.pl' -o -name '*.ps1' \
               -o -name '*.py' -o -name '*.sh' -o -name '*.tcl' \) \
            -not -path '*/.git/*' | wc -l)
        melde "Stand $stand, $anzahl Erzeugnisse"
    else
        melde "Abgleich fehlgeschlagen — vorheriger Stand bleibt bestehen"
    fi
}

melde "Start, Takt ${TAKT}s"
while true; do
    abgleichen
    sleep "$TAKT"
done
