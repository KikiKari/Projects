<?php
// abstraction-provenance: {"artifact_sha256": "ac4d91e9151e8d350c09ef9192761589edc2bf00debbbd9e5ef9136fce7d594c", "source_sha256": "78b518f6f68bf0f05a573239d113470b3f5a9440be7cff5f80bc8576462525c3", "target_language": "php"}
// node-monitor.css — portiert nach php
// Quelle: css, Projects@abstractions:css/node-monitor.css
// Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py
function generate_css($filename) {
    $css = [
        ':root' => [
            '--bg' => '#0d1117',
            '--surface' => '#161b22',
            '--border' => '#30363d',
            '--text' => '#e6edf3',
            '--green' => '#3fb950',
            '--red' => '#f85149',
            '--accent' => '#58a6ff'
        ],
        '*' => [
            'box-sizing' => 'border-box',
            'margin' => '0',
            'padding' => '0'
        ],
        'body' => [
            'background' => 'var(--bg)',
            'color' => 'var(--text)',
            'font-family' => '-apple-system, sans-serif',
            'padding' => '1.5rem'
        ],
        'h1' => [
            'color' => 'var(--accent)',
            'margin-bottom' => '1rem',
            'font-size' => '1.2rem'
        ],
        'canvas' => [
            'display' => 'block',
            'border' => '1px solid var(--border)',
            'border-radius' => '8px',
            'background' => 'var(--surface)'
        ],
        '#log' => [
            'margin-top' => '1rem',
            'height' => '140px',
            'overflow-y' => 'auto',
            'background' => 'var(--surface)',
            'border' => '1px solid var(--border)',
            'border-radius' => '8px',
            'padding' => '.75rem',
            'font-size' => '.78rem',
            'font-family' => 'monospace',
            'color' => '#8b949e'
        ],
        '#log .err' => [
            'color' => 'var(--red)'
        ],
        '#log .ok' => [
            'color' => 'var(--green)'
        ]
    ];

    $output = "/* abstraction-provenance: {\"artifact_sha256\": \"37bc702d7c4046193f78406172db9f9b81e5951260071773ee3519d55f802128\", \"source_sha256\": \"ed59efd19fa280b88488d50ce98f4213a84c5f833eacd98c7cb448f570c805fe\", \"target_language\": \"css\"} */\n";
    $output .= "/* node-monitor.html — portiert nach css */\n";
    $output .= "/* Quelle: html, OpenClaw@main:examples/node-monitor.html */\n";
    $output .= "/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */\n\n";

    foreach ($css as $selector => $rules) {
        $output .= "$selector {\n";
        foreach ($rules as $property => $value) {
            $output .= "  $property: $value;\n";
        }
        $output .= "}\n\n";
    }

    file_put_contents($filename, $output);
}

// Beispielaufruf:
// generate_css('node-monitor.css');

?>
