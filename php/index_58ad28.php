<?php
// abstraction-provenance: {"artifact_sha256": "0187a636bcaff381296496a2f7499bc786171c317d4efced4149b917484a346c", "source_sha256": "cbb5bc6a6daaf8b0fa22ba63f44d741131d32c58a9faab7d6cda9954587b0052", "target_language": "php"}
// index_58ad28.css — portiert nach php
// Quelle: css, Projects@abstractions:css/index_58ad28.css
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py
function generateCSS($filename = 'index_58ad28.css') {
    $css = [
        ':root' => [
            '--bg' => '#ffffff',
            '--soft' => '#f6f7f9',
            '--line' => '#e3e6ea',
            '--text' => '#16191d',
            '--muted' => '#5f6773',
            '--tg' => '#2481cc',
            '--tg-soft' => '#e8f2fb',
            '--tt' => '#fe2c55',
            '--ok' => '#15803d',
            '--ok-soft' => '#e7f6ec',
            '--warn' => '#b45309',
            '--warn-soft' => '#fdf3e3',
            'color-scheme' => 'light'
        ],
        '@media (prefers-color-scheme: dark)' => [
            ':root' => [
                '--bg' => '#0f1115',
                '--soft' => '#171a21',
                '--line' => '#262b36',
                '--text' => '#f2f4f8',
                '--muted' => '#9aa3b2',
                '--tg-soft' => '#132a3d',
                '--ok-soft' => '#12261a',
                '--warn-soft' => '#2c2110',
                'color-scheme' => 'dark'
            ]
        ],
        '*' => [
            'box-sizing' => 'border-box'
        ],
        'body' => [
            'margin' => '0',
            'background' => 'var(--bg)',
            'color' => 'var(--text)',
            'font' => '16px/1.6 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif'
        ],
        '.wrap' => [
            'max-width' => '820px',
            'margin' => '0 auto',
            'padding' => '0 20px 72px'
        ],
        'header' => [
            'padding' => '64px 0 40px',
            'border-bottom' => '1px solid var(--line)',
            'margin-bottom' => '8px'
        ],
        'h1' => [
            'font-size' => '34px',
            'line-height' => '1.2',
            'margin' => '0 0 12px',
            'letter-spacing' => '-0.02em'
        ],
        '.lede' => [
            'font-size' => '18px',
            'color' => 'var(--muted)',
            'margin' => '0 0 22px',
            'max-width' => '60ch'
        ],
        'h2' => [
            'font-size' => '13px',
            'margin' => '44px 0 14px',
            'text-transform' => 'uppercase',
            'letter-spacing' => '0.06em',
            'color' => 'var(--muted)',
            'font-weight' => '650'
        ],
        'h3' => [
            'font-size' => '17px',
            'margin' => '26px 0 6px'
        ],
        'p' => [
            'margin' => '0 0 14px',
            'max-width' => '68ch'
        ],
        '.badges' => [
            'display' => 'flex',
            'gap' => '7px',
            'flex-wrap' => 'wrap',
            'margin-bottom' => '22px'
        ],
        '.badge' => [
            'font-size' => '12px',
            'font-weight' => '650',
            'padding' => '4px 11px',
            'border-radius' => '99px',
            'background' => 'var(--soft)',
            'color' => 'var(--muted)',
            'border' => '1px solid var(--line)'
        ],
        '.badge.on' => [
            'background' => 'var(--ok-soft)',
            'color' => 'var(--ok)',
            'border-color' => 'transparent'
        ],
        '.cta' => [
            'display' => 'flex',
            'gap' => '10px',
            'flex-wrap' => 'wrap'
        ],
        '.btn' => [
            'display' => 'inline-block',
            'font-weight' => '650',
            'font-size' => '15px',
            'padding' => '11px 20px',
            'border-radius' => '9px',
            'text-decoration' => 'none',
            'border' => '1px solid var(--line)',
            'background' => 'var(--bg)',
            'color' => 'var(--text)'
        ],
        '.btn.primary' => [
            'background' => 'var(--tg)',
            'border-color' => 'var(--tg)',
            'color' => '#fff'
        ],
        '.btn:hover' => [
            'border-color' => 'var(--tg)'
        ],
        '.grid' => [
            'display' => 'grid',
            'grid-template-columns' => 'repeat(auto-fit, minmax(230px, 1fr))',
            'gap' => '14px'
        ],
        '.card' => [
            'border' => '1px solid var(--line)',
            'border-radius' => '12px',
            'padding' => '16px 18px',
            'background' => 'var(--bg)'
        ],
        '.card h3' => [
            'margin-top' => '0',
            'font-size' => '15.5px'
        ],
        '.card p' => [
            'font-size' => '14px',
            'color' => 'var(--muted)',
            'margin' => '0'
        ],
        'ol.steps' => [
            'list-style' => 'none',
            'counter-reset' => 's',
            'padding' => '0',
            'margin' => '0'
        ],
        'ol.steps li' => [
            'counter-increment' => 's',
            'position' => 'relative',
            'padding' => '0 0 20px 40px',
            'border-left' => '2px solid var(--line)',
            'margin-left' => '11px'
        ],
        'ol.steps li:last-child' => [
            'border-left-color' => 'transparent',
            'padding-bottom' => '0'
        ],
        'ol.steps li::before' => [
            'content' => 'counter(s)',
            'position' => 'absolute',
            'left' => '-13px',
            'top' => '0',
            'width' => '24px',
            'height' => '24px',
            'border-radius' => '50%',
            'background' => 'var(--tg)',
            'color' => '#fff',
            'display' => 'flex',
            'align-items' => 'center',
            'justify-content' => 'center',
            'font-size' => '12px',
            'font-weight' => '700'
        ],
        'ol.steps b' => [
            'display' => 'block',
            'margin-bottom' => '3px'
        ],
        'ol.steps p' => [
            'font-size' => '14.5px',
            'color' => 'var(--muted)',
            'margin' => '0 0 8px'
        ],
        'code' => [
            'background' => 'var(--soft)',
            'padding' => '2px 7px',
            'border-radius' => '5px',
            'font-size' => '13.5px',
            'font-family' => 'ui-monospace, SFMono-Regular, Menlo, monospace',
            'word-break' => 'break-word'
        ],
        'pre' => [
            'background' => 'var(--soft)',
            'border' => '1px solid var(--line)',
            'border-radius' => '10px',
            'padding' => '13px 15px',
            'overflow-x' => 'auto',
            'margin' => '0 0 14px'
        ],
        'pre code' => [
            'background' => 'none',
            'padding' => '0',
            'font-size' => '13.5px',
            'line-height' => '1.7'
        ],
        'table' => [
            'width' => '100%',
            'border-collapse' => 'collapse',
            'font-size' => '14.5px',
            'margin' => '0 0 16px'
        ],
        'th, td' => [
            'text-align' => 'left',
            'padding' => '9px 11px',
            'border-bottom' => '1px solid var(--line)',
            'vertical-align' => 'top'
        ],
        'th' => [
            'color' => 'var(--muted)',
            'font-size' => '12px',
            'text-transform' => 'uppercase',
            'letter-spacing' => '0.04em',
            'font-weight' => '650'
        ],
        '.note' => [
            'border-left' => '3px solid var(--warn)',
            'background' => 'var(--warn-soft)',
            'border-radius' => '0 9px 9px 0',
            'padding' => '13px 16px',
            'margin' => '0 0 16px',
            'font-size' => '14.5px'
        ],
        '.note b' => [
            'display' => 'block',
            'margin-bottom' => '3px'
        ],
        'a' => [
            'color' => 'var(--tg)'
        ],
        'footer' => [
            'margin-top' => '52px',
            'padding-top' => '22px',
            'border-top' => '1px solid var(--line)',
            'font-size' => '13.5px',
            'color' => 'var(--muted)'
        ]
    ];

    $output = "/* abstraction-provenance: {\"artifact_sha256\": \"537643848792cfff80c1482b508d158466cc91ff9b4bb017d27cc984f4a6b58f\", \"source_sha256\": \"58ad2830d3e11b79c54044cfe5a82e7e3fd2a9b1ca1f65c546ff6e92e821c6f3\", \"target_language\": \"css\"} */\n";
    $output .= "/* index.html — portiert nach css */\n";
    $output .= "/* Quelle: html, Projects@Telegram-Monitor:public/index.html */\n";
    $output .= "/* Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py */\n\n";

    foreach ($css as $selector => $properties) {
        if ($selector === '@media (prefers-color-scheme: dark)') {
            $output .= "@media (prefers-color-scheme: dark) {\n";
            foreach ($properties as $subSelector => $subProperties) {
                $output .= "  {$subSelector} {\n";
                foreach ($subProperties as $property => $value) {
                    $output .= "    {$property}: {$value};\n";
                }
                $output .= "  }\n";
            }
            $output .= "}\n\n";
        } else {
            $output .= "{$selector} {\n";
            foreach ($properties as $property => $value) {
                $output .= "  {$property}: {$value};\n";
            }
            $output .= "}\n\n";
        }
    }

    file_put_contents($filename, $output);
    return $output;
}

// Generate the CSS file
generateCSS();

?>
