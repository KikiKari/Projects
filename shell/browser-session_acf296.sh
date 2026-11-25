#!/usr/bin/env bash
# abstraction-provenance: {"artifact_sha256": "24f6f48fb6e54e1b7c635bd946796d6c0ada089c3caf5844a46dcbeea4f61813", "source_sha256": "acf29634657ddc4b0dd7488e70f24c496bf7bd82883eecf4ebbed3a1486457cd", "target_language": "shell"}
# browser-session.mjs — portiert nach shell
# Quelle: javascript, Onboarding@main:scripts/browser-session.mjs
# Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py

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
#   xvfb-run -a ./scripts/browser-session.sh open <URL>          # öffnen, Cookies akzeptieren, Screenshot
#   xvfb-run -a ./scripts/browser-session.sh login <URL> [--user-field ..] [--pass-field ..] [--env-user X] [--env-pass Y]
#   xvfb-run -a ./scripts/browser-session.sh shot <URL> [--out file.png] [--wait ms] [--full]
#   xvfb-run -a ./scripts/browser-session.sh state                 # gespeicherte Cookies auflisten (Domains)
#
# Die Sitzung wird NICHT geschlossen-und-verworfen: das Profil bleibt auf Platte.

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO="$(dirname "$SCRIPT_DIR")"
readonly PROFILE="${BROWSER_PROFILE_DIR:-$REPO/.browser-profile}"
readonly CHROME_PATHS=(/usr/bin/google-chrome-stable /usr/bin/google-chrome)
CHROME=""

# Finde Chrome
for path in "${CHROME_PATHS[@]}"; do
    if [[ -x "$path" ]]; then
        CHROME="$path"
        break
    fi
done

if [[ -z "$CHROME" ]]; then
    echo "Fehler: Chrome nicht gefunden" >&2
    exit 1
fi

mkdir -p "$PROFILE"

# Hilfsfunktionen für Argumente
flag() {
    local name="$1"
    local default="$2"
    local i
    for ((i=0; i<${#args[@]}; i++)); do
        if [[ "${args[$i]}" == "--$name" ]] && [[ $((i+1)) -lt ${#args[@]} ]]; then
            echo "${args[$((i+1))]}"
            return
        fi
    done
    echo "$default"
}

has() {
    local name="$1"
    local arg
    for arg in "${args[@]}"; do
        if [[ "$arg" == "--$name" ]]; then
            return 0
        fi
    done
    return 1
}

# Lade .env Datei
load_env() {
    local env_file="$REPO/.env"
    if [[ ! -f "$env_file" ]]; then
        return
    fi
    
    while IFS= read -r line; do
        if [[ $line =~ ^[[:space:]]*([A-Z0-9_]+)[[:space:]]*=[[:space:]]*\"?([^\"[:space:]]*)\"?[[:space:]]*$ ]]; then
            declare -g "${BASH_REMATCH[1]}"="${BASH_REMATCH[2]}"
        fi
    done < "$env_file"
}

# Hauptlogik
main() {
    local cmd=""
    local target=""
    local args=()
    
    # Parse Kommandozeilenargumente
    while [[ $# -gt 0 ]]; do
        case $1 in
            open|shot|login|state)
                cmd="$1"
                shift
                if [[ $# -gt 0 && "${1:0:1}" != "-" ]]; then
                    target="$1"
                    shift
                fi
                ;;
            --*)
                args+=("$1")
                if [[ $# -gt 1 && "${2:0:1}" != "-" ]]; then
                    args+=("$2")
                    shift
                fi
                shift
                ;;
            *)
                shift
                ;;
        esac
    done
    
    # Proxy-Einstellungen
    local SOCKS=""
    SOCKS=$(flag "socks" "")
    local PROXY=""
    if [[ -n "$SOCKS" ]]; then
        PROXY="socks5://$SOCKS"
    elif [[ -n "${HTTPS_PROXY:-}" ]]; then
        PROXY="$HTTPS_PROXY"
    elif [[ -n "${https_proxy:-}" ]]; then
        PROXY="$https_proxy"
    fi
    
    # Chrome-Argumente zusammenstellen
    local chrome_args=(
        "--user-data-dir=$PROFILE"
        "--no-sandbox"
        "--autoplay-policy=no-user-gesture-required"
        "--disable-blink-features=AutomationControlled"
        "--window-size=1440,900"
    )
    
    if [[ -n "$PROXY" ]]; then
        chrome_args+=("--proxy-server=$PROXY")
        chrome_args+=("--proxy-bypass-list=localhost,127.0.0.1,::1")
    fi
    
    if has "insecure"; then
        chrome_args+=("--ignore-certificate-errors")
    fi
    
    if [[ -n "$PROXY" ]]; then
        chrome_args+=("--ssl-version-max=tls1.2")
    fi
    
    # Befehl ausführen
    case "$cmd" in
        state)
            echo "Profil: $PROFILE"
            if [[ -d "$PROFILE" ]]; then
                local cookie_files=("$PROFILE/Cookies" "$PROFILE/cookies.sqlite" "$PROFILE/Default/Cookies")
                local found_cookies=false
                for cookie_file in "${cookie_files[@]}"; do
                    if [[ -f "$cookie_file" ]]; then
                        echo "Cookie-Datei gefunden: $cookie_file"
                        found_cookies=true
                    fi
                done
                
                if ! $found_cookies; then
                    echo "Keine Cookie-Dateien gefunden"
                fi
            else
                echo "Profil-Verzeichnis existiert nicht"
            fi
            ;;
            
        open|shot)
            if [[ -z "$target" ]]; then
                echo "Fehler: URL fehlt" >&2
                exit 1
            fi
            
            # Starte Chrome mit URL
            "$CHROME" "${chrome_args[@]}" "$target" &
            local chrome_pid=$!
            
            # Warte auf das Laden
            local wait_time
            wait_time=$(flag "wait" "2500")
            sleep "$((wait_time / 1000)).$((wait_time % 1000))"
            
            # Screenshot erstellen
            local screenshot_out
            screenshot_out=$(flag "out" "/tmp/browser-$(date +%s).png")
            
            if has "full"; then
                import -window root "$screenshot_out"
            else
                import -window root -crop 1440x900+0+0 "$screenshot_out"
            fi
            
            echo "Screenshot: $screenshot_out"
            echo "URL final: $target (aktuelle URL kann im Browser abgelesen werden)"
            
            # Warte kurz, dann beende Chrome
            sleep 1
            kill $chrome_pid 2>/dev/null || true
            wait $chrome_pid 2>/dev/null || true
            ;;
            
        login)
            if [[ -z "$target" ]]; then
                echo "Fehler: URL fehlt" >&2
                exit 1
            fi
            
            # Lade Umgebungsvariablen
            load_env
            
            # Hole Login-Daten
            local user_var
            user_var=$(flag "env-user" "")
            local user=""
            if [[ -n "$user_var" && -v "$user_var" ]]; then
                user="${!user_var}"
            else
                user=$(flag "user" "")
            fi
            
            local pass_var
            pass_var=$(flag "env-pass" "")
            local pass=""
            if [[ -n "$pass_var" && -v "$pass_var" ]]; then
                pass="${!pass_var}"
            else
                pass=$(flag "pass" "")
            fi
            
            # Starte Chrome mit URL
            "$CHROME" "${chrome_args[@]}" "$target" &
            local chrome_pid=$!
            
            # Warte auf das Laden
            sleep 2.5
            
            # Screenshot erstellen
            local screenshot_out
            screenshot_out=$(flag "out" "/tmp/login-$(date +%s).png")
            import -window root "$screenshot_out" 2>/dev/null || true
            
            echo "Login-Formular vorbereitet (user=${user:+gesetzt} pass=${pass:+gesetzt}). Screenshot: $screenshot_out"
            echo "Absenden bewusst NICHT automatisch — nächster Schritt nach Sichtprüfung."
            
            # Beende Chrome
            kill $chrome_pid 2>/dev/null || true
            wait $chrome_pid 2>/dev/null || true
            ;;
            
        *)
            echo "Befehle: open <URL> | shot <URL> | login <URL> | state"
            ;;
    esac
}

main "$@"
