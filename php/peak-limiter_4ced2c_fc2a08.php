<?php
// abstraction-provenance: {"artifact_sha256": "60dbcd3ac04b746021e91badfbe631fa446a039f4be593072eaa36d49b88d8ad", "source_sha256": "fc2a08fec30e381e2f112d375f3c1136b4730cdaa58967167750a5dc9b65532d", "target_language": "php"}
// peak-limiter_4ced2c.css — portiert nach php
// Quelle: css, Projects@abstractions:css/peak-limiter_4ced2c.css
// Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py
function generate_peak_limiter_css($output_file) {
    $css_content = <<<CSS
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
CSS;

    file_put_contents($output_file, $css_content);
}

// Wenn das Skript direkt aufgerufen wird, erzeuge die CSS-Datei
if (basename(__FILE__) === basename($_SERVER['SCRIPT_NAME'])) {
    $output_filename = "peak-limiter_4ced2c.css";
    if (isset($argv[1])) {
        $output_filename = $argv[1];
    }
    generate_peak_limiter_css($output_filename);
    echo "CSS-Datei wurde erfolgreich erstellt: " . $output_filename . "\n";
}
?>
