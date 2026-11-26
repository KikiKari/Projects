<?php
// abstraction-provenance: {"artifact_sha256": "c6da5035e7e211dd363d4915e35f10febaae701e08529ed458d002c18cbb3302", "source_sha256": "08fdd65a33a6ec90261b4ce48be82ca8338400da1b321dfc70a57bedabfa45aa", "target_language": "php"}
// App.css — portiert nach php
// Quelle: css, OpenClaw@main:src/App.css
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py
function generateCSS($filename) {
    $css = new CSSBuilder();
    $document = $css->build();
    file_put_contents($filename, $document);
}

class CSSBuilder {
    private $rules = [];
    
    public function build() {
        $this->addRoot();
        $this->addAll();
        $this->addBody();
        $this->addPageShell();
        $this->addHeroCard();
        $this->addEyebrow();
        $this->addH1();
        $this->addLead();
        $this->addLinkGrid();
        $this->addLinkGridAnchors();
        
        return $this->generateOutput();
    }
    
    private function addRule($selector, $properties) {
        $this->rules[] = [
            'selector' => $selector,
            'properties' => $properties
        ];
    }
    
    private function addRoot() {
        $this->addRule(':root', [
            'color-scheme' => 'dark',
            'font-family' => 'Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif',
            'background' => '#0b1020',
            'color' => '#eef2ff'
        ]);
    }
    
    private function addAll() {
        $this->addRule('*', [
            'box-sizing' => 'border-box'
        ]);
    }
    
    private function addBody() {
        $this->addRule('body', [
            'margin' => '0',
            'min-width' => '320px',
            'min-height' => '100vh',
            'background' => '
    radial-gradient(circle at 20% 20%, rgba(56, 189, 248, 0.22), transparent 30rem),
    radial-gradient(circle at 80% 10%, rgba(168, 85, 247, 0.2), transparent 28rem),
    linear-gradient(135deg, #050816 0%, #111827 55%, #172033 100%)'
        ]);
    }
    
    private function addPageShell() {
        $this->addRule('.page-shell', [
            'min-height' => '100vh',
            'display' => 'grid',
            'place-items' => 'center',
            'padding' => '2rem'
        ]);
    }
    
    private function addHeroCard() {
        $this->addRule('.hero-card', [
            'width' => 'min(100%, 56rem)',
            'padding' => 'clamp(2rem, 6vw, 4.5rem)',
            'border' => '1px solid rgba(148, 163, 184, 0.28)',
            'border-radius' => '2rem',
            'background' => 'rgba(15, 23, 42, 0.72)',
            'box-shadow' => '0 2rem 6rem rgba(0, 0, 0, 0.35)',
            'backdrop-filter' => 'blur(18px)'
        ]);
    }
    
    private function addEyebrow() {
        $this->addRule('.eyebrow', [
            'margin' => '0 0 1rem',
            'color' => '#67e8f9',
            'font-size' => '0.8rem',
            'font-weight' => '700',
            'letter-spacing' => '0.18em',
            'text-transform' => 'uppercase'
        ]);
    }
    
    private function addH1() {
        $this->addRule('h1', [
            'margin' => '0',
            'max-width' => '12ch',
            'font-size' => 'clamp(2.75rem, 8vw, 6rem)',
            'line-height' => '0.95',
            'letter-spacing' => '-0.06em'
        ]);
    }
    
    private function addLead() {
        $this->addRule('.lead', [
            'margin' => '1.5rem 0 0',
            'max-width' => '42rem',
            'color' => '#cbd5e1',
            'font-size' => 'clamp(1.05rem, 2vw, 1.35rem)',
            'line-height' => '1.65'
        ]);
    }
    
    private function addLinkGrid() {
        $this->addRule('.link-grid', [
            'display' => 'grid',
            'gap' => '0.85rem',
            'margin-top' => '2rem'
        ]);
    }
    
    private function addLinkGridAnchors() {
        $this->addRule('.link-grid a', [
            'display' => 'flex',
            'align-items' => 'center',
            'justify-content' => 'space-between',
            'gap' => '1rem',
            'padding' => '1rem 1.15rem',
            'border' => '1px solid rgba(148, 163, 184, 0.25)',
            'border-radius' => '1rem',
            'color' => '#f8fafc',
            'text-decoration' => 'none',
            'background' => 'rgba(255, 255, 255, 0.06)'
        ]);
        
        $this->addRule('.link-grid a:hover,\n.link-grid a:focus-visible', [
            'border-color' => 'rgba(103, 232, 249, 0.75)',
            'outline' => 'none',
            'background' => 'rgba(103, 232, 249, 0.12)'
        ]);
    }
    
    private function generateOutput() {
        $output = '';
        foreach ($this->rules as $rule) {
            $output .= $rule['selector'] . " {\n";
            foreach ($rule['properties'] as $property => $value) {
                $output .= "  " . $property . ": " . $value . ";\n";
            }
            $output .= "}\n\n";
        }
        return rtrim($output);
    }
}

// Wenn das Skript direkt aufgerufen wird
if (isset($argv[1])) {
    generateCSS($argv[1]);
} else if (isset($_SERVER['argv'][1])) {
    generateCSS($_SERVER['argv'][1]);
}

?>
