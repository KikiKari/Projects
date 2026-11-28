<?php
// abstraction-provenance: {"artifact_sha256": "f08bd34218df3d186bd1ec3087f291e1818ea69904a0919eae37928eaf7d20a0", "source_sha256": "a19d3a3ec8b016d9d04f485dc499f8ad715431708b02863f2ac58f3208061edd", "target_language": "php"}
// peak-limiter.css — portiert nach php
// Quelle: css, Projects@abstractions:css/peak-limiter.css
// Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py
function generate_peak_limiter_css($output_file) {
    $css_content = <<<CSS
/* abstraction-provenance: {"artifact_sha256": "3f2b97b726a0a4643711dc1dc285df9b75511cc4f35fbe168e178bf60aeaa00d", "source_sha256": "162cbb093559fd1ff9a7f362e753f4d965a73d5e557fce20d9cd95367574146b", "target_language": "css"} */
/* peak-limiter.html — portiert nach css */
/* Quelle: html, Projects@TikTok-Live-Companion:plugin-source/tests/peak-limiter.html */
/* auch in: Projects@TikTok-Live-Companion-Android:plugin- source/tests/peak-limiter.html */
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
CSS;

    file_put_contents($output_file, $css_content);
}

// Wenn das Skript direkt aufgerufen wird, erzeuge die CSS-Datei
if (basename(__FILE__) === basename($_SERVER['SCRIPT_NAME'])) {
    if ($argc < 2) {
        echo "Verwendung: php " . basename(__FILE__) . " <ausgabedatei>\n";
        exit(1);
    }
    
    generate_peak_limiter_css($argv[1]);
}

?>
