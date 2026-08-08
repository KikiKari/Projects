#!/bin/bash
# abstractions_manager.js — portiert nach shell
# Quelle: javascript, Projects@abstractions:javascript/abstractions_manager.js
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# abstractions_manager.py — portiert nach bash
# Quelle: python, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/abstractions_manager.py
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

# Script Abstractions Manager - Multi-Node Edition

# Konfiguration
readonly WORKSPACE="/home/openclaw/.openclaw/workspace"
readonly ABSTRACTIONS_REPO="${WORKSPACE}/git/Abstraktionen"
readonly LOG_DIR="${WORKSPACE}/logs/abstractions-manager"
readonly STATE_FILE="${WORKSPACE}/db/abstractions_state.json"

# Node-Konfiguration mit Prioritäten
declare -A NODES=(
    ["node1.always_available"]="true"
    ["node1.capacity"]="medium"
    ["node1.priority"]="2"
    ["node2.always_available"]="true"
    ["node2.capacity"]="medium"
    ["node2.priority"]="3"
    ["node3.always_available"]="false"
    ["node3.capacity"]="medium"
    ["node3.priority"]="4"
    ["node5.always_available"]="false"
    ["node5.capacity"]="low"
    ["node5.priority"]="5"
    ["node5.device"]="Redmi Note 11S"
    ["node5.condition"]="mobile_internet"
    ["node7.always_available"]="true"
    ["node7.capacity"]="high"
    ["node7.priority"]="1"
)

readonly AVAILABLE_MODELS=(
    "openrouter/moonshotai/kimi-k2.5"
    "openrouter/openai/gpt-4o"
    "openrouter/anthropic/claude-3-5-sonnet-20241022"
    "openrouter/google/gemini-2.0-flash-001"
    "openrouter/nvidia/llama-3.3-nemotron-super-49b-v1"
    "openrouter/qwen/qwen-2.5-coder-32b-instruct"
)

# Ziel-Sprachen-Konfiguration
declare -A TARGET_LANGUAGES=(
    ["perl5.ext"]=".pl"
    ["perl5.shebang"]="#!/usr/bin/env perl"
    ["perl5.header"]="use strict;
use warnings;"
    ["perl6.ext"]=".raku"
    ["perl6.shebang"]="#!/usr/bin/env raku"
    ["perl6.header"]="use v6;"
    ["javascript.ext"]=".js"
    ["javascript.shebang"]="#!/usr/bin/env node"
    ["javascript.header"]=""
    ["python.ext"]=".py"
    ["python.shebang"]="#!/usr/bin/env python3"
    ["python.header"]=""
    ["shell.ext"]=".sh"
    ["shell.shebang"]="#!/bin/bash"
    ["shell.header"]="set -euo pipefail"
    ["powershell.ext"]=".ps1"
    ["powershell.shebang"]="#!/usr/bin/env pwsh"
    ["powershell.header"]="#Requires -Version 7"
    ["tcl.ext"]=".tcl"
    ["tcl.shebang"]="#!/usr/bin/env tclsh"
    ["tcl.header"]="package require Tcl 8.6"
    ["ruby.ext"]=".rb"
    ["ruby.shebang"]="#!/usr/bin/env ruby"
    ["ruby.header"]="require 'json'
require 'fileutils'"
    ["lua.ext"]=".lua"
    ["lua.shebang"]="#!/usr/bin/env lua"
    ["lua.header"]=""
    ["go.ext"]=".go"
    ["go.shebang"]="// +build ignore"
    ["go.header"]="package main"
)

log() {
    local message="$1"
    local level="${2:-INFO}"
    mkdir -p "${LOG_DIR}"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local line="[${timestamp}] [${level}] ${message}"
    echo "${line}"
    local log_file
    log_file="${LOG_DIR}/$(date '+%Y-%m-%d').log"
    echo "${line}" >> "${log_file}"
}

getNodeByPriority() {
    local jobWeight="${1:-medium}"
    local preferredOrder
    
    # Prioritäts-Matrix
    if [[ "${jobWeight}" == "heavy" ]]; then
        # Schwere Jobs → Node 7 (Docker mit vielen Ressourcen)
        preferredOrder=("node7" "node2" "node1")
    elif [[ "${jobWeight}" == "medium" ]]; then
        # Mittlere Jobs → Stable Nodes
        preferredOrder=("node2" "node1" "node7")
    else  # light
        # Leichte Jobs → Mobile/verfügbare Nodes
        preferredOrder=("node5" "node1" "node2")
    fi
    
    # Prüfe Verfügbarkeit
    local nodeId
    for nodeId in "${preferredOrder[@]}"; do
        if [[ -z "${NODES[${nodeId}.always_available]:-}" ]]; then
            continue
        fi
        
        local always_available="${NODES[${nodeId}.always_available]}"
        
        # Skip nicht immer verfügbare Nodes wenn nicht explizit requested
        if [[ "${always_available}" != "true" && "${jobWeight}" != "light" ]]; then
            continue
        fi
        
        # Prüfe ob Node online
        if checkNodeStatus "${nodeId}"; then
            echo "${nodeId}"
            return 0
        fi
    done
    
    # Fallback zu Node 1
    echo "node1"
}

checkNodeStatus() {
    local nodeId="$1"
    if command -v openclaw >/dev/null 2>&1; then
        if timeout 5 openclaw nodes status "${nodeId}" 2>/dev/null | grep -qE "(online|active)"; then
            return 0
        fi
    fi
    
    # Bei Timeout/Error: Prüfe letzten bekannten Status
    if [[ "${NODES[${nodeId}.always_available]:-}" == "true" ]]; then
        return 0
    fi
    return 1
}

getJobWeight() {
    local scriptSize="$1"
    local targetLangsCount="$2"
    local totalWork=$((scriptSize * targetLangsCount))
    
    if (( totalWork > 50000 )); then  # Große Scripts, viele Sprachen
        echo "heavy"
    elif (( totalWork > 10000 )); then  # Mittlere Last
        echo "medium"
    else
        echo "light"
    fi
}

loadState() {
    if [[ -f "${STATE_FILE}" ]]; then
        if jq empty "${STATE_FILE}" >/dev/null 2>&1; then
            cat "${STATE_FILE}"
            return 0
        fi
    fi
    
    cat <<EOF
{
  "processed": {},
  "queue": [],
  "current_priority": "high",
  "stats": {
    "total_scripts": 0,
    "abstractions_created": 0
  }
}
EOF
}

saveState() {
    local state="$1"
    mkdir -p "$(dirname "${STATE_FILE}")"
    echo "${state}" > "${STATE_FILE}"
}

findScriptsInDir() {
    local directory="$1"
    local excludePatterns="${2:-node_modules .git __pycache__ dist build}"
    
    if [[ ! -d "${directory}" ]]; then
        return 0
    fi
    
    local extensions=(".py" ".js" ".sh" ".pl" ".rb")
    local files=()
    
    while IFS= read -r -d '' file; do
        files+=("${file}")
    done < <(find "${directory}" -type f -print0 2>/dev/null)
    
    local script
    for script in "${files[@]}"; do
        local should_exclude=false
        for pattern in ${excludePatterns}; do
            if [[ "${script}" == *"${pattern}"* ]]; then
                should_exclude=true
                break
            fi
        done
        
        if [[ "${should_exclude}" == false ]]; then
            local ext="${script##*.}"
            for extension in "${extensions[@]}"; do
                if [[ ".${ext}" == "${extension}" ]]; then
                    echo "${script}"
                    break
                fi
            done
        fi
    done
}

createAbstraction() {
    local scriptPath="$1"
    local targetLang="$2"
    
    if [[ ! -f "${scriptPath}" ]]; then
        log "Failed: ${scriptPath} - File not found" "ERROR"
        return 1
    fi
    
    local originalContent
    originalContent=$(cat "${scriptPath}")
    
    local ext="${scriptPath##*.}"
    local sourceLangMap_py="Python"
    local sourceLangMap_js="JavaScript"
    local sourceLangMap_sh="Shell"
    local sourceLangMap_pl="Perl"
    local sourceLangMap_rb="Ruby"
    
    case "${ext}" in
        py) local sourceLang="${sourceLangMap_py}" ;;
        js) local sourceLang="${sourceLangMap_js}" ;;
        sh) local sourceLang="${sourceLangMap_sh}" ;;
        pl) local sourceLang="${sourceLangMap_pl}" ;;
        rb) local sourceLang="${sourceLangMap_rb}" ;;
        *) local sourceLang="${ext}" ;;
    esac
    
    local targetDir="${ABSTRACTIONS_REPO}/${targetLang}"
    mkdir -p "${targetDir}"
    
    local targetFile="${targetDir}/$(basename "${scriptPath}" ".${ext}")${TARGET_LANGUAGES[${targetLang}.ext]}"
    
    if [[ -f "${targetFile}" ]]; then
        return 1
    fi
    
    local template_shebang="${TARGET_LANGUAGES[${targetLang}.shebang]}"
    local template_header="${TARGET_LANGUAGES[${targetLang}.header]:-}"
    
    # Erste 15 Zeilen des Originalcodes
    local lines=""
    local i=0
    while IFS= read -r line && (( i < 15 )); do
        lines+="# ${line}"$'\n'
        ((i++))
    done <<< "${originalContent}"
    lines="${lines%$'\n'}"  # Entferne letztes Newline
    
    local content="${template_shebang}
# $(basename "${scriptPath}" ".${ext}") - ${targetLang^} Version
# Portiert von ${sourceLang}
# Original: ${scriptPath}
# Erstellt: $(date '+%Y-%m-%d')
#
"
    
    if [[ -n "${template_header}" ]]; then
        content+="${template_header}"$'\n\n'
    fi
    
    content+="# Original-Code-Referenz:
${lines}

function main() {
    # TODO: Implementiere ${sourceLang} Funktionalität in ${targetLang^}
    echo \"Hello World\"
}

if [[ \"\${BASH_SOURCE[0]}\" == \"\${0}\" ]]; then
    main
fi
"
    
    echo "${content}" > "${targetFile}"
    log "Created: ${targetFile}"
    return 0
}

processOnNode() {
    local nodeId="$1"
    shift
    local scripts=("$@")
    
    local created=0
    local script
    local lang
    
    if [[ "${nodeId}" == "node1" ]]; then
        # Lokale Verarbeitung
        for script in "${scripts[@]}"; do
            for lang in "${targetLangs[@]}"; do
                if createAbstraction "${script}" "${lang}"; then
                    ((created++))
                fi
            done
        done
    else
        # Remote-Verarbeitung
        log "Dispatching ${#scripts[@]} jobs to ${nodeId}"
        # TODO: Implementiere Remote-Dispatch wenn Node-Infrastruktur bereit
        # Für jetzt: Lokale Verarbeitung mit Node-Logging
        for script in "${scripts[@]}"; do
            for lang in "${targetLangs[@]}"; do
                if createAbstraction "${script}" "${lang}"; then
                    ((created++))
                    log "Processed on ${nodeId}: $(basename "${script}") -> ${lang}"
                fi
            done
        done
    fi
    
    echo "${created}"
}

processPriorityHigh() {
    local created=0
    local targets=(
        "skill-creator:${WORKSPACE}/skills/skill-creator/scripts"
        "json-utils:${WORKSPACE}/skills/json-utils/scripts"
        "scripting-utils:${WORKSPACE}/skills/scripting-utils/scripts"
        "model-usage:${WORKSPACE}/skills/model-usage/scripts"
        "tiktok-live:${WORKSPACE}/skills/tiktok-live/scripts"
    )
    
    local target
    for target in "${targets[@]}"; do
        local skillName="${target%%:*}"
        local scriptsDir="${target#*:}"
        
        local scripts=()
        while IFS= read -r script; do
            scripts+=("${script}")
        done < <(findScriptsInDir "${scriptsDir}" "node_modules .git test tests")
        
        log "${skillName}: ${#scripts[@]} scripts found"
        
        local count=0
        local script
        for script in "${scripts[@]}"; do
            if (( count >= 10 )); then
                break
            fi
            
            local scriptSize
            scriptSize=$(stat -c%s "${script}" 2>/dev/null || echo "0")
            
            local targetLangs=("perl5" "javascript" "python" "shell" "tcl")
            local jobWeight
            jobWeight=$(getJobWeight "${scriptSize}" "${#targetLangs[@]}")
            
            # Wähle Node basierend auf Job-Gewicht
            local selectedNode
            selectedNode=$(getNodeByPriority "${jobWeight}")
            log "Processing $(basename "${script}") (${jobWeight}) on ${selectedNode}"
            
            local result
            result=$(processOnNode "${selectedNode}" "${script}")
            ((created += result))
            
            ((count++))
        done
    done
    
    echo "${created}"
}

processPriorityMedium() {
    local created=0
    local targets=(
        "workspace-scripts:${WORKSPACE}/scripts"
        "db-maintainer:${WORKSPACE}/skills/db-maintainer/scripts"
        "log-collector:${WORKSPACE}/skills/log-collector/scripts"
    )
    
    local target
    for target in "${targets[@]}"; do
        local dirName="${target%%:*}"
        local scriptsDir="${target#*:}"
        
        local scripts=()
        while IFS= read -r script; do
            scripts+=("${script}")
        done < <(findScriptsInDir "${scriptsDir}" "node_modules .git")
        
        local script
        for script in "${scripts[@]}"; do
            local scriptSize
            scriptSize=$(stat -c%s "${script}" 2>/dev/null || echo "0")
            
            local targetLangs=("perl5" "javascript" "powershell" "python")
            local jobWeight
            jobWeight=$(getJobWeight "${scriptSize}" "${#targetLangs[@]}")
            
            # Mittlere Priority → eher leichtere Jobs
            local adjustedWeight="${jobWeight}"
            if [[ "${jobWeight}" == "heavy" ]]; then
                adjustedWeight="medium"
            fi
            
            local selectedNode
            selectedNode=$(getNodeByPriority "${adjustedWeight}")
            log "Processing $(basename "${script}") (${jobWeight}) on ${selectedNode}"
            
            local result
            result=$(processOnNode "${selectedNode}" "${script}")
            ((created += result))
        done
    done
    
    echo "${created}"
}

gitCommit() {
    local message="$1"
    if command -v git >/dev/null 2>&1 && [[ -d "${ABSTRACTIONS_REPO}/.git" ]]; then
        (
            cd "${ABSTRACTIONS_REPO}" || return 1
            git add . >/dev/null 2>&1 || true
            git commit -m "${message}" >/dev/null 2>&1 || true
            log "Git commit: ${message}"
        ) || true
    fi
}

createStatusReport() {
    local state="$1"
    local reportFile="${ABSTRACTIONS_REPO}/STATUS.md"
    
    local content="# Script Abstractions - Status Report

**Letzte Aktualisierung:** $(date '+%Y-%m-%d %H:%M')

"
    
    # Verarbeitete Scripts und Abstraktionen
    local processed_count
    processed_count=$(echo "${state}" | jq -r '(.processed | length)' 2>/dev/null || echo "0")
    
    local current_priority
    current_priority=$(echo "${state}" | jq -r '.current_priority // "high"' 2>/dev/null || echo "high")
    
    local abstractions_created
    abstractions_created=$(echo "${state}" | jq -r '.stats.abstractions_created // 0' 2>/dev/null || echo "0")
    
    content+="- Aktuelle Priorität: ${current_priority}
- Verarbeitete Scripts: ${processed_count}
- Abstraktionen gesamt: ${abstractions_created}

## Abstraktionen pro Sprache

"
    
    # Zähle Abstraktionen pro Sprache
    if [[ -d "${ABSTRACTIONS_REPO}" ]]; then
        local lang
        for lang in "${!TARGET_LANGUAGES[@]}"; do
            if [[ "${lang}" == *".ext" ]]; then
                continue
            fi
            
            local langDir="${ABSTRACTIONS_REPO}/${lang}"
            if [[ -d "${langDir}" ]]; then
                local count
                count=$(find "${langDir}" -maxdepth 1 -type f 2>/dev/null | wc -l)
                if (( count > 0 )); then
                    content+="- ${lang}: ${count}"$'\n'
                fi
            fi
        done
    fi
    
    content+="
## Verfügbare Modelle

"
    
    local i=0
    for model in "${AVAILABLE_MODELS[@]}"; do
        if (( i < 3 )); then
            content+="- \`${model}\`"$'\n'
        fi
        ((i++))
    done
    
    content+="- ... und $(( ${#AVAILABLE_MODELS[@]} - 3 )) weitere

## Multi-Node Support

| Node | Verfügbarkeit | Kapazität | Priorität | Gerät |
|------|---------------|-----------|-----------|-------|
"
    
    # Sortiere Nodes nach Priorität
    local sorted_nodes=()
    for node in node1 node2 node3 node5 node7; do
        if [[ -n "${NODES[${node}.priority]:-}" ]]; then
            sorted_nodes+=("${NODES[${node}.priority]}:${node}")
        fi
    done
    IFS=$'\n' sorted_nodes=($(sort <<<"${sorted_nodes[*]}"))
    unset IFS
    
    local entry
    for entry in "${sorted_nodes[@]}"; do
        local nodeId="${entry#*:}"
        local avail="❓ Unbekannt"
        if [[ "${NODES[${nodeId}.always_available]:-}" == "true" ]]; then
            avail="✅ Immer"
        elif [[ -n "${NODES[${nodeId}.always_available]:-}" ]]; then
            avail="📱 Bedingt"
        fi
        
        local capacity="${NODES[${nodeId}.capacity]:-unknown}"
        local priority="${NODES[${nodeId}.priority]:--}"
        local device="${NODES[${nodeId}.device]:-Server}"
        
        content+="| ${nodeId} | ${avail} | ${capacity} | ${priority} | ${device} |"$'\n'
    done
    
    content+="
### Job-Verteilung

- **Heavy Jobs** (>50KB × Sprachen) → Node 7 (Docker, hohe Ressourcen)
- **Medium Jobs** → Node 2 (Stable), Node 1 (Primary)
- **Light Jobs** → Node 5 (Redmi Note 11S, wenn verfügbar)
"
    
    echo "${content}" > "${reportFile}"
}

main() {
    log "Script Abstractions Manager (Multi-Node) gestartet"
    
    local state
    state=$(loadState)
    local processed_count
    processed_count=$(echo "${state}" | jq -r '(.processed | length)' 2>/dev/null || echo "0")
    log "State loaded: ${processed_count} processed"
    
    local current_priority
    current_priority=$(echo "${state}" | jq -r '.current_priority // "high"' 2>/dev/null || echo "high")
    local created=0
    
    if [[ "${current_priority}" == "high" ]]; then
        log "Processing HIGH priority: Top 5 Skills"
        created=$(processPriorityHigh)
        if (( created > 0 )); then
            gitCommit "High priority: ${created} abstractions"
        fi
        state=$(echo "${state}" | jq '.current_priority = "medium"')
    elif [[ "${current_priority}" == "medium" ]]; then
        log "Processing MEDIUM priority: Workspace Scripts"
        created=$(processPriorityMedium)
        if (( created > 0 )); then
            gitCommit "Medium priority: ${created} abstractions"
        fi
        state=$(echo "${state}" | jq '.current_priority = "high"')  # Zyklus
    fi
    
    # Aktualisiere Statistiken
    local total_abstractions=0
    if [[ -d "${ABSTRACTIONS_REPO}" ]]; then
        local lang
        for lang in "${!TARGET_LANGUAGES[@]}"; do
            if [[ "${lang}" == *".ext" ]]; then
                continue
            fi
            
            local langDir="${ABSTRACTIONS_REPO}/${lang}"
            if [[ -d "${langDir}" ]]; then
                local count
                count=$(find "${langDir}" -maxdepth 1 -type f 2>/dev/null | wc -l)
                ((total_abstractions += count))
            fi
        done
    fi
    
    state=$(echo "${state}" | jq ".stats.last_run = \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\" | .stats.abstractions_created = ${total_abstractions}")
    
    saveState "${state}"
    createStatusReport "${state}"
    
    log "Abgeschlossen. ${created} neue Abstraktionen erstellt."
}

# Hauptausführung
main "$@"
