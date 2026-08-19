#!/usr/bin/env bash
# spawn_agent.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:skills/sub-agents-utils/scripts/spawn_agent.py
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Sub-Agent spawner - Einfache CLI für sessions_spawn

# Lade Modellkonfiguration
load_models() {
    local config_path="${OPENCLAW_CONFIG:-/home/openclaw/.openclaw/openclaw.json}"
    local config_content
    local primary_model
    local fallback_models
    local model
    local models=()

    # Lies die Konfigurationsdatei
    if ! config_content=$(cat "$config_path" 2>/dev/null); then
        echo "Fehler: Kann Konfiguration nicht lesen: $config_path" >&2
        exit 1
    fi

    # Extrahiere primäres Modell
    if ! primary_model=$(echo "$config_content" | jq -r '.agents.defaults.model.primary // empty' 2>/dev/null); then
        echo "Fehler: Ungültiges JSON in Konfiguration" >&2
        exit 1
    fi

    # Extrahiere Fallback-Modelle
    if ! fallback_models=$(echo "$config_content" | jq -r '.agents.defaults.model.fallbacks[] // empty' 2>/dev/null); then
        echo "Fehler: Ungültiges JSON in Konfiguration" >&2
        exit 1
    fi

    # Prüfe primäres Modell
    if [[ -n "$primary_model" && "$primary_model" != "null" && "$primary_model" != "anthropic/"* ]]; then
        models+=("$primary_model")
    fi

    # Prüfe Fallback-Modelle
    while IFS= read -r model; do
        if [[ -n "$model" && "$model" != "null" && "$model" != "anthropic/"* ]]; then
            # Prüfe auf Duplikate
            local is_duplicate=false
            for existing in "${models[@]}"; do
                if [[ "$existing" == "$model" ]]; then
                    is_duplicate=true
                    break
                fi
            done
            if [[ "$is_duplicate" == false ]]; then
                models+=("$model")
            fi
        fi
    done <<< "$fallback_models"

    # Prüfe ob Modelle vorhanden sind
    if [[ ${#models[@]} -eq 0 ]]; then
        echo "Fehler: Keine allgemein verfügbaren Modelle in $config_path" >&2
        exit 1
    fi

    # Gebe Modelle zeilenweise aus
    printf '%s\n' "${models[@]}"
}

# Globale Modelle laden
readarray -t MODELS < <(load_models)

# Hilfsfunktion zur Modellprüfung
is_valid_model() {
    local model="$1"
    for m in "${MODELS[@]}"; do
        if [[ "$m" == "$model" ]]; then
            return 0
        fi
    done
    return 1
}

# Erstelle Konfiguration für sessions_spawn
get_spawn_config() {
    local task="$1"
    local label="$2"
    local model="$3"
    local thinking="$4"
    local timeout="$5"
    local thread="$6"
    local mode="$7"

    local config="{\"task\":\"$task\"}"

    if [[ -n "$label" ]]; then
        config=$(echo "$config" | jq --arg label "$label" '. + {label: $label}')
    fi

    if [[ -n "$model" ]] && is_valid_model "$model"; then
        config=$(echo "$config" | jq --arg model "$model" '. + {model: $model}')
    fi

    if [[ -n "$thinking" ]]; then
        config=$(echo "$config" | jq --arg thinking "$thinking" '. + {thinking: $thinking}')
    fi

    if [[ -n "$timeout" ]] && [[ "$timeout" =~ ^[0-9]+$ ]]; then
        config=$(echo "$config" | jq --argjson timeout "$timeout" '. + {runTimeoutSeconds: $timeout}')
    fi

    if [[ "$thread" == "true" ]]; then
        config=$(echo "$config" | jq '. + {thread: true}')
        if [[ "$mode" == "run" ]]; then
            config=$(echo "$config" | jq '. + {mode: "session"}')
        else
            config=$(echo "$config" | jq --arg mode "$mode" '. + {mode: $mode}')
        fi
    else
        config=$(echo "$config" | jq --arg mode "$mode" '. + {mode: $mode}')
    fi

    echo "$config"
}

# Gibt das equivalente Tool-Kommando aus
print_spawn_command() {
    local config="$1"
    
    echo
    echo "🛠️  Tool-Aufruf:"
    echo "=================================================="
    echo "sessions_spawn("
    
    local keys
    readarray -t keys < <(echo "$config" | jq -r 'keys[]')
    
    for key in "${keys[@]}"; do
        local value
        value=$(echo "$config" | jq -r --arg k "$key" '.[$k]')
        if [[ "$value" == "true" ]] || [[ "$value" == "false" ]] || [[ "$value" =~ ^[0-9]+$ ]]; then
            echo "    $key=$value"
        else
            echo "    $key=\"$value\""
        fi
    done
    
    echo ")"
    echo "=================================================="
}

# Gibt das equivalente Slash-Kommando aus
print_slash_command() {
    local config="$1"
    
    local task
    local label
    local model
    local thinking
    
    task=$(echo "$config" | jq -r '.task // ""')
    label=$(echo "$config" | jq -r '.label // "agent"')
    model=$(echo "$config" | jq -r '.model // ""')
    thinking=$(echo "$config" | jq -r '.thinking // ""')
    
    local cmd="/subagents spawn $label \"$task\""
    
    if [[ -n "$model" ]] && [[ "$model" != "null" ]]; then
        cmd+=" --model $model"
    fi
    
    if [[ -n "$thinking" ]] && [[ "$thinking" != "null" ]]; then
        cmd+=" --thinking $thinking"
    fi
    
    echo
    echo "💬 Slash Command:"
    echo "=================================================="
    echo "$cmd"
    echo "=================================================="
}

# Hauptfunktion
main() {
    local task=""
    local label=""
    local model=""
    local thinking=""
    local timeout="900"
    local thread="false"
    local mode="run"
    local output="tool"
    
    # Hilfe anzeigen
    show_help() {
        cat << EOF
Sub-Agent Spawn Helper

Optionen:
  -t, --task TASK           Aufgabenbeschreibung (erforderlich)
  -l, --label LABEL         Optionaler Label
  -m, --model MODEL         KI-Modell
  --thinking LEVEL          Thinking Level (low|medium|high)
  --timeout SECONDS         Timeout in Sekunden (default: 900)
  --thread                  Thread-Binding aktivieren
  --mode MODE               Run mode (run|session) (default: run)
  -o, --output FORMAT       Output format (tool|slash|json) (default: tool)
  -h, --help                Diese Hilfe anzeigen

Beispiele:
  $0 -t "Analyze logs" 
  $0 -t "Code review" -m openai/gpt-5.6-sol --timeout 1800
  $0 -t "Batch process" -l "batch-worker" --thread
EOF
    }
    
    # Argumente parsen
    while [[ $# -gt 0 ]]; do
        case $1 in
            -t|--task)
                task="$2"
                shift 2
                ;;
            -l|--label)
                label="$2"
                shift 2
                ;;
            -m|--model)
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
            -o|--output)
                output="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo "Unbekannte Option: $1" >&2
                show_help
                exit 1
                ;;
        esac
    done
    
    # Prüfe erforderliche Parameter
    if [[ -z "$task" ]]; then
        echo "Fehler: --task ist erforderlich" >&2
        show_help
        exit 1
    fi
    
    # Prüfe Modelloption
    if [[ -n "$model" ]] && ! is_valid_model "$model"; then
        echo "Fehler: Ungültiges Modell '$model'" >&2
        echo "Verfügbare Modelle:" >&2
        printf '  %s\n' "${MODELS[@]}" >&2
        exit 1
    fi
    
    # Prüfe Thinking-Level
    if [[ -n "$thinking" ]] && [[ ! "$thinking" =~ ^(low|medium|high)$ ]]; then
        echo "Fehler: Ungültiger Thinking-Level '$thinking'. Erlaubt: low, medium, high" >&2
        exit 1
    fi
    
    # Prüfe Mode
    if [[ ! "$mode" =~ ^(run|session)$ ]]; then
        echo "Fehler: Ungültiger Mode '$mode'. Erlaubt: run, session" >&2
        exit 1
    fi
    
    # Prüfe Output-Format
    if [[ ! "$output" =~ ^(tool|slash|json)$ ]]; then
        echo "Fehler: Ungültiges Output-Format '$output'. Erlaubt: tool, slash, json" >&2
        exit 1
    fi
    
    # Erstelle Konfiguration
    local config
    config=$(get_spawn_config "$task" "$label" "$model" "$thinking" "$timeout" "$thread" "$mode")
    
    echo "✅ Sub-Agent Konfiguration:"
    echo "$config" | jq .
    
    # Ausgabe entsprechend dem Format
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
            
            # Speichere als Datei
            local filename="subagent_${label:-spawn}.json"
            local output_file="/tmp/$filename"
            echo "$config" > "$output_file"
            echo "💾 Gespeichert: $output_file"
            ;;
    esac
}

# Skript ausführen
main "$@"
