#!/bin/bash
# abstraction-provenance: {"artifact_sha256": "09b331001fa9aa61c572a5efab98fb52bbd1662d0e010a0bf6bee766f2750dce", "source_sha256": "fce23ec10c43acef00ba36b3975889539f87b908bd4cfce77616443d2b5f569e", "target_language": "shell"}
# icon-controls.css — portiert nach shell
# Quelle: css, Projects@TikTok-Live-Companion:plugin-source/browser-extension/icon-controls.css
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/icon-controls.css
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/icon-controls.css
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/browser-extension/icon-controls.css
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Function to generate CSS for a specific icon style
generate_icon_style() {
    local style=$1
    cat <<EOF
html[data-icon-style="$style"] {
EOF

    # Define all icons with their respective paths
    local icons=(
        "auto-chat-refresh-counter"
        "browser"
        "captions"
        "chat-counter"
        "fullscreen"
        "mute"
        "off"
        "on"
        "pip"
        "play"
        "player"
        "protection-slider"
        "recommendation-counter"
        "report"
        "reset"
        "settings"
        "status"
        "stop"
        "unmute"
        "volume-slider"
    )

    for icon in "${icons[@]}"; do
        echo "  --icon-$icon:url(\"icons/$style/$icon.png\");"
    done

    echo "}"
}

# Function to generate control styles
generate_control_styles() {
    cat <<'EOF'
button[data-control-icon]::before,
.control-icon::before {
  content: "";
  display: inline-block;
  width: 32px;
  height: 32px;
  flex: 0 0 32px;
  background: var(--control-icon) center/contain no-repeat;
  vertical-align: middle;
  margin-inline-end: 0;
  pointer-events: none;
}

button[data-control-icon] {
  min-height: 44px;
  min-width: 44px;
  font-size: 0;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

button[data-control-icon][hidden] {
  display: none;
}

input[type="checkbox"] {
  appearance: none;
  -webkit-appearance: none;
  width: 44px;
  height: 44px;
  min-width: 44px;
  border: 0;
  background: var(--icon-off) center/40px no-repeat;
  cursor: pointer;
  vertical-align: middle;
}

input[type="checkbox"]:checked {
  background-image: var(--icon-on);
}

input[type="checkbox"]:focus-visible,
button[data-control-icon]:focus-visible {
  outline: 2px solid #1769df;
  outline-offset: 2px;
}

input[type="checkbox"]:disabled {
  opacity: .45;
  cursor: default;
}

.control-icon {
  display: inline-flex;
  align-items: center;
}

input[type="range"] {
  min-height: 32px;
}

.icon-style-setting {
  display: flex;
  align-items: center;
  gap: 8px;
}
EOF
}

# Function to generate icon variables
generate_icon_variables() {
    local icons=(
        "auto-chat-refresh-counter"
        "browser"
        "captions"
        "chat-counter"
        "fullscreen"
        "mute"
        "off"
        "on"
        "pip"
        "play"
        "player"
        "protection-slider"
        "recommendation-counter"
        "report"
        "reset"
        "settings"
        "status"
        "stop"
        "unmute"
        "volume-slider"
    )

    for icon in "${icons[@]}"; do
        echo "[data-control-icon=\"$icon\"] { --control-icon:var(--icon-$icon); }"
    done
}

# Main function
main() {
    local output_file="${1:-}"

    if [[ -z "$output_file" ]]; then
        echo "Usage: $0 <output-file>" >&2
        exit 1
    fi

    # Generate the complete CSS
    {
        # Generate styles for each icon theme
        generate_icon_style "plastisch"
        generate_icon_style "glass"
        generate_icon_style "linear"
        
        # Generate control styles
        generate_control_styles
        
        # Generate icon variables
        generate_icon_variables
    } > "$output_file"
}

# Run main function with all arguments
main "$@"
