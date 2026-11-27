<?php
// abstraction-provenance: {"artifact_sha256": "a063b651c9f0c6df9605e893c477972ac8d1c5e0ce3286db7d4c6f65847e32f2", "source_sha256": "9be2a45ff3b835da1be1793cc88c8cb54d6a2456cf2ccc358c8243df836440e3", "target_language": "php"}
// status-overview-panel.css — portiert nach php
// Quelle: css, Projects@TikTok-Live-Companion:plugin-source/browser-extension/status-overview-panel.css
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py
function writeCssToFile($filename) {
    $cssRules = [
        '.overview-row' => [
            'display' => 'grid',
            'grid-template-columns' => '24px minmax(0,1fr) 11px 22px auto',
            'gap' => '7px',
            'align-items' => 'center',
            'margin' => '6px 0'
        ],
        '.overview-row input' => [
            'min-width' => '0',
            'width' => '100%'
        ],
        '.overview-state' => [
            'width' => '11px',
            'height' => '11px',
            'border-radius' => '50%',
            'background' => '#888'
        ],
        '.overview-state.online' => [
            'background' => 'var(--good)',
            'box-shadow' => '0 0 0 3px color-mix(in srgb, var(--good) 15%, transparent)'
        ],
        '.overview-state.offline' => [
            'background' => 'var(--bad)',
            'box-shadow' => '0 0 0 3px color-mix(in srgb, var(--bad) 15%, transparent)'
        ],
        '.overview-state.checking, .overview-state.error' => [
            'background' => 'var(--warn)'
        ],
        '.overview-count' => [
            'font-size' => '11px',
            'text-align' => 'center',
            'font-variant-numeric' => 'tabular-nums'
        ],
        '.overview-actions' => [
            'display' => 'grid',
            'grid-template-columns' => '44px repeat(2,minmax(0,1fr))',
            'gap' => '6px',
            'align-items' => 'stretch'
        ],
        '.overview-actions button' => [
            'min-width' => '0',
            'padding' => '8px 2px',
            'font-size' => '11px',
            'white-space' => 'nowrap'
        ],
        '#overview-rows' => [
            'display' => 'flex',
            'flex-direction' => 'column'
        ],
        '.monitor-settings > label:not(.option-row)' => [
            'display' => 'block',
            'margin' => '12px 0'
        ],
        '.monitor-settings .option-row input' => [
            'appearance' => 'auto',
            'width' => '13px',
            'height' => '13px',
            'min-width' => '13px',
            'background' => 'none'
        ],
        '.overview-link' => [
            'padding' => '8px 0',
            'border-bottom' => '1px solid #bbb',
            'overflow-wrap' => 'anywhere'
        ],
        '.overview-link p' => [
            'margin' => '4px 0'
        ],
        '.overview-row .overview-retry' => [
            'width' => '24px',
            'min-width' => '24px',
            'height' => '26px',
            'min-height' => '26px',
            'padding' => '0',
            'background-image' => 'var(--icon-reset)',
            'background-size' => '20px',
            'background-position' => 'center',
            'background-repeat' => 'no-repeat'
        ],
        '.top-setting input' => [
            'appearance' => 'auto',
            '-webkit-appearance' => 'checkbox',
            'width' => '13px',
            'height' => '13px',
            'min-width' => '13px',
            'background' => 'none'
        ],
        '.overview-visually-hidden' => [
            'position' => 'absolute',
            'width' => '1px',
            'height' => '1px',
            'padding' => '0',
            'margin' => '-1px',
            'overflow' => 'hidden',
            'clip' => 'rect(0,0,0,0)',
            'white-space' => 'nowrap',
            'border' => '0'
        ],
        '.overview-row[hidden]' => [
            'display' => 'none'
        ]
    ];

    $cssContent = '';
    
    foreach ($cssRules as $selector => $properties) {
        $cssContent .= $selector . ' {';
        foreach ($properties as $property => $value) {
            $cssContent .= $property . ':' . $value . '; ';
        }
        $cssContent = rtrim($cssContent) . ";}\n";
    }

    file_put_contents($filename, $cssContent);
}

if (isset($argv[1])) {
    writeCssToFile($argv[1]);
} else {
    echo "Bitte geben Sie einen Dateinamen als Parameter an.\n";
}

?>
