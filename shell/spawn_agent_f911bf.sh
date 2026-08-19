#!/usr/bin/env bash
# spawn_agent.py — portiert nach shell
# Quelle: python, OpenClaw@gateway2:skills/sub-agents-utils/scripts/spawn_agent.py
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Sub-Agent spawner - Einfache CLI für sessions_spawn

WORKSPACE="/home/openclaw/.openclaw/workspace"

# Füge WORKSPACE zum PYTHONPATH hinzu und lade die Modelle
export PYTHONPATH="${WORKSPACE}:${PYTHONPATH:-}"

# Lade verfügbare Modelle via Python-Hilfsprogramm
readarray -t MODELS < <(python3 -c "
import sys
sys.path.insert(0, '$WORKSPACE')
try:
    from openclaw_models import configured_models
    models = configured_models()
    for model in models:
        print(model)
except Exception as e:
    print(f'Modellkonfiguration kann nicht geladen werden: {e}', file=sys.stderr)
    sys.exit(1)
")

# Hilfsfunktion zur Überprüfung, ob ein Element in einem Array enthalten ist
function contains_element() {
    local element="$1"
    shift
    local array=("$@")
    for item in "${array[@]}"; do
        if [[ "$item" == "$element" ]]; then
            return 0
        fi
    done
    return 1
}

# Funktion zum Erstellen der Konfiguration
function get_spawn_config() {
    local task="$1"
    local label="$2"
    local model="$3"
    local thinking="$4"
    local timeout="$5"
    local thread="$6"
    local mode="$7"

    local config="{\"task\":\"$task\""

    if [[ -n "$label" ]]; then
        config="${config},\"label\":\"$label\""
    fi

    if [[ -n "$model" ]] && contains_element "$model" "${MODELS[@]}"; then
        config="${config},\"model\":\"$model\""
    fi

    if [[ -n "$thinking" ]]; then
        config="${config},\"thinking\":\"$thinking\""
    fi

    if [[ -n "$timeout" ]] && [[ "$timeout" =~ ^[0-9]+$ ]]; then
        config="${config},\"runTimeoutSeconds\":$timeout"
    fi

    if [[ "$thread" == "true" ]]; then
        config="${config},\"thread\":true"
        if [[ "$mode" == "run" ]]; then
            mode="session"
        fi
    fi

    config="${config},\"mode\":\"$mode\"}"
    echo "$config"
}

# Funktion zum Ausgeben des äquivalenten Tool-Kommandos
function print_spawn_command() {
    local config="$1"
    echo
    echo "🛠️  Tool-Aufruf:"
    echo "=================================================="
    echo "sessions_spawn("
    echo "$config" | jq -r 'to_entries[] | "    \(.key)=\(.value | if type == "string" then "\"\(.|tojson)\"" else . end)"'
    echo ")"
    echo "=================================================="
}

# Funktion zum Ausgeben des äquivalenten Slash-Kommandos
function print_slash_command() {
    local config="$1"
    local task label model thinking cmd

    task=$(echo "$config" | jq -r '.task // ""')
    label=$(echo "$config" | jq -r '.label // "agent"')
    model=$(echo "$config" | jq -r '.model // ""')
    thinking=$(echo "$config" | jq -r '.thinking // ""')

    cmd="/subagents spawn $label \"$task\""
    if [[ -n "$model" ]]; then
        cmd+=" --model $model"
    fi
    if [[ -n "$thinking" ]]; then
        cmd+=" --thinking $thinking"
    fi

    echo
    echo "💬 Slash Command:"
    echo "=================================================="
    echo "$cmd"
    echo "=================================================="
}

# Hauptfunktion
function main() {
    local task=""
    local label=""
    local model=""
    local thinking=""
    local timeout="900"
    local thread="false"
    local mode="run"
    local output="tool"

    while [[ $# -gt 0 ]]; do
        case $1 in
            --task|-t)
                task="$2"
                shift 2
                ;;
            --label|-l)
                label="$2"
                shift 2
                ;;
            --model|-m)
                model="$2"
                shift 2
                ;;
            --thinking)
                thinking="$2"
                shift 2
                ;;
            --timeout)
                timeout="$2"
                shift 2
                ;;
            --thread)
                thread="true"
                shift
                ;;
            --mode)
                mode="$2"
                shift 2
                ;;
            --output|-o)
                output="$2"
                shift 2
                ;;
            -h|--help)
                cat <<EOF
usage: spawn_agent.sh [-h] --task TASK [--label LABEL]
                      [--model {${MODELS[*]}}] [--thinking {low,medium,high}]
                      [--timeout TIMEOUT] [--thread] [--mode {run,session}]
                      [--output {tool,slash,json}]

Sub-Agent Spawn Helper

optional arguments:
  -h, --help            show this help message and exit
  --task TASK, -t TASK  Aufgabenbeschreibung
  --label LABEL, -l LABEL
                        Optionaler Label
  --model {${MODELS[*]}}
                        KI-Modell
  --thinking {low,medium,high}
                        Thinking Level
  --timeout TIMEOUT     Timeout in Sekunden (default: 900)
  --thread              Thread-Binding aktivieren
  --mode {run,session}  Run mode
  --output {tool,slash,json}, -o {tool,slash,json}
                        Output format

Beispiele:
  spawn_agent.sh -t "Analyze logs" 
  spawn_agent.sh -t "Code review" -m openrouter/anthropic/claude-haiku-4.5 --timeout 1800
  spawn_agent.sh -t "Batch process" -l "batch-worker" --thread
EOF
                exit 0
                ;;
            *)
                echo "Unbekanntes Argument: $1" >&2
                exit 1
                ;;
        esac
    done

    if [[ -z "$task" ]]; then
        echo "Fehler: --task ist erforderlich." >&2
        exit 1
    fi

    # Validierung des Modells
    if [[ -n "$model" ]] && ! contains_element "$model" "${MODELS[@]}"; then
        echo "Fehler: Ungültiges Modell '$model'. Gültige Optionen sind: ${MODELS[*]}" >&2
        exit 1
    fi

    # Validierung von thinking
    if [[ -n "$thinking" ]] && ! [[ "$thinking" =~ ^(low|medium|high)$ ]]; then
        echo "Fehler: Ungültiger Wert für --thinking. Gültige Werte sind: low, medium, high" >&2
        exit 1
    fi

    # Validierung von timeout
    if ! [[ "$timeout" =~ ^[0-9]+$ ]]; then
        echo "Fehler: Timeout muss eine Zahl sein." >&2
        exit 1
    fi

    # Validierung von mode
    if ! [[ "$mode" =~ ^(run|session)$ ]]; then
        echo "Fehler: Ungültiger Wert für --mode. Gültige Werte sind: run, session" >&2
        exit 1
    fi

    # Validierung von output
    if ! [[ "$output" =~ ^(tool|slash|json)$ ]]; then
        echo "Fehler: Ungültiger Wert für --output. Gültige Werte sind: tool, slash, json" >&2
        exit 1
    fi

    local config
    config=$(get_spawn_config "$task" "$label" "$model" "$thinking" "$timeout" "$thread" "$mode")

    echo "✅ Sub-Agent Konfiguration:"
    echo "$config" | jq .

    case "$output" in
        tool)
            print_spawn_command "$config"
            ;;
        slash)
            print_slash_command "$config"
            ;;
        json)
            echo
            echo "📄 JSON:"
            echo "$config"
            
            local output_file
            output_file="/tmp/subagent_${label:-spawn}.json"
            echo "$config" > "$output_file"
            echo "💾 Gespeichert: $output_file"
            ;;
    esac
}

main "$@"
