#!/usr/bin/env bash
# wavespeed-image.js — portiert nach shell
# Quelle: javascript, OpenClaw@gateway1:scripts/wavespeed-image.js
# auch in: OpenClaw@gateway2:wavespeed-image.js
# auch in: OpenClaw@gateway2:scripts/wavespeed-image.js
# Erzeugt: 2026-08-23 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# WaveSpeed Image Analysis Tool
# User-Requested Only — kostenpflichtig ($0.14/Bild)

# Config
API_BASE="https://api.wavespeed.ai/v1"
MAX_IMAGES=7
PRICE_PER_IMAGE=0.14

# Load token from env
if [[ -z "${BANANA_TOKEN:-}" ]]; then
    echo "❌ Fehler: BANANA_TOKEN nicht gesetzt in ~/.config/openclaw/env" >&2
    exit 1
fi

show_usage() {
    cat <<EOF

Usage: wavespeed-image <command> [options]

Commands:
  analyze <image...>    Analyze one or more images

Options:
  --prompt <text>       Analysis prompt (required)
  --dry-run             Show cost without executing
  -h, --help            Show this help

Examples:
  wavespeed-image analyze photo.jpg --prompt "What's in this image?"
  wavespeed-image analyze img1.jpg img2.jpg --prompt "Compare these"

EOF
}

show_cost_warning() {
    local image_count=$1
    local total_cost
    total_cost=$(echo "scale=2; $image_count * $PRICE_PER_IMAGE" | bc)
    
    printf '\n'
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║  ⚠️  KOSTENHINWEIS — WaveSpeed Image Analysis              ║"
    echo "╠════════════════════════════════════════════════════════════╣"
    printf "║  Anzahl Bilder: %-44s║\n" "$image_count"
    printf "║  Preis pro Bild: \$%-42s║\n" "$PRICE_PER_IMAGE"
    printf "║  Gesamtkosten: ~\$%-43s║\n" "$total_cost"
    echo "╠════════════════════════════════════════════════════════════╣"
    echo "║  Abrechnung über dein WaveSpeed Guthaben                   ║"
    echo "║  https://wavespeed.ai/account/billing                      ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    printf '\n'
}

confirm_execution() {
    # In OpenClaw context, this would be handled by the system
    # For CLI: require explicit --confirm flag
    if [[ " ${ARGS[*]} " =~ " --confirm " ]]; then
        return 0
    else
        return 1
    fi
}

analyze_images() {
    local image_paths=("$@")
    local prompt="${image_paths[-1]}"
    unset 'image_paths[${#image_paths[@]}-1]'
    
    echo ""
    echo "🖼️  Analysiere ${#image_paths[@]} Bilder..."
    echo "📝 Prompt: \"$prompt\""
    echo ""
    echo "⏳ Anfrage wird gesendet..."
    echo ""
    
    # TODO: Implement actual API call
    # For now, return simulated response
    
    echo "✅ Analyse abgeschlossen"
    echo ""
    
    for img in "${image_paths[@]}"; do
        basename_img=$(basename "$img")
        echo "📄 $basename_img:"
        echo "   [Analyse-Ergebnis für $basename_img würde hier stehen]"
        echo ""
    done
}

main() {
    local ARGS=("$@")
    
    if [[ $# -eq 0 ]] || [[ " ${ARGS[*]} " =~ " -h " ]] || [[ " ${ARGS[*]} " =~ " --help " ]]; then
        show_usage
        exit 0
    fi
    
    local command="${ARGS[0]}"
    
    if [[ "$command" == "analyze" ]]; then
        # Parse arguments
        local image_paths=()
        local prompt=""
        local i=1
        
        while [[ $i -lt ${#ARGS[@]} ]]; do
            if [[ "${ARGS[$i]}" == "--prompt" ]]; then
                ((i++))
                prompt="${ARGS[$i]:-}"
            elif [[ "${ARGS[$i]}" != "--dry-run" ]] && [[ "${ARGS[$i]}" != "--confirm" ]] && [[ ! "${ARGS[$i]}" =~ ^-- ]]; then
                image_paths+=("${ARGS[$i]}")
            fi
            ((i++))
        done
        
        # Validate
        if [[ ${#image_paths[@]} -eq 0 ]]; then
            echo "❌ Fehler: Mindestens ein Bild-Pfad erforderlich" >&2
            exit 1
        fi
        
        if [[ ${#image_paths[@]} -gt $MAX_IMAGES ]]; then
            echo "❌ Fehler: Maximum $MAX_IMAGES Bilder erlaubt" >&2
            exit 1
        fi
        
        if [[ -z "$prompt" ]]; then
            echo "❌ Fehler: --prompt erforderlich" >&2
            exit 1
        fi
        
        # Validate files exist
        for img in "${image_paths[@]}"; do
            if [[ ! -f "$img" ]]; then
                echo "❌ Fehler: Datei nicht gefunden: $img" >&2
                exit 1
            fi
        done
        
        # Show cost warning
        show_cost_warning "${#image_paths[@]}"
        
        # Dry run
        if [[ " ${ARGS[*]} " =~ " --dry-run " ]]; then
            echo "✅ Dry-run: Keine API-Anfrage gesendet"
            echo ""
            exit 0
        fi
        
        # Check for confirmation
        if ! confirm_execution; then
            echo ""
            echo "⚠️  Hinweis: Füge --confirm hinzu um die Anfrage auszuführen"
            echo "   Befehl: wavespeed-image analyze ${image_paths[*]} --prompt \"$prompt\" --confirm"
            echo ""
            exit 0
        fi
        
        # Execute
        analyze_images "${image_paths[@]}" "$prompt"
        
    else
        echo "❌ Unbekannter Befehl: $command" >&2
        show_usage
        exit 1
    fi
}

main "$@"
