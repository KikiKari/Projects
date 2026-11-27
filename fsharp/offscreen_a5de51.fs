// abstraction-provenance: {"artifact_sha256": "11f68cf8c6cd1e2094533cf3e7bf272c7f26d0b823241b35a64e38be428b08e3", "source_sha256": "a5de51b02b40bbdeafb7fb0f4da19091ec351b10a9160307085ebcef403cdd67", "target_language": "fsharp"}
// offscreen.html — portiert nach fsharp
// Quelle: html, Projects@vercel/install-and-configure-vercel-w-98sxlo:plugin-source/browser-extension/offscreen.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

open System
open System.IO
open System.Xml.Linq

let createOffscreenHtml () =
    let html = 
        XElement(XName.Get "html", XAttribute(XName.Get "lang", "de"),
            XElement(XName.Get "head",
                XElement(XName.Get "meta", XAttribute(XName.Get "charset", "utf-8")),
                XElement(XName.Get "title", "TikTok LIVE Companion Sprachausgabe")
            ),
            XElement(XName.Get "body",
                XElement(XName.Get "script", XAttribute(XName.Get "src", "offscreen.js"))
            )
        )
    
    let doc = XDocument(XDeclaration("1.0", "utf-8", null), html)
    doc

let writeToFile (filePath: string) =
    let doc = createOffscreenHtml()
    use writer = new StreamWriter(filePath, false, Text.Encoding.UTF8)
    writer.WriteLine("<!doctype html>")
    doc.Save(writer)

[<EntryPoint>]
let main args =
    match args with
    | [| filePath |] -> 
        writeToFile filePath
        0
    | _ -> 
        printfn "Usage: program <output-file-path>"
        1
