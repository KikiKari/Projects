#!/usr/bin/perl
# index.html — portiert nach perl5
# Quelle: html, OpenClaw@main:index.html
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;

# Function to generate the HTML content
sub generate_html {
    return <<'HTML';
<!DOCTYPE html>
<html lang="de">
  <head>
    <meta charset="utf-8" />
    <link rel="icon" href="/favicon.ico" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="theme-color" content="#0b1020" />
    <meta
      name="description"
      content="OpenClaw Startseite für Repository, Dokumentation und Frontend-Branch."
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
HTML
}

# Main function to write HTML to a file
sub main {
    my $filename = shift @ARGV || 'index.html';
    
    # Generate the HTML content
    my $html_content = generate_html();
    
    # Write to file
    open(my $fh, '>', $filename) or die "Could not open file '$filename': $!";
    print $fh $html_content;
    close($fh);
    
    print "HTML file created: $filename\n";
}

# Execute main function
main();
