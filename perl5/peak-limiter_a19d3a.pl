#!/usr/bin/perl
# abstraction-provenance: {"artifact_sha256": "2a8383b37ea8eb94e0ca69734452fe5bc56a8c1548e3dd18e94f5da84bd58d57", "source_sha256": "a19d3a3ec8b016d9d04f485dc499f8ad715431708b02863f2ac58f3208061edd", "target_language": "perl5"}
# peak-limiter.css — portiert nach perl5
# Quelle: css, Projects@abstractions:css/peak-limiter.css
# Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;

# abstraction-provenance: {"artifact_sha256": "3f2b97b726a0a4643711dc1dc285df9b75511cc4f35fbe168e178bf60aeaa00d", "source_sha256": "162cbb093559fd1ff9a7f362e753f4d965a73d5e557fce20d9cd95367574146b", "target_language": "Perl 5"}
# peak-limiter.html — portiert nach css
# Quelle: html, Projects@TikTok-Live-Companion:plugin-source/tests/peak-limiter.html
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/tests/peak-limiter.html
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/tests/peak-limiter.html
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/tests/peak-limiter.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

my $output_file = $ARGV[0] || 'peak-limiter.css';

open(my $fh, '>', $output_file) or die "Konnte Datei '$output_file' nicht öffnen: $!";

print $fh <<'EOF';
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

close($fh);

print "CSS wurde erfolgreich in '$output_file' geschrieben.\n";
