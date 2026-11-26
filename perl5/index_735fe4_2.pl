#!/usr/bin/perl
# abstraction-provenance: {"artifact_sha256": "eaef992fdbf1d5fb8f35699ae45a8dfd922ee7fed86ece55d3890a8d2a5ffc5e", "source_sha256": "735fe4b2c74b10f265f715cd4e85d574f46a7132d2e592703b5e712888470105", "target_language": "perl5"}
# index.html — portiert nach perl5
# Quelle: html, OpenClaw@main:index.html
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;

# Function to generate the HTML document
sub generate_html {
    my $html = <<'EOF';
<!DOCTYPE html>
<html lang="de">
  <head>
    <meta charset="utf-8" />
    <link rel="icon" href="/favicon.ico" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="theme-color" content="#0b1020" />
    <meta
      name="description"
      content="OpenClaw Startseite f&uuml;r Repository, Dokumentation und Frontend-Branch."
    />
    <link rel="apple-touch-icon" href="/logo192.png" />
    <!--
      manifest.json provides metadata used when your web app is installed on a
      user's mobile device or desktop. See https://developers.google.com/web/fundamentals/web-app-manifest/
    -->
    <link rel="manifest" href="/manifest.json" />
    <title>OpenClaw</title>
  </head>
  <body>
    <noscript>You need to enable JavaScript to run this app.</noscript>
    <div id="root"></div>
    <!--
      This HTML file is a template.
      If you open it directly in the browser, you will see an empty page.

      You can add webfonts, meta tags, or analytics to this file.
      The build step will place the bundled scripts into the <body> tag.

      To begin the development, run `npm start` or `yarn start`.
      To create a production bundle, use `npm run build` or `yarn build`.
    -->
  </body>
  <script type="module" src="/src/index.jsx"></script>
</html>
EOF
    return $html;
}

# Main execution
sub main {
    my $filename = $ARGV[0] || 'index.html';
    
    my $content = generate_html();
    
    open(my $fh, '>', $filename) or die "Could not open file '$filename': $!";
    print $fh $content;
    close($fh);
    
    print "HTML file generated: $filename\n";
}

main();
