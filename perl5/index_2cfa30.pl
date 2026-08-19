#!/usr/bin/perl
# index.html — portiert nach perl5
# Quelle: html, Projects@TikTok-Live-Companion:site/index.html
# auch in: Projects@TikTok-Live-Companion-Android:site/index.html
# auch in: Projects@TikTok-Live-Companion-iOS:site/index.html
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

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
    <meta name="description" content="Dokumentation f&uuml;r TikTok LIVE Companion 0.8.0 &ndash; Chat-TTS, Zuschauerstatistik, Songerkennung und Stream-Informationen direkt im Browser." />
    <meta name="theme-color" content="#ffffff" />
    <link rel="icon" type="image/png" href="/branding/staenderglobus-ios.png" />
    <link rel="apple-touch-icon" href="/branding/staenderglobus-ios.png" />
    <title>TikTok LIVE Companion &ndash; Dokumentation</title>
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
    # Check if a filename parameter is provided
    if (@ARGV != 1) {
        print STDERR "Usage: $0 <output_file>\n";
        exit 1;
    }
    
    my $filename = $ARGV[0];
    
    # Generate the HTML content
    my $content = generate_html();
    
    # Write content to the specified file
    open(my $fh, '>', $filename) or die "Could not open file '$filename': $!";
    print $fh $content;
    close($fh);
    
    print "HTML document written to $filename\n";
}

# Run main function
main();
