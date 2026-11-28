<?php
// abstraction-provenance: {"artifact_sha256": "b80d4fc0cc6a0f26a0f6adb5e44cc82308da54435c5bff34bdf41ea43670aa91", "source_sha256": "9ed2bdeb80b99c649aeb5bf47416f21d76279e40bca0b04d2f75f7e1afd3a910", "target_language": "php"}
// index_81ff5e.css — portiert nach php
// Quelle: css, Projects@abstractions:css/index_81ff5e.css
// Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py
function generateCSS($outputFile) {
    $css = [
        ':root' => [
            'color-scheme' => 'light',
            '--ink' => '#1b1c1f',
            '--muted' => '#6c6e75',
            '--faint' => '#9a9ca3',
            '--card' => '#fff',
            '--line' => '#e9eaee',
            '--accent' => '#5b5bd6',
            '--accent2' => '#7c5cff',
            '--ok' => '#22a06b',
            '--err' => '#e0533d',
            '--radius' => '16px',
            '--shadow' => '0 1px 2px rgba(20, 20, 40, 0.04), 0 6px 20px rgba(20, 20, 40, 0.06)'
        ],
        '*' => [
            'box-sizing' => 'border-box'
        ],
        'body' => [
            'margin' => '0',
            'font-family' => '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif',
            'color' => 'var(--ink)',
            'min-height' => '100vh',
            'background' => 'radial-gradient(1100px 560px at 100% -10%, #e8ecff 0%, rgba(232, 236, 255, 0) 55%), linear-gradient(180deg, #eef1f6, #f7f7f8 42%)',
            'background-attachment' => 'fixed'
        ],
        '.wrap' => [
            'max-width' => '820px',
            'margin' => '0 auto',
            'padding' => '24px 18px 70px'
        ],
        '.brand' => [
            'display' => 'flex',
            'align-items' => 'center',
            'gap' => '12px',
            'margin-bottom' => '4px'
        ],
        '.mark' => [
            'width' => '32px',
            'height' => '32px',
            'border-radius' => '9px',
            'background' => 'linear-gradient(135deg, var(--accent), var(--accent2))',
            'box-shadow' => '0 4px 12px rgba(91, 91, 214, 0.35)',
            'position' => 'relative',
            'flex' => '0 0 auto'
        ],
        '.mark:after' => [
            'content' => '""',
            'position' => 'absolute',
            'inset' => '8px',
            'border-radius' => '4px',
            'border' => '2px solid rgba(255, 255, 255, 0.92)'
        ],
        'h1' => [
            'font-size' => '21px',
            'margin' => '0',
            'font-weight' => '700'
        ],
        '.sub' => [
            'color' => 'var(--muted)',
            'font-size' => '13px',
            'margin' => '2px 0 16px'
        ],
        '.card' => [
            'background' => 'var(--card)',
            'border' => '1px solid var(--line)',
            'border-radius' => 'var(--radius)',
            'box-shadow' => 'var(--shadow)',
            'padding' => '16px',
            'margin-bottom' => '14px'
        ],
        '.card h2' => [
            'font-size' => '14px',
            'margin' => '0 0 10px'
        ],
        'label.lab' => [
            'display' => 'block',
            'font-size' => '12px',
            'font-weight' => '600',
            'color' => 'var(--muted)',
            'margin' => '8px 0 3px'
        ],
        'input' => [
            'width' => '100%',
            'font-size' => '13px',
            'padding' => '8px 10px',
            'border' => '1px solid var(--line)',
            'border-radius' => '9px',
            'font-family' => 'ui-monospace, Menlo, Consolas, monospace',
            'background' => '#fff'
        ],
        'textarea' => [
            'width' => '100%',
            'font-size' => '13px',
            'padding' => '8px 10px',
            'border' => '1px solid var(--line)',
            'border-radius' => '9px',
            'font-family' => 'ui-monospace, Menlo, Consolas, monospace',
            'background' => '#fff',
            'min-height' => '90px',
            'white-space' => 'pre',
            'overflow' => 'auto'
        ],
        '.row' => [
            'display' => 'flex',
            'gap' => '8px',
            'flex-wrap' => 'wrap',
            'align-items' => 'center'
        ],
        '.btn' => [
            'font-size' => '13px',
            'font-weight' => '600',
            'padding' => '8px 14px',
            'border' => '1px solid var(--line)',
            'border-radius' => '10px',
            'background' => '#fff',
            'cursor' => 'pointer',
            'box-shadow' => 'var(--shadow)',
            'transition' => 'transform 0.1s'
        ],
        '.btn:hover' => [
            'transform' => 'translateY(-1px)'
        ],
        '.btn.primary' => [
            'background' => 'linear-gradient(135deg, var(--accent), var(--accent2))',
            'color' => '#fff',
            'border-color' => 'transparent'
        ],
        '.btn.sm' => [
            'padding' => '5px 9px',
            'font-size' => '12px'
        ],
        '.msg' => [
            'font-size' => '12px',
            'margin-left' => '6px'
        ],
        '.msg.ok' => [
            'color' => 'var(--ok)'
        ],
        '.msg.err' => [
            'color' => 'var(--err)'
        ],
        '.prov' => [
            'border' => '1px solid var(--line)',
            'border-radius' => '12px',
            'padding' => '10px 12px',
            'margin-bottom' => '10px'
        ],
        '.prov h3' => [
            'margin' => '0 0 6px',
            'font-size' => '13.5px',
            'display' => 'flex',
            'align-items' => 'center',
            'gap' => '8px'
        ],
        '.kv' => [
            'display' => 'grid',
            'grid-template-columns' => '180px 1fr auto',
            'gap' => '6px',
            'margin' => '4px 0',
            'align-items' => 'center'
        ],
        '.kv input' => [
            'font-size' => '12px',
            'padding' => '5px 7px'
        ],
        '.kv .k' => [
            'color' => 'var(--muted)',
            'font-weight' => '600'
        ],
        '.muted' => [
            'color' => 'var(--faint)',
            'font-size' => '13px'
        ],
        '.hide' => [
            'display' => 'none'
        ],
        '.foot' => [
            'color' => 'var(--faint)',
            'font-size' => '11.5px',
            'text-align' => 'center',
            'margin-top' => '18px',
            'line-height' => '1.5'
        ],
        'a' => [
            'color' => 'var(--accent)'
        ]
    ];

    // Generate CSS output
    $output = "/* abstraction-provenance: {\"artifact_sha256\": \"6c7bf507504ec73409a080d09a27627c41cdd58e5cad63094e66d411e563bbf9\", \"source_sha256\": \"81ff5e370288082827f95b7b3dc2b94ce16d7710bcedcfd099f0ea81805a7d12\", \"target_language\": \"css\"} */\n";
    $output .= "/* index.html — portiert nach css */\n";
    $output .= "/* Quelle: html, Projects@secret-vault-public:secret-vault-public/index.html */\n";
    $output .= "/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */\n\n";

    foreach ($css as $selector => $properties) {
        $output .= "$selector {\n";
        foreach ($properties as $property => $value) {
            $output .= "  $property: $value;\n";
        }
        $output .= "}\n\n";
    }

    // Write to file
    file_put_contents($outputFile, $output);
}

// Wenn das Skript direkt aufgerufen wird
if (basename(__FILE__) == basename($_SERVER['SCRIPT_NAME'])) {
    $outputFile = $argv[1] ?? 'index_81ff5e.css';
    generateCSS($outputFile);
}

?>
