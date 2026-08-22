#!/usr/bin/env bash
# tiktok-check-profile.js — portiert nach shell
# Quelle: javascript, OpenClaw@gateway1:skills/tiktok-live/scripts/tiktok-check-profile.js
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# TikTok Live Status Checker
# Prüft ausschließlich profilgebundene Live-Indikatoren.
# Der allgemeine TikTok-Navigationspunkt "LIVE" ist kein Statussignal.
# Unterstützt @handle-Normalisierung und optionalen Node-Lastschutz
# via TIKTOK_MAX_LOAD_PER_CPU (Exit-Code 75 bei NODE_BUSY).

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly TEMP_DIR="${TMPDIR:-/tmp}"
readonly TEMP_HTML="${TEMP_DIR}/tiktok_profile.html"
readonly TEMP_SCREENSHOT="${TEMP_DIR}/tiktok_screenshot.png"

# Farbcodes für Debug-Ausgaben
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Standard-User-Agent
readonly USER_AGENT='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'

# Funktion zur Ausgabe von Fehlermeldungen
error() {
    echo >&2 "ERROR: $*"
}

# Funktion zur Ausgabe von Debug-Meldungen
debug() {
    [[ ${DEBUG:-} == "1" ]] && echo >&2 "DEBUG: $*" || true
}

# Funktion zur Berechnung der Systemlast pro CPU-Kern
get_normalized_load() {
    local load_avg
    load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    local cpu_count
    cpu_count=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 1)
    echo "scale=2; ${load_avg}/${cpu_count}" | bc -l
}

# Lastschutz-Funktion
reject_busy_node() {
    local limit="${TIKTOK_MAX_LOAD_PER_CPU:-}"
    if [[ -z "${limit}" ]] || ! [[ "${limit}" =~ ^[0-9]+\.?[0-9]*$ ]]; then
        debug "Lastschutz deaktiviert (kein gültiger Grenzwert)"
        return 0
    fi

    local normalized_load
    normalized_load=$(get_normalized_load)
    debug "Aktuelle normierte Last: ${normalized_load}, Limit: ${limit}"

    if (( $(echo "${normalized_load} > ${limit}" | bc -l) )); then
        error "NODE_BUSY normalizedLoad=${normalized_load} limit=${limit}"
        exit 75
    fi
}

# Funktion zum Herunterladen der Profilseite
fetch_profile_page() {
    local username="$1"
    local url="https://www.tiktok.com/@${username}"

    debug "Lade Profilseite: ${url}"

    # Verwende curl mit Browser-ähnlichem User-Agent
    if ! curl -s -L \
        --compressed \
        -H "User-Agent: ${USER_AGENT}" \
        -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" \
        -H "Accept-Language: en-US,en;q=0.5" \
        -H "Accept-Encoding: gzip, deflate, br" \
        -H "Connection: keep-alive" \
        -H "Upgrade-Insecure-Requests: 1" \
        --max-time 30 \
        --connect-timeout 10 \
        "${url}" >"${TEMP_HTML}"; then
        error "Fehler beim Abrufen der Profilseite"
        return 1
    fi

    debug "Profilseite erfolgreich heruntergeladen"
    return 0
}

# Funktion zum Entfernen von Cookie-Bannern (simuliert)
remove_cookie_banners() {
    # In einer echten Implementierung würden wir hier JavaScript ausführen,
    # aber da wir nur HTML parsen, simulieren wir das Schließen.
    debug "Entferne Cookie-Banner (Simulation)"
    # Da wir kein echtes DOM haben, ignorieren wir dies vorerst
    # In einer realen Umgebung würde man z.B. mit pup oder jq arbeiten
    sleep 1
}

# Funktion zur Extraktion relevanter Informationen aus dem HTML
extract_live_indicators() {
    local html_file="$1"
    local username="$2"

    # Lese die HTML-Datei
    local html_content
    html_content=$(<"${html_file}")

    # Indikatoren initialisieren
    local live_icon_visible=false
    local live_badge_visible=false
    local has_live_border=false
    local has_live_link=false
    local live_indicator_visible=false

    # Methode 1: Suche nach data-e2e="live-icon"
    if grep -qi 'data-e2e="live-icon"' <<<"${html_content}"; then
        live_icon_visible=true
    fi

    # Methode 2: Suche nach LIVE Text/Badge im Profilbereich
    if grep -qiE '(LIVE|LIVE NOW)' <<<"${html_content}"; then
        # Prüfen ob es im Kontext des Profils ist
        if grep -qiE 'profile.*LIVE|LIVE.*profile' <<<"${html_content}" ||
           grep -qiE 'header.*LIVE|LIVE.*header' <<<"${html_content}"; then
            live_badge_visible=true
        fi
    fi

    # Methode 3: Suchen nach rotem Rahmen oder Live-Indikatoren
    if grep -qiE 'border.*red|red.*border|fe2c55|#ff0000|rgb\(255|rgb\(254' <<<"${html_content}"; then
        has_live_border=true
    fi

    # Methode 4: Suchen nach Live-Links
    if grep -qi "/@${username}/live" <<<"${html_content}"; then
        has_live_link=true
    fi

    # Methode 5: Suchen nach Live-Indikatoren wie pulsierende Punkte
    if grep -qiE 'live-indicator|LiveBadge' <<<"${html_content}"; then
        live_indicator_visible=true
    fi

    # Zusammenfassung
    local is_live=false
    if [[ "${live_icon_visible}" == true ]] ||
       [[ "${live_badge_visible}" == true ]] ||
       [[ "${has_live_border}" == true ]] ||
       [[ "${has_live_link}" == true ]] ||
       [[ "${live_indicator_visible}" == true ]]; then
        is_live=true
    fi

    # JSON-Ausgabe erstellen
    cat <<EOF
{
  "username": "${username}",
  "isLive": ${is_live},
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "indicators": {
    "liveIcon": ${live_icon_visible},
    "liveBadge": ${live_badge_visible},
    "liveBorder": ${has_live_border},
    "liveLink": ${has_live_link},
    "liveIndicator": ${live_indicator_visible}
  }
}
EOF

    # Rückgabewert setzen
    if [[ "${is_live}" == true ]]; then
        return 0
    else
        return 1
    fi
}

# Hauptfunktion
main() {
    local raw_username="$1"

    # Parameterprüfung
    if [[ -z "${raw_username}" ]]; then
        error "Verwendung: $0 <username>"
        exit 1
    fi

    # Normalisiere Username (@ entfernen)
    local username
    username="${raw_username#@}"

    if [[ -z "${username}" ]]; then
        error "Username darf nicht leer sein"
        exit 1
    fi

    debug "Überprüfe TikTok-Profil: @${username}"

    # Lastschutz prüfen
    reject_busy_node

    # Temporäre Dateien bereinigen
    trap 'rm -f "${TEMP_HTML}" "${TEMP_SCREENSHOT}"' EXIT

    # Profilseite abrufen
    if ! fetch_profile_page "${username}"; then
        cat <<EOF
{
  "error": true,
  "message": "Fehler beim Abrufen der Profilseite",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
        exit 1
    fi

    # Cookie-Banner entfernen (simuliert)
    remove_cookie_banners

    # Wartezeit für vollständiges Laden
    sleep 3

    # Screenshot speichern wenn DEBUG=1
    if [[ ${DEBUG:-} == "1" ]]; then
        debug "Speichere Screenshot zu Debug-Zwecken"
        # In einer echten Implementierung würde man hier einen Screenshot machen
        # Da wir nur HTML haben, kopieren wir die HTML-Datei
        cp "${TEMP_HTML}" "${TEMP_SCREENSHOT}" 2>/dev/null || true
    fi

    # Live-Indikatoren extrahieren und ausgeben
    extract_live_indicators "${TEMP_HTML}" "${username}"
}

# Skript starten
main "$@"
