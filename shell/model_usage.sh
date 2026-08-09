#!/usr/bin/env bash
# model_usage.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:skills/model-usage/scripts/model_usage.py
# auch in: OpenClaw@gateway2:skills/model-usage/scripts/model_usage.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Summarize CodexBar local cost usage by model.
#
# Defaults to current model (most recent daily entry), or list all models.

PROVIDER="codex"
MODE="current"
MODEL=""
INPUT=""
DAYS=""
FORMAT="text"
PRETTY=""

# Print to stderr
eprint() {
    echo "$*" >&2
}

# Run codexbar cost command and return JSON
run_codexbar_cost() {
    local provider="$1"
    local output
    if ! command -v codexbar >/dev/null 2>&1; then
        eprint "codexbar not found on PATH. Install CodexBar CLI first."
        return 1
    fi
    if ! output=$(codexbar cost --format json --provider "$provider" 2>/dev/null); then
        eprint "codexbar cost failed (exit $?)."
        return 1
    fi
    echo "$output"
}

# Load JSON payload from file or stdin or run codexbar
load_payload() {
    local input_path="$1"
    local provider="$2"
    local data

    if [[ -n "$input_path" ]]; then
        if [[ "$input_path" == "-" ]]; then
            data=$(cat)
        else
            if [[ ! -f "$input_path" ]]; then
                eprint "Input file not found: $input_path"
                return 1
            fi
            data=$(cat "$input_path")
        fi
    else
        data=$(run_codexbar_cost "$provider")
        if [[ $? -ne 0 ]]; then
            return 1
        fi
    fi

    echo "$data"
}

# Parse daily entries from payload
parse_daily_entries() {
    local payload="$1"
    echo "$payload" | jq -c '.daily // [] | map(select(type == "object"))'
}

# Parse date string to seconds since epoch
parse_date() {
    local value="$1"
    date -d "$value" +%s 2>/dev/null || echo ""
}

# Filter entries by days
filter_by_days() {
    local entries="$1"
    local days="$2"
    if [[ -z "$days" ]]; then
        echo "$entries"
        return
    fi
    local cutoff
    cutoff=$(date -d "$days days ago" +%s 2>/dev/null)
    echo "$entries" | jq -c --argjson cutoff "$cutoff" 'map(select(.date and ($cutoff | tostring) <= (.date | strptime("%Y-%m-%d") | mktime | tostring)))'
}

# Aggregate costs by model
aggregate_costs() {
    local entries="$1"
    echo "$entries" | jq -c 'reduce .[] as $entry ({}; . as $acc | ($entry.modelBreakdowns // []) | reduce .[] as $item ($acc; .[$item.modelName] += $item.cost))'
}

# Pick current model (highest cost model from latest date)
pick_current_model() {
    local entries="$1"
    local result
    result=$(echo "$entries" | jq -r 'sort_by(.date // "") | reverse | .[] | select(.modelBreakdowns or .modelsUsed) | if .modelBreakdowns then (.modelBreakdowns | sort_by(.cost) | reverse | .[0].modelName) else (.modelsUsed | last) end as $model | select($model) | "\($model)|\(.date)"' | head -n1)
    if [[ -n "$result" ]]; then
        echo "$result"
    else
        echo "|"
    fi
}

# Format USD value
usd() {
    local value="$1"
    if [[ -z "$value" || "$value" == "null" ]]; then
        echo "—"
    else
        printf '$%.2f' "$value" | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'
    fi
}

# Get latest day cost for a model
latest_day_cost() {
    local entries="$1"
    local model="$2"
    echo "$entries" | jq -r --arg model "$model" 'sort_by(.date // "") | reverse | .[] | select(.modelBreakdowns) | .modelBreakdowns[] | select(.modelName == $model) | "\(.cost)|\(.date)"' | head -n1
}

# Render text output for current model
render_text_current() {
    local provider="$1"
    local model="$2"
    local latest_date="$3"
    local total_cost="$4"
    local latest_cost="$5"
    local latest_cost_date="$6"
    local entry_count="$7"

    echo "Provider: $provider"
    echo "Current model: $model"
    if [[ -n "$latest_date" && "$latest_date" != "null" ]]; then
        echo "Latest model date: $latest_date"
    fi
    echo "Total cost (rows): $(usd "$total_cost")"
    if [[ -n "$latest_cost_date" && "$latest_cost_date" != "null" ]]; then
        echo "Latest day cost: $(usd "$latest_cost") ($latest_cost_date)"
    fi
    echo "Daily rows: $entry_count"
}

# Render text output for all models
render_text_all() {
    local provider="$1"
    local totals="$2"
    echo "Provider: $provider"
    echo "Models:"
    echo "$totals" | jq -r 'to_entries | sort_by(-.value) | .[] | "- \(.key): \(.value | tostring)"' | while read -r line; do
        model=$(echo "$line" | cut -d':' -f1 | sed 's/- //')
        cost=$(echo "$line" | cut -d':' -f2 | xargs)
        echo "- $model: $(usd "$cost")"
    done
}

# Build JSON output for current model
build_json_current() {
    local provider="$1"
    local model="$2"
    local latest_date="$3"
    local total_cost="$4"
    local latest_cost="$5"
    local latest_cost_date="$6"
    local entry_count="$7"
    
    jq -n --arg provider "$provider" \
          --arg model "$model" \
          --arg latest_date "$latest_date" \
          --arg total_cost "$total_cost" \
          --arg latest_cost "$latest_cost" \
          --arg latest_cost_date "$latest_cost_date" \
          --arg entry_count "$entry_count" \
          '{
            provider: $provider,
            mode: "current",
            model: $model,
            latestModelDate: $latest_date,
            totalCostUSD: ($total_cost | if . == "null" then null else . | tonumber end),
            latestDayCostUSD: ($latest_cost | if . == "null" then null else . | tonumber end),
            latestDayCostDate: $latest_cost_date,
            dailyRowCount: ($entry_count | tonumber)
          }'
}

# Build JSON output for all models
build_json_all() {
    local provider="$1"
    local totals="$2"
    echo "$totals" | jq --arg provider "$provider" '{
        provider: $provider,
        mode: "all",
        models: [to_entries[] | {model: .key, totalCostUSD: .value}]
    }'
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --provider)
            PROVIDER="$2"
            shift 2
            ;;
        --mode)
            MODE="$2"
            shift 2
            ;;
        --model)
            MODEL="$2"
            shift 2
            ;;
        --input)
            INPUT="$2"
            shift 2
            ;;
        --days)
            DAYS="$2"
            shift 2
            ;;
        --format)
            FORMAT="$2"
            shift 2
            ;;
        --pretty)
            PRETTY="1"
            shift
            ;;
        -h|--help)
            echo "Summarize CodexBar model usage from local cost logs."
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --provider [codex|claude]  Provider name (default: codex)"
            echo "  --mode [current|all]       Mode of operation (default: current)"
            echo "  --model MODEL              Explicit model name"
            echo "  --input PATH               Path to JSON input (or '-' for stdin)"
            echo "  --days N                   Limit to last N days"
            echo "  --format [text|json]       Output format (default: text)"
            echo "  --pretty                   Pretty-print JSON output"
            exit 0
            ;;
        *)
            eprint "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Main logic
main() {
    local payload
    payload=$(load_payload "$INPUT" "$PROVIDER")
    if [[ $? -ne 0 ]]; then
        return 1
    fi

    local entries
    entries=$(parse_daily_entries "$payload")
    if [[ -n "$DAYS" ]]; then
        entries=$(filter_by_days "$entries" "$DAYS")
    fi

    if [[ "$MODE" == "current" ]]; then
        local model="$MODEL"
        local latest_date=""
        if [[ -z "$model" ]]; then
            local model_date
            model_date=$(pick_current_model "$entries")
            model=$(echo "$model_date" | cut -d'|' -f1)
            latest_date=$(echo "$model_date" | cut -d'|' -f2)
            if [[ -z "$model" || "$model" == "null" ]]; then
                eprint "No model data found in codexbar cost payload."
                return 2
            fi
        fi

        local totals
        totals=$(aggregate_costs "$entries")
        local total_cost
        total_cost=$(echo "$totals" | jq -r --arg model "$model" '.[$model] // "null"')
        local latest_cost_result
        latest_cost_result=$(latest_day_cost "$entries" "$model")
        local latest_cost
        local latest_cost_date
        latest_cost=$(echo "$latest_cost_result" | cut -d'|' -f1)
        latest_cost_date=$(echo "$latest_cost_result" | cut -d'|' -f2)
        local entry_count
        entry_count=$(echo "$entries" | jq -r 'length')

        if [[ "$FORMAT" == "json" ]]; then
            local json_output
            json_output=$(build_json_current "$PROVIDER" "$model" "$latest_date" "$total_cost" "$latest_cost" "$latest_cost_date" "$entry_count")
            if [[ -n "$PRETTY" ]]; then
                echo "$json_output" | jq .
            else
                echo "$json_output"
            fi
        else
            render_text_current "$PROVIDER" "$model" "$latest_date" "$total_cost" "$latest_cost" "$latest_cost_date" "$entry_count"
        fi
        return 0
    fi

    local totals
    totals=$(aggregate_costs "$entries")
    if [[ $(echo "$totals" | jq -r 'length') -eq 0 ]]; then
        eprint "No model breakdowns found in codexbar cost payload."
        return 2
    fi

    if [[ "$FORMAT" == "json" ]]; then
        local json_output
        json_output=$(build_json_all "$PROVIDER" "$totals")
        if [[ -n "$PRETTY" ]]; then
            echo "$json_output" | jq .
        else
            echo "$json_output"
        fi
    else
        render_text_all "$PROVIDER" "$totals"
    fi
    return 0
}

main
exit $?
