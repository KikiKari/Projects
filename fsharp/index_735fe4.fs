// abstraction-provenance: {"artifact_sha256": "9c53c3a88c81ea8c4970605af1f8c1b3ff4c25f71b50deac02eef6ca4f8ad569", "source_sha256": "735fe4b2c74b10f265f715cd4e85d574f46a7132d2e592703b5e712888470105", "target_language": "fsharp"}
// index.html — portiert nach fsharp
// Quelle: html, OpenClaw@main:index.html
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

// F# Programm zur Erzeugung der index.html Datei
open System
open System.IO

// Funktion zur Erstellung der HTML-Struktur
let createHtmlDocument () =
    let html = """
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
</html>"""
    html.TrimStart()

// Hauptfunktion
[<EntryPoint>]
let main argv =
    try
        // Prüfe ob ein Dateiname übergeben wurde
        let filename = 
            if argv.Length > 0 then argv.[0]
            else "index.html"
        
        // Erzeuge den HTML-Inhalt
        let htmlContent = createHtmlDocument()
        
        // Schreibe in Datei
        File.WriteAllText(filename, htmlContent)
        
        printfn "HTML-Datei erfolgreich erstellt: %s" filename
        0
    with
    | ex ->
        eprintfn "Fehler beim Erstellen der HTML-Datei: %s" ex.Message
        1
