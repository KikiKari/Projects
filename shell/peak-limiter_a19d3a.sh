#!/bin/bash
# abstraction-provenance: {"artifact_sha256": "813c06e3ecc5a57d687dbe5023747babb22cf90ea2f6aa804255a4768e8d84ae", "source_sha256": "a19d3a3ec8b016d9d04f485dc499f8ad715431708b02863f2ac58f3208061edd", "target_language": "shell"}
# peak-limiter.css — portiert nach shell
# Quelle: css, Projects@abstractions:css/peak-limiter.css
# Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Schreibe die CSS-Inhalte in die angegebene Datei
write_css() {
    local output_file="$1"

    cat > "$output_file" << 'EOF'
/* abstraction-provenance: {"artifact_sha256": "3f2b97b726a0a4643711dc1dc285df9b75511cc4f35fbe168e178bf60aeaa00d", "source_sha256": "162cbb093559fd1ff9a7f362e753f4d965a73d5e557fce20d9cd95367574146b", "target_language": "css"} */
/* peak-limiter.html — portiert nach css */
/* Quelle: html, Projects@TikTok-Live-Companion:plugin-source/tests/peak-limiter.html */
/* auch in: Projects@TikTok-Live-Companion-Android:plugin-source/tests/peak-limiter.html */
/* auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/tests/peak-limiter.html */
/* auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/tests/peak-limiter.html */
/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */

body {
  font: 16px system-ui;
  max-width: 1000px;
  margin: 40px auto;
  padding: 20px;
}

pre {
  white-space: pre-wrap;
}

button {
  padding: 12px;
}
EOF
}

# Hauptprogramm
main() {
    if [[ $# -ne 1 ]]; then
        echo "Verwendung: $0 <ausgabedatei>" >&2
        exit 1
    fi

    local output_file="$1"
    write_css "$output_file"
}

main "$@"
