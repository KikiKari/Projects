#!/usr/bin/env bash
# abstraction-provenance: {"artifact_sha256": "d1009110ffb5102e34d95b8221c1c48fdd91f2b21b33fac6d54dffd8a44664d5", "source_sha256": "502dcda47466a4ab74da59badbe4b12c4782ed031c43d5038f8bd8534373cd35", "target_language": "shell"}
# model_usage.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:skills/model-usage/scripts/model_usage.py
# auch in: OpenClaw@gateway2:skills/model-usage/scripts/model_usage.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

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

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Options:
  --provider PROVIDER   Provider to query (codex or claude) [default: codex]
  --mode MODE           Mode: current or all [default: current]
  --model MODEL         Explicit model name to report instead of auto-current
  --input INPUT         Path to codexbar cost JSON (or '-' for stdin)
  --days DAYS           Limit to last N days (based on daily rows)
  --format FORMAT       Output format: text or json [default: text]
  --pretty              Pretty-print JSON output
  -h, --help            Show this help message and exit
EOF
}

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
            PRETTY="yes"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

eprint() {
    echo "$*" >&2
}

run_codexbar_cost() {
    local provider="$1"
    if ! command -v codexbar >/dev/null 2>&1; then
        eprint "codexbar not found on PATH. Install CodexBar CLI first."
        return 1
    fi
    
    local output
    if ! output=$(codexbar cost --format json --provider "$provider" 2>/dev/null); then
        eprint "codexbar cost failed"
        return 1
    fi
    
    echo "$output"
}

load_payload() {
    local input_path="$1"
    local provider="$2"
    
    if [[ -n "$input_path" ]]; then
        if [[ "$input_path" == "-" ]]; then
            cat
        else
            cat "$input_path"
        fi
    else
        run_codexbar_cost "$provider"
    fi
}

parse_daily_entries() {
    local payload="$1"
    echo "$payload" | jq -c '.daily // [] | map(select(type == "object"))' 2>/dev/null || echo '[]'
}

filter_by_days() {
    local entries="$1"
    local days="$2"
    
    if [[ -z "$days" ]]; then
        echo "$entries"
        return
    fi
    
    local cutoff
    cutoff=$(date -d "$days days ago" +%Y-%m-%d 2>/dev/null || date -v-"$days"d +%Y-%m-%d 2>/dev/null) || {
        eprint "Failed to calculate cutoff date"
        echo "$entries"
        return
    }
    
    echo "$entries" | jq -c --arg cutoff "$cutoff" '
        map(select(.date and .date >= $cutoff))
    ' 2>/dev/null || echo '[]'
}

aggregate_costs() {
    local entries="$1"
    echo "$entries" | jq -c '
        map(.modelBreakdowns // [])
        | flatten
        | map(select(type == "object" and .modelName and (.cost | type == "number")))
        | group_by(.modelName)
        | map({
            modelName: .[0].modelName,
            cost: map(.cost) | add
          })
        | map({(.modelName): .cost})
        | add // {}
    ' 2>/dev/null || echo '{}'
}

pick_current_model() {
    local entries="$1"
    local result
    result=$(echo "$entries" | jq -r '
        sort_by(.date // "")
        | reverse
        | .[]
        | select(.modelBreakdowns or .modelsUsed)
        | if .modelBreakdowns then
            .modelBreakdowns |= map(select(type == "object" and .modelName and (.cost | type == "number")))
            | .modelBreakdowns |= sort_by(.cost) | .modelBreakdowns |= reverse
            | if (.modelBreakdowns | length) > 0 then
                .modelBreakdowns[0].modelName + "|" + (.date // "")
              else
                empty
              end
          elif .modelsUsed and (.modelsUsed | length) > 0 then
            (.modelsUsed | last) + "|" + (.date // "")
          else
            empty
          end
    ' 2>/dev/null | head -n1)
    
    if [[ -n "$result" && "$result" != "null" ]]; then
        echo "$result"
    else
        echo "|"
    fi
}

usd() {
    local value="$1"
    if [[ -z "$value" || "$value" == "null" ]]; then
        echo "—"
    else
        printf '$%.2f' "$value" | sed 's/\$\([0-9]*\)\.\([0-9]*\)/\$\1,\2/' | sed 's/,\([0-9]\{3\}\)\([,.]\)/,\1\2/g'
    fi
}

latest_day_cost() {
    local entries="$1"
    local model="$2"
    echo "$entries" | jq -c --arg model "$model" '
        sort_by(.date // "")
        | reverse
        | .[]
        | select(.modelBreakdowns)
        | .modelBreakdowns[]
        | select(.modelName == $model)
        | {date: .date, cost: .cost}
    ' 2>/dev/null | head -n1 | jq -r '{"date": .date, "cost": .cost}' 2>/dev/null || echo '{"date": null, "cost": null}'
}

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

render_text_all() {
    local provider="$1"
    local totals="$2"
    
    echo "Provider: $provider"
    echo "Models:"
    
    echo "$totals" | jq -r '
        to_entries
        | sort_by(.value)
        | reverse
        | .[]
        | "- " + .key + ": " + (.value | tostring)
    ' 2>/dev/null | while read -r line; do
        model=$(echo "$line" | cut -d':' -f1 | sed 's/- //' | xargs)
        cost=$(echo "$line" | cut -d':' -f2 | xargs)
        echo "- $model: $(usd "$cost")"
    done
}

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
          --arg entry_count "$entry_count" '
    {
        provider: $provider,
        mode: "current",
        model: $model,
        latestModelDate: $latest_date,
        totalCostUSD: ($total_cost | if . == "" or . == "null" then null else tonumber end),
        latestDayCostUSD: ($latest_cost | if . == "" or . == "null" then null else tonumber end),
        latestDayCostDate: $latest_cost_date,
        dailyRowCount: ($entry_count | tonumber)
    }'
}

build_json_all() {
    local provider="$1"
    local totals="$2"
    
    echo "$totals" | jq --arg provider "$provider" '
        {
            provider: $provider,
            mode: "all",
            models: (
                to_entries
                | sort_by(.value)
                | reverse
                | map({model: .key, totalCostUSD: .value})
            )
        }
    '
}

main() {
    local payload entries filtered_entries model latest_date totals total_cost latest_cost_info latest_cost latest_cost_date entry_count
    
    if ! payload=$(load_payload "$INPUT" "$PROVIDER"); then
        return 1
    fi
    
    if ! entries=$(parse_daily_entries "$payload"); then
        eprint "Failed to parse daily entries"
        return 1
    fi
    
    if ! filtered_entries=$(filter_by_days "$entries" "$DAYS"); then
        eprint "Failed to filter entries by days"
        return 1
    fi
    
    if [[ "$MODE" == "current" ]]; then
        if [[ -z "$MODEL" ]]; then
            local current_result
            current_result=$(pick_current_model "$filtered_entries")
            IFS='|' read -r model latest_date <<< "$current_result"
            
            if [[ -z "$model" || "$model" == "null" ]]; then
                eprint "No model data found in codexbar cost payload."
                return 2
            fi
        else
            model="$MODEL"
        fi
        
        if ! totals=$(aggregate_costs "$filtered_entries"); then
            eprint "Failed to aggregate costs"
            return 1
        fi
        
        total_cost=$(echo "$totals" | jq -r --arg model "$model" '.[$model] // "null"')
        latest_cost_info=$(latest_day_cost "$filtered_entries" "$model")
        latest_cost=$(echo "$latest_cost_info" | jq -r '.cost // "null"')
        latest_cost_date=$(echo "$latest_cost_info" | jq -r '.date // "null"')
        entry_count=$(echo "$filtered_entries" | jq 'length')
        
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
    
    if ! totals=$(aggregate_costs "$filtered_entries"); then
        eprint "Failed to aggregate costs"
        return 1
    fi
    
    if [[ "$(echo "$totals" | jq 'length')" -eq 0 ]]; then
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

main "$@"
