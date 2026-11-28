#!/bin/bash
# abstraction-provenance: {"artifact_sha256": "6a19d32569654c31e5f8f6aa358a40531e61ef9551399f04dd6d9ea629acad69", "source_sha256": "fc2a08fec30e381e2f112d375f3c1136b4730cdaa58967167750a5dc9b65532d", "target_language": "shell"}
# peak-limiter_4ced2c.css — portiert nach shell
# Quelle: css, Projects@abstractions:css/peak-limiter_4ced2c.css
# Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Abstraction provenance information
# artifact_sha256: c86160b4782bbdd4341a998965a2c305098b3c29f36c24b5c96324073afc4800
# source_sha256: 4ced2ca9b27b1be45a4172c7993a0693b54431a3a2703c30cb796b668ff34bc0
# target_language: css

# Check if output file parameter is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <output_file>"
    exit 1
fi

output_file="$1"

# Write CSS content to the specified output file
cat > "$output_file" << 'EOF'
/* abstraction-provenance: {"artifact_sha256": "c86160b4782bbdd4341a998965a2c305098b3c29f36c24b5c96324073afc4800", "source_sha256": "4ced2ca9b27b1be45a4172c7993a0693b54431a3a2703c30cb796b668ff34bc0", "target_language": "css"} */
/* peak-limiter.html — portiert nach css */
/* Quelle: html, Projects@vercel/install-and-configure-vercel-w-98sxlo:plugin-source/tests/peak-limiter.html */
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
