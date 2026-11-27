#!/usr/bin/perl
# abstraction-provenance: {"artifact_sha256": "19d2e37517ea6113681851604932ddc8da6a5e351ba870eebd02d8ecbb838a17", "source_sha256": "a243d1fdcbd0c82c97b2771c181438428885fd9c2feaed782f7e9eb8066fed59", "target_language": "perl5"}
# offscreen.html — portiert nach perl5
# Quelle: html, Projects@TikTok-Live-Companion:plugin-source/browser-extension/offscreen.html
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/offscreen.html
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/offscreen.html
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/browser-extension/offscreen.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;

# Get output filename from command line argument
my $output_file = $ARGV[0] || die "Usage: $0 <output_filename>\n";

# Create the HTML structure
my $html_content = <<'EOF';
<!doctype html>
<html lang="de">
<head>
  <meta charset="utf-8">
  <title>TikTok LIVE Companion Sprachausgabe</title>
</head>
<body>
  <script src="offscreen.js"></script>
</body>
</html>
EOF

# Write to file
open(my $fh, '>', $output_file) or die "Could not open file '$output_file' for writing: $!\n";
print $fh $html_content;
close($fh);

print "HTML file created successfully: $output_file\n";
