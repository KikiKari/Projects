<?php
// abstraction-provenance: {"artifact_sha256": "7052c3e1ec9b7d0d32bc85769a79de2fcea31f19aae9040ee37b87abac04e99a", "source_sha256": "470ecd5aad55c517d9e61935d3422a32740607ef531514fee63990c26ee64839", "target_language": "php"}
// kontaktbogen.css — portiert nach php
// Quelle: css, Projects@abstractions:css/kontaktbogen.css
// Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py
function generateCSS($outputFile) {
    $css = [
        ':root' => [
            '--bg' => '#FAF8F4',
            '--ink' => '#1B1A17',
            '--muted' => '#6E6A61',
            '--line' => '#E5E1D8',
            '--accent' => '#A8542F',
            '--accent-2' => '#2E7D7B',
            '--surface' => '#fff'
        ],
        
        '*' => [
            'box-sizing' => 'border-box'
        ],
        
        'body' => [
            'margin' => '0',
            'font-family' => "'Hanken Grotesk', system-ui, sans-serif",
            'background' => 'var(--bg)',
            'color' => 'var(--ink)',
            'line-height' => '1.5'
        ],
        
        'header' => [
            'padding' => '2.5rem 2rem 1rem',
            'border-bottom' => '1px solid var(--line)',
            'background' => 'var(--surface)',
            'position' => 'sticky',
            'top' => '0',
            'z-index' => '10'
        ],
        
        'header h1' => [
            'margin' => '0 0 .5rem',
            'font-family' => "'Newsreader', Georgia, serif",
            'font-weight' => '400',
            'font-size' => '2.25rem'
        ],
        
        'header p' => [
            'margin' => '.25rem 0',
            'color' => 'var(--muted)',
            'max-width' => '80ch'
        ],
        
        '.legend' => [
            'display' => 'flex',
            'gap' => '1rem',
            'flex-wrap' => 'wrap',
            'margin-top' => '.75rem',
            'font-size' => '.8125rem'
        ],
        
        '.pill' => [
            'padding' => '.15rem .6rem',
            'border-radius' => '999px',
            'border' => '1px solid var(--line)',
            'background' => '#fff'
        ],
        
        '.pill.pflicht' => [
            'border-color' => 'var(--accent)',
            'color' => 'var(--accent)',
            'font-weight' => '600'
        ],
        
        '.pill.auswahl' => [
            'border-color' => 'var(--accent-2)',
            'color' => 'var(--accent-2)',
            'font-weight' => '600'
        ],
        
        'main' => [
            'padding' => '2rem',
            'max-width' => '1400px',
            'margin' => '0 auto'
        ],
        
        'section' => [
            'margin' => '2.5rem 0'
        ],
        
        'section h2' => [
            'font-family' => "'Newsreader', serif",
            'font-weight' => '400',
            'font-size' => '1.5rem',
            'margin' => '0 0 .25rem',
            'display' => 'flex',
            'align-items' => 'center',
            'gap' => '.75rem'
        ],
        
        'section .sub' => [
            'color' => 'var(--muted)',
            'font-size' => '.875rem',
            'margin' => '0 0 1.25rem'
        ],
        
        '.grid' => [
            'display' => 'grid',
            'grid-template-columns' => 'repeat(auto-fill, minmax(240px, 1fr))',
            'gap' => '1rem'
        ],
        
        '.card' => [
            'background' => 'var(--surface)',
            'border' => '1px solid var(--line)',
            'border-radius' => '10px',
            'overflow' => 'hidden',
            'display' => 'flex',
            'flex-direction' => 'column'
        ],
        
        '.card .imgwrap' => [
            'aspect-ratio' => '1',
            'background' => '#f1eee7',
            'display' => 'flex',
            'align-items' => 'center',
            'justify-content' => 'center',
            'overflow' => 'hidden'
        ],
        
        '.card img' => [
            'width' => '100%',
            'height' => '100%',
            'object-fit' => 'contain',
            'background' => '#fff'
        ],
        
        '.card .meta' => [
            'padding' => '.6rem .75rem .75rem',
            'font-size' => '.78125rem'
        ],
        
        '.card .name' => [
            'font-family' => "'JetBrains Mono', monospace",
            'font-size' => '.6875rem',
            'color' => 'var(--muted)',
            'word-break' => 'break-all',
            'line-height' => '1.3',
            'margin-bottom' => '.35rem'
        ],
        
        '.card .dims' => [
            'color' => 'var(--muted)',
            'font-size' => '.6875rem',
            'margin-bottom' => '.35rem'
        ],
        
        '.card .prompt' => [
            'color' => 'var(--ink)',
            'font-size' => '.75rem',
            'line-height' => '1.35',
            'font-style' => 'italic',
            'border-top' => '1px solid var(--line)',
            'padding-top' => '.4rem',
            'margin-top' => '.35rem',
            'max-height' => '5.5em',
            'overflow' => 'hidden'
        ],
        
        '.tag' => [
            'display' => 'inline-block',
            'padding' => '.1rem .45rem',
            'border-radius' => '999px',
            'font-size' => '.6875rem',
            'background' => '#F1EEE7',
            'color' => 'var(--muted)',
            'margin-right' => '.25rem'
        ],
        
        '.tag.p' => [
            'background' => '#F1E5DD',
            'color' => 'var(--accent)'
        ],
        
        '.tag.a' => [
            'background' => '#DEEDEC',
            'color' => 'var(--accent-2)'
        ]
    ];

    // Generate CSS content
    $content = "/* abstraction-provenance: {\"artifact_sha256\": \"450641e159859fa2b6c4bef0c3cf3d2fc42700f880b018b48996ee2e02d23ab2\", \"source_sha256\": \"ca574d779b67b58a38559123215e116d8c6e2ef4c122350bb69958e8a6423187\", \"target_language\": \"css\"} */\n";
    $content .= "/* kontaktbogen.html — portiert nach css */\n";
    $content .= "/* Quelle: html, Onboarding@main:development/contactsheets/v1/kontaktbogen.html */\n";
    $content .= "/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */\n\n";

    foreach ($css as $selector => $properties) {
        $content .= "$selector {\n";
        foreach ($properties as $property => $value) {
            $content .= "  $property: $value;\n";
        }
        $content .= "}\n\n";
    }

    // Write to file
    file_put_contents($outputFile, $content);
}

// Check if output file is provided as argument
if ($argc < 2) {
    echo "Usage: php " . $argv[0] . " <output-file>\n";
    exit(1);
}

generateCSS($argv[1]);

?>
