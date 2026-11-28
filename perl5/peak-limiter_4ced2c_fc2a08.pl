#!/usr/bin/perl
# abstraction-provenance: {"artifact_sha256": "fff5c8a07a63245abe2cdc3de80fffa2ed8b27ad21a84a1e780dc16f4150e789", "source_sha256": "fc2a08fec30e381e2f112d375f3c1136b4730cdaa58967167750a5dc9b65532d", "target_language": "perl5"}
# peak-limiter_4ced2c.css — portiert nach perl5
# Quelle: css, Projects@abstractions:css/peak-limiter_4ced2c.css
# Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;

# abstraction-provenance: {"artifact_sha256": "c86160b4782bbdd4341a998965a2c305098b3c29f36c24b5c96324073afc4800", "source_sha256": "4ced2ca9b27b1be45a4172c7993a0693b54431a3a2703c30cb796b668ff34bc0", "target_language": "perl"}
# peak-limiter.html — portiert nach css
# Quelle: html, Projects@vercel/install-and-configure-vercel-w-98sxlo:plugin-source/tests/peak-limiter.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

my $output_file = $ARGV[0] || 'peak-limiter_4ced2c.css';

open my $fh, '>', $output_file or die "Kann Datei '$output_file' nicht öffnen: $!";

print $fh <<'EOF';
/* abstraction-provenance: {"artifact_sha256": "c86160b4782bbdd4341a998965a2c305098b3c29f36c24b5c96324073afc4800", "source_sha256": "4ced2ca9b27b1be45a4172c7993a0693b54431a3a2703c30cb796b668ff34bc0", "target_language": "css"} */
/* peak-limiter.html — portiert nach css */
/* Quelle: html, Projects@vercel/install-and-configure-vercel-w-98sxlo:plugin-source/tests/peak-limiter.html */
/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */

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
EOF

close $fh;

print "CSS wurde erfolgreich in '$output_file' geschrieben.\n";
