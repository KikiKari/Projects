#!/bin/bash
# ABSTRACTIONS_MANAGER.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:abstraction-manager/ABSTRACTIONS_MANAGER.py
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Script Abstractions Manager - Multi-Node Edition
#
# Portiert OpenClaw-Scripts automatisch in Zielsprachen und verwaltet
# den Verarbeitungsstatus über ein JSON-State-File. Läuft per Cron (alle 6h).
#
# Verwendung:
#     bash ABSTRACTIONS_MANAGER.sh
#
# Konfiguration:
#     Alle Pfade und Einstellungen werden über Umgebungsvariablen aus der
#     Der Workspace-Pfad ist hardcoded: /home/openclaw/.openclaw/workspace

# ---------------------------------------------------------------------------
# Konfiguration
# ---------------------------------------------------------------------------

WORKSPACE="/home/openclaw/.openclaw/workspace"
ABSTRACTIONS_REPO="$WORKSPACE/git/Abstraktionen"
LOG_DIR="$WORKSPACE/logs/abstractions-manager"
STATE_FILE="$WORKSPACE/db/abstractions_state.json"

declare -A NODES=(
  ["node1"]='{"always_available":true,"capacity":"medium","priority":2}'
  ["node2"]='{"always_available":true,"capacity":"medium","priority":3}'
  ["node3"]='{"always_available":false,"capacity":"medium","priority":4}'
  ["node5"]='{"always_available":false,"capacity":"low","priority":5,"device":"Redmi Note 11S","condition":"mobile_internet"}'
  ["node7"]='{"always_available":true,"capacity":"high","priority":1}'
)

AVAILABLE_MODELS=(
  "openrouter/moonshotai/kimi-k2.5"
  "openrouter/openai/gpt-4o"
  "openrouter/anthropic/claude-3-5-sonnet-20241022"
  "openrouter/google/gemini-2.0-flash-001"
  "openrouter/nvidia/llama-3.3-nemotron-super-49b-v1"
  "openrouter/qwen/qwen-2.5-coder-32b-instruct"
)

declare -A TARGET_LANGUAGES=(
  ["perl5"]='{"ext":".pl","shebang":"#!/usr/bin/env perl","header":"use strict;\nuse warnings;\n","main_block":"sub main {\n    # TODO: Implementiere {source_lang} Funktionalität in Perl 5\n}\n\nmain();\n"}'
  ["perl6"]='{"ext":".raku","shebang":"#!/usr/bin/env raku","header":"use v6;\n","main_block":"sub MAIN() {\n    # TODO: Implementiere {source_lang} Funktionalität in Raku\n}"}'
  ["javascript"]='{"ext":".js","shebang":"#!/usr/bin/env node","header":"\"use strict\";\n","main_block":"function main() {\n    // TODO: Implementiere {source_lang} Funktionalität in JavaScript\n}\n\nmain();\n"}'
  ["python"]='{"ext":".py","shebang":"#!/usr/bin/env python3","header":"","main_block":"def main():\n    # TODO: Implementiere {source_lang} Funktionalität in Python\n    pass\n\n\nif __name__ == \"__main__\":\n    main()\n"}'
  ["shell"]='{"ext":".sh","shebang":"#!/bin/bash","header":"set -euo pipefail\n","main_block":"main() {\n    # TODO: Implementiere {source_lang} Funktionalität in Bash\n}\n\nmain \"$@\"\n"}'
  ["powershell"]='{"ext":".ps1","shebang":"#!/usr/bin/env pwsh","header":"#Requires -Version 7\n","main_block":"function Main {\n    # TODO: Implementiere {source_lang} Funktionalität in PowerShell\n}\n\nMain\n"}'
  ["tcl"]='{"ext":".tcl","shebang":"#!/usr/bin/env tclsh","header":"package require Tcl 8.6\n","main_block":"proc main {} {\n    # TODO: Implementiere {source_lang} Funktionalität in Tcl\n}\n\nmain\n"}'
  ["ruby"]='{"ext":".rb","shebang":"#!/usr/bin/env ruby","header":"# frozen_string_literal: true\nrequire \"json\"\nrequire \"fileutils\"\n","main_block":"def main\n  # TODO: Implementiere {source_lang} Funktionalität in Ruby\nend\n\nmain if __FILE__ == $PROGRAM_NAME\n"}'
  ["lua"]='{"ext":".lua","shebang":"#!/usr/bin/env lua","header":"","main_block":"local function main()\n    -- TODO: Implementiere {source_lang} Funktionalität in Lua\nend\n\nmain()\n"}'
  ["go"]='{"ext":".go","shebang":"// +build ignore","header":"package main\n\nimport \"fmt\"\n","main_block":"func main() {\n    // TODO: Implementiere {source_lang} Funktionalität in Go\n    _ = fmt.Println\n}"}'
)

# ---------------------------------------------------------------------------
# Logging-Setup
# ---------------------------------------------------------------------------

_setup_logger() {
  mkdir -p "$LOG_DIR"
  LOG_LEVEL="${ABSTRACTIONS_LOG_LEVEL:-INFO}"
  LOG_FILE="$LOG_DIR/$(date +%Y-%m-%d).log"
}

log() {
  local level="$1"
  shift
  local message="$*"
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo "$timestamp | $level     | ${FUNCNAME[1]}:${BASH_LINENO[0]} | $message" | tee -a "$LOG_FILE"
}

log_debug() {
  [[ "$LOG_LEVEL" == "DEBUG" ]] && log "DEBUG" "$@" || true
}

log_info() {
  log "INFO" "$@"
}

log_warning() {
  log "WARNING" "$@"
}

log_error() {
  log "ERROR" "$@"
}

# ---------------------------------------------------------------------------
# State-Management
# ---------------------------------------------------------------------------

load_state() {
  if [[ -f "$STATE_FILE" ]]; then
    if jq -e . >/dev/null 2>&1 < "$STATE_FILE"; then
      cat "$STATE_FILE"
    else
      log_error "State-File konnte nicht geparst werden ($STATE_FILE)"
      echo '{"processed":{},"queue":[],"current_priority":"high","stats":{"total_scripts":0,"abstractions_created":0}}'
    fi
  else
    echo '{"processed":{},"queue":[],"current_priority":"high","stats":{"total_scripts":0,"abstractions_created":0}}'
  fi
}

save_state() {
  local state="$1"
  mkdir -p "$(dirname "$STATE_FILE")"
  local tmpfile
  tmpfile=$(mktemp -p "$(dirname "$STATE_FILE")" .abstractions_state_XXXXXX.tmp)
  echo "$state" > "$tmpfile"
  mv "$tmpfile" "$STATE_FILE"
  log_debug "State atomar gespeichert: $STATE_FILE"
}

# ---------------------------------------------------------------------------
# Node-Management
# ---------------------------------------------------------------------------

check_node_status() {
  local node_id="$1"
  if command -v openclaw >/dev/null 2>&1; then
    if timeout 5 openclaw nodes status "$node_id" >/dev/null 2>&1; then
      return 0
    else
      log_warning "Timeout beim Status-Check von $node_id — verwende always_available"
      return 1
    fi
  else
    log_warning "'openclaw'-Binary nicht gefunden — verwende always_available für $node_id"
    return 1
  fi
}

get_job_weight() {
  local script_size="$1"
  local target_langs_count="$2"
  local total_work=$((script_size * target_langs_count))
  if (( total_work > 50000 )); then
    echo "heavy"
  elif (( total_work > 10000 )); then
    echo "medium"
  else
    echo "light"
  fi
}

get_node_by_priority() {
  local job_weight="${1:-medium}"
  local preferred_order
  case "$job_weight" in
    heavy) preferred_order=("node7" "node2" "node1") ;;
    medium) preferred_order=("node2" "node1" "node7") ;;
    light) preferred_order=("node5" "node1" "node2") ;;
    *) preferred_order=("node1" "node2") ;;
  esac

  for node_id in "${preferred_order[@]}"; do
    if [[ -n "${NODES[$node_id]:-}" ]]; then
      local node_cfg="${NODES[$node_id]}"
      local always_available
      always_available=$(echo "$node_cfg" | jq -r '.always_available // false')
      if [[ "$always_available" == "false" ]] && [[ "$job_weight" != "light" ]]; then
        continue
      fi
      if check_node_status "$node_id"; then
        log_debug "Node $node_id ausgewählt für ${job_weight}-Job"
        echo "$node_id"
        return 0
      fi
    fi
  done

  log_warning "Kein passender Node gefunden für Gewicht '$job_weight' — Fallback node1"
  echo "node1"
}

# ---------------------------------------------------------------------------
# Script-Verarbeitung
# ---------------------------------------------------------------------------

find_scripts_in_dir() {
  local directory="$1"
  local exclude_patterns=("${@:2}")
  if [[ ${#exclude_patterns[@]} -eq 0 ]]; then
    exclude_patterns=("node_modules" ".git" "__pycache__" "dist" "build")
  fi

  if [[ ! -d "$directory" ]]; then
    log_debug "Verzeichnis existiert nicht: $directory"
    return 0
  fi

  local found_scripts=()
  local pattern
  for pattern in "*.py" "*.js" "*.sh" "*.pl" "*.rb"; do
    while IFS= read -r -d '' file; do
      local exclude=false
      for excl in "${exclude_patterns[@]}"; do
        if [[ "$file" == *"$excl"* ]]; then
          exclude=true
          break
        fi
      done
      if [[ "$exclude" == false ]]; then
        found_scripts+=("$file")
      fi
    done < <(find "$directory" -name "$pattern" -type f -print0 2>/dev/null || true)
  done

  printf '%s\n' "${found_scripts[@]}"
}

_build_stub_content() {
  local script_path="$1"
  local target_lang="$2"
  local source_lang="$3"
  local template="$4"
  
  local shebang
  shebang=$(echo "$template" | jq -r '.shebang')
  local header
  header=$(echo "$template" | jq -r '.header')
  local main_block
  main_block=$(echo "$template" | jq -r ".main_block" | sed "s/{source_lang}/$source_lang/g")
  
  local today
  today=$(date +%Y-%m-%d)
  
  local original_lines=""
  if [[ -r "$script_path" ]]; then
    original_lines=$(head -n 15 "$script_path" 2>/dev/null || true)
  else
    log_warning "Originaldatei konnte nicht gelesen werden: $script_path"
  fi
  
  local comment_char
  if [[ "$target_lang" == "go" ]] || [[ "$target_lang" == "javascript" ]]; then
    comment_char="//"
  else
    comment_char="#"
  fi
  
  local original_preview=""
  if [[ -n "$original_lines" ]]; then
    while IFS= read -r line; do
      original_preview+="$comment_char $line"$'\n'
    done <<< "$original_lines"
  fi

  cat <<EOF
$shebang
$comment_char $(basename "$script_path" .*) - ${target_lang^} Version
$comment_char Portiert von $source_lang
$comment_char Original: $script_path
$comment_char Erstellt: $today

$header
$comment_char Original-Code-Referenz:
$original_preview
$main_block
EOF
}

create_abstraction() {
  local script_path="$1"
  local target_lang="$2"
  
  if [[ -z "${TARGET_LANGUAGES[$target_lang]:-}" ]]; then
    log_error "Unbekannte Zielsprache: $target_lang"
    return 1
  fi
  
  local template="${TARGET_LANGUAGES[$target_lang]}"
  local ext
  ext=$(echo "$template" | jq -r '.ext')
  
  local source_lang
  case "${script_path##*.}" in
    py) source_lang="Python" ;;
    js) source_lang="JavaScript" ;;
    sh) source_lang="Shell" ;;
    pl) source_lang="Perl" ;;
    rb) source_lang="Ruby" ;;
    *) source_lang="${script_path##*.}" ;;
  esac
  
  local target_dir="$ABSTRACTIONS_REPO/$target_lang"
  mkdir -p "$target_dir"
  
  local target_file="$target_dir/$(basename "$script_path" .*)"$(echo "$template" | jq -r '.ext')
  if [[ -f "$target_file" ]]; then
    log_debug "Bereits vorhanden, übersprungen: $target_file"
    return 1
  fi
  
  local content
  content=$(_build_stub_content "$script_path" "$target_lang" "$source_lang" "$template")
  
  local tmpfile
  tmpfile=$(mktemp -p "$target_dir" .stub_XXXXXX"$ext")
  echo "$content" > "$tmpfile"
  mv "$tmpfile" "$target_file"
  log_info "Erstellt: $target_file"
  return 0
}

process_on_node() {
  local node_id="$1"
  local scripts=("${@:2}")
  local target_langs=("${@:$((${#scripts[@]}+2))}")
  
  local created=0
  local script
  for script in "${scripts[@]}"; do
    local lang
    for lang in "${target_langs[@]}"; do
      if create_abstraction "$script" "$lang"; then
        ((created++))
      fi
    done
  done
  
  echo "$created"
}

# ---------------------------------------------------------------------------
# Prioritäts-Verarbeitung
# ---------------------------------------------------------------------------

process_priority_high() {
  local target_dirs=(
    "skill-creator:$WORKSPACE/skills/skill-creator/scripts"
    "json-utils:$WORKSPACE/skills/json-utils/scripts"
    "scripting-utils:$WORKSPACE/skills/scripting-utils/scripts"
    "model-usage:$WORKSPACE/skills/model-usage/scripts"
    "tiktok-live:$WORKSPACE/skills/tiktok-live/scripts"
  )
  local target_langs=("perl5" "javascript" "python" "shell" "tcl")
  local created=0
  local exclude=("node_modules" ".git" "test" "tests")
  
  local dir_entry
  for dir_entry in "${target_dirs[@]}"; do
    local skill_name="${dir_entry%%:*}"
    local scripts_dir="${dir_entry#*:}"
    
    local scripts=()
    while IFS= read -r script; do
      scripts+=("$script")
    done < <(find_scripts_in_dir "$scripts_dir" "${exclude[@]}")
    
    log_info "$skill_name: ${#scripts[@]} Scripts gefunden"
    
    local count=0
    local script
    for script in "${scripts[@]}"; do
      if (( count >= 10 )); then
        break
      fi
      
      local script_size
      script_size=$(stat -c %s "$script" 2>/dev/null || echo "0")
      local job_weight
      job_weight=$(get_job_weight "$script_size" "${#target_langs[@]}")
      local selected_node
      selected_node=$(get_node_by_priority "$job_weight")
      log_info "Verarbeite $(basename "$script") ($job_weight) auf $selected_node"
      local result
      result=$(process_on_node "$selected_node" "$script" "${target_langs[@]}")
      ((created += result))
      ((count++))
    done
  done
  
  echo "$created"
}

process_priority_medium() {
  local target_dirs=(
    "workspace-scripts:$WORKSPACE/scripts"
    "db-maintainer:$WORKSPACE/skills/db-maintainer/scripts"
    "log-collector:$WORKSPACE/skills/log-collector/scripts"
  )
  local target_langs=("perl5" "javascript" "powershell" "python")
  local created=0
  local exclude=("node_modules" ".git")
  
  local dir_entry
  for dir_entry in "${target_dirs[@]}"; do
    local dir_name="${dir_entry%%:*}"
    local scripts_dir="${dir_entry#*:}"
    
    local scripts=()
    while IFS= read -r script; do
      scripts+=("$script")
    done < <(find_scripts_in_dir "$scripts_dir" "${exclude[@]}")
    
    local count=0
    local script
    for script in "${scripts[@]}"; do
      if (( count >= 10 )); then
        break
      fi
      
      local script_size
      script_size=$(stat -c %s "$script" 2>/dev/null || echo "0")
      local job_weight
      job_weight=$(get_job_weight "$script_size" "${#target_langs[@]}")
      local effective_weight="$job_weight"
      if [[ "$job_weight" == "heavy" ]]; then
        effective_weight="medium"
      fi
      local selected_node
      selected_node=$(get_node_by_priority "$effective_weight")
      log_info "Verarbeite $(basename "$script") ($job_weight) auf $selected_node"
      local result
      result=$(process_on_node "$selected_node" "$script" "${target_langs[@]}")
      ((created += result))
      ((count++))
    done
  done
  
  echo "$created"
}

# ---------------------------------------------------------------------------
# Git-Integration
# ---------------------------------------------------------------------------

git_commit() {
  local message="$1"
  if command -v git >/dev/null 2>&1; then
    if cd "$ABSTRACTIONS_REPO" 2>/dev/null; then
      if git add . >/dev/null 2>&1; then
        if git commit -m "$message" >/dev/null 2>&1; then
          log_info "Git commit erfolgreich: $message"
        else
          log_warning "Git commit fehlgeschlagen: $message"
        fi
      else
        log_warning "Git add fehlgeschlagen"
      fi
      cd - >/dev/null || return
    else
      log_warning "Konnte nicht ins Repo-Verzeichnis wechseln"
    fi
  else
    log_error "'git'-Binary nicht gefunden — Commit übersprungen"
  fi
}

# ---------------------------------------------------------------------------
# Status-Report
# ---------------------------------------------------------------------------

create_status_report() {
  local state="$1"
  
  if [[ ! -d "$ABSTRACTIONS_REPO" ]]; then
    log_warning "Abstractions-Repo existiert nicht: $ABSTRACTIONS_REPO"
    return
  fi
  
  local lang_counts=()
  local lang
  for lang in "${!TARGET_LANGUAGES[@]}"; do
    if [[ -d "$ABSTRACTIONS_REPO/$lang" ]]; then
      local count
      count=$(find "$ABSTRACTIONS_REPO/$lang" -type f | wc -l)
      lang_counts+=("$lang:$count")
    fi
  done
  
  local report_file="$ABSTRACTIONS_REPO/STATUS.md"
  {
    echo "# Script Abstractions - Status Report"
    echo ""
    echo "**Letzte Aktualisierung:** $(date '+%Y-%m-%d %H:%M')"
    echo ""
    echo "- Aktuelle Priorität: $(echo "$state" | jq -r '.current_priority // "high"')"
    echo "- Verarbeitete Scripts: $(echo "$state" | jq -r '.processed | length')"
    echo "- Abstraktionen gesamt: $(echo "$state" | jq -r '.stats.abstractions_created // 0')"
    echo ""
    echo "## Abstraktionen pro Sprache"
    echo ""
    
    local entry
    for entry in "${lang_counts[@]}"; do
      local lang_name="${entry%%:*}"
      local lang_count="${entry#*:}"
      echo "- $lang_name: $lang_count"
    done
    
    echo ""
    echo "## Verfügbare Modelle"
    echo ""
    
    local i=0
    for model in "${AVAILABLE_MODELS[@]}"; do
      if (( i < 3 )); then
        echo "- \`$model\`"
      fi
      ((i++))
    done
    echo "- ... und $(( ${#AVAILABLE_MODELS[@]} - 3 )) weitere"
    
    echo ""
    echo "## Multi-Node Support"
    echo ""
    echo "| Node | Verfügbarkeit | Kapazität | Priorität | Gerät |"
    echo "|------|---------------|-----------|-----------|-------|"
    
    local node_id
    for node_id in "${!NODES[@]}"; do
      local cfg="${NODES[$node_id]}"
      local avail
      if [[ $(echo "$cfg" | jq -r '.always_available // false') == "true" ]]; then
        avail="✅ Immer"
      else
        avail="📱 Bedingt"
      fi
      local capacity
      capacity=$(echo "$cfg" | jq -r '.capacity // "unknown"')
      local priority
      priority=$(echo "$cfg" | jq -r '.priority // "-"')
      local device
      device=$(echo "$cfg" | jq -r '.device // "Server"')
      echo "| $node_id | $avail | $capacity | $priority | $device |"
    done
    
    echo ""
    echo "### Job-Verteilung"
    echo ""
    echo "- **Heavy Jobs** (>50 KB × Sprachen) → Node 7 (Docker, hohe Ressourcen)"
    echo "- **Medium Jobs** → Node 2 (Stable), Node 1 (Primary)"
    echo "- **Light Jobs** → Node 5 (Redmi Note 11S, wenn verfügbar)"
  } > "$report_file"
  
  log_info "Status-Report erstellt: $report_file"
}

# ---------------------------------------------------------------------------
# Einstiegspunkt
# ---------------------------------------------------------------------------

main() {
  _setup_logger
  log_info "Script Abstractions Manager (Multi-Node) gestartet"
  
  local state
  state=$(load_state)
  log_info "State geladen: $(echo "$state" | jq -r '.processed | length') bereits verarbeitet"
  
  local current_priority
  current_priority=$(echo "$state" | jq -r '.current_priority // "high"')
  local created=0
  
  if [[ "$current_priority" == "high" ]]; then
    log_info "Verarbeite HIGH-Priorität: Top 5 Skills"
    created=$(process_priority_high)
    if (( created > 0 )); then
      git_commit "High priority: $created abstractions"
    fi
    state=$(echo "$state" | jq '.current_priority = "medium"')
  elif [[ "$current_priority" == "medium" ]]; then
    log_info "Verarbeite MEDIUM-Priorität: Workspace Scripts"
    created=$(process_priority_medium)
    if (( created > 0 )); then
      git_commit "Medium priority: $created abstractions"
    fi
    state=$(echo "$state" | jq '.current_priority = "high"')
  fi
  
  local last_run
  last_run=$(date -Iseconds)
  state=$(echo "$state" | jq --arg lr "$last_run" '.stats.last_run = $lr')
  
  local total_abstractions=0
  local lang
  for lang in "${!TARGET_LANGUAGES[@]}"; do
    if [[ -d "$ABSTRACTIONS_REPO/$lang" ]]; then
      local count
      count=$(find "$ABSTRACTIONS_REPO/$lang" -type f | wc -l)
      ((total_abstractions += count))
    fi
  done
  state=$(echo "$state" | jq --argjson ta "$total_abstractions" '.stats.abstractions_created = $ta')
  
  save_state "$state"
  create_status_report "$state"
  
  log_info "Abgeschlossen. $created neue Abstraktionen erstellt."
}

main "$@"
