#!/usr/bin/env raku
# abstraction-provenance: {"artifact_sha256": "6b25084fd2e009422079470247ab543a4025d333f99b34ddd2fa452633c57858", "source_sha256": "735fe4b2c74b10f265f715cd4e85d574f46a7132d2e592703b5e712888470105", "target_language": "perl6"}
# index.html — portiert nach perl6
# Quelle: html, OpenClaw@main:index.html
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

use v6;

sub create-html-document {
    my $html = '<!DOCTYPE html>' ~ "\n";
    $html ~= '<html lang="de">' ~ "\n";
    $html ~= '  <head>' ~ "\n";
    $html ~= '    <meta charset="utf-8" />' ~ "\n";
    $html ~= '    <link rel="icon" href="/favicon.ico" />' ~ "\n";
    $html ~= '    <meta name="viewport" content="width=device-width, initial-scale=1" />' ~ "\n";
    $html ~= '    <meta name="theme-color" content="#0b1020" />' ~ "\n";
    $html ~= '    <meta' ~ "\n";
    $html ~= '      name="description"' ~ "\n";
    $html ~= '      content="OpenClaw Startseite für Repository, Dokumentation und Frontend-Branch."' ~ "\n";
    $html ~= '    />' ~ "\n";
    $html ~= '    <link rel="apple-touch-icon" href="/logo192.png" />' ~ "\n";
    $html ~= '    <!--' ~ "\n";
    $html ~= '      manifest.json provides metadata used when your web app is installed on a' ~ "\n";
    $html ~= '      user\'s mobile device or desktop. See https://developers.google.com/web/fundamentals/web-app-manifest/' ~ "\n";
    $html ~= '    -->' ~ "\n";
    $html ~= '    <link rel="manifest" href="/manifest.json" />' ~ "\n";
    $html ~= '    <title>OpenClaw</title>' ~ "\n";
    $html ~= '  </head>' ~ "\n";
    $html ~= '  <body>' ~ "\n";
    $html ~= '    <noscript>You need to enable JavaScript to run this app.</noscript>' ~ "\n";
    $html ~= '    <div id="root"></div>' ~ "\n";
    $html ~= '    <!--' ~ "\n";
    $html ~= '      This HTML file is a template.' ~ "\n";
    $html ~= '      If you open it directly in the browser, you will see an empty page.' ~ "\n";
    $html ~= '' ~ "\n";
    $html ~= '      You can add webfonts, meta tags, or analytics to this file.' ~ "\n";
    $html ~= '      The build step will place the bundled scripts into the <body> tag.' ~ "\n";
    $html ~= '' ~ "\n";
    $html ~= '      To begin the development, run `npm start` or `yarn start`.' ~ "\n";
    $html ~= '      To create a production bundle, use `npm run build` or `yarn build`.' ~ "\n";
    $html ~= '    -->' ~ "\n";
    $html ~= '  </body>' ~ "\n";
    $html ~= '  <script type="module" src="/src/index.jsx"></script>' ~ "\n";
    $html ~= '</html>' ~ "\n";
    
    return $html;
}

sub MAIN($output-file) {
    my $content = create-html-document();
    
    # Schreibe den Inhalt in die angegebene Datei
    spurt($output-file, $content);
    
    say "HTML document created successfully at $output-file";
}
