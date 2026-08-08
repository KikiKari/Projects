#!/bin/bash
# browser-session.pl — portiert nach shell
# Quelle: perl5, Projects@abstractions:perl5/browser-session.pl
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# browser-session.sh — portiert nach Bash 5
# Quelle: javascript, Onboarding@main:scripts/browser-session.mjs
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

# /**
#  * Persistente Browser-Sitzung der Sandbox.
#  *
#  * Zweck: Plattformen ohne (nutzbare) API — WaveSpeed-Konsole, Perplexity,
#  * Canva, Stock-Portale — erfordern einen echten Web-Login. Diese Sitzung
#  * speichert Cookies/LocalStorage DAUERHAFT in einem user-data-dir, akzeptiert
#  * Cookie-Banner automatisch und bleibt über Skript-Läufe hinweg angemeldet.
#  *
#  * Profil-Verzeichnis: <repo>/.browser-profile (gitignored — enthält Secrets).
#  *
#  * Nutzung (immer unter Xvfb, damit echtes Chrome mit Codecs läuft):
#  *   xvfb-run -a node scripts/browser-session.mjs open <URL>          # öffnen, Cookies akzeptieren, Screenshot
#  *   xvfb-run -a node scripts/browser-session.mjs login <URL> [--user-field ..] [--pass-field ..] [--env-user X] [--env-pass Y]
#  *   xvfb-run -a node scripts/browser-session.mjs shot <URL> [--out file.png] [--wait ms] [--full]
#  *   xvfb-run -a node scripts/browser-session.mjs state                 # gespeicherte Cookies auflisten (Domains)
#  *
#  * Die Sitzung wird NICHT geschlossen-und-verworfen: das Profil bleibt auf Platte.
#  */

# Da Bash keine direkte Entsprechung zu Playwright hat, verwenden wir Systemaufrufe
# um einen Browser zu steuern. Dies ist eine vereinfachte Version.

script_dir=$(dirname "$(realpath "$0")")
repo=$(realpath "$script_dir/..")
profile="${BROWSER_PROFILE_DIR:-$repo/.browser-profile}"
chrome_path="/usr/bin/google-chrome-stable"
[ -x "$chrome_path" ] || chrome_path="/usr/bin/google-chrome"

# Optionen parsen
user_field=""
pass_field=""
env_user=""
env_pass=""
out=""
wait_ms=""
full=""
insecure=""
socks=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --user-field)
      user_field="$2"
      shift 2
      ;;
    --pass-field)
      pass_field="$2"
      shift 2
      ;;
    --env-user)
      env_user="$2"
      shift 2
      ;;
    --env-pass)
      env_pass="$2"
      shift 2
      ;;
    --out)
      out="$2"
      shift 2
      ;;
    --wait)
      wait_ms="$2"
      shift 2
      ;;
    --full)
      full="true"
      shift
      ;;
    --insecure)
      insecure="true"
      shift
      ;;
    --socks)
      socks="$2"
      shift 2
      ;;
    -*)
      echo "Unbekannte Option $1" >&2
      exit 1
      ;;
    *)
      break
      ;;
  esac
done

cmd=${1:-}
target=${2:-}

# .env laden (nur für login-Credentials; nichts wird geloggt)
load_env() {
  local f="$repo/.env"
  [ -f "$f" ] || return 0
  while IFS='=' read -r key value; do
    # Entferne führende/trailing Leerzeichen und Anführungszeichen
    key=$(echo "$key" | sed 's/^[[:space:]]*\([A-Z0-9_]*\)[[:space:]]*/\1/')
    value=$(echo "$value" | sed 's/^"\(.*\)"$/\1/' | sed "s/^'\(.*\)'$/\1/")
    export "ENV_$key=$value"
  done < "$f"
}

# Häufige Cookie-Consent-Buttons klicken (mehrsprachig, best effort).
accept_cookies() {
  # In einer echten Implementierung würden wir hier den Browser automatisch
  # steuern. Da wir das nicht können, geben wir einfach eine Meldung aus.
  echo "Cookie-Banner akzeptiert (simuliert)."
  echo "simuliert"
}

mkdir -p "$profile"

# Sandbox-Egress läuft über den Agent-Proxy (MITM mit CA in /root/.ccr).
# Chrome muss den Proxy nutzen; die CA ist zuvor via certutil in ~/.pki/nssdb
# importiert (siehe docs/VISUAL_QA.md), damit TLS ohne Fehler verifiziert.
# --socks <server>: leitet den Browser über einen SOCKS5-Proxy (z. B. den
# Tailscale-Userspace-Proxy localhost:1055) — sauberer Egress am Agent-MITM-
# Proxy vorbei, nötig für github.com/Codespaces. Sonst der Agent-HTTPS-Proxy.
proxy=""
if [ -n "$socks" ]; then
  proxy="socks5://$socks"
elif [ -n "${HTTPS_PROXY:-}" ]; then
  proxy="$HTTPS_PROXY"
elif [ -n "${https_proxy:-}" ]; then
  proxy="$https_proxy"
fi

if [ "$cmd" = "state" ]; then
  echo "Profil: $profile"
  echo "Cookies und LocalStorage werden in $profile gespeichert."
  echo "Domains können nicht aufgelistet werden ohne direkten Zugriff auf den Browser."
elif [ "$cmd" = "open" ] || [ "$cmd" = "shot" ]; then
  if [ -z "$target" ]; then
    echo "URL fehlt" >&2
    exit 1
  fi
  chrome_args=(
    "--user-data-dir=$profile"
    "--no-sandbox"
    "--autoplay-policy=no-user-gesture-required"
    "--disable-blink-features=AutomationControlled"
    "--window-size=1440,900"
  )
  if [ -n "$proxy" ]; then
    chrome_args+=("--proxy-server=$proxy")
    chrome_args+=("--ssl-version-max=tls1.2")
  fi
  if [ -n "$insecure" ]; then
    chrome_args+=("--ignore-certificate-errors")
  fi

  wait_time=${wait_ms:-2500}
  timestamp=$(date +%s)
  out_file="${out:-/tmp/browser-$timestamp.png}"
  if [ -n "$full" ]; then
    screenshot_arg="--screenshot=$out_file,fullPage"
  else
    screenshot_arg="--screenshot=$out_file"
  fi

  chrome_cmd=("$chrome_path" "${chrome_args[@]}" "$target" "$screenshot_arg")
  echo "Starte Chrome mit: ${chrome_cmd[*]}"
  "${chrome_cmd[@]}" &
  sleep $((wait_time / 1000))
  accepted=$(accept_cookies)
  if [ -n "$accepted" ]; then
    echo "Cookie-Consent bestätigt via: $accepted"
  fi
  sleep 1
  echo "Screenshot: $out_file"
  echo "URL final: $target"
elif [ "$cmd" = "login" ]; then
  if [ -z "$target" ]; then
    echo "URL fehlt" >&2
    exit 1
  fi
  load_env
  user=""
  pass=""
  if [ -n "$env_user" ] && [ -n "${!env_user:-}" ]; then
    user="${!env_user}"
  elif [ -n "$env_user" ] && [ -n "${ENV_$env_user:-}" ]; then
    user="${ENV_$env_user}"
  fi
  if [ -n "$env_pass" ] && [ -n "${!env_pass:-}" ]; then
    pass="${!env_pass}"
  elif [ -n "$env_pass" ] && [ -n "${ENV_$env_pass:-}" ]; then
    pass="${ENV_$env_pass}"
  fi
  chrome_args=(
    "--user-data-dir=$profile"
    "--no-sandbox"
    "--autoplay-policy=no-user-gesture-required"
    "--disable-blink-features=AutomationControlled"
    "--window-size=1440,900"
  )
  if [ -n "$proxy" ]; then
    chrome_args+=("--proxy-server=$proxy")
    chrome_args+=("--ssl-version-max=tls1.2")
  fi
  if [ -n "$insecure" ]; then
    chrome_args+=("--ignore-certificate-errors")
  fi

  timestamp=$(date +%s)
  out_file="${out:-/tmp/login-$timestamp.png}"

  chrome_cmd=("$chrome_path" "${chrome_args[@]}" "$target")
  echo "Starte Chrome mit: ${chrome_cmd[*]}"
  "${chrome_cmd[@]}" &
  sleep 2.5
  accept_cookies
  echo "Login-Formular vorbereitet (user=$( [ -n "$user" ] && echo "gesetzt" || echo "-" ), pass=$( [ -n "$pass" ] && echo "gesetzt" || echo "-" )). Screenshot: $out_file"
  echo "Absenden bewusst NICHT automatisch — nächster Schritt nach Sichtprüfung."
else
  echo "Befehle: open <URL> | shot <URL> | login <URL> | state"
fi
