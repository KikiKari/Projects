<?php
// abstraction-provenance: {"artifact_sha256": "90e944806219dceac23aec4fa338e990f8512c2aac016993c847516cb2f0e19f", "source_sha256": "618fbec1aa70b1376cdfa3b8809f339c78f591a33e1ef35fb84ee21ffcdc97cf", "target_language": "php"}
// periodensystem.css — portiert nach php
// Quelle: css, Projects@abstractions:css/periodensystem.css
// Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py
function generatePeriodensystemCSS($outputFile) {
    $css = [
        'reset' => [
            '*' => [
                'box-sizing' => 'border-box',
                'margin' => '0',
                'padding' => '0'
            ]
        ],
        
        'variables_light' => [
            ':root' => [
                '--bg' => '#fafaf7',
                '--surface' => '#ffffff',
                '--border' => 'rgba(0,0,0,0.12)',
                '--text' => '#1a1a1a',
                '--text-muted' => '#666'
            ]
        ],
        
        'variables_dark' => [
            '@media (prefers-color-scheme: dark)' => [
                ':root' => [
                    '--bg' => '#1a1a1a',
                    '--surface' => '#242424',
                    '--border' => 'rgba(255,255,255,0.15)',
                    '--text' => '#f0f0f0',
                    '--text-muted' => '#aaa'
                ]
            ]
        ],
        
        'body' => [
            'body' => [
                'font-family' => "-apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif",
                'background' => 'var(--bg)',
                'color' => 'var(--text)',
                'padding' => '24px',
                'max-width' => '1100px',
                'margin' => '0 auto',
                'line-height' => '1.5'
            ]
        ],
        
        'headings' => [
            'h1' => [
                'font-size' => '22px',
                'font-weight' => '500',
                'margin-bottom' => '4px'
            ],
            '.subtitle' => [
                'color' => 'var(--text-muted)',
                'font-size' => '14px',
                'margin-bottom' => '20px'
            ]
        ],
        
        'detail' => [
            '.detail' => [
                'background' => 'var(--surface)',
                'border' => '1px solid var(--border)',
                'border-radius' => '12px',
                'padding' => '16px 20px',
                'min-height' => '110px',
                'display' => 'flex',
                'align-items' => 'center',
                'gap' => '20px',
                'margin-bottom' => '16px'
            ],
            '.detail-empty' => [
                'color' => 'var(--text-muted)',
                'font-size' => '14px',
                'text-align' => 'center',
                'width' => '100%'
            ]
        ],
        
        'symbol_box' => [
            '.symbol-box' => [
                'font-size' => '40px',
                'font-weight' => '500',
                'line-height' => '1',
                'width' => '80px',
                'height' => '80px',
                'display' => 'flex',
                'align-items' => 'center',
                'justify-content' => 'center',
                'border-radius' => '8px',
                'flex-shrink' => '0'
            ]
        ],
        
        'info' => [
            '.info-name' => [
                'font-size' => '20px',
                'font-weight' => '500',
                'margin-bottom' => '8px'
            ],
            '.info-meta' => [
                'font-size' => '13px',
                'color' => 'var(--text-muted)',
                'display' => 'grid',
                'grid-template-columns' => 'repeat(2, minmax(0, 1fr))',
                'gap' => '4px 24px'
            ],
            '.info-meta b' => [
                'font-weight' => '500',
                'color' => 'var(--text)',
                'margin-left' => '6px'
            ]
        ],
        
        'grid' => [
            '.grid' => [
                'display' => 'grid',
                'grid-template-columns' => 'repeat(18, minmax(0, 1fr))',
                'gap' => '3px'
            ],
            '.fgrid' => [
                'margin-top' => '8px'
            ]
        ],
        
        'cell' => [
            '.cell' => [
                'aspect-ratio' => '1',
                'border-radius' => '4px',
                'padding' => '3px',
                'display' => 'flex',
                'flex-direction' => 'column',
                'align-items' => 'center',
                'justify-content' => 'center',
                'cursor' => 'pointer',
                'font-family' => 'inherit',
                'line-height' => '1',
                'transition' => 'transform 0.12s ease',
                'border' => '0',
                'position' => 'relative',
                'overflow' => 'hidden'
            ],
            '.cell:hover' => [
                'transform' => 'scale(1.18)',
                'z-index' => '5',
                'box-shadow' => '0 2px 8px rgba(0,0,0,0.15)'
            ],
            '.cell:focus-visible' => [
                'outline' => '2px solid var(--text)',
                'outline-offset' => '1px'
            ],
            '.cell.active' => [
                'outline' => '2px solid var(--text)',
                'outline-offset' => '1px',
                'z-index' => '4'
            ],
            '.cell .num' => [
                'font-size' => '9px',
                'opacity' => '0.75',
                'align-self' => 'flex-start',
                'line-height' => '1',
                'padding-left' => '2px'
            ],
            '.cell .sym' => [
                'font-size' => '14px',
                'font-weight' => '500',
                'margin-top' => '2px'
            ]
        ],
        
        'marker' => [
            '.cell-marker' => [
                'cursor' => 'default',
                'font-size' => '9px',
                'font-weight' => '500',
                'border' => '1px dashed currentColor',
                'background' => 'transparent !important'
            ],
            '.cell-marker:hover' => [
                'transform' => 'none',
                'box-shadow' => 'none'
            ]
        ],
        
        'categories_light' => [
            '.cat-am' => ['background' => '#FCEBEB', 'color' => '#501313'],
            '.cat-em' => ['background' => '#FAEEDA', 'color' => '#412402'],
            '.cat-tm' => ['background' => '#E6F1FB', 'color' => '#042C53'],
            '.cat-ptm' => ['background' => '#F1EFE8', 'color' => '#2C2C2A'],
            '.cat-hm' => ['background' => '#E1F5EE', 'color' => '#04342C'],
            '.cat-nm' => ['background' => '#EAF3DE', 'color' => '#173404'],
            '.cat-h' => ['background' => '#EEEDFE', 'color' => '#26215C'],
            '.cat-eg' => ['background' => '#FBEAF0', 'color' => '#4B1528'],
            '.cat-la' => ['background' => '#FAECE7', 'color' => '#4A1B0C'],
            '.cat-ac' => ['background' => '#F5C4B3', 'color' => '#4A1B0C']
        ],
        
        'categories_dark' => [
            '@media (prefers-color-scheme: dark)' => [
                '.cat-am' => ['background' => '#791F1F', 'color' => '#F7C1C1'],
                '.cat-em' => ['background' => '#633806', 'color' => '#FAC775'],
                '.cat-tm' => ['background' => '#0C447C', 'color' => '#B5D4F4'],
                '.cat-ptm' => ['background' => '#444441', 'color' => '#D3D1C7'],
                '.cat-hm' => ['background' => '#085041', 'color' => '#9FE1CB'],
                '.cat-nm' => ['background' => '#27500A', 'color' => '#C0DD97'],
                '.cat-h' => ['background' => '#3C3489', 'color' => '#CECBF6'],
                '.cat-eg' => ['background' => '#72243E', 'color' => '#F4C0D1'],
                '.cat-la' => ['background' => '#712B13', 'color' => '#F5C4B3'],
                '.cat-ac' => ['background' => '#993C1D', 'color' => '#F5C4B3']
            ]
        ],
        
        'legend' => [
            '.legend' => [
                'display' => 'grid',
                'grid-template-columns' => 'repeat(auto-fit, minmax(160px, 1fr))',
                'gap' => '8px 16px',
                'margin-top' => '24px',
                'font-size' => '12px',
                'color' => 'var(--text-muted)'
            ],
            '.legend-item' => [
                'display' => 'flex',
                'align-items' => 'center',
                'gap' => '8px'
            ],
            '.legend-swatch' => [
                'width' => '14px',
                'height' => '14px',
                'border-radius' => '3px',
                'flex-shrink' => '0'
            ]
        ]
    ];

    $output = "/* abstraction-provenance: {\"artifact_sha256\": \"57a7240136c3ce381e11df3125a02154266008c65c09f97475511fe273d71a65\", \"source_sha256\": \"dd2fb3ad5bb22a75afbf2a71e58025215a6cba660525d3fa1c6b4ea12fc311fb\", \"target_language\": \"css\"} */\n";
    $output .= "/* periodensystem.html — portiert nach css */\n";
    $output .= "/* Quelle: html, Onboarding@main:docs/reference-library/examples/periodensystem.html */\n";
    $output .= "/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */\n\n";

    foreach ($css as $section => $rules) {
        foreach ($rules as $selector => $properties) {
            if (strpos($selector, '@media') === 0) {
                $output .= "{$selector} {\n";
                foreach ($properties as $subSelector => $subProperties) {
                    $output .= "  {$subSelector} {\n";
                    foreach ($subProperties as $prop => $value) {
                        $output .= "    {$prop}: {$value};\n";
                    }
                    $output .= "  }\n";
                }
                $output .= "}\n";
            } else {
                $output .= "{$selector} {\n";
                foreach ($properties as $prop => $value) {
                    $output .= "  {$prop}: {$value};\n";
                }
                $output .= "}\n";
            }
        }
        $output .= "\n";
    }

    file_put_contents($outputFile, $output);
}

// Wenn das Skript direkt aufgerufen wird
if (isset($argv[1])) {
    generatePeriodensystemCSS($argv[1]);
} else {
    echo "Verwendung: php " . basename(__FILE__) . " <ausgabedatei>\n";
}

?>
