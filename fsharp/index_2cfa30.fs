// abstraction-provenance: {"artifact_sha256": "ad8b7f53625a49728cc835e593a29eb06a56b2c16091609b20de9eb59af2811d", "source_sha256": "2cfa301efe20d60c29e0e9f0746e5a99d405ea44a5d03839c72e6b525451fe07", "target_language": "fsharp"}
// index.html — portiert nach fsharp
// Quelle: html, Projects@TikTok-Live-Companion-Android:site/index.html
// auch in: Projects@TikTok-Live-Companion-iOS:site/index.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

open System
open System.IO
open System.Xml.Linq

// Funktion zum Erstellen des HTML-Dokuments
let createHtmlDocument () =
    // Erstellen des HTML-Dokuments mit XDocument
    let docType = XDeclaration("1.0", "UTF-8", null)
    
    let html = 
        XElement(XName.Get("html"), XAttribute(XName.Get("lang"), "de"),
            XElement(XName.Get("head"),
                XElement(XName.Get("meta"), 
                    XAttribute(XName.Get("charset"), "UTF-8")),
                XElement(XName.Get("meta"), 
                    XAttribute(XName.Get("name"), "viewport"),
                    XAttribute(XName.Get("content"), "width=device-width, initial-scale=1.0")),
                XElement(XName.Get("meta"), 
                    XAttribute(XName.Get("name"), "description"),
                    XAttribute(XName.Get("content"), "Dokumentation für TikTok LIVE Companion 0.8.0 – Chat-TTS, Zuschauerstatistik, Songerkennung und Stream-Informationen direkt im Browser.")),
                XElement(XName.Get("meta"), 
                    XAttribute(XName.Get("name"), "theme-color"),
                    XAttribute(XName.Get("content"), "#ffffff")),
                XElement(XName.Get("link"), 
                    XAttribute(XName.Get("rel"), "icon"),
                    XAttribute(XName.Get("type"), "image/png"),
                    XAttribute(XName.Get("href"), "/branding/staenderglobus-ios.png")),
                XElement(XName.Get("link"), 
                    XAttribute(XName.Get("rel"), "apple-touch-icon"),
                    XAttribute(XName.Get("href"), "/branding/staenderglobus-ios.png")),
                XElement(XName.Get("title"), "TikTok LIVE Companion – Dokumentation")
            ),
            XElement(XName.Get("body"),
                XElement(XName.Get("div"), XAttribute(XName.Get("id"), "root")),
                XElement(XName.Get("script"), 
                    XAttribute(XName.Get("type"), "module"),
                    XAttribute(XName.Get("src"), "/src/main.tsx"))
            )
        )
    
    // Hinzufügen des <!DOCTYPE html> als Kommentar (da XDocument keinen direkten DOCTYPE-Support hat)
    // In der Ausgabe wird dies manuell hinzugefügt
    
    html

// Funktion zum Schreiben des HTML-Dokuments in eine Datei
let writeHtmlToFile (filePath: string) =
    let htmlElement = createHtmlDocument()
    
    // Manuelles Erstellen des XML mit DOCTYPE
    use writer = new StreamWriter(filePath, false, Text.Encoding.UTF8)
    
    // Schreiben des DOCTYPE
    writer.WriteLine("<!doctype html>")
    
    // Schreiben des HTML-Inhalts
    htmlElement.Save(writer)
    
    printfn "HTML-Datei wurde erfolgreich erstellt: %s" filePath

// Hauptfunktion
[<EntryPoint>]
let main argv =
    let filePath = 
        if argv.Length > 0 then argv.[0] 
        else "index.html"
    
    try
        writeHtmlToFile filePath
        0
    with
    | ex ->
        eprintfn "Fehler beim Erstellen der HTML-Datei: %s" ex.Message
        1
