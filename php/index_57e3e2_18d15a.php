<?php
// abstraction-provenance: {"artifact_sha256": "dda65a2414004557a2d836bd696ced0281439a661b395f751295b0ed2b981296", "source_sha256": "18d15a289b831c9da96c808e0cc1de4dae7bf3dfc35a804a239a992cd82cde89", "target_language": "php"}
// index_57e3e2.css — portiert nach php
// Quelle: css, Projects@abstractions:css/index_57e3e2.css
// Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py
class CSSGenerator {
    private $rules = [];

    public function __construct() {
        $this->initializeCSSRules();
    }

    private function initializeCSSRules() {
        // Root
        $this->rules[':root'] = [
            'color-scheme' => 'light'
        ];

        // Universal selector
        $this->rules['*'] = [
            'box-sizing' => 'border-box'
        ];

        // Body
        $this->rules['body'] = [
            'margin' => '0',
            'font-family' => '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif',
            'background' => '#f7f7f5',
            'color' => '#1d1c1a'
        ];

        // Wrap
        $this->rules['.wrap'] = [
            'max-width' => '880px',
            'margin' => '0 auto',
            'padding' => '20px 16px 60px'
        ];

        // Headings
        $this->rules['h1'] = [
            'font-size' => '22px',
            'margin' => '0 0 2px'
        ];

        $this->rules['.sub'] = [
            'color' => '#6b6a66',
            'font-size' => '13px',
            'margin-bottom' => '16px'
        ];

        // Bar
        $this->rules['.bar'] = [
            'display' => 'flex',
            'gap' => '10px',
            'align-items' => 'center',
            'margin-bottom' => '16px',
            'flex-wrap' => 'wrap'
        ];

        // Buttons
        $this->rules['button'] = [
            'font-size' => '13px',
            'font-weight' => '600',
            'padding' => '7px 13px',
            'border' => '1px solid #d9d8d3',
            'border-radius' => '8px',
            'background' => '#fff',
            'cursor' => 'pointer'
        ];

        $this->rules['button:hover'] = [
            'background' => '#f2f1ec'
        ];

        $this->rules['button.primary'] = [
            'background' => '#1d1c1a',
            'color' => '#fff',
            'border-color' => '#1d1c1a'
        ];

        // Note
        $this->rules['.note'] = [
            'background' => '#fffdf4',
            'border' => '1px solid #f0e9c8',
            'border-radius' => '10px',
            'padding' => '12px 14px',
            'font-size' => '13px',
            'color' => '#4a4734',
            'margin-bottom' => '16px',
            'line-height' => '1.5'
        ];

        // Section
        $this->rules['.section'] = [
            'background' => '#fff',
            'border' => '1px solid #e8e7e3',
            'border-radius' => '12px',
            'margin-bottom' => '14px',
            'overflow' => 'hidden'
        ];

        $this->rules['.section > h2'] = [
            'font-size' => '15px',
            'margin' => '0',
            'padding' => '13px 16px',
            'border-bottom' => '1px solid #efeee9',
            'display' => 'flex',
            'align-items' => 'center',
            'gap' => '9px'
        ];

        $this->rules['.section > h2 .badge'] = [
            'margin-left' => 'auto',
            'font-size' => '12px',
            'font-weight' => '600',
            'background' => '#efeee9',
            'color' => '#5a5852',
            'padding' => '2px 9px',
            'border-radius' => '20px'
        ];

        // Body class
        $this->rules['.body'] = [
            'padding' => '8px 16px 14px',
            'font-size' => '14px'
        ];

        // Muted text
        $this->rules['.muted'] = [
            'color' => '#8a8884'
        ];

        // Error text
        $this->rules['.err'] = [
            'color' => '#c0392b'
        ];

        // Key-value pairs
        $this->rules['.kv'] = [
            'display' => 'flex',
            'justify-content' => 'space-between',
            'padding' => '4px 0',
            'border-bottom' => '1px solid #f4f3ee'
        ];

        $this->rules['.kv:last-child'] = [
            'border' => 'none'
        ];

        $this->rules['.kv .k'] = [
            'color' => '#6b6a66'
        ];

        $this->rules['.kv .v'] = [
            'font-weight' => '600'
        ];

        // Links
        $this->rules['a'] = [
            'color' => '#2b5cc4',
            'text-decoration' => 'none'
        ];

        $this->rules['a:hover'] = [
            'text-decoration' => 'underline'
        ];

        // Modal
        $this->rules['.modal'] = [
            'position' => 'fixed',
            'inset' => '0',
            'background' => 'rgba(0, 0, 0, .35)',
            'display' => 'none',
            'align-items' => 'flex-start',
            'justify-content' => 'center',
            'padding' => '40px 16px',
            'overflow' => 'auto'
        ];

        $this->rules['.modal.open'] = [
            'display' => 'flex'
        ];

        // Card
        $this->rules['.card'] = [
            'background' => '#fff',
            'border-radius' => '14px',
            'max-width' => '560px',
            'width' => '100%',
            'padding' => '20px'
        ];

        $this->rules['.card h3'] = [
            'margin' => '0 0 4px',
            'font-size' => '17px'
        ];

        $this->rules['.card p.hint'] = [
            'margin' => '0 0 16px',
            'font-size' => '12px',
            'color' => '#8a8884'
        ];

        // Form fields
        $this->rules['.field'] = [
            'margin-bottom' => '12px'
        ];

        $this->rules['.field label'] = [
            'display' => 'block',
            'font-size' => '12px',
            'font-weight' => '600',
            'color' => '#5a5852',
            'margin-bottom' => '3px'
        ];

        $this->rules['.field input'] = [
            'width' => '100%',
            'font-size' => '13px',
            'padding' => '7px 9px',
            'border' => '1px solid #d9d8d3',
            'border-radius' => '7px',
            'font-family' => 'ui-monospace, Menlo, monospace'
        ];

        $this->rules['.field .desc'] = [
            'font-size' => '11px',
            'color' => '#a8a6a1',
            'margin-top' => '2px'
        ];

        // Actions
        $this->rules['.actions'] = [
            'display' => 'flex',
            'gap' => '10px',
            'justify-content' => 'flex-end',
            'margin-top' => '8px'
        ];

        // Warning
        $this->rules['.warn'] = [
            'background' => '#fdf3f3',
            'border' => '1px solid #f3d9d9',
            'color' => '#9a3b3b',
            'border-radius' => '8px',
            'padding' => '10px 12px',
            'font-size' => '12px',
            'margin-bottom' => '14px'
        ];
    }

    public function generateCSS() {
        $output = "/* abstraction-provenance: {\"artifact_sha256\": \"a05439af4536c91ed01734c3151c3870ffe206fc2433d74fe3db29d4666579ca\", \"source_sha256\": \"57e3e28b7c96948ea289f7d9401b6d0bf990d118129de570394784d35e23cf4c\", \"target_language\": \"css\"} */\n";
        $output .= "/* index.html — portiert nach css */\n";
        $output .= "/* Quelle: html, Projects@tagesstatus-live-public:tagesstatus-live-public/index.html */\n";
        $output .= "/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */\n\n";

        foreach ($this->rules as $selector => $properties) {
            $output .= $selector . " {\n";
            foreach ($properties as $property => $value) {
                $output .= "  " . $property . ": " . $value . ";\n";
            }
            $output .= "}\n\n";
        }

        return $output;
    }

    public function saveToFile($filename) {
        $css = $this->generateCSS();
        return file_put_contents($filename, $css) !== false;
    }
}

// Wenn das Skript direkt aufgerufen wird
if (isset($argv[1])) {
    $generator = new CSSGenerator();
    if ($generator->saveToFile($argv[1])) {
        echo "CSS erfolgreich in {$argv[1]} gespeichert\n";
    } else {
        echo "Fehler beim Speichern der CSS-Datei\n";
    }
} elseif (isset($_SERVER['argv'][1])) {
    // Für CLI-Aufrufe
    $generator = new CSSGenerator();
    if ($generator->saveToFile($_SERVER['argv'][1])) {
        echo "CSS erfolgreich in {$_SERVER['argv'][1]} gespeichert\n";
    } else {
        echo "Fehler beim Speichern der CSS-Datei\n";
    }
} else {
    // Standardausgabe
    $generator = new CSSGenerator();
    echo $generator->generateCSS();
}
