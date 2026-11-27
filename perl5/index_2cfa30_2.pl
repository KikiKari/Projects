#!/usr/bin/perl
# abstraction-provenance: {"artifact_sha256": "ea165cb2ac1e227eec6698cb9004ff0d1dee64578772b6e0591574a12983a5e7", "source_sha256": "2cfa301efe20d60c29e0e9f0746e5a99d405ea44a5d03839c72e6b525451fe07", "target_language": "perl5"}
# index.html — portiert nach perl5
# Quelle: html, Projects@TikTok-Live-Companion-Android:site/index.html
# auch in: Projects@TikTok-Live-Companion-iOS:site/index.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;

# Function to generate the HTML document
sub generate_html {
    my $html = <<'EOF';
<!doctype html>
<html lang="de">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <meta name="description" content="Dokumentation für TikTok LIVE Companion 0.8.0 – Chat-TTS, Zuschauerstatistik, Songerkennung und Stream-Informationen direkt im Browser." />
    <meta name="theme-color" content="#ffffff" />
    <link rel="icon" type="image/png" href="/branding/staenderglobus-ios.png" />
    <link rel="apple-touch-icon" href="/branding/staenderglobus-ios.png" />
    <title>TikTok LIVE Companion – Dokumentation</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
EOF
    return $html;
}

# Main execution
sub main {
    my $filename = $ARGV[0] || 'index.html';
    
    open(my $fh, '>', $filename) or die "Could not open file '$filename': $!";
    print $fh generate_html();
    close($fh);
    
    print "HTML document written to $filename\n";
}

main() if $0 eq __FILE__;
