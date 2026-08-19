#!/bin/bash
# sync-local.ps1 — portiert nach shell
# Quelle: powershell, Onboarding@main:scripts/sync-local.ps1
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Standardparameter
BRANCH="${1:-claude/onboarding-persistent-sandbox-vjfmcx}"
INTERVAL_SECONDS="${2:-20}"
COMPOSE_FILE="${3:-docker-compose.dev.yml}"
ONCE="${4:-false}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

# Logging-Funktion
log() {
  echo "[$(date +%H:%M:%S)] $1"
}

# Wrapper für docker compose
invoke_compose() {
  docker compose -f "$COMPOSE_FILE" "$@" || log "WARNUNG: docker compose $* fehlgeschlagen (Exit $?)"
}

# Sicherstellen, dass der Ziel-Branch ausgecheckt ist
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$CURRENT_BRANCH" != "$BRANCH" ]]; then
  log "Wechsle von '$CURRENT_BRANCH' auf '$BRANCH' …"
  git fetch origin "$BRANCH"
  if ! git switch "$BRANCH" 2>/dev/null; then
    git switch -c "$BRANCH" --track "origin/$BRANCH" || {
      log "Fehler beim Checkout von Branch '$BRANCH'"
      exit 1
    }
  fi
fi

log "Sync aktiv: origin/$BRANCH -> $REPO_ROOT (Intervall ${INTERVAL_SECONDS}s, Compose: $COMPOSE_FILE)"

while true; do
  if ! git fetch origin "$BRANCH" --quiet; then
    log "Fetch fehlgeschlagen (Netzwerk?) — nächster Versuch in ${INTERVAL_SECONDS}s"
  else
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse "origin/$BRANCH")

    if [[ "$LOCAL" != "$REMOTE" ]]; then
      if ! git merge-base --is-ancestor "$LOCAL" "$REMOTE"; then
        log "ACHTUNG: Lokaler Stand ist von origin/$BRANCH abgewichen (lokale Commits?). Kein automatischer Merge — bitte manuell auflösen."
      else
        CHANGED_FILES=$(git diff --name-only "$LOCAL".."$REMOTE")
        git merge --ff-only "$REMOTE" --quiet
        CHANGED_COUNT=$(echo "$CHANGED_FILES" | wc -l | tr -d ' ')
        log "Aktualisiert ${LOCAL:0:7} -> ${REMOTE:0:7} ($CHANGED_COUNT Datei(en))"

        COMPOSE_CHANGED=false
        BACKEND_IMAGE_CHANGED=false
        FRONTEND_DEPS_CHANGED=false

        while IFS= read -r file; do
          case "$file" in
            "$COMPOSE_FILE")
              COMPOSE_CHANGED=true
              ;;
            package.json|package-lock.json)
              FRONTEND_DEPS_CHANGED=true
              ;;
            backend/Dockerfile|backend/requirements*.txt)
              BACKEND_IMAGE_CHANGED=true
              ;;
          esac
        done <<< "$CHANGED_FILES"

        if [[ "$COMPOSE_CHANGED" == true ]]; then
          log "Compose-Datei geändert — erzeuge Dev-Stack neu …"
          invoke_compose up -d
        fi

        if [[ "$BACKEND_IMAGE_CHANGED" == true ]]; then
          log "Backend-Dependencies/Dockerfile geändert — baue nur das Backend neu …"
          invoke_compose up -d --build backend
        fi

        if [[ "$FRONTEND_DEPS_CHANGED" == true ]]; then
          log "Frontend-Dependencies geändert — starte Frontend neu (npm install läuft im Container) …"
          invoke_compose restart frontend
        fi

        if [[ "$COMPOSE_CHANGED" == false && "$BACKEND_IMAGE_CHANGED" == false && "$FRONTEND_DEPS_CHANGED" == false ]]; then
          log "Nur Quellcode/Assets — Hot-Reload übernimmt, kein Build nötig."
        fi
      fi
    fi
  fi

  if [[ "$ONCE" == true ]]; then
    break
  fi
  sleep "$INTERVAL_SECONDS"
done
