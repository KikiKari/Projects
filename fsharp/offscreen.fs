// abstraction-provenance: {"artifact_sha256": "ef1eb931e15ede8a458c3223f5149332ddc6d9027bebeb7d80520095229af7e7", "source_sha256": "a243d1fdcbd0c82c97b2771c181438428885fd9c2feaed782f7e9eb8066fed59", "target_language": "fsharp"}
// offscreen.html — portiert nach fsharp
// Quelle: html, Projects@TikTok-Live-Companion:plugin-source/browser-extension/offscreen.html
// auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/offscreen.html
// auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/offscreen.html
// auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/browser-extension/offscreen.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

open System
open System.IO
open System.Xml

let createOffscreenHtml (outputPath: string) =
    let doc = XmlDocument()
    
    // Create the doctype
    let doctype = doc.CreateDocumentType("html", null, null, null)
    doc.AppendChild(doctype) |> ignore
    
    // Create html element with lang attribute
    let html = doc.CreateElement("html")
    let langAttr = doc.CreateAttribute("lang")
    langAttr.Value <- "de"
    html.Attributes.Append(langAttr) |> ignore
    doc.AppendChild(html) |> ignore
    
    // Create head section
    let head = doc.CreateElement("head")
    html.AppendChild(head) |> ignore
    
    // Create meta charset
    let meta = doc.CreateElement("meta")
    let charsetAttr = doc.CreateAttribute("charset")
    charsetAttr.Value <- "utf-8"
    meta.Attributes.Append(charsetAttr) |> ignore
    head.AppendChild(meta) |> ignore
    
    // Create title
    let title = doc.CreateElement("title")
    title.InnerText <- "TikTok LIVE Companion Sprachausgabe"
    head.AppendChild(title) |> ignore
    
    // Create body section
    let body = doc.CreateElement("body")
    html.AppendChild(body) |> ignore
    
    // Create script tag with src attribute
    let script = doc.CreateElement("script")
    let srcAttr = doc.CreateAttribute("src")
    srcAttr.Value <- "offscreen.js"
    script.Attributes.Append(srcAttr) |> ignore
    body.AppendChild(script) |> ignore
    
    // Write to file with proper formatting
    use writer = XmlWriter.Create(outputPath, new XmlWriterSettings(Indent = true, IndentChars = "  "))
    doc.Save(writer)

// Main execution
[<EntryPoint>]
let main argv =
    let outputPath = 
        if argv.Length > 0 then argv.[0]
        else "offscreen.html"
    
    createOffscreenHtml outputPath
    0
