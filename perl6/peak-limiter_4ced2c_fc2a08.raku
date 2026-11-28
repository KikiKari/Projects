#!/usr/bin/env raku
# abstraction-provenance: {"artifact_sha256": "649eac97d87065779c4bec75cc9121f566d2e018263d514e5ac1248a6582acef", "source_sha256": "fc2a08fec30e381e2f112d375f3c1136b4730cdaa58967167750a5dc9b65532d", "target_language": "perl6"}
# peak-limiter_4ced2c.css — portiert nach perl6
# Quelle: css, Projects@abstractions:css/peak-limiter_4ced2c.css
# Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

# abstraction-provenance: {"artifact_sha256": "c86160b4782bbdd4341a998965a2c305098b3c29f36c24b5c96324073afc4800", "source_sha256": "4ced2ca9b27b1be45a4172c7993a0693b54431a3a2703c30cb796b668ff34bc0", "target_language": "raku"}
# peak-limiter.html — portiert nach raku
# Quelle: html, Projects@vercel/install-and-configure-vercel-w-98sxlo:plugin-source/tests/peak-limiter.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

sub create-css-content() {
    my $css = q:to/END_CSS/;
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
END_CSS
    return $css;
}

sub MAIN($output-file) {
    my $content = create-css-content();
    spurt($output-file, $content);
}
