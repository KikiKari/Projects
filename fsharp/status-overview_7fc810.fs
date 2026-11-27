// abstraction-provenance: {"artifact_sha256": "44bac97c5b696c1072ba0c00a1f5157fd91c1cb319a68e5328c3ec3c1ef211a1", "source_sha256": "7fc810e8bcb817cb81407c2ad604d4bd70dce9f3ff8cb2bbfbcacfec00febd1c", "target_language": "fsharp"}
// status-overview.html — portiert nach fsharp
// Quelle: html, Projects@TikTok-Live-Companion:plugin-source/browser-extension/status-overview.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

open System
open System.IO
open System.Xml

let createStatusOverview (outputPath: string) =
    let doc = new XmlDocument()
    
    // Create doctype
    let doctype = doc.CreateDocumentType("html", null, null, null)
    doc.AppendChild(doctype) |> ignore
    
    // Create root element
    let html = doc.CreateElement("html")
    let langAttr = doc.CreateAttribute("lang")
    langAttr.Value <- "de"
    html.Attributes.Append(langAttr) |> ignore
    doc.AppendChild(html) |> ignore
    
    // Create head
    let head = doc.CreateElement("head")
    html.AppendChild(head) |> ignore
    
    // Add meta charset
    let metaCharset = doc.CreateElement("meta")
    let charsetAttr = doc.CreateAttribute("charset")
    charsetAttr.Value <- "utf-8"
    metaCharset.Attributes.Append(charsetAttr) |> ignore
    head.AppendChild(metaCharset) |> ignore
    
    // Add viewport meta
    let metaViewport = doc.CreateElement("meta")
    let nameAttr = doc.CreateAttribute("name")
    nameAttr.Value <- "viewport"
    metaViewport.Attributes.Append(nameAttr) |> ignore
    let contentAttr = doc.CreateAttribute("content")
    contentAttr.Value <- "width=device-width,initial-scale=1"
    metaViewport.Attributes.Append(contentAttr) |> ignore
    head.AppendChild(metaViewport) |> ignore
    
    // Add title
    let title = doc.CreateElement("title")
    title.InnerText <- "STATUS-Overview"
    head.AppendChild(title) |> ignore
    
    // Add stylesheet link
    let link = doc.CreateElement("link")
    let relAttr = doc.CreateAttribute("rel")
    relAttr.Value <- "stylesheet"
    link.Attributes.Append(relAttr) |> ignore
    let hrefAttr = doc.CreateAttribute("href")
    hrefAttr.Value <- "status-overview.css"
    link.Attributes.Append(hrefAttr) |> ignore
    head.AppendChild(link) |> ignore
    
    // Create body
    let body = doc.CreateElement("body")
    html.AppendChild(body) |> ignore
    
    // Create main element
    let main = doc.CreateElement("main")
    let idAttr = doc.CreateAttribute("id")
    idAttr.Value <- "grid"
    main.Attributes.Append(idAttr) |> ignore
    let ariaLabelAttr = doc.CreateAttribute("aria-label")
    ariaLabelAttr.Value <- "LIVE-Übersicht"
    main.Attributes.Append(ariaLabelAttr) |> ignore
    body.AppendChild(main) |> ignore
    
    // Add script tags
    let script1 = doc.CreateElement("script")
    let srcAttr1 = doc.CreateAttribute("src")
    srcAttr1.Value <- "vendor-mpegts.js"
    script1.Attributes.Append(srcAttr1) |> ignore
    body.AppendChild(script1) |> ignore
    
    let script2 = doc.CreateElement("script")
    let srcAttr2 = doc.CreateAttribute("src")
    srcAttr2.Value <- "status-overview-player.js"
    script2.Attributes.Append(srcAttr2) |> ignore
    body.AppendChild(script2) |> ignore
    
    // Save to file
    use writer = new XmlTextWriter(outputPath, Text.Encoding.UTF8)
    writer.Formatting <- Formatting.Indented
    writer.Indentation <- 2
    doc.Save(writer)

// Main entry point
[<EntryPoint>]
let main argv =
    let outputPath = 
        if argv.Length > 0 then argv.[0] 
        else "status-overview.html"
    
    createStatusOverview outputPath
    0
