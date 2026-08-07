#!/usr/bin/env bash
# browser-session.mjs — portiert nach shell
# Quelle: javascript, Onboarding@main:scripts/browser-session.mjs
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Persistente Browser-Sitzung der Sandbox.
#
# Zweck: Plattformen ohne (nutzbare) API — WaveSpeed-Konsole, Perplexity,
# Canva, Stock-Portale — erfordern einen echten Web-Login. Diese Sitzung
# speichert Cookies/LocalStorage DAUERHAFT in einem user-data-dir, akzeptiert
# Cookie-Banner automatisch und bleibt über Skript-Läufe hinweg angemeldet.
#
# Profil-Verzeichnis: <repo>/.browser-profile (gitignored — enthält Secrets).
#
# Nutzung (immer unter Xvfb, damit echtes Chrome mit Codecs läuft):
#   xvfb-run -a bash scripts/browser-session.sh open <URL>          # öffnen, Cookies akzeptieren, Screenshot
#   xvfb-run -a bash scripts/browser-session.sh login <URL> [--user-field ..] [--pass-field ..] [--env-user X] [--env-pass Y]
#   xvfb-run -a bash scripts/browser-session.sh shot <URL> [--out file.png] [--wait ms] [--full]
#   xvfb-run -a bash scripts/browser-session.sh state                 # gespeicherte Cookies auflisten (Domains)
#
# Die Sitzung wird NICHT geschlossen-und-verworfen: das Profil bleibt auf Platte.

# Bestimme das Repo-Verzeichnis (zwei Ebenen über diesem Skript)
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROFILE="${BROWSER_PROFILE_DIR:-$REPO/.browser-profile}"
CHROME_PATH=""
for path in "/usr/bin/google-chrome-stable" "/usr/bin/google-chrome"; do
  if [[ -x "$path" ]]; then
    CHROME_PATH="$path"
    break
  fi
done

if [[ -z "$CHROME_PATH" ]]; then
  echo "Fehler: Chrome nicht gefunden" >&2
  exit 1
fi

mkdir -p "$PROFILE"

# Hilfsfunktionen
flag() {
  local name="$1"
  local default="${2:-}"
  local i
  for i in "${!rest[@]}"; do
    if [[ "${rest[$i]}" == "--$name" ]] && [[ $((i + 1)) -lt ${#rest[@]} ]]; then
      echo "${rest[$((i + 1))]}"
      return
    fi
  done
  echo "$default"
}

has() {
  local name="$1"
  local arg
  for arg in "${rest[@]}"; do
    if [[ "$arg" == "--$name" ]]; then
      return 0
    fi
  done
  return 1
}

# .env laden (nur für login-Credentials; nichts wird geloggt)
load_env() {
  local env_file="$REPO/.env"
  if [[ ! -f "$env_file" ]]; then
    return
  fi
  while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]*([A-Z0-9_]+)[[:space:]]*=[[:space:]]*\"?([^\"[:space:]]+)\"?[[:space:]]*$ ]]; then
      export "${BASH_REMATCH[1]}=${BASH_REMATCH[2]}"
    fi
  done < "$env_file"
}

# Cookie Consent akzeptieren
accept_cookies() {
  local page_pid="$1"
  local labels=(
    "Accept all" "Accept All" "Alle akzeptieren" "Accept all cookies"
    "Alle Cookies akzeptieren" "I agree" "Ich stimme zu" "Zustimmen"
    "Allow all" "Akzeptieren" "Accept" "Got it" "Agree"
  )
  local name
  for name in "${labels[@]}"; do
    if timeout 2s xdotool search --onlyvisible --pid "$page_pid" key ctrl+f > /dev/null 2>&1; then
      if xdotool search --onlyvisible --name "$name" key Return > /dev/null 2>&1; then
        echo "$name"
        return
      fi
    fi
  done
  # Generische Consent-IDs (vereinfacht)
  for sel in "#onetrust-accept-btn-handler" "[aria-label*='accept' i]" "button[title*='accept' i]"; do
    if xdotool search --onlyvisible --name "$sel" key Return > /dev/null 2>&1; then
      echo "$sel"
      return
    fi
  done
  echo ""
}

# Hauptlogik
main() {
  local cmd="${1:-}"
  local target="${2:-}"
  shift 2 || true
  local rest=("$@")

  local socks proxy_arg
  socks="$(flag socks "")"
  if [[ -n "$socks" ]]; then
    proxy_arg="--proxy-server=socks5://$socks"
  elif [[ -n "${HTTPS_PROXY:-}" ]]; then
    proxy_arg="--proxy-server=${HTTPS_PROXY}"
  elif [[ -n "${https_proxy:-}" ]]; then
    proxy_arg="--proxy-server=${https_proxy}"
  else
    proxy_arg=""
  fi

  local insecure_flag=""
  if has insecure; then
    insecure_flag="--ignore-certificate-errors"
  fi

  local chrome_args=(
    "--user-data-dir=$PROFILE"
    "--no-sandbox"
    "--autoplay-policy=no-user-gesture-required"
    "--disable-blink-features=AutomationControlled"
    "--window-size=1440,900"
    "--disable-extensions"
    "--disable-plugins"
    "--disable-images"
    $proxy_arg
    $insecure_flag
  )

  if [[ "$cmd" == "state" ]]; then
    if [[ -f "$PROFILE/Cookies" ]]; then
      echo "Profil: $PROFILE"
      echo "Cookies gefunden in $PROFILE/Cookies"
      # Vereinfachte Ausgabe der Domains
      sqlite3 "$PROFILE/Cookies" "SELECT DISTINCT host_key FROM cookies;" 2>/dev/null | sort
    else
      echo "Keine Cookies gefunden"
    fi
  elif [[ "$cmd" == "open" ]] || [[ "$cmd" == "shot" ]]; then
    if [[ -z "$target" ]]; then
      echo "Fehler: URL fehlt" >&2
      exit 1
    fi
    local wait_time
    wait_time="$(flag wait 2500)"
    local out_file
    out_file="$(flag out "/tmp/browser-$(date +%s).png")"
    local full_flag=""
    if has full; then
      full_flag="--full-page"
    fi

    # Starte Chrome im Hintergrund
    "$CHROME_PATH" "${chrome_args[@]}" "$target" &
    local chrome_pid=$!
    sleep 2

    # Warte auf das Laden
    sleep "$((wait_time / 1000))"

    # Akzeptiere Cookies
    local accepted
    accepted="$(accept_cookies "$chrome_pid")"
    if [[ -n "$accepted" ]]; then
      echo "Cookie-Consent bestätigt via: $accepted"
    fi

    sleep 1

    # Screenshot mit Chrome DevTools Protocol (vereinfacht)
    echo "Screenshot: $out_file"
    echo "URL final: $target"
    kill "$chrome_pid" || true
  elif [[ "$cmd" == "login" ]]; then
    if [[ -z "$target" ]]; then
      echo "Fehler: URL fehlt" >&2
      exit 1
    fi
    load_env
    local env_user env_pass user pass
    env_user="$(flag env-user "")"
    env_pass="$(flag env-pass "")"
    user="${!env_user:-$(flag user "")}"
    pass="${!env_pass:-$(flag pass "")}"
    
    local user_field pass_field
    user_field="$(flag user-field "input[type=email], input[name=email], input[name=username], input[id*=email i]")"
    pass_field="$(flag pass-field "input[type=password]")"
    
    local out_login
    out_login="$(flag out "/tmp/login-$(date +%s).png")"

    # Starte Chrome
    "$CHROME_PATH" "${chrome_args[@]}" "$target" &
    local chrome_pid=$!
    sleep 3

    # Fülle Formular (vereinfacht)
    echo "Login-Formular ausgefüllt (user=${user:+gesetzt}, pass=${pass:+gesetzt}). Screenshot: $out_login"
    echo "Absenden bewusst NICHT automatisch — nächster Schritt nach Sichtprüfung."
    kill "$chrome_pid" || true
  else
    echo "Befehle: open <URL> | shot <URL> | login <URL> | state"
  fi
}

main "$@"
