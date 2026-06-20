#!/usr/bin/env bash
# abstractions-publish-gateway.sh
#
# Pusht den Stand von workspace/git/Abstraktionen/ auf den
# gateway{1,2}-abstractions-Branch.
#
# Exit-Codes:
#   0 = Erfolg (gepusht ODER nichts zu tun)
#   1 = Unerwarteter Branch
#   2 = Secret im Diff gefunden
#   3 = Git-Operation fehlgeschlagen
#   4 = Repo-Pfad nicht erreichbar oder kein Git-Repo

set -u

ABSTRACTIONS_REPO="/home/openclaw/.openclaw/workspace/git/Abstraktionen"
LOG_DIR="/home/openclaw/.openclaw/logs/abstractions-publish-gateway"
mkdir -p "$LOG_DIR" 2>/dev/null
LOG_FILE="$LOG_DIR/$(date +%Y-%m-%d).log"

log() {
  local msg="$1"
  local ts
  ts=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$ts] $msg" | tee -a "$LOG_FILE"
}

# --- Schritt 1: Repo erreichbar? ---
if ! cd "$ABSTRACTIONS_REPO" 2>/dev/null; then
  log "STATUS=error CODE=4 REASON=repo-unreachable PATH=$ABSTRACTIONS_REPO"
  exit 4
fi

if [[ ! -d ".git" ]]; then
  log "STATUS=error CODE=4 REASON=not-a-git-repo PATH=$ABSTRACTIONS_REPO"
  exit 4
fi

# --- Schritt 2: Branch ermitteln ---
BRANCH=$(git branch --show-current 2>/dev/null)
if [[ "$BRANCH" != "gateway1-abstractions" && "$BRANCH" != "gateway2-abstractions" ]]; then
  log "STATUS=error CODE=1 REASON=unexpected-branch BRANCH=$BRANCH"
  exit 1
fi
log "STATUS=info STEP=branch-detected BRANCH=$BRANCH"

# --- Schritt 3: Hat sich was geändert? ---
STATUS_OUTPUT=$(git status --porcelain)
if [[ -z "$STATUS_OUTPUT" ]]; then
  log "STATUS=skip REASON=no-changes BRANCH=$BRANCH"
  exit 0
fi

CHANGED_COUNT=$(echo "$STATUS_OUTPUT" | wc -l)
log "STATUS=info STEP=changes-detected COUNT=$CHANGED_COUNT BRANCH=$BRANCH"

# --- Schritt 4: Secret-Scan auf geänderte Dateien ---
SECRET_PATTERNS='sk-[A-Za-z0-9]{20,}|ghp_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,}|ntn_[A-Za-z0-9]{30,}|secret_[A-Za-z0-9]{30,}|tvly-[A-Za-z0-9-]{20,}|nvapi-[A-Za-z0-9]{30,}|tskey-[A-Za-z0-9-]{20,}|xoxb-[A-Za-z0-9-]{20,}|xapp-[A-Za-z0-9-]{20,}|AIza[A-Za-z0-9_-]{30,}'

SECRET_HITS=""
while IFS= read -r line; do
  file_path="${line:3}"
  if [[ -f "$file_path" ]]; then
    if grep -E -l "$SECRET_PATTERNS" "$file_path" 2>/dev/null > /dev/null; then
      matched_pattern=$(grep -E -o "$SECRET_PATTERNS" "$file_path" 2>/dev/null | head -1 | cut -c1-10)
      SECRET_HITS="$SECRET_HITS $file_path[$matched_pattern...]"
    fi
  fi
done <<< "$STATUS_OUTPUT"

if [[ -n "$SECRET_HITS" ]]; then
  log "STATUS=error CODE=2 REASON=secrets-found HITS=$SECRET_HITS"
  exit 2
fi
log "STATUS=info STEP=secret-scan-clean"

# --- Schritt 5: Stage + Commit ---
if ! git add -A 2>&1 | tee -a "$LOG_FILE"; then
  log "STATUS=error CODE=3 REASON=git-add-failed"
  exit 3
fi

COMMIT_MSG="auto: abstractions-sync $(date '+%Y-%m-%d %H:%M')"
if ! git commit -m "$COMMIT_MSG" 2>&1 | tee -a "$LOG_FILE"; then
  if git status --porcelain | grep -q .; then
    log "STATUS=error CODE=3 REASON=git-commit-failed"
    exit 3
  else
    log "STATUS=skip REASON=nothing-staged-after-add"
    exit 0
  fi
fi

COMMIT_HASH=$(git log -1 --format=%h)
log "STATUS=info STEP=commit-created HASH=$COMMIT_HASH MSG=\"$COMMIT_MSG\""

# --- Schritt 6: Push ---
if ! git push 2>&1 | tee -a "$LOG_FILE"; then
  log "STATUS=error CODE=3 REASON=git-push-failed BRANCH=$BRANCH HASH=$COMMIT_HASH"
  exit 3
fi

# --- Erfolg ---
log "STATUS=ok BRANCH=$BRANCH COUNT=$CHANGED_COUNT HASH=$COMMIT_HASH"
echo ""
echo "=== SUMMARY ==="
echo "Branch:  $BRANCH"
echo "Files:   $CHANGED_COUNT"
echo "Commit:  $COMMIT_HASH"
echo "Status:  OK - gepusht nach origin/$BRANCH"
exit 0
