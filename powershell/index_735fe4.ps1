#!/usr/bin/env pwsh
# index.html — portiert nach powershell
# Quelle: html, OpenClaw@main:index.html
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

param(
    [Parameter(Mandatory=$true)]
    [string]$OutputPath
)

# Create the HTML structure using PowerShell commands
$html = @"
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
"@

# Write the HTML content to the specified output path
$html | Out-File -FilePath $OutputPath -Encoding utf8

Write-Host "HTML file created at: $OutputPath"
