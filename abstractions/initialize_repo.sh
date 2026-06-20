#!/usr/bin/env bash
# =============================================================================
# initialize_repo.sh — Initialisiert das Git-Repository für Script-Abstraktionen.
#
# Erstellt die komplette Verzeichnisstruktur, initialisiert das Git-Repository
# und legt ein initiales README und .gitignore an.
#
# Usage:
#   ./initialize_repo.sh [OPTIONS]
#
# Options:
#   -w, --workspace PATH   Workspace-Basispfad
#                          (Standard: /home/openclaw/.openclaw/workspace)
#   -b, --branch NAME      Name des initialen Git-Branches (Standard: main)
#   -n, --dry-run          Zeigt Aktionen nur an ohne sie auszuführen
#   -h, --help             Zeigt diese Hilfe an
#
# Exit Codes:
#   0   Erfolg
#   1   Allgemeiner Fehler
#   2   Pflichtprogramm fehlt (git)
#   3   Verzeichnis-Erstellung fehlgeschlagen
#   4   Git-Initialisierung fehlgeschlagen
#
# Beispiele:
#   ./initialize_repo.sh
#   ./initialize_repo.sh --workspace /custom/path
#   ./initialize_repo.sh --dry-run
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Konstanten
# ---------------------------------------------------------------------------

readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SCRIPT_VERSION="1.0.0"

readonly DEFAULT_WORKSPACE_BASE="/home/openclaw/.openclaw/workspace"
readonly ABSTRACTION_REPO_SUBDIR="git/script-abstractions"
readonly DEFAULT_BRANCH_NAME="main"

readonly TARGET_SUBDIRECTORIES=(
    "original"
    "python"
    "perl5"
    "perl6"
    "javascript"
    "tcl"
    "bash"
    "powershell"
    "ruby"
    "lua"
    "go"
)

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------

# Farb-Codes (werden deaktiviert wenn kein Terminal)
if [[ -t 1 ]]; then
    COLOR_RESET='\033[0m'
    COLOR_GREEN='\033[0;32m'
    COLOR_YELLOW='\033[1;33m'
    COLOR_RED='\033[0;31m'
    COLOR_BLUE='\033[0;34m'
else
    COLOR_RESET='' COLOR_GREEN='' COLOR_YELLOW='' COLOR_RED='' COLOR_BLUE=''
fi

#######################################
# Gibt eine strukturierte Info-Meldung aus.
# Arguments:
#   $@ — Meldungstext
# Outputs:
#   Schreibt nach stderr
#######################################
log_info() {
    echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET}  $(date '+%Y-%m-%d %H:%M:%S') $*" >&2
}

#######################################
# Gibt eine Erfolgs-Meldung aus.
# Arguments:
#   $@ — Meldungstext
# Outputs:
#   Schreibt nach stderr
#######################################
log_success() {
    echo -e "${COLOR_GREEN}[OK]${COLOR_RESET}    $(date '+%Y-%m-%d %H:%M:%S') $*" >&2
}

#######################################
# Gibt eine Warn-Meldung aus.
# Arguments:
#   $@ — Meldungstext
# Outputs:
#   Schreibt nach stderr
#######################################
log_warn() {
    echo -e "${COLOR_YELLOW}[WARN]${COLOR_RESET}  $(date '+%Y-%m-%d %H:%M:%S') $*" >&2
}

#######################################
# Gibt eine Fehler-Meldung aus und beendet das Script.
# Arguments:
#   $1 — Exit-Code
#   $@ — Fehlermeldung
# Outputs:
#   Schreibt nach stderr
#######################################
log_error_and_exit() {
    local exit_code="$1"
    shift
    echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $(date '+%Y-%m-%d %H:%M:%S') $*" >&2
    exit "${exit_code}"
}

# ---------------------------------------------------------------------------
# Hilfsfunktionen
# ---------------------------------------------------------------------------

#######################################
# Gibt die Hilfe aus.
# Outputs:
#   Schreibt nach stdout
#######################################
print_usage() {
    cat <<EOF
${SCRIPT_NAME} v${SCRIPT_VERSION} — Git-Repository-Initialisierung

Usage: ${SCRIPT_NAME} [OPTIONS]

Options:
  -w, --workspace PATH   Workspace-Basispfad
                         (Standard: ${DEFAULT_WORKSPACE_BASE})
  -b, --branch NAME      Name des initialen Git-Branches (Standard: ${DEFAULT_BRANCH_NAME})
  -n, --dry-run          Zeigt Aktionen nur an ohne sie auszuführen
  -h, --help             Zeigt diese Hilfe an

Exit Codes:
  0   Erfolg
  1   Allgemeiner Fehler
  2   git nicht gefunden
  3   Verzeichnis-Erstellung fehlgeschlagen
  4   Git-Initialisierung fehlgeschlagen

Beispiele:
  ${SCRIPT_NAME}
  ${SCRIPT_NAME} --workspace /custom/workspace
  ${SCRIPT_NAME} --dry-run
EOF
}

#######################################
# Führt einen Befehl aus oder zeigt ihn nur an (dry-run).
# Globals:
#   IS_DRY_RUN
# Arguments:
#   $@ — Auszuführender Befehl mit Argumenten
# Returns:
#   Exit-Code des Befehls (oder 0 bei dry-run)
#######################################
run_command() {
    if [[ "${IS_DRY_RUN}" == "true" ]]; then
        log_info "[dry-run] würde ausführen: $*"
        return 0
    fi
    "$@"
}

#######################################
# Prüft ob ein Programm im PATH verfügbar ist.
# Arguments:
#   $1 — Programmname
# Returns:
#   0 wenn gefunden, 1 sonst
#######################################
is_program_available() {
    command -v "$1" &>/dev/null
}

# ---------------------------------------------------------------------------
# Argument-Parsing
# ---------------------------------------------------------------------------

#######################################
# Parsed CLI-Argumente und setzt globale Variablen.
# Arguments:
#   $@ — CLI-Argumente
# Globals (set):
#   WORKSPACE_BASE_PATH, INITIAL_BRANCH_NAME, IS_DRY_RUN
#######################################
parse_arguments() {
    WORKSPACE_BASE_PATH="${DEFAULT_WORKSPACE_BASE}"
    INITIAL_BRANCH_NAME="${DEFAULT_BRANCH_NAME}"
    IS_DRY_RUN="false"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -w|--workspace)
                [[ -z "${2:-}" ]] && log_error_and_exit 1 "--workspace erfordert einen Pfad."
                WORKSPACE_BASE_PATH="$2"
                shift 2
                ;;
            -b|--branch)
                [[ -z "${2:-}" ]] && log_error_and_exit 1 "--branch erfordert einen Namen."
                INITIAL_BRANCH_NAME="$2"
                shift 2
                ;;
            -n|--dry-run)
                IS_DRY_RUN="true"
                shift
                ;;
            -h|--help)
                print_usage
                exit 0
                ;;
            *)
                log_error_and_exit 1 "Unbekanntes Argument: '$1'. Nutze --help."
                ;;
        esac
    done
}

# ---------------------------------------------------------------------------
# Kern-Logik
# ---------------------------------------------------------------------------

#######################################
# Prüft alle Voraussetzungen.
# Globals:
#   IS_DRY_RUN
# Returns:
#   Beendet Script mit Exit-Code 2 wenn Voraussetzungen fehlen
#######################################
check_prerequisites() {
    log_info "Prüfe Voraussetzungen..."

    if ! is_program_available "git"; then
        log_error_and_exit 2 "git ist nicht installiert oder nicht im PATH."
    fi

    local git_version
    git_version="$(git --version)"
    log_info "Git gefunden: ${git_version}"
}

#######################################
# Erstellt die Verzeichnisstruktur.
# Arguments:
#   $1 — Basis-Pfad des Repositories
# Returns:
#   Beendet Script mit Exit-Code 3 bei Fehler
#######################################
create_directory_structure() {
    local repo_base_path="$1"

    log_info "Erstelle Verzeichnisstruktur unter: ${repo_base_path}"

    if ! run_command mkdir -p "${repo_base_path}"; then
        log_error_and_exit 3 "Konnte Basis-Verzeichnis nicht erstellen: ${repo_base_path}"
    fi

    for subdirectory in "${TARGET_SUBDIRECTORIES[@]}"; do
        local full_subdir_path="${repo_base_path}/${subdirectory}"
        if ! run_command mkdir -p "${full_subdir_path}"; then
            log_error_and_exit 3 "Konnte Unterverzeichnis nicht erstellen: ${full_subdir_path}"
        fi
        # .gitkeep damit leere Verzeichnisse in Git getrackt werden
        if [[ "${IS_DRY_RUN}" != "true" ]]; then
            touch "${full_subdir_path}/.gitkeep"
        fi
        log_success "Verzeichnis erstellt: ${subdirectory}/"
    done
}

#######################################
# Initialisiert das Git-Repository.
# Arguments:
#   $1 — Repository-Pfad
#   $2 — Initialer Branch-Name
#######################################
initialize_git_repository() {
    local repo_path="$1"
    local branch_name="$2"

    if [[ -d "${repo_path}/.git" ]]; then
        log_warn "Git-Repository existiert bereits — überspringe Initialisierung."
        return 0
    fi

    log_info "Initialisiere Git-Repository (Branch: ${branch_name})..."

    if ! run_command git -C "${repo_path}" init --initial-branch="${branch_name}"; then
        log_error_and_exit 4 "Git-Initialisierung fehlgeschlagen in: ${repo_path}"
    fi

    log_success "Git-Repository initialisiert."
}

#######################################
# Erstellt .gitignore und README.md.
# Arguments:
#   $1 — Repository-Pfad
#######################################
create_initial_files() {
    local repo_path="$1"

    # .gitignore
    if [[ ! -f "${repo_path}/.gitignore" ]]; then
        log_info "Erstelle .gitignore..."
        if [[ "${IS_DRY_RUN}" != "true" ]]; then
            cat > "${repo_path}/.gitignore" <<'GITIGNORE'
# Temporäre Dateien
*.tmp
*.dryrun
*.log

# Python
__pycache__/
*.pyc
.venv/

# Node.js
node_modules/

# Betriebssystem
.DS_Store
Thumbs.db
GITIGNORE
        fi
        log_success ".gitignore erstellt."
    fi

    # README.md
    if [[ ! -f "${repo_path}/README.md" ]]; then
        log_info "Erstelle README.md..."
        if [[ "${IS_DRY_RUN}" != "true" ]]; then
            cat > "${repo_path}/README.md" <<'READMEEOF'
# Script Abstractions

Portierungen von OpenClaw-Scripts in alternative Programmiersprachen.

## Struktur

| Verzeichnis  | Inhalt                          |
|--------------|---------------------------------|
| `original/`  | Original-Scripts als Referenz   |
| `python/`    | Python-Portierungen             |
| `perl5/`     | Perl 5 Portierungen             |
| `perl6/`     | Raku Portierungen               |
| `javascript/`| Node.js Portierungen            |
| `bash/`      | Bash Portierungen               |
| `powershell/`| PowerShell Portierungen         |
| `tcl/`       | Tcl Portierungen                |
| `ruby/`      | Ruby Portierungen               |
| `lua/`       | Lua Portierungen                |
| `go/`        | Go Portierungen                 |

## Verwendung

Neue Portierung erstellen:
```bash
python3 create_abstraction.py --source /path/to/script.py --target-lang perl5
```

Sub-Agent für komplexe Portierung:
```bash
python3 spawn_agent.py --task "Port script.py to Go" --model claude-3-5-sonnet
```
READMEEOF
        fi
        log_success "README.md erstellt."
    fi
}

#######################################
# Erstellt den initialen Git-Commit.
# Arguments:
#   $1 — Repository-Pfad
#######################################
create_initial_git_commit() {
    local repo_path="$1"

    if [[ "${IS_DRY_RUN}" == "true" ]]; then
        log_info "[dry-run] würde initialen Commit erstellen."
        return 0
    fi

    # Prüfen ob schon Commits existieren
    if git -C "${repo_path}" rev-parse HEAD &>/dev/null 2>&1; then
        log_warn "Repository hat bereits Commits — überspringe initialen Commit."
        return 0
    fi

    git -C "${repo_path}" add --all
    git -C "${repo_path}" commit -m "Initial repository structure" \
        --author="Abstractions Manager <abstractions@openclaw.local>"

    log_success "Initialer Commit erstellt."
}

# ---------------------------------------------------------------------------
# Hauptfunktion
# ---------------------------------------------------------------------------

#######################################
# Hauptfunktion — orchestriert alle Schritte.
# Arguments:
#   $@ — CLI-Argumente
#######################################
main() {
    parse_arguments "$@"

    local repo_path="${WORKSPACE_BASE_PATH}/${ABSTRACTION_REPO_SUBDIR}"

    log_info "=== ${SCRIPT_NAME} v${SCRIPT_VERSION} ==="
    log_info "Workspace:   ${WORKSPACE_BASE_PATH}"
    log_info "Repository:  ${repo_path}"
    log_info "Branch:      ${INITIAL_BRANCH_NAME}"
    [[ "${IS_DRY_RUN}" == "true" ]] && log_warn "DRY-RUN — keine Änderungen werden vorgenommen."

    check_prerequisites
    create_directory_structure "${repo_path}"
    initialize_git_repository  "${repo_path}" "${INITIAL_BRANCH_NAME}"
    create_initial_files       "${repo_path}"
    create_initial_git_commit  "${repo_path}"

    log_success "=== Repository-Initialisierung abgeschlossen ==="
    log_info "Pfad: ${repo_path}"
}

main "$@"
