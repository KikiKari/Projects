<?php
// abstraction-provenance: {"artifact_sha256": "8487704607f925196f5b14abdbe5ff1bb3ae7411e35b4845404d91064939d38b", "source_sha256": "daf22c296c801d3d533083361cc59fbdc22e5bfe528aa4bad1973b54cc5448a4", "target_language": "php"}
// index.css — portiert nach php
// Quelle: css, OpenClaw@main:src/index.css
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py
function generateCSS($filename) {
    $css = [
        'body' => [
            'margin' => '0',
            'font-family' => "-apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen', 'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue', sans-serif",
            '-webkit-font-smoothing' => 'antialiased',
            '-moz-osx-font-smoothing' => 'grayscale'
        ],
        'code' => [
            'font-family' => "source-code-pro, Menlo, Monaco, Consolas, 'Courier New', monospace"
        ]
    ];

    $output = '';
    
    foreach ($css as $selector => $properties) {
        $output .= $selector . " {\n";
        foreach ($properties as $property => $value) {
            $output .= "  " . $property . ": " . $value . ";\n";
        }
        $output .= "}\n\n";
    }

    file_put_contents($filename, rtrim($output));
}

// Wenn das Skript direkt aufgerufen wird, erzeuge die CSS-Datei
if (basename(__FILE__) === basename($_SERVER['SCRIPT_NAME'])) {
    $filename = $argv[1] ?? 'index.css';
    generateCSS($filename);
}

?>
